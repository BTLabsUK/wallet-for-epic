// SPDX-License-Identifier: Apache-2.0
// The desktop's cancel confirmations (WAL-20, 2026-10-30). A send both wallets signed that the
// network refused offers Keep / Unlock coins / Move coins back, under a calm two-line
// comparison (B-04). Unlock coins cancels with no spend back and a calm toast; Move coins back
// spends back as before. A send still waiting keeps one
// free cancel. The invoice payer's dialog has the same three buttons.
import 'package:epic_wallet/src/cancel_final.dart' show CancelResult;
import 'package:epic_wallet/src/desktop/data/clock.dart';
import 'package:epic_wallet/src/desktop/data/invoices.dart' show IncomingInvoice, PayState;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/pay_dialogs.dart' show showCancelPaymentDialog;
import 'package:epic_wallet/src/desktop/screens/wallet/cancel_note.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;
final _now = DateTime(2026, 10, 30, 12);

/// Records every cancel with its spend-back choice.
class _Desk extends MockDeskWallet {
  _Desk() : super(delay: Duration.zero);

  final List<(int, bool)> cancels = [];

  @override
  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) {
    cancels.add((id, spendBack));
    return super.cancelTx(id, spendBack: spendBack);
  }
}

Tx _send({required bool notPosted, int id = 77}) => Tx(
  id: id,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  direction: TxDirection.sent,
  state: notPosted ? TxState.posted : TxState.waitingRecipient,
  method: TxMethod.epicbox,
  amount: 250000000,
  fee: 7000000,
  created: DateTime(2026, 10, 20),
  counterparty: 'esAlice@epicbox.example',
  cancellable: true,
  notPosted: notPosted,
);

Future<_Desk> _pump(WidgetTester tester, Widget Function(BuildContext) body) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final desk = _Desk();
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(desk), deskClockProvider.overrideWithValue(() => _now)]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Builder(builder: body))),
      ),
    ),
  );
  await _frames(tester);
  return desk;
}

/// A waiting send's step animates for ever: bounded frames, never pumpAndSettle.
Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Unmounts the widget and lets Riverpod's auto-dispose timer run before the test ends.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

Finder _button(String label) => find.widgetWithText(EButton, label);

