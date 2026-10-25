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
    final invite = await api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Anna');
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
    final invite = await api.makeInvite(name: 'the owner', expiry: const Duration(days: 7), words: true);
    expect(invite.inviteWords, hasLength(pairingWordCount));
    expect(invite.expiresAt, now.add(pairingWordsExpiry));
    api.relayUnreachable = true;
    await expectLater(
      api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1), words: true),
      _failure(PairingFailure.relayUnreachable),
    );
  });

  test('the other side: an invite read, answered, and confirmed', () async {
    final link = api.inviteLinkFrom(name: 'Northwind', kind: PairingParty.exchange, asksInvoices: true);
    final preview = await api.openInvite(link);
    expect((preview.name, preview.kind, preview.asksInvoices), ('Northwind', PairingParty.exchange, true));
    final answered = await api.acceptInvite(token: preview.token, name: 'the owner', allowInvoices: true);
    expect(answered.state, PairingState.pendingReply);
    api.confirmAnswer(answered.id);
    final verified = await api.checkWords(answered.id, PairingCheck.match);
    expect(verified!.allowInvoices, isTrue, reason: 'the user turned it on when answering');
    await expectLater(api.acceptInvite(token: preview.token, name: 'the owner'), _failure(PairingFailure.invalid));
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
    final answered = await api.acceptInvite(token: preview.token, name: 'the owner');
    final invite = await api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1));
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

  test('Allow invoices: only for a verified contact; the allowlist follows it', () async {
    final tom = api.seedPaired(name: 'Tom', state: PairingState.paired, paymentsAddress: 'es${'t' * 50}@relay');
    await expectLater(api.setAllowInvoices(tom.id, true), throwsA(isA<WalletError>()));
    final anna = api.seedPaired(name: 'Anna', paymentsAddress: 'es${'a' * 50}@relay');
    await api.setAllowInvoices(anna.id, true);
    expect(session.allowlist, ['es${'a' * 50}@relay']);
    await api.setAllowInvoices(anna.id, false);
    expect(session.allowlist, isEmpty);
  });

  test('keys changed: the old record stays aside; Keep the old keys brings it back', () async {
    final old = api.seedPaired(name: 'Anna', contactId: 'c1', allowInvoices: true, paymentsAddress: 'es${'a' * 50}@relay');
    final changed = api.changeKeys(old.id);
    expect(changed.state, PairingState.keysChanged);
    expect(changed.contactId, 'c1');
    expect((await api.pairingForContact('c1'))!.id, changed.id);
    expect(session.allowlist, isEmpty, reason: 'nothing parks while the keys are in question');
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
    await api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1));
    final backup = api.exportBackup();
    expect((backup!['records'] as List), hasLength(1), reason: 'pending invites stay behind');
    final other = FakeWalletSession().pairing;
    expect(other.importBackup(backup), 1);
    final restored = (await other.pairing('p1'))!;
    expect((restored.contactId, restored.otherDevice), ('c1', true));
    expect(await other.useImportedPairings(), 1);
    expect((await other.pairing('p1'))!.otherDevice, isFalse);
  });

  test('a core without pairing refuses every call', () async {
    api.enabled = false;
    expect(api.supported, isFalse);
    await expectLater(api.makeInvite(name: 'x', expiry: const Duration(hours: 1)), throwsA(isA<WalletError>()));
    expect(await api.pairings(), isEmpty);
    expect(const NoPairing().supported, isFalse);
  });
}
