// F34 data: LepicDeskWallet's history backup over the shared core session (FakeWalletSession):
// the backup record and the F33 reminder rule, export and import with the refusals in the
// design's words, the CSV range, and WALLET.txt in the wallet folder.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/backup_reminder.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/history/export.dart' show csvHeader, historyDamaged, historyNewer, historyOtherChain, historyOtherWallet;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart' show HistoryExportSnapshot;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

void main() {
  group('the F33 rule (a copy of the phone\'s)', () {
    final now = DateTime(2026, 10, 22, 12);
    List<core.TxEntry> payments(int n, {DateTime? at}) => [
      for (var i = 0; i < n; i++) core.fakeTx(key: 'l:$i', id: i, timeUnix: _at(at ?? now.subtract(Duration(days: 40 + i))), confirmed: true),
    ];
    final long = _at(now.subtract(const Duration(days: 31)));

    test('the constants', () {
      expect(deskReminderMinPayments, 10);
      expect(deskReminderPause, const Duration(days: 30));
      expect(deskReminderQuiet, const Duration(minutes: 10));
    });

    test('restored and imported rows do not count; an export resets the count', () {
      final txs = [
        ...payments(3),
        core.fakeTx(key: 'r', source: core.TxSource.restored),
        core.fakeTx(key: 'i', source: core.TxSource.imported),
      ];
      expect(deskUnbackedPayments(txs), 3);
      expect(deskUnbackedPayments(txs, exportedAt: _at(now)), 0);
    });

    test('10 payments and 30 days; 9 are not enough; a fresh payment keeps it quiet', () {
      expect(deskPaymentsNotInBackup(payments(9), now: now, firstSeenAt: long), isNull);
      expect(deskPaymentsNotInBackup(payments(10), now: now, firstSeenAt: long), 10);
      expect(deskPaymentsNotInBackup(payments(10), now: now, firstSeenAt: _at(now.subtract(const Duration(days: 29)))), isNull);
      expect(deskPaymentsNotInBackup(payments(10), now: now), isNull, reason: 'no start known yet');
      expect(deskPaymentsNotInBackup(payments(10), now: now, firstSeenAt: long, dismissedAt: _at(now.subtract(const Duration(days: 2)))), isNull);
      final fresh = [...payments(10), core.fakeTx(key: 'new', timeUnix: _at(now.subtract(const Duration(minutes: 5))))];
      expect(deskPaymentsNotInBackup(fresh, now: now, firstSeenAt: long), isNull);
    });

    test('a payment pending at the export that settled since counts again', () {
      final pending = core.fakeTx(key: 'p', timeUnix: _at(now.subtract(const Duration(days: 50))), status: core.TxStatus.awaitingConfirmation);
      final snapshot = HistoryExportSnapshot.of([pending]);
      final settled = core.fakeTx(key: 'p', timeUnix: pending.timeUnix, status: core.TxStatus.confirmed);
      expect(deskUnbackedPayments([settled], exportedAt: _at(now.subtract(const Duration(days: 45))), snapshot: snapshot), 1);
    });
  });

  group('LepicDeskWallet', () {
    late Directory support;
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-backup-test-');
      service = core.FakeWalletService(password: _password);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory('${support.path}/wallets/${chain.name}');
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
      );
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    Future<void> open() async {
      await wallet.createWallet(name: 'Savings', password: _password);
      expect(await wallet.unlock(_password), isTrue);
    }

    test('WALLET.txt: the label and network, no secrets; a rename rewrites it', () async {
      final phrase = await wallet.createWallet(name: 'Savings', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      final folder = (await wallet.account()).folder;
      final file = File('$folder/WALLET.txt');
      expect(file.existsSync(), isTrue);
      var text = file.readAsStringSync();
      expect(text, startsWith('Epic Cash Desktop (BT Labs) wallet folder\nLabel:     Savings\nNetwork:   mainnet\n'));
      expect(text, contains('This folder is not a backup. Restore with the recovery phrase.'));
      expect(text, isNot(contains(_password)));
      for (final w in phrase) {
        expect(RegExp('\\b$w\\b').hasMatch(text), isFalse, reason: 'phrase word $w');
      }
      expect(text, isNot(contains(service.session.address)));
      await wallet.renameWallet((await wallet.wallets()).single.id, 'Daily');
      text = file.readAsStringSync();
      expect(text, contains('Label:     Daily'));
    });

    test('the record: never exported, then exported with nothing new', () async {
      await open();
      service.session.transactionsValue = [for (var i = 0; i < 3; i++) core.fakeTx(key: 'l:$i', id: i, confirmed: true)];
      var s = await wallet.historyBackupState();
      expect(s.lastExport, isNull);
      expect(s.unbacked, 3);
      expect(s.reminder, isNull, reason: 'fewer than 10');
      expect(s.payments, 3);
      expect(s.network, 'mainnet');
      final at = DateTime.now();
      await wallet.markHistoryExported(at);
      s = await wallet.historyBackupState();
      expect(s.lastExport!.difference(at).inSeconds.abs(), lessThan(2));
      expect(s.unbacked, 0);
    });

    test('export and import of the same file through the core session', () async {
      await open();
      final bytes = await wallet.exportHistory();
      expect(bytes, isNotEmpty);
      final r = await wallet.importHistory(bytes);
      expect(r.nothingNew, isTrue);
    });

    test('refusals in the design\'s words', () async {
      await open();
      Future<HistoryFileError> refused(String message) async {
        service.session.importError = core.WalletError(kind: core.WalletErrorKind.invalidArgument, message: message);
        try {
          await wallet.importHistory(Uint8List.fromList(utf8.encode('x')));
        } on HistoryFileError catch (e) {
          return e;
        }
        fail('not refused');
      }

      expect((await refused(historyOtherWallet)).problem, HistoryFileProblem.otherWallet);
      expect((await refused(historyNewer)).text, 'A newer version of the app made this file. Update the app, then import it.');
      expect((await refused(historyDamaged)).problem.title, 'File damaged');
      final chain = await refused(historyOtherChain('Floonet', 'Mainnet'));
      expect((chain.problem.title, chain.text), ('Wrong network', 'The file is from Floonet; this wallet is on Mainnet.'));
      expect((await refused('This is not a history file exported by this app')).problem, HistoryFileProblem.notOurs);
      service.session.importError = null;
      await expectLater(
        wallet.importHistory(Uint8List(maxDeskHistoryBytes + 1)),
        throwsA(isA<HistoryFileError>().having((e) => e.problem, 'problem', HistoryFileProblem.tooLarge)),
      );
    });

    test('CSV: the shared header; the range keeps local days inclusive', () async {
      await open();
      DateTime day(int d, [int h = 12]) => DateTime(2026, 3, d, h);
      service.session.transactionsValue = [
        core.fakeTx(key: 'a', id: 1, timeUnix: _at(day(1, 0)), confirmed: true),
        core.fakeTx(key: 'b', id: 2, timeUnix: _at(day(2, 23)), confirmed: true),
        core.fakeTx(key: 'c', id: 3, timeUnix: _at(day(3)), confirmed: true),
      ];
      final all = await wallet.exportHistoryCsv();
      expect(all.split('\n').first, csvHeader.trim());
      expect(all.trim().split('\n'), hasLength(4));
      final some = await wallet.exportHistoryCsv(from: day(1), to: day(2));
      expect(some.trim().split('\n'), hasLength(3));
    });
  });
}
