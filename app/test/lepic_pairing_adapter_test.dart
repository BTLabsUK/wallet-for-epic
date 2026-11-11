// SPDX-License-Identifier: Apache-2.0
// The LEPIC adapter's pairing calls over a stand-in `EpicWallet` (26.10.18): late pairing
// messages, a pairing the other side removed, removal that tells it, and a key check that may
// not run. No native library is loaded.
import 'dart:async';
import 'dart:typed_data';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/pairing_fake.dart' show FakePairing;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:epic_wallet/src/ui/message_check_lines.dart' show messageCheckLines;
import 'package:epic_wallet/src/ui/pairing/pairing_notices.dart' show pairingNoticeOf;
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
  String? requested,
  String relay = _relay,
  lepic.ContactKind? kind,
  int? heard,
  int peerProfile = 0,
  Uint8List? enc,
}) => lepic.ContactView(
  contactId: id,
  label: '',
  claimedName: 'Bob',
  kind: kind,
  lastSealedInMs: heard,
  state: state,
  status: removed
      ? lepic.PairingStatus.ended
      : state == lepic.PairingState.verified
      ? lepic.PairingStatus.verified
      : lepic.PairingStatus.paired,
  peerFeatures: 0,
  peerProfile: peerProfile,
  paymentsAddress: proven,
  peerHeardAtMs: created,
  endedReason: removed ? lepic.PairingEndReason.unpaired : null,
  endedAtMs: removed ? created + 1000 : null,
  sas: const [],
  allowInvoices: false,
  seal: lepic.SealState.on_,
  appContact: app,
  homeRelay: relay,
  requestedRelay: requested,
  peerEncKey: enc,
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

  /// The contacts a check was sent to, and those whose check fails.
  final List<String> checked = [];
  final Set<String> checkFails = {};

  /// What a collect finds: run with the contacts it was limited to.
  void Function(List<String>? only)? onCollect;
  final List<List<String>?> collects = [];
  List<String> unreachable = [];
  lepic.KeyCheckStart keyCheck = lepic.KeyCheckStart.sent;

  @override
  bool get isDisposed => false;
  @override
  bool nativeDirectInUse() => false;

  @override
  void lock() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => eventSink.stream;

  @override
  Future<void> contactCheck({required String contactId}) async {
    if (checkFails.contains(contactId)) {
      throw const lepic.WalletError(kind: lepic.WalletErrorKind.contactNotFound, code: 0, message: 'no such contact');
    }
    checked.add(contactId);
  }

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async =>
      lepic.InvoiceSweep(deleted: const [], cancelled: Uint32List(0), cancellable: Uint32List(0));

  /// What collects report in turn; past the end, nothing more.
  final List<({int capped, int timedOut})> collectEnds = [];

  /// Mailboxes each collect reports stopped at a message held for later.
  int collectKept = 0;

  /// What collects report of their mailboxes in turn, ahead of [collectKept].
  final List<({int kept, int mailboxes, int notReached})> collectLooks = [];

  final List<lepic.QuarantinedMessageView> quarantine = [];
  final List<String> discarded = [];
  int retries = 0;

  @override
  Future<List<lepic.QuarantinedMessageView>> contactQuarantine() async => List.of(quarantine);

  @override
  Future<bool> contactQuarantineDiscard({required String id}) async {
    discarded.add(id);
    quarantine.removeWhere((m) => m.id == id);
    return true;
  }

  @override
  Future<lepic.QuarantineRetryReport> contactQuarantineRetry({String? id, required lepic.ContactRelayMode relayMode}) async {
    retries++;
    return lepic.QuarantineRetryReport(retried: quarantine.length, cleared: 0, kept: quarantine.length);
  }

  @override
  Future<lepic.ContactCollectReport> contactsCollect({
    required lepic.CollectTrigger trigger,
    required lepic.ContactRelayMode relayMode,
    List<String>? only,
  }) async {
    collects.add(only);
    onCollect?.call(only);
    final end = collectEnds.isEmpty ? (capped: 0, timedOut: 0) : collectEnds.removeAt(0);
    final look = collectLooks.isEmpty ? (kept: collectKept, mailboxes: 0, notReached: 0) : collectLooks.removeAt(0);
    return lepic.ContactCollectReport(
      capped: end.capped,
      kept: look.kept,
      refused: 0,
      timedOut: end.timedOut,
      notReached: look.notReached,
      quarantined: 0,
      quarantineDropped: 0,
      buffered: 0,
      mailboxes: look.mailboxes,
      messages: 1,
      paired: 0,
      failed: const [],
      delivered: 0,
      unreachable: unreachable,
      ended: const [],
    );
  }

  @override
  Future<lepic.OutboxReport> contactsOutboxDeliver({required lepic.ContactRelayMode relayMode}) async =>
      const lepic.OutboxReport(delivered: 0, failed: 0, stuck: 0);

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

  /// The posts again of a waiting send: contact and transaction.
  final List<String> reposted = [];

  @override
  Future<String?> contactOfTransaction({required int txId}) async => txId == 42 ? 'bob' : null;

  @override
  Future<lepic.SlateWire> contactPostSlate({
    required String contactId,
    required int txId,
    lepic.SlatePurpose? purpose,
    required lepic.ContactRelayMode relayMode,
  }) async {
    reposted.add('$contactId $txId ${purpose?.name}');
    return lepic.SlateWire.native;
  }

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

  final List<String> moved = [];

  /// As LEPIC's `contact_apply_relay_move`: only the relay the contact asked for.
  @override
  Future<void> contactApplyRelayMove({required String contactId, required String relay}) async {
    final i = paired.indexWhere((c) => c.contactId == contactId);
    if (i < 0 || paired[i].requestedRelay != relay) {
      throw const lepic.WalletError(kind: lepic.WalletErrorKind.relayMoveNotRequested, code: 92, message: 'not asked');
    }
    moved.add('$contactId $relay');
    paired[i] = _view(contactId, app: paired[i].appContact, relay: relay);
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

  group('a collect', () {
    lepic.QuarantinedMessageView kept(String id, Duration age) => lepic.QuarantinedMessageView(
      id: id,
      contactId: 'bob',
      reason: 'undecodable_slate',
      firstSeenMs: DateTime.now().subtract(age).millisecondsSinceEpoch,
      attempts: 1,
      size: BigInt.from(100),
    );

    test('goes back to a capped mailbox up to the limit', () async {
      wallet.collectEnds.addAll(List.filled(20, (capped: 1, timedOut: 0)));
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(wallet.collects, hasLength(1 + appConfig.number('contacts.collect_repeats')));
    });

    test('does not go back when it ran out of time', () async {
      wallet.collectEnds.addAll([(capped: 1, timedOut: 0), (capped: 1, timedOut: 1), (capped: 1, timedOut: 0)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(wallet.collects, hasLength(2));
    });

    test('adds the messages of every round to the check', () async {
      wallet.collectEnds.addAll([(capped: 1, timedOut: 0), (capped: 0, timedOut: 0)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(session.checks.value.outcome.messages, 2);
    });

    test('a message held in a mailbox shows on the check, once over the rounds', () async {
      wallet
        ..collectKept = 1
        ..collectEnds.addAll([(capped: 1, timedOut: 0), (capped: 0, timedOut: 0)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(session.checks.value.outcome.held, 1);
    });

    test('a held message stays on the check when a later round does not reach its mailbox', () async {
      wallet
        ..collectLooks.addAll([(kept: 1, mailboxes: 50, notReached: 0), (kept: 0, mailboxes: 50, notReached: 0)])
        ..collectEnds.addAll([(capped: 1, timedOut: 0), (capped: 0, timedOut: 0)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(messageCheckLines(englishStrings, session.checks.value), contains(englishStrings.msgCheckItemHeld(1)));
    });

    test('a look at fewer mailboxes leaves what a wider one held', () async {
      wallet.collectLooks.addAll([
        (kept: 1, mailboxes: 3, notReached: 0),
        // One contact's mailbox only.
        (kept: 0, mailboxes: 1, notReached: 0),
        // A relay down: only one of the three was read.
        (kept: 0, mailboxes: 3, notReached: 2),
      ]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      await (session.pairing as dynamic).collectOrFail(PairingCollectTrigger.foreground, only: ['bob']);
      expect(session.checks.value.outcome.held, 1);
      await session.pairing.collect();
      expect(session.checks.value.outcome.held, 1);
    });

    test('a look as wide as the last clears what it held', () async {
      wallet.collectLooks.addAll([(kept: 1, mailboxes: 3, notReached: 0), (kept: 0, mailboxes: 3, notReached: 0)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      await session.pairing.collect();
      expect(session.checks.value.outcome.held, 0);
    });

    test('a pull clears what a wider look held: it reads every mailbox', () async {
      wallet.collectLooks.addAll([(kept: 1, mailboxes: 3, notReached: 0), (kept: 0, mailboxes: 2, notReached: 0)]);
      await session.pairing.collect();
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(session.checks.value.outcome.held, 0);
    });

    test('tries kept messages again on open only', () async {
      wallet.quarantine.add(kept('a', Duration.zero));
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(wallet.retries, 0);
      await session.pairing.collect(trigger: PairingCollectTrigger.open);
      expect(wallet.retries, 1);
      expect(session.checks.value.outcome.unreadable, 1);
    });

    test('removes kept messages past the keep time', () async {
      final days = appConfig.number('contacts.quarantine_keep_days');
      wallet.quarantine.addAll([kept('old', Duration(days: days + 1)), kept('new', Duration.zero)]);
      await session.pairing.collect(trigger: PairingCollectTrigger.pull);
      expect(wallet.discarded, ['old']);
      expect(session.checks.value.outcome.unreadable, 1);
    });
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

  group('a sealed message that could not be opened', () {
    // The notice the user reads for the event the wallet raised.
    Future<String?> notice(lepic.WalletEvent e) async {
      wallet.eventSink.add(e);
      await _settle();
      final r = pairingNoticeOf(englishStrings, seen.single);
      return r?.text;
    }

    test('names the sender when its contact is known', () async {
      wallet.paired.add(_view('c1'));
      expect(await notice(const lepic.WalletEvent(kind: lepic.WalletEventKind.sealedUnopenable, contactId: 'c1')), 'A message from Bob could not be opened.');
    });

    test('names the sender when only its relay is known and a contact lives there', () async {
      wallet.paired.add(_view('c1'));
      expect(await notice(const lepic.WalletEvent(kind: lepic.WalletEventKind.sealedUnopenable, relay: _relay)), 'A message from Bob could not be opened.');
    });

    test('says it was sealed for another wallet or install when the sender is not known', () async {
      expect(await notice(const lepic.WalletEvent(kind: lepic.WalletEventKind.sealedUnopenable, contactId: 'stranger')), englishStrings.openSealedOtherTitle);
      expect(seen.single.name, isEmpty);
    });

    test('says the same with no contact and no relay at all', () async {
      expect(await notice(const lepic.WalletEvent(kind: lepic.WalletEventKind.sealedUnopenable)), englishStrings.openSealedOtherTitle);
    });
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

  test("the peer's profile bits reach the record", () async {
    wallet.paired.add(_view('svc', peerProfile: 3));
    expect((await session.pairing.pairing('svc'))!.peerProfile, 3);
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

  group('a contact asks to move to another relay', () {
    final domain = FakePairing.serviceKey;

    lepic.WalletEvent asked(String relay) => lepic.WalletEvent(kind: lepic.WalletEventKind.contactRelayMoveRequested, contactId: 'c1', relay: relay);

    test('any other contact to a public relay: moved without a word, and dated', () async {
      wallet.paired.add(_view('c1', requested: 'new.example.org:443'));
      wallet.eventSink.add(asked('new.example.org:443'));
      await _settle();

      expect(wallet.moved, ['c1 new.example.org:443']);
      expect(seen.map((e) => e.kind), [PairingEventKind.contactUpdated]);
      final r = (await session.pairing.pairings()).single;
      expect(r.homeRelay, 'new.example.org:443');
      expect(r.movedAt, isNotNull);
      expect(r.relayMove, RelayMoveState.none);
    });

    for (final host in ['192.168.1.20', 'localhost', 'box.local', 'relay.lan', 'x.internal', 'nas.home.arpa', 'abc.onion', 'relay']) {
      test('a relay that is not a public DNS name ($host): not moved, a quiet line', () async {
        wallet.paired.add(_view('c1', requested: host));
        wallet.eventSink.add(asked(host));
        await _settle();

        expect(wallet.moved, isEmpty);
        final r = (await session.pairing.pairings()).single;
        expect((r.homeRelay, r.relayMove), (_relay, RelayMoveState.notPublic));
        expect(wallet.moved, isEmpty);
      });
    }

    test('a domain-backed contact: asked once, nothing moves until the user says', () async {
      wallet.paired.add(_view('c1', requested: 'new.example.org', enc: domain));
      wallet.eventSink.add(asked('new.example.org'));
      await _settle();

      expect(wallet.moved, isEmpty);
      var r = (await session.pairing.pairings()).single;
      expect((r.homeRelay, r.relayMove), (_relay, RelayMoveState.ask));

      await session.pairing.markRelayMoveShown('c1', 'new.example.org');
      r = (await session.pairing.pairings()).single;
      expect(r.relayMove, RelayMoveState.open);
      expect(wallet.moved, isEmpty);
    });

    test('Accept moves a domain-backed contact', () async {
      wallet.paired.add(_view('c1', requested: 'new.example.org', enc: domain));
      await session.pairing.acceptRelayMove('c1', 'new.example.org');

      expect(wallet.moved, ['c1 new.example.org']);
      final r = (await session.pairing.pairings()).single;
      expect((r.homeRelay, r.relayMove), ('new.example.org', RelayMoveState.none));
      expect(r.movedAt, isNotNull);
    });

    test('Refuse keeps the relay; a move to another relay asks again', () async {
      wallet.paired.add(_view('c1', requested: 'new.example.org', enc: domain));
      await session.pairing.refuseRelayMove('c1', 'new.example.org');

      var r = (await session.pairing.pairings()).single;
      expect((r.homeRelay, r.relayMove), (_relay, RelayMoveState.refused));
      expect(wallet.moved, isEmpty);

      wallet.paired[0] = _view('c1', requested: 'third.example.org', enc: domain);
      r = (await session.pairing.pairings()).single;
      expect(r.relayMove, RelayMoveState.ask);
    });

    test('a move waiting from before is settled when the contacts load', () async {
      wallet.paired.add(_view('c1', requested: 'new.example.org'));
      final r = (await session.pairing.pairings()).single;
      expect(r.homeRelay, 'new.example.org');
      expect(wallet.moved, ['c1 new.example.org']);
    });

    test('settleRelayMoves makes the silent moves and leaves the asked ones', () async {
      wallet.paired.addAll([_view('c1', requested: 'new.example.org'), _view('c2', requested: 'other.example.org', enc: domain)]);
      await session.pairing.settleRelayMoves();
      await _settle();

      expect(wallet.moved, ['c1 new.example.org']);
      expect(seen.map((e) => e.kind), contains(PairingEventKind.contactUpdated));
    });
  });
  group('the contact check after a long gap', () {
    const wait = Duration(milliseconds: 60);
    const every = Duration(milliseconds: 20);
    final longAgo = DateTime.now().millisecondsSinceEpoch - 86400000;

    /// Replaces the contact [id] in the stand-in, as a collect would.
    void hear(String id, {String? requested, String? relay}) {
      final i = wallet.paired.indexWhere((c) => c.contactId == id);
      final c = wallet.paired[i];
      wallet.paired[i] = _view(id, kind: c.kind, peerProfile: c.peerProfile, heard: DateTime.now().millisecondsSinceEpoch + 5, requested: requested, relay: relay ?? c.homeRelay!);
    }

    test('asks automated contacts (card profile) that are not ended, not people; heard after is reachable, silence is not answering', () async {
      wallet.paired.addAll([
        _view('shop', peerProfile: 2, heard: longAgo),
        _view('ex', peerProfile: 2, heard: longAgo),
        _view('anna', kind: lepic.ContactKind.person, heard: longAgo),
        _view('old', peerProfile: 2, heard: longAgo, removed: true),
      ]);
      wallet.onCollect = (only) => hear('shop');

      final outcomes = await session.pairing.checkContacts(wait: wait, every: every);
      await _settle();

      expect(wallet.checked, ['shop', 'ex']);
      expect(outcomes, {'shop': ContactCheckOutcome.reachable, 'ex': ContactCheckOutcome.notAnswering});
      // Each look is at the contacts still waited for.
      expect(wallet.collects.first, ['shop', 'ex']);
      expect(wallet.collects.last, ['ex']);
      final records = {for (final r in await session.pairing.pairings()) r.id: r};
      expect(records['ex']!.notAnswering, isTrue);
      expect(records['shop']!.notAnswering, isFalse);
      expect(records['anna']!.notAnswering, isFalse);
      expect(seen.map((e) => e.kind), contains(PairingEventKind.contactUpdated));
    });

    test('Not answering lasts until the contact is heard again', () async {
      wallet.paired.add(_view('ex', peerProfile: 2, heard: longAgo));
      await session.pairing.checkContacts(wait: wait, every: every);
      expect((await session.pairing.pairings()).single.notAnswering, isTrue);

      hear('ex');
      expect((await session.pairing.pairings()).single.notAnswering, isFalse);
    });

    test('a later check that is answered clears it', () async {
      wallet.paired.add(_view('ex', peerProfile: 2, heard: longAgo));
      await session.pairing.checkContacts(wait: wait, every: every);
      wallet.onCollect = (only) => hear('ex');
      final outcomes = await session.pairing.checkContacts(wait: wait, every: every);

      expect(outcomes['ex'], ContactCheckOutcome.reachable);
      expect((await session.pairing.pairings()).single.notAnswering, isFalse);
    });

    test('a check that cannot be sent leaves the others to go on', () async {
      wallet.paired.addAll([
        _view('bad', peerProfile: 2, heard: longAgo),
        _view('good', peerProfile: 2, heard: longAgo),
      ]);
      wallet.checkFails.add('bad');
      wallet.onCollect = (only) => hear('good');

      final outcomes = await session.pairing.checkContacts(wait: wait, every: every);

      expect(wallet.checked, ['good']);
      expect(outcomes, {'bad': ContactCheckOutcome.failed, 'good': ContactCheckOutcome.reachable});
      expect((await session.pairing.pairings()).any((r) => r.notAnswering), isFalse);
    });

    test('a home relay that does not answer is not answering before the wait ends', () async {
      wallet.paired.add(_view('ex', peerProfile: 2, heard: longAgo));
      wallet.unreachable = [_relay];
      wallet.eventSink.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.homeRelayUnreachable, relay: _relay));
      await _settle();

      final outcomes = await session.pairing.checkContacts(wait: const Duration(seconds: 5), every: every);

      expect(outcomes['ex'], ContactCheckOutcome.notAnswering);
      expect(wallet.collects.length, 1);
    });

    test('an answer that names a public relay is followed', () async {
      wallet.paired.add(_view('shop', peerProfile: 2, heard: longAgo));
      wallet.onCollect = (only) => hear('shop', requested: 'listed.example.org:443');

      final outcomes = await session.pairing.checkContacts(wait: wait, every: every);

      expect(outcomes['shop'], ContactCheckOutcome.moved);
      expect(wallet.moved, ['shop listed.example.org:443']);
      expect((await session.pairing.pairings()).single.notAnswering, isFalse);
    });

    test('an answer that names a relay that is not public is not followed', () async {
      wallet.paired.add(_view('shop', peerProfile: 2, heard: longAgo));
      wallet.onCollect = (only) => hear('shop', requested: '10.0.0.7');

      final outcomes = await session.pairing.checkContacts(wait: wait, every: every);
      await _settle();

      expect(outcomes['shop'], ContactCheckOutcome.moved);
      expect(wallet.moved, isEmpty);
      expect((await session.pairing.pairings()).single.relayMove, RelayMoveState.notPublic);
    });
  });

  test('adapter maps repostViaMailbox to contactPostSlate', () async {
    await session.pairing.repostViaMailbox('l:42');

    expect(wallet.reposted, ['bob 42 payment']);
    await expectLater(session.pairing.repostViaMailbox('l:7'), throwsA(isA<WalletError>()));
    expect(wallet.reposted, hasLength(1));
  });
}
