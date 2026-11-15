// SPDX-License-Identifier: Apache-2.0
// Send and Receive (desktop): Send has no method strip, the address decides the method line, and
// Review leads to the password and the send's live card; a declined send ends that card. Receive
// has its switch and the Payment files card with one Open.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/trust_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  /// Once set, the send still waiting for its recipient is listed as cancelled, declined by its
  /// receiver: the core's word after a `declined` notice.
  bool declined = false;

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }

  @override
  Future<List<Tx>> transactions() async {
    final rows = await super.transactions();
    if (!declined) return rows;
    return [
      for (final t in rows)
        if (!t.incoming && t.state == TxState.waitingRecipient)
          Tx(id: t.id, slateId: t.slateId, direction: t.direction, state: TxState.cancelled, method: t.method, amount: t.amount, fee: t.fee, created: t.created, counterparty: t.counterparty, receiverDeclined: true)
        else
          t,
    ];
  }
}

const _to = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

/// The last [_pump]'s state, for a test that changes the wallet under the page.
late ProviderContainer _container;

Future<_Wallet> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = _Wallet();
  final container = _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }
  return wallet;
}

/// Review, then the password the send asks for, then the confirm.
Future<void> _reviewAndSend(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(EButton, _l.deskSendReview));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(EButton, _l.deskSendReview));
  await tester.pumpAndSettle();
  expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
  await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField)), 'secret-pass');
  await tester.pump();
  await tester.tap(find.byWidgetPredicate((w) => w is EButton && w.semanticsId == TrustIds.sendConfirm));
  await tester.pumpAndSettle();
}

SendScreen _send() => SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok));

void main() {
  testWidgets('Send: no method strip, the method line follows the address, Review sends', (tester) async {
    final wallet = await _pump(tester, _send());
    expect(find.byType(ESegmented<TxMethod?>), findsNothing);
    expect(find.text('Payment method'), findsNothing);
    expect(find.byKey(const ValueKey('send-route-epicbox')), findsOneWidget);
    await _reviewAndSend(tester);
    expect(wallet.sent, hasLength(1));
    expect(wallet.sent.single.method, TxMethod.epicbox);
    // The page now shows the payment's steps, not the old "Sent" card.
    expect(find.byKey(const ValueKey('send-done')), findsOneWidget);
    expect(find.text(_l.deskSendDoneViaEpicbox), findsNothing);
  });

  testWidgets('a send its receiver declines ends the live card: Declined by the receiver, and why', (tester) async {
    final wallet = await _pump(tester, _send());
    await _reviewAndSend(tester);
    expect(find.byKey(const ValueKey('send-done')), findsOneWidget);
    // The receiver's `declined` notice: the core cancelled the send, the list says so.
    wallet.declined = true;
    await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('send-done')), findsNothing);
    expect(find.byKey(const ValueKey('send-cancelled')), findsOneWidget);
    expect(find.text(_l.txStatusReceiverDeclined), findsOneWidget);
    expect(find.text(_l.txDetailsReceiverDeclined), findsOneWidget);
    expect(find.text(_l.payOnItsWay), findsNothing);
    // The way on stays: a new send, and the row under Activity.
    expect(find.widgetWithText(EButton, _l.deskSendNewSend), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSendViewTx), findsOneWidget);
  });

  testWidgets('Receive: the switch and the Payment files card with one Open for every file', (tester) async {
    await _pump(tester, const ReceiveScreen());
    expect(find.byKey(const ValueKey('rx-switch-epicbox')), findsOneWidget);
    expect(find.text(_l.deskRecvFiles), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-files-open')), findsOneWidget);
    expect(find.text(_l.postFinishedTitle), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
  });
}
