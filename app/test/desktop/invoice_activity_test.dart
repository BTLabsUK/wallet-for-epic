// Issued invoices in Activity on the mock (R-1 S-2, S-3): a row reads "Unpaid" only while
// the invoice waits for its payer; the details of a waiting one say Unpaid by the big amount.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/tx_invoice_block.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Activity on [api], with [arg] (a transaction id selects it).
Future<void> _open(WidgetTester tester, MockDeskWallet api, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(DeskRoute.activity, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Iterable<String> _labels(WidgetTester tester) =>
    tester.widgetList<Semantics>(find.byType(Semantics)).map((s) => s.properties.label ?? '').where((l) => l.isNotEmpty);

void main() {
  testWidgets('a row reads Unpaid only while the issued invoice waits', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    final book = (await tester.runAsync(api.invoices))!;
    final waiting = book.sent.firstWhere((r) => r.state == RequestState.waiting);
    final paid = book.sent.firstWhere((r) => r.state == RequestState.confirming);
    await _open(tester, api);
    final labels = _labels(tester).toList();
    expect(labels.where((l) => l.startsWith('Unpaid ${formatEpic(waiting.amount)} EPIC')), hasLength(1));
    expect(labels.where((l) => l.startsWith('Unpaid ${formatEpic(paid.amount)} EPIC')), isEmpty, reason: labels.join('\n'));
    expect(labels.where((l) => l.startsWith('Invoice ${formatEpic(paid.amount)} EPIC')), hasLength(1));
  });

  testWidgets('the details of a waiting issued invoice say Unpaid by the amount', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    final book = (await tester.runAsync(api.invoices))!;
    final waiting = book.sent.firstWhere((r) => r.state == RequestState.waiting);
    await _open(tester, api, arg: waiting.txId);
    expect(find.byType(TxInvoiceBlock), findsOneWidget);
    // The row's caption and the details' caption.
    expect(find.text('Unpaid'), findsNWidgets(2));
  });
}
