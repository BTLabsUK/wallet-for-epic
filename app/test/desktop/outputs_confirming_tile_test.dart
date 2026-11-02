// SPDX-License-Identifier: Apache-2.0
// linux-08: Outputs read "Confirming 0.0 · 1 output". The tile counted an output awaiting
// finalization (a payment received, not yet posted by its sender) but showed only the value
// confirming on chain. Its value is the confirming and the finalizing value, as the phone's.
// #69: the Confirming tab then counted only the confirming outputs, so the tile said 2 and the
// table 1. Tile, tab and table now share one mapping (outputPart).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<Balance> balance() async => const Balance(spendable: 131900000, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 10000000);

  @override
  Future<List<Output>> outputs() async => const [
    Output(commitment: '08aa', value: 131900000, status: OutputStatus.unspent, height: 3767074, confirmations: 10),
    Output(commitment: '08bb', value: 10000000, status: OutputStatus.unconfirmed, awaitingFinalization: true),
  ];
}

void main() {
  testWidgets('Confirming shows the value of the outputs it counts', (tester) async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: OutputsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    // The tile: the column holding the label, its value and its count.
    final tile = find.ancestor(of: find.text('Confirming').first, matching: find.byType(Column)).first;
    expect(find.descendant(of: tile, matching: find.text('1 output')), findsOneWidget);
    final value = tester.widget<EMoney>(find.descendant(of: tile, matching: find.byType(EMoney)));
    expect(value.nano, 10000000);
    // Total's value is the sum of the tiles' values, as its count is the sum of theirs.
    final totalTile = find.ancestor(of: find.text('Total').first, matching: find.byType(Column)).first;
    expect(tester.widget<EMoney>(find.descendant(of: totalTile, matching: find.byType(EMoney))).nano, 131900000 + 10000000);
    expect(find.descendant(of: totalTile, matching: find.text('2 outputs')), findsOneWidget);
    // Its tab counts and lists the same output.
    final tabs = tester.widget<ESegmented<OutputsFilter>>(find.byType(ESegmented<OutputsFilter>));
    expect(tabs.segments.firstWhere((s) => s.value == OutputsFilter.confirming).count, 1);
  });

  test('every tile and its tab count the same outputs; All = Total = the sum of the tiles', () {
    const all = [
      Output(commitment: 'a', value: 1, status: OutputStatus.unspent),
      Output(commitment: 'b', value: 1, status: OutputStatus.confirming),
      Output(commitment: 'c', value: 1, status: OutputStatus.unconfirmed),
      Output(commitment: 'd', value: 1, status: OutputStatus.unconfirmed, awaitingFinalization: true),
      Output(commitment: 'e', value: 1, status: OutputStatus.unconfirmed, unpaidInvoice: true),
      Output(commitment: 'f', value: 1, status: OutputStatus.immature),
      Output(commitment: 'g', value: 1, status: OutputStatus.unconfirmed, isCoinbase: true, hasCategory: false),
      Output(commitment: 'h', value: 1, status: OutputStatus.locked),
      Output(commitment: 'i', value: 1, status: OutputStatus.spent),
    ];
    final n = outputCounts(all);
    int listed(OutputsFilter f, {bool showSpent = false}) => all.where((o) => outputListed(f, o.word, showSpent: showSpent)).length;
    expect(n.spendable, 1);
    expect(n.confirming, 3, reason: 'confirming, unconfirmed and awaiting finalization');
    expect(n.immature, 2, reason: 'immature and mining');
    expect(n.locked, 1);
    expect(n.total, 7, reason: 'every output with a part: not the unpaid invoice, not the spent one');
    expect(listed(OutputsFilter.spendable), n.spendable);
    expect(listed(OutputsFilter.confirming), n.confirming);
    expect(listed(OutputsFilter.locked), n.locked);
    // UD-008: every number reconciles.
    expect(listed(OutputsFilter.all), n.total);
    expect(n.total, n.spendable + n.confirming + n.immature + n.locked);
    expect(listed(OutputsFilter.all, showSpent: true), 8, reason: 'the spent row only on request');
    // And the values: Total's is the sum of the tiles' (Confirming's takes awaiting finalization).
    const b = Balance(spendable: 100, awaitingConfirmation: 20, awaitingFinalization: 3, immature: 40, locked: 5, reportedTotal: 165);
    expect(outputsTotalValue(b), b.spendable + (b.awaitingConfirmation + b.awaitingFinalization) + b.immature + b.locked);
    expect(outputsTotalValue(b), 168);
  });
}
