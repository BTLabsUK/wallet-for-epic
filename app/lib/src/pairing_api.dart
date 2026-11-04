// SPDX-License-Identifier: Apache-2.0
/// Pairing (LEPIC RFC 0002, sections 7 to 11): the calls the screens make, on the open
/// wallet's [WalletSession.pairing]. The types are the app's own, in `models.dart`; LEPIC's
/// adapter maps its binding onto them (U-24), the fakes play both sides for tests, the
/// tour and the web preview.
///
/// One code, two ways. The wallet holds one standing code (7 days), shown as a QR and shared
/// as a link. Way 1 sends a request to a contact's Epicbox address; Way 2 is the code, scanned
/// or pasted, finished over Epicbox or by hand, then the four words. A request between two
/// contacts proves both addresses and ends Verified without words.
///
/// Nothing here pays or signs a payment. A pairing step that cannot go on throws a
/// [WalletError] of kind [WalletErrorKind.pairingFailed]; [pairingFailureOf] says why.
library;

import 'models.dart';

/// How long a code (the standing one, or the one a request carries) is good for (RFC 7.1).
const Duration pairingInviteExpiry = Duration(days: 7);

/// A standing code with less than this left is replaced by a fresh one.
const Duration pairingInviteRenewBefore = Duration(hours: 24);

/// How long the answerer waits for the confirm (RFC 8.2).
const Duration pairingReplyWait = Duration(hours: 1);

/// How long an inviter waits to hear the other wallet before the pairing ends as never
/// finished. Counted in time spent collecting, not wall time.
const Duration pairingHeardWait = Duration(days: 7);

/// How often the contact check collects the contacts it asked, until the wait ends.
const Duration contactCheckEvery = Duration(seconds: 15);

/// How long a private invite (a device link's QR) is good for.
const Duration privateInviteExpiry = Duration(minutes: 15);

/// The largest payload a private pairing posts.
const int privatePayloadMaxBytes = 32 * 1024;

/// How many words the check shows.
const int sasWordCount = 4;

abstract interface class PairingApi {
  /// True when this core pairs. Every other call throws when it is false.
  bool get supported;

  /// Every pairing of this wallet, pending ones included, newest first. The standing code is
  /// not among them: an unused code shows only on the Pair screen ([standingCode]).
  Future<List<PairingRecord>> pairings();

  /// The pairing [id], or null when there is none.
  Future<PairingRecord?> pairing(String id);

  /// The pairing the address-book contact [contactId] uses, of those attached to it (their
  /// [PairingRecord.contactId]) as [contactPairingOf] picks it, or null. The address book is
  /// shared by every wallet on the device; which contact a wallet paired with is the wallet's
  /// to say.
  Future<PairingRecord?> pairingForContact(String contactId);

  /// Second answers to used codes, shown until removed (C-15).
  Future<List<PairingStray>> strays();

  /// Forgets the stray [id].
  Future<void> removeStray(String id);

  /// Sets the Epicbox servers (`host[:port]`, up to three) of Settings › Advanced › Connection
  /// servers. Kept for the core's sake; the code carries the wallet's own relay.
  void setConnectionServers(List<String>? hosts);

  /// Applies the relay moves contacts asked for whose relay is in the Epicbox server list.
  /// Called when the server list changes; the contact list does it when it loads.
  Future<void> followRelayMoves();

  /// The stale contact check (after a long gap): asks each paired shop and exchange whose
  /// pairing has not ended to answer (people are not checked), then collects just those
  /// contacts every [every] for [wait] (default `[contacts] check_wait_s`). Per contact: heard
  /// after the check was sent is [ContactCheckOutcome.reachable]; a card on another relay is
  /// [ContactCheckOutcome.moved] (applied when the relay is in the server list, else
  /// [PairingEventKind.relayMoveRefused]); an unreachable home relay, or no word by the end of
  /// the wait, is [ContactCheckOutcome.notAnswering] ([PairingRecord.notAnswering], until the
  /// contact is heard again). A check that cannot be sent for one contact leaves the others
  /// alone. Returns the outcome by pairing id; empty when nothing was checked.
  Future<Map<String, ContactCheckOutcome>> checkContacts({Duration? wait, Duration every = contactCheckEvery});

  // Your code (RFC 7.1): this wallet is A.

