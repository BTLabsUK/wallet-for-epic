// The wallet's side of the public-node fallback (D-7): every node move runs alone, the latest
// decision wins, a user's pick beats a fallback switch under way, a decision that came in while
// the built-in node started is applied once it is on, and no switch cuts a send in flight.

import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show SendRequest, SendFailed, TxMethod;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _remote = 'https://node.example';
const _public = 'https://node.epiccash.com:3413';
const _local = 'http://127.0.0.1:3413';
const _other = 'https://other.example';
final _epicbox = '${'2' * 52}@epicbox.example';

class _Session extends core.FakeWalletSession {
  /// Holds every Epicbox send until completed.
  Completer<void>? sendGate;
  int sendsStarted = 0;

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
  Future<core.NodeTip> nodeTip({required core.WalletConfig config}) async => core.NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

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
    walletDir: (chain) async => '${dir.path}/wallets/${chain.name}',
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
    await secrets.write('app.node.mainnet', _remote);
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
    expect(await secrets.read('app.node.mainnet'), _remote);
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
    expect(await secrets.read('app.node.mainnet'), _local);
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
    expect(await secrets.read('app.node.mainnet'), _other);
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
    expect(await secrets.read('app.node.mainnet'), _local);
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
}
