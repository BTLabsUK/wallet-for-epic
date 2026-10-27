/// Pairing (LEPIC RFC 0002, sections 7 to 11): the calls the screens make, on the open
/// wallet's [WalletSession.pairing]. The types are the app's own, in `models.dart`; LEPIC's
/// adapter maps its binding onto them (U-24), the fakes play both sides for tests, the
/// tour and the web preview.
///
/// Nothing here pays or signs a payment. A pairing step that cannot go on throws a
/// [WalletError] of kind [WalletErrorKind.pairingFailed]; [pairingFailureOf] says why.
library;

import 'models.dart';

/// The expiries an online invite offers (RFC 7.1); 24 hours is the default.
const List<Duration> pairingInviteExpiries = [Duration(hours: 1), Duration(hours: 24), Duration(days: 7)];
const Duration pairingInviteDefaultExpiry = Duration(hours: 24);

/// How long pairing words are good for (RFC 7.7).
const Duration pairingWordsExpiry = Duration(minutes: 10);

/// How long the answerer waits for the confirm (RFC 8.2).
const Duration pairingReplyWait = Duration(hours: 1);

/// This wallet's unanswered words invite for [contactId] (null: none) with 2 minutes or more
/// left: opened again, the words page shows it instead of making a new one each visit.
PairingRecord? openWordsInvite(Iterable<PairingRecord> all, {String? contactId, required DateTime now}) => all
    .where(
      (r) =>
          r.state == PairingState.pendingInvite &&
          r.inviteWords.isNotEmpty &&
          r.contactId == contactId &&
          r.expiresAt != null &&
          r.expiresAt!.difference(now) >= const Duration(minutes: 2),
    )
    .firstOrNull;

/// How long a private invite (a device link's QR) is good for.
const Duration privateInviteExpiry = Duration(minutes: 15);

/// The largest payload a private pairing posts.
const int privatePayloadMaxBytes = 32 * 1024;

/// How many words a pairing-words invite has, and the check.
const int pairingWordCount = 5;
const int sasWordCount = 4;

abstract interface class PairingApi {
  /// True when this core pairs. Every other call throws when it is false.
  bool get supported;

  /// Every pairing of this wallet, pending ones included, newest first.
  Future<List<PairingRecord>> pairings();

  /// The pairing [id], or null when there is none.
  Future<PairingRecord?> pairing(String id);

  /// The pairing the address-book contact [contactId] uses, of those attached to it (their
  /// [PairingRecord.contactId]) as [contactPairingOf] picks it, or null. The address book is
  /// shared by every wallet on the device; which contact a wallet paired with is the wallet's
  /// to say.
  Future<PairingRecord?> pairingForContact(String contactId);

  /// Second answers to used invites, shown in Pending invites until removed (C-15).
  Future<List<PairingStray>> strays();

  /// Forgets the stray [id].
  Future<void> removeStray(String id);

  /// Sets the Epicbox servers (`host[:port]`, up to three) where pairing words meet, from
  /// Settings › Advanced › Connection servers: [makeInvite] with words leaves the invite on
  /// them and [openWords] looks on them. Null is the core's built-in list (the defaults). It
  /// applies to the next words call; a pairing that exists keeps its mailbox on the inviter's
  /// own Epicbox server.
  void setConnectionServers(List<String>? hosts);

  // Inviting (RFC 7.1, 7.7): this wallet is A.

  /// Makes an invite that [name] (the name the other side will see, 1 to 48 bytes) answers
  /// within [expiry]. With [words], it is also offered as five pairing words for 10 minutes
  /// ([pairingWordsExpiry] replaces [expiry]); words need Epicbox and a built-in relay, and
  /// [WalletErrorKind.pairingFailed] `relayUnreachable` says when they cannot be offered.
  /// [label] is whom it is for (a contact's name), [contactId] the contact the pairing
  /// attaches to once answered. Returns the pending record with its link (and words).
  Future<PairingRecord> makeInvite({
    required String name,
    required Duration expiry,
    bool words = false,
    String? label,
    String? contactId,
  });

