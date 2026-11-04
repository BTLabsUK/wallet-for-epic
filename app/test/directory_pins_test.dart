// SPDX-License-Identifier: Apache-2.0
// Payment-link pins and replay (docs/design/directory-wire.md §5): the trust state of a link,
// paid-before within 30 days, a changed wallet, a request made for another payer, expiry with
// the 120 s skew, and the history delete taking the pins with it. Synthetic vectors only.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/history/directory_pins.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'directory_vectors_support.dart';

Future<bool> _yes(String keyText, String domain, Uint8List message, Uint8List der) async => true;

void main() {
  final v = vectorList(loadVectors(), 'payreqs');
  Payreq request(String id) => Payreq.decode(fromHex(v.firstWhere((e) => e['id'] == id)['hex']! as String));

  final basic = request('req-basic');
  final dkeyHex = toHex(basic.card.dkey);
  final now = 1800000000;

  LinkStanding standing(Meta meta, {Set<String> dkeys = const {}, int? at}) => linkStanding(
    basic,
    pinnedDkeys: dkeys,
    pins: meta.directoryPins,
    paidRequests: meta.paidRequests,
    nowSeconds: at ?? now,
  );

  group('trust', () {
    test('a directory the user pairs with, and any other', () {
      final meta = Meta();
      expect(standing(meta, dkeys: {dkeyHex}).trust, DirectoryTrust.directoryYouUse);
      expect(standing(meta).trust, DirectoryTrust.notADirectoryYouUse);
      expect(standing(meta, dkeys: {'02ab'}).trust, DirectoryTrust.notADirectoryYouUse);
      expect(standing(meta).paidBefore, isNull);
    });

    test('a listing key that differs from the pinned one is a changed wallet', () {
      final meta = Meta();
      final other = ListingPin(listingKey: '03${'ab' * 32}', firstPaid: now - 900, lastPaid: now - 500);
      meta.directoryPins[pinKey(basic.card.dkey, basic.card.handle)] = other;
      final s = standing(meta, dkeys: {dkeyHex});
      expect(s.trust, DirectoryTrust.changedWallet);
      expect(s.changedSince, DateTime.fromMillisecondsSinceEpoch((now - 500) * 1000, isUtc: true));
    });

    test('a pin of another handle of the same directory does not matter', () {
      final meta = Meta();
      meta.recordLinkPayment(request('req-payee'), now - 100);
      expect(standing(meta).trust, DirectoryTrust.notADirectoryYouUse);
    });
  });

  group('pins and replay', () {
    test('a payment pins the listing key and remembers the request', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now - 1000);
      final pin = meta.directoryPins[pinKey(basic.card.dkey, basic.card.handle)]!;
      expect(pin, ListingPin(listingKey: toHex(basic.card.listingKey), firstPaid: now - 1000, lastPaid: now - 1000));
      final s = standing(meta, dkeys: {dkeyHex});
      expect(s.trust, DirectoryTrust.directoryYouUse);
      expect(s.paidBefore, DateTime.fromMillisecondsSinceEpoch((now - 1000) * 1000, isUtc: true));
    });

    test('paying again keeps the first date and moves the last', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now - 5000);
      meta.recordLinkPayment(basic, now - 1000);
      final pin = meta.directoryPins[pinKey(basic.card.dkey, basic.card.handle)]!;
      expect((pin.firstPaid, pin.lastPaid), (now - 5000, now - 1000));
    });

    test('paying after the changed-wallet warning replaces the pin', () {
      final meta = Meta();
      meta.directoryPins[pinKey(basic.card.dkey, basic.card.handle)] =
          ListingPin(listingKey: '03${'ab' * 32}', firstPaid: 1, lastPaid: 2);
      meta.recordLinkPayment(basic, now);
      final pin = meta.directoryPins[pinKey(basic.card.dkey, basic.card.handle)]!;
      expect(pin, ListingPin(listingKey: toHex(basic.card.listingKey), firstPaid: now, lastPaid: now));
      expect(standing(meta).trust, DirectoryTrust.notADirectoryYouUse);
    });

    test('a paid request is remembered for 30 days', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now);
      final day = const Duration(days: 1).inSeconds;
      expect(standing(meta, at: now + 29 * day).paidBefore, isNotNull);
      expect(standing(meta, at: now + 30 * day).paidBefore, isNull);
      // Recording a later payment drops the ones past the window.
      meta.recordLinkPayment(request('req-payee'), now + 31 * day);
      expect(meta.paidRequests.keys, [toHex(request('req-payee').reqid)]);
    });

    test('the pins survive the meta file and go with the history delete', () async {
      final tmp = await Directory.systemTemp.createTemp('directory_pins_');
      addTearDown(() => tmp.delete(recursive: true));
      final store = await MetaStore.open(tmp.path);
      await store.update((m) => m.recordLinkPayment(basic, now));
      final again = await MetaStore.open(tmp.path);
      expect(again.snapshot.directoryPins, hasLength(1));
      expect(again.snapshot.paidRequests, hasLength(1));
      await MetaStore.deleteFiles(tmp.path);
      final fresh = await MetaStore.open(tmp.path);
      expect(fresh.snapshot.directoryPins, isEmpty);
      expect(fresh.snapshot.paidRequests, isEmpty);
    });
  });

  group('made for another payer and expiry', () {
    final forOne = request('req-for');
    final mine = forOne.forKey!;

    test('a request for a listing key is for that wallet only', () async {
      Future<Payreq> run(Uint8List? key) =>
          verifyPayreq(forOne, net: 0, nowSeconds: now, listingKey: key, verifier: _yes);
      expect(await run(mine), isA<Payreq>());
      await expectLater(run(null), throwsA(isA<DirectoryException>().having((e) => e.error, 'error', DirectoryError.forOther)));
      final other = Uint8List.fromList(mine)..[5] ^= 1;
      await expectLater(run(other), throwsA(isA<DirectoryException>().having((e) => e.error, 'error', DirectoryError.forOther)));
    });

    test('a request open to anyone ignores the wallet key', () async {
      expect(await verifyPayreq(basic, net: 0, nowSeconds: now, listingKey: mine, verifier: _yes), isA<Payreq>());
    });

    test('expiry allows 120 seconds of clock skew', () async {
      final expires = basic.expires.toInt();
      Future<Payreq> at(int t) => verifyPayreq(basic, net: 0, nowSeconds: t, verifier: _yes);
      expect(await at(expires), isA<Payreq>());
      expect(await at(expires + expirySkewSeconds), isA<Payreq>());
      await expectLater(at(expires + expirySkewSeconds + 1), throwsA(isA<DirectoryException>().having((e) => e.error, 'error', DirectoryError.expired)));
    });
  });
}
