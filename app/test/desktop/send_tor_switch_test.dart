// The one Tor switch on desktop Send: every gate and chip comes from torWay. Starting and
// not connected hold covered sends (Epicbox, an onion); nothing falls back to the clearnet;
// Link to http(s) goes on the clearnet even with Tor on; an onion with Tor off needs Tor.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';
const _epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
const _https = 'https://pay.example.org:3415';

/// The mock wallet with tor's health set by the test, recording each send and switch change.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];
  final List<bool> torCalls = [];

  /// While the switch is on: tor's health and whether sends work.
  ServiceHealth torHealth = ServiceHealth.ok;
  bool canSend = true;

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }

  @override
  Future<void> setTor(bool on) {
    torCalls.add(on);
    return super.setTor(on);
  }

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    final on = s.tor != ServiceHealth.off;
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: on ? torHealth : ServiceHealth.off,
      torCanSend: on && canSend,
      lastUpdate: s.lastUpdate,
    );
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  });

  tearDown(() => container.dispose());

  /// Pumps 2 s of frames: the chip's spinner never settles while Tor starts.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, SendArgs args, {bool tor = true}) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      if (tor) await wallet.setTor(true);
      await container.read(deskProvider.notifier).refresh();
    });
    wallet.torCalls.clear();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
      ),
    );
    await settle(tester);
  }

  /// The summary's primary button, whatever it reads now.
  EButton review(WidgetTester tester) => tester.widget<EButton>(find.descendant(of: find.byType(EPanel).last, matching: find.byType(EButton)).last);
  Finder chip(String text) => find.descendant(of: find.byKey(const ValueKey('tor-chip')), matching: find.text(text));

  group('Tor starting', () {
    setUp(() {
      wallet.torHealth = ServiceHealth.checking;
      wallet.canSend = false;
    });

    for (final (name, to) in [('Epicbox', _epicbox), ('a Link onion', _onion)]) {
      testWidgets('$name waits: Review disabled, "Waiting for Tor", nothing sent', (tester) async {
        await show(tester, SendArgs(recipient: to, amount: '1'));
        expect(chip('Tor starting'), findsOneWidget);
        expect(find.text('Tor is starting'), findsOneWidget);
        expect(review(tester).label, 'Waiting for Tor');
        expect(review(tester).onPressed, isNull);
        // Enter in Amount does not review either.
        await tester.tap(find.byType(EditableText).at(1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        expect(find.text('Check and send'), findsNothing);
        expect(wallet.sent, isEmpty);
      });
    }
  });

  group('Tor not connected', () {
    setUp(() {
      wallet.torHealth = ServiceHealth.down;
      wallet.canSend = false;
    });

    testWidgets('a notice with Retry and Turn Tor off; nothing sent', (tester) async {
      await show(tester, const SendArgs(recipient: _epicbox, amount: '1'));
      expect(find.text('Tor is not connected'), findsOneWidget);
      expect(find.text('Nothing is sent until it is, or until Tor is turned off.'), findsOneWidget);
      expect(chip('Tor not connected'), findsOneWidget);
      expect(review(tester).label, 'Tor not connected');
      expect(review(tester).onPressed, isNull);
      await tester.tap(find.widgetWithText(EButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(wallet.torCalls, [true]);
      expect(wallet.sent, isEmpty);
      await tester.tap(find.widgetWithText(EButton, 'Turn Tor off'));
      await tester.pumpAndSettle();
      expect(wallet.torCalls, [true, false]);
      // Tor off: Epicbox goes on the clearnet again, and says so.
      expect(find.text('Tor is not connected'), findsNothing);
      expect(chip('Not over Tor'), findsOneWidget);
      expect(review(tester).onPressed, isNotNull);
      expect(wallet.sent, isEmpty);
    });

    testWidgets('an onion is held too', (tester) async {
      await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'));
      expect(find.text('Tor is not connected'), findsOneWidget);
      expect(review(tester).onPressed, isNull);
    });
  });

  testWidgets('Link http(s) with Tor on: sendable, "Not over Tor", sent over http', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _https, amount: '5'));
    expect(chip('Not over Tor'), findsOneWidget);
    expect(find.text('Link to http(s) addresses goes over the clearnet, not Tor.'), findsOneWidget);
    expect(review(tester).label, 'Review send');
    await tester.tap(find.text('Review send'));
    await tester.pumpAndSettle();
    expect(find.text('Link Payment · HTTP (their wallet must be open)'), findsOneWidget);
    await enterReviewPassword(tester);
    await tester.tap(find.textContaining('Send 5'));
    await tester.pumpAndSettle();
    expect(wallet.sent.single.method, TxMethod.http);
    expect(wallet.sent.single.to, _https);
  });

  testWidgets('Link onion with Tor on: "Over Tor", sent over Tor', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'));
    expect(chip('Over Tor'), findsOneWidget);
    expect(find.text('Link to http(s) addresses goes over the clearnet, not Tor.'), findsNothing);
    expect(review(tester).onPressed, isNotNull);
  });

  testWidgets('an onion with Tor off: "Needs Tor" and Turn on Tor; the form is kept', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'), tor: false);
    expect(find.text('Needs Tor'), findsOneWidget);
    expect(chip('Not over Tor'), findsOneWidget);
    expect(review(tester).onPressed, isNull);
    expect(find.text('Link to http(s) addresses goes over the clearnet, not Tor.'), findsNothing);
    await tester.tap(find.widgetWithText(EButton, 'Turn on Tor'));
    await tester.pumpAndSettle();
    expect(wallet.torCalls, [true]);
    expect(find.text(_onion), findsOneWidget, reason: 'the form is kept');
    expect(find.text('Needs Tor'), findsNothing);
    expect(review(tester).onPressed, isNotNull);
    expect(wallet.sent, isEmpty);
  });

  testWidgets('File shows no chip', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.file, amount: '1'));
    expect(find.byKey(const ValueKey('tor-chip')), findsNothing);
  });
}
