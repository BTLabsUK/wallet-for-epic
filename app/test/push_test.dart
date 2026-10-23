// Push notifications: the registration requests (PROTOCOL.md), and how the Tor switch and the
// unlock drive them. Fakes stand in for Firebase, the relay's HTTP and the clock.

import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/push_controller.dart';
import 'package:epic_wallet/src/push_registration.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');
const String _relayAddress = 'esPushKey@flooepicbox.btlabs.uk';
final DateTime _now = DateTime.utc(2026, 10, 23, 12);
final int _stamp = _now.millisecondsSinceEpoch ~/ 1000;

/// What happened, across Firebase, the relay and tor, in order.
typedef _Order = List<String>;

class _Push implements PushPlatform {
  _Push(this.order);

  final _Order order;
  int starts = 0;
  bool permitted = true;
  int _issued = 0;
  String? _current;
  final refresh = StreamController<String>.broadcast();

  @override
  Future<bool> configured() async => true;

  @override
  Future<bool> start() async {
    starts++;
    return permitted;
  }

  @override
  Future<String?> token() async => _current ??= 'tok-${++_issued}';

  @override
  Future<void> deleteToken() async {
    order.add('deleteToken');
    _current = null;
  }

  @override
  Stream<String> get tokenRefresh => refresh.stream;

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

class _Session extends FakeWalletSession {
  _Session(this.order) {
    address = _relayAddress;
  }

  final _Order order;

  @override
  Stream<TorEvent> startTor({required String torBinary, String? libDir}) {
    order.add('startTor');
    return super.startTor(torBinary: torBinary, libDir: libDir);
  }

  @override
  Future<void> stopTor() async {
    await super.stopTor();
    order.add('stopTor');
  }
}

/// The config the next harness opens with ([_Harness.relay]).
WalletConfig _opening = _Harness._config;

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => _opening;
}

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

typedef _Post = ({Uri url, Map<String, dynamic> body, Duration timeout});

class _Harness {
  _Harness({this.wanted = false, this.torSaved = false, String? relay}) {
    _opening = relay == null ? _config : relayConfig(relay);
    session = _Session(order);
    if (relay != null) session.address = 'esPushKey@$relay';
    push = _Push(order);
    if (wanted) store.values['app.push'] = 'true';
    if (torSaved) store.values[PhoneTor.receivingKey(_config)] = 'true';
  }

  static const WalletConfig _config = WalletConfig(
    dataDir: '/fake/wallets/mainnet',
    chain: Chain.mainnet,
    nodeUrl: 'https://node.btlabs.uk',
    epicboxDomain: 'flooepicbox.btlabs.uk',
    epicboxPort: 443,
  );

  /// [_config] on another Epicbox relay.
  static WalletConfig relayConfig(String relay) => WalletConfig(
    dataDir: _config.dataDir,
    chain: _config.chain,
    nodeUrl: _config.nodeUrl,
    epicboxDomain: relay,
    epicboxPort: 443,
  );

  final bool wanted;
  final bool torSaved;
  final order = <String>[];
  late final _Session session;
  late final _Push push;
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  final posts = <_Post>[];

  /// The relay's answer; null answers 204, a completer that never completes keeps it waiting.
  Future<int> Function(Uri url)? answer;

  late ProviderContainer container;

