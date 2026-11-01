/// The app's trust policy: which conveniences may be sent to or shown for a peer.
///
/// Two axes, never one scale. [PeerCompat] is what the wallet software behind an Epicbox key has
/// shown it can do (learned by LEPIC from messages the user's own actions caused).
/// [Relationship] is what the user has with a contact. Every function here takes both facts it
/// needs and a clock, so it is pure.
///
/// Bits never relax a security check: a feature bit only decides whether a convenience is sent
/// to a wallet. Signatures, the address proof, the four words and sealed envelopes are checked
/// elsewhere and are never skipped because of anything in this file.
library;

/// Feature registry (u32, only grows). Values are masks, not bit numbers.
const int featureMarker = 1 << 0;
const int featurePairRequests = 1 << 1;
const int featureAddressProof = 1 << 2;
const int featureStatusNotices = 1 << 3;
/// Bit 4 (linked-device forwarding) is reserved and never claimed: both linked devices run the
/// same release, so forwarding needs no capability check.
const int featureLinkedDevicesReserved = 1 << 4;
const int featureDirectory = 1 << 5;

/// The host bits (4 and 5) this build claims to other LEPIC wallets: one constant of the build,
/// the same for every user, never a setting (LEPIC's `WalletConfig.host_features`). Bit 4 stays
/// unclaimed (above) and the directory is not in this release, so none.
const int appHostFeatures = 0;

/// A key counts as LEPIC for payments-address traffic only while its last marked message is
/// this young; an unasked send also needs no unmarked message this young.
const Duration compatWindow = Duration(days: 30);

/// A mailbox send with no answer for this long offers "Cancel and send by Epicbox".
const Duration mailboxUnansweredAfter = Duration(hours: 24);

/// At this age an unanswered mailbox send is gone from the relay; Cancel becomes the main action.
const Duration mailboxGoneAfter = Duration(days: 7);

/// A paired contact not heard from for this long shows "Not heard from … since".
const Duration notHeardAfter = Duration(days: 90);

/// What LEPIC knows about one Epicbox key (LEPIC's `peer_compat`).
class PeerCompat {
  const PeerCompat({
    this.lastMarkedAt,
    this.lastUnmarkedAt,
    this.claimed = 0,
    this.works = 0,
    this.featuresAt,
  });

  /// Last authenticated message from the key that carried the marker, or an accepted notice.
  final DateTime? lastMarkedAt;

  /// Last Epicbox slate from the key without the marker.
  final DateTime? lastUnmarkedAt;

  /// The `f` of the latest marked message (1 for a marker without `f`).
  final int claimed;

  /// Bits that actually worked with this key.
  final int works;

  /// When [claimed] was last written; null means an older build that never sent `f`.
  final DateTime? featuresAt;

  bool claims(int feature) => claimed & feature == feature;
  bool worked(int feature) => works & feature == feature;
}

enum RelationshipKind { none, contact, paired, verified, keysChanged, ended }

enum EndedReason { mismatch, cancelled, unpaired, expired, notHeard }

/// What the user has with a contact, derived by the app from its address book and the pairing.
class Relationship {
  const Relationship(
    this.kind, {
    this.waiting = false,
    this.endedReason,
    this.hasEpicboxAddress = false,
    this.peerFeatures = 0,
  });

  const Relationship.none() : this(RelationshipKind.none);

  final RelationshipKind kind;

  /// A pairing that was started and is not answered yet (a sub-state of [RelationshipKind.contact]).
  final bool waiting;

  /// Only for [RelationshipKind.ended].
  final EndedReason? endedReason;

  /// The contact has an Epicbox address (proven, or from the address book).
  final bool hasEpicboxAddress;

  /// The peer's `0x82` kept in the pairing record (0 for a record without one).
  final int peerFeatures;

  bool get inContacts => kind != RelationshipKind.none;
  bool get isPaired =>
      kind == RelationshipKind.paired || kind == RelationshipKind.verified;
  bool get isContactOnly => kind == RelationshipKind.contact;
}

/// The contact line the page shows, if any.
enum ContactLineKind { none, answeredByOtherApp, notHeardSince }

class ContactLine {
  const ContactLine(this.kind, [this.since]);
  const ContactLine.none() : this(ContactLineKind.none);

  final ContactLineKind kind;

  /// The date for [ContactLineKind.notHeardSince].
  final DateTime? since;
}

/// Where an unanswered mailbox send stands.
enum MailboxSendStage { waiting, notAnswered, neverPickedUp }

bool _within(DateTime? at, Duration window, DateTime now) =>
    at != null && now.difference(at) <= window;

