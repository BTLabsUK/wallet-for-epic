// SPDX-License-Identifier: Apache-2.0
// The desktop adapter turning the built-in node on and off: the node starts before the wallet
// moves to it, the wallet goes back to its old node when it is turned off, and a node that cannot
// start leaves everything as it was.

import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show DeskError, ServiceHealth;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/server_list_file.dart' show useServerValues;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _remote = 'https://node.example';

class _Opens extends core.FakeWalletService {
  _Opens() : super(password: _password);

  final List<String> nodeUrls = [];

  /// The height the node reports; 0 while a local node still downloads the chain.
  BigInt tip = BigInt.from(2500000);

  /// What the node says of being ready for transactions; null for nodes that do not say.
  bool? ready;

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async => core.NodeTip(height: tip, nodeVersion: '3.6.0', readyForTxs: ready);

  /// A node URL the wallet cannot open on.
  String? failOn;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) {
    nodeUrls.add(config.nodeUrl);
    if (config.nodeUrl == failOn) {
      throw const core.WalletError(kind: core.WalletErrorKind.nodeUnreachable, message: 'down');
    }
    return super.open(config: config, password: password);
  }
}

class _Process implements NodeProcess {
  _Process(this.pid);

  @override
  final int pid;
  final Completer<int> _exit = Completer<int>();
  int terminated = 0;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  List<String> get tail => const [];

  @override
  void terminate() {
    terminated++;
    if (!_exit.isCompleted) _exit.complete(0);
  }

  @override
  void kill() {
    if (!_exit.isCompleted) _exit.complete(137);
  }
}

class _NoOrphans implements ProcessInspector {
  @override
  Future<bool> isAlive(int pid) async => false;

  @override
  Future<String?> executable(int pid) async => null;

  @override
  Future<List<String>?> commandLine(int pid) async => null;

  @override
  void terminate(int pid) {}

  @override
  void kill(int pid) {}
}

