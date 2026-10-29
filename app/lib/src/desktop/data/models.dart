// SPDX-License-Identifier: Apache-2.0
/// The desktop UI's view of a wallet. Plain immutable types; the UI reads only these and the
/// [DeskWalletApi] in `api.dart`. The mock (`mock_wallet.dart`) fills them with canned data; a
/// LEPIC adapter will map `WalletService` and `models.dart` onto them later.
library;

import '../../advanced.dart';
import '../../amount.dart' show cutEpic, displayDecimals, exactDecimals, exactEpic;
import '../../models.dart' show DeviceEnding;
import '../../payment_prefs.dart';
import 'package:flutter/foundation.dart';

import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n.dart' show AppLocalizations, englishStrings, localDigits;
import '../../models.dart' show ImportConflict, ManualField, SelectionStrategy, SendOptions;
import '../../providers.dart' show defaultMinimumConfirmations;
import '../../settings.dart' show autoLockDefault;
import '../../smart_outputs.dart' show smartOutputsDefault;
import '../../ui/send_screen.dart' show normalizeAmountText;
import '../../recipient.dart' show RecipientKind, parseRecipient;
import '../../network.dart' show EpicboxRelay;
import '../../relay_directory.dart' show ServerIcon;
import '../../watch_mode.dart' show BlockWait;

export '../../models.dart' show ImportConflict, ManualField, SelectionStrategy, SendOptions, txLabelMaxLength, txTransports;
export '../../relay_directory.dart' show ServerIcon;
export '../../send_summary.dart' show SendEstimate, SendSummary;

/// Amounts are kept in nanoepic (1 EPIC = 10^8), as the wallet does.
const int nanoPerEpic = 100000000;

/// The one display rule of both apps ([displayEpic] in amount.dart): four decimals, cut off,
/// grouped, `1,234.5000`. [decimals] 8 gives the exact amount ([exactEpic]), for the places
/// where exactness is the point; other values cut to that many. [trim] and [minDecimals] are
/// kept for callers and ignored: every shown amount writes its decimals out.
String formatEpic(int nano, {int decimals = displayDecimals, bool trim = true, int minDecimals = displayDecimals}) {
  final atomic = BigInt.from(nano);
  return decimals >= exactDecimals ? exactEpic(atomic) : cutEpic(atomic, decimals);
}

/// [formatEpic] in [l]'s separators (`1.281,5261` in German): for text shown, never for a field,
/// the clipboard or a file.
String formatEpicL(AppLocalizations l, int nano, {int decimals = displayDecimals, bool trim = true, int minDecimals = displayDecimals}) =>
    localDigits(l, formatEpic(nano, decimals: decimals, trim: trim, minDecimals: minDecimals));

/// [parseEpic]'s answer for more than 8 decimals.
const int epicTooLong = -1;

/// Amount text ("12.5", "12,5") to nanoepic: null when it is not a number, [epicTooLong]
/// for more than 8 decimals.
int? parseEpic(String raw) {
  final s = raw.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  final m = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(s);
  if (m == null || (m.group(1)!.isEmpty && (m.group(2) ?? '').isEmpty)) return null;
  final frac = m.group(2) ?? '';
  if (frac.length > 8) return epicTooLong;
  return (int.tryParse(m.group(1)!.isEmpty ? '0' : m.group(1)!) ?? 0) * nanoPerEpic + (int.tryParse(frac.padRight(8, '0')) ?? 0);
}

/// An amount field's text in [l]'s language to nanoepic, as [parseEpic] answers: cleaned by
/// [normalizeAmountText] first, so "1.000" in German, where the app shows 1000 so, is refused as
/// unclear instead of read as 1, and "1,5" is 1.5 everywhere.
///
/// Throws a [LocalizedFormatException] (its `text(l)` is the field error) for an unclear or
/// negative amount.
int? parseEpicIn(AppLocalizations l, String raw) => parseEpic(
  normalizeAmountText(raw, unit: 'EPIC', groupSeparator: NumberFormat.decimalPattern(l.localeName).symbols.GROUP_SEP),
);

@immutable
class Balance {
  const Balance({
    required this.spendable,
    required this.awaitingConfirmation,
    required this.locked,
    required this.awaitingFinalization,
    this.immature = 0,
    this.minConfirmations = defaultMinimumConfirmations,
    this.reportedTotal,
  });

  final int spendable;
  final int awaitingConfirmation;

  /// Locked by unfinished sends.
  final int locked;
  final int awaitingFinalization;

  /// Mining rewards below their lock height.
  final int immature;

  /// Confirmations a coin needs to count as [spendable]: the count LEPIC worked this balance
  /// out with. Sends ask for the same, so they can spend exactly [spendable].
  final int minConfirmations;

  /// The core's total; null where none was reported (the mock, an empty Overview).
  final int? reportedTotal;

  /// The wallet's total as the core reports it (LEPIC's `WalletSummary.total`, as
  /// `epic-wallet info`): every unspent and locked output, not what awaits finalization. A
  /// pending send's change awaits finalization until the same refresh that marks its locked
  /// inputs spent confirms it, so nothing counts twice. Without the core's figure, the same
  /// sum of the parts.
  int get total => reportedTotal ?? spendable + awaitingConfirmation + locked + immature;
}

enum TxDirection { received, sent }

enum TxState {
  /// Signed by us, waiting for the other side (file or Epicbox slate out).
  waitingRecipient,

  /// Finalized and posted, not yet in a block.
  posted,

  /// In blocks, under the confirmation count.
  confirming,
  confirmed,
  cancelled,
}

enum TxMethod { epicbox, http, tor, file }

/// Who started a transaction: the sender ([payment]) or the receiver with a request ([invoice]).
enum TxFlow { payment, invoice }

/// Confirmations before a mining reward can be spent.
const int coinbaseMaturity = 1440;

enum OutputStatus { unconfirmed, confirming, unspent, immature, locked, spent }

/// The word the Outputs page shows for an output, one place.
enum OutputWord { spendable, confirming, finalizing, unpaidInvoice, immature, mining, locked, spent }

/// One coin of the balance (an output and its commitment).
@immutable
class Output {
  const Output({
    required this.commitment,
    required this.value,
    required this.status,
    this.height,
    this.confirmations = 0,
    this.confirmationsNeeded = defaultMinimumConfirmations,
    this.lockHeight,
    this.isCoinbase = false,
    this.awaitingFinalization = false,
    this.unpaidInvoice = false,
    this.hasCategory = true,
    this.mmrIndex,
    this.txId,
    this.heldBy,
  });

