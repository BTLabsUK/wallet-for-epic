// SPDX-License-Identifier: Apache-2.0
// Wallet levels on Send and Receive (desktop): Shallow sends from the page by Epicbox alone and
// shows Receive's address card without host, switch or files; Deeper words the method strip and
// the files casually; Deep end is today's pages.
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }
}

const _to = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

Future<_Wallet> _pump(WidgetTester tester, WalletLevel level, Widget screen) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = _Wallet();
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskLevelProvider.overrideWithValue(level)]);
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

void main() {
  testWidgets('Shallow Send: one page, no method strip, the Summary button sends', (tester) async {
    final wallet = await _pump(tester, WalletLevel.justSendReceive, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.byType(ESegmented<TxMethod?>), findsNothing);
    expect(find.text('Payment method'), findsNothing);
    expect(find.text('How to send it'), findsNothing);
    expect(find.text('Send options'), findsNothing);
    expect(find.text('Nothing leaves until you press Send. After that it cannot be taken back.'), findsOneWidget);
    final button = find.widgetWithText(EButton, 'Send 1.0000\u00a0EPIC');
    expect(button, findsOneWidget);
    expect(find.widgetWithText(EButton, 'Review'), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The password guards the send; the page was the review.
    expect(find.text('Check and send'), findsNothing);
    expect(find.text('Your password'), findsOneWidget);
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, 'Password'), matching: find.byType(TextField)), 'secret-pass');
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Send').last);
    await tester.pumpAndSettle();
    expect(wallet.sent, hasLength(1));
    expect(wallet.sent.single.method, TxMethod.epicbox);
    // The page now shows the payment's steps, not the old "Sent" card.
    expect(find.byKey(const ValueKey('send-done')), findsOneWidget);
    expect(find.text('On its way'), findsOneWidget);
    expect(find.text('Handed to Epicbox. Completes when the recipient answers.'), findsNothing);
  });

  testWidgets('Deeper Send: the strip is headed "How to send it" and Review stays', (tester) async {
    await _pump(tester, WalletLevel.casual, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.text('How to send it'), findsOneWidget);
    expect(find.text('Payment method'), findsNothing);
    expect(find.byType(ESegmented<TxMethod?>), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Review'), findsOneWidget);
  });

  testWidgets('Deep end Send is today\'s: "Payment method" and Review', (tester) async {
    await _pump(tester, WalletLevel.everything, SendScreen(arg: SendArgs(recipient: _to, amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Review'), findsOneWidget);
  });

  testWidgets('Shallow Receive: Your address, Show QR, no switch, no files, no closed-wallet line', (tester) async {
    await _pump(tester, WalletLevel.justSendReceive, const ReceiveScreen());
    expect(find.text('Your address'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);
    expect(find.text('Ready to receive'), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-switch-epicbox')), findsNothing);
    expect(find.text('Receiving'), findsNothing);
    expect(find.textContaining('files'), findsNothing);
    expect(find.text('Other ways to receive'), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
    final card = find.byKey(const ValueKey('rx-shallow-address'));
    final address = tester.widget<EAddress>(find.descendant(of: card, matching: find.byType(EAddress)));
    expect(address.address, contains('@'), reason: 'the whole address, with the server');
    expect(find.descendant(of: card, matching: find.byType(ECopyButton)), findsOneWidget);
  });

  testWidgets('Deeper Receive: the switch and the payment files in casual words', (tester) async {
    await _pump(tester, WalletLevel.casual, const ReceiveScreen());
    expect(find.byKey(const ValueKey('rx-switch-epicbox')), findsOneWidget);
    expect(find.text('Payment files'), findsOneWidget);
    expect(find.text('Sign a payment file'), findsOneWidget);
    expect(find.text('Finish a reply file'), findsOneWidget);
    expect(find.text('Post a finished payment'), findsNothing);
    expect(find.textContaining('closed'), findsNothing);
  });

  testWidgets('Deep end Receive keeps the transaction files and Post a finished payment', (tester) async {
    await _pump(tester, WalletLevel.everything, const ReceiveScreen());
    expect(find.text('Transaction files'), findsOneWidget);
    expect(find.text('Sign a transaction file'), findsOneWidget);
    expect(find.text('Post a finished payment'), findsOneWidget);
    expect(find.textContaining('closed'), findsNothing);
  });
}
