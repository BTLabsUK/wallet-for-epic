// SPDX-License-Identifier: Apache-2.0
// HTTP From the internet: the public IP and port check cache, and the notice on Receive and in
// Settings, over a fake probe (nothing is asked of the internet).
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/http_reach.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe implements PublicReachProbe {
  String? ip = '203.0.113.24';
  bool? open = false;
  final List<String> calls = [];
  Completer<void>? gate;

  @override
  Future<String?> publicIp() async {
    calls.add('ip');
    await gate?.future;
    return ip;
  }

  @override
  Future<bool?> reachable(String ip, int port) async {
    calls.add('$ip:$port');
    return open;
  }
}

class _Wallet extends MockDeskWallet {
  final List<HttpReach?> answers = [];
  final List<bool> rechecks = [];

  @override
  Future<HttpReach?> httpReach({bool recheck = false}) async {
    rechecks.add(recheck);
    return answers.length > 1 ? answers.removeAt(0) : answers.first;
  }
}

HttpReach _reach({String? ip = '203.0.113.24', bool? reachable}) =>
    HttpReach(port: 3415, publicIp: ip, lan: '10.0.1.24', reachable: reachable, checkedAt: DateTime(2026));

void main() {
  group('HttpReachCache', () {
    late _Probe probe;
    late DateTime now;
    late String? lan;
    late HttpReachCache cache;

    setUp(() {
      probe = _Probe();
      now = DateTime(2026, 10, 23, 12);
      lan = '10.0.1.24';
      cache = HttpReachCache(probe: probe, lan: () async => lan, now: () => now);
    });

    test('asks the IP, then the port on it', () async {
      final r = await cache.read(3415);
      expect(probe.calls, ['ip', '203.0.113.24:3415']);
      expect((r.publicAddress, r.lanAddress, r.reachable), ('http://203.0.113.24:3415', 'http://10.0.1.24:3415', false));
    });

    test('kept 2 minutes; asked again after, on recheck, a new port or a new network', () async {
      await cache.read(3415);
      now = now.add(const Duration(seconds: 90));
      await cache.read(3415);
      expect(probe.calls, hasLength(2));
      await cache.read(3415, recheck: true);
      expect(probe.calls, hasLength(4));
      now = now.add(const Duration(minutes: 3));
      await cache.read(3415);
      expect(probe.calls, hasLength(6));
      await cache.read(3420);
      expect(probe.calls.last, '203.0.113.24:3420');
      lan = '10.0.0.7';
      expect((await cache.read(3420)).lan, '10.0.0.7');
      expect(probe.calls, hasLength(10));
    });

    test('no public IP: no port check', () async {
      probe.ip = null;
      final r = await cache.read(3415);
      expect(probe.calls, ['ip']);
      expect((r.publicAddress, r.reachable), (null, null));
    });

    test('calls at the same time share one check', () async {
      probe.gate = Completer();
      final a = cache.read(3415);
      final b = cache.read(3415, recheck: true);
      await pumpEventQueue();
      probe.gate!.complete();
      expect(identical(await a, await b), isTrue);
      expect(probe.calls, ['ip', '203.0.113.24:3415']);
    });
  });

  group('HttpReachNotice', () {
    Future<_Wallet> pump(WidgetTester tester, List<HttpReach?> answers) async {
      final wallet = _Wallet()..answers.addAll(answers);
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)], retry: (_, _) => null);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: HttpReachNotice())),
        ),
      );
      await tester.pump();
      return wallet;
    }

    testWidgets('not reachable: forward the port; Check asks again', (tester) async {
      final wallet = await pump(tester, [_reach(reachable: false), _reach(reachable: true)]);
      expect(find.text('Not reachable from the internet'), findsOneWidget);
      expect(find.textContaining('Forward TCP port 3415 on your router to this computer (10.0.1.24)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('http-reach-check')));
      await tester.pump();
      expect(find.text('Reachable from the internet'), findsOneWidget);
      expect(wallet.rechecks, [false, true]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no IP and no answer from the port check say so', (tester) async {
      await pump(tester, [_reach(ip: null)]);
      expect(find.text('Public IP not found'), findsOneWidget);
      // The address sits in the sentence as its own unbroken span, so the notice's text is read.
      expect(tester.widget<ENotice>(find.byKey(const ValueKey('http-reach'))).text, contains('On your network: http://10.0.1.24:3415'));
      await tester.pumpWidget(const SizedBox());
      await pump(tester, [_reach()]);
      expect(find.text('Reachability unknown'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
