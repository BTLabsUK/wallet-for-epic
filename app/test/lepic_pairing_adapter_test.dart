// SPDX-License-Identifier: Apache-2.0
// The LEPIC adapter's pairing calls over a stand-in `EpicWallet` (26.10.18): late pairing
// messages, a pairing the other side removed, removal that tells it, and a key check that may
// not run. No native library is loaded.
import 'dart:async';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _relay = 'epicbox.pool.example.org:443';

/// A stored pairing as LEPIC lists it. [proven] is the payments address its proof gave, null
/// for a pairing made before 26.10.25 (v13 marks those heard at their creation, with no proof).
lepic.ContactView _view(
  String id, {
  String? app,
  int created = 1792900000000,
  bool removed = false,
  String? proven,
  lepic.PairingState state = lepic.PairingState.paired,
}) => lepic.ContactView(
  contactId: id,
  label: '',
  claimedName: 'Bob',
  state: state,
  status: removed
      ? lepic.PairingStatus.ended
      : state == lepic.PairingState.verified
      ? lepic.PairingStatus.verified
      : lepic.PairingStatus.paired,
  peerFeatures: 0,
  paymentsAddress: proven,
  peerHeardAtMs: created,
  endedReason: removed ? lepic.PairingEndReason.unpaired : null,
  endedAtMs: removed ? created + 1000 : null,
  sas: const [],
  allowInvoices: false,
  seal: lepic.SealState.on_,
  appContact: app,
  homeRelay: _relay,
  importedFromBackup: false,
  lapsed: false,
  removedByPeer: removed,
  createdAtMs: created,
);

/// LEPIC's pairings in memory. Fails any other native call.
class _PairingWallet implements lepic.EpicWallet {
  final List<lepic.PendingPairingView> pending = [];
  final List<lepic.ContactView> paired = [];
  final StreamController<lepic.WalletEvent> eventSink = StreamController<lepic.WalletEvent>.broadcast();
  final List<String> calls = [];
  lepic.KeyCheckStart keyCheck = lepic.KeyCheckStart.sent;

  @override
  bool get isDisposed => false;

  @override
  void lock() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => eventSink.stream;

  @override
  Future<List<lepic.PendingPairingView>> pairingsPending() async => pending;

  @override
  Future<List<lepic.ContactView>> contacts() async => paired;

  @override
  Future<lepic.ContactView> contact({required String contactId}) async =>
      paired.where((c) => c.contactId == contactId).firstOrNull ??
      (throw const lepic.WalletError(kind: lepic.WalletErrorKind.contactNotFound, code: 0, message: 'no such contact'));

  @override
  Future<List<lepic.ContactView>> pairingsForAppContact({required String appContact}) async => [
    for (final c in paired)
      if (c.appContact == appContact) c,
  ];

  final List<String?> attachAddresses = [];

  /// As LEPIC's `check_attach_address`: with an address, the pairing must prove that key.
  @override
  Future<void> contactAttach({required String contactId, String? appContact, String? appAddress}) async {
    attachAddresses.add(appAddress);
    final i = paired.indexWhere((c) => c.contactId == contactId);
    final c = paired[i];
    if (appContact != null && appAddress != null) {
      final proven = c.paymentsAddress;
      if (proven == null) throw const lepic.WalletError(kind: lepic.WalletErrorKind.addressProofMissing, code: 82, message: 'no proof');
      if (proven.split('@').first != appAddress.split('@').first) {
        throw const lepic.WalletError(kind: lepic.WalletErrorKind.otherAddress, code: 81, message: 'another key');
      }
    }
    paired[i] = _view(c.contactId, app: appContact, created: c.createdAtMs, removed: c.removedByPeer, proven: c.paymentsAddress, state: c.state);
  }

  final List<lepic.PairRequestView> requests = [];
  final List<String> dismissed = [];
  final List<String?> acceptedExpecting = [];

  @override
  Future<List<lepic.PairRequestView>> pairingRequests() async => [for (final r in requests) if (!dismissed.contains(r.requestId)) r];

  @override
  Future<void> pairingRequestDismiss({required String requestId}) async {
    if (!requests.any((r) => r.requestId == requestId) || dismissed.contains(requestId)) {
      throw const lepic.WalletError(kind: lepic.WalletErrorKind.pairingNotFound, code: 0, message: 'no request');
    }
    dismissed.add(requestId);
  }

  @override
  Future<lepic.InvitePreview> pairingPreview({required String link}) async =>
      lepic.InvitePreview(claimedName: 'Anna', kind: lepic.ContactKind.person, expiresAtMs: 1792990000000, homeRelay: _relay, service: false, pairingClass: lepic.PairingClass.contact, own: false);

  @override
  Future<lepic.PairingAnswer> pairingAccept({
    required String link,
    required String name,
    required bool byHand,
    required lepic.ContactRelayMode relayMode,
    required lepic.PairingClass pairingClass,
    String? expectAddress,
  }) async {
    acceptedExpecting.add(expectAddress);
    return const lepic.PairingAnswer(contactId: 'answer-1', replyLink: 'epiccash://pair-reply/1/x', posted: true);
  }