  List<String> get postActions => [
    for (final p in posts) p.url.pathSegments.last,
  ];

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(store),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(_Config.new),
          updatePlatformProvider.overrideWithValue(null),
          torBundleFinderProvider.overrideWithValue(() async => _bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          pushPlatformProvider.overrideWithValue(push),
          clockProvider.overrideWithValue(() => _now),
          pushPostProvider.overrideWithValue((url, body, timeout) {
            order.add('post:${url.pathSegments.last}');
            posts.add((
              url: url,
              body: jsonDecode(body) as Map<String, dynamic>,
              timeout: timeout,
            ));
            return answer?.call(url) ?? Future.value(204);
          }),
          torSwitchHooksProvider.overrideWith(
            (ref) => ref.watch(pushTorHooksProvider),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AdvancedOptions(enabled: false, child: child!),
          home: const SettingsScreen(),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
      await push.refresh.close();
    });
    await tester.pumpAndSettle();
    // The Tor controller reads the bundle and the onion on real async: wait for it.
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
    // Alive for the app's life, as WalletApp keeps it.
    container.listen(pushControllerProvider, (_, _) {});
    await settle(tester);
  }

  /// The pending work: real async for the stores, then the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pumpAndSettle();
    }
  }

  PhoneTor get tor => container.read(phoneTorProvider.notifier);
  PushController get controller =>
      container.read(pushControllerProvider.notifier);
  bool get wantedNow => store.values['app.push'] == 'true';

  /// Tor turned on and connected.
  Future<void> torOn(WidgetTester tester) async {
    await tor.setReceiving(true);
    await tester.pumpAndSettle();
    await emit(tester, TorEventKind.ready);
    await settle(tester);
  }

  /// Tor turned off, with the stop and the hook after it driven by pumps: under fake async a
  /// bare await would never see a timer on the way fire.
  Future<void> torOff(WidgetTester tester) async {
    var done = false;
    unawaited(tor.setReceiving(false).then((_) => done = true));
    for (var i = 0; i < 20 && !done; i++) {
      await settle(tester);
    }
    expect(done, isTrue, reason: 'setReceiving(false) returns');
  }

  Future<void> emit(WidgetTester tester, TorEventKind kind) async {
    session.torStatusValue = kind == TorEventKind.ready
        ? TorStatus(kind: TorStatusKind.ready, onion: session.onion)
        : TorStatus.off;
    session.torEvents.add(
      TorEvent(
        kind: kind,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The notes said so far.
  final notes = <PushNote>[];

  void listenForNotes() {
    container.listen(pushNoteProvider, (_, e) {
      if (e != null) notes.add(e.note);
    });
  }
}

SwitchListTile _row(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(settingsPushKey));

Future<void> _reach(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(settingsPushKey),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the registration request', () {
    late List<_Post> posts;
    late Future<int> Function(Uri url) answer;
    late bool clearnet;
    late FakeWalletSession session;

    PushRegistration make() => PushRegistration(
      post: (url, body, timeout) {
        posts.add((
          url: url,
          body: jsonDecode(body) as Map<String, dynamic>,
          timeout: timeout,
        ));
        return answer(url);
      },
      now: () => _now,
      clearnet: () => clearnet,
    );

    setUp(() {
      posts = [];
      answer = (_) async => 204;
      clearnet = true;
      session = FakeWalletSession()..address = _relayAddress;
    });

    test(
      'register: the body PROTOCOL.md fixes, signed by the session',
      () async {
        final outcome = await make().register(session, 'tok-1');
        expect(outcome, PushOutcome.sent);
        final post = posts.single;
        expect(
          post.url.toString(),
          'https://flooepicbox.btlabs.uk/push/v1/register',
        );
        expect(post.body, {
          'address': _relayAddress,
          'token': 'tok-1',
          'timestamp': _stamp,
          'signature': 'sig:register:tok-1:$_stamp',
        });
        expect(post.timeout, const Duration(seconds: 10));
        expect(session.pushSignatures.single, (
          action: 'register',
          token: 'tok-1',
          timestamp: _stamp,
        ));
      },
    );

    test('unregister goes to its own path, with the caller’s cap', () async {
      final outcome = await make().unregister(
        session,
        'tok-1',
        timeout: const Duration(seconds: 5),
      );
      expect(outcome, PushOutcome.sent);
      expect(posts.single.url.path, '/push/v1/unregister');
      expect(posts.single.body['signature'], 'sig:unregister:tok-1:$_stamp');
      expect(posts.single.timeout, const Duration(seconds: 5));
    });

    test('a wallet on another relay sends nothing', () async {
      for (final other in [
        'esKey@epicbox.epiccash.com',
        'esKey@flooepicbox.btlabs.uk.evil.example',
        'esKey',
      ]) {
        session.address = other;
        expect(await make().register(session, 'tok-1'), PushOutcome.skipped);
      }
      expect(posts, isEmpty);
      expect(session.pushSignatures, isEmpty);
    });

    test('the relay’s own address forms are accepted', () {
      expect(PushRegistration.onRelay('esKey@flooepicbox.btlabs.uk'), isTrue);
      expect(
        PushRegistration.onRelay('esKey@flooepicbox.btlabs.uk:443'),
        isTrue,
      );
      expect(PushRegistration.onRelay('esKey@epicbox.epiccash.com'), isFalse);
    });

    test('Tor on: nothing is signed or sent', () async {
      clearnet = false;
      expect(await make().register(session, 'tok-1'), PushOutcome.skipped);
      expect(posts, isEmpty);
      expect(session.pushSignatures, isEmpty);
    });

    test(
      'Tor switched on while the signature was made: nothing is sent',
      () async {
        final registration = PushRegistration(
          post: (url, body, timeout) async {
            posts.add((url: url, body: const {}, timeout: timeout));
            return 204;
          },
          now: () => _now,
          clearnet: () => session.pushSignatures.isEmpty,
        );
        expect(
          await registration.register(session, 'tok-1'),
          PushOutcome.skipped,
        );
        expect(posts, isEmpty);
      },
    );

    test(
      'a refusal, a dead network and a timeout are failures, not throws',
      () async {
        answer = (_) async => 401;
        expect(await make().register(session, 'tok-1'), PushOutcome.failed);
        answer = (_) => Future.error(const NetErrorForTest());
        expect(await make().register(session, 'tok-1'), PushOutcome.failed);
        answer = (_) => Future.error(TimeoutException('slow'));
        expect(await make().register(session, 'tok-1'), PushOutcome.failed);
      },
    );
  });

  group('Settings › Notifications', () {
    testWidgets('normal: off, nothing to say', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _reach(tester);
      expect(_row(tester).value, isFalse);
      expect(_row(tester).onChanged, isNotNull);
      expect(_row(tester).subtitle, isNull);
    });

    testWidgets('paused: on, with the one state line, while Tor is on', (
      tester,
    ) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      await h.torOn(tester);
      await _reach(tester);
      expect(_row(tester).value, isTrue);
      expect(
        _row(tester).onChanged,
        isNotNull,
        reason: 'it can still be turned off',
      );
      expect(find.text('Paused while Tor is on'), findsOneWidget);
    });

    testWidgets('another relay: offered as usual, nothing sent before it is turned on', (
      tester,
    ) async {
      final h = _Harness(relay: 'epicbox.epiccash.com');
      await h.pump(tester);
      await _reach(tester);
      expect(_row(tester).value, isFalse);
      expect(_row(tester).onChanged, isNotNull);
      expect(_row(tester).subtitle, isNull);
      expect(h.posts, isEmpty);
    });

    testWidgets('disabled: off and not offered while Tor is on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torOn(tester);
      await _reach(tester);
      expect(_row(tester).value, isFalse);
      expect(_row(tester).onChanged, isNull);
      expect(find.text('Paused while Tor is on'), findsNothing);
    });
  });

  group('after each unlock', () {
    testWidgets(
      'wanted, Tor off: Firebase starts and the token is registered',
      (tester) async {
        final h = _Harness(wanted: true);
        await h.pump(tester);
        expect(h.push.starts, 1);
        expect(h.postActions, ['register']);
        expect(h.posts.single.body['token'], 'tok-1');
        expect(h.container.read(pushControllerProvider), isTrue);
      },
    );

    testWidgets('not wanted: nothing starts and nothing is sent', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(h.push.starts, 0);
      expect(h.posts, isEmpty);
    });

    testWidgets('a new token from Firebase is registered', (tester) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.push.refresh.add('tok-new');
      await h.settle(tester);
      expect(h.postActions, ['register', 'register']);
      expect(h.posts.last.body['token'], 'tok-new');
    });

    testWidgets(
      'the relay switched live to the BT Labs one: registered there',
      (tester) async {
        final h = _Harness(wanted: true, relay: 'epicbox.epiccash.com');
        await h.pump(tester);
        expect(h.posts, isEmpty, reason: 'another relay cannot push');
        h.session.address = _relayAddress;
        h.container
            .read(walletConfigProvider.notifier)
            .select(_Harness._config);
        await h.settle(tester);
        expect(h.postActions, ['register']);
        expect(h.posts.single.body['address'], _relayAddress);
      },
    );

    testWidgets('Tor already on at the unlock: no start, no request', (
      tester,
    ) async {
      final h = _Harness(wanted: true, torSaved: true);
      await h.pump(tester);
      expect(h.push.starts, 0);
      expect(h.posts, isEmpty);
      expect(h.container.read(phoneTorProvider).receiving, isTrue);
    });
  });

  group('Tor on', () {
    testWidgets('unregister and the token’s deletion come before tor starts', (
      tester,
    ) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.order.clear();
      await h.tor.setReceiving(true);
      await tester.pumpAndSettle();
      expect(
        h.order,
        containsAll(['post:unregister', 'deleteToken', 'startTor']),
      );
      final start = h.order.indexOf('startTor');
      expect(h.order.indexOf('post:unregister'), lessThan(start));
      expect(h.order.indexOf('deleteToken'), lessThan(start));
      expect(h.posts.last.body['token'], 'tok-1');
      expect(h.posts.last.timeout, const Duration(seconds: 5));
      expect(h.wantedNow, isTrue, reason: 'wanted is the memory of "was on"');
      // Nothing after tor routing started.
      await h.emit(tester, TorEventKind.ready);
      await h.settle(tester);
      expect(h.order.where((e) => e.startsWith('post:')), ['post:unregister']);
    });

    testWidgets('a failing unregister still drops the token and starts tor', (
      tester,
    ) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.answer = (_) => Future.error(const NetErrorForTest());
      h.order.clear();
      await h.tor.setReceiving(true);
      await tester.pumpAndSettle();
      expect(h.order, contains('deleteToken'));
      expect(h.session.torStarts, hasLength(1));
      expect(
        h.order.indexOf('deleteToken'),
        lessThan(h.order.indexOf('startTor')),
      );
    });

    testWidgets('a slow unregister is given up after the cap', (tester) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.answer = (_) => Completer<int>().future;
      h.order.clear();
      unawaited(h.tor.setReceiving(true));
      await tester.pump(const Duration(seconds: 1));
      expect(
        h.session.torStarts,
        isEmpty,
        reason: 'still waiting for the relay',
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(h.order, contains('deleteToken'));
      expect(h.session.torStarts, hasLength(1));
      expect(
        h.order.indexOf('deleteToken'),
        lessThan(h.order.indexOf('startTor')),
      );
    });

    testWidgets('not wanted: tor starts with nothing sent', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.tor.setReceiving(true);
      await tester.pumpAndSettle();
      expect(h.posts, isEmpty);
      expect(h.order, ['startTor']);
    });
  });

  group('Tor off', () {
    testWidgets(
      'was on: after tor stopped, a fresh token, registered, and said',
      (tester) async {
        final h = _Harness(wanted: true);
        await h.pump(tester);
        h.listenForNotes();
        await h.torOn(tester);
        h.order.clear();
        await h.torOff(tester);
        expect(
          h.order.first,
          'stopTor',
          reason: 'nothing before the clearnet is back',
        );
        expect(h.order, ['stopTor', 'post:register']);
        expect(
          h.posts.last.body['token'],
          'tok-2',
          reason: 'a new token, not the old one',
        );
        expect(h.notes, [PushNote.on]);
        expect(h.wantedNow, isTrue);
      },
    );

    testWidgets('was off: nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.listenForNotes();
      await h.torOn(tester);
      await h.torOff(tester);
      expect(h.posts, isEmpty);
      expect(h.push.starts, 0);
      expect(h.notes, isEmpty);
    });

    testWidgets(
      'switched off during Tor: no request, and Tor off keeps it off',
      (tester) async {
        final h = _Harness(wanted: true);
        await h.pump(tester);
        h.listenForNotes();
        await h.torOn(tester);
        h.posts.clear();
        h.order.clear();
        await h.controller.turnOff();
        await h.settle(tester);
        expect(h.wantedNow, isFalse);
        expect(h.posts, isEmpty, reason: 'nothing is sent while Tor is on');
        expect(h.order, isEmpty);
        await h.torOff(tester);
        expect(h.posts, isEmpty);
        expect(h.notes, [PushNote.off]);
        expect(h.wantedNow, isFalse);
      },
    );
  });

  group('the switch', () {
    testWidgets('off, Tor off: unregister, drop the token, say so', (
      tester,
    ) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.listenForNotes();
      h.posts.clear();
      await h.controller.turnOff();
      await h.settle(tester);
      expect(h.postActions, ['unregister']);
      expect(h.order, contains('deleteToken'));
      expect(h.wantedNow, isFalse);
      expect(h.notes, [PushNote.off]);
    });

    testWidgets('off, then on again: a new token is registered', (tester) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      await h.controller.turnOff();
      await h.settle(tester);
      h.posts.clear();
      final on = h.controller.turnOn();
      await h.settle(tester);
      expect(await on, isTrue);
      expect(h.postActions, ['register']);
      expect(h.posts.single.body['token'], 'tok-2', reason: 'the old one was deleted');
      expect(h.wantedNow, isTrue);
    });

    testWidgets('on: saved, started, registered', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(await h.controller.turnOn(), isTrue);
      await h.settle(tester);
      expect(h.wantedNow, isTrue);
      expect(h.postActions, ['register']);
    });

    testWidgets('on with permission denied: back off, nothing sent', (
      tester,
    ) async {
      final h = _Harness();
      h.push.permitted = false;
      await h.pump(tester);
      expect(await h.controller.turnOn(), isFalse);
      expect(h.wantedNow, isFalse);
      expect(h.posts, isEmpty);
      expect(h.container.read(pushProvider).blocked, isTrue);
    });

    testWidgets('on while Tor is on is not possible', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torOn(tester);
      expect(await h.controller.turnOn(), isFalse);
      expect(h.wantedNow, isFalse);
      expect(h.posts, isEmpty);
    });
  });

  group('the reminder', () {
    testWidgets('once, after a minute; not again once saved', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.listenForNotes();
      await tester.pump(const Duration(seconds: 59));
      expect(h.notes, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      await h.settle(tester);
      expect(h.notes, [PushNote.available]);
      expect(h.store.values[pushHintShownKey], 'true');

      // A new run: the flag is saved, so it never comes.
      final again = _Harness();
      again.store.values[pushHintShownKey] = 'true';
      await again.pump(tester);
      again.listenForNotes();
      await tester.pump(const Duration(seconds: 90));
      await again.settle(tester);
      expect(again.notes, isEmpty);
    });

    testWidgets('never when they are on', (tester) async {
      final h = _Harness(wanted: true);
      await h.pump(tester);
      h.listenForNotes();
      await tester.pump(const Duration(seconds: 90));
      await h.settle(tester);
      expect(h.notes, isEmpty);
      expect(h.store.values[pushHintShownKey], isNull);
    });

    testWidgets('never while Tor is on', (tester) async {
      final h = _Harness(torSaved: true);
      await h.pump(tester);
      h.listenForNotes();
      await tester.pump(const Duration(seconds: 90));
      await h.settle(tester);
      expect(h.notes, isEmpty);
      expect(h.store.values[pushHintShownKey], isNull);
    });
  });
}

class NetErrorForTest implements Exception {
  const NetErrorForTest();
}
