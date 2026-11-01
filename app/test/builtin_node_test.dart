// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/builtin_node_provider.dart';
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/settings_file/host_settings.dart';

import 'support/test_settings.dart';

class FakeInspector implements ProcessInspector {
  final Map<int, ({String exe, List<String> cmd})> procs = {};
  final List<int> terminated = [];
  final List<int> killed = [];
  bool exitsOnTerminate = true;

  /// Survives the kill too.
  bool immortal = false;

  /// Called when a polite stop arrives, e.g. to swap the process for a stranger's.
  void Function(int pid)? onTerminate;

  @override
  Future<bool> isAlive(int pid) async => procs.containsKey(pid);

  @override
  Future<String?> executable(int pid) async => procs[pid]?.exe;

  @override
  Future<List<String>?> commandLine(int pid) async => procs[pid]?.cmd;

  @override
  void terminate(int pid) {
    terminated.add(pid);
    onTerminate?.call(pid);
    if (exitsOnTerminate) procs.remove(pid);
  }

  @override
  void kill(int pid) {
    killed.add(pid);
    if (!immortal) procs.remove(pid);
  }
}

class FakeProcess implements NodeProcess {
  FakeProcess(
    this.pid, {
    this.exitsOnTerminate = true,
    this.exitsOnKill = true,
  });

