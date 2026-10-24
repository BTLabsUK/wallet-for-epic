// Invoices in Activity on the mock (R-1 S-2, S-3): a row reads "Unpaid" only while the
// invoice waits for its payer; the details of a waiting one say Unpaid by the big amount; a
// Open in Invoices opens every invoice transaction on its tab, selected.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/invoice_parts.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/issue_tab.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/pay_tab.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/tx_invoice_block.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Activity on [api], with [arg] (a transaction id selects it).
Future<void> _open(WidgetTester tester, MockDeskWallet api, {Object? arg, Size size = const Size(1280, 800)}) async {
  tester.view.physicalSize = size;
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

Future<void> _tapOpen(WidgetTester tester) async {
  final open = find.text('Open in Invoices');
  await tester.ensureVisible(open);
  await tester.tap(open);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// The row opened from Activity.
final _selected = find.byWidgetPredicate((w) => w is InvReveal && w.selected);

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

  testWidgets('Open in Invoices on a paid invoice waiting to post: Pay tab, under Paid, selected', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    for (final w in (await tester.runAsync(api.invoices))!.waiting) {
      await tester.runAsync(() => api.payInvoice(w.slateId, amount: w.amount, password: 'pass'));
    }
    final book = (await tester.runAsync(api.invoices))!;
    final delivered = book.toPay.lastWhere((i) => i.state == PayState.delivered);
    expect(book.needsAction.where((i) => i.slateId == delivered.slateId), isEmpty, reason: 'To pay does not list it');
    await _open(tester, api, arg: delivered.txId, size: const Size(1920, 1000));
    await _tapOpen(tester);
    expect(find.byType(TxInvoiceBlock), findsNothing);
    expect(find.byType(PayTab), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(_selected, findsOneWidget);
    expect(find.descendant(of: _selected, matching: find.text(delivered.label)), findsOneWidget);
    expect(find.text('No invoices are waiting'), findsNothing, reason: 'never an empty tab');
  });

  // linux-12: a reply that reached a relay the service never reads leaves the payment waiting
  // to post with its coins locked. Its details offer Send again and say when Cancel comes.
  testWidgets('a paid invoice waiting to post offers Send again, which sends the reply again', (tester) async {
    final api = _Resends();
    for (final w in (await tester.runAsync(api.invoices))!.waiting) {
      await tester.runAsync(() => api.payInvoice(w.slateId, amount: w.amount, password: 'pass'));
    }
    final book = (await tester.runAsync(api.invoices))!;
    final delivered = book.toPay.lastWhere((i) => i.state == PayState.delivered);
    await _open(tester, api, arg: delivered.txId, size: const Size(1920, 1000));
    expect(find.byType(TxInvoiceBlock), findsOneWidget);
    expect(find.textContaining('Cancel becomes available once'), findsOneWidget);
    final again = find.descendant(of: find.byType(TxInvoiceBlock), matching: find.text('Send again'));
    await tester.ensureVisible(again);
    await tester.tap(again);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(api.resent, [delivered.slateId]);
  });

  testWidgets('Open in Invoices on an issued invoice: Issue tab, selected', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    final book = (await tester.runAsync(api.invoices))!;
    // The last row, not the one Issue selects by itself.
    final issued = book.sent.lastWhere((r) => r.state == RequestState.expired);
    await _open(tester, api, arg: issued.txId, size: const Size(1920, 1000));
    expect(find.byType(TxInvoiceBlock), findsOneWidget);
    await _tapOpen(tester);
    expect(find.byType(TxInvoiceBlock), findsNothing);
    expect(find.byType(IssueTab), findsOneWidget);
    expect(_selected, findsOneWidget);
    expect(find.descendant(of: _selected, matching: find.text(payerOf(issued))), findsOneWidget);
  });

  testWidgets('Open in Invoices on a withdrawn payment opens it among the payments to settle', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    for (final w in (await tester.runAsync(api.invoices))!.waiting) {
      await tester.runAsync(() => api.payInvoice(w.slateId, amount: w.amount, password: 'pass'));
    }
    var book = (await tester.runAsync(api.invoices))!;
    final delivered = book.toPay.lastWhere((i) => i.state == PayState.delivered);
    // Wide enough for the test font's "Withdrawn after paying" tag.
    await _open(tester, api, arg: delivered.txId, size: const Size(1920, 1000));
    expect(find.byType(TxInvoiceBlock), findsOneWidget);

    api.proto.serviceWithdraws();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    book = (await tester.runAsync(api.invoices))!;
    final withdrawn = book.toPay.singleWhere((i) => i.state == PayState.withdrawnAfterPay);
    expect(withdrawn.slateId, delivered.slateId);
    await _tapOpen(tester);
    expect(find.byType(TxInvoiceBlock), findsNothing);
    expect(_selected, findsOneWidget);
    expect(find.text('${withdrawn.label} withdrew an invoice you paid'), findsOneWidget);
    expect(find.text('Cancel payment'), findsOneWidget);
  });
}

/// The mock, recording each reply sent again.
class _Resends extends MockDeskWallet {
  _Resends() : super(delay: Duration.zero);

  final resent = <String>[];

  @override
  Future<IncomingInvoice> retryInvoiceReply(String slateId) {
    resent.add(slateId);
    return super.retryInvoiceReply(slateId);
  }
}
