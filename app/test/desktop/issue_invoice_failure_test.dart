// SPDX-License-Identifier: Apache-2.0
// Send invoice's failure notice on the desktop: each common refusal reads as what failed and what
// to do, never the generic line when the wallet said why. The form runs on the mock wallet with
// requestPayment made to fail as the LEPIC wallet's would.
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/network_gate.dart' show NetBlocked;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;

/// The mock wallet, with requestPayment failing as [error].
class _Refusing extends MockDeskWallet {
  _Refusing(this.error) : super(delay: Duration.zero);

  final Object error;

  @override
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft) async => throw error;
}

Future<void> _real(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Opens the form on a wallet failing with [error], picks the first contact, asks 0.1 and sends.
Future<void> _sendFailing(WidgetTester tester, Object error) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Refusing(error))]);
  addTearDown(c.dispose);
  await tester.runAsync(() => c.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: IssueInvoiceScreen())),
    ),
  );
  await _real(tester);
  await tester.tap(find.byType(ESelect<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l.trustVerified).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.descendant(of: find.byType(EInput).first, matching: find.byType(TextField)), '0.1');
  await tester.pump();
  await tester.tap(find.text(_l.reqNewSend));
  await _real(tester);
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('a contact whose wallet does not pay invoices is named, with what to do instead', (tester) async {
    // As LEPIC's contactRefusesInvoices reaches the desk: an invalid invoice, the pairing failure behind it.
    final refused = pairingError(PairingFailure.refusesInvoices);
    await _sendFailing(tester, InvoiceError(InvoiceProblem.invalid, 'refused', cause: refused.kind.name, source: refused));
    expect(find.text(_l.deskInvFailed), findsNothing);
    expect(find.textContaining('does not pay invoices'), findsOneWidget);
    expect(find.text(_l.pairRefusesInvoicesBody), findsOneWidget);
  });

  testWidgets('Tor only before Tor is ready: the mode says why', (tester) async {
    await _sendFailing(tester, const NetBlocked(NetworkMode.torOnly, 'epicbox'));
    expect(find.text(_l.deskSetAdvModeTorOnlyText), findsOneWidget);
  });

  group('issueInvoiceFailure', () {
    String title(Object e) => issueInvoiceFailure(_l, e, name: 'Pairing Demo Shop').title;

    test('the relay or the node down: their own lines', () {
      expect(title(const InvoiceError(InvoiceProblem.notDelivered, 'x')), _l.deskInvIssuerNotDelivered);
      expect(title(const InvoiceError(InvoiceProblem.relayDown, 'x')), _l.deskInvIssuerNotDelivered);
      expect(title(const InvoiceError(InvoiceProblem.nodeDown, 'x')), _l.deskInvIssuerNodeDown);
    });

    test('a refusal by the contact names the contact', () {
      final refused = pairingError(PairingFailure.refusesInvoices);
      final f = issueInvoiceFailure(_l, InvoiceError(InvoiceProblem.invalid, 'x', source: refused), name: 'Pairing Demo Shop');
      expect(f.title, _l.pairRefusesInvoicesTitle('Pairing Demo Shop'));
      expect(f.body, _l.pairRefusesInvoicesBody);
      final waiting = pairingError(PairingFailure.waiting);
      expect(title(InvoiceError(InvoiceProblem.invalid, 'x', source: waiting)), _l.pairWaitingFor('Pairing Demo Shop'));
    });

    test('a busy wallet or the network off: the app\'s usual words', () {
      const busy = WalletError(kind: WalletErrorKind.walletBusy, message: 'busy');
      expect(title(const InvoiceError(InvoiceProblem.invalid, 'x', source: busy)), _l.deskErrWalletBusy);
    });

    test('an argument refused or anything unknown: the invoice was not sent', () {
      const bad = WalletError(kind: WalletErrorKind.invalidArgument, message: 'the amount must be above zero');
      expect(title(const InvoiceError(InvoiceProblem.invalid, 'x', source: bad)), _l.deskInvIssuerFailed);
      expect(title(const InvoiceError(InvoiceProblem.invalid, 'x')), _l.deskInvIssuerFailed);
      expect(title(StateError('x')), _l.deskInvIssuerFailed);
    });
  });
}