  final String commitment;
  final int value;
  final OutputStatus status;

  /// The linked device whose payment holds this output here (status [OutputStatus.locked]); null
  /// when a send of this wallet locks it or nothing does.
  final String? heldBy;
  final int? height;
  final int confirmations;

  /// Confirmations before it is spendable ([Balance.minConfirmations]).
  final int confirmationsNeeded;

  /// Height a mining reward unlocks at.
  final int? lockHeight;

  /// A mining reward.
  final bool isCoinbase;

  /// LEPIC's category is awaiting finalization (a send's change, a payment coming in).
  final bool awaitingFinalization;

  /// This wallet's output of an invoice it issued that is not paid yet: in no balance figure.
  final bool unpaidInvoice;

  /// LEPIC gave the output a category; a reward still being mined has none.
  final bool hasCategory;

  /// Its position in the chain's output set, once found there.
  final int? mmrIndex;

  /// The transaction that made it or, once a send locks or spends it, that send ([Tx.id]).
  final int? txId;

  /// Can be spent now.
  bool get spendable => status == OutputStatus.unspent;

  /// This output counted with [needed] confirmations (the mock, after the setting changes): one
  /// in a block is confirming below [needed] and spendable from it.
  Output withConfirmationsNeeded(int needed) => Output(
    commitment: commitment,
    value: value,
    status: (status == OutputStatus.unspent || status == OutputStatus.confirming) && height != null
        ? (confirmations >= needed ? OutputStatus.unspent : OutputStatus.confirming)
        : status,
    height: height,
    confirmations: confirmations,
    confirmationsNeeded: needed,
    lockHeight: lockHeight,
    isCoinbase: isCoinbase,
    awaitingFinalization: awaitingFinalization,
    unpaidInvoice: unpaidInvoice,
    hasCategory: hasCategory,
    mmrIndex: mmrIndex,
    txId: txId,
  );

  /// The one place: unconfirmed and awaiting finalization is finalizing; a
  /// reward without a category, mining; any other unconfirmed output, like one on chain under
  /// the confirmations needed, is confirming.
  OutputWord get word => switch (status) {
    OutputStatus.unspent => OutputWord.spendable,
    OutputStatus.confirming => OutputWord.confirming,
    OutputStatus.unconfirmed =>
      unpaidInvoice
          ? OutputWord.unpaidInvoice
          : awaitingFinalization
          ? OutputWord.finalizing
          : isCoinbase && !hasCategory
          ? OutputWord.mining
          : OutputWord.confirming,
    OutputStatus.immature => OutputWord.immature,
    OutputStatus.locked => OutputWord.locked,
    OutputStatus.spent => OutputWord.spent,
  };
}

/// A split or consolidate, finalized and posted: [txId] spent the inputs and holds the
/// change, [receivedTxId] holds the output of [amount].
@immutable
class SelfSend {
  const SelfSend({required this.txId, required this.receivedTxId, required this.amount, required this.fee, required this.inputCount, required this.outputCount});

  final int txId;
  final int receivedTxId;
  final int amount;
  final int fee;
  final int inputCount;
  final int outputCount;
}

/// The Outputs page's choices for one wallet: the strategy sends use unless Send
/// overrides it, and whether SmartOutputs splits the change.
@immutable
class OutputPrefs {
  const OutputPrefs({this.strategy = SelectionStrategy.smallest, this.smartOutputs = smartOutputsDefault});

  final SelectionStrategy strategy;
  final bool smartOutputs;

  @override
  bool operator ==(Object other) => other is OutputPrefs && strategy == other.strategy && smartOutputs == other.smartOutputs;

  @override
  int get hashCode => Object.hash(strategy, smartOutputs);
}

/// [Tx.withManual] without a contact name: the row keeps its own.
const Object _keepName = Object();

@immutable
class Tx {
  const Tx({
    required this.id,
    required this.slateId,
    required this.direction,
    required this.state,
    required this.method,
    required this.amount,
    required this.fee,
    required this.created,
    this.confirmations = 0,
    this.confirmationsNeeded = defaultMinimumConfirmations,
    this.counterparty,
    this.contactName,
    this.message,
    this.messageBySender = true,
    this.height,
    this.kernel,
    this.hasProof = false,
    this.proofSender,
    this.proofSignature,
    this.coinbase = false,
    this.otherWallet = false,
    this.unverified = false,
    this.foundByScan = false,
    this.foundDuring,
    this.datedByBlock = true,
    this.fromBackup = false,
    this.cancellable = false,
    this.notPosted = false,
    this.undelivered = false,
    this.confirmedAt,
    this.startedAt,
    this.detail,
    this.flow = TxFlow.payment,
    this.toSelf = false,
    this._key,
    this.transport,
    this.label,
    this.note,
    this.manualFields = const {},
    this.manualEditedAt,
    this.senderPosted = false,
    this.senderCancelled = false,
    this.pairingId,
    this.blockWait = BlockWait.none,
    this.credited = 0,
    this.deviceName,
    this.deviceEnding,
    this.deviceWhy,
  });

  final int id;

  /// What the transaction pays to this wallet, in nano: a send's change, a payment received.
  /// The change of a send not in a block yet counts in [Balance.awaitingFinalization].
  final int credited;

  /// The linked device that made this send: the row reads "Sent from `<device>`".
  final String? deviceName;

  /// A [deviceName] payment that did not go through, and how it ended ([TxEntry.deviceEnding]).
  final DeviceEnding? deviceEnding;

  /// The other device's code for why a payment failed there.
  final String? deviceWhy;

  /// The row's stable key as the core names it (`s:<slate>`, `k:<kernel>`, `c:<commitment>`,
  /// `l:<id>`); what labels and details are stored under.
  String get key => _key ?? (slateId.isNotEmpty ? 's:$slateId' : 'l:$id');
  final String? _key;
  final String slateId;
  final TxDirection direction;
  final TxState state;
  final TxMethod method;
  final int amount;
  final int fee;
  final DateTime created;
  final int confirmations;

  /// Confirmations before it is final and its coins spendable ([Balance.minConfirmations]).
  final int confirmationsNeeded;

  /// Address, URL or file name of the other side.
  final String? counterparty;
  final String? contactName;

  /// A split or consolidation: both sides are this wallet.
  final bool toSelf;

  /// How it came, as the core names it (`epicbox`, `http`, `tor`, `file`); null when not known,
  /// which a restored row is until the user says.
  final String? transport;

  /// The user's name for this payment; null when there is none.
  final String? label;

  /// The user's private note.
  final String? note;

