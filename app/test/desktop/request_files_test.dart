// SPDX-License-Identifier: Apache-2.0
// Payment requests by file on the desktop (DESIGN §3.2, §3.3), on the mock wallet: the request
// form's "Save as a file for anyone" and its saved panel, and Import reading a request file into
// its Review, paying it behind the password and saving the answer.
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/invoice_parts.dart' show InvButton;
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/review_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/import_tx_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';


final _l = englishStrings;
late ProviderContainer _c;
late MockDeskWallet _mock;
late MockDeskHistoryFiles _saves;

class _PickRequest implements DeskFiles {
  @override
  Future<String?> pickSlate({required String title}) async => '/home/alex/mail/request-12.5.slate';

  @override
  Future<List<PickedSlate>> pickSlates({required String title}) async => const [];
}

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, Widget screen, {bool requestFiles = true}) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _mock = MockDeskWallet(delay: Duration.zero)..supportsRequestFiles = requestFiles;
  _saves = MockDeskHistoryFiles();
  _c = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_mock),
      deskHistoryFilesProvider.overrideWithValue(_saves),
      deskFilesProvider.overrideWithValue(_PickRequest()),
    ],
  );
  addTearDown(_c.dispose);
  await tester.runAsync(() => _c.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await _real(tester);
}

/// Picks "Save as a file for anyone" under To (the mock has a contact that pays requests).
Future<void> _toFile(WidgetTester tester) async {
  await tester.tap(find.byType(ESelect<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l.reqToFile).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  group('request form', () {
    testWidgets('Save as a file for anyone: the saved panel with the file, and the request waits By file', (tester) async {
      await _open(tester, const IssueInvoiceScreen());
      expect(find.byKey(deskRequestSaveFileKey), findsNothing);
      await _toFile(tester);
      expect(find.text(_l.reqToFile), findsWidgets);
      await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskInvIssuerAmount), matching: find.byType(EditableText)), '42.5');
      await tester.pump();
      await tester.tap(find.byKey(deskRequestSaveFileKey));
      await _real(tester, 1200);
      expect(find.byKey(deskRequestFileDoneKey), findsOneWidget);
      expect(find.text(_l.reqFileSaved), findsOneWidget);
      expect(find.text(_l.reqFileLead), findsOneWidget);
      expect(_saves.saved.single, endsWith('.tx'));
      expect(find.text(_l.deskInvIssuerAnother), findsOneWidget);
      final sent = (await tester.runAsync(_mock.invoices))!.sent.where((r) => r.byFile).toList();
      expect(sent, hasLength(1));
      expect(sent.single.amount, 4250000000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a save dialog closed leaves Save as file on the panel', (tester) async {
      await _open(tester, const IssueInvoiceScreen());
      await _toFile(tester);
      _saves.saves.add(null);
      await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskInvIssuerAmount), matching: find.byType(EditableText)), '1');
      await tester.pump();
      await tester.tap(find.byKey(deskRequestSaveFileKey));
      await _real(tester, 1200);
      expect(find.byKey(deskRequestFileDoneKey), findsOneWidget);
      expect(find.widgetWithText(InvButton, _l.reqSaveFile), findsOneWidget);
      await tester.tap(find.widgetWithText(InvButton, _l.reqSaveFile));
      await _real(tester);
      expect(_saves.saved, hasLength(1));
    });

    testWidgets('without request files on the core: no file item, no Save as file', (tester) async {
      await _open(tester, const IssueInvoiceScreen(), requestFiles: false);
      await tester.tap(find.byType(ESelect<String>));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqToFile), findsNothing);
      expect(find.byKey(deskRequestSaveFileKey), findsNothing);
    });
  });

  group('Import a request file', () {
    testWidgets('opens the Review in its file form; Approve asks the password and saves the answer', (tester) async {
      await _open(tester, const ImportTxScreen());
      await tester.tap(find.text(_l.deskFinChooseFile));
      await _real(tester);
      expect(find.text(_l.reqFromFileTitle), findsOneWidget);
      expect(find.byKey(deskRequestFileWarnKey), findsOneWidget);
      expect(find.text(_l.reqFileMessageLabel), findsOneWidget);
      expect(find.text('Invoice 2026-118, two bags of beans'), findsOneWidget);
      await tester.ensureVisible(find.byKey(deskRequestFileApproveKey));
      await tester.tap(find.byKey(deskRequestFileApproveKey));
      await _real(tester);
      final field = find.descendant(of: find.byType(EDialog), matching: find.byType(EditableText));
      await tester.enterText(field, 'correct horse');
      await tester.tap(find.widgetWithText(InvButton, _l.deskInvPayerPay));
      await _real(tester, 2000);
      expect(find.text(_l.reqAnswerTitle), findsOneWidget);
      expect(find.text(_l.reqAnswerLead), findsOneWidget);
      // Money left: the page no longer says signing spends nothing, nor offers to sign.
      expect(find.text(_l.deskImpNoticeTitle), findsNothing);
      expect(find.text(_l.deskImpTitle), findsNothing);
      expect(find.text(_l.reqTitle), findsOneWidget);
      expect(find.text(_l.deskImpAnother), findsNothing);
      expect(find.text(_l.deskImpOpenAnother), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Not now goes back and pays nothing', (tester) async {
      await _open(tester, const ImportTxScreen());
      await tester.tap(find.text(_l.deskFinChooseFile));
      await _real(tester);
      await tester.ensureVisible(find.text(_l.reqNotNow));
      await tester.tap(find.text(_l.reqNotNow));
      await _real(tester);
      expect(find.text(_l.reqFromFileTitle), findsNothing);
      expect(find.text(_l.deskImpChoose), findsOneWidget);
      final txs = (await tester.runAsync(_mock.transactions))!;
      expect(txs.where((t) => t.slateId == MockDeskWallet.mockRequestSlate), isEmpty);
    });

    testWidgets('one paid before opens read-only: already paid', (tester) async {
      await _open(tester, const ImportTxScreen());
      final file = (await tester.runAsync(() => _mock.readRequestFile('request.slate')))!;
      await tester.runAsync(() => _mock.payRequestFile(file, password: 'x'));
      await tester.tap(find.text(_l.deskFinChooseFile));
      await _real(tester);
      expect(find.text(_l.reqFileAlreadyPaid), findsOneWidget);
      expect(find.byKey(deskRequestFileApproveKey), findsNothing);
    });
  });
}