void main() {
  group('a send both signed that the network refused', () {
    testWidgets('three choices named by outcome, the two-line comparison above them', (tester) async {
      await _pump(tester, (_) => TxDetail(tx: _send(notPosted: true)));
      await tester.tap(_button(_l.deskTxCancelOutgoingAction).first);
      await _frames(tester);
      expect(find.text(_l.deskTxCancelOutgoingTitle), findsOneWidget);
      expect(find.byType(DeskCancelChoices), findsOneWidget);
      expect(_button(_l.deskTxCancelKeep), findsOneWidget);
      expect(_button(_l.cancelUnlockOpen), findsOneWidget);
      expect(_button(_l.cancelMoveBack), findsOneWidget);
      // A calm two-line comparison above the buttons; no caption per way, no info icon (B-04).
      expect(find.text(_l.cancelCompareMoveBack), findsOneWidget);
      expect(find.text(_l.cancelCompareUnlock), findsOneWidget);
      expect(find.text(_l.cancelFeeLine), findsNothing);
      expect(find.byKey(deskCancelFeeHintKey), findsNothing);
      expect(find.text(_l.cancelMoreInHelp), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
      // The main button is the last one: at the end of the bar, after Unlock coins, which comes
      // after Keep (the bar may wrap onto a second row when the labels are long).
      final sure = tester.getRect(_button(_l.cancelMoveBack));
      final stop = tester.getRect(_button(_l.cancelUnlockOpen));
      final keep = tester.getRect(_button(_l.deskTxCancelKeep));
      expect(sure.bottom, greaterThanOrEqualTo(stop.bottom - 1));
      expect(sure.bottom, greaterThanOrEqualTo(keep.bottom - 1));
      expect(stop.bottom, greaterThanOrEqualTo(keep.bottom - 1));
      if ((sure.center.dy - stop.center.dy).abs() < 1) expect(stop.right, lessThanOrEqualTo(sure.left + 1));
      if ((stop.center.dy - keep.center.dy).abs() < 1) expect(keep.right, lessThanOrEqualTo(stop.left + 1));
      await _end(tester);
    });

    testWidgets('Unlock coins: cancelled with no spend back, a calm toast', (tester) async {
      final desk = await _pump(tester, (_) => TxDetail(tx: _send(notPosted: true, id: MockDeskWallet.signedCancelDemoId)));
      desk.addSignedCancelDemo(id: MockDeskWallet.signedCancelDemoId);
      await tester.tap(_button(_l.deskTxCancelOutgoingAction).first);
      await _frames(tester);
      await tester.tap(_button(_l.cancelUnlockOpen));
      await _frames(tester, 20);
      expect(desk.cancels, [(MockDeskWallet.signedCancelDemoId, false)]);
      expect(find.text(_l.cancelStoppedWaitingTitle), findsOneWidget);
      expect(find.text(_l.cancelStoppedWaitingText), findsOneWidget);
      expect(find.text(_l.deskInvPayerSpentText), findsNothing);
      await _end(tester);
    });

    testWidgets('Move coins back: cancelled and spent back, as before', (tester) async {
      final desk = await _pump(tester, (_) => TxDetail(tx: _send(notPosted: true, id: MockDeskWallet.signedCancelDemoId)));
      desk.addSignedCancelDemo(id: MockDeskWallet.signedCancelDemoId);
      await tester.tap(_button(_l.deskTxCancelOutgoingAction).first);
      await _frames(tester);
      await tester.tap(_button(_l.cancelMoveBack));
      await _frames(tester, 20);
      expect(desk.cancels, [(MockDeskWallet.signedCancelDemoId, true)]);
      expect(find.text(_l.deskTxCancelled), findsOneWidget);
      expect(find.text(_l.deskInvPayerSpentText), findsOneWidget);
      await _end(tester);
    });

    testWidgets('Keep: nothing happens', (tester) async {
      final desk = await _pump(tester, (_) => TxDetail(tx: _send(notPosted: true)));
      await tester.tap(_button(_l.deskTxCancelOutgoingAction).first);
      await _frames(tester);
      await tester.tap(_button(_l.deskTxCancelKeep));
      await _frames(tester);
      expect(desk.cancels, isEmpty);
      expect(find.byType(DeskCancelChoices), findsNothing);
      await _end(tester);
    });
  });

  testWidgets('a send still waiting: one free cancel, no Stop waiting, no fee line', (tester) async {
    final desk = await _pump(tester, (_) => TxDetail(tx: _send(notPosted: false)));
    await tester.tap(_button(_l.deskTxCancelOutgoingAction).first);
    await _frames(tester);
    expect(find.byType(DeskCancelChoices), findsNothing);
    expect(_button(_l.cancelUnlockOpen), findsNothing);
    expect(_button(_l.cancelMoveBack), findsNothing);
    expect(find.text(_l.cancelFeeLine), findsNothing);
    expect(_button(_l.deskTxCancelOutgoingAction), findsNWidgets(2), reason: 'the pane and the dialog say the same');
    await tester.tap(_button(_l.deskTxCancelOutgoingAction).last);
    await _frames(tester, 20);
    expect(desk.cancels, [(77, true)]);
    await _end(tester);
  });

  testWidgets('an invoice paid: the same three buttons and the two lines', (tester) async {
    final invoice = IncomingInvoice(
      slateId: 'inv-1',
      senderAddress: 'esShop',
      label: 'Shop',
      amount: 8000000,
      fee: 1000000,
      receivedAt: _now.subtract(const Duration(days: 2)),
      expiresAt: _now.subtract(const Duration(days: 1)),
      state: PayState.posted,
    );
    await _pump(tester, (context) => EButton(label: 'open', onPressed: () => showCancelPaymentDialog(context, invoice)));
    await tester.tap(find.text('open'));
    await _frames(tester);
    expect(find.text(_l.deskInvPayerCancelTitle), findsOneWidget);
    expect(find.text(_l.deskInvPayerCancelText), findsOneWidget);
    expect(find.byType(DeskCancelChoices), findsOneWidget);
    expect(_button(_l.deskInvPayerKeepPayment), findsOneWidget);
    expect(_button(_l.cancelUnlockOpen), findsOneWidget);
    expect(_button(_l.cancelMoveBack), findsOneWidget);
    expect(find.text(_l.cancelCompareMoveBack), findsOneWidget);
    expect(find.text(_l.cancelCompareUnlock), findsOneWidget);
    await _end(tester);
  });
}
