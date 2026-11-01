// SPDX-License-Identifier: Apache-2.0
// The fake pairing engine (RFC 0002, pairing v3) the screens, the tour and the web preview
// run on: the standing invite, requests to a contact and their answers, the states a pairing
// goes through (Waiting until heard, Paired, Verified, Ended with its reason), the request
// filter, the mismatch hold, crossed invites, the attach rules, and the backup.
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/trust/policy.dart' show featureStatusNotices;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _failure(PairingFailure f) => throwsA(isA<WalletError>().having(pairingFailureOf, 'failure', f));

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';
final String _tom = 'es${'t' * 50}@epicbox.epiccash.com';

BigInt _epic(int n) => BigInt.from(n) * BigInt.from(100000000);

void main() {
  late FakeWalletSession session;
  late FakePairing api;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 11, 1, 12);
    session = FakeWalletSession();
    api = session.pairing..clock = () => now;
  });

  group('the standing invite', () {
    test('one per wallet, 7 days, never listed; renewed under 24 h left, on a new name, or once used', () async {
      final a = await api.standingCode(name: 'Alex');
      expect(a.state, PairingState.pendingInvite);
      expect(a.expiresAt, now.add(pairingInviteExpiry));
      expect(pairingLinkKind(a.inviteLink!), PairingLinkKind.invite);
      expect(await api.pairings(), isEmpty, reason: 'an unused invite is no row');
      expect((await api.standingCode(name: 'Alex')).id, a.id, reason: 'the same one on every visit');
      now = now.add(const Duration(days: 6, hours: 1));
      expect((await api.standingCode(name: 'Alex')).id, isNot(a.id), reason: 'under 24 h left');
      final b = await api.standingCode(name: 'Alex');
      final c = await api.standingCode(name: 'Alexander');
      expect(c.id, isNot(b.id), reason: 'a new name makes a new invite');
      // The old one was withdrawn: an answer to it is refused as cancelled.
      await expectLater(api.openReply(fakePairingLink('pair-reply', {'t': b.id, 'n': 'Anna'})), _failure(PairingFailure.cancelled));
      api.answerInvite(c.id, name: 'Anna');
      expect(api.standing, isNull, reason: 'used: the next visit makes a fresh one');
      expect((await api.pairings()).single.id, c.id, reason: 'answered, it is a row');
    });

    test('an empty or too long name is refused', () async {
      await expectLater(api.standingCode(name: ' '), throwsA(isA<WalletError>()));
      await expectLater(api.standingCode(name: 'x' * 49), throwsA(isA<WalletError>()));
    });
  });

  group('Way 2, the invite answered', () {
    test('a peer with status notices: Waiting until heard, then Paired; They match verifies', () async {
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final invite = await api.standingCode(name: 'Alex');
      api.answerInvite(invite.id, name: 'Anna');
      await pumpEventQueue();
      expect(events.single.kind, PairingEventKind.replied);
      var r = (await api.pairing(invite.id))!;
      expect(r.state, PairingState.waiting);
      expect(r.sas, hasLength(sasWordCount));
      expect(r.peerHeardAt, isNull);
      expect(r.seals, isFalse, reason: 'nothing is sealed to a wallet not heard yet');
      api.hear(invite.id);
      r = (await api.pairing(invite.id))!;
      expect(r.state, PairingState.paired);
      expect(r.peerHeardAt, now);
      expect(events.last.kind, PairingEventKind.heard);
      final verified = await api.checkWords(invite.id, PairingCheck.match);
      expect(verified!.state, PairingState.verified);
      expect(verified.allowInvoices, isFalse, reason: 'never on unless the user turned it on');
      api.peerMatch(invite.id);
      expect((await api.pairing(invite.id))!.peerVerifiedAt, now, reason: 'Anna confirmed too');
    });

    test('a peer without status notices is paired at the reply', () async {
      final invite = await api.standingCode(name: 'Alex');
      api.answerInvite(invite.id, name: 'Anna', features: 0);
      expect((await api.pairing(invite.id))!.state, PairingState.paired);
    });

    test('They match while Waiting counts as heard and verifies', () async {
      final invite = await api.standingCode(name: 'Alex');
      api.answerInvite(invite.id, name: 'Anna');
      final r = await api.checkWords(invite.id, PairingCheck.match);
      expect((r!.state, r.peerHeardAt), (PairingState.verified, now));
    });

    test('never heard: ended, kept, with its reason', () async {
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final invite = await api.standingCode(name: 'Alex');
      api.answerInvite(invite.id, name: 'Anna');
      api.neverFinished(invite.id);
      await pumpEventQueue();
      final r = (await api.pairing(invite.id))!;
      expect((r.state, r.endedReason), (PairingState.ended, PairingEndReason.neverFinished));
      expect(events.last.kind, PairingEventKind.ended);
      expect(events.last.endedReason, PairingEndReason.neverFinished);
      await expectLater(api.checkWords(invite.id, PairingCheck.match), _failure(PairingFailure.ended));
      await expectLater(api.setSeal(invite.id, true), _failure(PairingFailure.ended));
    });

    test('the other side: the invite read, answered, and confirmed as paired', () async {
      final link = api.inviteLinkFrom(name: 'Northwind', kind: PairingParty.exchange, asksInvoices: true);
      final preview = await api.openInvite(link);
      expect((preview.name, preview.kind, preview.asksInvoices, preview.isRequest), ('Northwind', PairingParty.exchange, true, false));
      final answered = await api.acceptInvite(token: preview.token, name: 'Alex', allowInvoices: true);
      expect(answered.state, PairingState.pendingReply);
      api.confirmAnswer(answered.id);
      final paired = (await api.pairing(answered.id))!;
      expect((paired.state, paired.peerHeardAt), (PairingState.paired, now));
      final verified = await api.checkWords(answered.id, PairingCheck.match);
      expect(verified!.allowInvoices, isTrue, reason: 'the user turned it on when answering');
      await expectLater(api.acceptInvite(token: preview.token, name: 'Alex'), _failure(PairingFailure.invalid));
    });

    test('by hand: the answer opened here always has a confirmation to send back', () async {
      final invite = await api.standingCode(name: 'Alex');
      await expectLater(api.confirmLink(invite.id), throwsA(isA<WalletError>()));
      final r = await api.openReply(fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Anna'}));
      expect(r.state, PairingState.waiting);
      expect(pairingLinkKind(await api.confirmLink(invite.id)), PairingLinkKind.confirm);
      // The same answer again (it came through the relay too) changes nothing.
      expect((await api.openReply(fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Anna'}))).id, invite.id);
    });

    test('an expired invite cannot be opened; a link that is none is invalid; the own one is refused', () async {
      await expectLater(api.openInvite(api.inviteLinkFrom(name: 'Anna', expiresIn: const Duration(minutes: -1))), _failure(PairingFailure.expired));
      await expectLater(api.openInvite('epiccash://pair/1/nonsense'), _failure(PairingFailure.invalid));
      final own = await api.standingCode(name: 'Alex');
      await expectLater(api.openInvite(own.inviteLink!), _failure(PairingFailure.ownCard));
    });

    test('an answer without a confirm for an hour ends; a cancelled answer goes', () async {
      final preview = await api.openInvite(api.inviteLinkFrom(name: 'Anna'));
      final answered = await api.acceptInvite(token: preview.token, name: 'Alex');
      now = now.add(const Duration(hours: 2));
      expect(await api.collect(), 1);
      expect(await api.pairing(answered.id), isNull);
    });
  });

  group('Way 1, a request to a contact', () {
    test('only to a proven peer, never twice, and the answer must come from that address', () async {
      await expectLater(api.requestPairing(toAddress: _anna, name: 'Alex', contactId: 'c1'), _failure(PairingFailure.peerNotProven));
      api.provenPeers.add(_anna);
      final sent = await api.requestPairing(toAddress: _anna, name: 'Alex', contactId: 'c1');
      expect((sent.state, sent.way, sent.expectAddress, sent.contactId), (PairingState.pendingInvite, PairingWay.request, _anna, 'c1'));
      expect(api.standing, isNull, reason: 'a request carries its own invite, never the standing one');
      expect(pairingsInContacts(await api.pairings()).single.id, sent.id, reason: 'a sent request is a row');
      await expectLater(api.requestPairing(toAddress: _anna, name: 'Alex'), _failure(PairingFailure.inProgress));
      // An answer from another wallet stores nothing.
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      expect(api.answerInvite(sent.id, name: 'Mallory', fromAddress: _tom), isNull);
      await pumpEventQueue();
      expect(events.single.failure, PairingFailure.otherWallet);
      expect(await api.pairing(sent.id), isNull);
    });

    test('answered by the expected address: Waiting, then Verified once heard, no words needed', () async {
      api.provenPeers.add(_anna);
      final sent = await api.requestPairing(toAddress: _anna, name: 'Alex', contactId: 'c1');
      api.answerInvite(sent.id, name: 'Anna', fromAddress: _anna);
      var r = (await api.pairing(sent.id))!;
      expect(r.state, PairingState.waiting);
      api.hear(sent.id);
      r = (await api.pairing(sent.id))!;
      expect((r.state, r.paymentsAddress), (PairingState.verified, _anna));
      await expectLater(api.requestPairing(toAddress: _anna, name: 'Alex'), _failure(PairingFailure.alreadyUsed));
    });

    test('Epicbox off or a failed post: nothing stored', () async {
      api.provenPeers.add(_anna);
      api.epicboxOff = true;
      await expectLater(api.requestPairing(toAddress: _anna, name: 'Alex'), _failure(PairingFailure.relayUnreachable));
      api.epicboxOff = false;
      api.relayUnreachable = true;
      await expectLater(api.requestPairing(toAddress: _anna, name: 'Alex'), throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.transportFailed)));
      expect(await api.pairings(), isEmpty);
    });

    test('the receiving side: a request is stored, one per sender, newer replaces, dismissed hides until a newer one', () async {
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final first = api.receiveRequest(from: _anna, name: 'Anna')!;
      await pumpEventQueue();
      expect((events.single.kind, events.single.requestId, events.single.sender), (PairingEventKind.requested, first.id, _anna));
      expect(api.receiveRequest(from: _anna, name: 'Anna', expiresIn: const Duration(days: 6)), isNull, reason: 'not newer');
      await api.dismissRequest(first.id);
      expect(await api.requests(), isEmpty);
      now = now.add(const Duration(hours: 1));
      final newer = api.receiveRequest(from: _anna, name: 'Anna')!;
      expect((await api.requests()).single.id, newer.id, reason: 'a newer request shows again');
      // Accepting a dismissed copy (forwarded by the other device) is refused.
      final dismissed = await api.openInvite(first.inviteLink);
      await expectLater(api.acceptInvite(token: dismissed.token, name: 'Alex'), _failure(PairingFailure.inviteDismissed));
    });

    test('the app shows requests from contacts only', () {
      final a = api.receiveRequest(from: _anna, name: 'Anna')!;
      api.receiveRequest(from: _tom, name: 'Tom');
      final shown = requestsFromContacts(api.requestList, {epicboxKey(_anna)});
      expect(shown.map((r) => r.id), [a.id]);
    });

    test('a request answered on the linked device: hidden here, with the device named', () async {
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final q = api.receiveRequest(from: _anna, name: 'Anna')!;
      await api.requestHandledOn(q.id, 'Desktop');
      await pumpEventQueue();
      expect(await api.requests(), isEmpty);
      expect((events.last.kind, events.last.name, events.last.requestId), (PairingEventKind.pairedElsewhere, 'Desktop', q.id));
    });

    test('answering a request: the preview carries the sender, the answer expects it, both verified at the confirm', () async {
      final q = api.receiveRequest(from: _anna, name: 'Anna')!;
      final preview = await api.openRequest(q.id);
      expect((preview.fromAddress, preview.requestId, preview.isRequest), (_anna, q.id, true));
      final answered = await api.acceptInvite(token: preview.token, name: 'Alex', contactId: 'c1');
      expect((answered.expectAddress, answered.way), (_anna, PairingWay.request));
      expect(await api.requests(), isEmpty, reason: 'answered, no longer listed');
      api.confirmAnswer(answered.id);
      final r = (await api.pairing(answered.id))!;
      expect((r.state, r.paymentsAddress), (PairingState.verified, _anna));
    });

    test('a request from a key with a live pairing is dropped', () async {
      api.seedPaired(name: 'Anna', paymentsAddress: _anna);
      expect(api.receiveRequest(from: _anna, name: 'Anna'), isNull);
    });
  });

  group('crossed invites', () {
    test('the wallet with the lower key keeps its own; the other answers and withdraws', () async {
      api.provenPeers.add(_anna);
      final own = await api.requestPairing(toAddress: _anna, name: 'Alex', contactId: 'c1');
      final theirs = await api.openInvite(api.inviteLinkFrom(name: 'Anna', from: _anna));
      // This wallet's key is the lower one: its own request wins, the answer is refused.
      api.ownAddress = 'es${'1' * 50}@epicbox.epiccash.com';
      await expectLater(api.acceptInvite(token: theirs.token, name: 'Alex'), _failure(PairingFailure.crossed));
      expect(await api.pairing(own.id), isNotNull);
      // The higher key: the answer goes ahead and the own request is withdrawn.
      api.ownAddress = 'es${'z' * 50}@epicbox.epiccash.com';
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final answered = await api.acceptInvite(token: theirs.token, name: 'Alex');
      await pumpEventQueue();
      expect(answered.state, PairingState.pendingReply);
      expect(await api.pairing(own.id), isNull);
      expect(events.single.failure, PairingFailure.crossed);
    });
  });

  group('They do not match', () {
    test('ends on this side, kept, and holds a sealed send waiting in that mailbox', () async {
      session.summaryValue = WalletSummary(lastConfirmedHeight: BigInt.from(10), minimumConfirmations: BigInt.one, total: _epic(100), spendable: _epic(100), awaitingConfirmation: BigInt.zero, awaitingFinalization: BigInt.zero, immature: BigInt.zero, locked: BigInt.zero, validatedWithNode: true);
      final anna = api.seedPaired(name: 'Anna', state: PairingState.paired, paymentsAddress: _anna, contactId: 'c1');
      final sent = await api.sendViaMailbox(id: anna.id, amount: _epic(25), minimumConfirmations: BigInt.one);
      expect(sent.status, TxStatus.awaitingRecipient);
      final ended = await api.checkWords(anna.id, PairingCheck.mismatch);
      expect((ended!.state, ended.endedReason), (PairingState.ended, PairingEndReason.mismatch));
      expect(await api.pairing(anna.id), isNotNull, reason: 'kept, not deleted');
      // The send is still there, cancellable, never finalized through that mailbox.
      final held = session.transactionsValue.where((t) => t.pairingId == anna.id || t.slateId == sent.slateId).single;
      expect((held.status, held.cancellable), (TxStatus.awaitingRecipient, true));
      final sealed = await api.sealSlate(id: api.seedPaired(name: 'Other').id, slateJson: '{"id":"${sent.slateId}"}');
      expect(sealed, isNotEmpty);
      await expectLater(api.sendViaMailbox(id: anna.id, amount: BigInt.one, minimumConfirmations: BigInt.one), _failure(PairingFailure.ended));
      await expectLater(api.sealSlate(id: anna.id, slateJson: '{}'), _failure(PairingFailure.ended));
    });

    test('the peer reported it: ended with that reason, invoices dropped, Allow invoices off', () async {
      final anna = api.seedPaired(name: 'Anna', paymentsAddress: _anna, allowInvoices: true);
      session.relayInvoice(from: _anna, slateId: 'i1', amount: BigInt.one);
      expect((await session.collectInvoices()).parked, 1);
      final events = <PairingEvent>[];
      api.events().listen(events.add);
      final r = api.peerMismatch(anna.id);
      await pumpEventQueue();
      expect((r.state, r.endedReason, r.allowInvoices), (PairingState.ended, PairingEndReason.peerMismatch, false));
      expect(session.pendingInvoicesValue, isEmpty);
      expect(events.single.kind, PairingEventKind.ended);
    });

    test('the other side removed it: ended as unpaired, removedByPeer reads it', () async {
      final anna = api.seedPaired(name: 'Anna');
      api.removedByPeer(anna.id);
      final r = (await api.pairing(anna.id))!;
      expect((r.state, r.endedReason, r.removedByPeer), (PairingState.ended, PairingEndReason.unpaired, true));
    });
  });

  group('sends and invoices by state', () {
    test('Waiting refuses a sealed send, an invoice and Allow invoices; Paired allows the send', () async {
      final invite = await api.standingCode(name: 'Alex');
      api.answerInvite(invite.id, name: 'Anna');
      await expectLater(api.sealSlate(id: invite.id, slateJson: '{}'), _failure(PairingFailure.waiting));
      await expectLater(api.sendViaMailbox(id: invite.id, amount: BigInt.one, minimumConfirmations: BigInt.one), _failure(PairingFailure.waiting));
      await expectLater(api.setAllowInvoices(invite.id, true), _failure(PairingFailure.waiting));
      api.hear(invite.id);
      expect((await api.pairing(invite.id))!.paysByMailbox, isTrue);
    });

    test('Allow invoices: only for a verified contact; requests park only while it is on', () async {
      final tom = api.seedPaired(name: 'Tom', state: PairingState.paired, paymentsAddress: _tom);
      await expectLater(api.setAllowInvoices(tom.id, true), throwsA(isA<WalletError>()));
      final anna = api.seedPaired(name: 'Anna', paymentsAddress: _anna);
      Future<int> parked(String slateId) async {
        session.relayInvoice(from: _anna, slateId: slateId, amount: BigInt.one);
        return (await session.collectInvoices()).parked;
      }

      expect(await parked('i0'), 0);
      await api.setAllowInvoices(anna.id, true);
      expect(await parked('i1'), 1);
      await api.setAllowInvoices(anna.id, false);
      expect(await parked('i2'), 0);
    });
  });

  group('attach', () {
    test('a contact with no address takes any pairing; one with the proven address too', () async {
      await session.saveContact(contact: Contact(id: 'c1', name: 'Anna'));
      await session.saveContact(contact: Contact(id: 'c2', name: 'Anna B', address: _anna));
      final r = api.seedPaired(name: 'Anna', paymentsAddress: _anna);
      expect((await api.attach(r.id, 'c1', contactAddress: null)).contactId, 'c1');
      expect((await api.attach(r.id, 'c2', contactAddress: _anna)).contactId, 'c2');
    });

    test('another key is refused; no proof yet is refused as missing', () async {
      final proven = api.seedPaired(name: 'Anna', paymentsAddress: _anna);
      await expectLater(api.attach(proven.id, 'c3', contactAddress: _tom), _failure(PairingFailure.otherAddress));
      final unproven = api.seedPaired(name: 'Old', paymentsAddress: null);
      final r = (await api.pairing(unproven.id))!.copyWith();
      api.seed(PairingRecord(id: 'np', state: PairingState.paired, way: PairingWay.link, inviter: false, createdAt: now, name: 'Old', peerHeardAt: now));
      await expectLater(api.attach('np', 'c3', contactAddress: _tom), _failure(PairingFailure.addressProofMissing));
      expect(r.id, unproven.id);
    });
  });

  test('keys changed: the old record stays aside; Keep the old keys brings it back', () async {
    final old = api.seedPaired(name: 'Anna', contactId: 'c1', allowInvoices: true, paymentsAddress: _anna);
    final changed = api.changeKeys(old.id);
    expect(changed.state, PairingState.keysChanged);
    expect((await api.pairingForContact('c1'))!.id, changed.id);
    final back = await api.resolveKeysChanged(changed.id, KeysChoice.keepOld);
    expect((back.id, back.state, back.allowInvoices), (old.id, PairingState.verified, true));
    expect(await api.pairing(changed.id), isNull);
  });

  test('the backup carries paired records only: never a pending, waiting or ended one', () async {
    api.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1', peerVerifiedAt: now);
    api.seedPaired(id: 'p2', name: 'Waiting', state: PairingState.waiting);
    api.seedPaired(id: 'p3', name: 'Gone', state: PairingState.ended);
    api.provenPeers.add(_tom);
    await api.requestPairing(toAddress: _tom, name: 'Alex');
    final backup = api.exportBackup();
    expect((backup!['records'] as List).map((r) => (r as Map)['id']), ['p1']);
    final other = FakeWalletSession().pairing;
    expect(other.importBackup(backup), 1);
    final restored = (await other.pairing('p1'))!;
    expect((restored.contactId, restored.otherDevice, restored.peerVerifiedAt, restored.peerFeatures), ('c1', true, now, featureStatusNotices));
    expect(restored.peerHeardAt, isNotNull);
  });

  group('which pairing a contact uses', () {
    PairingRecord rec(String id, {required DateTime created, DateTime? heard, PairingState state = PairingState.verified, bool checking = false, String? contact = 'anna', PairingEndReason? ended}) =>
        PairingRecord(id: id, state: state, way: PairingWay.link, inviter: false, createdAt: created, lastSealedIn: heard ?? created, contactId: contact, checksKeys: checking, endedReason: ended);
    final t0 = DateTime(2026, 10, 25, 5);

    test('of three attached, the one heard from last, not a newer one never heard from', () {
      final all = [
        rec('re-pair-2', created: t0.add(const Duration(hours: 4))),
        rec('re-pair-1', created: t0.add(const Duration(hours: 3)), heard: t0.add(const Duration(hours: 5))),
        rec('first', created: t0, heard: t0.add(const Duration(minutes: 10))),
        rec('other', created: t0.add(const Duration(hours: 6)), contact: 'ben'),
      ];
      expect(contactPairingOf(all, 'anna')?.id, 're-pair-1');
      expect(contactPairingOf(all, 'ben')?.id, 'other');
      expect(contactPairingOf(all, 'nobody'), isNull);
    });

    test('keys changed first; waiting only while nothing paired is; an ended one only when nothing else is', () {
      final old = rec('old', created: t0);
      final changed = rec('changed', created: t0.add(const Duration(hours: 1)), state: PairingState.keysChanged);
      expect(contactPairingOf([old, changed], 'anna')?.id, 'changed');
      expect(contactPairingOf([rec('waiting', created: t0, state: PairingState.waiting)], 'anna')?.id, 'waiting');
      expect(contactPairingOf([rec('waiting', created: t0.add(const Duration(hours: 2)), state: PairingState.waiting), old], 'anna')?.id, 'old');
      final dead = rec('dead', created: t0, state: PairingState.ended, ended: PairingEndReason.peerMismatch);
      expect(contactPairingOf([dead, old], 'anna')?.id, 'old');
      expect(contactPairingOf([dead], 'anna')?.id, 'dead');
      expect(dead.paysByMailbox, isFalse);
    });
  });

  test('a core without pairing refuses every call', () async {
    api.enabled = false;
    expect(api.supported, isFalse);
    await expectLater(api.standingCode(name: 'x'), throwsA(isA<WalletError>()));
    expect(await api.pairings(), isEmpty);
    expect(await api.requests(), isEmpty);
    expect(const NoPairing().supported, isFalse);
  });
}
