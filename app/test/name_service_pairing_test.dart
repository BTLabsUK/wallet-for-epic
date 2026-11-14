// SPDX-License-Identifier: Apache-2.0
// Name service pairing on the fakes: the hello and the Check the code step, Join and Leave, the
// name service's unlisted, and the payload routing between the devices and the name service services.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/name_service/phone_name_service.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/ui/pairing/name_service_parts.dart';
import 'package:epic_wallet/src/ui/pairing/pair_check.dart';
import 'package:epic_wallet/src/ui/pairing/pair_incoming.dart' show PairingWaitingScreen;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'devices/two_devices.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final Uint8List _serviceKey = Uint8List.fromList([2, ...List.filled(32, 9)]);
final String _serviceKeyHex = toHex(_serviceKey);
const int _nameServiceBits = featureStatusNotices | featureNameService;

class _Now {
  DateTime now = DateTime.utc(2026, 11, 4, 12);
  DateTime call() => now;
}

/// The verifier of the fakes' listing keys: a signature is the hash [FakeListingKeys] makes,
/// the hello's is filler. [listing] counts the card checks.
class _Verifier {
  int listing = 0;

  Future<bool> call(String keyText, String domain, Uint8List message, Uint8List der) async {
    if (domain == domainListing) {
      listing++;
      final want = sha256.convert([...'$_serviceKeyHex 0 $domain '.codeUnits, ...message]).bytes;
      return _same(der, want);
    }
    return domain == domainHello || domain == domainUnlist;
  }
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A name service service over [session], with a short wait and a clock the test moves.
class _Rig {
  _Rig({Duration wait = const Duration(seconds: 30)}) {
    service = NameService(
      host: SessionNameServiceHost(session, net: netMainnet, verifier: verifier.call, online: () => true),
      store: NameServiceStore(store, chain: Chain.mainnet, walletId: 'w1'),
      clock: clock.call,
      wait: wait,
      onDrained: drained.add,
    );
  }

  final drained = <PaymentsDrainReport>[];
  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final clock = _Now();
  final verifier = _Verifier();
  late final NameService service;

  FakePairing get api => session.pairing;

  /// A Paired pairing whose peer claims the name service feature.
  PairingRecord paired({String name = 'Anna', int bits = _nameServiceBits}) {
    api.clock = clock.call;
    return api.seedPaired(name: name, state: PairingState.paired, peerFeatures: bits);
  }

  /// A Verified name service the wallet pinned: hello read, code matched.
  Future<PairingRecord> verified() async {
    await service.load();
    final r = paired();
    api.nameServiceHello(r.id, serviceKey: _serviceKey);
    await service.beginHello(r.id);
    await service.readPayloads();
    await api.checkWords(r.id, PairingCheck.match);
    await service.pin(r.id);
    return api.records.single;
  }

