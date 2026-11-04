// SPDX-License-Identifier: Apache-2.0
// Directory pairing on the fakes: the hello and the Check the code step, Join and Leave, the
// directory's unlisted, and the payload routing between the devices and the directory services.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/directory/directory.dart';
import 'package:epic_wallet/src/directory/phone_directory.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart' show invoicesOnProvider;
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/ui/pairing/directory_parts.dart';
import 'package:epic_wallet/src/ui/pairing/pair_check.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'devices/two_devices.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final Uint8List _dkey = Uint8List.fromList([2, ...List.filled(32, 9)]);
final String _dkeyHex = toHex(_dkey);
const int _directoryBits = featureStatusNotices | featureDirectory;

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
      final want = sha256.convert([...'$_dkeyHex 0 $domain '.codeUnits, ...message]).bytes;
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

/// A directory service over [session], with a short wait and a clock the test moves.
class _Rig {
  _Rig({Duration wait = const Duration(seconds: 30)}) {
    service = DirectoryService(
      host: SessionDirectoryHost(session, net: netMainnet, verifier: verifier.call, online: () => true),
      store: DirectoryStore(store, chain: Chain.mainnet, walletId: 'w1'),
      clock: clock.call,
      wait: wait,
      poll: const Duration(seconds: 1),
    );
  }

  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final clock = _Now();
  final verifier = _Verifier();
  late final DirectoryService service;

  FakePairing get api => session.pairing;

  /// A Paired pairing whose peer claims the directory feature.
  PairingRecord paired({String name = 'Anna', int bits = _directoryBits}) {
    api.clock = clock.call;
    return api.seedPaired(name: name, state: PairingState.paired, peerFeatures: bits);
  }

  /// A Verified directory the wallet pinned: hello read, code matched.
  Future<PairingRecord> verified() async {
    await service.load();
    final r = paired();
    api.directoryHello(r.id, dkey: _dkey);
    await service.beginHello(r.id);
    await service.readPayloads();
    await api.checkWords(r.id, PairingCheck.match);
    await service.pin(r.id);
    return api.records.single;
  }

  List<DirectoryPayload> get posted => [for (final p in api.posted) DirectoryPayload.decode(Uint8List.fromList(p.bytes))];
}