  /// What the user typed rather than the chain or the wallet: [ManualField.label] when set, and
  /// on a restored row the sender, method and note. Shown as "Added by you".
  final Set<ManualField> manualFields;

  /// When the user last changed [manualFields]; null when none is set or the time is not known.
  final DateTime? manualEditedAt;
  final String? message;

  /// Whether the sender wrote [message]; false for the receiver's (an invoice issuer's).
  final bool messageBySender;
  final int? height;
  final String? kernel;
  final bool hasProof;

  /// The payment proof's sender address and the recipient's signature over it, as the core
  /// reports them; null where it has none. The proof dialog shows only what is here.
  final String? proofSender;
  final String? proofSignature;

  /// A mining reward: spendable only after [coinbaseMaturity] confirmations.
  final bool coinbase;

  /// Coins another wallet using this recovery phrase spent (a send) or received: the chain shows
  /// it and this wallet has no record. Confirmed, no counterparty, and for a send no fee known.
  final bool otherWallet;

  /// An [otherWallet] send only the node's answers show so far (no completed scan has covered
  /// its blocks yet); LEPIC clears it after the next one.
  final bool unverified;

  /// A received output a scan found with no transaction record (another copy of the seed).
  final bool foundByScan;

  /// For [foundByScan]: which scan found it; null when the core did not record that.
  final FoundDuring? foundDuring;

  /// False when [created] is the time of the scan: the block's time could not be read.
  final bool datedByBlock;

  /// A payment only an imported history backup knows: the chain was not asked about it.
  final bool fromBackup;

  /// The core allows cancelling this payment. An incoming one is cancelled only while the node has
  /// not seen it: the core asks the node and refuses otherwise. False for an issued invoice request.
  final bool cancellable;

  /// Our send, finalized but refused by the node (or never answered): stored for a repost, its
  /// outputs locked. It can still be cancelled; the core asks the node first.
  final bool notPosted;

  /// An Epicbox, HTTP or Tor send no attempt has delivered: [DeskWalletApi.resendTx] sends
  /// it again. Never set for the send being made right now.
  final bool undelivered;

  /// An incoming Epicbox payment still waiting for its sender, whose sender reports it posted
  /// the transaction, under an hour ago (the core's `senderReportsPosted`). The sender's word
  /// only: never shown as received before the chain confirms it.
  final bool senderPosted;

  /// An incoming payment (not an invoice) whose sender reports it cancelled it, not confirmed
  /// (the core's `senderCancelled`): still waiting and cleared by itself (sender_cancel.dart),
  /// or already cleared. Reads "Cancelled by the sender".
  final bool senderCancelled;

  /// Why a payment past its watch window is still not in a block (watch_mode.dart), for the
  /// note in its details.
  final BlockWait blockWait;

  /// The pairing the payment was exchanged with (the core's `TxEntry.pairingId`): it
  /// went through the contact's mailbox, or as a file sealed to it; null for any other.
  final String? pairingId;
  final DateTime? confirmedAt;

  /// When this wallet made or took in the slate; [created] becomes the block's time once it
  /// confirms (LNX2-3). Null: [created].
  final DateTime? startedAt;

  /// Why the state is what it is, when that is not obvious: where an imported transaction came
  /// from, or what the blockchain says against the older wallet.
  final String? detail;

  /// Who started it: the sender (a payment) or the receiver with a request. An incoming
  /// invoice transaction is a request this wallet sent; an outgoing one an invoice it paid
  /// (`invoices.dart` holds their states).
  final TxFlow flow;

  bool get isInvoice => flow == TxFlow.invoice;

  /// A payment a scan found with no record (the core's `TxSource.restored`): the only rows that
  /// take typed details.
  bool get restored => foundByScan;

