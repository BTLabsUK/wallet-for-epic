// History files and the archive calls of one wallet. Ported from the tests in
// app/rust/src/core/export.rs and the history calls of core/session.rs. Sealing is LEPIC's and
// runs in integration_test/history_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/merge.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _invalid(String message) => throwsA(
  isA<WalletError>()
      .having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)
      .having((e) => e.message, 'message', message),
);

TxEntry _tx(String note, String counterparty) => fakeTx(
  key: 's:1',
  id: 1,
  slateId: '1',
  kind: TxKind.sent,
  status: TxStatus.confirmed,
  createdAtUnix: 1790000000,
  blockHeight: BigInt.from(12),
  amountCredited: BigInt.from(50000000),
  amountDebited: BigInt.from(200000000),
  fee: BigInt.from(800000),
  numInputs: 1,
  kernelExcess: '08ab',
  counterparty: counterparty,
  note: note,
);

void main() {
  group('csv', () {
    test('quotes and defuses formulas', () {
      final out = historyCsv([
        _tx('rent, "march"\nsecond line', '=HYPERLINK("x")'),
      ], BigInt.from(40));
      final firstBreak = out.indexOf('\n');
      expect(out.substring(0, firstBreak), csvHeader);
      expect(
        out.substring(firstBreak + 1),
        '2026-09-21T14:13:20Z,Sent,Completed,-1.49200000,0.00800000,'
        '"\'=HYPERLINK(""x"")","rent, ""march""\nsecond line",1,08ab,12\n',
      );
      expect(epicDecimal(BigInt.from(5)), '0.00000005');
    });

    test('status words follow the app status chip', () {
      String words(TxEntry t, int? tip) =>
          statusWords(t, tip == null ? null : BigInt.from(tip));
      final t = _tx('', '');
      expect(words(t, 15), 'Confirming 4/10');
      expect(words(t, 21), 'Completed');
      expect(words(t, null), 'Completed');
      TxEntry with_({
        TxStatus? status,
        TxKind kind = TxKind.sent,
        int? id = 1,
        int? height,
      }) => fakeTx(
        id: id,
        kind: kind,
        status: status ?? TxStatus.awaitingConfirmation,
        blockHeight: height == null ? null : BigInt.from(height),
      );
      expect(
        words(with_(status: TxStatus.awaitingRecipient, height: 12), 21),
        'Waiting for recipient',
      );
      expect(words(with_(), 21), 'Confirming 0/10');
      expect(words(with_(kind: TxKind.received), 21), 'Waiting for sender');
      expect(
        words(with_(kind: TxKind.received, id: null), 21),
        'From backup, status unknown',
      );
      expect(
        words(with_(status: TxStatus.cancelled, id: null), 21),
        'Cancelled',
      );
      expect(typeWord(TxKind.coinbase), 'Mining reward');
    });

    test('dates are UTC, and no time a file names can throw', () {
      expect(isoUtc(0), '1970-01-01T00:00:00Z');
      expect(isoUtc(951782400), '2000-02-29T00:00:00Z');
      expect(isoUtc(1790000000), '2026-09-21T14:13:20Z');
      isoUtc(-9223372036854775808);
      isoUtc(9223372036854775807);
    });
  });

  group('payload', () {
    HistoryPayload valid() => HistoryPayload(
      chain: 'Mainnet',
      walletFp: '00',
      exportedAtUnix: 1,
      appVersion: 't',
      txs: [Record(slateId: 's', kind: 'Sent', status: 'Confirmed')],
    );

    test('round trips in the old core field names', () {
      final bytes = valid().encode();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(json.keys, [
        'format',
        'version',
        'chain',
        'wallet_fp',
        'exported_at_unix',
        'app_version',
        'last_confirmed_height',
        'txs',
        'contacts',
      ]);
      final back = HistoryPayload.decode(bytes);
      expect(back.txs.single.slateId, 's');
      expect(back.format, historyFormat);
    });

    test(
      'hostile contents are errors with the old sentences, never a crash',
      () {
        final junk = <String>[
          '',
          'null',
          '[]',
          '{}',
          '{"format":1}',
          '[' * 100000,
          '{"txs":[${List.filled(10, '{"amount_credited":1e400}').join(',')}]}',
          '\u{fffd}\u0000',
        ];
        for (final j in junk) {
          expect(
            () => HistoryPayload.decode(utf8.encode(j)),
            throwsA(isA<WalletError>()),
            reason: j.length > 40 ? j.substring(0, 40) : j,
          );
        }
        expect(
          () => HistoryPayload.decode(
            utf8.encode('{"format":"wfe-history","version":99}'),
          ),
          throwsA(isA<WalletError>()),
        );
        expect(
          () => HistoryPayload.decode(
            utf8.encode(
              '{"format":"wfe-history","version":99,"chain":"Mainnet","wallet_fp":"",'
              '"exported_at_unix":1,"app_version":""}',
            ),
          ),
          _invalid(historyNewer),
        );
        expect(
          () => HistoryPayload.decode([0xff, 0xfe]),
          _invalid(historyDamaged),
        );

        // Valid JSON with absurd values parses, and the merge and CSV cope with it.
        final odd = valid()
          ..txs.add(
            Record(
              slateId: 'x' * 10000,
              kind: '?',
              status: '?',
              amountCredited: (BigInt.one << 64) - BigInt.one,
              amountDebited: (BigInt.one << 64) - BigInt.one,
              fee: (BigInt.one << 64) - BigInt.one,
              createdAtUnix: -9223372036854775808,
              blockHeight: (BigInt.one << 64) - BigInt.one,
              outputCommits: List.filled(1000, ''),
            ),
          );
        final p = HistoryPayload.decode(odd.encode());
        final rows = mergeHistory(const [], Meta(records: p.txs));
        final txs = [for (final m in rows) m.tx];
        historyCsv(txs, (BigInt.one << 64) - BigInt.one);
        historyCsv(txs, BigInt.zero);
      },
    );
  });

  group('wallet history', () {
    late Directory dir;
    late WalletHistory history;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('wfe-hist-');
      history = await WalletHistory.open(dir.path, Chain.mainnet);
    });
    tearDown(() async {
      history.close();
      await dir.delete(recursive: true);
    });

    final live = [
      fakeTx(key: 'l:1', id: 1, slateId: 'a', kind: TxKind.sent),
      fakeTx(key: 'l:2', id: 2, slateId: 'self', kind: TxKind.sent),
      fakeTx(key: 'l:3', id: 3, slateId: 'self', kind: TxKind.received),
    ];

    test('a note goes on its row only, and blank clears it', () async {
      await history.setNote(live, 's:a', '  rent ');
      await history.setNote(live, 's:self', 'send side');
      final rows = history.transactions(live);
      String? note(int id) => rows.firstWhere((t) => t.id == id).note;
      expect(note(1), 'rent');
      expect(note(2), 'send side');
      expect(note(3), isNull);
      // Notes saved under an older key move to the row's key.
      await history.setNote(live, 's:a', null);
      expect(history.meta.notes.containsKey('s:a'), isFalse);
      final reopened = await WalletHistory.open(dir.path, Chain.mainnet);
      expect(reopened.meta.notes, {'s:self': 'send side'});
      reopened.close();
    });

    test(
      'contacts: add, replace, delete, sorted, with the old checks',
      () async {
        final bob = await history.saveContact(
          const Contact(id: '', name: ' bob ', address: ' b@relay ', note: ' '),
        );
        expect(bob.id, hasLength(32));
        expect((bob.name, bob.address, bob.note), ('bob', 'b@relay', null));
        await history.saveContact(
          const Contact(id: '', name: 'Alice', address: 'a@relay'),
        );
        expect(history.contacts().map((c) => c.name), ['Alice', 'bob']);
        await history.saveContact(
          Contact(id: bob.id, name: 'Bob', address: 'b@relay', note: 'x'),
        );
        expect(history.contacts().last.note, 'x');
        expect(
          () => history.saveContact(
            const Contact(id: 'nope', name: 'n', address: 'a'),
          ),
          _invalid('no contact with id nope'),
        );
        expect(
          () => history.saveContact(
            const Contact(id: '', name: ' ', address: 'a'),
          ),
          _invalid('the contact needs a name'),
        );
        expect(
          () => history.saveContact(
            const Contact(id: '', name: 'n', address: ''),
          ),
          _invalid('the contact needs an address'),
        );
        await history.deleteContact(bob.id);
        expect(history.contacts().map((c) => c.name), ['Alice']);
      },
    );

    test('export then import twice, and files of others are refused', () async {
      await history.saveContact(
        const Contact(id: '', name: 'Bob', address: 'b@relay'),
      );
      await history.setNote(live, 's:a', 'rent');
      final payload = history.exportPayload(
        live,
        walletFp: 'fp',
        appVersion: 't',
        now: DateTime.fromMillisecondsSinceEpoch(1790000000000),
      );
      expect(payload.chain, 'Mainnet');
      expect(payload.txs, hasLength(3));
      expect(payload.txs.where((r) => r.note == 'rent'), hasLength(1));
      final file = payload.encode();

      final dirB = await Directory.systemTemp.createTemp('wfe-hist-b-');
      addTearDown(() => dirB.delete(recursive: true));
      final b = await WalletHistory.open(dirB.path, Chain.mainnet);
      addTearDown(b.close);
      final first = await b.importPayload(
        HistoryPayload.decode(file),
        const [],
        walletFp: 'fp',
      );
      expect(
        (first.merged, first.added, first.skipped, first.contactsAdded),
        // The two sides of the self-send share a slate id, so the old core's rule keeps one
        // record for both.
        (0, 2, 1, 1),
      );
      final again = await b.importPayload(
        HistoryPayload.decode(file),
        const [],
        walletFp: 'fp',
      );
      expect(
        (again.merged, again.added, again.skipped, again.contactsAdded),
        (0, 0, 3, 0),
      );
      final rows = b.transactions(const []);
      expect(rows.where((t) => t.note == 'rent'), hasLength(1));
      expect(rows.every((t) => t.source == TxSource.imported), isTrue);

      // The same records against a wallet that holds them live count as merged.
      final dirC = await Directory.systemTemp.createTemp('wfe-hist-c-');
      addTearDown(() => dirC.delete(recursive: true));
      final c = await WalletHistory.open(dirC.path, Chain.mainnet);
      addTearDown(c.close);
      final onLive = await c.importPayload(
        HistoryPayload.decode(file),
        live,
        walletFp: 'fp',
      );
      expect((onLive.merged, onLive.added), (2, 0));
      expect(c.transactions(live), hasLength(3), reason: 'no duplicates');

      expect(
        () => b.importPayload(
          HistoryPayload.decode(file),
          const [],
          walletFp: 'other',
        ),
        _invalid(historyOtherWallet),
      );
      final floonet = await WalletHistory.open(dirB.path, Chain.floonet);
      addTearDown(floonet.close);
      expect(
        () => floonet.importPayload(
          HistoryPayload.decode(file),
          const [],
          walletFp: 'fp',
        ),
        _invalid(historyOtherChain('Mainnet', 'Floonet')),
      );
    });

    test('a record with nothing to match by is skipped', () async {
      final payload = HistoryPayload(
        chain: 'Mainnet',
        walletFp: 'fp',
        exportedAtUnix: 1,
        appVersion: 't',
        txs: [Record(kind: 'Sent', status: 'Confirmed')],
      );
      final report = await history.importPayload(
        payload,
        const [],
        walletFp: 'fp',
      );
      expect((report.added, report.skipped), (0, 1));
    });

    test('an export leaves out rows a scan rebuilt that have no note', () {
      final scan = [
        fakeTx(key: 'l:7', id: 7, source: TxSource.restored),
        fakeTx(key: 'l:8', id: 8, slateId: 'b'),
      ];
      final payload = history.exportPayload(
        scan,
        walletFp: 'fp',
        appVersion: 't',
      );
      expect(payload.txs.map((r) => r.slateId), ['b']);
    });

    test('the wallet fingerprint is the old core one', () {
      // SHA-256 of the key text, first 16 bytes, as Session::wallet_fp hashes it.
      expect(
        walletFingerprint('esKey@epicbox.epiccash.com'),
        walletFingerprint('esKey@other.relay:443'),
      );
      expect(walletFingerprint('esKey@x'), '2d7c1195d0d03c73ff5691d0d2d01add');
    });
  });
}
