// Labels on any transaction and details on restored ones: the archive, the merge, exports and
// imports. Spec: docs/feedback/designs/restored-edit (labels, Added by you, Details differ).
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = DateTime.fromMillisecondsSinceEpoch(1790000500000);

/// A wallet-made send with change, as LEPIC gives it once it names output commitments.
TxEntry _send({
  int id = 1,
  String slate = 'a',
  List<String> commits = const ['chg1'],
}) => fakeTx(
  key: 's:$slate',
  id: id,
  slateId: slate,
  kind: TxKind.sent,
  status: TxStatus.confirmed,
  blockHeight: BigInt.from(20),
  amountCredited: BigInt.from(30000000),
  amountDebited: BigInt.from(100000000),
  fee: BigInt.from(700000),
  kernelExcess: 'k$slate',
  outputCommits: commits,
  counterparty: 'esBob@epicbox.epiccash.com',
  transport: 'epicbox',
);

/// An output a scan found: no slate, no kernel, LEPIC's id changes on every restore, the
/// commitment never does.
TxEntry _found({int id = 7, String commit = 'out7', int block = 100}) => fakeTx(
  key: 'c:$commit',
  id: id,
  source: TxSource.restored,
  status: TxStatus.confirmed,
  blockHeight: BigInt.from(block),
  amountCredited: BigInt.from(50000000),
  outputCommits: [commit],
);