  /// The wallet's standing code, carrying [name] (what the other side sees, 1 to 48 bytes). A
  /// fresh one is made when there is none, when it was answered, when less than
  /// [pairingInviteRenewBefore] is left, when the wallet's relay changed, or when [name]
  /// differs from the one it carries (the old one is withdrawn then). Sends nothing. The link
  /// is in [PairingRecord.inviteLink]; the record is never listed by [pairings].
  Future<PairingRecord> standingCode({required String name});

  /// Gives every Contact-class pairing the new own [name]: each gets a fresh card at the next
  /// collect. Returns how many. Called with [standingCode] when the user changes the name.
  Future<int> setOwnName(String name);

  /// Way 1: sends a request to pair to [toAddress], a contact's Epicbox address, as [name].
  /// The request carries a code of its own (never the standing one) and expects the answer to
  /// prove [toAddress]. [contactId] is the contact it attaches to once answered. Fails
  /// `peerNotProven` (no Epic Cash payment with that key yet, or its wallet does not take
  /// requests), `alreadyUsed` for a live pairing with that key, `inProgress` for one in
  /// progress, `relayUnreachable` when Epicbox is off or Offline, and transport errors when
  /// the post failed: nothing is stored then. Returns the pending record
  /// ([PairingState.pendingInvite], [PairingRecord.expectAddress] set).
  Future<PairingRecord> requestPairing({required String toAddress, required String name, String? contactId});

  /// Cancels the code or request [id] (a later answer is told it was cancelled), or forgets
  /// the answer [id] still waiting for its confirm. A cancelled code stays hidden until it
  /// expires, so a late answer is refused, not left hanging.
  Future<void> cancelInvite(String id);

  /// The inviter by hand: opens a `epiccash://pair-reply/…` link pasted under Have their code?.
  /// Returns the record (Waiting or Verified), whose finish code goes back the same way.
  Future<PairingRecord> openReply(String link);

  /// The inviter by hand: the `epiccash://pair-confirm/…` finish code for the pairing [id].
  /// After an answer taken by hand it always exists; after one the relay carried, only while
  /// the confirm could not be posted.
  Future<String> confirmLink(String id);

  // Answering (RFC 7.2, 7.3): this wallet is B.

  /// Opens a code (`epiccash://pair/1/…`, also pasted as text) without answering it.
  Future<PairingInvitePreview> openInvite(String link);

  /// The requests to pair that came to this wallet's address and are still live (not
  /// answered, dismissed or expired), oldest first. The core knows no address book: the app
  /// shows those from contacts and dismisses the rest on arrival.
  Future<List<PairRequest>> requests();

  /// Opens the stored request [requestId] as a preview, as [openInvite] does a code: its
  /// sender address is on the preview, and accepting it expects the confirm to prove it.
  Future<PairingInvitePreview> openRequest(String requestId);

  /// Hides the request [requestId]. Its code is remembered until it expires, so a replay is
  /// dropped; a newer request from the same sender shows again.
  Future<void> dismissRequest(String requestId);

  /// The request [requestId] was answered on the linked device [device] (the first Pair
  /// wins): hidden here, with a [PairingEventKind.pairedElsewhere] notice naming the device.
  Future<void> requestHandledOn(String requestId, String device);

  /// A request the linked device received and passed on (the relay hands a message to one
  /// device only): listed by [requests] and answered here as one that came here, until it is
  /// answered, dismissed, handled on the other device or expired. Raises
  /// [PairingEventKind.requested]. Not kept across a restart.
  Future<void> takeForwardedRequest(PairRequest request);

  /// Answers the code of [preview] as [name]. [allowInvoices] is the user's choice on a code
  /// that asks for it; it takes effect once the words match. [contactId] attaches the
  /// pairing to an address-book contact. The answer goes through the code's relay; when
  /// [byHand] is set, or the relay is unreachable ([PairingRecord.relayDown] on the result),
  /// it waits to be sent as a link ([replyLink]). A preview of a request expects the confirm
  /// to prove the sender's address. Fails `inviteDismissed`, `inProgress`, `alreadyUsed`, and
  /// `crossed` when this wallet's own pairing with the same key wins the lower-key rule (its
  /// own then survives; otherwise the own one is withdrawn). Returns the record,
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

  /// The answerer by hand: opens the inviter's `epiccash://pair-confirm/…` finish code.
  /// Returns the record.
  Future<PairingRecord> openConfirm(String link);

  // After pairing.