  /// The label without surrounding blanks, or null when there is none.
  String? get labelText {
    final t = label?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// This row with the user's entries replaced; a null argument keeps the field, an empty
  /// string removes it. For the mock, which stores them beside the rows.
  /// [contactName], when given, replaces the name (null removes it).
  Tx withManual({String? label, String? counterparty, String? transport, String? note, int? editedAtUnix, Object? contactName = _keepName}) {
    String? pick(String? now, String? was) => now == null ? was : (now.isEmpty ? null : now);
    final l = pick(label, this.label), cp = pick(counterparty, this.counterparty), via = pick(transport, this.transport), n = pick(note, this.note);
    final manual = <ManualField>{
      if (l != null) ManualField.label,
      if (restored && cp != null) ManualField.counterparty,
      if (restored && via != null) ManualField.transport,
      if (restored && n != null) ManualField.note,
    };
    return Tx(
      id: id,
      slateId: slateId,
      direction: direction,
      state: state,
      method: via == null ? method : TxMethod.values.firstWhere((m) => m.name == via, orElse: () => method),
      amount: amount,
      fee: fee,
      created: created,
      confirmations: confirmations,
      confirmationsNeeded: confirmationsNeeded,
      counterparty: cp,
      contactName: identical(contactName, _keepName) ? this.contactName : contactName as String?,
      message: message,
      messageBySender: messageBySender,
      height: height,
      kernel: kernel,
      hasProof: hasProof,
      proofSender: proofSender,
      proofSignature: proofSignature,
      coinbase: coinbase,
      otherWallet: otherWallet,
      unverified: unverified,
      foundByScan: foundByScan,
      foundDuring: foundDuring,
      datedByBlock: datedByBlock,
      fromBackup: fromBackup,
      cancellable: cancellable,
      notPosted: notPosted,
      undelivered: undelivered,
      confirmedAt: confirmedAt,
      startedAt: startedAt,
      detail: detail,
      flow: flow,
      toSelf: toSelf,
      key: key,
      transport: via,
      label: l,
      note: n,
      manualFields: manual,
      manualEditedAt: manual.isEmpty ? null : (editedAtUnix == null ? manualEditedAt : DateTime.fromMillisecondsSinceEpoch(editedAtUnix * 1000)),
      senderPosted: senderPosted,
      senderCancelled: senderCancelled,
      pairingId: pairingId,
      blockWait: blockWait,
      credited: credited,
      deviceName: deviceName,
      deviceEnding: deviceEnding,
      deviceWhy: deviceWhy,
    );
  }

  /// This row counted with [needed] confirmations (the mock, after the setting changes): a
  /// payment in a block is confirming below [needed] and confirmed from it.
  Tx withConfirmationsNeeded(int needed) => Tx(
    id: id,
    slateId: slateId,
    direction: direction,
    state: (state == TxState.confirming || state == TxState.confirmed) && !coinbase && confirmations > 0
        ? (confirmations >= needed ? TxState.confirmed : TxState.confirming)
        : state,
    method: method,
    amount: amount,
    fee: fee,
    created: created,
    confirmations: confirmations,
    confirmationsNeeded: needed,
    counterparty: counterparty,
    contactName: contactName,
    message: message,
    messageBySender: messageBySender,
    height: height,
    kernel: kernel,
    hasProof: hasProof,
    proofSender: proofSender,
    proofSignature: proofSignature,
    coinbase: coinbase,
    otherWallet: otherWallet,
    unverified: unverified,
    foundByScan: foundByScan,
    foundDuring: foundDuring,
    datedByBlock: datedByBlock,
    fromBackup: fromBackup,
    cancellable: cancellable,
    notPosted: notPosted,
    undelivered: undelivered,
    confirmedAt: confirmedAt,
    startedAt: startedAt,
    detail: detail,
    flow: flow,
    toSelf: toSelf,
    key: _key,
    transport: transport,
    label: label,
    note: note,
    manualFields: manualFields,
    manualEditedAt: manualEditedAt,
    senderPosted: senderPosted,
      senderCancelled: senderCancelled,
    pairingId: pairingId,
    blockWait: blockWait,
    credited: credited,
    deviceName: deviceName,
    deviceEnding: deviceEnding,
    deviceWhy: deviceWhy,
  );

  bool get immature => coinbase && state != TxState.cancelled && confirmations > 0 && confirmations < coinbaseMaturity;

  bool get incoming => direction == TxDirection.received;
  bool get pending => state == TxState.waitingRecipient || state == TxState.posted || state == TxState.confirming;
}

/// What of [Balance.awaitingFinalization] is this wallet's own: the change of a send, and the
/// receiving side of a split or consolidation, while not in a block. The core counts the
/// change there and the coins it comes from in [Balance.locked], so it is never money waiting
/// for a sender, and Total leaves it out until the block.
int ownChangeOffChain(Iterable<Tx> txs) => txs
    .where((t) => t.height == null && t.state != TxState.cancelled && !t.coinbase && (!t.incoming || t.toSelf))
    .fold(0, (sum, t) => sum + t.credited);

/// Which scan found an output with no record: the one after a restore, or a later one.
enum FoundDuring { restore, rescan }

/// An address book entry: at most one address of each kind (RFC 0002 17.2), never a list.
/// [address], given to the constructor, goes into the field of its kind; an explicit
/// [epicbox], [http] or [tor] wins over it.
@immutable
class Contact {
  Contact({
    required this.id,
    required this.name,
    String? address,
    String? epicbox,
    String? http,
    String? tor,
    this.note,
    this.favourite = false,
    this.lastUsed,
    this.hasPicture = false,
  }) : epicbox = _blank(epicbox) ?? _ofKind(address, RecipientKind.epicbox),
       http = _blank(http) ?? _ofKind(address, RecipientKind.http),
       tor = _blank(tor) ?? _ofKind(address, RecipientKind.tor);

  static String? _blank(String? s) => s == null || s.trim().isEmpty ? null : s;

  static String? _ofKind(String? address, RecipientKind kind) {
    if (_blank(address) == null) return null;
    return parseRecipient(address!).kind == kind ? address : null;
  }

  final String id;
  final String name;
  final String? note;
  final bool favourite;
  final DateTime? lastUsed;

  /// A picture was added for the contact (the mock draws a placeholder).
  final bool hasPicture;

  /// `<key>@<relay>`.
  final String? epicbox;

  /// The wallet URL.
  final String? http;

  /// `<56 characters>.onion`.
  final String? tor;


  /// The address Send uses when nothing else says: Epicbox, else Tor, else HTTP.
  String get address => epicbox ?? tor ?? http ?? '';

  /// Every address, Epicbox, HTTP, Tor.
  List<String> get addresses => [?epicbox, ?http, ?tor];

  String? addressOf(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => epicbox,
    RecipientKind.http => http,
    RecipientKind.tor => tor,
  };

  /// The kinds this contact has an address of, Epicbox, HTTP, Tor.
  List<RecipientKind> get kinds => [
    for (final k in const [RecipientKind.epicbox, RecipientKind.http, RecipientKind.tor])
      if (addressOf(k) != null) k,
  ];

  Contact copyWith({bool? favourite, DateTime? lastUsed}) => Contact(
    id: id,
    name: name,
    epicbox: epicbox,
    http: http,
    tor: tor,
    note: note,
    favourite: favourite ?? this.favourite,
    lastUsed: lastUsed ?? this.lastUsed,
    hasPicture: hasPicture,
  );
}

enum ServiceHealth { ok, slow, down, off, checking }

/// One Epic node the wallet may use.
@immutable
class NodeServer {
  const NodeServer({
    required this.url,
    required this.label,
    this.operator,
    this.health = ServiceHealth.ok,
    this.latencyMs,
    this.height,
    this.version,
    this.own = false,
    this.icon,
    this.listedAs,
  });

  final String url;
  final String label;
  final String? operator;
  final ServiceHealth health;
  final int? latencyMs;
  final int? height;
  final String? version;

  /// Added by the user (the old "My nodes").
  final bool own;

  /// The operator's icon on the status site, or null: the tile shows initials.
  final ServerIcon? icon;

  /// The operator's name as the status site lists it (the tile's initials), or null.
  final String? listedAs;
}

/// One Epicbox relay.
@immutable
class EpicboxServer {
  const EpicboxServer({required this.domain, this.port = 443, this.operator, this.health = ServiceHealth.ok, this.latencyMs, this.icon, this.listedAs});

  final String domain;
  final int port;
  final String? operator;
  final ServiceHealth health;
  final int? latencyMs;

  /// The operator's icon on the status site, or null: the tile shows initials.
  final ServerIcon? icon;

  /// The operator's name as the status site lists it (the tile's initials), or null.
  final String? listedAs;
}

/// What the status rows and the Overview's status card show.
@immutable
class ServiceStatus {
  const ServiceStatus({
    required this.node,
    required this.nodeHealth,
    required this.nodeHeight,
    required this.epicbox,
    required this.epicboxHealth,
    required this.httpListener,
    required this.tor,
    this.httpProblem,
    this.httpProblemPort,
    this.torProgress,
    this.torProblem,
    this.torCanSend = false,
    this.torIncluded = true,
    this.torSlowStart = false,
    this.epicboxViaTor = false,
    this.epicboxBlocked = false,
    this.epicboxInstead,
    this.epicboxOwn = false,
    this.syncProgress,
    this.scanning = false,
    this.restoreScan,
    this.lastUpdate,
    this.notice,
  });

