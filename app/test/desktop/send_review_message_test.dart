// Bot #124: the review showed no trace of the message typed on Send, so the sender could not
// tell whether it would go with the payment. The review dialog lists it as typed, none when
// empty, and Send hands it to the wallet, where the transaction keeps it.
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
    container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(wallet)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, SendArgs args) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => container.read(deskProvider.notifier).refresh(),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: SendScreen(arg: args)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const anna =
      'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
  final dialog = find.byType(EDialog);

  testWidgets('the review shows the message as typed, wrapped whole', (
    tester,
  ) async {
    final long = List.filled(8, 'Rent for the flat in March').join(' ');
    await pump(
      tester,
      SendArgs(
        recipient: anna,
        amount: '25',
        message: ' $long ',
        step: SendStep.review,
      ),
    );
    expect(find.text('Check and send'), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Message')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text(long)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a message the review has no Message row', (
    tester,
  ) async {
    await pump(
      tester,
      const SendArgs(recipient: anna, amount: '25', step: SendStep.review),
    );
    expect(find.text('Check and send'), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Message')),
      findsNothing,
    );
  });

  testWidgets(
    'Send hands the message to the wallet, and the transaction keeps it',
    (tester) async {
      await pump(
        tester,
        const SendArgs(
          recipient: anna,
          amount: '25',
          message: 'For rent',
          step: SendStep.review,
        ),
      );
      await enterReviewPassword(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is EButton && w.label.startsWith('Send 25'),
        ),
      );
      await tester.pumpAndSettle();
      expect(wallet.sent.single.message, 'For rent');
      final txs = await tester.runAsync(() => wallet.transactions());
      expect(txs!.where((t) => t.message == 'For rent'), hasLength(1));
    },
  );
}
