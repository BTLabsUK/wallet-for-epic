// SPDX-License-Identifier: Apache-2.0
// The node layer against a real epic node: the bundled binary in a scratch folder, mainnet,
// header sync only. Off unless WFE_NODE_LIVE=1 (it downloads chain headers, ~1 GB a million).
//
//   WFE_NODE_LIVE=1 WFE_NODE_BIN=<path to epic 4.1.x> flutter test test/node/node_live_test.dart
//
// WFE_NODE_LIVE_SECONDS (default 180) is how long it syncs headers; it stops sooner when the
// chain data passes WFE_NODE_LIVE_MAX_GB (default 2), and the node itself stops under 5 GB free.
// Needs ports 3413 and 3414 free. Everything goes in a temp folder that is deleted afterwards.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/chain_data.dart';
import 'package:epic_wallet/src/node/local_node_controller.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/node_detect.dart';
import 'package:epic_wallet/src/node/node_info.dart';
import 'package:epic_wallet/src/node/node_maintenance.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:epic_wallet/src/node/peers.dart';
import 'package:epic_wallet/src/node/sync_progress.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final _env = Platform.environment;
final _live = _env['WFE_NODE_LIVE'] == '1';
final _binary = _env['WFE_NODE_BIN'] ?? '';
final _syncFor = Duration(seconds: int.tryParse(_env['WFE_NODE_LIVE_SECONDS'] ?? '') ?? 180);
final _maxBytes = (double.tryParse(_env['WFE_NODE_LIVE_MAX_GB'] ?? '') ?? 2) * (1 << 30);

class _RealHttp extends HttpOverrides {}

class _NoMonitor implements NodeDirectory {
  @override
  Future<List<NodeStatus>> nodes(String chain) async => throw const SocketException('offline');
}

void _say(String m) {
  // ignore: avoid_print
  print('[live] $m');
}

/// Waits until [ok] holds for the controller's state, or fails after [limit].
Future<LocalNodeState> _until(LocalNodeController c, bool Function(LocalNodeState s) ok, Duration limit, String what) async {
  if (ok(c.state)) return c.state;
  try {
    return await c.states.firstWhere(ok).timeout(limit);
  } on TimeoutException {
    fail('$what: not within ${limit.inSeconds} s; last state ${c.state.phase.name} ${c.state.progress?.stage.name}');
  }
}