  final NodeServer node;
  final ServiceHealth nodeHealth;
  final int nodeHeight;
  final EpicboxServer epicbox;
  final ServiceHealth epicboxHealth;

  /// The HTTP listener: off, starting ([ServiceHealth.checking]), on, or failed to start or
  /// stopped by itself ([ServiceHealth.down], with [httpProblem]).
  final ServiceHealth httpListener;

  /// Why the HTTP listener is down; null otherwise. Worded at display time ([httpProblemText]).
  final HttpProblem? httpProblem;

  /// The port [httpProblem] is about.
  final int? httpProblemPort;

  /// The wallet's tor: off, connecting ([ServiceHealth.checking], with [torProgress] until
  /// connected, then publishing the onion), ready, running for sends only
  /// ([ServiceHealth.slow], with [torProblem]), or stopped by a failure ([ServiceHealth.down],
  /// with [torProblem]).
  final ServiceHealth tor;

  /// 0 to 100 while tor connects to the Tor network; null otherwise.
  final int? torProgress;

  /// Why tor is down or the onion is not published, in a few words; null otherwise.
  final String? torProblem;

  /// Tor is connected: sends to an onion work.
  final bool torCanSend;

  /// This build has the bundled tor; without it Tor cannot be turned on.
  final bool torIncluded;

  /// Tor has been connecting for a minute without progress to show: Retry is offered while
  /// it still tries.
  final bool torSlowStart;

  /// The Epicbox connection goes through Tor ([DeskWalletApi.setEpicboxOverTor] on and Tor on):
  /// it waits for tor and never goes directly, so an [epicboxHealth] of checking or down then
  /// means "Connecting via Tor".
  final bool epicboxViaTor;

  /// This network ends the TLS handshake with [epicbox] twice in a row (relay_block.dart): the
  /// relay is up, a filter on the way answers for it. Steady until a connection, a stop or a
  /// switch of relay; the state line says it and offers [epicboxInstead]. Direct only.
  final bool epicboxBlocked;

  /// The relay to offer while [epicboxBlocked] (relayInstead); null when none is left.
  final EpicboxRelay? epicboxInstead;

  /// The open wallet has its own Epicbox server (an import that kept the older app's): a
  /// change in Settings applies to this wallet only.
  final bool epicboxOwn;

  /// 0..1 while the wallet scans; null when idle.
  final double? syncProgress;

  /// A chain scan runs: the first one after a restore, or Recheck balance. Auto-lock waits for
  /// it, or an idle computer would stop a restore at every lock and never finish it.
  final bool scanning;

  /// The scan a restore or a rebuilt database still owes: null once the core says the scan
  /// from block 0 finished. Receiving and sending wait for it.
  final RestoreScan? restoreScan;
  final DateTime? lastUpdate;

  /// A one-line state the wallet is in, e.g. a database being rebuilt; null when none.
  final String? notice;
}

/// Where the scan a restore owes stands ([ServiceStatus.restoreScan]): it runs (or is about to),
/// it waits for the network (Offline, or the node does not answer), or it stopped with an error
/// or did not finish and waits for Try again ([DeskWalletApi.syncNow]).
enum RestoreScanState { running, waiting, failed }

@immutable
class RestoreScan {
  const RestoreScan(this.state, {this.percent, this.fromHeight, this.offline = false});

  final RestoreScanState state;

  /// 0 to 100 while it runs and the core has said how far; null otherwise.
  final int? percent;

  /// The height typed at Restore, while the scan from block 0 the core still owes runs after the
  /// scan from it ended (copy D1: "Funds after block N are in"); null otherwise.
  final int? fromHeight;

  /// It waits because Offline mode is on (not for a node that does not answer).
  final bool offline;
}

/// Why the HTTP listener is down: kept structured so every language words it ([httpProblemText]).
enum HttpProblem { portInUse, portUnavailable, stopped }

/// [ServiceStatus.httpProblem] in a few words: "Port 3415 in use".
String httpProblemText(AppLocalizations l, HttpProblem p, int port) => switch (p) {
  HttpProblem.portInUse => l.deskErrPortInUse(port),
  HttpProblem.portUnavailable => l.deskErrPortUnavailable(port),
  HttpProblem.stopped => l.deskErrStoppedWithError,
};

/// The Tor line of the status card and Settings › Transactions: what tor is doing now.
String torStatusLine(AppLocalizations l, ServiceStatus s) {
  if (!s.torIncluded) return l.deskErrTorMissing;
  return switch (s.tor) {
    ServiceHealth.off => l.deskTorLineOff,
    ServiceHealth.ok => l.deskTorLineReady,
    ServiceHealth.down => s.torProblem ?? l.deskErrTorStopped,
    ServiceHealth.slow => l.deskTorLineSendsWork(s.torProblem ?? l.deskErrOnionNotPublished),
    ServiceHealth.checking => s.torCanSend ? l.deskTorLinePublishing : l.deskTorLineConnecting(s.torProgress ?? 0),
  };
}

/// New wallet passwords must have at least this many characters (LEPIC refuses shorter ones).
const int minPasswordLength = 8;

/// Whether [password] is long enough for a new wallet: counted in characters (runes), as the
/// core counts them, so four emoji are four characters, not eight.
bool passwordLongEnough(String password) => password.runes.length >= minPasswordLength;

/// One step of a rescan: the core's message and, when it gives one, the percentage.
/// [finished] is set on the last step of a scan that ran to its end (not on a stopped one),
/// with what it found in [counts] when the core reports them.
@immutable
class ScanStep {
  const ScanStep(this.message, {this.percent, this.finished = false, this.counts});

  final String message;
  final int? percent;
  final bool finished;
  final ScanCounts? counts;
}

/// What a finished rescan did: outputs found on the chain, restored to the wallet, back to
/// unspent (stored as spent), unlocked (locked by a send that never completed) and deleted
/// (unconfirmed); the last two only with "Delete unconfirmed". [resumed]: it continued a
/// stopped scan, and the counts cover only that part.
@immutable
class ScanCounts {
  const ScanCounts({this.found = 0, this.restored = 0, this.revived = 0, this.unlocked = 0, this.deleted = 0, this.resumed = false});

  final int found;
  final int restored;
  final int revived;
  final int unlocked;
  final int deleted;
  final bool resumed;
}

/// The history backup record of the open wallet, for the Backup rows, the export dialog
/// and the Overview reminder.
@immutable
class HistoryBackupState {
  const HistoryBackupState({this.lastExport, this.unbacked = 0, this.reminder, this.payments = 0, this.contacts = 0, this.network = 'mainnet', this.importOffer = false});

