// SPDX-License-Identifier: Apache-2.0
// The fee line of a desktop cancel confirmation (WAL-20 copy, 2026-10-30): when the cancel also
// moves the coins back to this wallet (a send the network refused, an invoice this wallet paid),
// the dialog names the normal network fee on its own line with an info icon that opens the
// explanation as a popover; a plain cancel (a send still waiting) has neither.
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
final Finder _popover = find.byKey(const ValueKey('info-popover-text'));

Tx _send({required bool notPosted}) => Tx(
  id: 77,
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

Future<ProviderContainer> _container(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskClockProvider.overrideWithValue(() => _now)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  return container;
}

Future<void> _pump(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await _container(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: body)),
      ),
    ),
  );
  await _frames(tester);
}

/// A waiting send's step animates for ever: bounded frames, never pumpAndSettle.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Unmounts the widget and lets Riverpod's auto-dispose timer run before the test ends.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('a send the network refused: the fee line with its info icon, which opens the explanation', (tester) async {
    await _pump(tester, TxDetail(tx: _send(notPosted: true)));
    await tester.tap(find.widgetWithText(EButton, _l.deskTxCancelOutgoingAction).first);
    await _frames(tester);
    expect(find.text(_l.deskTxCancelOutgoingTitle), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsOneWidget);
    expect(find.byKey(deskCancelFeeHintKey), findsOneWidget);
    // Beside the fee line: the icon sits on the same row as the text.
    final line = tester.getRect(find.text(_l.cancelFeeLine));
    final icon = tester.getRect(find.byKey(deskCancelFeeHintKey));
    expect(icon.left, greaterThanOrEqualTo(line.right - 1));
    expect(icon.center.dy, closeTo(line.center.dy, 12));
    await tester.tap(find.byKey(deskCancelFeeHintKey));
    await _frames(tester);
    expect(_popover, findsOneWidget);
    expect(find.text(_l.cancelChoicesTitle), findsOneWidget);
    expect(find.text(_l.cancelChoicesWhy), findsOneWidget);
    await _end(tester);
  });

  testWidgets('a send still waiting: a plain cancel, no fee line, no icon', (tester) async {
    await _pump(tester, TxDetail(tx: _send(notPosted: false)));
    await tester.tap(find.widgetWithText(EButton, _l.deskTxCancelOutgoingAction).first);
    await _frames(tester);
    expect(find.text(_l.deskTxCancelOutgoingTitle), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsNothing);
    expect(find.byKey(deskCancelFeeHintKey), findsNothing);
    expect(find.byType(EInfoHint), findsNothing);
    await _end(tester);
  });

  testWidgets('an invoice paid: the fee line with its info icon', (tester) async {
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
    await _pump(
      tester,
      Builder(builder: (context) => EButton(label: 'open', onPressed: () => showCancelPaymentDialog(context, invoice))),
    );
    await tester.tap(find.text('open'));
    await _frames(tester);
    expect(find.text(_l.deskInvPayerCancelTitle), findsOneWidget);
    expect(find.text(_l.deskInvPayerCancelText), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsOneWidget);
    expect(find.byKey(deskCancelFeeHintKey), findsOneWidget);
    await tester.tap(find.byKey(deskCancelFeeHintKey));
    await _frames(tester);
    expect(find.text(_l.cancelChoicesWhy), findsOneWidget);
    await _end(tester);
  });
}
