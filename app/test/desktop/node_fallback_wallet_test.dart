// SPDX-License-Identifier: Apache-2.0
// The wallet's side of the public-node fallback: every node move runs alone, the latest
// decision wins, a user's pick beats a fallback switch under way, a decision that came in while
// the built-in node started is applied once it is on, and no switch cuts a send in flight.

import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show DeskError, ScanStep, SendRequest, SendFailed, TxMethod;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/server_list_file.dart' show useServerValues;

const _password = 'test-pass-1234';
const _remote = 'https://node.example';
const _public = 'https://node.epic.invalid:3413';
const _local = 'http://127.0.0.1:3413';
const _other = 'https://other.example';
final _epicbox = '${'2' * 52}@epicbox.example';

class _Session extends core.FakeWalletSession {
  /// Holds every Epicbox send until completed.
  Completer<void>? sendGate;
  int sendsStarted = 0;

  /// A scan that runs until [cancelScan].
  StreamController<core.ScanProgress>? scanning;
  int cancelScans = 0;

  @override
  Stream<core.ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    final c = scanning = StreamController<core.ScanProgress>();
    return c.stream;
  }

  @override
  void cancelScan() {
    cancelScans++;
    scanning?.close();
  }

  @override
  Future<core.TxEntry> sendEpicbox({required BigInt amount, required BigInt minimumConfirmations, required String address, String? message, core.SendOptions? options}) async {
    sendsStarted++;
    await sendGate?.future;
    throw const core.WalletError(kind: core.WalletErrorKind.transportFailed, message: 'relay down');
  }
}

class _Opens extends core.FakeWalletService {
  _Opens(_Session s) : super(password: _password, session: s);

  final List<String> nodeUrls = [];

  /// Holds the opening on a node URL until completed.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async => core.NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    nodeUrls.add(config.nodeUrl);
    await gates[config.nodeUrl]?.future;
    return super.open(config: config, password: password);
  }
}

class _Process implements NodeProcess {
  _Process(this.pid);

  @override
  final int pid;
  final Completer<int> _exit = Completer<int>();

  @override
  Future<int> get exitCode => _exit.future;

  @override
  List<String> get tail => const [];

  @override
  void terminate() {
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

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late Directory dir;
  late MemorySecretStore secrets;
  late _Session session;
  late _Opens service;
  late int spawned;
  Completer<void>? startGate;

  BuiltInNode node(Chain chain) => BuiltInNode(
    root: '${dir.path}/node',
    binary: '${dir.path}/epic',
    chain: chain,
    autoPoll: false,
    killWait: const Duration(milliseconds: 20),
    exitPoll: const Duration(milliseconds: 5),
    inspector: _NoOrphans(),
    portInUse: (_) async => false,
    freeBytes: (_) async => 100 * 1024 * 1024 * 1024,
    api: (port, method, {required owner, secret}) async => null,
    startProcess: (exe, args, {required workingDirectory}) async {
      final g = startGate;
      if (g != null) await g.future;
      return _Process(4000 + spawned++);
    },
  );

  LepicDeskWallet make() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async => WalletRegistry.firstWalletDir(dir.path, chain),
    secrets: secrets,
    filesDir: () async => dir,
    nodePoll: const Duration(hours: 1),
    builtInNode: (chain) async => node(chain),
  );

