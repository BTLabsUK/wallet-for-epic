// SPDX-License-Identifier: Apache-2.0
// Link HTTP on the mock wallet: Send › Link asks before plain HTTP leaves this computer, and
// Settings › Receiving turns the HTTP listener on and makes it reachable only from the guide.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_http.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

import 'review_password.dart';

/// The mock wallet, recording each send.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }
}

/// A valid onion (the ed25519 key 00 01 02 … 1f): a payment proof can be asked of its wallet.
const _proofOnion = 'aaaqeayeaudaocajbifqydiob4ibceqtcqkrmfyydenbwha5dyp3kead.onion';

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  });

  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1280, 1500); // Transactions is a long page
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendTo(WidgetTester tester, String to) async {
    await show(tester, SendScreen(arg: SendArgs(method: TxMethod.http, recipient: to, amount: '1')));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
  }

  group('Send › Link HTTP', () {
    testWidgets('plain http to another computer asks first, then sends with consent', (tester) async {
      await sendTo(tester, 'http://203.0.113.5:3415');
      expect(find.text('Not encrypted. Send anyway?'), findsOneWidget);
      await tester.tap(find.text('Send anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Check and send'), findsOneWidget);
      await enterReviewPassword(tester);
      await tester.tap(find.text('Send 1.0000 EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent.single.method, TxMethod.http);
      expect(wallet.sent.single.allowPlainHttp, isTrue);
    });

    testWidgets('Cancel on the question sends nothing', (tester) async {
      await sendTo(tester, 'HTTP://203.0.113.5:3415');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Check and send'), findsNothing);
      expect(wallet.sent, isEmpty);
    });

    // WAL-02 and WAL-05 on the desktop: Tom (the mock's c4) has an Epicbox address too.
    testWidgets("a contact's safer address is offered first; Use the safer address moves To there", (tester) async {
      await sendTo(tester, 'http://10.0.1.24:3415');
      expect(find.text('Safer address available'), findsOneWidget);
      expect(find.textContaining('Tom also has Epicbox'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('send-use-plain-http')));
      await tester.pumpAndSettle();
      expect(find.text('Not encrypted. Send anyway?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Check and send'), findsNothing);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('send-use-safer-route')));
      await tester.pumpAndSettle();
      final tom = container.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c4');
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, tom.epicbox);
      expect(find.text('Check and send'), findsNothing);
      expect(wallet.sent, isEmpty);
    });

    testWidgets("the review says a payment proof is asked when the contact's onion is known", (tester) async {
      await tester.runAsync(() async {
        final n = container.read(deskProvider.notifier);
        await n.refresh();
        final tom = container.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c4');
        await n.saveContact(Contact(id: tom.id, name: tom.name, epicbox: tom.epicbox, http: tom.http, tor: _proofOnion, note: tom.note));
      });
      await sendTo(tester, 'http://10.0.1.24:3415');
      await tester.tap(find.byKey(const ValueKey('send-use-plain-http')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Check and send'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-review-proof')), findsOneWidget);
      expect(find.text("Payment proof asked: only Tom's wallet can complete this payment."), findsOneWidget);
    });

    testWidgets('the history row marks a send made over plain HTTP', (tester) async {
      final t = Tx(
        id: 50,
        slateId: 'e5f60718-2a3b-44c5-d6e7-f8091a2b3c4e',
        direction: TxDirection.sent,
        state: TxState.confirmed,
        method: TxMethod.http,
        amount: 40 * nanoPerEpic,
        fee: 800000,
        created: DateTime(2026, 10, 2),
        counterparty: 'http://10.0.1.24:3415',
        contactName: 'Tom',
        unsafeSend: true,
      );
      await show(tester, TxRow(tx: t, onTap: () {}));
      expect(find.textContaining('Plain HTTP', findRichText: true), findsOneWidget);
      await show(tester, TxRow(tx: Tx(id: 51, slateId: '', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.http, amount: nanoPerEpic, fee: 0, created: DateTime(2026, 10, 2)), onTap: () {}));
      expect(find.textContaining('Plain HTTP', findRichText: true), findsNothing);
    });

    testWidgets('https and this computer go straight to the review', (tester) async {
      await sendTo(tester, 'https://wallet.example.org');
      expect(find.text('Not encrypted. Send anyway?'), findsNothing);
      expect(find.text('Check and send'), findsOneWidget);
    });

    testWidgets('host:port without a scheme is refused with a reason', (tester) async {
      await sendTo(tester, '203.0.113.5:3415');
      expect(find.text('Start with https:// or http://.'), findsOneWidget);
      expect(find.text('Check and send'), findsNothing);
    });
  });

  group('Settings › Transactions', () {
    // Link · HTTP is the one HTTP switch (Payment methods); its group below holds the state.
    Finder httpSwitch() => find.byKey(const ValueKey('st-offer-linkHttp'));
    String httpState(WidgetTester tester) => tester.widget<EStateLine>(find.byKey(const ValueKey('st-state-http'))).line.text;

    // `show` turns the Link methods on (advancedOn): Link · HTTP on means the listener runs.
    testWidgets('Link · HTTP on: the listener runs local only, its group shows the state with no second switch; off takes the group away', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      expect(httpState(tester), 'On · this computer only (127.0.0.1)');
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing, reason: 'no second HTTP switch');
      expect(find.byKey(const ValueKey('st-autostart-http')), findsNothing);
      expect(find.text('http://127.0.0.1:3415'), findsNothing, reason: 'the address lives on Receive');
      await tester.tap(httpSwitch());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('st-state-http')), findsNothing);
      expect(container.read(deskProvider).status?.httpListener, ServiceHealth.off);
    });

    testWidgets('From the internet: the guide the first time, then straight', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      await tester.tap(find.text('From the internet'));
      await tester.pumpAndSettle();
      expect(find.byType(InternetGuide), findsOneWidget);
      // Close leaves it local only.
      await tester.tap(find.widgetWithText(EButton, 'Close'));
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.publicMode, isFalse);

      // Seen once: the next pick switches straight (the guide stays behind the (?)).
      await tester.tap(find.text('From the internet'));
      await tester.pumpAndSettle();
      expect(find.byType(InternetGuide), findsNothing);
      expect(container.read(deskProvider).settings.publicMode, isTrue);
      expect(httpState(tester), 'On · from the internet, port 3415');
      expect(find.textContaining('must forward TCP 3415'), findsOneWidget);
    });

    testWidgets('a port outside 1 to 65535 is refused', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      final field = find.descendant(of: find.byType(HttpOptions), matching: find.byType(EditableText));
      await tester.enterText(field, '70000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Port must be 1 to 65535'), findsOneWidget);
      await tester.enterText(field, '3420');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.httpPort, 3420);
    });

    testWidgets('the tour’s port-in-use state names the port', (tester) async {
      await show(tester, const SettingsReceivingScreen(arg: ReceivingDemo.httpFailed));
      expect(httpState(tester), contains('Port 3415 is used by another program'));
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
