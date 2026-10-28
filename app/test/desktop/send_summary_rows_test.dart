// SPDX-License-Identifier: Apache-2.0
// Send's output lines: Balance after, Spendable until change confirms and
// its caption, the split line, the strategy line, Advanced, and the review dialog's facts.
import 'package:epic_wallet/src/desktop/screens/transfer/send_advanced.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_summary_rows.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _nano(double epic) => (epic * nanoPerEpic).round();

final int _total = _nano(1309.73215);
final int _spendable = _nano(1284.73215);

SendSummary _summary({int inputs = 1, double locked = 34.73215, double change = 9.72415, int changeOutputs = 1}) => SendSummary.of(
  balance: _total,
  spendable: _spendable,
  estimate: SendEstimate(amount: _nano(25), fee: _nano(0.008), inputCount: inputs, locked: _nano(locked), change: _nano(change), changeOutputs: changeOutputs),
);

Finder _rich(String text) => find.text(text, findRichText: true);

void main() {
  Future<void> host(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: SizedBox(width: 300, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Smallest: what stays spendable and the lock caption', (tester) async {
    await host(tester, SendLockRows(summary: _summary(), strategy: SelectionStrategy.smallest, defaultStrategy: SelectionStrategy.smallest, blocks: 6));
    expect(find.text('Balance after'), findsOneWidget);
    expect(_rich('1,284.72415 EPIC'), findsOneWidget);
    expect(find.text('Spendable until change confirms'), findsOneWidget);
    expect(_rich('1,250.0000 EPIC'), findsOneWidget);
    expect(find.text('1 output locked, 34.73215 EPIC, about 6 blocks.'), findsOneWidget);
    expect(find.textContaining('Strategy for this send'), findsNothing);
  });

  testWidgets('All: nothing spendable, in warn, and the strategy line', (tester) async {
    await host(tester, SendLockRows(summary: _summary(inputs: 5, locked: 1284.73215, change: 1259.72415), strategy: SelectionStrategy.all, defaultStrategy: SelectionStrategy.smallest, blocks: 6));
    expect(_rich('0.0000 EPIC'), findsOneWidget);
    final caption = find.text('Everything is locked: 5 outputs, 1,284.73215 EPIC, about 6 blocks.');
    expect(caption, findsOneWidget);
    final context = tester.element(caption);
    expect(tester.widget<Text>(caption).style?.color, context.dc.warn);
    expect(find.text('Strategy for this send: All · 5 outputs.'), findsOneWidget);
  });

  testWidgets('no change: nothing waits', (tester) async {
    await host(tester, SendLockRows(summary: _summary(inputs: 2, locked: 25.008, change: 0, changeOutputs: 0), strategy: SelectionStrategy.smallest, defaultStrategy: SelectionStrategy.smallest, blocks: 6));
    expect(find.text('No change: 2 outputs spent exactly, nothing waits.'), findsOneWidget);
  });

  testWidgets('before an amount: dashes and no caption', (tester) async {
    await host(tester, const SendLockRows(summary: null, strategy: SelectionStrategy.smallest, defaultStrategy: SelectionStrategy.smallest, blocks: 6));
    expect(find.text('—'), findsNWidgets(2));
    expect(find.textContaining('locked'), findsNothing);
  });

  testWidgets('the split line and why', (tester) async {
    await host(tester, SendSplitLine(outputs: 4, extraFee: _nano(0.012), change: _nano(9.72415)));
    expect(find.text('Change split into 4 outputs (+0.012 EPIC fee)'), findsOneWidget);
    expect(SendSplitLine.why(englishStrings, 4, _nano(9.72415)), 'So the next send does not wait for this one to confirm. Change comes back as 4 outputs of about 2.4310 EPIC instead of one.');
    await tester.tap(find.byType(HelpTip));
    await tester.pumpAndSettle();
    expect(find.text(SendSplitLine.why(englishStrings, 4, _nano(9.72415))), findsOneWidget);
  });

  group('Advanced', () {
    Future<List<SelectionStrategy>> advanced(WidgetTester tester, {SelectionStrategy def = SelectionStrategy.smallest, bool sendAll = false}) async {
      final picked = <SelectionStrategy>[];
      await host(
        tester,
        SendAdvanced(
          strategy: def,
          defaultStrategy: def,
          split: true,
          sendAll: sendAll,
          initiallyOpen: true,
          onStrategy: picked.add,
          onSplit: (_) {},
          onOutputs: () {},
        ),
      );
      return picked;
    }

    testWidgets('the default tag follows the default; a radio picks', (tester) async {
      final picked = await advanced(tester, def: SelectionStrategy.all);
      expect(find.text('Send options · All outputs', findRichText: true), findsOneWidget);
      final tag = find.text('default');
      expect(tag, findsOneWidget);
      expect(find.ancestor(of: tag, matching: find.byWidgetPredicate((w) => w is ERadioRow && w.title == 'All')), findsOneWidget);
      await tester.tap(find.text('Smallest'));
      expect(picked, [SelectionStrategy.smallest]);
    });

    testWidgets('send all turns the radios off', (tester) async {
      final picked = await advanced(tester, sendAll: true);
      expect(find.text('Sending everything spends every output.'), findsOneWidget);
      await tester.tap(find.text('Smallest'));
      expect(picked, isEmpty);
    });

    test('subtitle says when the change is not split', () {
      expect(advancedSubtitle(englishStrings, SelectionStrategy.smallest, split: false), '· Smallest outputs, change not split');
    });
  });

  test('review lines', () {
    final normal = reviewOutputLines(englishStrings, _summary(), strategy: SelectionStrategy.smallest, defaultStrategy: SelectionStrategy.smallest, blocks: 6);
    expect(normal.feeSecondLine, isNull);
    expect(normal.facts.map((f) => f.$1), ['Locks']);
    expect(reviewLocks(englishStrings, _summary(), SelectionStrategy.smallest, 6), '34.73215 EPIC in 1 output until the change confirms (6 blocks). 1,250.0000 EPIC stays spendable.');

    final all = _summary(inputs: 5, locked: 1284.73215, change: 1259.72415);
    expect(reviewLocks(englishStrings, all, SelectionStrategy.all, 6), 'Everything: 1,284.73215 EPIC in 5 outputs until the change confirms (6 blocks). Nothing stays spendable.');
    expect(reviewLocks(englishStrings, all, SelectionStrategy.smallest, 6), '1,284.73215 EPIC in 5 outputs until the change confirms (6 blocks). Nothing else is spendable meanwhile.');
    expect(reviewLocks(englishStrings, _summary(inputs: 2, locked: 25.008, change: 0, changeOutputs: 0), SelectionStrategy.smallest, 6), '25.0080 EPIC in 2 outputs; no change comes back.');

    final split = reviewOutputLines(englishStrings, _summary(changeOutputs: 4), strategy: SelectionStrategy.all, defaultStrategy: SelectionStrategy.smallest, blocks: 6, extraFee: _nano(0.012));
    expect(split.feeSecondLine, 'Change split into 4 outputs (+0.012 EPIC).');
    expect(split.facts.map((f) => f.$1), ['Locks', 'Strategy']);

    // Strategy All consolidates: with the line given it says one change output, never a split.
    final l = lookupAppLocalizations(const Locale('en'));
    final allLine = reviewOutputLines(englishStrings, all, strategy: SelectionStrategy.all, defaultStrategy: SelectionStrategy.smallest, blocks: 6, usesAll: l.sendUsesAllOutputs);
    expect(allLine.feeSecondLine, 'Uses all 5 outputs · change 1 output');
  });
}
