// SPDX-License-Identifier: Apache-2.0
// History backup screens on the mock wallet: the Backup group's state line, the export, import and CSV
// dialogs with their result and error states, the backup reminder on Overview, and a From backup
// row in Activity.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/backup.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int exports = 0, dismissals = 0;

  @override
  Future<void> markHistoryExported(DateTime when) {
    exports++;
    return super.markHistoryExported(when);
  }

  @override
  Future<void> dismissHistoryReminder(DateTime when) {
    dismissals++;
    return super.dismissHistoryReminder(when);
  }
}

late _Wallet _api;
late MockDeskHistoryFiles _files;
final List<String> _opened = [];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _api = _Wallet();
  _files = MockDeskHistoryFiles();
  _opened.clear();
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_api),
      deskHistoryFilesProvider.overrideWithValue(_files),
      deskOpenFolderProvider.overrideWithValue((dir) async {
        _opened.add(dir);
        return true;
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A button that opens [dialog].
Widget _opener(Future<void> Function(BuildContext) dialog) => Builder(builder: (c) => TextButton(onPressed: () => dialog(c), child: const Text('open')));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('the state line in its three forms', () {
    final now = DateTime(2026, 10, 22, 16);
    expect(backupStateLine(englishStrings, const HistoryBackupState()), 'Never exported.');
    expect(
      backupStateLine(englishStrings, HistoryBackupState(lastExport: DateTime(2026, 10, 3, 14, 2), unbacked: 12), now: now),
      'Last export 3 Oct 2026, 14:02 · 12 payments since.',
    );
    expect(backupStateLine(englishStrings, HistoryBackupState(lastExport: DateTime(2026, 10, 22, 14, 2)), now: now), 'Last export today, 14:02 · nothing new since.');
    expect(deskHistoryFileName('mainnet', DateTime(2026, 10, 22), 'wfeh'), 'epic-wallet-data-20261022.wfeh');
    expect(deskHistoryFileName('mainnet', DateTime(2026, 10, 22), 'csv', wallet: 'Savings'), 'epic-wallet-data-savings-20261022.csv');
  });

  test('the wallet part of the file name', () {
    expect(deskWalletFileLabel('Savings'), 'savings');
    expect(deskWalletFileLabel('My Wallet #2'), 'my-wallet-2');
    expect(deskWalletFileLabel('Main wallet'), 'main-wallet');
    expect(deskWalletFileLabel('Savings account'), 'savings');
    expect(deskWalletFileLabel('Longwalletname'), 'longwalletna');
    expect(deskWalletFileLabel('Épargne'), 'pargne');
    expect(deskWalletFileLabel('a  b'), 'a-b');
    expect(deskWalletFileLabel('abcdefghijk lm'), 'abcdefghijk');
    expect(deskWalletFileLabel('钱包'), '');
    expect(deskWalletFileLabel('  '), '');
    expect(deskHistoryFileName('floonet', DateTime(2026, 10, 22), 'wfeh', wallet: 'ฉัน'), 'epic-wallet-data-floonet-20261022.wfeh');
  });

  test('CSV ranges: local days, inclusive; a custom day that is not a date gives none', () {
    final now = DateTime(2026, 10, 22);
    expect(csvDays(CsvRange.all, now: now), (from: null, to: null));
    expect(csvDays(CsvRange.lastYear, now: now), (from: DateTime(2025), to: DateTime(2025, 12, 31)));
    expect(csvDays(CsvRange.custom, now: now, from: '2026-01-01', to: '2026-02-30'), isNull);
    expect(csvDays(CsvRange.custom, now: now, from: '2026-01-01', to: '2026-01-31'), (from: DateTime(2026), to: DateTime(2026, 1, 31)));
  });

  testWidgets('the Backup group: three rows and the state line', (tester) async {
    await _pump(tester, const BackupGroup());
    // The group sits on Settings › Wallet as Backup.
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Export wallet data'), findsOneWidget);
    expect(find.text('Import wallet data'), findsOneWidget);
    // GP-049: the CSV row reads as the wallet data rows do.
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Last export 3 Oct 2026, 14:02 · 12 payments since.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Export…'), findsNWidgets(2));
  });

  testWidgets('export: Save as… writes, records the export and shows the path', (tester) async {
    await _pump(tester, _opener(showExportHistoryDialog));
    await _open(tester);
    expect(find.text('48 payments, 6 contacts'), findsOneWidget);
    expect(find.text('The recovery phrase, keys, the password'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Save as…'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.textContaining(RegExp(r'~/Documents/epic-wallet-data-([a-z0-9-]+-)?\d{8}\.wfeh')), findsOneWidget);
    expect(_api.exports, 1);
    expect(_files.saved.single, endsWith('.wfeh'));
    await tester.tap(find.widgetWithText(EButton, 'Open folder'));
    expect(_opened.single, '~/Documents');
  });

  testWidgets('export: closing the system dialog writes nothing and records nothing', (tester) async {
    await _pump(tester, _opener(showExportHistoryDialog));
    _files.saves.add(null);
    await _open(tester);
    await tester.tap(find.widgetWithText(EButton, 'Save as…'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(find.widgetWithText(EButton, 'Save as…'), findsOneWidget);
    expect(_api.exports, 0);
  });

  testWidgets('export: a write error says Not saved with the folder, and offers Try again', (tester) async {
    await _pump(tester, _opener(showExportHistoryDialog));
    _files.saves.add(const FileSystemException('Cannot open file', '/media/usb/x.wfeh', OSError('Permission denied', 13)));
    await _open(tester);
    await tester.tap(find.widgetWithText(EButton, 'Save as…'));
    await tester.pumpAndSettle();
    expect(find.text('Not saved'), findsOneWidget);
    expect(find.text('Could not write to /media/usb: Permission denied. Choose another folder.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Try again'), findsOneWidget);
    expect(_api.exports, 0);
  });

  testWidgets('import: the counts, then Nothing new for the same file', (tester) async {
    await _pump(tester, _opener(showImportHistoryDialog));
    await _open(tester);
    expect(
      find.text('A file from this wallet (same recovery phrase). Restore the wallet from its phrase first.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(EButton, 'Choose file…'));
    await tester.pumpAndSettle();
    expect(find.text('Imported'), findsOneWidget);
    // One summary of what came back.
    expect(find.textContaining('Imported: '), findsOneWidget);
    expect(find.textContaining('records were already here'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Done'));
    await tester.pumpAndSettle();
    await _open(tester);
    await tester.tap(find.widgetWithText(EButton, 'Choose file…'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing new'), findsOneWidget);
    expect(find.textContaining('was already here', findRichText: true), findsOneWidget);
  });

  testWidgets('import: a refused file shows its title and text above the list', (tester) async {
    await _pump(tester, _opener(showImportHistoryDialog));
    _api.nextImport = const HistoryFileError(HistoryFileProblem.otherChain, 'The file is from another network.');
    await _open(tester);
    await tester.tap(find.widgetWithText(EButton, 'Choose file…'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong network'), findsOneWidget);
    expect(find.text('The file is from another network.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Choose file…'), findsOneWidget);
    _files.picks.add(tooLargeHistoryFile);
    await tester.tap(find.widgetWithText(EButton, 'Choose file…'));
    await tester.pumpAndSettle();
    expect(find.text('The file is too large to be one.'), findsOneWidget);
  });

  testWidgets('CSV: the warning before any file; a bad custom day disables Save as…', (tester) async {
    await _pump(tester, _opener(showExportCsvDialog));
    await _open(tester);
    expect(find.text('Not encrypted.'), findsOneWidget);
    expect(find.textContaining(RegExp(r'payments? · '), findRichText: true), findsOneWidget);
    expect(_files.saved, isEmpty);
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, 'From'), matching: find.byType(EditableText)), '2026-13-01');
    await tester.pumpAndSettle();
    expect(find.text('Enter a date as 2026-01-31'), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Save as…')).onPressed, isNull);
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(EButton, 'Save as…'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(_files.saved.single, endsWith('.csv'));
    expect(find.textContaining('newest first. Amounts in EPIC with 8 decimals; dates in UTC.'), findsOneWidget);
  });

  testWidgets('the reminder names the count; Not now dismisses it', (tester) async {
    await _pump(tester, const SizedBox());
    final state = const HistoryBackupState(unbacked: 12, reminder: 12);
    await _pump(tester, HistoryReminder(state: state));
    expect(find.text('12 payments are not in your exported wallet data.'), findsOneWidget);
    expect(find.text('A restore from the recovery phrase brings back the balance, not who paid what.'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Not now'));
    await tester.pumpAndSettle();
    expect(_api.dismissals, 1);
    await _pump(tester, HistoryReminder(state: HistoryBackupState(lastExport: DateTime(2026, 9), unbacked: 11, reminder: 11)));
    expect(find.text('11 payments are new or changed since the last wallet data export.'), findsOneWidget);
  });

  testWidgets('a payment only a backup knows reads From backup, with no Cancel', (tester) async {
    final t = Tx(
      id: -1,
      slateId: '',
      direction: TxDirection.received,
      state: TxState.confirmed,
      method: TxMethod.epicbox,
      amount: nanoPerEpic,
      fee: 0,
      created: DateTime(2026, 9, 14),
      fromBackup: true,
    );
    expect(whoOf(englishStrings, t), 'Received');
    expect(statusOf(englishStrings, t).$1, 'Imported');
    expect(whoTip(englishStrings, t), 'Imported from a wallet data file.');
    await _pump(tester, TxRow(tx: t, onTap: () {}));
    expect(find.text('Received'), findsOneWidget);
    expect(find.textContaining('Imported', findRichText: true), findsWidgets);
    await _pump(tester, TxDetail(tx: t));
    expect(find.text('imported from a wallet data file'), findsOneWidget);
    expect(find.text('Imported from a wallet data file. Status not checked on the chain.'), findsOneWidget);
    expect(find.text('Progress'), findsNothing);
    expect(find.widgetWithText(EButton, 'Cancel'), findsNothing);
  });
}
