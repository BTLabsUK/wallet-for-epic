// SPDX-License-Identifier: Apache-2.0
// The merge of LEPIC's rows with the archive. Ported from the tests in
// app/rust/src/core/history.rs; live rows are TxEntry values as lepicTxEntry makes them.
import 'package:epic_wallet/src/history/merge.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A LEPIC row: key `l:<id>`, as `lepicTxEntry` gives it.
TxEntry live(
  int id, {
  TxKind kind = TxKind.received,
  TxStatus status = TxStatus.confirmed,
  TxSource source = TxSource.wallet,
  String? slateId,
  String? kernel,
  List<String> commits = const [],
  int createdAtUnix = 1790000000,
  int? blockHeight,
  int amountCredited = 0,
  int amountDebited = 0,
  CancelReason? cancelReason,
}) => fakeTx(
  key: 'l:$id',
  id: id,
  slateId: slateId,
  kind: kind,
  status: status,
  source: source,
  createdAtUnix: createdAtUnix,
  blockHeight: blockHeight == null ? null : BigInt.from(blockHeight),
  kernelExcess: kernel,
  outputCommits: commits,
  amountCredited: BigInt.from(amountCredited),
  amountDebited: BigInt.from(amountDebited),
  cancelReason: cancelReason,
);

TxEntry restored(int id, List<String> commits, {int? blockHeight}) => live(
  id,
  source: TxSource.restored,
  commits: commits,
  blockHeight: blockHeight,
  amountCredited: 30,
);

Record record({
  String? slate,
  String? kernel,
  List<String> commits = const [],
}) => Record(
  slateId: slate,
  kernelExcess: kernel,
  kind: 'Sent',
  status: 'Confirmed',
  confirmed: true,
  createdAtUnix: 1600000000,
  amountCredited: BigInt.from(30),
  amountDebited: BigInt.from(100),
  fee: BigInt.from(7),
  numInputs: 1,
  numOutputs: 1,
  outputCommits: [...commits],
  counterparty: 'bob@relay',
  note: 'rent',
);

MergedTx byId(List<MergedTx> rows, int? id) =>
    rows.firstWhere((m) => m.id == id);

