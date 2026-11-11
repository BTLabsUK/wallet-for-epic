// SPDX-License-Identifier: Apache-2.0
// Overview's payments under way: the newest is a card with its steps, the next three are rows in
// one box, and from the fifth a "N more" line whose View opens Activity on Pending.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

/// [n] sends waiting for their recipients, the newest first (ids 1..n).
class _Wallet extends MockDeskWallet {
  _Wallet(this.n) : super(delay: Duration.zero);

  final int n;

  @override
  Future<List<Tx>> transactions() async => [
    for (var i = 1; i <= n; i++)
      Tx(
        id: i,
        slateId: 's$i',
        direction: TxDirection.sent,
        state: TxState.waitingRecipient,
        method: i == 3 ? TxMethod.file : TxMethod.epicbox,
        counterparty: i == 3 ? '/tmp/pay.tx' : null,
        amount: 1000000 * i,
        fee: 8000,
        created: DateTime(2026, 10, 27, 12).subtract(Duration(minutes: i)),
      ),
  ];
}

Future<ProviderContainer> _pump(WidgetTester tester, int n) async {
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet(n))]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: OverviewScreen())),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

Finder _card(int id) => find.byKey(ValueKey('overview-inflight-$id'));
Finder _row(int id) => find.byKey(ValueKey('overview-inflight-row-$id'));
final _more = find.byKey(const ValueKey('overview-inflight-more'));

void main() {
  testWidgets('one payment under way: a card, no rows, no more line', (tester) async {
    await _pump(tester, 1);
    expect(_card(1), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w.key.toString().contains('overview-inflight-row-')), findsNothing);
    expect(_more, findsNothing);
  });

  testWidgets('four: the newest as a card, the other three as rows, no more line', (tester) async {
    final container = await _pump(tester, 4);
    expect(_card(1), findsOneWidget);
    for (final id in [2, 3, 4]) {
      expect(_row(id), findsOneWidget);
      expect(_card(id), findsNothing);
    }
    expect(_more, findsNothing);
    // A row says the step it is at, as the card does, and opens its payment in Activity.
    expect(find.descendant(of: _row(2), matching: find.textContaining('Sending via Epicbox')), findsOneWidget);
    expect(find.descendant(of: _row(2), matching: find.text(_l.deskLvPayOnEpicbox)), findsOneWidget);
    // A file names no one: the row says how it goes, not "to file".
    expect(find.descendant(of: _row(3), matching: find.text('Sending via file')), findsOneWidget);
    await tester.tap(_row(3));
    await tester.pump();
    expect(container.read(deskNavProvider).route, DeskRoute.activity);
    expect(container.read(deskNavProvider).arg, 3);
  });

  testWidgets('seven: a card, three rows and "3 more"; View opens Activity on Pending', (tester) async {
    final container = await _pump(tester, 7);
    expect(_card(1), findsOneWidget);
    for (final id in [2, 3, 4]) {
      expect(_row(id), findsOneWidget);
    }
    for (final id in [5, 6, 7]) {
      expect(_row(id), findsNothing);
      expect(_card(id), findsNothing);
    }
    expect(find.descendant(of: _more, matching: find.text('3 more payments under way')), findsOneWidget);
    await tester.tap(find.descendant(of: _more, matching: find.text(_l.deskOvInflightView)));
    await tester.pump();
    final at = container.read(deskNavProvider);
    expect(at.route, DeskRoute.activity);
    expect(at.arg, isA<ActivityArgs>().having((a) => a.pending, 'pending', true));
  });
}
