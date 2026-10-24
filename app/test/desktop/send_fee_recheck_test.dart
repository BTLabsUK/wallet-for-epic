// linux-10: the review's fee is the fee the send pays. The core chooses the inputs again when
// it sends, so an output that finished confirming after the estimate changed the fee booked
// (0.0110 booked against 0.0120 reviewed). Send estimates once more and, when the fee moved,
// shows the new one and waits for the user instead of sending.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final sent = <SendRequest>[];

  /// Added to every estimate's fee from now on: the wallet's outputs moved.
  int feeShift = 0;

  /// The fee of the last estimate.
  int? lastFee;

  @override
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options}) async {
    final e = await super.estimateSend(amount, options: options);
    lastFee = e.fee + feeShift;
    return SendEstimate(amount: e.amount, fee: e.fee + feeShift, inputCount: e.inputCount, change: e.change - feeShift, locked: e.locked, changeOutputs: e.changeOutputs);
  }

  @override
  Future<SendResult> send(SendRequest r) {
    sent.add(r);
    return super.send(r);
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

  Future<void> pump(WidgetTester tester, SendArgs args) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
      ),
    );
    await tester.pumpAndSettle();
  }

  const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
  final send = find.byWidgetPredicate((w) => w is EButton && w.label.startsWith('Send 25'));

  testWidgets('a fee that moved after the review is shown before anything is sent', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', step: SendStep.review));
    expect(find.text('Check and send'), findsOneWidget);
    final reviewed = wallet.lastFee!;
    wallet.feeShift = -100000;
    await enterReviewPassword(tester);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(wallet.sent, isEmpty);
    expect(find.text('The fee changed'), findsOneWidget);
    expect(find.textContaining('now pays ${formatEpic(reviewed - 100000)} EPIC instead of ${formatEpic(reviewed)} EPIC'), findsOneWidget);
    // The user has seen the new fee: Send now sends it.
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(wallet.sent, hasLength(1));
  });

  testWidgets('an unchanged fee sends at once', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', step: SendStep.review));
    await enterReviewPassword(tester);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('The fee changed'), findsNothing);
    expect(wallet.sent, hasLength(1));
  });
}
