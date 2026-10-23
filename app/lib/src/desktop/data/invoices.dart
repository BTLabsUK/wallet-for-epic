/// Invoices over Epicbox on desktop (`docs/invoices/flow.md` on `plan/invoices`): requests this
/// wallet sends (it is paid) and invoices it receives (it pays). The UI word for an invoice this
/// wallet sends is a request; for one it receives, an invoice.
///
/// [MockDeskWallet] plays them for the prototype; [LepicDeskWallet] maps the shared session's
/// invoice calls onto these types.
library;

import 'package:flutter/widgets.dart';

import 'models.dart' show DeskError;

/// How long an invoice stays payable unless Settings says otherwise (UP-14: 24 h, 48 h at most).
const Duration defaultInvoiceExpiry = Duration(hours: 24);
const Duration maxInvoiceExpiry = Duration(hours: 48);

/// The expiries Settings › Invoices offers.
const List<Duration> invoiceExpiries = [Duration(hours: 12), Duration(hours: 24), Duration(hours: 48)];

/// The longest message a request carries: 256 bytes, as on Send.
const int requestMessageMaxBytes = 256;

/// The longest message line a list shows (flow.md §4.2).
const int invoiceLineMaxChars = 120;

/// The key part of an Epicbox address, before `@`. Senders are matched on it alone: the relay
/// checks the signature with the key, never the domain.
String addressKey(String address) => address.trim().split('@').first;