/// LEPIC by the stored dates: the last marked message is newer than the last unmarked one.
bool isLepicKey(PeerCompat? c) {
  final marked = c?.lastMarkedAt;
  if (marked == null) return false;
  final unmarked = c!.lastUnmarkedAt;
  return unmarked == null || marked.isAfter(unmarked);
}

/// "Proven" for anything sent to the key's payments address: LEPIC, and marked within 30 days.
/// An unmarked slate from the key turns it off again at once (the downgrade).
bool isProven(PeerCompat? c, DateTime now) =>
    isLepicKey(c) && _within(c!.lastMarkedAt, compatWindow, now);

/// Fresh, for unasked sends: proven, and no unmarked message within 30 days.
bool isFresh(PeerCompat? c, DateTime now) =>
    isProven(c, now) && !_within(c!.lastUnmarkedAt, compatWindow, now);

/// May a plain notice (`posted`, `cancelled`, `withdrawn`, `declined`) go to a payments address.
/// [exchangeMarked]: this exchange's own incoming slate carried the marker.
bool mayNotifyPlain(
  PeerCompat? c,
  DateTime now, {
  required bool exchangeMarked,
}) => exchangeMarked && isProven(c, now);

/// May a pair request (the unasked message) go to the contact: fresh, bit 1 claimed, and the
/// contact is a plain contact or an ended pairing.
bool mayPairRequest(PeerCompat? c, Relationship r, DateTime now) =>
    isFresh(c, now) &&
    c!.claims(featurePairRequests) &&
    (r.kind == RelationshipKind.contact || r.kind == RelationshipKind.ended);

/// May the contact page offer Pair (the way-1 form): as [mayPairRequest] but a plain contact only.
bool mayOfferPair(PeerCompat? c, Relationship r, DateTime now) =>
    r.kind == RelationshipKind.contact && mayPairRequest(c, r, now);

/// May a directory payload go to the directory whose pairing claims [directoryClaimed].
bool mayDirectoryPayload(int directoryClaimed, Relationship r) =>
    directoryClaimed & featureDirectory != 0 && r.isPaired;

/// How an unanswered mailbox send stands, by the time since it was sent.
MailboxSendStage mailboxSendStage(DateTime sentAt, DateTime now) {
  final age = now.difference(sentAt);
  if (age >= mailboxGoneAfter) return MailboxSendStage.neverPickedUp;
  if (age >= mailboxUnansweredAfter) return MailboxSendStage.notAnswered;
  return MailboxSendStage.waiting;
}

/// Is "Cancel and send by Epicbox" offered for a mailbox send made at [sentAt]: unanswered for
/// 24 hours, the contact paired or verified, and an Epicbox address known. No compatibility
/// needed: the new send is an ordinary slate.
bool mayCancelAndSendByEpicbox(Relationship r, DateTime sentAt, DateTime now) =>
    r.isPaired &&
    r.hasEpicboxAddress &&
    mailboxSendStage(sentAt, now) != MailboxSendStage.waiting;

/// Is the mailbox route for sends offered: paired or verified, and no contact line shows
/// (neither "answered by another wallet app" nor "not heard from since").
bool mayOfferMailboxRoute(PeerCompat? c, Relationship r, DateTime now, {DateTime? lastSealedIn}) =>
    r.isPaired && contactLine(c, r, now, lastSealedIn: lastSealedIn).kind == ContactLineKind.none;

/// The key's last Epicbox slate came without the marker, after its last marked one.
bool answeredByOtherApp(PeerCompat? c) {
  final unmarked = c?.lastUnmarkedAt;
  if (unmarked == null) return false;
  final marked = c!.lastMarkedAt;
  return marked == null || unmarked.isAfter(marked);
}

/// The line for the contact page. [lastSealedIn] is when a sealed envelope from the contact
/// last opened. "Answered by another wallet app" shows for contacts, paired and verified, and
/// wins over "Not heard from" when both apply; the latter needs a paired or verified contact and
/// 90 days since the latest sign of life.
ContactLine contactLine(
  PeerCompat? c,
  Relationship r,
  DateTime now, {
  DateTime? lastSealedIn,
}) {
  final inRange = r.kind == RelationshipKind.contact || r.isPaired;
  if (!inRange) return const ContactLine.none();
  if (answeredByOtherApp(c)) {
    return const ContactLine(ContactLineKind.answeredByOtherApp);
  }
  if (!r.isPaired) return const ContactLine.none();
  final marked = c?.lastMarkedAt;
  final latest = marked == null
      ? lastSealedIn
      : (lastSealedIn != null && lastSealedIn.isAfter(marked)
            ? lastSealedIn
            : marked);
  if (latest != null && now.difference(latest) > notHeardAfter) {
    return ContactLine(ContactLineKind.notHeardSince, latest);
  }
  return const ContactLine.none();
}