  /// A wallet restored from its phrase that has not answered "Import a history backup?" yet:
  /// Overview offers the import, or Not now.
  final bool importOffer;

  /// The last export saved; null: never.
  final DateTime? lastExport;

  /// Payments a backup would keep that the last export does not have.
  final int unbacked;

  /// The count the Overview reminder names; null while it stays hidden (the backup reminder rule).
  final int? reminder;

  /// What an export holds now.
  final int payments, contacts;

  /// The chain's name, as in the file name (`mainnet`, `floonet`).
  final String network;
}

/// What an import of a history backup did.
@immutable
class HistoryImport {
  const HistoryImport({
    this.merged = 0,
    this.added = 0,
    this.skipped = 0,
    this.contactsAdded = 0,
    this.conflicts = const [],
    this.applied = true,
    this.replaced = 0,
    this.pairingsAdded = 0,
    this.pairingsOtherDevice = 0,
    this.notesAdded = 0,
    this.labelsAdded = 0,
    this.detailsAdded = 0,
    this.invoicesAdded = 0,
    this.starsAdded = 0,
    this.walletName,
    this.settings,
  });

  /// Payments already here that got details back.
  final int merged;

  /// Payments only the file knew, now shown as From backup.
  final int added;

  /// Records already here, unchanged.
  final int skipped;
  final int contactsAdded;

  /// Fields where the file has another value than one the user typed here. Not empty only when
  /// [applied] is false: nothing was written, and the import runs again with the user's choices.
  final List<ImportConflict> conflicts;

  /// False when [conflicts] stopped the import before anything was written.
  final bool applied;

  /// Fields the user chose the file's value for.
  final int replaced;

  /// Pairings the file brought back (RFC 10.5); of those, the ones used on another device,
  /// which wait for the user to take them over here (RFC 9.5).
  final int pairingsAdded;
  final int pairingsOtherDevice;

  /// Notes, labels, and a scan-found payment's sender or method the file filled in where this
  /// wallet had none.
  final int notesAdded;
  final int labelsAdded;
  final int detailsAdded;

  /// Invoices (issued or paid) whose outcome the file brought back.
  final int invoicesAdded;

  /// Contacts this wallet starred again.
  final int starsAdded;

  /// The wallet's name the file carries; [planDeskBackupSettings] offers it.
  final String? walletName;

  /// The settings the file carries (`backup_settings.dart`), null for a file without any;
  /// [planDeskBackupSettings] plans them.
  final Map<String, Object?>? settings;

  bool get nothingNew =>
      merged == 0 &&
      added == 0 &&
      contactsAdded == 0 &&
      replaced == 0 &&
      pairingsAdded == 0 &&
      notesAdded == 0 &&
      labelsAdded == 0 &&
      detailsAdded == 0 &&
      invoicesAdded == 0 &&
      starsAdded == 0;
}

/// Why a history backup file was refused.
enum HistoryFileProblem {
  otherWallet("Another wallet's backup"), // l10n-ok: English for tests; screens use [label]
  otherChain('Wrong network'), // l10n-ok
  notOurs('Not a history backup'), // l10n-ok
  newer('Newer file'), // l10n-ok
  damaged('File damaged'), // l10n-ok
  tooLarge('Not a history backup'); // l10n-ok

  const HistoryFileProblem(this.title);

  /// English, for tests and logs. Screens show [label].
  final String title;

  /// The title in [l]'s language.
  String label(AppLocalizations l) => switch (this) {
    otherWallet => l.deskErrHistOtherWallet,
    otherChain => l.deskErrHistOtherChain,
    notOurs || tooLarge => l.deskErrHistNotOurs,
    newer => l.deskErrHistNewer,
    damaged => l.deskErrHistDamaged,
  };
}

/// A refused history backup file: [problem]'s title, and [text] saying why.
class HistoryFileError implements Exception {
  const HistoryFileError(this.problem, this.text) : _word = null;

  /// A refusal the user reads in their language: [shown] words it, [text] keeps its English.
  HistoryFileError.l10n(this.problem, String Function(AppLocalizations l) word) : text = word(englishStrings), _word = word;

  final HistoryFileProblem problem;
  final String text;
  final String Function(AppLocalizations l)? _word;

  /// [text] in [l]'s language.
  String shown(AppLocalizations l) => _word?.call(l) ?? text;

  @override
  String toString() => text;
}

/// A wallet error, in a short sentence for the screen.
class DeskError implements Exception {
  const DeskError(this.message, {this.wrongPassword = false, this.locked = false, this.newPasswordNeeded = false, this.sameWallet, this.unbuildable = false, this.notPostedTx, this.wrongPhrase = false, this.resetUnverifiable = false})
    : _text = null;

  /// An error the user reads in their language: [text] words it when shown ([DeskError.text]),
  /// [message] keeps its English for logs.
  DeskError.l10n(String Function(AppLocalizations l) text, {this.wrongPassword = false, this.locked = false, this.newPasswordNeeded = false, this.sameWallet, this.unbuildable = false, this.notPostedTx, this.wrongPhrase = false, this.resetUnverifiable = false})
    : message = text(englishStrings),
      _text = text;

  /// English, for logs. The user reads [text].
  final String message;
  final String Function(AppLocalizations l)? _text;

  /// The message in [l]'s language; English for an error made with a plain [message].
  String text(AppLocalizations l) => _text?.call(l) ?? message;
  final bool wrongPassword;

  /// Forgot password: the phrase is not this wallet's (another wallet's, or no phrase at all).
  final bool wrongPhrase;

  /// Forgot password: the wallet's files cannot confirm any phrase (no database it used, or a
  /// damaged one), so nothing changed; a restore from the phrase is the way out.
  final bool resetUnverifiable;

  /// A restore whose phrase belongs to this listed wallet: nothing was made. The restore
  /// flow offers to open it instead.
  final WalletEntry? sameWallet;

  /// A send or split the coins at hand cannot build (change too small to split, too heavy):
  /// ask for fewer change outputs.
  final bool unbuildable;

  /// A split or consolidate stored with its outputs locked that the node did not take: the
  /// send's [Tx.id], to post again ([DeskWalletApi.repostTx]) or cancel.
  final int? notPostedTx;

  /// An import whose old password is too short for the app: it needs a new one.
  final bool newPasswordNeeded;

