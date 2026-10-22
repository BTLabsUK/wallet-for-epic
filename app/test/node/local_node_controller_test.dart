import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/local_node_controller.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:epic_wallet/src/node/sync_progress.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProcess implements NodeProcess {
  FakeProcess(this.pid);

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

class NoProcesses implements ProcessInspector {
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

Map<String, dynamic> status(String sync, int height, {int? current, int? highest}) => {
  'protocol_version': 2,
  'user_agent': 'MW/Epic 4.1.0',
  'connections': 7,
  'tip': {'height': height},
  'sync_status': sync,
  'sync_info': {'current_height': current ?? height, 'highest_height': highest ?? height},
};

void main() {
  late Directory dir;
  late DateTime now;
  late MemorySecretStore store;
  late Map<String, dynamic>? Function(String method) answer;
  late int dirSizeCalls;
  late int sizeNow;
  late List<String> freeProbed;
  late int? directoryTip;
  late int pid;
  Completer<void>? gate;
  final controllers = <LocalNodeController>[];
  final nodes = <BuiltInNode>[];

  BuiltInNode makeNode() {
    final node = BuiltInNode(
      root: '${dir.path}/node',
      binary: '${dir.path}/epic',
      chain: Chain.mainnet,
      autoPoll: false,
      killAfter: const Duration(milliseconds: 50),
      killWait: const Duration(milliseconds: 50),
      clock: () => now,
      inspector: NoProcesses(),
      log: (_) {},
      portInUse: (_) async => false,
      freeBytes: (_) async => 100 << 30,
      api: (port, method, {required owner, secret}) async => answer(method),
      startProcess: (exe, args, {required workingDirectory}) async {
        final g = gate;
        if (g != null) await g.future;
        return FakeProcess(++pid);
      },
    );
    nodes.add(node);
    return node;
  }

  LocalNodeController make(
    BuiltInNode node, {
    Duration diskEvery = const Duration(minutes: 5),
  }) {
    final c = LocalNodeController(
      node,
      settings: NodeSettings(store, Chain.mainnet),
      dirSize: (d) async {
        dirSizeCalls++;
        return sizeNow;
      },
      freeBytes: (d) async {
        freeProbed.add(d);
        return 42 << 30;
      },
      directoryTip: () async => directoryTip,
      peersMaxHeight: () async => null,
      clock: () => now,
      diskEvery: diskEvery,
    );
    controllers.add(c);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('local_node_controller_test');
    File('${dir.path}/epic').writeAsStringSync('#!/bin/sh\n');
    now = DateTime(2026, 10, 22, 12);
    store = MemorySecretStore();
    answer = (_) => null;
    dirSizeCalls = 0;
    sizeNow = 1000;
    freeProbed = [];
    directoryTip = null;
    pid = 5000;
    gate = null;
  });

  tearDown(() async {
    for (final c in controllers) {
      await c.dispose();
    }
    controllers.clear();
    for (final n in nodes) {
      await n.dispose();
    }
    nodes.clear();
    dir.deleteSync(recursive: true);
  });

  test('load reads the settings into the node and measures the disk', () async {
    await NodeSettings(store, Chain.mainnet).setMaxOutbound(4);
    final node = makeNode();
    final c = make(node);
    expect(c.state.phase, LocalNodePhase.stopped);
    await c.load();
    await settle();
    expect(node.options, const NodeTomlOptions(maxOutbound: 4));
    expect(node.pid, isNull);
    expect(c.state.chainDataBytes, 1000);
    expect(c.state.chainDataBytesAtStart, 1000);
    expect(c.state.freeBytes, 42 << 30);
    expect(c.state.dataFolder, node.folder);
    expect(c.state.chainDataPath, node.chainDataPath);
    // the chain data folder does not exist yet: its nearest existing parent is probed
    expect(Directory(freeProbed.single).existsSync(), isTrue);
  });

  test('the disk is measured again on the timer; the first size stays', () async {
    final c = make(makeNode(), diskEvery: const Duration(milliseconds: 30));
    await c.load();
    await settle();
    sizeNow = 5000;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(dirSizeCalls, greaterThan(1));
    expect(c.state.chainDataBytes, 5000);
    expect(c.state.chainDataBytesAtStart, 1000);
  });

  test('no timer runs after dispose, and the node keeps running', () async {
    final node = makeNode();
    final c = make(node, diskEvery: const Duration(milliseconds: 20));
    await c.load();
    await c.start();
    final done = expectLater(c.states, emitsThrough(emitsDone));
    await c.dispose();
    await done;
    final calls = dirSizeCalls;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(dirSizeCalls, calls);
    expect(node.pid, isNotNull);
    answer = (m) => m == 'get_status' ? status('header_sync', 0, highest: 9) : null;
    await node.poll();
    await c.dispose();
  });

  test('dispose during a start leaves the start alone', () async {
    final node = makeNode();
    final c = make(node);
    await c.load();
    gate = Completer<void>();
    final started = c.start();
    await settle();
    await c.dispose();
    gate!.complete();
    await started;
    expect(node.pid, isNotNull);
  });

  test('syncing, then synced against the directory tip', () async {
    final node = makeNode();
    final c = make(node);
    final seen = <LocalNodePhase>[];
    c.states.listen((s) => seen.add(s.phase));
    await c.load();
    await c.start();
    directoryTip = 1000;
    answer = (m) => switch (m) {
      'ready_for_txs' => {'ready_for_txs': false},
      'get_status' => status('header_sync', 0, current: 400, highest: 990),
      _ => null,
    };
    await node.poll();
    await settle();
    expect(c.state.phase, LocalNodePhase.syncing);
    expect(c.state.networkHeight, 1000);
    expect(c.state.progress?.stage, SyncStage.headers);
    expect(c.state.peers, 7);

    answer = (m) => switch (m) {
      'ready_for_txs' => {'ready_for_txs': true},
      'get_status' => status('no_sync', 995),
      _ => null,
    };
    await node.poll();
    await settle();
    expect(c.state.phase, LocalNodePhase.synced);
    expect(c.state.online, isTrue);
    expect(c.state.blocksBehind, 5);
    expect(seen, containsAllInOrder([
      LocalNodePhase.starting,
      LocalNodePhase.syncing,
      LocalNodePhase.synced,
    ]));
  });

  test('ETA and stage rate from the polls', () async {
    final node = makeNode();
    final c = make(node);
    await c.load();
    await c.start();
    for (var i = 0; i <= 3; i++) {
      answer = (m) => m == 'get_status'
          ? {
              ...status('txhashset_download', 0),
              'sync_info': {'downloaded_size': i * 1000000, 'total_size': 10000000},
            }
          : null;
      await node.poll();
      await settle();
      now = now.add(const Duration(seconds: 10));
    }
    expect(c.state.stageRate, closeTo(100000, 1));
    expect(c.state.eta, const Duration(seconds: 70));
    expect(c.state.uptime, const Duration(seconds: 30));
  });

  test('setOptions persists and asks for a restart while running', () async {
    final node = makeNode();
    final c = make(node);
    await c.load();
    await c.setOptions(const NodeTomlOptions(maxInbound: 3));
    expect(await NodeSettings(store, Chain.mainnet).maxInbound(), 3);
    expect(c.state.restartNeeded, isFalse);
    await c.start();
    await c.setOptions(const NodeTomlOptions(maxInbound: 9));
    expect(c.state.restartNeeded, isTrue);
    await c.restart();
    await settle();
    expect(c.state.restartNeeded, isFalse);
    expect(node.appliedOptions, const NodeTomlOptions(maxInbound: 9));
    await c.stop();
    await settle();
    expect(c.state.phase, LocalNodePhase.stopped);
  });

  group('logTail', () {
    late LocalNodeController c;

    setUp(() {
      c = make(makeNode());
      Directory(File(c.logPath).parent.path).createSync(recursive: true);
    });

    test('no log yet is empty', () async {
      expect(await c.logTail(), isEmpty);
    });

    test('last lines, CRLF stripped', () async {
      File(c.logPath).writeAsStringSync(
        '${List.generate(10, (i) => 'line $i').join('\r\n')}\r\n',
      );
      expect(await c.logTail(lines: 3), ['line 7', 'line 8', 'line 9']);
    });

    test('reads only the end and drops the partial first line', () async {
      File(c.logPath).writeAsStringSync(
        '${'x' * 1000}\nalpha\nbeta\ngamma',
      );
      expect(await c.logTail(maxBytes: 14), ['beta', 'gamma']);
      expect(await c.logTail(maxBytes: 100000), hasLength(4));
    });
  });

  test('simpleDirSize counts files and does not follow links', () async {
    final d = Directory('${dir.path}/size')..createSync();
    File('${d.path}/a').writeAsBytesSync(List.filled(100, 1));
    Directory('${d.path}/sub').createSync();
    File('${d.path}/sub/b').writeAsBytesSync(List.filled(50, 1));
    final outside = Directory('${dir.path}/outside')..createSync();
    File('${outside.path}/big').writeAsBytesSync(List.filled(10000, 1));
    if (!Platform.isWindows) Link('${d.path}/link').createSync(outside.path);
    expect(await simpleDirSize(d.path), 150);
    expect(await simpleDirSize('${dir.path}/missing'), 0);
  });
}
