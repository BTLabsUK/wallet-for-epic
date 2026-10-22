// A send that ends badly never leaves the review spinning, and never invites a second payment
// while the first may be waiting.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

/// The mock wallet, with [send] and [transactions] scripted.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  Object? sendThrows;
  SendResult? sendReturns;
  bool listsFail = false;
  int sends = 0;

  @override
  Future<SendResult> send(SendRequest request) async {
    sends++;
    if (sendThrows != null) throw sendThrows!;
    return sendReturns ?? super.send(request);
  }

  @override
  Future<List<Tx>> transactions() async {
    if (listsFail) throw const DeskError('The wallet is locked');
    return super.transactions();
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

  Future<void> review(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: const Scaffold(
            body: SendScreen(
              arg: SendArgs(step: SendStep.review, recipient: 'esXyz1234567890abcdefghijk@epicbox.epiccash.com', amount: '1', epicboxHealth: ServiceHealth.ok),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsOneWidget);
  }

  testWidgets('a send that throws closes the review and points to Activity', (tester) async {
    wallet.sendThrows = StateError('socket closed');
    await review(tester);
    await enterReviewPassword(tester);
    await tester.tap(find.text('Send 1.0000 EPIC'));
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsNothing);
    expect(find.text('Not confirmed. Check Activity before sending again.'), findsOneWidget);
    expect(find.text('View in Activity'), findsOneWidget);
    expect(find.text('Review again'), findsNothing);
    expect(wallet.sends, 1);
  });

  testWidgets('a payment waiting in Activity offers no second review', (tester) async {
    wallet.sendReturns = const SendFailed('Not delivered. The payment waits in Activity; cancel it there to unlock the funds.', inActivity: true);
    await review(tester);
    await enterReviewPassword(tester);
    await tester.tap(find.text('Send 1.0000 EPIC'));
    await tester.pumpAndSettle();
    expect(find.text('View in Activity'), findsOneWidget);
    expect(find.text('Review again'), findsNothing);
  });

  testWidgets('a plain refusal still offers Review again', (tester) async {
    wallet.sendReturns = const SendFailed('Not enough funds');
    await review(tester);
    await enterReviewPassword(tester);
    await tester.tap(find.text('Send 1.0000 EPIC'));
    await tester.pumpAndSettle();
    expect(find.text('Review again'), findsOneWidget);
  });

  test('the send result stands when the lists cannot reload after it', () async {
    await container.read(deskProvider.notifier).refresh();
    wallet.sendReturns = const SendFailed('Not enough funds');
    wallet.listsFail = true;
    final c = container.read(deskProvider.notifier);
    final r = await c.send(const SendRequest(method: TxMethod.epicbox, amount: 1, to: 'x'));
    expect(r, isA<SendFailed>());
    expect(c.sending, 0);
  });

  test('a send in flight is counted, so Quit can wait', () async {
    await container.read(deskProvider.notifier).refresh();
    final c = container.read(deskProvider.notifier);
    final pending = c.send(const SendRequest(method: TxMethod.epicbox, amount: 1, to: 'x'));
    expect(c.sending, 1);
    await pending;
    expect(c.sending, 0);
  });
}