/// Untrusted text from another wallet as one plain line: control, zero-width, line-separator
/// and bidi characters removed, whitespace runs folded, cut to [max] characters. Never
/// rendered as a link.
String cleanInvoiceText(String? text, {int? max}) {
  final s = (text ?? '')
      .replaceAll(RegExp('[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u2028\u2029\u202a-\u202e\u2060\u2066-\u2069\ufeff]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (max == null || s.characters.length <= max) return s;
  return '${s.characters.take(max - 1).toString().trimRight()}…';
}

/// Where a request this wallet sent stands (flow.md §3.3). Only [waiting] moves to the
/// endings; [paid] → [confirming] → [completed] follow the chain.
enum RequestState {
  /// Delivered to the payer's invoice address, no answer yet. It can be withdrawn.
  waiting,

  /// The payer paid; this wallet finalized the payment and is posting it.
  paid,

  /// Posted; in the pool ([IssuedRequest.confirmations] 0) or in blocks under the count.
  confirming,

  /// Enough confirmations: spendable.
  completed,

  /// Finalized, but the node refused or could not be reached: Repost.
  notPosted,

  /// The payer declined it (wallet-for-epic and LEPIC payers only); the app withdrew it.
  declined,

  /// Its time ran out unpaid; the wallet cancelled it.
  expired,

  /// This wallet withdrew it.
  withdrawn,

  /// The payer's wallet cannot pay invoices and sent it back (a stock epic-wallet).
  bounced,

  /// Paid but never posted, then cancelled here (flow.md draft 2 §3.3, Advanced): it will not
  /// arrive.
  cancelled;

  /// Ended without a payment: nothing arrives.
  bool get endedUnpaid => this == declined || this == expired || this == withdrawn || this == bounced || this == cancelled;

  /// The payer's money is on its way or here.
  bool get paidOut => this == paid || this == confirming || this == completed || this == notPosted;
}

/// A request this wallet sent: [payerAddress] (their invoice address) is asked for [amount].
/// The payment arrives on this wallet's payments address. Nothing about it spends.
@immutable
class IssuedRequest {
  const IssuedRequest({
    required this.slateId,
    required this.txId,
    required this.payerAddress,
    required this.amount,
    required this.issuedAt,
    required this.expiresAt,
    required this.state,
    this.payerName,
    this.message,
    this.confirmations = 0,
    this.answeredAt,
    this.lateReplyRefused = false,
  });

  final String slateId;

  /// The request's transaction in Activity.
  final int txId;
  final String payerAddress;

  /// The contact whose invoice address it is; null for an address typed in.
  final String? payerName;
  final int amount;
  final String? message;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final RequestState state;
  final int confirmations;

  /// When it left [RequestState.waiting].
  final DateTime? answeredAt;

  /// A payment for it arrived after it ended and was refused (flow.md §5, late I2).
  final bool lateReplyRefused;

  bool get withdrawable => state == RequestState.waiting;

  IssuedRequest copyWith({RequestState? state, int? confirmations, DateTime? answeredAt, bool? lateReplyRefused}) => IssuedRequest(
    slateId: slateId,
    txId: txId,
    payerAddress: payerAddress,
    payerName: payerName,
    amount: amount,
    message: message,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    state: state ?? this.state,
    confirmations: confirmations ?? this.confirmations,
    answeredAt: answeredAt ?? this.answeredAt,
    lateReplyRefused: lateReplyRefused ?? this.lateReplyRefused,
  );
}

/// Where an invoice this wallet received stands (flow.md §4.4, §4.5).
enum PayState {
  /// In Requests › To pay: nothing is paid until the user approves it.
  waiting,

  /// Approved and signed; the reply did not reach the relay. The coins stay locked. Retry
  /// sends the stored reply again without a second approval.
  notDelivered,

  /// The reply reached the relay: the service finalizes and posts it.
  delivered,

  /// The service reports it posted the payment (advisory; LEPIC services only).
  posted,

  /// In blocks, under the confirmation count.
  confirming,
  completed,

  /// The service withdrew the invoice after it was paid: the user may cancel the payment.
  withdrawnAfterPay,

  /// Paid, its time passed, and the payment is neither in the pool nor on the chain: the user
  /// may cancel it.
  pastTtl,

  /// The user cancelled the payment; the coins are back.
  cancelled,

  /// The user declined it before paying.
  declined,

  /// Its time ran out before the user answered.
  expired,

  /// The service withdrew it before the user answered.
  withdrawn;

  /// Paid: an outgoing transaction exists for it.
  bool get paid => this == notDelivered || this == delivered || this == posted || this == confirming || this == completed || this == withdrawnAfterPay || this == pastTtl || this == cancelled;

  /// The user should act on the payment (Retry or Cancel payment).
  bool get needsAction => this == notDelivered || this == withdrawnAfterPay || this == pastTtl;

  /// The coins of the payment are locked by it.
  bool get locking => this == notDelivered || this == delivered || this == posted || this == withdrawnAfterPay || this == pastTtl;

  /// The payment can still be cancelled by the user.
  bool get cancellable => this == notDelivered || this == withdrawnAfterPay || this == pastTtl;
}

/// An invoice a trusted sender billed this wallet with.
@immutable
class IncomingInvoice {
  const IncomingInvoice({
    required this.slateId,
    required this.senderAddress,
    required this.label,
    required this.amount,
    required this.fee,
    required this.receivedAt,
    required this.expiresAt,
    required this.state,
    this.message,
    this.confirmations = 0,
    this.txId,
    this.answeredAt,
    this.kernel,
    this.spendToSelf = false,
  });

  final String slateId;

  /// The trusted list's stored address for the sender (matched on the key), never the
  /// message's own `from`.
  final String senderAddress;

  /// The user's label for the sender from the trusted list, never a name from the invoice.
  final String label;
  final int amount;

  /// The fee this wallet pays on top, as estimated for the amount.
  final int fee;

  /// The sender's message, already cleaned ([cleanInvoiceText]). Untrusted.
  final String? message;
  final DateTime receivedAt;
  final DateTime expiresAt;
  final PayState state;
  final int confirmations;

  /// The payment's transaction in Activity, once approved.
  final int? txId;

  /// When it was approved, declined, or ended.
  final DateTime? answeredAt;

  /// From the service's `posted` notice.
  final String? kernel;

  /// A [PayState.cancelled] payment whose coins this wallet can still spend to itself, which
  /// makes the cancel final (D-2).
  final bool spendToSelf;

  int get total => amount + fee;

  Duration timeLeftAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  IncomingInvoice copyWith({PayState? state, int? confirmations, int? txId, DateTime? answeredAt, String? kernel, bool? spendToSelf}) => IncomingInvoice(
    slateId: slateId,
    senderAddress: senderAddress,
    label: label,
    amount: amount,
    fee: fee,
    message: message,
    receivedAt: receivedAt,
    expiresAt: expiresAt,
    state: state ?? this.state,
    confirmations: confirmations ?? this.confirmations,
    txId: txId ?? this.txId,
    answeredAt: answeredAt ?? this.answeredAt,
    kernel: kernel ?? this.kernel,
    spendToSelf: spendToSelf ?? this.spendToSelf,
  );
}

/// A sender allowed to send invoices to the invoice address, by its full payments address; the
/// label is the user's. A contact's switch adds and removes the contact's address here.
@immutable
class TrustedSender {
  const TrustedSender({required this.address, required this.label, required this.since, this.contactId});

  final String address;
  final String label;
  final DateTime since;

  /// The contact this entry belongs to; null for a service with no contact.
  final String? contactId;
}

/// What LEPIC learned of a payer's wallet (U-20 `peer_capability`).
enum PeerCapability {
  /// Nothing known yet.
  unknown,

  /// A LEPIC wallet: pays requests and sends notices.
  lepic,

  /// It sent a request back before: it cannot pay requests.
  noInvoices,
}

/// The last check of the invoice address (the drain) and the payments address.
enum InvoiceCheck { ok, checking, failed }

/// Everything the Invoices page, Settings › Invoices and the badges show, read at [now]
/// (the wallet's clock; the prototype moves it).
@immutable
class InvoiceBook {
  const InvoiceBook({
    required this.now,
    required this.invoiceAddress,
    required this.invoiceIndex,
    required this.trusted,
    required this.toPay,
    required this.sent,
    this.expiry = defaultInvoiceExpiry,
    this.dropped = 0,
    this.lastCheck,
    this.check = InvoiceCheck.ok,
    this.checkProblem,
  });

  final DateTime now;

  /// This wallet's invoice address: give it only to senders it trusts; not for payments.
  final String invoiceAddress;

  /// Its derivation index (1 or higher); Rotate moves to the next one. Null when the wallet
  /// does not say.
  final int? invoiceIndex;
  final List<TrustedSender> trusted;

  /// Invoices received: waiting ones and those answered (paid, declined, ended).
  final List<IncomingInvoice> toPay;

  /// Requests sent, newest first.
  final List<IssuedRequest> sent;
  final Duration expiry;

  /// Messages from senders not on the trusted list that the last checks ignored unread.
  final int dropped;
  final DateTime? lastCheck;
  final InvoiceCheck check;

  /// Why the last check failed, in a few words.
  final String? checkProblem;

  /// The same book read at [now] (a countdown tick; nothing reloaded).
  InvoiceBook at(DateTime now) => InvoiceBook(
    now: now,
    invoiceAddress: invoiceAddress,
    invoiceIndex: invoiceIndex,
    trusted: trusted,
    toPay: toPay,
    sent: sent,
    expiry: expiry,
    dropped: dropped,
    lastCheck: lastCheck,
    check: check,
    checkProblem: checkProblem,
  );

  /// The same book with the check's state replaced (a drain started, failed or ended).
  InvoiceBook withCheck(InvoiceCheck check, {String? problem}) => InvoiceBook(
    now: now,
    invoiceAddress: invoiceAddress,
    invoiceIndex: invoiceIndex,
    trusted: trusted,
    toPay: toPay,
    sent: sent,
    expiry: expiry,
    dropped: dropped,
    lastCheck: lastCheck,
    check: check,
    checkProblem: problem,
  );

  /// What the sidebar badge counts: invoices waiting for an answer and payments the user must
  /// settle (Retry, Cancel payment).
  int get attention => waiting.length + needsAction.length;

  /// Invoices waiting for the user, oldest first: the sidebar badge.
  List<IncomingInvoice> get waiting => [for (final i in toPay) if (i.state == PayState.waiting && i.expiresAt.isAfter(now)) i]
    ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));

  /// Invoices answered or ended, newest answer first: paid ones until they complete or for a day,
  /// the rest for a day (flow.md D-3); a payment that needs the user stays until it is settled.
  List<IncomingInvoice> get answered => [
    for (final i in toPay)
      if (i.state != PayState.waiting || !i.expiresAt.isAfter(now))
        if (i.state.needsAction || now.difference(i.answeredAt ?? i.expiresAt) < const Duration(hours: 24)) i,
  ]..sort((a, b) => (b.answeredAt ?? b.expiresAt).compareTo(a.answeredAt ?? a.expiresAt));

  /// Payments of invoices the user must settle (Retry, Cancel payment).
  List<IncomingInvoice> get needsAction => [for (final i in toPay) if (i.state.needsAction) i];

  List<IssuedRequest> get openRequests => [for (final r in sent) if (r.state == RequestState.waiting) r];

  TrustedSender? trustedFor(String address) {
    final key = addressKey(address);
    return trusted.where((t) => addressKey(t.address) == key).firstOrNull;
  }

  IncomingInvoice? invoice(String slateId) => toPay.where((i) => i.slateId == slateId).firstOrNull;
  IssuedRequest? request(String slateId) => sent.where((r) => r.slateId == slateId).firstOrNull;

  /// The invoice paid with transaction [txId], or the request behind it.
  IncomingInvoice? invoiceOfTx(int txId) => toPay.where((i) => i.txId == txId).firstOrNull;
  IssuedRequest? requestOfTx(int txId) => sent.where((r) => r.txId == txId).firstOrNull;

  /// Another paid invoice from the same sender for the same amount in the last 48 h
  /// (flow.md §5: the same bill twice).
  IncomingInvoice? samePaidBefore(IncomingInvoice i) => toPay
      .where(
        (p) =>
            p.slateId != i.slateId &&
            p.state.paid &&
            p.state != PayState.cancelled &&
            addressKey(p.senderAddress) == addressKey(i.senderAddress) &&
            p.amount == i.amount &&
            now.difference(p.answeredAt ?? p.receivedAt) < const Duration(hours: 48),
      )
      .firstOrNull;
}