Future<T> _poll<T>(Future<T?> Function() read, Duration limit, String what) async {
  final until = DateTime.now().add(limit);
  while (DateTime.now().isBefore(until)) {
    final v = await read();
    if (v != null) return v;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  fail('$what: not within ${limit.inSeconds} s');
}

void main() {
  test(
    'start, sync headers, peers, ban and unban, restart with new options, stop, delete chain data',
    () => HttpOverrides.runWithHttpOverrides(() async {
      expect(File(_binary).existsSync(), isTrue, reason: 'WFE_NODE_BIN must name the epic binary');
      final root = await Directory.systemTemp.createTemp('wfe-node-live-');
      addTearDown(() async {
        await stopAllBuiltInNodes();
        await root.delete(recursive: true);
      });
      final node = BuiltInNode(root: root.path, binary: _binary, chain: Chain.mainnet, log: (m) => _say('node: $m'));
      final settings = NodeSettings(MemorySecretStore(), Chain.mainnet);
      final api = NodeApiClient(node.url, secret: node.readSecret);
      final controller = LocalNodeController(
        node,
        settings: settings,
        dirSize: dirSize,
        diskEvery: const Duration(seconds: 10),
        networkEvery: const Duration(seconds: 15),
        peersHeight: () async => medianPeerHeight(await api.connectedPeers()),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state.phase, LocalNodePhase.stopped);

      // Nothing answers before the start (else another node holds the port).
      final before = await detectLocalNode(Chain.mainnet, ours: node);
      expect(before.answers, isFalse, reason: 'port 3413 must be free for this test');

      await controller.start();
      final syncing = await _until(controller, (s) => s.phase == LocalNodePhase.syncing, const Duration(seconds: 90), 'syncing');
      _say('syncing: stage ${syncing.progress?.stage.name}, version ${syncing.version}');
      expect(syncing.online, isFalse, reason: 'never online while syncing');
      expect(syncing.startedAt, isNotNull);
      final firstStart = syncing.startedAt;

      // ready_for_txs is the readiness source; a syncing node says false.
      expect(await api.readyForTxs(), isFalse);
      expect((await api.version()).nodeVersion, startsWith('4.'));
      final probe = await detectLocalNode(Chain.mainnet, ours: node);
      expect(probe.answers, isTrue);
      expect(probe.ours, isTrue);
      expect(probe.otherNode, isFalse);

      // Limited info (monitor unreachable): from the node itself.
      final info = await NodeInfoService(nodes: _NoMonitor()).info(node.url, chain: 'mainnet');
      expect(info.source, NodeInfoSource.limited);
      expect(info.readyForTxs, isFalse);
      expect(info.state, NodeHealthState.degraded);
      expect(info.latencyMs, isNotNull);

      // Headers come in: the stage, its numbers and an ETA.
      final headers = await _until(
        controller,
        (s) => s.progress?.stage == SyncStage.headers && (s.progress?.done ?? 0) > 0,
        const Duration(minutes: 3),
        'header sync',
      );
      _say('headers ${headers.progress?.done} of ${headers.progress?.total}, ${headers.peers} peers');

      // Peers through the owner API.
      final peers = PeerService(api);
      final withPeer = await _poll(() async {
        final s = await peers.refresh();
        return s.connected.isEmpty ? null : s;
      }, const Duration(minutes: 2), 'a connected peer');
      final victim = withPeer.connected.first;
      _say('${withPeer.connected.length} peers (${withPeer.outbound} out, ${withPeer.inbound} in); banning ${victim.addr}');
      expect(victim.peer.userAgent, contains('Epic'));
      expect(victim.firstSeen, isNotNull);
      await peers.ban(victim.addr);
      final banned = await api.peers(addr: victim.addr);
      expect(banned.single.flag, PeerFlag.banned);
      expect(banned.single.banReason, 'ManualBan');
      expect((await peers.refresh()).banned.map((p) => p.addr), contains(victim.addr));
      await peers.unban(victim.addr);
      expect((await api.peers(addr: victim.addr)).single.flag, isNot(PeerFlag.banned));
      await expectLater(peers.ban('203.0.113.250:3414'), throwsA(isA<NodeRpcException>()));

      // Let it sync for a while, watching the size.
      final until = DateTime.now().add(_syncFor);
      LocalNodeState? withEta;
      while (DateTime.now().isBefore(until)) {
        await Future<void>.delayed(const Duration(seconds: 10));
        final s = controller.state;
        if (s.eta != null) withEta ??= s;
        _say('${s.phase.name} ${s.progress?.stage.name} ${s.progress?.done}/${s.progress?.total} '
            'overall ${s.progress?.overall?.toStringAsFixed(3)} eta ${s.eta?.inSeconds}s '
            'rate ${s.stageRate?.round()}/s disk ${s.chainDataBytes} free ${s.freeBytes} peers ${s.peers}');
        expect(s.phase, isNot(LocalNodePhase.error), reason: s.reason);
        if ((s.chainDataBytes ?? 0) > _maxBytes) {
          _say('chain data over the cap; stopping the sync early');
          break;
        }
      }
      expect(withEta, isNotNull, reason: 'an ETA while headers sync');
      final last = controller.state;
      expect(last.progress?.total, greaterThan(3000000), reason: 'headers are measured against the network tip');
      expect(last.progress?.overall, lessThan(0.3));
      expect(controller.state.chainDataBytes, greaterThan(0));
      expect(controller.state.freeBytes, greaterThan(5 << 30));

      // New options need a restart; the restart applies them.
      await controller.setMaxPeers(inbound: 8, outbound: 8);
      expect(controller.state.restartNeeded, isTrue);
      await controller.restart();
      final again = await _until(controller, (s) => s.phase == LocalNodePhase.syncing, const Duration(seconds: 90), 'syncing after restart');
      expect(again.restartNeeded, isFalse);
      expect(again.startedAt, isNot(firstStart));
      final toml = File(node.tomlPath).readAsStringSync();
      expect(toml, contains('peer_max_inbound_count = 8'));
      expect(toml, contains('peer_max_outbound_count = 8'));

      expect(await controller.logTail(lines: 20), isNotEmpty);

      // Stop: the process is gone and its lock with it.
      final pid = node.pid!;
      await controller.stop();
      expect(controller.state.phase, LocalNodePhase.stopped);
      expect(Directory('/proc/$pid').existsSync(), isFalse, reason: 'the node process exited');
      expect(await probeChainLock(node.chainDataPath), FolderLock.free);

      // Delete chain data: only this node's folder, with the node stopped.
      final freed = await NodeMaintenance(controller).deleteChainData();
      _say('deleted ${(freed / (1 << 20)).round()} MB of chain data');
      expect(freed, greaterThan(0));
      expect(Directory(node.chainDataPath).existsSync(), isFalse);
      expect(controller.state.chainDataBytes, 0);
    }, _RealHttp()),
    skip: _live ? false : 'set WFE_NODE_LIVE=1 and WFE_NODE_BIN to run against a real node',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