  List<NameServicePayload> get posted => [for (final p in api.posted) NameServicePayload.decode(Uint8List.fromList(p.bytes))];
}

void main() {
  group('the hello', () {
    test('a valid hello is held for the code; They match pins it', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired();
      expect(await rig.service.beginHello(r.id), HelloStep.waiting);
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.pinned, isFalse);
      expect(rig.service.stepOf(r.id), HelloStep.waiting);
      await rig.service.pin(r.id);
      expect(rig.service.verifiedFor(r.id)?.serviceKey, _serviceKeyHex);
      expect(await rig.api.payloads(), isEmpty, reason: 'acknowledged once stored');
    });

    test('a hello bound to other words is dropped: the words step follows the wait', () async {
      final rig = _Rig(wait: const Duration(seconds: 3));
      await rig.service.load();
      final r = rig.paired();
      await rig.service.beginHello(r.id);
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, bind: Uint8List.fromList([0, 0, 0, 0]));
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id), isNull);
      expect(await rig.api.payloads(), isEmpty, reason: 'acknowledged and dropped');
      rig.clock.now = rig.clock.now.add(const Duration(seconds: 4));
      await rig.service.sync(NameServiceSyncTrigger.tick);
      expect(rig.service.stepOf(r.id), HelloStep.words);
    });

    test('a peer without the name service bit is the ordinary words step, its hello dropped', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired(bits: featureStatusNotices);
      expect(await rig.service.beginHello(r.id), HelloStep.words);
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id), isNull);
      expect(await rig.api.payloads(), isEmpty);
    });

    test('Cancel is the words step', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired();
      await rig.service.beginHello(r.id);
      rig.service.cancelHello(r.id);
      expect(rig.service.stepOf(r.id), HelloStep.words);
    });

    test('a later hello from a Verified name service is acknowledged and ignored', () async {
      final rig = _Rig();
      final r = await rig.verified();
      expect(r.state, PairingState.verified);
      final before = rig.service.book;
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, issued: 99);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.pinned, isTrue);
      expect(rig.service.book.entries.length, before.entries.length);
      expect(await rig.api.payloads(), isEmpty);
    });
  });

  group('contacts that take no payments', () {
    const address = 'esYeBkJwAuhPNdWBVhu6tk3nvgBfAi3FPfvkAefqGJtV5JFYGfJZ@epicbox.example.com';

    test('the card profile refuses by pairing and by address; a hello changes nothing', () async {
      final rig = _Rig();
      await rig.service.load();
      rig.api.clock = rig.clock.call;
      final r = rig.api.seedPaired(
        name: 'Shop',
        state: PairingState.paired,
        peerFeatures: _nameServiceBits,
        peerProfile: profileNoPayments,
        paymentsAddress: address,
      );
      final other = rig.api.seedPaired(name: 'Anna', paymentsAddress: 'esOther@epicbox.example.com', peerProfile: profileAutomated);
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey);
      await rig.service.beginHello(r.id);
      await rig.service.readPayloads();
      final refusals = PairingRefusals(await rig.api.pairings());
      expect(refusals.refusesPayments(pairingId: r.id), isTrue);
      expect(refusals.refusedName(pairingId: r.id), 'Shop');
      expect(refusals.refusesPayments(address: address), isTrue);
      expect(refusals.refusesPayments(address: address.replaceFirst('epicbox.example.com', 'other.example.org')), isTrue,
          reason: 'the key part matches, as the contact screens do');
      expect(refusals.refusesPayments(pairingId: other.id, address: 'esOther@epicbox.example.com'), isFalse);
      expect(refusals.refusesPayments(), isFalse);
    });

    test('a book saved with the old noPayments value still loads, and the value is ignored', () async {
      final rig = _Rig();
      final old = {
        'v': 1,
        'entries': [
          {'dkey': _serviceKeyHex, 'pairing': 'p1', 'handle': '00', 'label': 'Shop', 'pinned': true, 'noPayments': true, 'payAs': '@alice_test'},
        ],
      };
      await rig.store.write(NameServiceStore.keyFor(Chain.mainnet, 'w1'), jsonEncode(old));
      await rig.service.load();
      final e = rig.service.book.byPairing('p1');
      expect(e?.pinned, isTrue);
      expect(e?.payAs, '@alice_test');
      expect(e!.toJson().containsKey('noPayments'), isFalse);
    });

    test('a replayed older hello, or one with the same issued, changes nothing', () async {
      final rig = _Rig();
      final r = await rig.verified();
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@alice_test', issued: 5);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, '@alice_test');
      // The older hello (issued 1 from verified(), then 4) does not revert the name.
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, issued: 4);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, '@alice_test');
      // The same issued with other content is ignored too.
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@bob', issued: 5);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, '@alice_test');
      expect(rig.service.book.byPairing(r.id)?.issued, BigInt.from(5));
    });

    test('an entry saved before issued was kept accepts the next hello; issued survives a reload', () {
      final entry = NameServiceEntry.fromJson({'dkey': 'aa', 'pairing': 'p', 'handle': 'bb'})!;
      expect(entry.issued, isNull);
      final back = NameServiceEntry.fromJson(entry.copyWith(issued: BigInt.from(7)).toJson())!;
      expect(back.issued, BigInt.from(7));
    });
  });

  group('the label in the hello', () {
    test('the @name is stored on the entry; a later hello replaces it, one without it clears it', () async {
      final rig = _Rig();
      final r = await rig.verified();
      expect(rig.service.book.byPairing(r.id)?.payAs, isNull);
      expect(rig.service.book.byPairing(r.id)?.payAsArg, 'none');
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@alice_test', issued: 2);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, '@alice_test');
      expect(rig.service.book.byPairing(r.id)?.payAsArg, '@alice_test');
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@bob', issued: 3);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, '@bob');
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, issued: 4);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.payAs, isNull);
    });
  });

  group('receipts through the service', () {
    test('canTell follows a verified name service; post sends the bytes over its pairing', () async {
      final rig = _Rig();
      await rig.service.load();
      expect(rig.service.canTell(_serviceKeyHex), isFalse);
      final r = await rig.verified();
      expect(rig.service.canTell(_serviceKeyHex), isTrue);
      expect(await rig.service.post(_serviceKeyHex, Uint8List.fromList([1, 2, 3])), isTrue);
      expect(rig.api.posted.last.id, r.id);
      expect(rig.api.posted.last.bytes, [1, 2, 3]);
      expect(await rig.service.post('02${'00' * 32}', Uint8List.fromList([1])), isFalse);
    });
  });

  group('Join and Leave', () {
    test('Join posts a card the codec and the verifier accept', () async {
      final rig = _Rig();
      final r = await rig.verified();
      await rig.service.join(_serviceKeyHex);
      final payload = rig.posted.whereType<ListingPayload>().single;
      final card = await verifyCard(ListingCard.decode(payload.card.toBytes()), netMainnet, rig.verifier.call);
      expect(toHex(card.serviceKey), _serviceKeyHex);
      expect(card.seq, 1);
      expect(rig.verifier.listing, greaterThan(0));
      final e = rig.service.verifiedFor(r.id)!;
      expect((e.joined, e.generation), (true, 0));
      expect(e.address, card.address);
      expect(rig.service.listingCodeFor(_serviceKeyHex), listingCodeIndexes(card.listingKey));
    });

    test('Leave posts an unlist and retires the generation; the next Join uses a new one', () async {
      final rig = _Rig();
      await rig.verified();
      await rig.service.join(_serviceKeyHex);
      await rig.service.leave(_serviceKeyHex);
      expect(rig.posted.last, isA<UnlistPayload>());
      var e = rig.service.book.byServiceKey(_serviceKeyHex)!;
      expect(e.joined, isFalse);
      expect(e.retired.single.generation, 0);
      expect(e.retired.single.drainUntil, rig.clock.now.add(listingDrainWindow));
      await rig.service.join(_serviceKeyHex);
      e = rig.service.book.byServiceKey(_serviceKeyHex)!;
      expect(e.generation, 1);
      expect(e.retired.single.generation, 0);
    });

    test('unlisted from the name service: Not listed, the generation retired', () async {
      final rig = _Rig();
      final r = await rig.verified();
      await rig.service.join(_serviceKeyHex);
      final e = rig.service.verifiedFor(r.id)!;
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(serviceKey: _serviceKey, handle: fromHex(e.handle), issued: 5));
      await rig.service.readPayloads();
      final after = rig.service.verifiedFor(r.id)!;
      expect(after.state, ListingState.unlisted);
      expect(after.retired.single.generation, 0);
    });

    test('the drains cover the listed generation and the retired ones within their days', () async {
      final rig = _Rig();
      await rig.verified();
      await rig.service.join(_serviceKeyHex);
      await rig.service.leave(_serviceKeyHex);
      await rig.service.join(_serviceKeyHex);
      rig.session.fakeListing.drains.clear();
      await rig.service.sync(NameServiceSyncTrigger.tick);
      expect(rig.session.fakeListing.drains.map((d) => d.$2).toSet(), {0, 1});
      rig.clock.now = rig.clock.now.add(listingDrainWindow + const Duration(hours: 1));
      rig.session.fakeListing.drains.clear();
      await rig.service.sync(NameServiceSyncTrigger.tick);
      expect(rig.session.fakeListing.drains.map((d) => d.$2).toSet(), {1});
    });

    /// Seventeen retired generations and the joined one: 18 live listings of one service.
    Future<_Rig> eighteenListings() async {
      final rig = _Rig();
      await rig.verified();
      for (var i = 0; i < 17; i++) {
        await rig.service.join(_serviceKeyHex);
        await rig.service.leave(_serviceKeyHex);
      }
      await rig.service.join(_serviceKeyHex);
      rig.session.fakeListing.drains.clear();
      rig.session.fakeListing.batches.clear();
      return rig;
    }

    test('the drains go in batches of at most 16 listings, in order, one report each', () async {
      final rig = await eighteenListings();
      final keys = rig.session.fakeListing;
      keys.reports[(_serviceKeyHex, 3)] = const PaymentsDrainReport(received: 2);
      keys.reports[(_serviceKeyHex, 16)] = const PaymentsDrainReport(finalized: 1, bounced: 1);
      await rig.service.sync(NameServiceSyncTrigger.tick);
      expect(keys.batches.map((b) => b.length), [16, 2]);
      expect([for (final b in keys.batches) for (final l in b) l.$2], [17, for (var g = 0; g < 17; g++) g]);
      // The joined generation comes first, then the retired ones as the book lists them.
      // A report with something in it reaches the host, in the order of the listings.
      expect(rig.drained.map((r) => (r.received, r.finalized, r.bounced)), [(2, 0, 0), (0, 1, 1)]);
    });

    test('a failed batch is logged and left for the next drain: the next batch goes on, nothing is retried', () async {
      final rig = await eighteenListings();
      final keys = rig.session.fakeListing;
      keys.drainFailure = StateError('relay down');
      keys.reports[(_serviceKeyHex, 16)] = const PaymentsDrainReport(received: 1);
      await rig.service.sync(NameServiceSyncTrigger.tick);
      expect(keys.batches.map((b) => b.length), [16, 2], reason: 'one call for each batch, none repeated');
      expect(keys.drains.map((d) => d.$2), [15, 16], reason: 'only the second batch went through');
      expect(rig.drained.single.received, 1);
    });
  });

  group('payload routing', () {
    test('the devices service leaves a contact payload to the name service service, which takes it', () async {
      final clock = Clock();
      final b = Side('Desktop', clock: clock, net: FakePrivateNet());
      final service = NameService(
        host: SessionNameServiceHost(b.session, net: netMainnet, verifier: _Verifier().call, online: () => true),
        store: NameServiceStore(b.store, chain: Chain.mainnet, walletId: 'w1'),
        clock: clock.call,
      );
      await service.load();
      final r = b.pairing.seedPaired(name: 'Anna', state: PairingState.paired, peerFeatures: _nameServiceBits);
      b.pairing.nameServiceHello(r.id, serviceKey: _serviceKey);
      await b.sync();
      expect(await b.pairing.payloads(), hasLength(1), reason: 'the devices service did not ack it');
      await service.readPayloads();
      expect(await b.pairing.payloads(), isEmpty);
      expect(service.book.byPairing(r.id), isNotNull);
    });

    test('a payload of a contact that is no name service is acknowledged and dropped', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired(bits: featureStatusNotices);
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(serviceKey: _serviceKey, handle: Uint8List(16), issued: 1));
      rig.api.receiveContactPayload(r.id, [1, 2, 3]);
      await rig.service.readPayloads();
      expect(await rig.api.payloads(), isEmpty);
      expect(rig.service.book.entries, isEmpty);
    });
  });

  group('screens', () {
    Future<_Rig> pump(WidgetTester tester, Widget home, {Duration wait = const Duration(seconds: 30)}) async {
      final rig = _Rig(wait: wait);
      await rig.service.load();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      return rig;
    }

    Future<void> mount(WidgetTester tester, _Rig rig, Widget home) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            walletServiceProvider.overrideWithValue(FakeWalletService(session: rig.session)),
            secretStoreProvider.overrideWithValue(rig.store),
            updatePlatformProvider.overrideWithValue(null),
            priceSourceProvider.overrideWithValue(_NoPrice()),
            qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
            slateFilesProvider.overrideWithValue(FakeSlateFiles()),
            sessionProvider.overrideWith(() => _OpenSession(rig.session)),
            nameServiceProvider.overrideWith((ref) {
              ref.onDispose(rig.service.dispose);
              return rig.service;
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('waiting, then Check the code; They match pins it and Join posts a verifiable card', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.nsWaitingFor('Anna')), findsOneWidget);
      expect(find.byKey(nsWaitCancelKey), findsOneWidget);
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey);
      unawaited(rig.service.sync(NameServiceSyncTrigger.tick));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.nsCodeLead('Anna')), findsOneWidget);
      expect(find.descendant(of: find.byKey(nsCodeKey), matching: find.byType(WordTiles)), findsOneWidget);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(rig.api.records.single.state, PairingState.verified);
      expect(rig.service.verifiedFor(r.id), isNotNull);
      expect(find.text(_l.nsJoinTitle('none', 'Anna')), findsOneWidget);
      expect(find.text(_l.nsJoin('none', 'Anna')), findsOneWidget);
      expect(find.text('Pay me via Anna'), findsOneWidget);
      await tester.tap(find.byKey(nsJoinKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final card = rig.posted.whereType<ListingPayload>().single.card;
      await verifyCard(ListingCard.decode(card.toBytes()), netMainnet, rig.verifier.call);
      expect(rig.service.verifiedFor(r.id)!.joined, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the features come with the confirm: the wait opens though the records still reload', (tester) async {
      final rig = await pump(tester, const SizedBox());
      rig.api.clock = rig.clock.call;
      final preview = await rig.api.openInvite(rig.api.inviteLinkFrom(name: 'Anna'));
      final answered = await rig.api.acceptInvite(token: preview.token, name: 'Alex');
      expect(answered.peerFeatures & _nameServiceBits, 0, reason: 'the answerer learns them from the confirm');
      await mount(tester, rig, PairingWaitingScreen(pairingId: answered.id, name: 'Anna'));
      rig.api.listDelay = const Duration(milliseconds: 300);
      rig.api.confirmAnswer(answered.id, features: _nameServiceBits);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CheckWordsScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(_l.nsWaitingFor('Anna')), findsOneWidget);
      rig.api.nameServiceHello(answered.id, serviceKey: _serviceKey);
      unawaited(rig.service.sync(NameServiceSyncTrigger.tick));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.nsCodeLead('Anna')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no hello: Cancel gives the ordinary words step', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(nsWaitCancelKey), findsOneWidget);
      await tester.tap(find.byKey(nsWaitCancelKey));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      expect(find.byKey(nsWaitCancelKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no hello in the wait: the words step', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      rig.clock.now = rig.clock.now.add(const Duration(seconds: 31));
      unawaited(rig.service.sync(NameServiceSyncTrigger.tick));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('They do not match ends the pairing and forgets the name service', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey);
      unawaited(rig.service.sync(NameServiceSyncTrigger.tick));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(checkNoMatchKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(checkStopKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.api.records.single.state, PairingState.ended);
      expect(rig.service.book.byServiceKey(_serviceKeyHex), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with a name in the hello the Join sheet says Pay me as @name', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@alice_test');
      unawaited(rig.service.sync(NameServiceSyncTrigger.tick));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pay me as @alice_test?'), findsOneWidget);
      expect(find.text('Pay me as @alice_test'), findsOneWidget);
      expect(find.textContaining('Pay me via'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the contact block: Joined · since, the listing code, Leave posts an unlist', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = await rig.verified();
      rig.api.nameServiceHello(r.id, serviceKey: _serviceKey, label: '@alice_test', issued: 2);
      await rig.service.readPayloads();
      await rig.service.join(_serviceKeyHex);
      await mount(tester, rig, Scaffold(body: SingleChildScrollView(child: NameServiceBlock(pairingId: r.id, label: 'Anna'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Pay me as @alice_test · since'), findsOneWidget);
      expect(find.text(_l.nsLeave), findsOneWidget);
      expect(find.text(_l.nsListingCode), findsWidgets);
      await tester.tap(find.byKey(nsLeaveKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.posted.last, isA<UnlistPayload>());
      expect(find.text(_l.nsRemoveTooTitle('Anna')), findsOneWidget);
      await tester.tap(find.text(_l.contactKeep));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.service.verifiedFor(r.id)!.joined, isFalse);
      expect(find.byKey(nsJoinKey), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('unlisted: Not listed with Join again', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = await rig.verified();
      await rig.service.join(_serviceKeyHex);
      final e = rig.service.verifiedFor(r.id)!;
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(serviceKey: _serviceKey, handle: fromHex(e.handle), issued: 5));
      await rig.service.readPayloads();
      await mount(tester, rig, Scaffold(body: SingleChildScrollView(child: NameServiceBlock(pairingId: r.id, label: 'Anna'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.nsNotListed), findsOneWidget);
      expect(find.text(_l.nsJoinAgain), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}