  /// The wallet closed (a node or Epicbox change could not reopen it): back to Unlock.
  final bool locked;

  @override
  String toString() => message;
}

@immutable
class WalletAccount {
  const WalletAccount({this.id, required this.name, required this.network, required this.folder, required this.created, this.appFolder});

  /// The registry id ([WalletEntry.id]); null in the mock.
  final String? id;
  final String name;

  /// "mainnet" or "floonet".
  final String network;
  final String folder;
  final DateTime created;

  /// Where the app keeps its settings and log; null in the mock.
  final String? appFolder;
}

enum ThemeChoice { system, dark, light }

/// Interface scales offered in Settings › Appearance, in percent (6.1.6's SCALES).
const List<int> deskScales = [90, 100, 110, 125, 150];

@immutable
class DeskSettings {
  const DeskSettings({
    this.theme = ThemeChoice.dark,
    this.scale = 100,
    this.language,
    this.helpLanguage,
    this.hideAmounts = false,
    this.directHttp = false,
    this.tor = false,
    this.publicMode = false,
    this.httpPort = 3415,
    this.httpAutostart = false,
    this.epicboxAutostart = true,
    this.torAutostart = false,
    this.autoLockMinutes = autoLockDefault,
    this.autoLockOn = true,
    this.fiat = 'USD',
    this.newLookSeen = false,
    this.internetGuideSeen = false,
    this.tourSeen = false,
    this.importWarningSeen = false,
    this.useStatusSite = true,
    this.advanced = AdvancedPrefs.none,
    this.payments = PaymentPrefs.defaults,
    this.pairingSeenAs = '',
    this.pairingClipSeen = '',
  });

  final ThemeChoice theme;

  /// The name other wallets see when this one pairs ("They will see you as"), as the phone
  /// keeps it; empty until the user gave one.
  final String pairingSeenAs;

  /// The pairing links offered once from the clipboard, or copied from this wallet, as their
  /// hashes (`PairingClipSeen.encode`): never offered again. Never the links themselves.
  final String pairingClipSeen;

  /// Interface scale in percent, one of [deskScales]: text and layout together.
  final int scale;

  /// The interface language as a code from `appLanguages` (Settings › Appearance › Language),
  /// or null to follow the computer's first language the app has, else English.
  final String? language;

  /// The language of the Help topics as a code from `appLanguages`, or null to follow the
  /// interface ([language]). Chosen with the switch at the top of Help.
  final String? helpLanguage;
  final bool hideAmounts;

  /// The HTTP listener switch: on, it runs while receiving is on. Not saved: at unlock it is
  /// what Start with the wallet says.
  final bool directHttp;
  final bool tor;

  /// Reachable "From the internet": the HTTP listener answers on all interfaces (0.0.0.0),
  /// not only this computer. Set only from the guide's explicit choice.
  final bool publicMode;

  /// The HTTP listener's port.
  final int httpPort;

  /// The HTTP listener starts at unlock. Like [publicMode] and [httpPort] it is the open
  /// wallet's own, not app-wide.
  final bool httpAutostart;

  /// Epicbox receiving starts at unlock. The open wallet's own, like [httpAutostart].
  final bool epicboxAutostart;

  /// Tor starts at unlock. The open wallet's own; [tor] alone is the now-state.
  final bool torAutostart;
  /// Auto-lock after this many minutes without a key or the mouse, one of `autoLockChoices`.
  final int autoLockMinutes;

  /// Auto-lock is on; off, the wallet locks only by Lock wallet or quitting.
  final bool autoLockOn;
  final String fiat;

  /// The one-time "new look" notice on Overview was closed.
  final bool newLookSeen;

  /// The Receive from the internet guide was shown once: From the internet then switches
  /// straight away; the guide stays behind the (?) next to it. App-wide.
  final bool internetGuideSeen;
  /// The tour was shown once (opened, closed or skipped): it does not open by itself again.
  final bool tourSeen;

  /// The warning before the first import of wallets or files was acknowledged; the dialog
  /// shows once per install.
  final bool importWarningSeen;

  /// Settings › Privacy: server health and node lists from the status site (`statusSite`), the
  /// settings file's `status.enabled` (not saved with the rest). Off, only the servers
  /// themselves are asked.
  final bool useStatusSite;

  /// Settings › Transactions: the methods Send and Receive offer and Send's first one.
  final PaymentPrefs payments;

  /// The Advanced page: which expert features show and the network mode (`advanced.dart`).
  final AdvancedPrefs advanced;

  DeskSettings copyWith({
    ThemeChoice? theme,
    int? scale,
    String? Function()? language,
    String? Function()? helpLanguage,
    bool? hideAmounts,
    bool? directHttp,
    bool? tor,
    bool? publicMode,
    int? httpPort,
    bool? httpAutostart,
    bool? epicboxAutostart,
    bool? torAutostart,
    int? autoLockMinutes,
    bool? autoLockOn,
    String? fiat,
    bool? newLookSeen,
    bool? internetGuideSeen,
    bool? tourSeen,
    bool? importWarningSeen,
    bool? useStatusSite,
    AdvancedPrefs? advanced,
    PaymentPrefs? payments,
    String? pairingSeenAs,
    String? pairingClipSeen,
  }) => DeskSettings(
    theme: theme ?? this.theme,
    scale: scale ?? this.scale,
    language: language != null ? language() : this.language,
    helpLanguage: helpLanguage != null ? helpLanguage() : this.helpLanguage,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    directHttp: directHttp ?? this.directHttp,
    tor: tor ?? this.tor,
    publicMode: publicMode ?? this.publicMode,
    httpPort: httpPort ?? this.httpPort,
    httpAutostart: httpAutostart ?? this.httpAutostart,
    epicboxAutostart: epicboxAutostart ?? this.epicboxAutostart,
    torAutostart: torAutostart ?? this.torAutostart,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    autoLockOn: autoLockOn ?? this.autoLockOn,
    fiat: fiat ?? this.fiat,
    newLookSeen: newLookSeen ?? this.newLookSeen,
    internetGuideSeen: internetGuideSeen ?? this.internetGuideSeen,
    tourSeen: tourSeen ?? this.tourSeen,
    importWarningSeen: importWarningSeen ?? this.importWarningSeen,
    useStatusSite: useStatusSite ?? this.useStatusSite,
    payments: payments ?? this.payments,
    advanced: advanced ?? this.advanced,
    pairingSeenAs: pairingSeenAs ?? this.pairingSeenAs,
    pairingClipSeen: pairingClipSeen ?? this.pairingClipSeen,
  );
}

/// What Send hands over.
@immutable
class SendRequest {
  const SendRequest({required this.method, required this.amount, this.to, this.message, this.sendAll = false, this.dandelion = true, this.allowPlainHttp = false, this.options, this.pairingId});