void main() {
  late Directory dir;
  late MemorySecretStore secrets;
  late _Opens service;
  late List<_Process> spawned;
  late bool portBusy;
  Completer<void>? gate;

  BuiltInNode node(Chain chain) => BuiltInNode(
    root: '${dir.path}/node',
    binary: '${dir.path}/epic',
    chain: chain,
    autoPoll: false,
    killWait: const Duration(milliseconds: 20),
    exitPoll: const Duration(milliseconds: 5),
    inspector: _NoOrphans(),
    portInUse: (_) async => portBusy,
    freeBytes: (_) async => 100 * 1024 * 1024 * 1024,
    api: (port, method, {required owner, secret}) async => null,
    startProcess: (exe, args, {required workingDirectory}) async {
      final g = gate;
      if (g != null) await g.future;
      final p = _Process(4000 + spawned.length);
      spawned.add(p);
      return p;
    },
  );

  LepicDeskWallet make({bool withNode = true}) => LepicDeskWallet(
    service: service,
    walletDir: (chain) async => WalletRegistry.firstWalletDir(dir.path, chain),
    secrets: secrets,
    filesDir: () async => dir,
    nodePoll: const Duration(hours: 1),
    builtInNode: withNode ? (chain) async => node(chain) : null,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('desk-node-test-');
    File('${dir.path}/epic').writeAsStringSync('');
    secrets = MemorySecretStore();
    // The node in use is the first of settings.toml's Node list.
    hostSettings = hostSettings.withValues(useServerValues(hostSettings, node: _remote));
    service = _Opens()..existingWallets.add('${dir.path}/wallets/mainnet');
    spawned = [];
    portBusy = false;
    gate = null;
  });

  tearDown(() async {
    await stopAllBuiltInNodes();
    await dir.delete(recursive: true);
  });

  test('turning it on starts the node, then moves the wallet to it', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    expect(spawned, hasLength(1));
    expect(service.nodeUrls.last, 'http://127.0.0.1:3413');
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'true');
    expect(hostSettings.nodeUse, 'http://127.0.0.1:3413');
    await wallet.dispose();
  });

  test('a local node at height 0 is Syncing, never Online', () async {
    service.tip = BigInt.zero;
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var st = await wallet.status();
    expect(st.nodeHeight, 0);
    expect(st.nodeHealth, ServiceHealth.slow, reason: 'tip 0 on the local node reads as Syncing');
    service.tip = BigInt.from(12);
    await wallet.useBuiltInNode(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    st = await wallet.status();
    expect(st.nodeHealth, ServiceHealth.ok);
    await wallet.dispose();
  });

  test('a node that says it is not ready for transactions is Syncing, at any height', () async {
    service.ready = false;
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await wallet.status()).nodeHealth, ServiceHealth.slow);
    await wallet.dispose();
  });

  test('a node that says it is ready, or says nothing, is judged by its height', () async {
    service.ready = true;
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await wallet.status()).nodeHealth, ServiceHealth.ok);
    await wallet.dispose();
  });

  test('a public node at height 0 is still Online: only the local node syncs from nothing', () async {
    service.tip = BigInt.zero;
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await wallet.status()).nodeHealth, ServiceHealth.ok);
    await wallet.dispose();
  });

  test('turning it off moves the wallet back to its old node and stops the node', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    await wallet.useBuiltInNode(false);
    expect(service.nodeUrls.last, _remote);
    expect(hostSettings.nodeUse, _remote);
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'false');
    expect(spawned.single.terminated, 1);
    await wallet.dispose();
  });

  test('a node that cannot start changes nothing', () async {
    portBusy = true;
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    final opens = service.nodeUrls.length;
    await expectLater(
      wallet.useBuiltInNode(true),
      // Worded from the failure kind (failureLine's words), not the node's English message.
      throwsA(isA<DeskError>().having((e) => e.message, 'message', contains('port 3413 is in use by another program'))),
    );
    expect(spawned, isEmpty);
    expect(service.nodeUrls.length, opens);
    expect(hostSettings.nodeUse, _remote);
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), isNull);
    await wallet.dispose();
  });

  test('picking another node turns the built-in node off', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    await wallet.useNode('https://other.example');
    expect(service.nodeUrls.last, 'https://other.example');
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'false');
    expect(spawned.single.terminated, 1);
    await wallet.dispose();
  });

  test('at launch it starts only when it was left on', () async {
    final off = make();
    await off.resumeBuiltInNode();
    expect(spawned, isEmpty);
    await off.dispose();

    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    final on = make();
    await on.resumeBuiltInNode();
    expect(spawned, hasLength(1));
    await on.dispose();
    expect(spawned.single.terminated, 1);
  });

  test('linux-04: the "Local node not started" notice goes once the node is started', () async {
    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    portBusy = true;
    final w = make();
    await w.resumeBuiltInNode();
    expect((await w.status()).notice, startsWith('Local node not started'));
    portBusy = false;
    await w.useBuiltInNode(true);
    await Future<void>.delayed(Duration.zero);
    expect((await w.status()).notice, isNull);
    await w.dispose();
  });

  test('linux-04: the notice goes when the node is stopped', () async {
    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    portBusy = true;
    final w = make();
    await w.resumeBuiltInNode();
    expect((await w.status()).notice, startsWith('Local node not started'));
    await w.useBuiltInNode(false);
    await Future<void>.delayed(Duration.zero);
    expect((await w.status()).notice, isNull);
    await w.dispose();
  });

  test('at launch it does not start when "Start with the app" is off', () async {
    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    await NodeSettings(secrets, Chain.mainnet).setStartWithApp(false);
    final w = make();
    await w.resumeBuiltInNode();
    expect(spawned, isEmpty);
    await w.dispose();
  });

  test('the saved node settings (data folder, peers) apply to the start at launch', () async {
    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    final s = NodeSettings(secrets, Chain.mainnet);
    await s.setChainDataPath('${dir.path}/elsewhere/chain_data');
    await s.setPreferredPeers(['203.0.113.9:3414']);
    final w = make();
    await w.resumeBuiltInNode();
    expect(spawned, hasLength(1));
    final toml = File('${dir.path}/node/main/epic-server.toml').readAsStringSync();
    expect(toml, contains('db_root = "${dir.path}/elsewhere/chain_data"'));
    expect(toml, contains('peers_preferred = ["203.0.113.9:3414"]'));
    await w.dispose();
  });

  test('Node only keeps the built-in node in use running; launching in Node only starts it; Kill switch stops it', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    final s = await wallet.settings();
    await wallet.saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.nodeOnly)));
    addTearDown(() => NetGate.set(NetworkMode.standard));
    expect(NetGate.restricted, isTrue);
    expect(spawned.single.terminated, 0, reason: 'its own peers are the node\'s setting');
    await wallet.syncNow();
    await wallet.dispose();
    await stopAllBuiltInNodes();
    final again = make();
    NetGate.set(NetworkMode.nodeOnly);
    await again.resumeBuiltInNode();
    expect(spawned, hasLength(2));
    await again.dispose();
    await stopAllBuiltInNodes();
    // Kill switch: no node starts, not even this computer's own.
    final killed = make();
    NetGate.set(NetworkMode.killSwitch);
    await killed.resumeBuiltInNode();
    expect(spawned, hasLength(2));
    await killed.dispose();
  });

  test('a build without the node refuses to turn it on', () async {
    final wallet = make(withNode: false);
    await expectLater(wallet.useBuiltInNode(true), throwsA(isA<DeskError>()));
    await secrets.write(builtInNodeSettingKey(Chain.mainnet), 'true');
    await wallet.resumeBuiltInNode();
    await wallet.dispose();
  });

  test('a wallet that cannot move to the node stops it and keeps the old setting', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    service.failOn = 'http://127.0.0.1:3413';
    await expectLater(wallet.useBuiltInNode(true), throwsA(isA<DeskError>()));
    expect(spawned.single.terminated, 1);
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), isNull);
    expect(hostSettings.nodeUse, _remote);
    expect(service.nodeUrls.last, _remote);
    await wallet.dispose();
  });

  test('starting a node already in use does not reopen the wallet', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    final opens = service.nodeUrls.length;
    await wallet.useBuiltInNode(true);
    expect(service.nodeUrls.length, opens);
    expect(spawned, hasLength(1));
    await wallet.dispose();
  });

  test('a failed turn-off keeps the node on and the setting true', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.useBuiltInNode(true);
    service.failOn = _remote;
    await expectLater(wallet.useBuiltInNode(false), throwsA(isA<DeskError>()));
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'true');
    expect(spawned.single.terminated, 0);
    await wallet.dispose();
  });

  test('turning it off while it starts leaves the wallet where it was', () async {
    final wallet = make();
    expect(await wallet.unlock(_password), isTrue);
    final g = gate = Completer<void>();
    final on = wallet.useBuiltInNode(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final off = wallet.useBuiltInNode(false);
    g.complete();
    await expectLater(on, throwsA(isA<DeskError>()));
    await off;
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), isNot('true'));
    expect(hostSettings.nodeUse, _remote);
    expect(service.nodeUrls.last, _remote);
    await wallet.dispose();
  });
}