void main() {
  late Directory dir;
  late WalletHistory history;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wfe-labels-');
    history = await WalletHistory.open(dir.path, Chain.mainnet);
  });
  tearDown(() async {
    history.close();
    await dir.delete(recursive: true);
  });

  Future<WalletHistory> another() async {
    final d = await Directory.systemTemp.createTemp('wfe-labels-b-');
    addTearDown(() => d.delete(recursive: true));
    final h = await WalletHistory.open(d.path, Chain.mainnet);
    addTearDown(h.close);
    return h;
  }

  TxEntry row(WalletHistory h, List<TxEntry> live, String key) =>
      h.transactions(live).firstWhere((t) => t.key == key);

  HistoryPayload exported(WalletHistory h, List<TxEntry> live) =>
      HistoryPayload.decode(
        h
            .exportPayload(live, walletFp: 'fp', appVersion: 't', now: _at)
            .encode(),
      );

  group('labels', () {
    test('any row takes a label; blank removes it and the record', () async {
      final live = [_send(), _found()];
      await history.setLabel(live, 's:a', '  Rent,   October ', now: _at);
      await history.setLabel(live, 'c:out7', 'Pool payout', now: _at);
      final send = row(history, live, 's:a');
      expect(send.label, 'Rent, October');
      expect(send.manualFields, {ManualField.label});
      expect(send.manualEditedAtUnix, 1790000500);
      expect(row(history, live, 'c:out7').label, 'Pool payout');
      // Amounts, kernel, height and the recorded sender never move.
      expect(send.amountDebited, BigInt.from(100000000));
      expect(send.kernelExcess, 'ka');
      expect(send.blockHeight, BigInt.from(20));
      expect(send.counterparty, 'esBob@epicbox.epiccash.com');

      await history.setLabel(live, 's:a', '   ');
      expect(row(history, live, 's:a').label, isNull);
      expect(row(history, live, 's:a').manualFields, isEmpty);
      expect(history.meta.manual.keys, ['c:out7']);
      final reopened = await WalletHistory.open(dir.path, Chain.mainnet);
      addTearDown(reopened.close);
      expect(reopened.meta.manual['c:out7']!.label, 'Pool payout');
    });

    test('a label keeps 60 characters', () async {
      final live = [_send()];
      await history.setLabel(live, 's:a', 'x' * 80);
      expect(row(history, live, 's:a').label, 'x' * txLabelMaxLength);
    });

    test('an archive without labels is written as before', () async {
      final live = [_send()];
      await history.setNote(live, 's:a', 'n');
      final text = await File('${dir.path}/$metaFileName').readAsString();
      expect(jsonDecode(text), isNot(contains('manual')));
    });
  });

  group('details of a restored row', () {
    test('sender, method and note fill only the restored row', () async {
      final live = [_send(), _found()];
      await history.setDetails(
        live,
        'c:out7',
        counterparty: ' esAnna@epicbox.epiccash.com ',
        transport: 'epicbox',
        note: 'weekly payout',
        now: _at,
      );
      final found = row(history, live, 'c:out7');
      expect(found.counterparty, 'esAnna@epicbox.epiccash.com');
      expect(found.transport, 'epicbox');
      expect(found.note, 'weekly payout');
      expect(found.manualFields, {
        ManualField.counterparty,
        ManualField.transport,
        ManualField.note,
      });
      expect(found.source, TxSource.restored);
      expect(found.amountCredited, BigInt.from(50000000));

      expect(
        () => history.setDetails(live, 's:a', counterparty: 'x'),
        throwsA(isA<WalletError>()),
      );
      expect(
        () => history.setDetails(live, 'c:out7', transport: 'pigeon'),
        throwsA(isA<WalletError>()),
      );

      await history.setDetails(live, 'c:out7');
      final cleared = row(history, live, 'c:out7');
      expect(
        (cleared.counterparty, cleared.transport, cleared.note),
        (null, null, null),
      );
      expect(history.meta.manual, isEmpty);
    });

    test('a recorded sender shows over a typed one', () async {
      final live = [_found()];
      await history.setDetails(live, 'c:out7', counterparty: 'esTyped@x');
      // A backup record of the same output names the real sender.
      await history.importPayload(
        HistoryPayload(
          chain: 'Mainnet',
          walletFp: 'fp',
          exportedAtUnix: 5,
          appVersion: 't',
          txs: [
            Record(
              slateId: 'z',
              kind: 'Received',
              status: 'Confirmed',
              confirmed: true,
              amountCredited: BigInt.from(50000000),
              outputCommits: ['out7'],
              counterparty: 'esRecorded@x',
            ),
          ],
        ),
        live,
        walletFp: 'fp',
      );
      final t = history.transactions(live).single;
      expect(t.counterparty, 'esRecorded@x');
      expect(t.manualFields, isNot(contains(ManualField.counterparty)));
    });
  });

  group('identity across a restore', () {
    test('a restored row keeps its label and details by commitment', () async {
      await history.setLabel([_found(id: 7)], 'c:out7', 'Pool payout');
      await history.setDetails(
        [_found(id: 7)],
        'c:out7',
        transport: 'tor',
        note: 'from the pool',
      );
      // After a restore LEPIC gives the same output another id.
      final after = [_found(id: 42)];
      final t = history.transactions(after).single;
      expect(t.id, 42);
      expect(
        (t.label, t.transport, t.note),
        ('Pool payout', 'tor', 'from the pool'),
      );
    });

    test(
      'a label typed under the old local id moves to the commitment',
      () async {
        // Before LEPIC named commitments the row's key was `l:<id>`.
        final old = [
          fakeTx(
            key: 'l:7',
            id: 7,
            source: TxSource.restored,
            blockHeight: BigInt.from(100),
          ),
        ];
        await history.setLabel(old, 'l:7', 'Old label');
        final now = [_found(id: 7)];
        expect(row(history, now, 'c:out7').label, 'Old label');
        await history.setLabel(now, 'c:out7', 'New label');
        expect(history.meta.manual.keys, ['c:out7']);
      },
    );

    test('a wallet-made send comes back with its label after a restore and an import', () async {
      final live = [
        _send(commits: ['chg1']),
      ];
      await history.setLabel(live, 's:a', 'Rent');
      final file = exported(history, live);
      expect(file.txs.single.outputCommits, ['chg1']);

      // The restored wallet only knows the change output.
      final b = await another();
      final restored = [_found(id: 3, commit: 'chg1', block: 20)];
      final report = await b.importPayload(file, restored, walletFp: 'fp');
      expect(report.applied, isTrue);
      final t = b.transactions(restored).single;
      expect(t.key, 's:a');
      expect(t.label, 'Rent');
      expect(t.kind, TxKind.sent);
    });

    test(
      'a restored row comes back with its details and stays restored',
      () async {
        final live = [_found(id: 7)];
        await history.setLabel(live, 'c:out7', 'Pool payout', now: _at);
        await history.setDetails(
          live,
          'c:out7',
          counterparty: 'esAnna@x',
          transport: 'http',
          note: 'weekly',
          now: _at,
        );
        final file = exported(history, live);
        final rec = file.txs.single;
        expect(rec.outputCommits, ['out7']);
        expect(rec.userFields, ['label', 'counterparty', 'method', 'note']);
        expect(rec.userEditedAtUnix, 1790000500);

        final b = await another();
        final restored = [_found(id: 99)];
        final report = await b.importPayload(file, restored, walletFp: 'fp');
        expect((report.merged, report.added, report.applied), (1, 0, true));
        expect(
          b.meta.records,
          isEmpty,
          reason: 'only what the user added travels',
        );
        final t = b.transactions(restored).single;
        expect(t.source, TxSource.restored);
        expect(
          (t.label, t.counterparty, t.transport, t.note),
          ('Pool payout', 'esAnna@x', 'http', 'weekly'),
        );
        expect(t.manualEditedAtUnix, 1790000500);
      },
    );
  });

  group('import conflicts', () {
    test(
      'the file fills empty fields; a different value asks, then never again',
      () async {
        final live = [
          _send(),
          _send(id: 2, slate: 'b', commits: const ['chg2']),
        ];
        await history.setLabel(live, 's:a', 'Theirs');
        await history.setLabel(live, 's:b', 'Only in file');
        await history.setNote(live, 's:a', 'their note');
        final file = exported(history, live);

        final b = await another();
        await b.setLabel(live, 's:a', 'Mine');
        await b.setNote(live, 's:a', 'my note');
        final before = jsonEncode(b.meta.toJson());

        final first = await b.importPayload(file, live, walletFp: 'fp');
        expect(first.applied, isFalse);
        expect(jsonEncode(b.meta.toJson()), before, reason: 'nothing written');
        expect(
          {for (final c in first.conflicts) c.id: (c.mine, c.theirs)},
          {
            's:a|label': ('Mine', 'Theirs'),
            's:a|note': ('my note', 'their note'),
          },
        );
        final c = first.conflicts.first;
        expect(c.timeUnix, row(b, live, 's:a').timeUnix);
        expect(c.amount, BigInt.from(-69300000));

        // Use the backup's label, keep my note.
        final applied = await b.importPayload(
          file,
          live,
          walletFp: 'fp',
          useBackup: {'s:a|label': true, 's:a|note': false},
        );
        expect((applied.applied, applied.replaced), (true, 1));
        expect(row(b, live, 's:a').label, 'Theirs');
        expect(row(b, live, 's:a').note, 'my note');
        expect(row(b, live, 's:b').label, 'Only in file');

        // The same file again: nothing asks, nothing changes.
        final settled = jsonEncode(b.meta.toJson());
        final again = await b.importPayload(file, live, walletFp: 'fp');
        expect(again.applied, isTrue);
        expect(again.conflicts, isEmpty);
        expect(jsonEncode(b.meta.toJson()), settled);
      },
    );

    test('keep all mine', () async {
      final live = [_found()];
      await history.setDetails(
        live,
        'c:out7',
        counterparty: 'esFile@x',
        transport: 'file',
      );
      final file = exported(history, live);
      final b = await another();
      await b.setDetails(
        live,
        'c:out7',
        counterparty: 'esMine@x',
        transport: 'file',
      );
      final asked = await b.importPayload(file, live, walletFp: 'fp');
      expect(asked.conflicts.map((c) => c.id), ['c:out7|counterparty']);
      await b.importPayload(file, live, walletFp: 'fp', useBackup: const {});
      expect(row(b, live, 'c:out7').counterparty, 'esMine@x');
      final again = await b.importPayload(file, live, walletFp: 'fp');
      expect(again.conflicts, isEmpty);
    });

    test('an old file without labels changes no label', () async {
      final live = [_send()];
      await history.setLabel(live, 's:a', 'Mine');
      final file = HistoryPayload.decode(
        utf8.encode(
          jsonEncode(
            jsonDecode(utf8.decode(exported(history, live).encode()))
              ..['txs'][0].remove('label')
              ..['txs'][0].remove('user_fields'),
          ),
        ),
      );
      final report = await history.importPayload(file, live, walletFp: 'fp');
      expect(report.applied, isTrue);
      expect(report.conflicts, isEmpty);
      expect(row(history, live, 's:a').label, 'Mine');
    });
  });

  group('exports', () {
    test('the CSV appends label, method and user_fields', () async {
      final live = [_send(), _found()];
      await history.setLabel(live, 's:a', '=Rent');
      await history.setDetails(live, 'c:out7', transport: 'tor', note: 'n');
      final lines = history.csv(live, BigInt.from(200)).trim().split('\n');
      expect(
        lines.first,
        'date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,'
        'block_height,label,method,user_fields',
      );
      final byKey = {for (final l in lines.skip(1)) l.split(',')[7]: l};
      expect(byKey['a'], endsWith(",'=Rent,Epicbox,label"));
      expect(byKey[''], endsWith(',,Direct · Tor,method;note'));
    });

    test('a .wfeh carries labels of every row and the archive keeps none in records', () async {
      final live = [_send()];
      await history.setLabel(live, 's:a', 'Rent', now: _at);
      final file = exported(history, live);
      final r = file.txs.single;
      expect((r.label, r.transport), ('Rent', 'epicbox'));
      expect(r.userFields, ['label']);
      expect(Record.fromJson(r.toJson()).toJson(), r.toJson());

      final b = await another();
      await b.importPayload(file, const [], walletFp: 'fp');
      final kept = b.meta.records.single.toJson();
      expect(kept, isNot(contains('label')));
      expect(kept, isNot(contains('user_fields')));
      // The imported row shows the label from the archive's manual map.
      expect(b.transactions(const []).single.label, 'Rent');
      expect(b.meta.manual['s:a']!.editedAtUnix, 1790000500);
    });

    test('a row a scan rebuilt with only a label is exported', () async {
      final live = [_found()];
      await history.setLabel(live, 'c:out7', 'Payout');
      expect(exported(history, live).txs.single.label, 'Payout');
    });
  });

  group('the old wallet\'s history against typed details', () {
    /// The old wallet's record of the payment [_found] was: same commitment, now an imported
    /// row with its own sender and method.
    TxEntry imported({String? from = 'esOld@epicbox.epiccash.com', String? via = 'http'}) =>
        fakeTx(
          key: 's:old',
          id: 9,
          slateId: 'old',
          source: TxSource.imported,
          kind: TxKind.received,
          status: TxStatus.confirmed,
          blockHeight: BigInt.from(100),
          amountCredited: BigInt.from(50000000),
          outputCommits: const ['out7'],
          counterparty: from,
          transport: via,
        );

    Future<void> typed() => history.setDetails(
      [_found()],
      'c:out7',
      counterparty: 'esMine@epicbox.epiccash.com',
      transport: 'epicbox',
      now: _at,
    );

    test('differing sender and method are conflicts; the old wallet\'s shows until chosen', () async {
      await typed();
      final live = [imported()];
      final c = history.legacyConflicts(live);
      expect(
        [for (final x in c) (x.field, x.mine, x.theirs)],
        [
          (ManualField.counterparty, 'esMine@epicbox.epiccash.com', 'esOld@epicbox.epiccash.com'),
          (ManualField.transport, 'epicbox', 'http'),
        ],
      );
      final shown = row(history, live, 's:old');
      expect(shown.counterparty, 'esOld@epicbox.epiccash.com');
      expect(shown.manualFields, isEmpty);
    });

    test('nothing differs: no conflicts', () async {
      await typed();
      // Equal values, or a value the old wallet does not record.
      expect(
        history.legacyConflicts([imported(from: 'esMine@epicbox.epiccash.com', via: 'epicbox')]),
        isEmpty,
      );
      expect(history.legacyConflicts([imported(from: null, via: null)]), isEmpty);
      // No typed details at all.
      final other = await another();
      expect(other.legacyConflicts([imported()]), isEmpty);
      // The row is still a scan find: nothing was recorded for it.
      expect(history.legacyConflicts([_found()]), isEmpty);
    });

    test('Mine (the default) keeps the typed values and never asks again', () async {
      await typed();
      final live = [imported()];
      final replaced = await history.resolveLegacyConflicts(live, const {});
      expect(replaced, 0);
      final shown = row(history, live, 's:old');
      expect(shown.counterparty, 'esMine@epicbox.epiccash.com');
      expect(shown.transport, 'epicbox');
      expect(shown.manualFields, {ManualField.counterparty, ManualField.transport});
      expect(history.legacyConflicts(live), isEmpty);
      // Another value from the old wallet is a new question.
      expect(history.legacyConflicts([imported(from: 'esOther@epicbox.epiccash.com')]), hasLength(1));
    });

    test('Theirs for one field takes the old wallet\'s and drops the typed one; the other stays', () async {
      await typed();
      final live = [imported()];
      final id = history.legacyConflicts(live).first.id;
      expect(id, 's:old|counterparty');
      final replaced = await history.resolveLegacyConflicts(live, {id: true});
      expect(replaced, 1);
      final shown = row(history, live, 's:old');
      expect(shown.counterparty, 'esOld@epicbox.epiccash.com');
      expect(shown.transport, 'epicbox');
      expect(shown.manualFields, {ManualField.transport});
      expect(history.meta.manual['s:old']!.counterparty, isNull);
      expect(history.legacyConflicts(live), isEmpty);
    });

    test('the choice survives a reopened archive', () async {
      await typed();
      final live = [imported()];
      await history.resolveLegacyConflicts(live, const {});
      final reopened = await WalletHistory.open(dir.path, Chain.mainnet);
      addTearDown(reopened.close);
      expect(reopened.legacyConflicts(live), isEmpty);
      expect(row(reopened, live, 's:old').counterparty, 'esMine@epicbox.epiccash.com');
    });
  });
}