  /// Cancels the invite [id] (a later answer is told it was cancelled), or forgets the answer
  /// [id] still waiting for its confirm; the other side is not told.
  Future<void> cancelInvite(String id);

  /// The inviter by hand (Epicbox off): opens a `epiccash://pair-reply/…` link pasted under
  /// Enter link or words. Returns the paired record, whose words the user checks next.
  Future<PairingRecord> openReply(String link);

  /// The inviter by hand: the `epiccash://pair-confirm/…` link for the pairing [id], to send
  /// back when the confirm cannot go through the relay.
  Future<String> confirmLink(String id);

  // Answering (RFC 7.2, 7.3): this wallet is B.

  /// Opens an invite link (`epiccash://pair/1/…`, also pasted as text) without answering it.
  Future<PairingInvitePreview> openInvite(String link);

  /// Opens the invite five pairing [words] (names or emoji, in order) find on the built-in
  /// relays. `notFound` when they open nothing.
  Future<PairingInvitePreview> openWords(List<String> words);

  /// Answers the invite of [preview] as [name]. [allowInvoices] is the user's choice on an
  /// invite that asks for it; it takes effect once the words match. [contactId] attaches the
  /// pairing to an address-book contact. The answer goes through the invite's relay; when
  /// [byHand] is set, or the relay is unreachable ([PairingRecord.relayDown] on the result),
  /// it waits to be sent as a link ([replyLink]). Returns the record,
  /// [PairingState.pendingReply].
  Future<PairingRecord> acceptInvite({
    required String token,
    required String name,
    bool allowInvoices = false,
    String? contactId,
    bool byHand = false,
  });

  /// The answerer by hand: the `epiccash://pair-reply/…` link of the pairing [id].
  Future<String> replyLink(String id);

  /// The answerer by hand: opens the inviter's `epiccash://pair-confirm/…` link. Returns the
  /// paired record.
  Future<PairingRecord> openConfirm(String link);

  // In person (RFC 7.4).

  /// A fresh card of this wallet, shown as [name], for the other phone to scan.
  Future<PairingCard> showCard({required String name});

  /// Pairs with the card the camera read (`epiccash://contact/1/…`), against the card [cardId]
  /// this phone showed. Both phones scanned, so the result is paired and its words show.
  Future<PairingRecord> scanCard({required String cardId, required String text});

  // After pairing.

  /// The user's answer on the four words of [id]. [PairingCheck.match] makes it verified (and
  /// turns on the invoices the user chose when answering an invite that asked);
  /// [PairingCheck.mismatch] deletes it on this side and returns null; [PairingCheck.skip]
  /// leaves it paired.
  Future<PairingRecord?> checkWords(String id, PairingCheck check);