  /// Unlocked, the built-in node on and in use.
  Future<LepicDeskWallet> onLocal() async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    await w.useBuiltInNode(true);
    expect(service.nodeUrls.last, _local);
    return w;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('desk-fallback-test-');
    File('${dir.path}/epic').writeAsStringSync('');
    secrets = MemorySecretStore();
    hostSettings = hostSettings.withValues(useServerValues(hostSettings, node: _remote));
    session = _Session();
    service = _Opens(session)..existingWallets.add('${dir.path}/wallets/mainnet');
    spawned = 0;
    startGate = null;
  });

  tearDown(() async {
    await stopAllBuiltInNodes();
    await dir.delete(recursive: true);
  });

  test('built-in node off: a fallback decision moves nothing', () async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    final opens = service.nodeUrls.length;
    await w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await w.applyNodeFallback(usePublic: false);
    expect(service.nodeUrls.length, opens);
    expect(hostSettings.nodeUse, _remote);
    await w.dispose();
  });

  test('to the public node and back, one reopen each; a repeat moves nothing', () async {
    final w = await onLocal();
    final opens = service.nodeUrls.length;
    await w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await w.applyNodeFallback(usePublic: true, publicUrl: _public);
    expect(service.nodeUrls.sublist(opens), [_public]);
    await w.applyNodeFallback(usePublic: false);
    expect(service.nodeUrls.sublist(opens), [_public, _local]);
    expect(hostSettings.nodeUse, _local);
    await w.dispose();
  });

  test('decisions queued behind a switch: only the latest moves the wallet', () async {
    final w = await onLocal();
    final opens = service.nodeUrls.length;
    final g = service.gates[_public] = Completer<void>();
    final first = w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await _settle();
    final back = w.applyNodeFallback(usePublic: false);
    final again = w.applyNodeFallback(usePublic: true, publicUrl: _public);
    g.complete();
    await Future.wait([first, back, again]);
    // The wallet was on the public node when the latest (public) came up: nothing more.
    expect(service.nodeUrls.sublist(opens), [_public]);
    await w.dispose();
  });

  test("a user's pick during a fallback switch wins", () async {
    final w = await onLocal();
    final g = service.gates[_public] = Completer<void>();
    final fallback = w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await _settle();
    final pick = w.useNode(_other);
    await _settle();
    g.complete();
    await Future.wait([fallback, pick]);
    expect(service.nodeUrls.last, _other);
    expect(hostSettings.nodeUse, _other);
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'false');
    // A later decision finds the built-in node off and leaves the pick alone.
    final opens = service.nodeUrls.length;
    await w.applyNodeFallback(usePublic: false);
    expect(service.nodeUrls.length, opens);
    await w.dispose();
  });

  test('a decision while the built-in node starts is applied once it is on', () async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    w.nodeWhileSyncing = () async => _public;
    final g = startGate = Completer<void>();
    final on = w.useBuiltInNode(true);
    await _settle();
    // The local node turned synced meanwhile.
    await w.applyNodeFallback(usePublic: false);
    g.complete();
    await on;
    await _settle();
    expect(service.nodeUrls.reversed.take(2).toList().reversed, [_public, _local]);
    expect(hostSettings.nodeUse, _local);
    expect(await secrets.read(builtInNodeSettingKey(Chain.mainnet)), 'true');
    await w.dispose();
  });

  test('turning it on reads the public node only when the local one is not synced', () async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    w.nodeWhileSyncing = () async => null;
    await w.useBuiltInNode(true);
    expect(service.nodeUrls.last, _local);
    await w.dispose();
  });

  test('no switch while a send is in flight: it happens after the send ends', () async {
    final w = await onLocal();
    final opens = service.nodeUrls.length;
    final disposed = session.disposeCalls;
    final g = session.sendGate = Completer<void>();
    final send = w.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: _epicbox));
    await _settle();
    expect(session.sendsStarted, 1);
    final fallback = w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await _settle();
    expect(service.nodeUrls.length, opens, reason: 'waits for the send');
    expect(session.disposeCalls, disposed);
    g.complete();
    expect(await send, isA<SendFailed>());
    await fallback;
    expect(service.nodeUrls.sublist(opens), [_public]);
    await w.dispose();
  });

  test('a pending node pick is not held off by sends that keep arriving', () async {
    final w = await onLocal();
    final opens = service.nodeUrls.length;
    final g = session.sendGate = Completer<void>();
    SendRequest req() => SendRequest(method: TxMethod.epicbox, amount: 1000, to: _epicbox);
    final first = w.send(req());
    await _settle();
    final pick = w.useNode(_other);
    await _settle();
    // Sends arriving while the pick waits do not start: the pick goes first.
    final later = [w.send(req()), w.send(req())];
    await _settle();
    expect(session.sendsStarted, 1);
    expect(service.nodeUrls.length, opens);
    g.complete();
    await pick;
    expect(service.nodeUrls.sublist(opens), [_other], reason: 'the switch ran before the later sends');
    expect(await first, isA<SendFailed>());
    for (final r in await Future.wait(later)) {
      expect(r, isA<SendFailed>());
    }
    expect(session.sendsStarted, 3);
    await w.dispose();
  });

  test('a send started during a switch waits for the new session', () async {
    final w = await onLocal();
    final g = service.gates[_public] = Completer<void>();
    final fallback = w.applyNodeFallback(usePublic: true, publicUrl: _public);
    await _settle();
    final send = w.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: _epicbox));
    await _settle();
    expect(session.sendsStarted, 0);
    g.complete();
    await fallback;
    expect(await send, isA<SendFailed>());
    expect(session.sendsStarted, 1);
    await w.dispose();
  });

  test('a lock stops a balance scan instead of waiting for it; the payment toast is not for scans', () async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    final steps = <ScanStep>[];
    final scan = w.rescan().listen(steps.add);
    await _settle();
    expect(session.scanning, isNotNull);
    expect(w.busy, isFalse, reason: 'a scan is not a payment');
    await w.lock().timeout(const Duration(seconds: 2));
    expect(session.cancelScans, 1);
    await scan.cancel();
    await w.dispose();
  });

  test('a node pick during a scan stops the scan and moves at once', () async {
    final w = make();
    expect(await w.unlock(_password), isTrue);
    final scan = w.rescan().listen((_) {});
    await _settle();
    final opens = service.nodeUrls.length;
    await w.useNode(_other).timeout(const Duration(seconds: 2));
    expect(session.cancelScans, 1);
    expect(service.nodeUrls.sublist(opens), [_other]);
    await scan.cancel();
    await w.dispose();
  });

  test('a scan is refused while the wallet locks, and does not slip in during a switch', () async {
    final w = await onLocal();
    final g = session.sendGate = Completer<void>();
    final send = w.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: _epicbox));
    await _settle();
    final lock = w.lock();
    await expectLater(w.rescan().first, throwsA(isA<DeskError>().having((e) => e.locked, 'locked', isTrue)));
    g.complete();
    await send;
    await lock;
    await w.dispose();
  });

  test('two locks at once share one: the second does not end the first’s refusal early', () async {
    final w = await onLocal();
    final g = session.sendGate = Completer<void>();
    final send = w.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: _epicbox));
    await _settle();
    final first = w.lock();
    final second = w.lock();
    g.complete();
    await send;
    await Future.wait([first, second]);
    final disposed = session.disposeCalls;
    await w.lock();
    expect(session.disposeCalls, disposed, reason: 'locked once, not twice');
    await w.dispose();
  });
}
