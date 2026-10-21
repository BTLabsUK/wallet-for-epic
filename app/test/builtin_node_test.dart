import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;

class FakeProcess implements NodeProcess {
  FakeProcess(this.pid, {this.exitsOnTerminate = true});

  @override
  final int pid;
  final bool exitsOnTerminate;
  final Completer<int> _exit = Completer<int>();
  int terminated = 0;
  int killed = 0;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  List<String> get tail => const [];

  @override
  void terminate() {
    terminated++;
    if (exitsOnTerminate) exit(0);
  }

  @override
  void kill() {
    killed++;
    exit(137);
  }

  void exit(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }
}

void main() {
  late Directory dir;
  late String binary;
  late DateTime now;
  late List<FakeProcess> spawned;
  late List<List<String>> spawnArgs;
  late Map<String, dynamic>? Function(String method, bool owner) answer;
  late bool portBusy;
  late int? free;
  late int pidCounter;
  var exitsOnTerminate = true;

  BuiltInNode make({
    Chain chain = Chain.floonet,
    String? bin,
    Duration killAfter = const Duration(milliseconds: 50),
  }) => BuiltInNode(
    root: '${dir.path}/node',
    binary: bin ?? binary,
    chain: chain,
    autoPoll: false,
    killAfter: killAfter,
    clock: () => now,
    portInUse: (_) async => portBusy,
    freeBytes: (_) async => free,
    api: (port, method, {required owner, secret}) async =>
        answer(method, owner),
    startProcess: (exe, args, {required workingDirectory}) async {
      spawnArgs.add(args);
      final p = FakeProcess(++pidCounter, exitsOnTerminate: exitsOnTerminate);
      spawned.add(p);
      return p;
    },
  );

  Map<String, dynamic> status(String phase, int height, [int? highest]) => {
    'sync_status': phase,
    'tip': {'height': height},
    'sync_info': {'current_height': height, 'highest_height': highest ?? height},
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('builtin_node_test');
    binary = '${dir.path}/epic';
    File(binary).writeAsStringSync('#!/bin/sh\n');
    now = DateTime(2026, 1, 1);
    spawned = [];
    spawnArgs = [];
    portBusy = false;
    free = 100 * 1024 * 1024 * 1024;
    pidCounter = 1000;
    exitsOnTerminate = true;
    answer = (_, _) => null;
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('toml', () {
    for (final (chain, folder, api, p2p, type, seeding) in [
      (Chain.mainnet, 'main', 3413, 3414, 'Mainnet', 'DNSSeed'),
      (Chain.floonet, 'floo', 13413, 13414, 'Floonet', 'DNSSeed'),
      (Chain.usernet, 'user', 23413, 23414, 'UserTesting', 'None'),
    ]) {
      test('${chain.name} is rendered for its network', () async {
        final node = make(chain: chain);
        await node.prepareFolder();
        final toml = File('${dir.path}/node/$folder/epic-server.toml')
            .readAsStringSync();
        expect(toml, contains('chain_type = "$type"'));
        expect(toml, contains('api_http_addr = "127.0.0.1:$api"'));
        expect(toml, contains('port = $p2p'));
        expect(toml, contains('seeding_type = "$seeding"'));
        expect(toml, contains('run_tui = false'));
        expect(toml, contains('${dir.path}/node/$folder/chain_data'));
        expect(toml, contains('${dir.path}/node/$folder/.api_secret'));
        expect(toml, isNot(contains('{{')));
        expect(node.url, 'http://127.0.0.1:$api');
        expect(File('${dir.path}/node/$folder/.api_secret').readAsStringSync(),
            hasLength(20));
      });
    }

    test('a toml the user edited is kept', () async {
      final node = make();
      expect(await node.prepareFolder(), isFalse);
      final edited = '${File(node.tomlPath).readAsStringSync()}# mine\n';
      File(node.tomlPath).writeAsStringSync(edited);
      expect(await node.prepareFolder(), isTrue);
      expect(File(node.tomlPath).readAsStringSync(), edited);
    });

    test('a toml this class wrote is brought up to date', () async {
      final node = make();
      await node.prepareFolder();
      final moved = BuiltInNode(
        root: node.root,
        binary: binary,
        chain: Chain.floonet,
      );
      // same folder, same text: untouched and not "edited"
      expect(await moved.prepareFolder(), isFalse);
    });

    test('an existing toml without a hash is the user\'s', () async {
      final node = make();
      Directory(node.folder).createSync(recursive: true);
      File(node.tomlPath).writeAsStringSync('[server]\n');
      expect(await node.prepareFolder(), isTrue);
      expect(File(node.tomlPath).readAsStringSync(), '[server]\n');
    });
  });

  group('start', () {
    test('refuses when the binary is missing', () async {
      final node = make(bin: '${dir.path}/nope');
      await expectLater(
        node.start(),
        throwsA(
          isA<NodeStartException>().having(
            (e) => e.failure,
            'failure',
            NodeFailure.binaryMissing,
          ),
        ),
      );
      expect(node.state.kind, NodeStatusKind.failed);
      expect(spawned, isEmpty);
    });

    test('refuses when the API port answers and leaves that node alone', () async {
      portBusy = true;
      final node = make();
      await expectLater(
        node.start(),
        throwsA(
          isA<NodeStartException>()
              .having((e) => e.failure, 'failure', NodeFailure.portInUse)
              .having((e) => e.message, 'message', 'Port 13413 in use')
              .having((e) => e.port, 'port', 13413),
        ),
      );
      expect(spawned, isEmpty);
      await node.stop();
      expect(node.pid, isNull);
    });

    test('refuses when the disk is under the floor', () async {
      free = 1024 * 1024 * 1024;
      final node = make();
      await expectLater(
        node.start(),
        throwsA(
          isA<NodeStartException>().having(
            (e) => e.failure,
            'failure',
            NodeFailure.diskLow,
          ),
        ),
      );
      expect(node.state.failure, NodeFailure.diskLow);
      expect(spawned, isEmpty);
    });

    test('starts with the chain flag, the toml and no shell', () async {
      final floo = make();
      await floo.start();
      expect(spawnArgs.single, [
        '--floonet',
        'server',
        '--config_file',
        floo.tomlPath,
        'run',
      ]);
      await floo.stop();
      final main = make(chain: Chain.mainnet);
      await main.start();
      expect(spawnArgs.last.first, 'server');
      await main.stop();
    });
  });

  group('states', () {
    test('follow the scripted API answers', () async {
      final node = make();
      final seen = <BuiltInNodeState>[];
      node.states.listen(seen.add);
      await node.start();
      expect(node.state.kind, NodeStatusKind.starting);

      answer = (_, _) => null;
      await node.poll();
      expect(node.state.kind, NodeStatusKind.starting);

      answer = (m, owner) => owner ? status('header_sync', 10, 500) : null;
      await node.poll();
      expect(
        node.state,
        const BuiltInNodeState(
          NodeStatusKind.syncing,
          height: 10,
          highest: 500,
          phase: 'header_sync',
        ),
      );

      answer = (m, owner) => owner ? status('no_sync', 500) : null;
      await node.poll();
      expect(
        node.state,
        const BuiltInNodeState(NodeStatusKind.running, height: 500),
      );
      await node.stop();
      expect(node.state.kind, NodeStatusKind.stopped);
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((s) => s.kind), [
        NodeStatusKind.starting,
        NodeStatusKind.syncing,
        NodeStatusKind.running,
        NodeStatusKind.stopped,
      ]);
    });

    test('fall back to the foreign tip when the owner call is refused', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => owner ? null : {'height': 42};
      await node.poll();
      expect(node.state.kind, NodeStatusKind.syncing);
      expect(node.state.height, 42);
      await node.stop();
    });

    test('poll backs off while the node does not answer', () async {
      final node = make();
      await node.start();
      expect(node.nextPollDelay, const Duration(seconds: 5));
      await node.poll();
      expect(node.nextPollDelay, const Duration(seconds: 10));
      await node.poll();
      await node.poll();
      await node.poll();
      expect(node.nextPollDelay, const Duration(seconds: 30));
      answer = (_, _) => status('no_sync', 1);
      await node.poll();
      expect(node.nextPollDelay, const Duration(seconds: 5));
      await node.stop();
    });

    test('an unexpected exit is a failure', () async {
      final node = make();
      await node.start();
      spawned.single.exit(1);
      await Future<void>.delayed(Duration.zero);
      expect(node.state.failure, NodeFailure.exited);
    });
  });

  group('stall watchdog', () {
    test('restarts once when the height stands still outside safe states', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('body_sync', 100, 200);
      await node.poll();
      now = now.add(const Duration(minutes: 2));
      await node.poll();
      expect(spawned, hasLength(1));
      now = now.add(const Duration(minutes: 2));
      await node.poll();
      expect(spawned, hasLength(2));
      expect(spawned.first.terminated, 1);
      expect(node.state.kind, NodeStatusKind.starting);

      // stalls again: reported, not restarted again
      answer = (m, owner) => status('body_sync', 100, 200);
      await node.poll();
      now = now.add(const Duration(minutes: 4));
      await node.poll();
      expect(spawned, hasLength(2));
      expect(node.state.kind, NodeStatusKind.stalled);
      await node.stop();
    });

    test('does not restart in a safe sync state', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('txhashset_download', 100, 200);
      for (var i = 0; i < 5; i++) {
        await node.poll();
        now = now.add(const Duration(minutes: 2));
      }
      expect(spawned, hasLength(1));
      expect(node.state.kind, NodeStatusKind.syncing);
      await node.stop();
    });

    test('restarts when the node stops answering for 3 minutes', () async {
      final node = make();
      await node.start();
      now = now.add(const Duration(minutes: 4));
      await node.poll();
      expect(spawned, hasLength(2));
      await node.stop();
    });
  });

  group('stop', () {
    test('stops only the pid it started', () async {
      final node = make();
      await node.start();
      expect(node.pid, 1001);
      await node.stop();
      expect(spawned.single.terminated, 1);
      expect(spawned.single.killed, 0);
      expect(node.pid, isNull);
      expect(File('${node.folder}/node.pid').existsSync(), isFalse);
      // a second stop touches nothing
      await node.stop();
      expect(spawned.single.terminated, 1);
    });

    test('kills a node that ignores the polite stop', () async {
      exitsOnTerminate = false;
      final node = make();
      await node.start();
      await node.stop();
      expect(spawned.single.terminated, 1);
      expect(spawned.single.killed, 1);
    });

    test('never signals anything when the port was foreign', () async {
      portBusy = true;
      final node = make();
      await node.start().then((_) {}, onError: (_) {});
      await node.stop();
      expect(spawned, isEmpty);
    });
  });

  group('disk watchdog', () {
    test('stops the node when free space drops under the floor', () async {
      final node = make();
      await node.start();
      answer = (_, _) => status('no_sync', 5);
      await node.poll();
      expect(node.state.kind, NodeStatusKind.running);
      free = 1024 * 1024 * 1024;
      now = now.add(const Duration(seconds: 31));
      await node.poll();
      expect(spawned.single.terminated, 1);
      expect(node.state.kind, NodeStatusKind.failed);
      expect(node.state.failure, NodeFailure.diskLow);
      expect(node.pid, isNull);
      // the chain data is left alone
      expect(Directory(node.folder).existsSync(), isTrue);
    });
  });
}
