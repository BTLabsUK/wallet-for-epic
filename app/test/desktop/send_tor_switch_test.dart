// SPDX-License-Identifier: Apache-2.0
// The one Tor switch on desktop Send: every gate and chip comes from torWay. Starting and
// not connected hold covered sends (Epicbox, an onion); nothing falls back to the clearnet;
// Link to http(s) goes on the clearnet even with Tor on; an onion with Tor off needs Tor.
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

final _l = englishStrings;

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';
const _epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
const _https = 'https://pay.example.org:3415';
// Plain http to the internet: held while the Tor switch is on. The local network goes direct.
const _httpInternet = 'http://pay.example.org:3415';
const _httpLan = 'http://10.0.0.5:3415';

/// The mock wallet with tor's health set by the test, recording each send and switch change.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];
  final List<bool> torCalls = [];
  int torRetries = 0;

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
  Future<void> retryTorPay() async => torRetries++;

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
      final n = container.read(deskProvider.notifier);
      await n.refresh();
      // Link · Tor on (Settings › Transactions): a send to an onion is about Tor, not an
      // off method.
      final s = container.read(deskProvider).settings;
      await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkHttp: true, linkTor: true)));
    });
    wallet.torCalls.clear();
    wallet.torRetries = 0;
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
        expect(chip(_l.deskKitChipStarting), findsOneWidget);
        expect(find.text(_l.deskSendTorStarting), findsOneWidget);
        // The button keeps its name; the short reason is its tip.
        expect(review(tester).label, _l.deskSendReview);
        expect(review(tester).tooltip, _l.deskSendReviewWaitTor);
        expect(review(tester).onPressed, isNull);
        // Enter in Amount does not review either.
        await tester.tap(find.byType(EditableText).at(1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        expect(find.text(_l.deskSendReviewTitle), findsNothing);
        expect(wallet.sent, isEmpty);
      }, skip: !torBuilt);
    }
  });

  group('Tor not connected', () {
    setUp(() {
      wallet.torHealth = ServiceHealth.down;
      wallet.canSend = false;
    });

    testWidgets('a notice with Retry only, no Turn Tor off (D-05); nothing sent', (tester) async {
      await show(tester, const SendArgs(recipient: _epicbox, amount: '1'));
      expect(find.text(_l.deskSendTorBlocked), findsOneWidget);
      expect(find.text(_l.deskSendTorBlockedText), findsOneWidget);
      expect(chip('Tor not connected'), findsOneWidget);
      expect(review(tester).label, 'Review');
      expect(review(tester).tooltip, 'Tor not connected');
      expect(review(tester).onPressed, isNull);
      await tester.tap(find.widgetWithText(EButton, _l.commonRetry));
      await tester.pumpAndSettle();
      expect(wallet.torRetries, 1, reason: 'Retry restarts the tor payments go through');
      expect(wallet.sent, isEmpty);
      // D-05: an error offers Retry only.
      expect(find.widgetWithText(EButton, _l.torTurnOff), findsNothing);
    }, skip: !torBuilt);

    testWidgets('an onion is held too', (tester) async {
      await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'));
      expect(find.text(_l.deskSendTorBlocked), findsOneWidget);
      expect(review(tester).onPressed, isNull);
    }, skip: !torBuilt);
  });

  testWidgets('Link https with Tor on: sendable, "Over Tor", sent over http through Tor', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _https, amount: '5'));
    expect(chip('Over Tor'), findsOneWidget);
    expect(find.text(_l.deskSendHttpClearnet), findsNothing);
    expect(review(tester).label, 'Review');
    await tester.tap(find.text(_l.deskSendReview));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Dialog), matching: find.text(_l.sendRouteLinkHttps)), findsOneWidget);
    await enterReviewPassword(tester);
    await tester.tap(find.textContaining('Send 5'));
    await tester.pumpAndSettle();
    expect(wallet.sent.single.method, TxMethod.http);
    expect(wallet.sent.single.to, _https);
  }, skip: !torBuilt);

  testWidgets('Link plain http to the internet with Tor on: held, and why', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _httpInternet, amount: '5'));
    // The notice under To (Turn Tor off, captioned as the switch for every connection: D-05).
    expect(find.byKey(const ValueKey('send-hold-torOnPlainHttp')), findsOneWidget);
    expect(find.text(_l.sendHeldTorOn), findsWidgets);
    expect(find.text(_l.torTurnOffCaption), findsOneWidget);
    expect(find.byKey(const ValueKey('send-hold-fix')), findsOneWidget);
    expect(review(tester).onPressed, isNull);
    // Pressed anyway: no consent question, nothing sent.
    await tester.tap(find.text(_l.deskSendReview), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Not encrypted. Send anyway?'), findsNothing);
    expect(wallet.sent, isEmpty);
  }, skip: !torBuilt);

  testWidgets('Link plain http to the local network with Tor on: goes direct, not held', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _httpLan, amount: '5'));
    expect(find.byKey(const ValueKey('send-hold-torOnPlainHttp')), findsNothing);
    expect(chip('Over Tor'), findsNothing);
    expect(review(tester).onPressed, isNotNull);
  }, skip: !torBuilt);

  testWidgets('Link plain http opened at the review with Tor on: refused, never asked', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _httpInternet, amount: '5', step: SendStep.review));
    expect(find.text('Not encrypted. Send anyway?'), findsNothing);
    expect(find.text(_l.deskSendReviewTitle), findsNothing);
    expect(find.text(_l.sendHeldTorOn), findsWidgets);
    expect(wallet.sent, isEmpty);
  }, skip: !torBuilt);

  testWidgets('Link onion with Tor on: "Over Tor", sent over Tor', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'));
    expect(chip(_l.deskKitChipOverTor), findsOneWidget);
    expect(find.text(_l.deskSendHttpClearnet), findsNothing);
    expect(review(tester).onPressed, isNotNull);
  }, skip: !torBuilt);

  testWidgets('an onion with the Tor switch off goes over the tor Link · Tor runs for payments', (tester) async {
    // Item 2: Link · Tor on starts tor for payments; no Turn on Tor, the switch stays off.
    await show(tester, const SendArgs(method: TxMethod.http, recipient: _onion, amount: '1'), tor: false);
    expect(find.text(_l.deskSendNeedsTor), findsNothing);
    expect(find.widgetWithText(EButton, _l.deskSendTurnOnTor), findsNothing);
    expect(review(tester).onPressed, isNotNull);
    expect(wallet.torCalls, isEmpty);
    expect(wallet.sent, isEmpty);
  }, skip: !torBuilt);

  testWidgets('File shows no chip', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.file, amount: '1'));
    expect(find.byKey(const ValueKey('tor-chip')), findsNothing);
  });
}
