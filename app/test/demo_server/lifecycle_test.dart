// The demo store, the start-up purge, the sweeper, the limits and the settings.

import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/config.dart';
import 'package:epic_wallet/src/demo_server/demo_store.dart';
import 'package:epic_wallet/src/demo_server/file_secret_store.dart';
import 'package:epic_wallet/src/demo_server/limits.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Future<String> mode(String path) async =>
    (await Process.run('stat', ['-c', '%a', path])).stdout.toString().trim();

void main() {
  test(
    'start-up removes expired demos and anything without a valid demo.json',
    () async {
      final root = await Directory.systemTemp.createTemp('wfe-demo-test-');
      final store = DemoStore(root.path);
      await store.prepare();
      final now = DateTime.now();
      final live = await store.create(now: now, ttl: const Duration(hours: 1));
      final expired = await store.create(
        now: now.subtract(const Duration(hours: 2)),
        ttl: const Duration(hours: 1),
      );
      final broken = newDemoId();
      await Directory(store.dirOf(broken)).create();
      await File('${store.dirOf(broken)}/demo.json').writeAsString('{not json');
      final missing = newDemoId();
      await Directory(store.walletDirOf(missing)).create(recursive: true);
      await Directory('${store.demosDir}/not-a-demo').create();
      await File('${store.demosDir}/stray.txt').writeAsString('x');

      final h = await Harness.start(
        root: root,
        config: (r) => DemoServerConfig(dataRoot: r, port: 0),
      );

      expect(h.server.liveCount, 1);
      final left = await Directory(store.demosDir)
          .list()
          .map((e) => e.path)
          .toList();
      expect(left, [store.dirOf(live.id)]);
      expect(await Directory(store.dirOf(expired.id)).exists(), isFalse);
      expect(await mode(root.path), '700');
      expect(await mode(store.dirOf(live.id)), '700');
      expect(await mode('${store.dirOf(live.id)}/demo.json'), '600');

      // The demo that survived the restart still answers its cookie.
      final v = Visitor(h)..cookie = live.id;
      expect((await v.status()).json['state'], 'active');
    },
  );

  test('the sweeper ends an expired demo and removes its directory', () async {
    final h = await Harness.start(
      config: (r) => DemoServerConfig(
        dataRoot: r,
        port: 0,
        ttl: const Duration(seconds: 1),
        sweepInterval: const Duration(milliseconds: 200),
      ),
    );
    final v = Visitor(h);
    await v.start();
    final dir = Directory(h.server.store.dirOf(v.cookie!));
    expect(await dir.exists(), isTrue);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (await dir.exists() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(await dir.exists(), isFalse);
    expect(h.server.liveCount, 0);
    expect((await v.status()).json, {'state': 'ended'});
  });

  test(
    'the file secret store keeps values across instances, mode 600',
    () async {
      final dir = await Directory.systemTemp.createTemp('wfe-demo-test-');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/secrets.json';
      final a = FileSecretStore(path);
      expect(await a.read('k'), isNull);
      await Future.wait([a.write('k', 'v1'), a.write('j', 'v2')]);
      expect(await mode(path), '600');
      final b = FileSecretStore(path);
      expect(await b.read('k'), 'v1');
      expect(await b.read('j'), 'v2');
      await b.delete('k');
      expect(jsonDecode(await File(path).readAsString()), {'j': 'v2'});
      expect(await File('$path.tmp').exists(), isFalse);
    },
  );

  test('the rate limit allows a client again once its oldest start leaves the hour', () {
    final limit = ClientRateLimit(limit: 2);
    final t0 = DateTime.utc(2026, 10, 6, 12);
    expect(limit.take('a', t0), isNull);
    expect(limit.take('a', t0.add(const Duration(minutes: 10))), isNull);
    expect(
      limit.take('a', t0.add(const Duration(minutes: 20))),
      const Duration(minutes: 40),
    );
    expect(limit.take('b', t0), isNull);
    expect(limit.take('a', t0.add(const Duration(minutes: 61))), isNull);
    limit.prune(t0.add(const Duration(hours: 3)));
    expect(limit.clients, 0);
  });

  test('the work gate runs at most its slots at once, in order', () async {
    final gate = WorkGate(2);
    var running = 0;
    var peak = 0;
    final order = <int>[];
    Future<int> job(int n) => gate.run(() async {
      running++;
      peak = running > peak ? running : peak;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      running--;
      order.add(n);
      return n;
    });
    final results = await Future.wait([for (var i = 0; i < 6; i++) job(i)]);
    expect(results, [0, 1, 2, 3, 4, 5]);
    expect(peak, 2);
    expect(gate.running, 0);
    // A failing task frees its slot.
    await expectLater(
      gate.run<void>(() async => throw StateError('x')),
      throwsStateError,
    );
    expect(gate.running, 0);
    expect(order, hasLength(6));
  });

  group('settings', () {
    test('defaults are the plan limits', () {
      final c = DemoServerConfig.parse([], {'HOME': '/home/x'});
      expect(c.dataRoot, '/home/x/wfe-demo');
      expect(c.bindAddress, '127.0.0.1');
      expect(c.port, 8771);
      expect(c.maxLiveDemos, 300);
      expect(c.newDemosPerClientPerHour, 5);
      expect(c.argonSlots, 2);
      expect(c.maxFrameBytes, 256 * 1024);
      expect(c.idleTimeout, const Duration(minutes: 10));
      expect(c.ttl, const Duration(hours: 24));
      expect(c.trustProxy, isFalse);
      expect(c.secureCookie, isTrue);
      expect(c.effectiveOrigins(8771), {
        'http://127.0.0.1:8771',
        'http://localhost:8771',
      });
    });

    test('flags win over the environment', () {
      final c = DemoServerConfig.parse(
        ['--port', '9000', '--ttl=15m', '--origins', 'https://try.btlabs.uk'],
        {
          'WFE_DEMO_PORT': '1',
          'WFE_DEMO_DATA_ROOT': '/tmp/d',
          'WFE_DEMO_TRUST_PROXY': '1',
          'WFE_DEMO_LEPIC_LIB': '/lib/liblepic_ffi.so',
        },
      );
      expect(c.port, 9000);
      expect(c.ttl, const Duration(minutes: 15));
      expect(c.dataRoot, '/tmp/d');
      expect(c.trustProxy, isTrue);
      expect(c.lepicLibrary, '/lib/liblepic_ffi.so');
      expect(c.effectiveOrigins(9000), {'https://try.btlabs.uk'});
    });

    test('bad values are config errors', () {
      for (final args in [
        ['--port', 'x'],
        ['--ttl', '0s'],
        ['--ttl', '1d'],
        ['--trust-proxy', 'yes'],
        ['--origins', 'https://a.example/path'],
        ['--nope', '1'],
        ['--port'],
        ['stray'],
      ]) {
        expect(
          () => DemoServerConfig.parse(args, {'HOME': '/h'}),
          throwsA(isA<ConfigError>()),
          reason: '$args',
        );
      }
      expect(() => DemoServerConfig.parse([], {}), throwsA(isA<ConfigError>()));
    });
  });
}
