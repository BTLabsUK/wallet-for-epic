// Send with the outputs lines wired in (design spec §4.7): the summary rows, Advanced's
// strategy re-estimating with the new options, Send all turning the radios off, and the
// review dialog's Locks line.
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_advanced.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

import 'review_password.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final asked = <SendOptions?>[];
  final sent = <SendRequest>[];

  /// While set, estimates wait for it.
  Completer<void>? hold;

  @override
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options}) async {
    asked.add(options);
    await hold?.future;
    return super.estimateSend(amount, options: options);
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
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
      ),
    );
    await tester.pumpAndSettle();
  }

  const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

  testWidgets('the summary says what stays spendable and what is locked', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25'));
    expect(find.text('Balance after'), findsOneWidget);
    expect(find.text('Spendable until change confirms'), findsOneWidget);
    expect(find.textContaining('locked,'), findsOneWidget);
    expect(wallet.asked.first?.strategy, SelectionStrategy.smallest);
  });

  testWidgets('a strategy picked under Advanced estimates again with it', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', advancedOpen: true));
    expect(find.text('default'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(ERadioRow), matching: find.text('All')));
    await tester.pumpAndSettle();
    expect(wallet.asked.last?.strategy, SelectionStrategy.all);
    expect(find.textContaining('Strategy for this send: All'), findsOneWidget);
    expect(find.textContaining('Send options · All outputs', findRichText: true), findsOneWidget);
  });

  testWidgets('Send all turns the strategy off', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, advancedOpen: true));
    await tester.tap(find.widgetWithText(EButton, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Sending everything spends every output.'), findsOneWidget);
    for (final r in tester.widgetList<ERadioRow>(find.byType(ERadioRow))) {
      expect(r.onSelected, isNull);
    }
  });

  testWidgets('the review repeats the lock', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', step: SendStep.review));
    expect(find.text('Check and send'), findsOneWidget);
    expect(find.text('Locks'), findsOneWidget);
    expect(find.textContaining('until the change confirms (3 blocks)'), findsOneWidget);
  });

  testWidgets('Review right after a new strategy sends with that strategy, not the last plan', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', advancedOpen: true));
    expect(wallet.asked.last?.strategy, SelectionStrategy.smallest);
    // The new strategy's estimate has not come back when Review is pressed.
    wallet.hold = Completer<void>();
    await tester.tap(find.descendant(of: find.byType(ERadioRow), matching: find.text('All')));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Review send'));
    await tester.pump();
    wallet.hold!.complete();
    wallet.hold = null;
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsOneWidget);
    await enterReviewPassword(tester);
    await tester.tap(find.byWidgetPredicate((w) => w is EButton && w.label.startsWith('Send 25')));
    await tester.pumpAndSettle();
    expect(wallet.sent.single.options?.strategy, SelectionStrategy.all);
  });
}
