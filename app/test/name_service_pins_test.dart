// SPDX-License-Identifier: Apache-2.0
// Payment-link pins and replay (docs/design/name-service-wire.md §5): the trust state of a link,
// paid-before within 30 days, a changed wallet, a request made for another payer, expiry with
// the 120 s skew, and the history delete taking the pins with it. Synthetic vectors only.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/history/name_service_pins.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'name_service_vectors_support.dart';

Future<bool> _yes(String keyText, String domain, Uint8List message, Uint8List der) async => true;

void main() {
  final v = vectorList(loadVectors(), 'payreqs');
  Payreq request(String id) => Payreq.decode(fromHex(v.firstWhere((e) => e['id'] == id)['hex']! as String));

  final basic = request('req-basic');
  final serviceKeyHex = toHex(basic.card.serviceKey);
  final now = 1800000000;

  LinkStanding standing(Meta meta, {Set<String> serviceKeys = const {}, int? at}) => linkStanding(
    basic,
    pinnedServiceKeys: serviceKeys,
    pins: meta.nameServicePins,
    paidRequests: meta.paidRequests,
    nowSeconds: at ?? now,
  );

  group('trust', () {
    test('a name service the user pairs with, and any other', () {
      final meta = Meta();
      expect(standing(meta, serviceKeys: {serviceKeyHex}).trust, NameServiceTrust.nameServiceYouUse);
      expect(standing(meta).trust, NameServiceTrust.notANameServiceYouUse);
      expect(standing(meta, serviceKeys: {'02ab'}).trust, NameServiceTrust.notANameServiceYouUse);
      expect(standing(meta).paidBefore, isNull);
    });

    test('a listing key that differs from the pinned one is a changed wallet', () {
      final meta = Meta();
      final other = ListingPin(listingKey: '03${'ab' * 32}', firstPaid: now - 900, lastPaid: now - 500);
      meta.nameServicePins[pinKey(basic.card.serviceKey, basic.card.handle)] = other;
      final s = standing(meta, serviceKeys: {serviceKeyHex});
      expect(s.trust, NameServiceTrust.changedWallet);
      expect(s.changedSince, DateTime.fromMillisecondsSinceEpoch((now - 500) * 1000, isUtc: true));
    });

    test('a pin of another handle of the same name service does not matter', () {
      final meta = Meta();
      meta.recordLinkPayment(request('req-payee'), now - 100);
      expect(standing(meta).trust, NameServiceTrust.notANameServiceYouUse);
    });
  });

  group('pins and replay', () {
    test('a payment pins the listing key and remembers the request', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now - 1000);
      final pin = meta.nameServicePins[pinKey(basic.card.serviceKey, basic.card.handle)]!;
      expect(pin, ListingPin(listingKey: toHex(basic.card.listingKey), firstPaid: now - 1000, lastPaid: now - 1000));
      final s = standing(meta, serviceKeys: {serviceKeyHex});
      expect(s.trust, NameServiceTrust.nameServiceYouUse);
      expect(s.paidBefore, DateTime.fromMillisecondsSinceEpoch((now - 1000) * 1000, isUtc: true));
    });

    test('paying again keeps the first date and moves the last', () {
      final meta = Meta();
      meta.recordLinkPayment(basic, now - 5000);
      meta.recordLinkPayment(basic, now - 1000);
      final pin = meta.nameServicePins[pinKey(basic.card.serviceKey, basic.card.handle)]!;
      expect((pin.firstPaid, pin.lastPaid), (now - 5000, now - 1000));
    });

    test('paying after the changed-wallet warning replaces the pin', () {
      final meta = Meta();
      meta.nameServicePins[pinKey(basic.card.serviceKey, basic.card.handle)] =
          ListingPin(listingKey: '03${'ab' * 32}', firstPaid: 1, lastPaid: 2);
      meta.recordLinkPayment(basic, now);
      final pin = meta.nameServicePins[pinKey(basic.card.serviceKey, basic.card.handle)]!;
      expect(pin, ListingPin(listingKey: toHex(basic.card.listingKey), firstPaid: now, lastPaid: now));
      expect(standing(meta).trust, NameServiceTrust.notANameServiceYouUse);
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
      final tmp = await Directory.systemTemp.createTemp('name_service_pins_');
      addTearDown(() => tmp.delete(recursive: true));
      final store = await MetaStore.open(tmp.path);
      await store.update((m) => m.recordLinkPayment(basic, now));
      final again = await MetaStore.open(tmp.path);
      expect(again.snapshot.nameServicePins, hasLength(1));
      expect(again.snapshot.paidRequests, hasLength(1));
      await MetaStore.deleteFiles(tmp.path);
      final fresh = await MetaStore.open(tmp.path);
      expect(fresh.snapshot.nameServicePins, isEmpty);
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
      await expectLater(run(null), throwsA(isA<NameServiceException>().having((e) => e.error, 'error', NameServiceError.forOther)));
      final other = Uint8List.fromList(mine)..[5] ^= 1;
      await expectLater(run(other), throwsA(isA<NameServiceException>().having((e) => e.error, 'error', NameServiceError.forOther)));
    });

    test('a request open to anyone ignores the wallet key', () async {
      expect(await verifyPayreq(basic, net: 0, nowSeconds: now, listingKey: mine, verifier: _yes), isA<Payreq>());
    });

    test('expiry allows 120 seconds of clock skew', () async {
      final expires = basic.expires.toInt();
      Future<Payreq> at(int t) => verifyPayreq(basic, net: 0, nowSeconds: t, verifier: _yes);
      expect(await at(expires), isA<Payreq>());
      expect(await at(expires + expirySkewSeconds), isA<Payreq>());
      await expectLater(at(expires + expirySkewSeconds + 1), throwsA(isA<NameServiceException>().having((e) => e.error, 'error', NameServiceError.expired)));
    });
  });
}