  @override
  Future<lepic.KeyCheckStart> contactKeyCheck({
    required String new_,
    required String old,
    required lepic.ContactRelayMode relayMode,
  }) async {
    calls.add('keyCheck');
    return keyCheck;
  }

  @override
  Future<void> contactKeysResolve({required String new_, required lepic.KeysDecision decision}) async => calls.add('resolve');

  @override
  Future<bool> contactUnpair({required String contactId, required lepic.ContactRelayMode relayMode}) async {
    calls.add('unpair $contactId');
    paired.removeWhere((c) => c.contactId == contactId);
    return true;
  }

  @override
  Future<bool> contactRemove({required String contactId}) async {
    calls.add('remove $contactId');
    paired.removeWhere((c) => c.contactId == contactId);
    return true;
  }
}

/// Lets the stand-in's events reach the session.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _PairingWallet wallet;
  late LepicWalletSession session;
  late List<PairingEvent> seen;

  setUp(() {
    wallet = _PairingWallet();
    session = LepicWalletSession(wallet);
    seen = [];
    session.pairing.events().listen(seen.add);
  });

  test("an invite whose home relay did not answer says so and names the relay", () async {
    wallet.pending.add(
      lepic.PendingPairingView(
        contactId: 'invite-1',
        inviter: true,
        inviteName: 'Alex',
        label: '',
        expiresAtMs: 1792900600000,
        createdAtMs: 1792900000000,
        homeRelay: _relay,
      ),
    );
    var invite = (await session.pairing.pairings()).single;
    expect((invite.relayDown, invite.homeRelay), (false, _relay));

    wallet.eventSink.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.homeRelayUnreachable, relay: _relay));
    await _settle();

    invite = (await session.pairing.pairings()).single;
    expect(invite.state, PairingState.pendingInvite);
    expect(invite.relayDown, isTrue);
  });

  test('an answer whose confirmation never came ends as not completed', () async {
    wallet.eventSink.add(
      const lepic.WalletEvent(
        kind: lepic.WalletEventKind.pairingFailed,
        contactId: 'answer-1',
        pairingFailure: lepic.PairingFailureReason.notConfirmed,
      ),
    );
    await _settle();
    expect(seen.single.kind, PairingEventKind.failed);
    expect(seen.single.failure, PairingFailure.notCompleted);
  });

  test('a pairing the other side removed is marked, said once, and pays nothing', () async {
    wallet.paired.add(_view('dead', app: 'book-1', removed: true));
    wallet.eventSink.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.contactUnpaired, contactId: 'dead'));
    await _settle();

    expect(seen.single.kind, PairingEventKind.unpaired);
    expect(seen.single.pairingId, 'dead');
    final r = (await session.pairing.pairing('dead'))!;
    expect(r.removedByPeer, isTrue);
    expect(r.paysByMailbox, isFalse);
    expect(r.seals, isFalse);
  });

  test('removing a pairing tells the other side', () async {
    wallet.paired.add(_view('p1'));
    await session.pairing.removePairing('p1');
    expect(wallet.calls, ['unpair p1']);
  });

  test('a key check that may not run leaves the new pairing in keys changed, not checking', () async {
    wallet.paired.addAll([_view('old', app: 'book-1'), _view('new', created: 1792990000000)]);
    wallet.keyCheck = lepic.KeyCheckStart.keysChanged;

    final r = await session.pairing.attach('new', 'book-1');

    expect(wallet.calls, ['keyCheck']);
    expect(r.checksKeys, isFalse);
    // LEPIC says keys changed itself; no "old keys not checked" notice.
    await _settle();
    expect(seen.where((e) => e.kind == PairingEventKind.keyCheckRefused), isEmpty);
  });

  // Attaching to a picked contact: LEPIC checks the contact's Epicbox address against the one
  // the pairing proves; the address book is written at Verified only, never by the attach.
  test('a pairing that proves another key is refused by a contact with an Epicbox address', () async {
    final c = await session.saveContact(contact: Contact(id: '', name: 'BT Labs', epicbox: 'es${'B' * 50}@epicbox.example.org'));
    wallet.paired.add(_view('new', proven: 'es${'C' * 50}@epicbox.example.org'));

    await expectLater(
      session.pairing.attach('new', c.id),
      throwsA(isA<WalletError>().having(pairingFailureOf, 'failure', PairingFailure.otherAddress)),
    );
    expect(wallet.attachAddresses.single, c.epicbox, reason: "the contact's own address goes to LEPIC");
    expect(wallet.paired.single.appContact, isNull);
    expect((await session.contacts()).single.epicbox, c.epicbox);
  });

  test('a pairing made before 26.10.25 (no proof, heard) shows honestly and attaches by address as not proven', () async {
    // As v13 migrated it: verified by the words then, heard at its creation, no proven address.
    wallet.paired.add(_view('old-pairing', state: lepic.PairingState.verified));
    final r = (await session.pairing.pairing('old-pairing'))!;
    expect(r.state, PairingState.verified, reason: 'what the words check gave, nothing more');
    expect(r.paymentsAddress, isNull);
    expect(r.peerHeardAt, isNotNull);
    expect(r.ended, isFalse);
    const address = 'esAnnaKey@epicbox.example.org';
    expect(pairingVouchesFor(r, address), isFalse, reason: 'no proven address is claimed for it');

    final c = await session.saveContact(contact: Contact(id: '', name: 'Anna', epicbox: address));
    await expectLater(
      session.pairing.attach('old-pairing', c.id),
      throwsA(isA<WalletError>().having(pairingFailureOf, 'failure', PairingFailure.addressProofMissing)),
    );
    expect(wallet.paired.single.appContact, isNull, reason: 'nothing changed');
    // Save as a new contact (no address): it attaches, and the book gets no address from it.
    final fresh = await session.saveContact(contact: Contact(id: '', name: 'Bob'));
    final attached = await session.pairing.attach('old-pairing', fresh.id);
    expect(attached.contactId, fresh.id);
    expect((await session.contacts()).firstWhere((x) => x.id == fresh.id).epicbox, isNull);
  });

  test('a pairing that ended keeps its record with the reason', () async {
    wallet.paired.add(_view('gone', removed: true));
    final r = (await session.pairing.pairing('gone'))!;
    expect((r.state, r.endedReason, r.removedByPeer), (PairingState.ended, PairingEndReason.unpaired, true));
    expect(r.endedAt, isNotNull);
  });

  test("a request opened and answered expects its sender's address and goes to the linked device", () async {
    wallet.requests.add(
      lepic.PairRequestView(
        requestId: '0123456789abcdef',
        fromAddress: 'esAnnaKey@epicbox.example.org',
        claimedName: 'Anna',
        kind: lepic.ContactKind.person,
        receivedAtMs: 1792900000000,
        expiresAtMs: 4102444800000,
        inviteLink: 'epiccash://pair/1/abc',
      ),
    );
    final listed = (await session.pairing.requests()).single;
    expect((listed.id, listed.fromAddress, listed.claimedName), ('0123456789abcdef', 'esAnnaKey@epicbox.example.org', 'Anna'));

    final preview = await session.pairing.openRequest(listed.id);
    expect((preview.fromAddress, preview.requestId), ('esAnnaKey@epicbox.example.org', listed.id));
    await session.pairing.acceptInvite(token: preview.token, name: 'Alex');
    expect(wallet.acceptedExpecting.single, 'esAnnaKey@epicbox.example.org');
    await _settle();
    expect(seen.where((e) => e.kind == PairingEventKind.requestAnswered).single.requestId, listed.id);
  });

  test('a request the linked device passed on is listed, and hidden once answered there', () async {
    final forwarded = PairRequest(
      id: 'fedcba9876543210',
      fromAddress: 'esAnnaKey@epicbox.example.org',
      claimedName: 'Anna',
      receivedAt: DateTime(2026, 11, 1),
      expiresAt: DateTime(2100),
      inviteLink: 'epiccash://pair/1/def',
    );
    await session.pairing.takeForwardedRequest(forwarded);
    expect((await session.pairing.requests()).single.id, forwarded.id);
    await _settle();
    expect(seen.last.kind, PairingEventKind.requested);

    await session.pairing.requestHandledOn(forwarded.id, 'Desktop 3F2A');
    expect(await session.pairing.requests(), isEmpty);
    await _settle();
    expect((seen.last.kind, seen.last.name), (PairingEventKind.pairedElsewhere, 'Desktop 3F2A'));
  });

  test('a contact with no Epicbox address takes the pairing; its HTTP and Tor stay', () async {
    final c = await session.saveContact(contact: Contact(id: '', name: 'Ana', http: 'https://wallet.example.org'));
    wallet.paired.add(_view('new'));

    final r = await session.pairing.attach('new', c.id);

    expect(r.contactId, c.id);
    final saved = (await session.contacts()).single;
    expect((saved.epicbox, saved.http), (null, 'https://wallet.example.org'));
    expect(wallet.calls, isEmpty, reason: 'no other pairing, no key check');
  });

  test('a contact with a pairing already takes a new one only through the key check', () async {
    final c = await session.saveContact(contact: Contact(id: '', name: 'Ana'));
    wallet.paired.addAll([_view('old', app: c.id), _view('new', created: 1792990000000)]);

    await session.pairing.attach('new', c.id);

    expect(wallet.calls, ['keyCheck']);
  });

  test("using the new keys removes the contact's older pairings, which the other side lost", () async {
    wallet.paired.addAll([
      _view('older', app: 'book-1', created: 1792800000000),
      _view('old', app: 'book-1', created: 1792900000000),
      _view('new', app: 'book-1', created: 1792990000000),
      _view('elsewhere', app: 'book-2', created: 1792800000000),
    ]);

    final kept = await session.pairing.resolveKeysChanged('new', KeysChoice.useNew);

    expect(kept.id, 'new');
    expect(wallet.calls, ['resolve', 'remove older', 'remove old']);
    expect([for (final c in wallet.paired) c.contactId], ['new', 'elsewhere']);
  });
}
