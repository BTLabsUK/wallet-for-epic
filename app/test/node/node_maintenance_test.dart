// NodeMaintenance: stop, the file work, the setting, start again; and what it refuses.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/legacy_wallets.dart' show LegacyRoots;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/chain_data.dart';
import 'package:epic_wallet/src/node/data_folder_ops.dart';
import 'package:epic_wallet/src/node/local_node_controller.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_maintenance.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

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
  void terminate() => kill();

  @override
  void kill() {
    if (!_exit.isCompleted) _exit.complete(0);
  }
}

class _NoProcesses implements ProcessInspector {
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

/// The files every node writes, with enough header bytes for a mainnet chain.
void _chain(String dir, {int extra = 0}) {
  File('$dir/lmdb/data.mdb')
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(1000 + extra, 1));
  File('$dir/header/header_head/pmmr_hash.bin')
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(64000, 2));
  for (final t in ['kernel', 'output', 'rangeproof']) {
    File('$dir/txhashset/$t/pmmr_data.bin')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(500, 3));
  }
}

void main() {
  late Directory dir;
  late MemorySecretStore store;
  late List<_Process> spawned;
  late BuiltInNode node;
  late LocalNodeController controller;
  late NodeMaintenance m;

  String own() => '${dir.path}/node/main/chain_data';

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('wfe-maint-');
    File('${dir.path}/epic').writeAsStringSync('');
    store = MemorySecretStore();
    spawned = [];
    node = BuiltInNode(
      root: '${dir.path}/node',
      binary: '${dir.path}/epic',
      chain: Chain.mainnet,
      autoPoll: false,
      killAfter: const Duration(milliseconds: 20),
      killWait: const Duration(milliseconds: 20),
      inspector: _NoProcesses(),
      log: (_) {},
      portInUse: (_) async => false,
      freeBytes: (_) async => 100 << 30,
      api: (port, method, {required owner, secret}) async => null,
      startProcess: (exe, args, {required workingDirectory}) async {
        final p = _Process(7000 + spawned.length);
        spawned.add(p);
        return p;
      },
    );
    controller = LocalNodeController(
      node,
      settings: NodeSettings(store, Chain.mainnet),
      freeBytes: (_) async => 100 << 30,
    );
    await controller.load();
    m = NodeMaintenance(
      controller,
      roots: LegacyRoots(home: '${dir.path}/home'),
      probe: (_) async => FolderLock.free,
      freeBytes: (_) async => 100 << 30,
      sameVolume: (a, b) async => false, // always the copy path, the one that can be interrupted
    );
  });

  tearDown(() async {
    await controller.dispose();
    await node.dispose();
    dir.deleteSync(recursive: true);
  });

  test('move: stop, copy, switch, old copy gone, start again on the new folder', () async {
    await controller.start();
    _chain(own());
    final target = '${dir.path}/big disk';
    expect((await m.planMove(target)).problems, isEmpty);
    await m.changeDataFolder(target, how: FolderChange.move);
    expect(Directory(own()).existsSync(), isFalse);
    expect(await chainLayoutComplete('$target/chain_data'), isTrue);
    expect(spawned, hasLength(2), reason: 'it ran before, so it runs again');
    expect(node.wantsRunning, isTrue);
    expect(File(node.tomlPath).readAsStringSync(), contains('db_root = "$target/chain_data"'));
    expect(await NodeSettings(store, Chain.mainnet).chainDataOrigin(), ChainDataOrigin.moved);
    expect(controller.state.chainDataReused, isFalse);
  });

  test('a failed move leaves the old folder in use and starts the node again on it', () async {
    await controller.start();
    _chain(own());
    final target = '${dir.path}/full';
    File('$target/chain_data/something').createSync(recursive: true);
    await expectLater(
      m.changeDataFolder(target, how: FolderChange.move),
      throwsA(isA<DataFolderException>().having((e) => e.problems, 'problems', contains(MoveProblem.targetNotEmpty))),
    );
    expect(await chainLayoutComplete(own()), isTrue);
    expect(await NodeSettings(store, Chain.mainnet).chainDataPath(), isNull);
    expect(node.chainDataPath, own());
    expect(spawned, hasLength(2));
    expect(node.wantsRunning, isTrue);
  });

  test('a stopped node stays stopped after a change', () async {
    _chain(own());
    await m.changeDataFolder('${dir.path}/other', how: FolderChange.move);
    expect(spawned, isEmpty);
    expect(controller.state.phase, LocalNodePhase.stopped);
  });

  test('pointing at a folder with chain data uses it in place, and Delete refuses it', () async {
    final theirs = '${dir.path}/their node/chain_data';
    _chain(theirs);
    await m.changeDataFolder('${dir.path}/their node', how: FolderChange.point);
    expect(controller.state.chainDataPath, theirs);
    expect(controller.state.chainDataReused, isTrue);
    await expectLater(
      m.deleteChainData(),
      throwsA(isA<DataFolderException>().having((e) => e.reason, 'reason', DataFolderFailure.foreignFolder)),
    );
    expect(await chainLayoutComplete(theirs), isTrue, reason: 'untouched');
  });

  test('pointing at an empty folder is a fresh sync of our own; Delete may delete it', () async {
    final fresh = '${dir.path}/fresh';
    Directory(fresh).createSync();
    await m.changeDataFolder(fresh, how: FolderChange.point);
    expect(controller.state.chainDataReused, isFalse);
    _chain('$fresh/chain_data');
    expect(await m.deleteChainData(), greaterThan(0));
    expect(Directory('$fresh/chain_data').existsSync(), isFalse);
  });

  test('reuse by copy: the CLI node\'s folder is only read; the node runs on its own copy', () async {
    final cli = '${dir.path}/home/.epic/main/chain_data';
    _chain(cli, extra: 77);
    final before = await dirSize(cli);
    final found = await findChainData(Chain.mainnet, roots: LegacyRoots(home: '${dir.path}/home'));
    final candidate = found.singleWhere((c) => c.source == ChainDataSource.cli);
    await m.reuseChainData(candidate, how: ReuseMode.copy);
    expect(await dirSize(cli), before);
    expect(await chainLayoutComplete(own()), isTrue);
    expect(controller.state.chainDataPath, own());
    expect(controller.state.chainDataOrigin, ChainDataOrigin.own);
  });

  test('reuse in place: the CLI folder is used, never deleted, and is no move target', () async {
    final cli = '${dir.path}/home/.epic/main/chain_data';
    _chain(cli);
    final candidate = (await findChainData(Chain.mainnet, roots: LegacyRoots(home: '${dir.path}/home'))).single;
    await m.reuseChainData(candidate, how: ReuseMode.point);
    expect(controller.state.chainDataReused, isTrue);
    await expectLater(m.deleteChainData(), throwsA(isA<DataFolderException>()));
    expect(await chainLayoutComplete(cli), isTrue);
    expect(
      (await m.planMove('${dir.path}/home/.epic/floo')).problems,
      [MoveProblem.targetForeign],
    );
  });

  test('delete: own folder, node stopped and left stopped, bytes back', () async {
    await controller.start();
    _chain(own());
    final freed = await m.deleteChainData();
    expect(freed, greaterThan(64000));
    expect(Directory(own()).existsSync(), isFalse);
    expect(node.wantsRunning, isFalse);
    expect(spawned, hasLength(1));
  });

  test('a hand-edited toml: nothing is moved, and the reason says so', () async {
    _chain(own());
    await node.prepareFolder();
    File(node.tomlPath).writeAsStringSync('${File(node.tomlPath).readAsStringSync()}\n# mine\n');
    await expectLater(
      m.changeDataFolder('${dir.path}/x', how: FolderChange.move),
      throwsA(isA<DataFolderException>().having((e) => e.reason, 'reason', DataFolderFailure.userToml)),
    );
    await expectLater(m.deleteChainData(), throwsA(isA<DataFolderException>()));
    expect(await chainLayoutComplete(own()), isTrue);
  });

  test('a start during a copy cancels the copy; the source is whole', () async {
    final cli = '${dir.path}/home/.epic/main/chain_data';
    _chain(cli);
    final candidate = (await findChainData(Chain.mainnet, roots: LegacyRoots(home: '${dir.path}/home'))).single;
    var started = false;
    await expectLater(
      m.reuseChainData(
        candidate,
        how: ReuseMode.copy,
        progress: (done, total) {
          if (!started) {
            started = true;
            unawaited(controller.start()); // the wallet starting it meanwhile
          }
        },
      ),
      throwsA(isA<DataFolderException>().having((e) => e.reason, 'reason', DataFolderFailure.cancelled)),
    );
    expect(await chainLayoutComplete(cli), isTrue);
    expect(await chainLayoutComplete(own()), isFalse);
    expect(Directory('${own()}.partial').existsSync(), isFalse);
  });
}