  @override
  final int pid;
  final bool exitsOnTerminate;
  final bool exitsOnKill;
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
    if (exitsOnKill) exit(137);
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
  var exitsOnKill = true;
  late FakeInspector inspector;
  late List<int> apiPorts;
  late List<int> probedPorts;
  late int diskProbes;
  late List<String> logs;
  Set<int> busyPorts = {};
  Completer<void>? gate;

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
    killWait: const Duration(milliseconds: 50),
    exitPoll: const Duration(milliseconds: 5),
    clock: () => now,
    inspector: inspector,
    log: logs.add,
    portInUse: (port) async {
      probedPorts.add(port);
      return portBusy || busyPorts.contains(port);
    },
    freeBytes: (_) async {
      diskProbes++;
      return free;
    },
    api: (port, method, {required owner, secret}) async {
      apiPorts.add(port);
      return answer(method, owner);
    },
    startProcess: (exe, args, {required workingDirectory}) async {
      spawnArgs.add(args);
      final g = gate;
      if (g != null) await g.future;
      final p = FakeProcess(
        ++pidCounter,
        exitsOnTerminate: exitsOnTerminate,
        exitsOnKill: exitsOnKill,
      );
      spawned.add(p);
      return p;
    },
  );

  Future<void> until(bool Function() ok) async {
    for (var i = 0; i < 400 && !ok(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(ok(), isTrue);
  }

  Map<String, dynamic> status(
    String phase,
    int height, [
    int? highest,
    int connections = 5,
  ]) => {
    'sync_status': phase,
    'connections': connections,
    'tip': {'height': height},
    'sync_info': {
      'current_height': height,
      'highest_height': highest ?? height,
    },
  };

  // The nodes here are floonet's unless a test names another chain: its ports are floonet's.
  setUp(() {
    useChainConfig(Chain.floonet);
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
    exitsOnKill = true;
    inspector = FakeInspector();
    apiPorts = [];
    probedPorts = [];
    diskProbes = 0;
    logs = [];
    busyPorts = {};
    gate = null;
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
        hostSettings = testSettings();
        useChainConfig(chain);
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
        expect(
          File('${dir.path}/node/$folder/.api_secret').readAsStringSync(),
          hasLength(20),
        );
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

    test(
      'refuses when the API port answers and leaves that node alone',
      () async {
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
      },
    );

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
          connections: 5,
        ),
      );

      answer = (m, owner) => owner ? status('no_sync', 500) : null;
      await node.poll();
      expect(
        node.state,
        const BuiltInNodeState(
          NodeStatusKind.running,
          height: 500,
          connections: 5,
        ),
      );
      await node.stop();
      expect(node.state.kind, NodeStatusKind.stopped);
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((s) => s.kind), [
        NodeStatusKind.starting,
        NodeStatusKind.syncing,
        NodeStatusKind.running,
        NodeStatusKind.stopping,
        NodeStatusKind.stopped,
      ]);
    });

    test(
      'fall back to the foreign tip when the owner call is refused',
      () async {
        final node = make();
        await node.start();
        answer = (m, owner) => owner ? null : {'height': 42};
        await node.poll();
        expect(node.state.kind, NodeStatusKind.syncing);
        expect(node.state.height, 42);
        await node.stop();
      },
    );

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
    test('restarts once when it has no peers for 3 minutes', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('body_sync', 100, 200, 0);
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
      answer = (m, owner) => status('body_sync', 100, 200, 0);
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
      now = now.add(const Duration(minutes: 5, seconds: 1));
      await node.poll();
      expect(spawned.single.terminated, 1);
      expect(node.state.kind, NodeStatusKind.failed);
      expect(node.state.failure, NodeFailure.diskLow);
      expect(node.pid, isNull);
      // the chain data is left alone
      expect(Directory(node.folder).existsSync(), isTrue);
    });
  });

  group('watchdog rules of the GUI', () {
    Future<void> every(BuiltInNode node, int minutes) async {
      for (var i = 0; i < minutes; i++) {
        await node.poll();
        now = now.add(const Duration(minutes: 1));
      }
      await node.poll();
    }

    test(
      'a header sync with the tip at 0 for 5 minutes is not restarted',
      () async {
        final node = make();
        await node.start();
        answer = (m, owner) => status('header_sync', 0, 500);
        await every(node, 5);
        expect(spawned, hasLength(1));
        expect(spawned.single.terminated, 0);
        expect(node.state.phase, 'header_sync');
        expect(node.state.connections, 5);
        await node.stop();
      },
    );

    test(
      'no peers outside awaiting_peers restarts after 3 minutes, not before',
      () async {
        final node = make();
        await node.start();
        answer = (m, owner) => status('header_sync', 0, 500, 0);
        await every(node, 2);
        expect(spawned, hasLength(1));
        await every(node, 2);
        expect(spawned, hasLength(2));
        await node.stop();
      },
    );

    test('a recovered node resets the window', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('header_sync', 0, 500, 0);
      await every(node, 2);
      answer = (m, owner) => status('header_sync', 0, 500, 3);
      await node.poll();
      answer = (m, owner) => status('header_sync', 0, 500, 0);
      await every(node, 2);
      expect(spawned, hasLength(1));
      await node.stop();
    });

    test('awaiting_peers and the safe states are never restarted', () async {
      final node = make();
      await node.start();
      for (final phase in ['awaiting_peers', ...safeSyncStates]) {
        answer = (m, owner) => status(phase, 0, 0, 0);
        await every(node, 5);
      }
      expect(spawned, hasLength(1));
      await node.stop();
    });

    test('synced with tip 0 restarts', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('no_sync', 0, 100);
      await every(node, 4);
      expect(spawned, hasLength(2));
      await node.stop();
    });

    test('no highest height restarts', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('header_sync', 0, 0);
      await every(node, 4);
      expect(spawned, hasLength(2));
      await node.stop();
    });

    test('body_sync at the tip that does not finish restarts', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('body_sync', 100, 100);
      await every(node, 4);
      expect(spawned, hasLength(2));
      await node.stop();
    });

    test('body_sync that is behind the tip is left alone', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('body_sync', 100, 200);
      await every(node, 5);
      expect(spawned, hasLength(1));
      await node.stop();
    });
  });

  group('orphans', () {
    String ourCmd(BuiltInNode n) =>
        'epic --floonet server --config_file ${n.tomlPath} run';

    void orphan(BuiltInNode n, int pid, {String? exe, List<String>? cmd}) {
      Directory(n.folder).createSync(recursive: true);
      File('${n.folder}/node.pid').writeAsStringSync('$pid\n');
      inspector.procs[pid] = (
        exe: exe ?? binary,
        cmd: cmd ?? ourCmd(n).split(' '),
      );
    }

    test('our leftover node is stopped, then a fresh one starts', () async {
      final node = make();
      orphan(node, 777);
      portBusy = false;
      await node.start();
      expect(inspector.terminated, [777]);
      expect(inspector.killed, isEmpty);
      expect(spawned, hasLength(1));
      expect(File('${node.folder}/node.pid').readAsStringSync().trim(), '1001');
      await node.stop();
    });

    // linux-04: an AppImage mounts at a new /tmp/.mount_* each run, so the node left by the
    // killed run is the same binary at another path, or one whose mount is gone.
    for (final exe in ['/tmp/.mount_EarLieR/usr/bin/epic', '/tmp/.mount_EarLieR/usr/bin/epic (deleted)']) {
      test('our leftover node from an earlier AppImage mount ($exe) is stopped, then a fresh one starts', () async {
        final node = make();
        orphan(node, 777, exe: exe);
        await node.start();
        expect(inspector.terminated, [777]);
        expect(spawned, hasLength(1));
        await node.stop();
      });
    }

    test(
      'a leftover that ignores the polite stop is killed after a re-check',
      () async {
        final node = make();
        orphan(node, 777);
        inspector.exitsOnTerminate = false;
        await node.start();
        expect(inspector.terminated, [777]);
        expect(inspector.killed, [777]);
        expect(spawned, hasLength(1));
        await node.stop();
      },
    );

    test('a pid that stops being ours before the kill is not killed', () async {
      final node = make();
      orphan(node, 777);
      inspector.exitsOnTerminate = false;
      inspector.onTerminate = (pid) =>
          inspector.procs[pid] = (exe: '/usr/bin/vim', cmd: ['vim']);
      await node.start();
      expect(inspector.killed, isEmpty);
      expect(inspector.procs.containsKey(777), isTrue);
      expect(spawned, hasLength(1));
      await node.stop();
    });

    test('a leftover that will not die fails the start', () async {
      final node = make();
      orphan(node, 777);
      inspector.exitsOnTerminate = false;
      inspector.onTerminate = (_) {};
      inspector.immortal = true;
      await expectLater(
        node.start(),
        throwsA(
          isA<NodeStartException>().having(
            (e) => e.failure,
            'failure',
            NodeFailure.orphanStuck,
          ),
        ),
      );
      expect(spawned, isEmpty);
    });

    for (final (name, exe, cmd) in [
      // Our exact command line, so only the executable tells it apart.
      (
        'another executable',
        '/usr/bin/vim',
        ['epic', 'server', '--config_file', 'TOML', 'run'],
      ),
      (
        'another config file',
        null,
        [
          'epic',
          'server',
          '--config_file',
          '/elsewhere/epic-server.toml',
          'run',
        ],
      ),
      ('no run', null, <String>['epic', 'server', '--config_file', 'TOML']),
    ]) {
      test('a live pid with $name is not touched', () async {
        final node = make();
        orphan(
          node,
          555,
          exe: exe,
          cmd: cmd.map((a) => a == 'TOML' ? node.tomlPath : a).toList(),
        );
        await node.start();
        expect(inspector.terminated, isEmpty);
        expect(inspector.killed, isEmpty);
        expect(inspector.procs.containsKey(555), isTrue);
        expect(spawned, hasLength(1));
        // only our own new pid is in the file
        expect(
          File('${node.folder}/node.pid').readAsStringSync().trim(),
          '1001',
        );
        await node.stop();
      });
    }

    test('a dead pid only loses the stale file', () async {
      final node = make();
      orphan(node, 555);
      inspector.procs.remove(555);
      await node.prepareFolder();
      final other = make();
      busyPorts = {};
      portBusy = true;
      await other.start().then((_) {}, onError: (_) {});
      expect(File('${node.folder}/node.pid').existsSync(), isFalse);
      expect(inspector.terminated, isEmpty);
    });

    test(
      'a foreign process on the port is still left alone after a stale pid',
      () async {
        final node = make();
        orphan(node, 555, exe: '/usr/bin/vim', cmd: ['vim']);
        portBusy = true;
        await node.start().then((_) {}, onError: (_) {});
        expect(inspector.terminated, isEmpty);
        expect(inspector.procs.containsKey(555), isTrue);
        expect(spawned, isEmpty);
      },
    );

    test('stopAllBuiltInNodes stops every running node and waits', () async {
      final a = make();
      final b = make(chain: Chain.mainnet);
      await a.start();
      await b.start();
      await stopAllBuiltInNodes();
      expect(spawned.map((p) => p.terminated), [1, 1]);
      expect(a.pid, isNull);
      expect(b.pid, isNull);
      expect(a.state.kind, NodeStatusKind.stopped);
    });
  });

  group('start and stop races', () {
    test('a second start while one is pending spawns once', () async {
      gate = Completer<void>();
      final node = make();
      final a = node.start();
      final b = node.start();
      await until(() => spawnArgs.isNotEmpty);
      gate!.complete();
      await Future.wait([a, b]);
      await node.start();
      expect(spawnArgs, hasLength(1));
      expect(spawned, hasLength(1));
      await node.stop();
    });

    test('stop during a start leaves nothing running', () async {
      gate = Completer<void>();
      final node = make();
      final started = node.start();
      await until(() => spawnArgs.isNotEmpty);
      final stopped = node.stop();
      gate!.complete();
      await started;
      await stopped;
      expect(spawned.single.terminated, 1);
      expect(node.pid, isNull);
      expect(node.state.kind, NodeStatusKind.stopped);
      expect(File('${node.folder}/node.pid').existsSync(), isFalse);
    });

    test('stop during a watchdog restart leaves nothing running', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => status('body_sync', 100, 200, 0);
      await node.poll();
      now = now.add(const Duration(minutes: 4));
      gate = Completer<void>();
      final polled = node.poll();
      await until(() => spawnArgs.length == 2);
      final stopped = node.stop();
      gate!.complete();
      await polled;
      await stopped;
      expect(spawned, hasLength(2));
      expect(spawned.every((p) => p.terminated == 1), isTrue);
      expect(node.pid, isNull);
      expect(node.state.kind, NodeStatusKind.stopped);
    });

    test('dispose waits for a start in flight', () async {
      gate = Completer<void>();
      final node = make();
      final started = node.start();
      await until(() => spawnArgs.isNotEmpty);
      final disposed = node.dispose();
      gate!.complete();
      await started;
      await disposed;
      expect(spawned.single.terminated, 1);
      expect(node.pid, isNull);
    });

    test('a stop while the node exits waits for its exit (closing the app mid-switch)', () async {
      exitsOnTerminate = false;
      final node = make(killAfter: const Duration(seconds: 5));
      await node.start();
      final first = node.stop();
      await until(() => spawned.single.terminated == 1);
      expect(node.state.kind, NodeStatusKind.stopping);
      var second = false;
      final again = node.stop().then((_) => second = true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(second, isFalse, reason: 'the old process still runs');
      spawned.single.exit(0);
      await Future.wait([first, again]);
      expect(spawned.single.killed, 0);
      expect(node.state.kind, NodeStatusKind.stopped);
    });

    test('a start while the old node exits begins after its exit', () async {
      exitsOnTerminate = false;
      final node = make(killAfter: const Duration(seconds: 5));
      await node.start();
      final stopped = node.stop();
      await until(() => spawned.single.terminated == 1);
      final started = node.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(spawned, hasLength(1), reason: 'the old one holds the ports and the chain data');
      spawned.single.exit(0);
      await Future.wait([stopped, started]);
      expect(spawned, hasLength(2));
      expect(node.pid, spawned.last.pid);
      // The old stop's end does not mark the new node stopped.
      expect(node.state.kind, isNot(NodeStatusKind.stopped));
      final last = node.stop();
      await until(() => spawned.last.terminated == 1);
      spawned.last.exit(0);
      await last;
    });

    test('start works again after a stop', () async {
      final node = make();
      await node.start();
      await node.stop();
      await node.start();
      expect(spawned, hasLength(2));
      expect(node.pid, 1002);
      await node.stop();
    });
  });

  group('force kill', () {
    test('keeps the pid file when the exit is not confirmed', () async {
      exitsOnTerminate = false;
      exitsOnKill = false;
      final node = make();
      await node.start();
      await node.stop();
      expect(spawned.single.killed, 1);
      expect(File('${node.folder}/node.pid').existsSync(), isTrue);
    });

    test('removes the pid file once the killed process has exited', () async {
      exitsOnTerminate = false;
      final node = make();
      await node.start();
      await node.stop();
      expect(spawned.single.killed, 1);
      expect(File('${node.folder}/node.pid').existsSync(), isFalse);
    });
  });

  group('disk probe', () {
    test('runs every 5 minutes, not every 30 seconds', () async {
      final node = make();
      await node.start();
      answer = (_, _) => status('no_sync', 5);
      final atStart = diskProbes;
      now = now.add(const Duration(seconds: 31));
      await node.poll();
      now = now.add(const Duration(minutes: 4));
      await node.poll();
      expect(diskProbes, atStart);
      now = now.add(const Duration(minutes: 1));
      await node.poll();
      expect(diskProbes, atStart + 1);
      await node.stop();
    });

    test(
      'an unknown free space starts the node, says so and logs once',
      () async {
        free = null;
        final node = make();
        await node.start();
        answer = (_, _) => status('no_sync', 5);
        await node.poll();
        expect(node.state.kind, NodeStatusKind.running);
        expect(node.state.diskUnknown, isTrue);
        now = now.add(const Duration(minutes: 6));
        await node.poll();
        expect(logs.where((l) => l.contains('unknown')), hasLength(1));
        await node.stop();
      },
    );
  });

  group('ports', () {
    test('the P2P port in use refuses the start', () async {
      busyPorts = {13414};
      final node = make();
      await expectLater(
        node.start(),
        throwsA(
          isA<NodeStartException>()
              .having((e) => e.failure, 'failure', NodeFailure.portInUse)
              .having((e) => e.message, 'message', 'Port 13414 in use')
              .having((e) => e.port, 'port', 13414),
        ),
      );
      expect(spawned, isEmpty);
    });

    test('a user toml that moves the ports is followed', () async {
      final node = make();
      await node.prepareFolder();
      final moved = File(node.tomlPath)
          .readAsStringSync()
          .replaceFirst('127.0.0.1:13413', '127.0.0.1:4444')
          .replaceFirst('port = 13414', 'port = 4445');
      File(node.tomlPath).writeAsStringSync(moved);
      busyPorts = {13413};
      await node.start();
      expect(probedPorts, [4444, 4445]);
      expect(node.url, 'http://127.0.0.1:4444');
      answer = (_, _) => status('no_sync', 5);
      await node.poll();
      expect(apiPorts, everyElement(4444));
      expect(apiPorts, isNotEmpty);
      await node.stop();
    });
  });

  group('toml and folder', () {
    test('has no foundation_path', () {
      expect(make().renderToml(), isNot(contains('foundation')));
    });

    test('a crash between the hash and the toml does not freeze it', () async {
      final node = make();
      await node.prepareFolder();
      final old = File(node.tomlPath).readAsStringSync();
      // an older toml of ours, with the hash file as it is after the first write of an update
      final older = old.replaceFirst('Floonet', 'Floonet # older');
      File(node.tomlPath).writeAsStringSync(older);
      File('${node.folder}/epic-server.toml.sha256')
          .writeAsStringSync('${_sha(older)}\n${_sha(old)}\n');
      expect(await node.prepareFolder(), isFalse);
      expect(File(node.tomlPath).readAsStringSync(), old);
      expect(
        File('${node.folder}/epic-server.toml.sha256')
            .readAsStringSync()
            .trim(),
        _sha(old),
      );
      expect(
        File('${node.folder}/epic-server.toml.sha256.tmp').existsSync(),
        isFalse,
      );
    });

    test('the secret is private and the folder owner-only', () async {
      final node = make();
      await node.prepareFolder();
      if (Platform.isWindows) return;
      expect(File('${node.folder}/.api_secret').statSync().mode & 0x1ff, 0x180);
      expect(Directory(node.folder).statSync().mode & 0x1ff, 0x1c0);
    });
  });

  group('toml options', () {
    test('without options the toml is as it always was', () async {
      final node = make();
      final toml = node.renderToml();
      expect(toml, isNot(contains('peers_preferred')));
      expect(toml, isNot(contains('peer_max_')));
      expect(toml, isNot(contains('{{')));
      expect(
        toml,
        contains(
          'capabilities = "HEADER_HIST | TXHASHSET_HIST | PEER_LIST | TX_KERNEL_HASH | HEADER_FASTSYNC"\n\n[server.pool_config]',
        ),
      );
    });

    test('peers, peer counts and the chain data folder are written', () {
      final node = make()
        ..options = const NodeTomlOptions(
          chainDataPath: '/data/epic chain',
          preferredPeers: [
            '1.2.3.4:3414',
            ' [2001:db8::1]:3414 ',
            'example.com:3414',
            '1.2.3.4',
            '1.2.3.4:99999',
            '[1.2.3.4]:3414',
            '1.2.3.4:3414',
          ],
          maxInbound: 12,
          maxOutbound: 8,
        );
      final toml = node.renderToml();
      final p2p = toml.substring(
        toml.indexOf('[server.p2p_config]'),
        toml.indexOf('[server.pool_config]'),
      );
      expect(
        p2p,
        contains('peers_preferred = ["1.2.3.4:3414", "[2001:db8::1]:3414"]\n'),
      );
      expect(p2p, contains('peer_max_inbound_count = 12\n'));
      expect(p2p, contains('peer_max_outbound_count = 8\n'));
      expect(toml, contains('db_root = "/data/epic chain"'));
      expect(node.chainDataPath, '/data/epic chain');
      expect(logs.where((l) => l.contains('left out')), hasLength(4));
    });

    test('peer addresses', () {
      for (final ok in ['1.2.3.4:1', '[::1]:3414', '[2001:db8::1]:65535']) {
        expect(isPeerAddress(ok), isTrue, reason: ok);
      }
      for (final bad in [
        '',
        '1.2.3.4',
        '1.2.3.4:0',
        '1.2.3.4:65536',
        '999.2.3.4:3414',
        '::1:3414',
        '[1.2.3.4]:3414',
        'host:3414',
        '1.2.3.4:34a',
      ]) {
        expect(isPeerAddress(bad), isFalse, reason: bad);
      }
    });

    test('options equality', () {
      expect(
        const NodeTomlOptions(preferredPeers: ['1.2.3.4:1'], maxInbound: 3),
        NodeTomlOptions(preferredPeers: ['1.2.3.4:1'], maxInbound: 3),
      );
      expect(
        const NodeTomlOptions(preferredPeers: ['1.2.3.4:1']),
        isNot(const NodeTomlOptions(preferredPeers: ['1.2.3.4:2'])),
      );
      expect(
        const NodeTomlOptions(maxOutbound: 1).copyWith(maxOutbound: () => null),
        const NodeTomlOptions(),
      );
    });

    test('changed options rewrite our toml at the next start', () async {
      final node = make();
      await node.start();
      expect(node.appliedOptions, const NodeTomlOptions());
      expect(node.restartNeeded, isFalse);
      node.options = const NodeTomlOptions(maxOutbound: 4);
      expect(node.restartNeeded, isTrue);
      expect(
        File(node.tomlPath).readAsStringSync(),
        isNot(contains('peer_max_outbound_count')),
      );
      await node.restart();
      expect(
        File(node.tomlPath).readAsStringSync(),
        contains('peer_max_outbound_count = 4'),
      );
      expect(node.appliedOptions, const NodeTomlOptions(maxOutbound: 4));
      expect(node.restartNeeded, isFalse);
      expect(node.userToml, isFalse);
      await node.stop();
      expect(node.restartNeeded, isFalse);
      expect(node.appliedOptions, isNull);
    });

    test('a toml the user edited is kept and its db_root followed', () async {
      final node = make();
      await node.prepareFolder();
      final edited = File(node.tomlPath).readAsStringSync().replaceFirst(
        RegExp(r'db_root = .*'),
        "db_root = '/elsewhere/chain'",
      );
      File(node.tomlPath).writeAsStringSync(edited);
      node.options = const NodeTomlOptions(preferredPeers: ['1.2.3.4:3414']);
      await node.start();
      expect(node.userToml, isTrue);
      expect(File(node.tomlPath).readAsStringSync(), edited);
      expect(node.chainDataPath, '/elsewhere/chain');
      expect(node.restartNeeded, isFalse);
      await node.stop();
    });
  });

  group('readiness and detail', () {
    Map<String, dynamic> full(String phase, int height, [int? highest]) => {
      ...status(phase, height, highest),
      'protocol_version': 2,
      'user_agent': 'MW/Epic 4.1.0',
    };

    test('ready_for_txs decides running over the sync status', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => switch (m) {
        'ready_for_txs' => {'ready_for_txs': true},
        'get_status' => full('header_sync', 10, 500),
        _ => null,
      };
      await node.poll();
      expect(node.state.kind, NodeStatusKind.running);
      expect(node.state.readyForTxs, isTrue);

      answer = (m, owner) => switch (m) {
        'ready_for_txs' => {'ready_for_txs': false},
        'get_status' => full('no_sync', 500),
        _ => null,
      };
      await node.poll();
      expect(node.state.kind, NodeStatusKind.syncing);
      expect(node.state.readyForTxs, isFalse);
      await node.stop();
    });

    test('an older node without ready_for_txs is judged as before', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => m == 'get_status' ? full('no_sync', 500) : null;
      await node.poll();
      expect(node.state.kind, NodeStatusKind.running);
      expect(node.state.readyForTxs, isNull);
      await node.stop();
    });

    test('ready_for_txs alone, without the secret, is enough', () async {
      final node = make();
      await node.start();
      File(node.secretPath).writeAsStringSync('');
      answer = (m, owner) => switch (m) {
        'ready_for_txs' => {'ready_for_txs': true},
        'get_tip' => {'height': 700},
        _ => null,
      };
      await node.poll();
      expect(node.state.kind, NodeStatusKind.running);
      expect(node.state.height, 700);
      expect(node.state.status, isNull);
      await node.stop();
    });

    test('the parsed status and the version are in the state', () async {
      final node = make();
      await node.start();
      var versionCalls = 0;
      answer = (m, owner) {
        if (m == 'get_version') {
          versionCalls++;
          return {'node_version': '4.1.0', 'block_header_version': 6};
        }
        return m == 'get_status' ? full('txhashset_download', 0) : null;
      };
      await node.poll();
      await node.poll();
      expect(node.state.status?.syncStatus, 'txhashset_download');
      expect(node.state.status?.userAgent, 'MW/Epic 4.1.0');
      expect(node.state.version, '4.1.0');
      expect(versionCalls, 1);
      await node.stop();
    });

    test('the version falls back to the user agent', () async {
      final node = make();
      await node.start();
      answer = (m, owner) => m == 'get_status'
          ? {...full('no_sync', 5), 'user_agent': 'MW/Epic 3.9.1'}
          : null;
      await node.poll();
      expect(node.state.version, '3.9.1');
      await node.stop();
    });

    test('the same answer twice is no new state', () async {
      final node = make();
      final seen = <BuiltInNodeState>[];
      node.states.listen(seen.add);
      await node.start();
      answer = (m, owner) => m == 'get_status' ? full('header_sync', 5, 9) : null;
      await node.poll();
      await node.poll();
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((s) => s.kind), [
        NodeStatusKind.starting,
        NodeStatusKind.syncing,
      ]);
      await node.stop();
    });

    test('startedAt is the spawn time and survives polls', () async {
      final node = make();
      expect(node.startedAt, isNull);
      final t0 = now;
      await node.start();
      expect(node.startedAt, t0);
      now = now.add(const Duration(minutes: 1));
      answer = (m, owner) => m == 'get_status' ? full('no_sync', 5) : null;
      await node.poll();
      expect(node.startedAt, t0);
      await node.restart();
      expect(node.startedAt, now);
      await node.stop();
      expect(node.startedAt, isNull);
    });

    test('the secret is public for the peer client', () async {
      final node = make();
      expect(await node.readSecret(), isNull);
      await node.prepareFolder();
      expect(node.secretPath, '${node.folder}/.api_secret');
      final secret = await node.readSecret();
      expect(secret, hasLength(20));
      File(node.secretPath).writeAsStringSync('abc\r\nsecond\n');
      expect(await node.readSecret(), 'abc');
    });
  });

  group('restart', () {
    test('stops, then starts a new process', () async {
      final node = make();
      await node.start();
      await node.restart();
      expect(spawned, hasLength(2));
      expect(spawned.first.terminated, 1);
      expect(node.pid, spawned.last.pid);
      expect(node.state.kind, NodeStatusKind.starting);
      await node.stop();
    });

    test('concurrent restarts collapse into one', () async {
      final node = make();
      await node.start();
      gate = Completer<void>();
      final a = node.restart();
      final b = node.restart();
      expect(identical(a, b), isTrue);
      await until(() => spawnArgs.length == 2);
      gate!.complete();
      await Future.wait([a, b]);
      expect(spawned, hasLength(2));
      await node.stop();
    });

    test('a stop during the stop part wins', () async {
      final node = make();
      await node.start();
      final restarted = node.restart();
      final stopped = node.stop();
      await Future.wait([restarted, stopped]);
      expect(spawned, hasLength(1));
      expect(node.pid, isNull);
      expect(node.state.kind, NodeStatusKind.stopped);
    });

    test('a stop during the start part wins', () async {
      final node = make();
      await node.start();
      gate = Completer<void>();
      final restarted = node.restart();
      await until(() => spawnArgs.length == 2);
      final stopped = node.stop();
      gate!.complete();
      await Future.wait([restarted, stopped]);
      expect(spawned, hasLength(2));
      expect(spawned.every((p) => p.terminated == 1), isTrue);
      expect(node.pid, isNull);
      expect(node.state.kind, NodeStatusKind.stopped);
    });

    test('a poll landing after the stop changes nothing', () async {
      final node = make();
      await node.start();
      final reply = Completer<Map<String, dynamic>?>();
      final node2 = BuiltInNode(
        root: '${dir.path}/node2',
        binary: binary,
        chain: Chain.floonet,
        autoPoll: false,
        killAfter: const Duration(milliseconds: 50),
        killWait: const Duration(milliseconds: 50),
        clock: () => now,
        inspector: inspector,
        log: logs.add,
        portInUse: (_) async => false,
        freeBytes: (_) async => free,
        api: (port, method, {required owner, secret}) => reply.future,
        startProcess: (exe, args, {required workingDirectory}) async =>
            FakeProcess(++pidCounter),
      );
      await node2.start();
      final polled = node2.poll();
      await node2.stop();
      reply.complete({'ready_for_txs': true});
      await polled;
      expect(node2.state.kind, NodeStatusKind.stopped);
      await node.stop();
    });

    test('restart while stopped starts it', () async {
      final node = make();
      await node.restart();
      expect(spawned, hasLength(1));
      await node.stop();
    });
  });

  group('shared instance', () {
    tearDown(resetBuiltInNodes);

    test('one node per root and chain', () {
      final where = BuiltInNodeLocation(root: '${dir.path}/r', binary: binary);
      final a = builtInNodeFor(where, Chain.mainnet);
      expect(identical(builtInNodeFor(where, Chain.mainnet), a), isTrue);
      expect(identical(builtInNodeFor(where, Chain.floonet), a), isFalse);
      final other = BuiltInNodeLocation(root: '${dir.path}/s', binary: binary);
      expect(identical(builtInNodeFor(other, Chain.mainnet), a), isFalse);
    });

    test('a disposed node is replaced', () async {
      final where = BuiltInNodeLocation(root: '${dir.path}/r', binary: binary);
      final a = builtInNodeFor(where, Chain.mainnet);
      await a.dispose();
      expect(a.isDisposed, isTrue);
      expect(identical(builtInNodeFor(where, Chain.mainnet), a), isFalse);
    });

    test('the provider gives the shared node and never disposes it', () async {
      final where = BuiltInNodeLocation(root: '${dir.path}/r', binary: binary);
      final container = ProviderContainer(
        overrides: [
          builtInNodeSupportedProvider.overrideWithValue(true),
          builtInNodeLocationProvider.overrideWith((ref) async => where),
        ],
      );
      final node = await container.read(
        builtInNodeProvider(Chain.mainnet).future,
      );
      expect(identical(node, builtInNodeFor(where, Chain.mainnet)), isTrue);
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(node.isDisposed, isFalse);
    });
  });

  group('provider', () {
    test('refuses where the built-in node is unsupported', () async {
      final container = ProviderContainer(
        overrides: [builtInNodeSupportedProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(builtInNodeProvider(Chain.mainnet).future),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

String _sha(String text) => sha256.convert(utf8.encode(text)).toString();
