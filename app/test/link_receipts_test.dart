// SPDX-License-Identifier: Apache-2.0
// The record of a payment made from a link (Meta round-trip, 30 day pruning), the type 5 receipt
// payload, and tellPayee: once per stage, never when the directory cannot be told.
import 'dart:io';

import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/directory/receipts.dart';
import 'package:epic_wallet/src/history/directory_pins.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'directory_vectors_support.dart';
import 'support/fake_receipts.dart';

void main() {
  final v = vectorList(loadVectors(), 'payreqs');
  Payreq request(String id) => Payreq.decode(fromHex(v.firstWhere((e) => e['id'] == id)['hex']! as String));
  final basic = request('req-basic');
  final other = request('req-payee');
  final now = 1800000000;
  const day = 86400;

  group('the record', () {
    test('kept by slate id, survives the meta file, told stages preserved on a re-record', () async {
      final tmp = await Directory.systemTemp.createTemp('link_rec_');
      addTearDown(() => tmp.delete(recursive: true));
      final store = await MetaStore.open(tmp.path);
      await store.update((m) => m.recordLinkPayment(basic, now, txId: 'slate-1'));
      final records = MetaLinkPayments(store);
      final rec = records.of('slate-1')!;
      expect(rec.reqid, toHex(basic.reqid));
      expect(rec.dkey, toHex(basic.card.dkey));
      expect(rec.shortId, toHex(basic.reqid).substring(0, 8));
      expect(rec.paidAt, now);
      expect(rec.told, isEmpty);
      await records.markTold('slate-1', 1);
      await store.update((m) => m.recordLinkPayment(basic, now, txId: 'slate-1'));
      expect(records.of('slate-1')!.told, {1});

      final again = await MetaStore.open(tmp.path);
      final back = again.snapshot.linkPayments['slate-1']!;
      expect(back, records.of('slate-1'));
      expect(back.amount, rec.amount);
      expect(back.told, {1});
    });

    test('without a txId nothing is stored; pruned with the paid requests at 30 days', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now);
      expect(meta.linkPayments, isEmpty);
      meta.recordLinkPayment(basic, now, txId: 'old');
      meta.recordLinkPayment(other, now + 29 * day, txId: 'mid');
      expect(meta.linkPayments.keys, containsAll(['old', 'mid']));
      meta.recordLinkPayment(other, now + 31 * day, txId: 'new');
      expect(meta.linkPayments.keys, ['mid', 'new']);
    });
  });

  group('the payload', () {
    test('encodes to a type 5 payload that decodes to the same fields', () {
      final reqid = basic.reqid;
      final bytes = ReceiptPayload.encode(reqid: reqid, stage: 2, amount: BigInt.from(500000000), at: now);
      final back = DirectoryPayload.decode(bytes) as ReceiptPayload;
      expect(back.reqid, reqid);
      expect(back.stage, 2);
      expect(back.amount, BigInt.from(500000000));
      expect(back.at, BigInt.from(now));
      expect(() => ReceiptPayload.encode(reqid: reqid, stage: 3, amount: BigInt.one, at: now), throwsA(anything));
    });
  });

  group('tellPayee', () {
    late MemoryLinkPayments records;
    setUp(() {
      final m = Meta()..recordLinkPayment(basic, now, txId: 's');
      records = MemoryLinkPayments({'s': m.linkPayments['s']!});
    });

    Future<bool> tell(FakeReceipts r, int stage, [int at = 1800000100]) =>
        tellPayee(receipts: r, records: records, slateId: 's', stage: stage, at: at);

    test('posts once per stage, bytes decode to the request, stage, amount and time', () async {
      final r = FakeReceipts();
      expect(await tell(r, 1, now), isTrue);
      expect(await tell(r, 1), isFalse);
      expect(r.posts, hasLength(1));
      final p = DirectoryPayload.decode(r.posts.single.$2) as ReceiptPayload;
      expect(r.posts.single.$1, toHex(basic.card.dkey));
      expect(p.reqid, basic.reqid);
      expect(p.stage, 1);
      expect(p.amount, records.of('s')!.amount);
      expect(p.at, BigInt.from(now));
      // Stage 2 is its own receipt.
      expect(await tell(r, 2), isTrue);
      expect(r.posts, hasLength(2));
      expect((DirectoryPayload.decode(r.posts.last.$2) as ReceiptPayload).stage, 2);
      expect(records.of('s')!.told, {1, 2});
    });

    test('nothing when the directory cannot be told, none when it refuses', () async {
      final r = FakeReceipts(tell: false);
      expect(await tell(r, 1), isFalse);
      expect(r.posts, isEmpty);
      final refuse = FakeReceipts(accept: false);
      expect(await tell(refuse, 1), isFalse);
      expect(records.of('s')!.told, isEmpty, reason: 'a refused post may be ticked again');
      expect(receiptLineOf(r, records.of('s'), posted: false), isNull);
      expect(receiptLineOf(FakeReceipts(), records.of('s'), posted: false)!.stage, 1);
      expect(receiptLineOf(FakeReceipts(), records.of('s'), posted: true)!.stage, 2);
    });

    test('a contact is matched to the listing address by its key', () {
      final rec = records.of('s')!;
      final key = rec.address.split('@').first;
      expect(contactEpicboxFor(rec, [null, 'x@y', '${key.toUpperCase()}@epicbox.example']), '${key.toUpperCase()}@epicbox.example');
      expect(contactEpicboxFor(rec, ['zzz@epicbox.example']), isNull);
    });
  });
}