  /// Collects the pairing and contact mailboxes once (an open invite, an answer waiting for
  /// its confirm, a contact's invoices, payments and withdrawals): what it finds comes as
  /// [events]. [trigger] says why (RFC 8.4). Returns how many pairings it completed or ended.
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground});

  /// Removes the pairing [id] (C-19). Its contact stays.
  Future<void> removePairing(String id);

  /// Seal payments for [id] on or off.
  Future<PairingRecord> setSeal(String id, bool on);

  /// Allow invoices for [id]: refused unless verified. Off declines the open requests from
  /// the contact; returns how many were declined.
  Future<int> setAllowInvoices(String id, bool on);

  /// Attaches the pairing [id] to the address-book contact [contactId] (null detaches it).
  Future<PairingRecord> attach(String id, String? contactId);

  /// Decides on changed keys ([PairingState.keysChanged]): the old keys come back verified, or
  /// the new ones stay paired and need the words checked.
  Future<PairingRecord> resolveKeysChanged(String id, KeysChoice choice);

  // Requests to a paired contact (RFC 11, 12).

  /// Sends the paired contact [id] a request for [amount] through its mailbox. Needs a
  /// verified contact whose card pays invoices (caps bit 1).
  Future<IssuedInvoice> requestPayment({
    required String id,
    required BigInt amount,
    String? message,
  });

  /// A request for [amount] as a payment file, for anyone to pay (an invoice slate, I1): the
  /// payer's wallet signs it and sends a file back, which Receive opens to finish. Kept as an
  /// issued invoice waiting for its payer.
  Future<Slate> requestFile({required BigInt amount, String? message});

  // Sealed payments (RFC 9).

  /// Seals the payment file [slateJson] for the paired contact [id]: the armored text to
  /// save or share. The slate is the same payment; only the wrapping differs.
  Future<String> sealSlate({required String id, required String slateJson});

  /// Opens a payment file or paste: a sealed one from a paired contact gives its slate and the
  /// pairing; a plain one comes back as it is, with no pairing. `sealedForOther` for one
  /// sealed for another wallet or install (RFC 9.5), `newerVersion` for a newer one.
  Future<OpenedSlate> openSlate(String text);

  /// Receives the payment in sealed [text] and returns the answer, sealed to its sender when
  /// it can be, else plain. [message] is signed into the answer.
  Future<SealedReply> receiveSealed(String text, {String? message});

  /// Finalizes and posts the answer in sealed [text], to a payment this wallet started.
  Future<TxEntry> finalizeSealed(String text);

  /// Pays the payment request (I1) in sealed [text] for exactly [amount], the amount the user
  /// approved, and returns the answer, sealed to the contact that sent it when it can be.
  Future<PaidSealedRequest> paySealedRequest(String text, {required BigInt amount});

  /// Sends [amount] to the paired contact [id] through its mailbox on its relay, sealed (RFC
  /// 9.1, "Send through Anna's mailbox"). The answer comes back the same way.
  Future<TxEntry> sendViaMailbox({
    required String id,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  });

  /// The plain copy of the sealed send [txKey] (RFC 9.3, "Send as plain instead"): the same
  /// slate, so it cannot be paid twice. The contact's seal becomes [SealMode.degraded].
  Future<String> plainSlate(String txKey);

  /// The paired contact and purpose of the transaction with slate [slateId] (a withdrawal
  /// from an exchange, a deposit request it paid, ...), or null when no pairing took part.
  Future<PairingSlate?> slateOf(String slateId);

  // Backup (RFC 10.5, 9.5).

  /// Pairing records imported from a backup that were in use on another device start here,
  /// and the other device should stop using them.
  Future<int> useImportedPairings();

  /// What happens to pairings as collecting and answers find it. Informational: no event
  /// pays anything.
  Stream<PairingEvent> events();

  // Private pairings (LEPIC's pairing class `private`): the channel between this wallet's own
  // linked devices (`devices/`). Their keys are their own domain, mixed with fresh secrets from
  // the QR and the answer, so the phrase alone does not find them. They have no pairing words
  // (QR or paste only), are never listed by [pairings], Pending invites or a backup, and carry
  // only opaque payloads: no slates, invoices or notices. A contact pairing never takes a
  // payload. [checkWords] and [removePairing] work on both classes.

  /// True when this core makes private pairings. The other private calls throw when false.
  bool get privateSupported;

  /// Every private pairing of this wallet, pending ones included, newest first.
  Future<List<PairingRecord>> privatePairings();

  /// Makes a private invite on [homeRelay] (a server `host[:port]`), shown as [name] to the
  /// device that answers it within [expiry]. Returns the pending record; its
  /// [PairingRecord.inviteLink] is what the QR or the pasted text carries.
  Future<PairingRecord> makePrivateInvite({required String name, required String homeRelay, Duration expiry = privateInviteExpiry});

  /// Answers the private invite [link] as [name]. A contact invite is refused
  /// ([PairingFailure.invalid]), so is this wallet's own ([PairingFailure.ownCard]). Returns the
  /// record, [PairingState.pendingReply] until the inviter's confirm is collected.
  Future<PairingRecord> acceptPrivateInvite({required String link, required String name});

  /// Collects the private pairings' mailboxes once ([only]: just these pairings): answers,
  /// confirms, payloads and removals. Payloads wait in [payloads]. Returns how many pairings it
  /// completed or ended.
  Future<int> collectPrivate({List<String>? only});

  /// Posts [bytes] to the private pairing [id] (outbox: retried until a server took it).
  /// Refused for a contact pairing and for one not paired.
  Future<void> postPayload({required String id, required List<int> bytes});

  /// The payloads collected and not acknowledged yet, oldest first.
  Future<List<PairingPayload>> payloads();

  /// Takes the payloads [ids] off [payloads], once their effect is stored.
  Future<void> ackPayloads(List<String> ids);
}