void main() {
  test('a send over plain HTTP is marked by its slate id, other rows are not', () {
    final meta = Meta(unsafeSends: ['s1']);
    final rows = mergeHistory([
      live(1, kind: TxKind.sent, slateId: 's1', amountDebited: 10),
      live(2, kind: TxKind.sent, slateId: 's2', amountDebited: 10),
      live(3),
    ], meta);
    expect(byId(rows, 1).tx.unsafeSend, isTrue);
    expect(byId(rows, 2).tx.unsafeSend, isFalse);
    expect(byId(rows, 3).tx.unsafeSend, isFalse);
  });

  test('a restored row is shown at its block time', () {
    final meta = Meta(blockTimes: {'42': 1700000000});
    final m = mergeHistory([
      restored(0, const [], blockHeight: 42),
    ], meta).single;
    expect(m.source, TxSource.restored);
    expect(m.key, 'l:0', reason: 'LEPIC rows a scan rebuilt have nothing else');
    expect(m.blockTimeUnix, 1700000000);
    expect(m.timeUnix, 1700000000);
  });

  test('a block time the node lacked is cached but not shown', () {
    final meta = Meta(blockTimes: {'5': 0});
    final m = mergeHistory([
      restored(1, ['c'], blockHeight: 5),
    ], meta).single;
    expect(m.blockTimeUnix, isNull);
  });

  test('keys follow slate, kernel, commitment, then id', () {
    final rows = mergeHistory([
      live(1, slateId: 's1', kernel: 'k1'),
      live(2, kernel: 'k2', commits: ['c2']),
      live(3, commits: ['c3']),
      live(4),
    ], Meta());
    expect(rows.map((m) => m.key).toSet(), {'s:s1', 'k:k2', 'c:c3', 'l:4'});
  });

  test('cancel reasons come from what the old core recorded, else LEPIC', () {
    final meta = Meta(
      annotations: {
        's1': Annotation(cancelledBy: 'late_answer'),
        's3': Annotation(cancelledBy: 'user', counterparty: 'ann@relay'),
      },
    );
    final rows = mergeHistory([
      live(
        1,
        slateId: 's1',
        kind: TxKind.sentCancelled,
        status: TxStatus.cancelled,
        cancelReason: CancelReason.expiry,
      ),
      live(
        2,
        slateId: 's2',
        kind: TxKind.sentCancelled,
        status: TxStatus.cancelled,
        cancelReason: CancelReason.expiry,
      ),
      live(3, slateId: 's3', kind: TxKind.sent, status: TxStatus.confirmed),
    ], meta);
    expect(byId(rows, 1).cancelReason, CancelReason.lateAnswer);
    expect(byId(rows, 2).cancelReason, CancelReason.expiry);
    expect(byId(rows, 3).cancelReason, isNull, reason: 'not cancelled');
    expect(byId(rows, 3).counterparty, 'ann@relay');

    // An export keeps the reason, and an import shows it again.
    final back = mergeHistory(
      const [],
      Meta(records: [toRecord(byId(rows, 1))]),
    );
    expect(back.single.cancelReason, CancelReason.lateAnswer);
    for (final c in CancelReason.values) {
      expect(cancelReasonFrom(cancelReasonName(c)), c);
    }
    for (final k in TxKind.values) {
      expect(kindFrom(kindName(k)), k);
    }
    for (final s in TxStatus.values) {
      expect(statusFrom(statusName(s), confirmed: false), s);
    }
  });

  test('records merge by slate, kernel, then commitment', () {
    final rows = [
      live(1, slateId: 'slate-9', kind: TxKind.sent, blockHeight: 5),
      restored(2, ['chg'], blockHeight: 9),
    ];
    final meta = Meta(
      records: [
        record(slate: 'slate-9'),
        record(slate: 'other-slate', kernel: 'kern', commits: ['chg']),
        record(kernel: 'lonely', commits: ['gone']),
      ],
    );
    final merged = mergeHistory(rows, meta);
    expect(
      merged,
      hasLength(3),
      reason: 'two live rows plus one imported record',
    );

    final a = byId(merged, 1);
    expect(a.source, TxSource.wallet);
    expect(a.counterparty, 'bob@relay');
    expect(a.note, 'rent');

    final b = byId(merged, 2);
    expect(
      b.source,
      TxSource.imported,
      reason: 'the restored row took the record',
    );
    expect(b.kind, TxKind.sent);
    expect(b.amountDebited, BigInt.from(100));
    expect(b.fee, BigInt.from(7));
    expect(b.key, 's:other-slate');
    expect(b.timeUnix, 1600000000);
    expect(b.blockHeight, BigInt.from(9), reason: 'the live height wins');
    expect(b.aliases, contains('c:chg'));

    final c = byId(merged, null);
    expect(c.source, TxSource.imported);
    expect(c.key, 'k:lonely');
    expect(c.cancellable, isFalse);
  });

  test('slate messages stay on the live row and out of the export', () {
    const said = [SlateMessage(role: SlateRole.sender, text: 'for lunch')];
    final row = fakeTx(
      key: 'l:1',
      id: 1,
      slateId: 'slate-9',
      kind: TxKind.sent,
      messages: said,
    );
    final old = {'messages': <Object?>[]};
    final merged = mergeHistory([
      row,
    ], Meta(records: [record(slate: 'slate-9')..messages = old]));
    final m = byId(merged, 1);
    expect(m.tx.messages, said);
    expect(m.tx.note, 'rent');
    expect(
      toRecord(m).messages,
      same(old),
      reason: 'a backup keeps what the old core wrote, never LEPIC\'s',
    );
  });

  test('a record absorbs every restored output of its transaction', () {
    final rows = [
      restored(0, ['o1'], blockHeight: 3),
      restored(1, ['o2'], blockHeight: 3),
    ];
    final r = record(kernel: 'k', commits: ['o1', 'o2'])..kind = 'Received';
    final merged = mergeHistory(rows, Meta(records: [r]));
    expect(merged, hasLength(1));
    expect(merged.single.outputCommits, hasLength(2));
  });

  test('keys of duplicate imported records stay put when rows are added', () {
    final a = record(slate: 'dup')..createdAtUnix = 1;
    final b = record(slate: 'dup')
      ..createdAtUnix = 2
      ..kind = 'Received';
    String keyOfB(List<MergedTx> rows) =>
        rows.firstWhere((m) => m.createdAtUnix == 2).key;
    final first = keyOfB(mergeHistory(const [], Meta(records: [a, b])));
    expect(first, startsWith('s:dup#'));
    final other = record(kernel: 'zzz')..createdAtUnix = 3;
    expect(keyOfB(mergeHistory(const [], Meta(records: [other, a, b]))), first);
  });

  test('a restored self-send keeps both sides', () {
    final rows = [
      restored(0, ['chg'], blockHeight: 3),
      restored(1, ['recv'], blockHeight: 3),
    ];
    final meta = Meta(
      records: [
        record(slate: 'self', commits: ['chg']),
        record(slate: 'self', commits: ['recv'])..kind = 'Received',
      ],
    );
    final kinds = mergeHistory(rows, meta).map((m) => m.kind).toList();
    expect(kinds, unorderedEquals([TxKind.sent, TxKind.received]));
  });

  test('the two sides of a self-send do not share notes', () {
    final rows = [
      live(1, slateId: 'self', kind: TxKind.sent),
      live(2, slateId: 'self', kind: TxKind.received),
    ];
    final keys = mergeHistory(rows, Meta()).map((m) => m.key).toSet();
    expect(keys, {'s:self', 's:self#l2'}, reason: 'keys stay unique');
    final sendKey = byId(mergeHistory(rows, Meta()), 1).key;
    final merged = mergeHistory(rows, Meta(notes: {sendKey: 'for the send'}));
    expect(byId(merged, 1).note, 'for the send');
    expect(byId(merged, 2).note, isNull);
    expect(sharedAliases(merged), contains('s:self'));
  });

  test('a note follows any alias, and wins over the record note', () {
    final meta = Meta(
      notes: {'c:c1': 'from before the import'},
      records: [
        record(slate: 'sl', commits: ['c1']),
      ],
    );
    final m = mergeHistory([
      restored(0, ['c1']),
    ], meta).single;
    expect(m.key, 's:sl');
    expect(m.note, 'from before the import');
  });

  test(
    'a note saved under a LEPIC id still shows once the row has a slate key',
    () {
      final meta = Meta(notes: {'l:4': 'old key'});
      final m = mergeHistory([live(4, slateId: 's4')], meta).single;
      expect(m.key, 's:s4');
      expect(m.note, 'old key');
    },
  );

  test('newest first, a row without an id last among equals', () {
    final rows = mergeHistory([
      live(1, createdAtUnix: 10),
      live(2, createdAtUnix: 30),
      live(3, createdAtUnix: 10),
    ], Meta(records: [record(kernel: 'k')..createdAtUnix = 10]));
    expect(rows.map((m) => m.id), [2, 3, 1, null]);
  });

  test('the hash of a duplicate key reads the fields as the old core does', () {
    // Pinned against app/rust/src/core/history.rs `identity_hash`: SHA-256 of
    // `Some("dup")|None|[]|2|30|100`, first four bytes.
    final m = mergeHistory(
      const [],
      Meta(records: [record(slate: 'dup')..createdAtUnix = 2]),
    ).single;
    expect(identityHash(m), '3bd21f6f');
  });

  test('two thousand rows merge quickly', () {
    final rows = <TxEntry>[];
    final records = <Record>[];
    for (var i = 0; i < 1000; i++) {
      rows.add(live(i, slateId: 'r$i', amountCredited: 100));
      rows.add(
        live(
          1000 + i,
          slateId: 's$i',
          kind: TxKind.sent,
          kernel: 'k$i',
          amountDebited: 100,
        ),
      );
      records.add(record(slate: 's$i', commits: ['c$i'])..note = 'payment $i');
    }
    final watch = Stopwatch()..start();
    final merged = mergeHistory(rows, Meta(records: records));
    watch.stop();
    expect(merged, hasLength(2000));
    expect(merged.where((m) => m.note != null), hasLength(1000));
    expect(watch.elapsedMilliseconds, lessThan(1000));
  });
}
