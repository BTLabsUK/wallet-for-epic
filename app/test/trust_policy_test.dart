import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.utc(2026, 11, 1, 12);
DateTime ago(Duration d) => now.subtract(d);
const day = Duration(days: 1);

PeerCompat compat({
  Duration? marked,
  Duration? unmarked,
  int claimed = featureMarker,
}) => PeerCompat(
  lastMarkedAt: marked == null ? null : ago(marked),
  lastUnmarkedAt: unmarked == null ? null : ago(unmarked),
  claimed: claimed,
);

const contact = Relationship(RelationshipKind.contact);
const paired = Relationship(RelationshipKind.paired, hasEpicboxAddress: true);
const verified = Relationship(
  RelationshipKind.verified,
  hasEpicboxAddress: true,
);

void main() {
  group('plain notice (posted, cancelled, withdrawn, declined)', () {
    final cases = <(String, PeerCompat?, bool, bool)>[
      ('marked 1 d, exchange marked', compat(marked: day), true, true),
      ('marked 30 d, exchange marked', compat(marked: day * 30), true, true),
      ('marked 31 d', compat(marked: day * 31), true, false),
      ('exchange not marked', compat(marked: day), false, false),
      (
        'unmarked after marked (twin)',
        compat(marked: day * 2, unmarked: day),
        true,
        false,
      ),
      (
        'marked after unmarked',
        compat(marked: day, unmarked: day * 2),
        true,
        true,
      ),
      ('never marked', compat(unmarked: day), true, false),
      ('unknown key', null, true, false),
    ];
    for (final (name, c, marked, want) in cases) {
      test(name, () {
        expect(mayNotifyPlain(c, now, exchangeMarked: marked), want);
      });
    }
  });

  group('pair request / offer Pair', () {
    final allBits = featureMarker | featurePairRequests;
    final cases = <(String, PeerCompat?, Relationship, bool)>[
      (
        'fresh, bit 1, contact',
        compat(marked: day, claimed: allBits),
        contact,
        true,
      ),
      (
        'fresh, bit 1, ended',
        compat(marked: day, claimed: allBits),
        const Relationship(
          RelationshipKind.ended,
          endedReason: EndedReason.cancelled,
        ),
        true,
      ),
      ('no bit 1', compat(marked: day, claimed: featureMarker), contact, false),
      (
        'bit 3 only',
        compat(marked: day, claimed: featureStatusNotices),
        contact,
        false,
      ),
      (
        'older than 30 d',
        compat(marked: day * 31, claimed: allBits),
        contact,
        false,
      ),
      (
        'unmarked within 30 d',
        compat(marked: day, unmarked: day * 40, claimed: allBits),
        contact,
        true,
      ),
      (
        'unmarked older than marked but within 30 d',
        compat(marked: day, unmarked: day * 5, claimed: allBits),
        contact,
        false,
      ),
      ('paired', compat(marked: day, claimed: allBits), paired, false),
      (
        'not a contact',
        compat(marked: day, claimed: allBits),
        const Relationship.none(),
        false,
      ),
      ('unknown key', null, contact, false),
    ];
    for (final (name, c, r, want) in cases) {
      test(name, () => expect(mayPairRequest(c, r, now), want));
    }
    test('offer Pair only for a plain contact', () {
      final c = compat(marked: day, claimed: allBits);
      expect(mayOfferPair(c, contact, now), isTrue);
      expect(
        mayOfferPair(c, const Relationship(RelationshipKind.ended), now),
        isFalse,
      );
    });
  });

  group('name service bit', () {
    test('name service bit 5 and paired', () {
      expect(mayNameServicePayload(featureNameService, paired), isTrue);
      expect(mayNameServicePayload(featureNameService, verified), isTrue);
      expect(mayNameServicePayload(featureNameService, contact), isFalse);
      expect(mayNameServicePayload(featureLinkedDevicesReserved, paired), isFalse);
    });
  });

  group('card profile', () {
    test('bit 0 is no payments, bit 1 automated', () {
      expect(profileNoPayments, 1);
      expect(profileAutomated, 2);
      expect(statedNoPayments(0), isFalse);
      expect(statedNoPayments(profileNoPayments), isTrue);
      expect(statedNoPayments(profileAutomated), isFalse);
      expect(statedAutomated(profileAutomated), isTrue);
      expect(statedAutomated(profileNoPayments), isFalse);
      expect(statedNoPayments(profileNoPayments | profileAutomated) && statedAutomated(profileNoPayments | profileAutomated), isTrue);
    });

    test('unknown bits are ignored', () {
      const unknown = 0xFFFFFFFC;
      expect(statedNoPayments(unknown), isFalse);
      expect(statedAutomated(unknown), isFalse);
      expect(statedNoPayments(unknown | profileNoPayments), isTrue);
      expect(statedAutomated(unknown | profileAutomated), isTrue);
    });

    test('the relationship carries the word as given', () {
      const r = Relationship(RelationshipKind.paired, peerProfile: 0x80000001);
      expect(r.peerProfile, 0x80000001);
      expect(statedNoPayments(r.peerProfile), isTrue);
      expect(const Relationship.none().peerProfile, 0);
    });
  });

  group('contact line', () {
    final cases =
        <(String, PeerCompat?, Relationship, DateTime?, ContactLineKind)>[
          (
            'answered by another app',
            compat(marked: day * 5, unmarked: day),
            paired,
            null,
            ContactLineKind.answeredByOtherApp,
          ),
          (
            'answered, plain contact',
            compat(unmarked: day),
            contact,
            null,
            ContactLineKind.answeredByOtherApp,
          ),
          (
            'answered, not a contact',
            compat(unmarked: day),
            const Relationship.none(),
            null,
            ContactLineKind.none,
          ),
          (
            'answered, ended',
            compat(unmarked: day),
            const Relationship(RelationshipKind.ended),
            null,
            ContactLineKind.none,
          ),
          (
            'marked after unmarked: line gone',
            compat(marked: day, unmarked: day * 5),
            paired,
            null,
            ContactLineKind.none,
          ),
          (
            'not heard 91 d',
            compat(marked: day * 91),
            paired,
            null,
            ContactLineKind.notHeardSince,
          ),
          (
            'heard 89 d',
            compat(marked: day * 89),
            verified,
            null,
            ContactLineKind.none,
          ),
          (
            'sealed envelope keeps her heard',
            compat(marked: day * 200),
            paired,
            ago(day * 10),
            ContactLineKind.none,
          ),
          (
            'not heard, plain contact',
            compat(marked: day * 200),
            contact,
            null,
            ContactLineKind.none,
          ),
          ('no dates at all', null, paired, null, ContactLineKind.none),
          (
            'answered wins over not heard',
            compat(marked: day * 200, unmarked: day),
            paired,
            null,
            ContactLineKind.answeredByOtherApp,
          ),
        ];
    for (final (name, c, r, sealed, want) in cases) {
      test(name, () {
        final line = contactLine(c, r, now, lastSealedIn: sealed);
        expect(line.kind, want);
      });
    }
    test('an automated peer shows no line, not even Not heard from', () {
      const service = Relationship(RelationshipKind.paired, peerProfile: profileAutomated);
      expect(contactLine(compat(marked: day * 200), service, now).kind, ContactLineKind.none);
      expect(contactLine(compat(marked: day * 200, unmarked: day), service, now).kind, ContactLineKind.none);
    });
    test('not heard carries the latest date', () {
      final line = contactLine(
        compat(marked: day * 200),
        paired,
        now,
        lastSealedIn: ago(day * 100),
      );
      expect(line.since, ago(day * 100));
    });
  });

  group('Cancel and send to their public Epicbox address', () {
    final cases = <(String, Relationship, Duration, bool)>[
      ('23 h', paired, const Duration(hours: 23), false),
      ('24 h paired', paired, const Duration(hours: 24), true),
      ('24 h verified', verified, const Duration(hours: 24), true),
      ('7 d paired', paired, day * 7, true),
      (
        'no Epicbox address',
        const Relationship(RelationshipKind.paired),
        day * 2,
        false,
      ),
      (
        'plain contact',
        const Relationship(RelationshipKind.contact, hasEpicboxAddress: true),
        day * 2,
        false,
      ),
      (
        'ended',
        const Relationship(RelationshipKind.ended, hasEpicboxAddress: true),
        day * 2,
        false,
      ),
    ];
    for (final (name, r, age, want) in cases) {
      test(
        name,
        () => expect(mayCancelAndSendByEpicbox(r, ago(age), now), want),
      );
    }
    test('stages', () {
      expect(
        mailboxSendStage(ago(const Duration(hours: 1)), now),
        MailboxSendStage.waiting,
      );
      expect(mailboxSendStage(ago(day * 2), now), MailboxSendStage.notAnswered);
      expect(
        mailboxSendStage(ago(day * 7), now),
        MailboxSendStage.neverPickedUp,
      );
    });
  });

  group('mailbox default', () {
    MailboxDefault rule({
      Relationship r = paired,
      bool opensSealed = true,
      bool online = true,
      PeerCompat? c,
      DateTime? lastSealedIn,
      DateTime? unansweredSince,
      bool notAnswering = false,
      bool relayDown = false,
      bool relayShared = false,
    }) => mailboxDefault(
      r: r,
      opensSealed: opensSealed,
      online: online,
      compat: c,
      now: now,
      lastSealedIn: lastSealedIn,
      unansweredSince: unansweredSince,
      notAnswering: notAnswering,
      relayDown: relayDown,
      relayShared: relayShared,
    );

    TxEntry send(Duration age, {TxStatus status = TxStatus.awaitingRecipient, String pairing = 'p1', TxKind kind = TxKind.sent}) => fakeTx(
      id: 1,
      slateId: 's',
      kind: kind,
      status: status,
      createdAtUnix: ago(age).millisecondsSinceEpoch ~/ 1000,
      pairingId: pairing,
    );

    test('paired, opens sealed, online → on', () {
      final d = rule(c: compat(marked: day));
      expect(d.offered, isTrue);
      expect(d.on, isTrue);
      expect(d.reason, PlainReason.none);
      expect(rule(r: verified).on, isTrue);
    });
    test('keys changed, ended, contact-only, waiting → hidden', () {
      for (final r in const [
        Relationship(RelationshipKind.keysChanged),
        Relationship(RelationshipKind.ended, endedReason: EndedReason.unpaired),
        contact,
        Relationship(RelationshipKind.contact, waiting: true),
        Relationship.none(),
      ]) {
        expect(rule(r: r).offered, isFalse, reason: r.kind.name);
      }
    });
    test('opensSealed false → hidden', () => expect(rule(opensSealed: false).offered, isFalse));
    test('online false → hidden', () => expect(rule(online: false).offered, isFalse));
    test('answered by another app → off(otherApp)', () {
      final d = rule(c: compat(marked: day * 2, unmarked: day), unansweredSince: ago(day * 2));
      expect(d.offered, isTrue);
      expect(d.reason, PlainReason.otherApp);
      expect(d.on, isFalse);
      final both = rule(c: compat(marked: day * 100, unmarked: day), lastSealedIn: ago(day * 100));
      expect(both.reason, PlainReason.otherApp);
    });
    test('not heard 91 days → off(notHeard, since: latest)', () {
      final d = rule(c: compat(marked: day * 95), lastSealedIn: ago(day * 91), unansweredSince: ago(day * 2));
      expect(d.reason, PlainReason.notHeard);
      expect(d.since, ago(day * 91));
    });
    test('unanswered send turns the default off', () {
      final since = ago(const Duration(hours: 25));
      final d = rule(c: compat(marked: day), unansweredSince: since);
      expect(d.reason, PlainReason.unanswered);
      expect(d.since, since);
      expect(d.on, isFalse);
    });
    test('notAnswering → off(notAnswering)', () => expect(rule(notAnswering: true).reason, PlainReason.notAnswering));
    test('relayDown → off(relayDown)', () {
      expect(rule(relayDown: true).reason, PlainReason.relayDown);
      expect(rule(relayDown: true).serverDown, isFalse);
      expect(rule(relayDown: true, notAnswering: true).reason, PlainReason.notAnswering);
    });
    test('relayDown on a shared server → on, serverDown', () {
      final d = rule(relayDown: true, relayShared: true);
      expect(d.on, isTrue);
      expect(d.reason, PlainReason.none);
      expect(d.serverDown, isTrue);
      expect(rule(relayShared: true).serverDown, isFalse);
      // The earlier reasons still win: the shared server only matters at the relay step.
      expect(rule(relayDown: true, relayShared: true, notAnswering: true).reason, PlainReason.notAnswering);
    });
    test('epicboxServer: host alone, port and case dropped', () {
      expect(epicboxServer('esYb3k@Epicbox.Example.org:443'), 'epicbox.example.org');
      expect(epicboxServer('epicbox.example.org:443'), 'epicbox.example.org');
      expect(epicboxServer(''), '');
      expect(sameEpicboxServer('k@epicbox.example.org', 'epicbox.example.org:443'), isTrue);
      expect(sameEpicboxServer('k@box.example.org', 'epicbox.example.org'), isFalse);
      expect(sameEpicboxServer(null, 'epicbox.example.org'), isFalse);
      expect(sameEpicboxServer('k@epicbox.example.org', ''), isFalse);
    });
    test('mailboxUnansweredSince: 25 h old counts, 23 h old does not', () {
      final old = send(const Duration(hours: 25));
      expect(mailboxUnansweredSince([old], 'p1', null, now), ago(const Duration(hours: 25)));
      expect(mailboxUnansweredSince([send(const Duration(hours: 23))], 'p1', null, now), isNull);
      expect(mailboxUnansweredSince([send(const Duration(hours: 30)), old], 'p1', null, now), ago(const Duration(hours: 30)));
    });
    test('sealed message after the send clears it', () {
      final t = [send(const Duration(hours: 25))];
      expect(mailboxUnansweredSince(t, 'p1', ago(const Duration(hours: 1)), now), isNull);
      expect(mailboxUnansweredSince(t, 'p1', ago(const Duration(hours: 26)), now), isNotNull);
    });
    test('cancelled sends are not unanswered', () {
      for (final s in [TxStatus.cancelled, TxStatus.confirmed, TxStatus.awaitingConfirmation]) {
        expect(mailboxUnansweredSince([send(day * 2, status: s)], 'p1', null, now), isNull, reason: s.name);
      }
      expect(mailboxUnansweredSince([send(day * 2, kind: TxKind.sentCancelled)], 'p1', null, now), isNull);
    });
    test('another pairing id → null', () {
      expect(mailboxUnansweredSince([send(day * 2, pairing: 'p2')], 'p1', null, now), isNull);
    });
  });

  group('downgrade of proven', () {
    test('proven, then an unmarked slate', () {
      final before = compat(marked: day * 2);
      expect(isProven(before, now), isTrue);
      final after = compat(marked: day * 2, unmarked: day);
      expect(isProven(after, now), isFalse);
      expect(isFresh(after, now), isFalse);
      MailboxDefault route(PeerCompat c, Relationship r, {DateTime? sealed}) =>
          mailboxDefault(r: r, opensSealed: true, online: true, compat: c, now: now, lastSealedIn: sealed);
      expect(route(after, paired).on, isFalse);
      expect(route(before, paired, sealed: now).on, isTrue);
      expect(route(before, contact).offered, isFalse);
      // Not heard from for over 90 days: the default is off.
      expect(route(compat(marked: day * 100), paired, sealed: now.subtract(day * 100)).on, isFalse);
    });
    test('recovery by a newer marked slate', () {
      expect(isProven(compat(marked: day, unmarked: day * 2), now), isTrue);
    });
    test('proven but not fresh until the twin window passes', () {
      final c = compat(marked: day, unmarked: day * 10);
      expect(isProven(c, now), isTrue);
      expect(isFresh(c, now), isFalse);
      expect(isFresh(compat(marked: day, unmarked: day * 31), now), isTrue);
    });
    test('a migrated old row is LEPIC but not proven', () {
      expect(isProven(compat(marked: day * 60), now), isFalse);
      expect(isLepicKey(compat(marked: day * 60)), isTrue);
    });
  });

  test('fake service returns the peer compat it holds', () async {
    final svc = FakeWalletService();
    expect(await svc.peerCompat('a@relay'), isNull);
    svc.peerCompats['a@relay'] = compat(marked: day);
    expect((await svc.peerCompat('a@relay'))?.lastMarkedAt, ago(day));
  });
}