/// The error of a pairing call on a core without pairing.
WalletError pairingUnsupported(String call) => WalletError(
  kind: WalletErrorKind.other,
  message: '$call needs LEPIC with pairing (RFC 0002, U-24)',
);

/// A [PairingApi] for a core without pairing: [supported] is false, lists are empty, every
/// call that would change something throws [pairingUnsupported].
class NoPairing implements PairingApi {
  const NoPairing();

  @override
  bool get supported => false;

  @override
  void setConnectionServers(List<String>? hosts) {}

  @override
  Future<List<PairingRecord>> pairings() async => const [];

  @override
  Future<PairingRecord?> pairing(String id) async => null;

  @override
  Future<PairingRecord?> pairingForContact(String contactId) async => null;

  @override
  Future<List<PairingStray>> strays() async => const [];

  @override
  Future<void> removeStray(String id) async => throw pairingUnsupported('removeStray');

  @override
  Future<PairingRecord> makeInvite({required String name, required Duration expiry, bool words = false, String? label, String? contactId}) async =>
      throw pairingUnsupported('makeInvite');

  @override
  Future<void> cancelInvite(String id) async => throw pairingUnsupported('cancelInvite');

  @override
  Future<PairingRecord> openReply(String link) async => throw pairingUnsupported('openReply');

  @override
  Future<String> confirmLink(String id) async => throw pairingUnsupported('confirmLink');

  @override
  Future<PairingInvitePreview> openInvite(String link) async => throw pairingUnsupported('openInvite');

  @override
  Future<PairingInvitePreview> openWords(List<String> words) async => throw pairingUnsupported('openWords');

  @override
  Future<PairingRecord> acceptInvite({required String token, required String name, bool allowInvoices = false, String? contactId, bool byHand = false}) async =>
      throw pairingUnsupported('acceptInvite');

  @override
  Future<String> replyLink(String id) async => throw pairingUnsupported('replyLink');

  @override
  Future<PairingRecord> openConfirm(String link) async => throw pairingUnsupported('openConfirm');

  @override
  Future<PairingCard> showCard({required String name}) async => throw pairingUnsupported('showCard');

  @override
  Future<PairingRecord> scanCard({required String cardId, required String text}) async => throw pairingUnsupported('scanCard');

  @override
  Future<PairingRecord?> checkWords(String id, PairingCheck check) async => throw pairingUnsupported('checkWords');

