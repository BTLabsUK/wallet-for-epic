// SPDX-License-Identifier: Apache-2.0
// A payment a scan found reads "Restored" or "Found by recheck" by which scan found it; the
// time is called the block's only when it is; an older entry makes no claim about the scan.
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

Tx _found({FoundDuring? during, bool byBlock = true}) => Tx(
  id: 1,
  slateId: '',
  direction: TxDirection.received,
  state: TxState.confirmed,
  method: TxMethod.epicbox,
  amount: nanoPerEpic,
  fee: 0,
  created: DateTime(2026, 3, 14, 9, 12),
  confirmations: 900,
  foundByScan: true,
  foundDuring: during,
  datedByBlock: byBlock,
);

void main() {
  test('the four kinds', () {
    final restored = foundTexts(englishStrings, _found(during: FoundDuring.restore));
    expect(restored.label, _l.deskTxFoundRestoredLabel);
    expect(restored.line, _l.deskTxFoundRestoredLine);
    expect(restored.step, _l.deskTxFoundRestoredStep);
    expect(restored.note, 'Time of the block. The sender is unknown.');
    expect(restored.tip, 'Found on the chain while restoring this wallet. The sender is not recorded.');

    final rescan = foundTexts(englishStrings, _found(during: FoundDuring.rescan));
    expect(rescan.label, 'Found by recheck');
    expect(rescan.line, 'Found by recheck');
    expect(rescan.tip, 'Found on the chain by a balance recheck. The sender is not recorded.');
    expect(rescan.note, 'Time of the block. The sender is unknown.');

    final scanTime = foundTexts(englishStrings, _found(during: FoundDuring.rescan, byBlock: false));
    expect(scanTime.note, 'Time of the scan; the block’s time could not be read. The sender is not recorded.');

    final older = foundTexts(englishStrings, _found());
    expect(older.label, 'Found by recheck');
    expect(older.step, 'Found by a scan');
    expect(older.note, 'The sender is not recorded.');
    expect(older.tip, 'Found on the chain by a scan. The sender is not recorded.');

    expect(whoOf(englishStrings, _found(during: FoundDuring.restore)), 'Restored');
    expect(methodOf(englishStrings, _found()), isNull);
    // No "The time is the block time" sentence is left anywhere.
    for (final t in [restored, rescan, scanTime, older]) {
      expect('${t.label}${t.line}${t.step}${t.note}${t.tip}', isNot(contains('when the scan')));
    }
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SingleChildScrollView(child: child))),
    ));
    await tester.pump();
  }

  testWidgets('a row: the label, the origin line, the tooltip', (tester) async {
    await pump(tester, TxRow(tx: _found(during: FoundDuring.restore), onTap: () {}));
    expect(find.text(_l.deskTxFoundRestoredLabel), findsOneWidget);
    expect(find.textContaining(_l.deskTxFoundRestoredLine), findsOneWidget);
    expect(find.byTooltip(_l.deskTxFoundRestoredTip), findsOneWidget);
  });

  testWidgets('the detail: restored under the amount, the found step first, Method –', (tester) async {
    await pump(tester, TxDetail(tx: _found(during: FoundDuring.restore)));
    expect(find.text(_l.deskTxHeadRestored), findsOneWidget);
    expect(find.textContaining('from '), findsNothing);
    expect(find.text(_l.deskTxFoundRestoredStep), findsOneWidget);
    expect(find.text(_l.deskTxNoteBlock), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(find.text('From'), findsNothing);
  });

  testWidgets('the detail of a rescan find with the scan time', (tester) async {
    await pump(tester, TxDetail(tx: _found(during: FoundDuring.rescan, byBlock: false)));
    expect(find.text(_l.deskTxHeadFoundOnChain), findsOneWidget);
    expect(find.text(_l.deskTxFoundRescanStep), findsOneWidget);
    expect(find.text('Time of the scan; the block’s time could not be read. The sender is not recorded.'), findsOneWidget);
  });
}
