import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/sync_progress.dart';
import 'package:flutter_test/flutter_test.dart';

NodeStatusInfo status(String sync, int height, {int? highest}) =>
    NodeStatusInfo(
      protocolVersion: 2,
      userAgent: 'MW/Epic 4.1.0',
      connections: 6,
      tip: NodeTipInfo(height),
      syncStatus: sync,
      syncInfo: highest == null
          ? null
          : NodeSyncInfo(currentHeight: height, highestHeight: highest),
    );

void main() {
  final now = DateTime(2026, 10, 22, 12);

  LocalNodeState derive(
    BuiltInNodeState s, {
    int? directoryTip,
    int? peersMaxHeight,
    DateTime? startedAt,
  }) => deriveLocalNodeState(
    s,
    now: now,
    dataFolder: '/n/main',
    chainDataPath: '/n/main/chain_data',
    directoryTip: directoryTip,
    peersMaxHeight: peersMaxHeight,
    startedAt: startedAt,
  );

  group('phase mapping', () {
    const running = NodeStatusKind.running;
    for (final (name, s, dirTip, phase) in <(String, BuiltInNodeState, int?, LocalNodePhase)>[
      ('off', const BuiltInNodeState.off(), null, LocalNodePhase.stopped),
      ('stopped', const BuiltInNodeState(NodeStatusKind.stopped), null, LocalNodePhase.stopped),
      ('starting', const BuiltInNodeState(NodeStatusKind.starting), null, LocalNodePhase.starting),
      (
        'syncing',
        const BuiltInNodeState(NodeStatusKind.syncing, height: 10, highest: 500, phase: 'header_sync'),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'syncing even when it says ready',
        const BuiltInNodeState(NodeStatusKind.syncing, height: 10, readyForTxs: true),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'running, ready, height > 0, network unknown',
        const BuiltInNodeState(running, height: 500, readyForTxs: true),
        null,
        LocalNodePhase.synced,
      ),
      (
        'running, ready, 10 behind',
        const BuiltInNodeState(running, height: 500, readyForTxs: true),
        510,
        LocalNodePhase.synced,
      ),
      (
        'running, ready, 11 behind',
        const BuiltInNodeState(running, height: 500, readyForTxs: true),
        511,
        LocalNodePhase.syncing,
      ),
      (
        'running, ready, ahead of the directory',
        const BuiltInNodeState(running, height: 600, readyForTxs: true),
        500,
        LocalNodePhase.synced,
      ),
      (
        'running at height 0 (O2)',
        const BuiltInNodeState(running, height: 0, readyForTxs: true),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'running without a height',
        const BuiltInNodeState(running, readyForTxs: true),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'running, not ready',
        const BuiltInNodeState(running, height: 500, readyForTxs: false),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'running, old node (ready null), no_sync',
        BuiltInNodeState(running, height: 500, status: status('no_sync', 500)),
        null,
        LocalNodePhase.synced,
      ),
      (
        'running, old node (ready null), no status',
        const BuiltInNodeState(running, height: 500),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'running, old node, body_sync',
        BuiltInNodeState(running, height: 500, status: status('body_sync', 500, highest: 900)),
        null,
        LocalNodePhase.syncing,
      ),
      (
        'stalled',
        const BuiltInNodeState(NodeStatusKind.stalled, height: 5),
        null,
        LocalNodePhase.error,
      ),
      (
        'failed',
        const BuiltInNodeState(
          NodeStatusKind.failed,
          failure: NodeFailure.portInUse,
          reason: 'Port 3413 in use',
        ),
        null,
        LocalNodePhase.error,
      ),
    ]) {
      test(name, () {
        final d = derive(s, directoryTip: dirTip);
        expect(d.phase, phase);
        expect(d.online, phase == LocalNodePhase.synced);
      });
    }
  });

  test('every node kind is mapped', () {
    for (final k in NodeStatusKind.values) {
      expect(() => derive(BuiltInNodeState(k)), returnsNormally);
    }
  });

  test('stalled keeps its reason and says stalled', () {
    final d = derive(
      const BuiltInNodeState(NodeStatusKind.stalled, reason: 'no peers'),
    );
    expect(d.stalled, isTrue);
    expect(d.reason, 'no peers');
  });

  test('failed carries failure and reason', () {
    final d = derive(
      const BuiltInNodeState(
        NodeStatusKind.failed,
        failure: NodeFailure.diskLow,
        reason: 'Not enough free disk space',
      ),
    );
    expect(d.failure, NodeFailure.diskLow);
    expect(d.reason, 'Not enough free disk space');
    expect(d.stalled, isFalse);
  });

  test('network height is the highest of node, peers and directory', () {
    final d = derive(
      const BuiltInNodeState(NodeStatusKind.syncing, height: 100, highest: 900),
      peersMaxHeight: 950,
      directoryTip: 940,
    );
    expect(d.networkHeight, 950);
    expect(d.blocksBehind, 850);
  });

  test('progress, peers and version come from the status', () {
    final d = derive(
      BuiltInNodeState(
        NodeStatusKind.syncing,
        height: 0,
        phase: 'header_sync',
        version: '4.1.0',
        status: status('header_sync', 0, highest: 1000),
      ),
    );
    expect(d.progress?.stage, SyncStage.headers);
    expect(d.networkHeight, 1000);
    expect(d.peers, 6);
    expect(d.version, '4.1.0');
  });

  test('uptime while live, none when stopped', () {
    final started = now.subtract(const Duration(minutes: 3));
    expect(
      derive(const BuiltInNodeState(NodeStatusKind.syncing), startedAt: started)
          .uptime,
      const Duration(minutes: 3),
    );
    final stopped = derive(
      const BuiltInNodeState(NodeStatusKind.stopped),
      startedAt: started,
    );
    expect(stopped.uptime, isNull);
    expect(stopped.startedAt, isNull);
  });

  test('ETA and rate only while syncing', () {
    LocalNodeState d(NodeStatusKind k) => deriveLocalNodeState(
      BuiltInNodeState(k, height: 5, readyForTxs: true),
      now: now,
      dataFolder: '/n',
      chainDataPath: '/n/c',
      eta: const Duration(minutes: 9),
      stageRate: 1234,
      chainDataBytes: 10,
      chainDataBytesAtStart: 4,
      freeBytes: 99,
      restartNeeded: true,
      userToml: true,
    );
    final syncing = d(NodeStatusKind.syncing);
    expect(syncing.eta, const Duration(minutes: 9));
    expect(syncing.stageRate, 1234);
    expect(syncing.chainDataBytes, 10);
    expect(syncing.chainDataBytesAtStart, 4);
    expect(syncing.freeBytes, 99);
    expect(syncing.restartNeeded, isTrue);
    expect(syncing.userToml, isTrue);
    final synced = d(NodeStatusKind.running);
    expect(synced.phase, LocalNodePhase.synced);
    expect(synced.eta, isNull);
    expect(synced.stageRate, isNull);
  });

  test('equal inputs give equal states', () {
    const s = BuiltInNodeState(NodeStatusKind.running, height: 5, readyForTxs: true);
    expect(derive(s), derive(s));
    expect(derive(s).hashCode, derive(s).hashCode);
  });
}