  @override
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground}) async => 0;

  @override
  Future<void> removePairing(String id) async => throw pairingUnsupported('removePairing');

  @override
  Future<PairingRecord> setSeal(String id, bool on) async => throw pairingUnsupported('setSeal');

  @override
  Future<int> setAllowInvoices(String id, bool on) async => throw pairingUnsupported('setAllowInvoices');

  @override
  Future<PairingRecord> attach(String id, String? contactId) async => throw pairingUnsupported('attach');

  @override
  Future<PairingRecord> resolveKeysChanged(String id, KeysChoice choice) async => throw pairingUnsupported('resolveKeysChanged');

  @override
  Future<IssuedInvoice> requestPayment({required String id, required BigInt amount, String? message}) async =>
      throw pairingUnsupported('requestPayment');

  @override
  Future<Slate> requestFile({required BigInt amount, String? message}) async => throw pairingUnsupported('requestFile');

  @override
  Future<String> sealSlate({required String id, required String slateJson}) async => throw pairingUnsupported('sealSlate');

  // Without pairing a file is always plain.
  @override
  Future<OpenedSlate> openSlate(String text) async => OpenedSlate(slateJson: text);

  @override
  Future<SealedReply> receiveSealed(String text, {String? message}) async => throw pairingUnsupported('receiveSealed');

  @override
  Future<TxEntry> finalizeSealed(String text) async => throw pairingUnsupported('finalizeSealed');

  @override
  Future<PaidSealedRequest> paySealedRequest(String text, {required BigInt amount}) async =>
      throw pairingUnsupported('paySealedRequest');

  @override
  Future<TxEntry> sendViaMailbox({
    required String id,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) async => throw pairingUnsupported('sendViaMailbox');

  @override
  Future<String> plainSlate(String txKey) async => throw pairingUnsupported('plainSlate');

  @override
  Future<int> useImportedPairings() async => 0;

  @override
  Future<PairingSlate?> slateOf(String slateId) async => null;

  @override
  Stream<PairingEvent> events() => const Stream.empty();

  @override
  bool get privateSupported => false;

  @override
  Future<List<PairingRecord>> privatePairings() async => const [];

  @override
  Future<PairingRecord> makePrivateInvite({required String name, required String homeRelay, Duration expiry = privateInviteExpiry}) async =>
      throw pairingUnsupported('makePrivateInvite');

  @override
  Future<PairingRecord> acceptPrivateInvite({required String link, required String name}) async =>
      throw pairingUnsupported('acceptPrivateInvite');

  @override
  Future<int> collectPrivate({List<String>? only}) async => 0;

  @override
  Future<void> postPayload({required String id, required List<int> bytes}) async => throw pairingUnsupported('postPayload');

  @override
  Future<List<PairingPayload>> payloads() async => const [];

  @override
  Future<void> ackPayloads(List<String> ids) async {}
}

/// What kind of pairing link [text] holds, by its scheme and path, without opening it. The
/// app also accepts the link pasted with surrounding text or whitespace.
enum PairingLinkKind { invite, reply, confirm, card }

/// [text]'s pairing link kind, or null when it holds none. Reads `epiccash://pair/`,
/// `pair-reply/`, `pair-confirm/` and `contact/`, in any case of the scheme.
PairingLinkKind? pairingLinkKind(String text) {
  final link = pairingLinkIn(text);
  if (link == null) return null;
  final rest = link.substring('epiccash://'.length).toLowerCase();
  if (rest.startsWith('pair-reply/')) return PairingLinkKind.reply;
  if (rest.startsWith('pair-confirm/')) return PairingLinkKind.confirm;
  if (rest.startsWith('pair/')) return PairingLinkKind.invite;
  if (rest.startsWith('contact/')) return PairingLinkKind.card;
  return null;
}

/// The first `epiccash://` pairing link in [text] (a shared message holds one among words),
/// whitespace removed, or null.
String? pairingLinkIn(String text) {
  final m = RegExp(r'epiccash://(?:pair|pair-reply|pair-confirm|contact)/[A-Za-z0-9_\-/=]+', caseSensitive: false).firstMatch(text);
  return m?.group(0);
}

/// After an in-person pairing [fresh]: removes the older in-person pairings with the same
/// name that were never checked and sit in no contact, the leftovers of an abandoned scan or
/// a card shown again, so Pending invites lists one row per person (PAIR-AND-7). A verified
/// or saved pairing is never touched. Best effort: a failure leaves the old row.
Future<void> dropOlderInPersonPairings(PairingApi api, PairingRecord fresh) async {
  final name = (fresh.name ?? '').trim();
  if (name.isEmpty) return;
  try {
    for (final r in await api.pairings()) {
      if (r.id == fresh.id || r.way != PairingWay.inPerson || r.state != PairingState.paired) continue;
      if (r.contactId != null || (r.name ?? '').trim() != name) continue;
      await api.removePairing(r.id);
    }
  } on Object {
    // The rows stay; each has Remove.
  }
}