  final TxMethod method;
  final int amount;

  /// An Epicbox send through the mailbox of this pairing (RFC 9.1): a contact with no
  /// address, [to] null.
  final String? pairingId;

  /// Address or URL; null for a file send.
  final String? to;
  final String? message;
  final bool sendAll;

  /// Broadcast through Dandelion++ (stem first); false fluffs it at once.
  final bool dandelion;

  /// The user agreed to send over plain `http` to another computer, unencrypted.
  final bool allowPlainHttp;

  /// Strategy and change outputs, as estimated ([DeskWalletApi.estimateSend]); null keeps
  /// the wallet's default. Not over Tor: LEPIC's Tor send takes none.
  final SendOptions? options;
}

/// Whether [error] is a split the coins cannot build: retry with one change output.
bool deskSplitRefused(Object error) => error is DeskError && error.unbuildable;

sealed class SendResult {
  const SendResult();
}

final class SendDone extends SendResult {
  const SendDone(this.tx);
  final Tx tx;
}

/// A file send: the slate to give the recipient.
final class SendFileReady extends SendResult {
  const SendFileReady(this.tx, this.fileName);
  final Tx tx;
  final String fileName;
}

final class SendFailed extends SendResult {
  const SendFailed(this.message, {this.inActivity = false}) : _word = null;

  /// A failure the user reads in their language: [text] words it, [message] keeps its English.
  SendFailed.l10n(String Function(AppLocalizations l) word, {this.inActivity = false}) : message = word(englishStrings), _word = word;

  /// English, for logs and tests.
  final String message;
  final String Function(AppLocalizations l)? _word;

  /// The message in [l]'s language.
  String text(AppLocalizations l) => _word?.call(l) ?? message;

  /// The payment may exist already (waiting in Activity): sending again could pay twice.
  final bool inActivity;
}

/// A signed transaction file: the payment and where its response was written.
@immutable
class ReceivedFile {
  const ReceivedFile(this.tx, this.response);

  final Tx tx;

  /// Beside the picked file, or in the app's files folder when that folder is read-only.
  final String response;
}

/// A wallet on this computer (Unlock's select, All wallets, Switch wallet).
@immutable
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.name,
    required this.folder,
    required this.network,
    this.current = false,
    this.lastOpened,
    this.missing = false,
  });

  /// The registry id (`WalletRegistry`): `legacy-<chain>` for the first wallet, 32 hex after.
  final String id;
  final String name;
  final String folder;
  final String network;

  /// Open now, or the one Unlock opens.
  final bool current;
  final DateTime? lastOpened;

  /// Its folder is gone (moved, or a drive unplugged).
  final bool missing;
}

/// What [DeskWalletApi.removeWallet] removes.
enum WalletRemoval {
  /// The list entry only; every file stays and All wallets can add it back.
  list,

  /// The wallet's keys and database (its `lepic` folder). `wallet_data` is kept.
  delete,
}

// ---- The import wizard (DeskFeatures.importWizard).

/// Where the import wizard found an old wallet: the groups of its Find step.
enum OldWalletGroup {
  gui('Older Epic Wallet'), // l10n-ok: English for tests; screens use [label]
  cli('The epic program'), // l10n-ok
  picked('Chosen folders'); // l10n-ok

  const OldWalletGroup(this.title);

  /// English, for tests. Screens show [label].
  final String title;

  /// The group's title in [l]'s language.
  String label(AppLocalizations l) => switch (this) {
    gui => l.deskErrOldGui,
    cli => l.deskErrOldCli,
    picked => l.deskErrOldPicked,
  };
}

/// A wallet an older Epic Wallet or the epic program left on this computer. Only read: the
/// import takes its wallet.seed, never changes its folder.
@immutable
class OldWallet {
  const OldWallet({
    required this.id,
    required this.name,
    required this.folder,
    required this.group,
    this.network = 'mainnet',
    this.lastUsed,
    this.sizeBytes = 0,
    this.sameAs,
    this.inApp = false,
    this.blocked,
  });

  /// The key for [DeskWalletApi.checkOldWallet] and [DeskWalletApi.importOldWallet].
  final String id;
  final String name;
  final String folder;
  final OldWalletGroup group;

  /// "mainnet", "floonet" or "usernet".
  final String network;
  final DateTime? lastUsed;
  final int sizeBytes;

  /// "Already in the app as Savings" or "Same wallet as Everyday"; null when unique.
  final String? sameAs;

  /// [sameAs] names a wallet the app already holds.
  final bool inApp;

  /// Why it cannot be imported (a test network, links in its folder); null when it can.
  final String? blocked;

  bool get importable => blocked == null;
}

/// What a folder chosen by hand holds: wallets, or [message] saying why there are none.
@immutable
class FolderFind {
  const FolderFind({required this.folder, required this.wallets, this.message});
  final String folder;
  final List<OldWallet> wallets;
  final String? message;
}

/// Whether another program uses an old wallet's folder now.
enum OldWalletUse { free, inUse, unknown }

/// One line of an import's proof: what was done and whether it held.
@immutable
class ImportProof {
  const ImportProof(this.text, {this.ok = true}) : _word = null;

  /// A line the user reads in their language: [line] words it, [text] keeps its English.
  ImportProof.l10n(String Function(AppLocalizations l) word, {this.ok = true}) : text = word(englishStrings), _word = word;

  /// English, for tests and logs.
  final String text;
  final String Function(AppLocalizations l)? _word;
  final bool ok;

  /// The line in [l]'s language.
  String line(AppLocalizations l) => _word?.call(l) ?? text;
}

/// A wallet the import made: listed, selected, its history due from a scan at the first unlock.
@immutable
class ImportedWallet {
  const ImportedWallet({required this.id, required this.name, required this.proof, this.oldRelay, this.appRelay = '', this.newPassword = false});

  /// The new wallet's list id ([WalletEntry.id]).
  final String id;
  final String name;
  final List<ImportProof> proof;

  /// The older app's Epicbox server (`host`, or `host:port` off 443) when it is not the app's:
  /// the wallet keeps it unless [DeskWalletApi.keepOldRelay] says otherwise. Null: same server.
  final String? oldRelay;

  /// The app's Epicbox server, the other choice.
  final String appRelay;

  /// The old password was too short and the wallet got the new one typed in the wizard.
  final bool newPassword;
}
