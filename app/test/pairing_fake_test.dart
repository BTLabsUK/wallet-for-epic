// The fake pairing engine (RFC 0002) the screens, the tour and the web preview run on: the
// states a pairing goes through, the key check, invoices only from a verified contact with
// Allow invoices on, and the per-wallet backup.
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _failure(PairingFailure f) => throwsA(isA<WalletError>().having(pairingFailureOf, 'failure', f));

void main() {
  late FakeWalletSession session;
  late FakePairing api;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 10, 25, 12);
    session = FakeWalletSession();
    api = session.pairing..clock = () => now;
  });

  test('an invite: answered, then paired with four words, then verified', () async {
    final events = <PairingEvent>[];
    api.events().listen(events.add);
    final invite = await api.makeInvite(name: 'Alex', expiry: const Duration(hours: 24), label: 'Anna');
    expect(invite.state, PairingState.pendingInvite);
    expect(invite.expiresAt, now.add(const Duration(hours: 24)));
    expect(pairingLinkKind(invite.inviteLink!), PairingLinkKind.invite);

    api.answerInvite(invite.id, name: 'Anna');
    await pumpEventQueue();
    expect(events.single.kind, PairingEventKind.replied);
    final paired = (await api.pairing(invite.id))!;
    expect(paired.state, PairingState.paired);
    expect(paired.sas, hasLength(sasWordCount));

    final verified = await api.checkWords(invite.id, PairingCheck.match);
    expect(verified!.state, PairingState.verified);
    expect(verified.verifiedAt, now);
    expect(verified.allowInvoices, isFalse, reason: 'never on unless the user turned it on');
  });

  test('words: offered for 10 minutes, found once, refused without the relay', () async {
    final invite = await api.makeInvite(name: 'Alex', expiry: const Duration(days: 7), words: true);
    expect(invite.inviteWords, hasLength(pairingWordCount));
    expect(invite.expiresAt, now.add(pairingWordsExpiry));
    api.relayUnreachable = true;
    await expectLater(
      api.makeInvite(name: 'Alex', expiry: const Duration(hours: 1), words: true),
      _failure(PairingFailure.noRelay),
    );
  });

  test('the other side: an invite read, answered, and confirmed', () async {
    final link = api.inviteLinkFrom(name: 'Northwind', kind: PairingParty.exchange, asksInvoices: true);
    final preview = await api.openInvite(link);
    expect((preview.name, preview.kind, preview.asksInvoices), ('Northwind', PairingParty.exchange, true));
    final answered = await api.acceptInvite(token: preview.token, name: 'Alex', allowInvoices: true);
    expect(answered.state, PairingState.pendingReply);
    api.confirmAnswer(answered.id);
    final verified = await api.checkWords(answered.id, PairingCheck.match);
    expect(verified!.allowInvoices, isTrue, reason: 'the user turned it on when answering');
    await expectLater(api.acceptInvite(token: preview.token, name: 'Alex'), _failure(PairingFailure.invalid));
  });

  test('an expired invite cannot be opened; a link that is none is invalid', () async {
    await expectLater(
      api.openInvite(api.inviteLinkFrom(name: 'Anna', expiresIn: const Duration(minutes: -1))),
      _failure(PairingFailure.expired),
    );
    await expectLater(api.openInvite('epiccash://pair/1/nonsense'), _failure(PairingFailure.invalid));
  });

  test('an answer without a confirm for an hour ends; an expired invite stays listed', () async {
    final preview = await api.openInvite(api.inviteLinkFrom(name: 'Anna'));
    final answered = await api.acceptInvite(token: preview.token, name: 'Alex');
    final invite = await api.makeInvite(name: 'Alex', expiry: const Duration(hours: 1));
    now = now.add(const Duration(hours: 2));
    expect(await api.collect(), 1);
    expect(await api.pairing(answered.id), isNull);
    expect((await api.pairing(invite.id))!.expiredAt(now), isTrue);
  });

  test('words that do not match drop the pairing; skip keeps it paired', () async {
    final a = api.seedPaired(name: 'Anna', state: PairingState.paired);
    final b = api.seedPaired(name: 'Tom', state: PairingState.paired);
    expect(await api.checkWords(a.id, PairingCheck.mismatch), isNull);
    expect(await api.pairing(a.id), isNull);
    final skipped = await api.checkWords(b.id, PairingCheck.skip);
    expect((skipped!.state, skipped.checkSkipped), (PairingState.paired, true));
  });

  test('Allow invoices: only for a verified contact; requests park only while it is on', () async {
    final tom = api.seedPaired(name: 'Tom', state: PairingState.paired, paymentsAddress: 'es${'t' * 50}@relay');
    await expectLater(api.setAllowInvoices(tom.id, true), throwsA(isA<WalletError>()));
    final anna = api.seedPaired(name: 'Anna', paymentsAddress: 'es${'a' * 50}@relay');
    Future<int> parked(String slateId) async {
      session.relayInvoice(from: 'es${'a' * 50}@relay', slateId: slateId, amount: BigInt.one);
      return (await session.drainInvoices()).parked;
    }

    expect(await parked('i0'), 0);
    await api.setAllowInvoices(anna.id, true);
    expect(await parked('i1'), 1);
    await api.setAllowInvoices(anna.id, false);
    expect(await parked('i2'), 0);
  });

  test('keys changed: the old record stays aside; Keep the old keys brings it back', () async {
    final old = api.seedPaired(name: 'Anna', contactId: 'c1', allowInvoices: true, paymentsAddress: 'es${'a' * 50}@relay');
    final changed = api.changeKeys(old.id);
    expect(changed.state, PairingState.keysChanged);
    expect(changed.contactId, 'c1');
    expect((await api.pairingForContact('c1'))!.id, changed.id);
    session.relayInvoice(from: 'es${'a' * 50}@relay', slateId: 'i1', amount: BigInt.one);
    expect((await session.drainInvoices()).parked, 0, reason: 'nothing parks while the keys are in question');
    final back = await api.resolveKeysChanged(changed.id, KeysChoice.keepOld);
    expect((back.id, back.state, back.allowInvoices), (old.id, PairingState.verified, true));
    expect(await api.pairing(changed.id), isNull);
  });

  test('keys changed: Use the new keys leaves them paired, to be checked, invoices off', () async {
    final old = api.seedPaired(name: 'Anna', allowInvoices: true);
    final changed = api.changeKeys(old.id);
    final next = await api.resolveKeysChanged(changed.id, KeysChoice.useNew);
    expect((next.state, next.allowInvoices, next.verifiedAt), (PairingState.paired, false, null));
  });

  test('the backup carries the paired records; restored elsewhere they are marked so', () async {
    api.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
    await api.makeInvite(name: 'Alex', expiry: const Duration(hours: 1));
    final backup = api.exportBackup();
    expect((backup!['records'] as List), hasLength(1), reason: 'pending invites stay behind');
    final other = FakeWalletSession().pairing;
    expect(other.importBackup(backup), 1);
    final restored = (await other.pairing('p1'))!;
    expect((restored.contactId, restored.otherDevice), ('c1', true));
    expect(await other.useImportedPairings(), 1);
    expect((await other.pairing('p1'))!.otherDevice, isFalse);
  });

  group('which pairing a contact uses (PAIR-AND-20)', () {
    PairingRecord rec(String id, {required DateTime created, DateTime? heard, PairingState state = PairingState.verified, bool checking = false, String? contact = 'anna'}) =>
        PairingRecord(id: id, state: state, way: PairingWay.link, inviter: false, createdAt: created, lastSealedIn: heard ?? created, contactId: contact, checksKeys: checking);
    final t0 = DateTime(2026, 10, 25, 5);

    test('of three attached, the one heard from last, not a newer one never heard from', () {
      final all = [
        // Newest first, as the lists hold them.
        rec('re-pair-2', created: t0.add(const Duration(hours: 4))),
        rec('re-pair-1', created: t0.add(const Duration(hours: 3)), heard: t0.add(const Duration(hours: 5))),
        rec('first', created: t0, heard: t0.add(const Duration(minutes: 10))),
        rec('other', created: t0.add(const Duration(hours: 6)), contact: 'ben'),
        rec('orphan', created: t0.add(const Duration(hours: 6)), contact: null),
      ];
      expect(contactPairingOf(all, 'anna')?.id, 're-pair-1');
      expect(contactPairingOf(all, 'ben')?.id, 'other');
      expect(contactPairingOf(all, 'nobody'), isNull);
    });

    test('a new pairing heard from by nobody yet is newer than an old one heard from before it', () {
      final all = [rec('new', created: t0.add(const Duration(hours: 2))), rec('old', created: t0, heard: t0.add(const Duration(hours: 1)))];
      expect(contactPairingOf(all, 'anna')?.id, 'new');
    });

    test('keys changed comes first; one still checking keys only when nothing else is', () {
      final checking = rec('checking', created: t0.add(const Duration(hours: 2)), checking: true);
      final old = rec('old', created: t0);
      expect(contactPairingOf([checking, old], 'anna')?.id, 'old');
      expect(contactPairingOf([checking], 'anna')?.id, 'checking');
      final changed = rec('changed', created: t0.add(const Duration(hours: 1)), state: PairingState.keysChanged);
      expect(contactPairingOf([old, changed], 'anna')?.id, 'changed');
      expect(contactPairingOf([rec('pending', created: t0, state: PairingState.pendingInvite)], 'anna'), isNull);
    });

    test('one the other side removed is taken only when nothing else is, and pays nothing', () {
      final dead = rec('dead', created: t0, heard: t0.add(const Duration(hours: 5))).copyWith(removedByPeer: true);
      final live = rec('live', created: t0.add(const Duration(hours: 1)));
      expect(contactPairingOf([dead, live], 'anna')?.id, 'live');
      expect(contactPairingOf([dead], 'anna')?.id, 'dead');
      expect((dead.paysByMailbox, live.paysByMailbox), (false, true));
    });
  });

  test('a core without pairing refuses every call', () async {
    api.enabled = false;
    expect(api.supported, isFalse);
    await expectLater(api.makeInvite(name: 'x', expiry: const Duration(hours: 1)), throwsA(isA<WalletError>()));
    expect(await api.pairings(), isEmpty);
    expect(const NoPairing().supported, isFalse);
  });
}
