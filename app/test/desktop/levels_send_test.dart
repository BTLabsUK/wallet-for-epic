// SPDX-License-Identifier: Apache-2.0
// Wallet levels on Send and Receive (desktop): Shallow sends from the page by Epicbox alone and
// shows Receive's address card without host, switch or files; Deeper words the files card casually;
// Deep end is today's pages. Send has no method strip at any level: the address decides.
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
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

Future<_Wallet> _pump(WidgetTester tester, WalletLevel level, Widget screen) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = _Wallet();
  final container = _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskLevelProvider.overrideWithValue(level)]);
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

/// Types the password the send asks for and confirms it.
Future<void> _enterPasswordAndSend(WidgetTester tester) async {
  await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField)), 'secret-pass');
  await tester.pump();
  await tester.tap(find.widgetWithText(EButton, 'Send').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Shallow Send: one page, no method strip, the Summary button sends', (tester) async {
    final wallet = await _pump(tester, WalletLevel.justSendReceive, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.byType(ESegmented<TxMethod?>), findsNothing);
    expect(find.text('Payment method'), findsNothing);
    expect(find.text(_l.deskLvSendHowTo), findsNothing);
    expect(find.text('Send options'), findsNothing);
    expect(find.text(_l.deskLvSendNothingLeaves), findsOneWidget);
    final button = find.widgetWithText(EButton, 'Send 1.0\u00a0EPIC');
    expect(button, findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSendReview), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The password guards the send; the page was the review.
    expect(find.text(_l.deskSendReviewTitle), findsNothing);
    expect(find.text(_l.deskLvSendPasswordTitle), findsOneWidget);
    await _enterPasswordAndSend(tester);
    expect(wallet.sent, hasLength(1));
    expect(wallet.sent.single.method, TxMethod.epicbox);
    // The page now shows the payment's steps, not the old "Sent" card.
    expect(find.byKey(const ValueKey('send-done')), findsOneWidget);
    expect(find.text(_l.lvPayOnItsWay), findsOneWidget);
    expect(find.text(_l.deskSendDoneViaEpicbox), findsNothing);
  });

  testWidgets('a send its receiver declines ends the live card: Declined by the receiver, and why', (tester) async {
    final wallet = await _pump(tester, WalletLevel.justSendReceive, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    await tester.tap(find.widgetWithText(EButton, 'Send 1.0\u00a0EPIC'));
    await tester.pumpAndSettle();
    await _enterPasswordAndSend(tester);
    expect(find.byKey(const ValueKey('send-done')), findsOneWidget);
    // The receiver's `declined` notice: the core cancelled the send, the list says so.
    wallet.declined = true;
    await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('send-done')), findsNothing);
    expect(find.byKey(const ValueKey('send-cancelled')), findsOneWidget);
    expect(find.text(_l.txStatusReceiverDeclined), findsOneWidget);
    expect(find.text(_l.txDetailsReceiverDeclined), findsOneWidget);
    expect(find.text(_l.lvPayOnItsWay), findsNothing);
    expect(find.text(_l.lvPayCloseNote), findsNothing);
    // The way on stays: a new send, and the row under Activity.
    expect(find.widgetWithText(EButton, _l.deskSendNewSend), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSendViewTx), findsOneWidget);
  });

  testWidgets('Deeper Send: no method strip, the method line follows the address and Review stays', (tester) async {
    await _pump(tester, WalletLevel.casual, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.text(_l.deskLvSendHowTo), findsNothing);
    expect(find.text('Payment method'), findsNothing);
    expect(find.byType(ESegmented<TxMethod?>), findsNothing);
    expect(find.byKey(const ValueKey('send-route-epicbox')), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSendReview), findsOneWidget);
  });

  testWidgets('Deep end Send: the same method line and Review', (tester) async {
    await _pump(tester, WalletLevel.everything, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.text('Payment method'), findsNothing);
    expect(find.byKey(const ValueKey('send-route-epicbox')), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSendReview), findsOneWidget);
  });

  testWidgets('Shallow Receive: Your address, its QR code shown, no switch, no files, no closed-wallet line', (tester) async {
    await _pump(tester, WalletLevel.justSendReceive, const ReceiveScreen());
    expect(find.text(_l.deskLvSendYourAddress), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-qr-image-epicbox')), findsOneWidget);
    expect(find.text('Show QR'), findsNothing);
    expect(find.text(_l.deskLvSendReady), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-switch-epicbox')), findsNothing);
    expect(find.text(_l.deskRecvReceiving), findsNothing);
    expect(find.textContaining('files'), findsNothing);
    expect(find.text(_l.deskRecvOtherWays), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
    final card = find.byKey(const ValueKey('rx-shallow-address'));
    final address = tester.widget<EAddress>(find.descendant(of: card, matching: find.byType(EAddress)));
    expect(address.address, contains('@'), reason: 'the whole address, with the server');
    expect(find.descendant(of: card, matching: find.byType(ECopyButton)), findsOneWidget);
  });

  testWidgets('Deeper Receive: the switch and the files card in casual words, one Open for every file', (tester) async {
    await _pump(tester, WalletLevel.casual, const ReceiveScreen());
    expect(find.byKey(const ValueKey('rx-switch-epicbox')), findsOneWidget);
    expect(find.text(_l.deskLvSendPayFiles), findsOneWidget);
    expect(find.text('Transaction files'), findsNothing);
    expect(find.byKey(const ValueKey('rx-files-open')), findsOneWidget);
    expect(find.text(_l.postFinishedTitle), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
  });

  testWidgets('Deep end Receive keeps the Transaction files card with its one Open', (tester) async {
    await _pump(tester, WalletLevel.everything, const ReceiveScreen());
    expect(find.text(_l.deskRecvFiles), findsOneWidget);
    expect(find.text(_l.deskLvSendPayFiles), findsNothing);
    expect(find.byKey(const ValueKey('rx-files-open')), findsOneWidget);
    expect(find.textContaining('closed'), findsNothing);
  });
}