void main() {
  group('the hello', () {
    test('a valid hello is held for the code; They match pins it', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired();
      expect(await rig.service.beginHello(r.id), HelloStep.waiting);
      rig.api.directoryHello(r.id, dkey: _dkey);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.pinned, isFalse);
      expect(rig.service.stepOf(r.id), HelloStep.waiting);
      await rig.service.pin(r.id);
      expect(rig.service.verifiedFor(r.id)?.dkey, _dkeyHex);
      expect(await rig.api.payloads(), isEmpty, reason: 'acknowledged once stored');
    });

    test('a hello bound to other words is dropped: the words step follows the wait', () async {
      final rig = _Rig(wait: const Duration(seconds: 3));
      await rig.service.load();
      final r = rig.paired();
      await rig.service.beginHello(r.id);
      rig.api.directoryHello(r.id, dkey: _dkey, bind: Uint8List.fromList([0, 0, 0, 0]));
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id), isNull);
      expect(await rig.api.payloads(), isEmpty, reason: 'acknowledged and dropped');
      rig.clock.now = rig.clock.now.add(const Duration(seconds: 4));
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(rig.service.stepOf(r.id), HelloStep.words);
    });

    test('a peer without the directory bit is the ordinary words step, its hello dropped', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired(bits: featureStatusNotices);
      expect(await rig.service.beginHello(r.id), HelloStep.words);
      rig.api.directoryHello(r.id, dkey: _dkey);
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

    test('a later hello from a Verified directory is acknowledged and ignored', () async {
      final rig = _Rig();
      final r = await rig.verified();
      expect(r.state, PairingState.verified);
      final before = rig.service.book;
      rig.api.directoryHello(r.id, dkey: _dkey, issued: 99);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.pinned, isTrue);
      expect(rig.service.book.entries.length, before.entries.length);
      expect(await rig.api.payloads(), isEmpty);
    });
  });

  group('contacts that take no payments', () {
    const address = 'esYeBkJwAuhPNdWBVhu6tk3nvgBfAi3FPfvkAefqGJtV5JFYGfJZ@epicbox.example.com';

    test('the hello flag is stored; lookups answer by pairing and by address', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.api.seedPaired(name: 'Shop', state: PairingState.paired, peerFeatures: _directoryBits, paymentsAddress: address);
      rig.api.clock = rig.clock.call;
      rig.api.directoryHello(r.id, dkey: _dkey, flags: dirHelloNoPayments);
      await rig.service.beginHello(r.id);
      await rig.service.readPayloads();
      expect(rig.service.book.byPairing(r.id)?.noPayments, isTrue);
      expect(rig.service.refusesPayments(pairingId: r.id), isTrue);
      expect(rig.service.refusesPayments(address: address), isTrue);
      expect(rig.service.refusesPayments(address: address.replaceFirst('epicbox.example.com', 'other.example.org')), isTrue,
          reason: 'the key part matches, as the contact screens do');
      expect(rig.service.refusesPayments(pairingId: 'nobody', address: 'esOther@epicbox.example.com'), isFalse);
      expect(rig.service.refusesPayments(), isFalse);
      // Kept in the app's own file and read back.
      final again = DirectoryService(
        host: SessionDirectoryHost(rig.session, net: netMainnet, verifier: rig.verifier.call, online: () => true),
        store: DirectoryStore(rig.store, chain: Chain.mainnet, walletId: 'w1'),
      );
      await again.load();
      expect(again.refusesPayments(address: address), isTrue);
    });

    test('a hello without the flag takes payments; an old file without it reads as false', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired();
      rig.api.directoryHello(r.id, dkey: _dkey);
      await rig.service.beginHello(r.id);
      await rig.service.readPayloads();
      expect(rig.service.refusesPayments(pairingId: r.id), isFalse);
      final old = DirectoryEntry.fromJson({'dkey': _dkeyHex, 'pairing': 'p', 'handle': '00'});
      expect(old?.noPayments, isFalse);
    });

    test('a later valid hello updates the flag', () async {
      final rig = _Rig();
      final r = await rig.verified();
      expect(rig.service.refusesPayments(pairingId: r.id), isFalse);
      rig.api.directoryHello(r.id, dkey: _dkey, flags: dirHelloNoPayments);
      await rig.service.readPayloads();
      expect(rig.service.refusesPayments(pairingId: r.id), isTrue);
      rig.api.directoryHello(r.id, dkey: _dkey);
      await rig.service.readPayloads();
      expect(rig.service.refusesPayments(pairingId: r.id), isFalse);
    });
  });

  group('receipts through the service', () {
    test('canTell follows a verified directory; post sends the bytes over its pairing', () async {
      final rig = _Rig();
      await rig.service.load();
      expect(rig.service.canTell(_dkeyHex), isFalse);
      final r = await rig.verified();
      expect(rig.service.canTell(_dkeyHex), isTrue);
      expect(await rig.service.post(_dkeyHex, Uint8List.fromList([1, 2, 3])), isTrue);
      expect(rig.api.posted.last.id, r.id);
      expect(rig.api.posted.last.bytes, [1, 2, 3]);
      expect(await rig.service.post('02${'00' * 32}', Uint8List.fromList([1])), isFalse);
    });
  });

  group('Join and Leave', () {
    test('Join posts a card the codec and the verifier accept', () async {
      final rig = _Rig();
      final r = await rig.verified();
      await rig.service.join(_dkeyHex);
      final payload = rig.posted.whereType<ListingPayload>().single;
      final card = await verifyCard(ListingCard.decode(payload.card.toBytes()), netMainnet, rig.verifier.call);
      expect(toHex(card.dkey), _dkeyHex);
      expect(card.seq, 1);
      expect(rig.verifier.listing, greaterThan(0));
      final e = rig.service.verifiedFor(r.id)!;
      expect((e.joined, e.generation), (true, 0));
      expect(e.address, card.address);
      expect(rig.service.listingCodeFor(_dkeyHex), listingCodeIndexes(card.listingKey));
    });

    test('Leave posts an unlist and retires the generation; the next Join uses a new one', () async {
      final rig = _Rig();
      await rig.verified();
      await rig.service.join(_dkeyHex);
      await rig.service.leave(_dkeyHex);
      expect(rig.posted.last, isA<UnlistPayload>());
      var e = rig.service.book.byDkey(_dkeyHex)!;
      expect(e.joined, isFalse);
      expect(e.retired.single.generation, 0);
      expect(e.retired.single.drainUntil, rig.clock.now.add(listingDrainWindow));
      await rig.service.join(_dkeyHex);
      e = rig.service.book.byDkey(_dkeyHex)!;
      expect(e.generation, 1);
      expect(e.retired.single.generation, 0);
    });

    test('unlisted from the directory: Not listed, the generation retired', () async {
      final rig = _Rig();
      final r = await rig.verified();
      await rig.service.join(_dkeyHex);
      final e = rig.service.verifiedFor(r.id)!;
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(dkey: _dkey, handle: fromHex(e.handle), issued: 5));
      await rig.service.readPayloads();
      final after = rig.service.verifiedFor(r.id)!;
      expect(after.state, ListingState.unlisted);
      expect(after.retired.single.generation, 0);
    });

    test('the drains cover the listed generation and the retired ones within their days', () async {
      final rig = _Rig();
      await rig.verified();
      await rig.service.join(_dkeyHex);
      await rig.service.leave(_dkeyHex);
      await rig.service.join(_dkeyHex);
      rig.session.fakeListing.drains.clear();
      await rig.service.sync(DirectorySyncTrigger.tick);
      expect(rig.session.fakeListing.drains.map((d) => d.$2).toSet(), {0, 1});
      rig.clock.now = rig.clock.now.add(listingDrainWindow + const Duration(hours: 1));
      rig.session.fakeListing.drains.clear();
      await rig.service.sync(DirectorySyncTrigger.tick);
      expect(rig.session.fakeListing.drains.map((d) => d.$2).toSet(), {1});
    });
  });

  group('payload routing', () {
    test('the devices service leaves a contact payload to the directory service, which takes it', () async {
      final clock = Clock();
      final b = Side('Desktop', clock: clock, net: FakePrivateNet());
      final service = DirectoryService(
        host: SessionDirectoryHost(b.session, net: netMainnet, verifier: _Verifier().call, online: () => true),
        store: DirectoryStore(b.store, chain: Chain.mainnet, walletId: 'w1'),
        clock: clock.call,
      );
      await service.load();
      final r = b.pairing.seedPaired(name: 'Anna', state: PairingState.paired, peerFeatures: _directoryBits);
      b.pairing.directoryHello(r.id, dkey: _dkey);
      await b.sync();
      expect(await b.pairing.payloads(), hasLength(1), reason: 'the devices service did not ack it');
      await service.readPayloads();
      expect(await b.pairing.payloads(), isEmpty);
      expect(service.book.byPairing(r.id), isNotNull);
    });

    test('a payload of a contact that is no directory is acknowledged and dropped', () async {
      final rig = _Rig();
      await rig.service.load();
      final r = rig.paired(bits: featureStatusNotices);
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(dkey: _dkey, handle: Uint8List(16), issued: 1));
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
            invoicesOnProvider.overrideWithValue(true),
            updatePlatformProvider.overrideWithValue(null),
            priceSourceProvider.overrideWithValue(_NoPrice()),
            qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
            slateFilesProvider.overrideWithValue(FakeSlateFiles()),
            sessionProvider.overrideWith(() => _OpenSession(rig.session)),
            directoryServiceProvider.overrideWith((ref) {
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
      expect(find.text(_l.dirWaitingFor('Anna')), findsOneWidget);
      expect(find.byKey(dirWaitCancelKey), findsOneWidget);
      rig.api.directoryHello(r.id, dkey: _dkey);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.dirCodeLead('Anna')), findsOneWidget);
      expect(find.descendant(of: find.byKey(dirCodeKey), matching: find.byType(WordTiles)), findsOneWidget);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(rig.api.records.single.state, PairingState.verified);
      expect(rig.service.verifiedFor(r.id), isNotNull);
      expect(find.text(_l.dirJoinTitle('Anna')), findsOneWidget);
      await tester.tap(find.byKey(dirJoinKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final card = rig.posted.whereType<ListingPayload>().single.card;
      await verifyCard(ListingCard.decode(card.toBytes()), netMainnet, rig.verifier.call);
      expect(rig.service.verifiedFor(r.id)!.joined, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no hello: Cancel gives the ordinary words step', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(dirWaitCancelKey), findsOneWidget);
      await tester.tap(find.byKey(dirWaitCancelKey));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      expect(find.byKey(dirWaitCancelKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no hello in the wait: the words step', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      rig.clock.now = rig.clock.now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('They do not match ends the pairing and forgets the directory', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = rig.paired();
      await mount(tester, rig, CheckWordsScreen(pairingId: r.id));
      await tester.pump(const Duration(milliseconds: 100));
      rig.api.directoryHello(r.id, dkey: _dkey);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(checkNoMatchKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(checkStopKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.api.records.single.state, PairingState.ended);
      expect(rig.service.book.byDkey(_dkeyHex), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the contact block: Joined · since, the listing code, Leave posts an unlist', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = await rig.verified();
      await rig.service.join(_dkeyHex);
      await mount(tester, rig, Scaffold(body: SingleChildScrollView(child: DirectoryBlock(pairingId: r.id, label: 'Anna'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Paid by name since'), findsOneWidget);
      expect(find.text(_l.dirListingCode), findsWidgets);
      await tester.tap(find.byKey(dirLeaveKey));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.posted.last, isA<UnlistPayload>());
      expect(find.text(_l.dirRemoveTooTitle('Anna')), findsOneWidget);
      await tester.tap(find.text(_l.contactKeep));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rig.service.verifiedFor(r.id)!.joined, isFalse);
      expect(find.byKey(dirJoinKey), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('unlisted: Not listed with Join again', (tester) async {
      final rig = await pump(tester, const SizedBox());
      final r = await rig.verified();
      await rig.service.join(_dkeyHex);
      final e = rig.service.verifiedFor(r.id)!;
      rig.api.receiveContactPayload(r.id, unlistedPayloadBytes(dkey: _dkey, handle: fromHex(e.handle), issued: 5));
      await rig.service.readPayloads();
      await mount(tester, rig, Scaffold(body: SingleChildScrollView(child: DirectoryBlock(pairingId: r.id, label: 'Anna'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_l.dirNotListed), findsOneWidget);
      expect(find.text(_l.dirJoinAgain), findsOneWidget);
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