  /// The user's answer on the four words of [id], allowed from Waiting on.
  /// [PairingCheck.match] makes it verified (and counts as heard; the other side learns of it
  /// when its wallet takes status notices). [PairingCheck.mismatch] ends it on this side and
  /// tells the other: the record stays, ended, with its sends in flight cancellable; returns
  /// the ended record. [PairingCheck.skip] is not offered by the app.
  Future<PairingRecord?> checkWords(String id, PairingCheck check);

  /// Collects the pairing and contact mailboxes once (an open code, an answer waiting for
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
  /// [contactAddress] is the contact's Epicbox address, when it has one: refused
  /// `otherAddress` when the pairing proves another key, `addressProofMissing` when the
  /// pairing proves none yet (tried again when a proof arrives). Writing the proven address
  /// into the book is the app's job, at Verified only.
  Future<PairingRecord> attach(String id, String? contactId, {String? contactAddress});

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
  /// save or share. The slate is the same payment; only the wrapping differs. Refused
  /// `waiting` while the other wallet is not heard, `ended` once the pairing ended.
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
  /// 9.1, "Send through Anna's mailbox"). The answer comes back the same way. Refused
  /// `waiting` and `ended` as [sealSlate].
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
  // (QR or paste only), are never listed by [pairings] or a backup, and carry only opaque
  // payloads: no slates, invoices or notices. A contact pairing never takes a payload.
  // [checkWords] and [removePairing] work on both classes.

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
  Future<void> followRelayMoves() async {}

  @override
  Future<Map<String, ContactCheckOutcome>> checkContacts({Duration? wait, Duration every = contactCheckEvery}) async => const {};

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
  Future<PairingRecord> standingCode({required String name}) async => throw pairingUnsupported('standingCode');

  @override
  Future<int> setOwnName(String name) async => throw pairingUnsupported('setOwnName');

  @override
  Future<PairingRecord> requestPairing({required String toAddress, required String name, String? contactId}) async =>
      throw pairingUnsupported('requestPairing');

  @override
  Future<void> cancelInvite(String id) async => throw pairingUnsupported('cancelInvite');

  @override
  Future<PairingRecord> openReply(String link) async => throw pairingUnsupported('openReply');

  @override
  Future<String> confirmLink(String id) async => throw pairingUnsupported('confirmLink');

  @override
  Future<PairingInvitePreview> openInvite(String link) async => throw pairingUnsupported('openInvite');

  @override
  Future<List<PairRequest>> requests() async => const [];

  @override
  Future<PairingInvitePreview> openRequest(String requestId) async => throw pairingUnsupported('openRequest');

  @override
  Future<void> dismissRequest(String requestId) async => throw pairingUnsupported('dismissRequest');

  @override
  Future<void> requestHandledOn(String requestId, String device) async => throw pairingUnsupported('requestHandledOn');

  @override
  Future<void> takeForwardedRequest(PairRequest request) async => throw pairingUnsupported('takeForwardedRequest');

  @override
  Future<PairingRecord> acceptInvite({required String token, required String name, bool allowInvoices = false, String? contactId, bool byHand = false}) async =>
      throw pairingUnsupported('acceptInvite');

  @override
  Future<String> replyLink(String id) async => throw pairingUnsupported('replyLink');

  @override
  Future<PairingRecord> openConfirm(String link) async => throw pairingUnsupported('openConfirm');

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
  Future<PairingRecord> attach(String id, String? contactId, {String? contactAddress}) async => throw pairingUnsupported('attach');

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
/// app also accepts the link pasted with surrounding text or whitespace. [card] is the older
/// in-person card, which the app no longer pairs with ("Not a pairing code").
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

/// The requests of [all] the app shows: those whose sender is an address-book contact, by
/// the key of its Epicbox address ([contactKeys]). The rest are dismissed on arrival.
List<PairRequest> requestsFromContacts(Iterable<PairRequest> all, Set<String> contactKeys) => [
  for (final r in all)
    if (contactKeys.contains(epicboxKey(r.fromAddress))) r,
];

/// The pairing records of [all] that sit in Contacts: a request this wallet sent, an answer
/// waiting for its confirm, and every stored record (waiting, paired, verified, keys changed,
/// ended). A code nobody answered is not among them: it shows only on the Pair screen.
List<PairingRecord> pairingsInContacts(Iterable<PairingRecord> all) => [
  for (final r in all)
    if (r.state.isRecord || r.state == PairingState.pendingReply || (r.state == PairingState.pendingInvite && r.expectAddress != null)) r,
];