/// What Request a payment hands over.
@immutable
class PaymentRequestDraft {
  const PaymentRequestDraft({required this.payerAddress, required this.amount, this.message, this.payerName});

  /// The payer's invoice address.
  final String payerAddress;
  final String? payerName;
  final int amount;
  final String? message;
}

/// What a notice about an invoice says, as the wallet learns it (drains, the listener, sweeps):
/// the screens word it (flow.md §3.3, §4.5). None ever says money was received for an
/// invoice this wallet pays (P-1).
enum InvoiceNoticeKind {
  /// A payer paid an invoice this wallet issued; the wallet finalized it.
  paid,

  /// The payer declined an issued invoice; the wallet withdrew it.
  declined,

  /// An issued invoice ran out of time unpaid.
  issuedExpired,

  /// The payer's wallet sent an issued invoice back: it cannot pay invoices.
  bounced,

  /// A service withdrew an invoice before the user answered it.
  withdrawn,

  /// An invoice ran out of time before the user answered it.
  expired,

  /// A payment for an invoice this install did not issue was refused (another install on
  /// the same phrase may have). Unverified: names no one.
  unknownPayment,

  /// An answer to a send this install did not make was refused. Unverified: names no one.
  unknownAnswer,
}

@immutable
class InvoiceNotice {
  const InvoiceNotice(this.kind, {required this.slateId, this.who = '', this.amount = 0});

  final InvoiceNoticeKind kind;
  final String slateId;

  /// The payer (contact name or short address) or the service (the user's label).
  final String who;
  final int amount;
}

/// Why an invoice call failed, for the screen to word ([InvoiceError]).
enum InvoiceProblem {
  wrongPassword,
  relayDown,
  nodeDown,
  notDelivered,
  alreadyAnswered,
  expired,
  onItsWay,
  cannotCheck,
  amountMismatch,

  /// The invoice's kernel is locked above the chain's tip: it cannot be paid (P-4).
  lockedAboveTip,

  /// The invoice changed from what was stored, or cannot be paid for another reason.
  invalid,
}

/// An invoice call's failure. [message] is English, for logs; screens word [problem].
class InvoiceError extends DeskError {
  const InvoiceError(this.problem, String message) : super(message, wrongPassword: problem == InvoiceProblem.wrongPassword);

  final InvoiceProblem problem;
}
