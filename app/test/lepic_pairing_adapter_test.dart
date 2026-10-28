// The LEPIC adapter's pairing calls over a stand-in `EpicWallet` (26.10.18): late pairing
// messages, a pairing the other side removed, removal that tells it, and a key check that may
// not run. No native library is loaded.
import 'dart:async';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _relay = 'epicbox.iniaku.my.id:443';

lepic.ContactView _view(String id, {String? app, int created = 1792900000000, bool removed = false}) => lepic.ContactView(
  contactId: id,
  label: '',
  claimedName: 'Bob',
  state: lepic.PairingState.paired,
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

  @override
  Future<void> contactAttach({required String contactId, String? appContact}) async {
    final i = paired.indexWhere((c) => c.contactId == contactId);
    final c = paired[i];
    paired[i] = _view(c.contactId, app: appContact, created: c.createdAtMs, removed: c.removedByPeer);
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
