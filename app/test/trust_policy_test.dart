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

  group('show an incoming pair request', () {
    for (final (name, r, want) in <(String, Relationship, bool)>[
      ('non-contact', const Relationship.none(), false),
      ('contact', contact, true),
      ('paired', paired, true),
      ('ended', const Relationship(RelationshipKind.ended), true),
    ]) {
      test(name, () => expect(mayShowPairRequest(r), want));
    }
  });

  group('status notices and wait until heard', () {
    for (final (name, r, notices, wait) in <(String, Relationship, bool, bool)>[
      (
        'paired with bit 3',
        const Relationship(
          RelationshipKind.paired,
          peerFeatures: featureStatusNotices,
        ),
        true,
        false,
      ),
      (
        'verified with bit 3',
        const Relationship(
          RelationshipKind.verified,
          peerFeatures: featureStatusNotices,
        ),
        true,
        false,
      ),
      (
        'waiting with bit 3',
        const Relationship(
          RelationshipKind.contact,
          waiting: true,
          peerFeatures: featureStatusNotices,
        ),
        true,
        true,
      ),
      (
        'waiting without bit 3',
        const Relationship(
          RelationshipKind.contact,
          waiting: true,
          peerFeatures: featurePairRequests,
        ),
        false,
        false,
      ),
      (
        'paired without bit 3',
        const Relationship(RelationshipKind.paired),
        false,
        false,
      ),
      (
        'plain contact with bit 3',
        const Relationship(
          RelationshipKind.contact,
          peerFeatures: featureStatusNotices,
        ),
        false,
        false,
      ),
      (
        'ended with bit 3',
        const Relationship(
          RelationshipKind.ended,
          peerFeatures: featureStatusNotices,
        ),
        false,
        false,
      ),
    ]) {
      test(name, () {
        expect(mayStatusNotices(r), notices);
        expect(mayWaitUntilHeard(r), wait);
      });
    }
  });

  group('linked device and directory bits', () {
    test('device bit 4', () {
      expect(mayForwardToDevice(featureLinkedDevices | featureMarker), isTrue);
      expect(mayForwardToDevice(featureMarker | featureDirectory), isFalse);
    });
    test('directory bit 5 and paired', () {
      expect(mayDirectoryPayload(featureDirectory, paired), isTrue);
      expect(mayDirectoryPayload(featureDirectory, verified), isTrue);
      expect(mayDirectoryPayload(featureDirectory, contact), isFalse);
      expect(mayDirectoryPayload(featureLinkedDevices, paired), isFalse);
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

  group('Cancel and send by Epicbox', () {
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

  group('downgrade of proven', () {
    test('proven, then an unmarked slate', () {
      final before = compat(marked: day * 2);
      expect(isProven(before, now), isTrue);
      final after = compat(marked: day * 2, unmarked: day);
      expect(isProven(after, now), isFalse);
      expect(isFresh(after, now), isFalse);
      expect(mayOfferMailboxRoute(after, paired), isFalse);
      expect(mayOfferMailboxRoute(before, paired), isTrue);
      expect(mayOfferMailboxRoute(before, contact), isFalse);
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
