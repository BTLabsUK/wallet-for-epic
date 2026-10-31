/// The wallet's data types, shared by the UI, [WalletService] and the LEPIC adapter.
///
/// They began as the generated types of the earlier Rust core and keep its field names, so
/// the UI and the tests did not change when the core did.
library;

import 'dart:convert';

import 'package:characters/characters.dart';

import 'recipient.dart';

/// Why a payment was cancelled.
enum CancelReason {
  /// The user cancelled it.
  user,

  /// The user released a finished send the network refused (`release_stuck_send`).
  release,

  /// Its 14-day limit passed without an answer; epic-wallet's refresh cancelled it.
  expiry,

  /// The recipient's answer came at or too near the 14-day limit, so it was cancelled
  /// instead of finished.
  lateAnswer,

  /// The send failed before it reached the recipient (the transport failed), and the core
  /// cancelled it at once.
  failed,
}

/// Which Epic chain the wallet talks to. Selects consensus parameters and default ports.
enum Chain { mainnet, floonet, usernet }

/// An address book entry: a name and at most one address of each kind (RFC 0002 17.2): an
/// Epicbox address, a Link · HTTP address (a wallet URL) and a Link · Tor address (an onion),
/// never a list. An empty `id` in `save_contact` creates a new one.
///
/// [address], given to the constructor, goes into the field of its kind as [parseRecipient]
/// reads it; an explicit [epicbox], [http] or [tor] wins over it. The address book is the
/// device's, shared by its wallets: nothing here belongs to one wallet.
class Contact {
  final String id;
  final String name;
  final String? note;

  /// `<key>@<relay>`.
  final String? epicbox;

  /// The wallet URL, `http(s)://host[:port][/path]`.
  final String? http;

  /// `<56 characters>.onion`.
  final String? tor;

  // No pairing here: the address book is shared by every wallet on the device, a pairing is
  // one wallet's. The wallet's pairing record names its contact ([PairingRecord.contactId]).

  Contact({
    required this.id,
    required this.name,
    String? address,
    String? epicbox,
    String? http,
    String? tor,
    this.note,
  }) : epicbox = _blank(epicbox) ?? _ofKind(address, RecipientKind.epicbox),
       http = _blank(http) ?? _ofKind(address, RecipientKind.http),
       tor = _blank(tor) ?? _ofKind(address, RecipientKind.tor);

  static String? _blank(String? s) => s == null || s.trim().isEmpty ? null : s;

  static String? _ofKind(String? address, RecipientKind kind) {
    if (_blank(address) == null) return null;
    return parseRecipient(address!).kind == kind ? address : null;
  }

  /// The address Send uses when nothing else says: Epicbox, else Tor, else HTTP; empty when
  /// the contact has none.
  String get address => epicbox ?? tor ?? http ?? '';

  /// Every address, in [contactKinds] order.
  List<String> get addresses => [?epicbox, ?http, ?tor];

  /// The address of [kind], or null.
  String? addressOf(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => epicbox,
    RecipientKind.http => http,
    RecipientKind.tor => tor,
  };

  /// The kinds this contact has an address of, in [contactKinds] order.
  List<RecipientKind> get kinds => [
    for (final k in contactKinds)
      if (addressOf(k) != null) k,
  ];

  /// This contact with the address of [kind] set to [value]; null removes it.
  Contact withAddress(RecipientKind kind, String? value) => Contact(
    id: id,
    name: name,
    note: note,
    epicbox: kind == RecipientKind.epicbox ? value : epicbox,
    http: kind == RecipientKind.http ? value : http,
    tor: kind == RecipientKind.tor ? value : tor,
  );

  /// This contact with another id, name or note; [clearNote] removes the note.
  Contact copyWith({
    String? id,
    String? name,
    String? note,
    bool clearNote = false,
  }) => Contact(
    id: id ?? this.id,
    name: name ?? this.name,
    note: clearNote ? null : note ?? this.note,
    epicbox: epicbox,
    http: http,
    tor: tor,
  );

  @override
  int get hashCode => Object.hash(id, name, note, epicbox, http, tor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          note == other.note &&
          epicbox == other.epicbox &&
          http == other.http &&
          tor == other.tor;
}

/// The kinds of contact address in the order a contact lists them: Epicbox, Link · HTTP,
/// Link · Tor.
const List<RecipientKind> contactKinds = [
  RecipientKind.epicbox,
  RecipientKind.http,
  RecipientKind.tor,
];

/// `amount` is the amount to send, as requested; `fee` comes on top of it.
///
/// The rest is what the send would spend and get back: [inputCount] of the wallet's outputs
/// worth [locked] (`amount + fee + change`), locked from the send until it confirms, and
/// [change] in [changeOutputs] outputs (zero when there is no change). A core that does not
/// report them leaves them zero.
class FeeEstimate {
  final BigInt amount;
  final BigInt fee;
  final int inputCount;
  final BigInt change;
  final BigInt locked;
  final int changeOutputs;

  FeeEstimate({
    required this.amount,
    required this.fee,
    this.inputCount = 0,
    BigInt? change,
    BigInt? locked,
    this.changeOutputs = 0,
  }) : change = change ?? BigInt.zero,
       locked = locked ?? BigInt.zero;

  @override
  int get hashCode =>
      amount.hashCode ^
      fee.hashCode ^
      inputCount.hashCode ^
      change.hashCode ^
      locked.hashCode ^
      changeOutputs.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeEstimate &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          fee == other.fee &&
          inputCount == other.inputCount &&
          change == other.change &&
          locked == other.locked &&
          changeOutputs == other.changeOutputs;
}

/// What a send the core cannot build from the coins at hand (change too small for the change
/// outputs asked for, too heavy) says, with [WalletErrorKind.invalidArgument].
const String sendUnbuildable = 'This send cannot be built from the coins available.';

/// What a consolidation with fewer than two spendable outputs says (LEPIC's
/// `nothingToConsolidate`), with [WalletErrorKind.invalidArgument]. Nothing was stored.
const String nothingToConsolidate = 'Nothing to consolidate: fewer than two spendable outputs.';

/// How a send chooses the outputs it spends, as `epic-wallet send --selection_strategy`.
enum SelectionStrategy {
  /// The fewest of the smallest outputs that cover amount and fee: the rest of the balance
  /// stays spendable while the send confirms. The default.
  smallest,

  /// Every spendable output: the whole balance is locked until the send confirms, and one
  /// larger output comes back. Suits sending everything.
  all,
}

/// The fewest and most outputs a send's change, or a split, may be cut into.
const int minChangeOutputs = 1;
const int maxChangeOutputs = 10;
const int minSplitOutputs = 2;
const int maxSplitOutputs = 10;

/// How a send chooses its inputs and change. Calls given none use [SendOptions.standard].
class SendOptions {
  final SelectionStrategy strategy;

  /// The outputs the change is split into, in equal parts, [minChangeOutputs] to
  /// [maxChangeOutputs]; each one adds to the fee. No change makes no change output.
  final int changeOutputs;

  const SendOptions({
    this.strategy = SelectionStrategy.smallest,
    this.changeOutputs = 1,
  });

  /// Smallest, one change output.
  static const SendOptions standard = SendOptions();

  @override
  int get hashCode => strategy.hashCode ^ changeOutputs.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendOptions &&
          strategy == other.strategy &&
          changeOutputs == other.changeOutputs;

  @override
  String toString() => 'SendOptions(${strategy.name}, $changeOutputs)';
}

/// An output's state, as `epic-wallet outputs` shows it.
enum WalletOutputStatus {
  /// Not on chain yet: change or a received output of a transaction in progress.
  unconfirmed,
  unspent,

  /// An input of a send that is not confirmed yet.
  locked,
  spent,
}

/// Where an output counts in [WalletSummary].
enum OutputCategory {
  spendable,
  awaitingConfirmation,
  awaitingFinalization,
  immature,
  locked,

  /// This wallet's output of an invoice it issued that is not paid yet: no balance figure
  /// counts it.
  unpaidInvoice,
}

/// One output (coin) of the wallet, from [WalletSession.outputs].
class WalletOutput {
  /// The Pedersen commitment, 66 lowercase hex characters.
  final String commitment;
  final BigInt value;
  final WalletOutputStatus status;

  /// Where it counts in the summary; null for a spent output and an unconfirmed coinbase.
  final OutputCategory? category;

  /// A mining reward, spendable only from [lockHeight].
  final bool isCoinbase;

  /// The height it was mined at, or for an output not on chain yet, the tip it was made at.
  final BigInt height;

  /// The first height at which it may be spent.
  final BigInt lockHeight;

  /// Its position in the chain's output set, once found there.
  final BigInt? mmrIndex;

  /// Zero while unconfirmed.
  final BigInt confirmations;

  /// The transaction that made it or, once a send locks or spends it, that send.
  final int? txId;

  const WalletOutput({
    required this.commitment,
    required this.value,
    required this.status,
    this.category,
    required this.isCoinbase,
    required this.height,
    required this.lockHeight,
    this.mmrIndex,
    required this.confirmations,
    this.txId,
  });

  @override
  int get hashCode => Object.hash(
    commitment,
    value,
    status,
    category,
    isCoinbase,
    height,
    lockHeight,
    mmrIndex,
    confirmations,
    txId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletOutput &&
          commitment == other.commitment &&
          value == other.value &&
          status == other.status &&
          category == other.category &&
          isCoinbase == other.isCoinbase &&
          height == other.height &&
          lockHeight == other.lockHeight &&
          mmrIndex == other.mmrIndex &&
          confirmations == other.confirmations &&
          txId == other.txId;
}

/// A send to the wallet itself (split or consolidate), finalized and posted.
class SelfSentTx {
  /// The outgoing transaction: it spent the inputs and holds the change outputs.
  final int txId;

  /// The incoming transaction: it holds the output of [amount].
  final int receivedTxId;
  final BigInt amount;
  final BigInt fee;

  /// How many outputs it spent.
  final int inputCount;

  /// How many outputs it made: the received one and the change.
  final int outputCount;

  const SelfSentTx({
    required this.txId,
    required this.receivedTxId,
    required this.amount,
    required this.fee,
    required this.inputCount,
    required this.outputCount,
  });

  @override
  int get hashCode =>
      Object.hash(txId, receivedTxId, amount, fee, inputCount, outputCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelfSentTx &&
          txId == other.txId &&
          receivedTxId == other.receivedTxId &&
          amount == other.amount &&
          fee == other.fee &&
          inputCount == other.inputCount &&
          outputCount == other.outputCount;
}

/// What `import_history` did.
/// Why [WalletSession.importLegacyHistory] imported nothing, or that it did.
enum LegacyHistoryStatus {
  imported,

  /// Imported before; links and dates were brought up to date.
  alreadyImported,

  /// The folder holds no wallet database.
  noHistory,

  /// A wallet of epic-wallet before 3.3 (GUI 5.3 or older), whose database is not read.
  oldFormat,

  /// The database is encrypted, damaged or not an epic-wallet database.
  unreadable,

  /// The database kept changing while it was copied: the old wallet is running.
  sourceBusy,
  tooLarge,

  /// The history belongs to a wallet with another recovery phrase.
  otherWallet,

  /// This wallet already holds a different imported history.
  otherHistory,
}

/// What [WalletSession.importLegacyHistory] did. Counts are of records, not of money.
class LegacyHistoryImport {
  final LegacyHistoryStatus status;
  final int transactions;

  /// Payments a scan had already found, now shown under the old wallet's transaction.
  final int linked;

  /// Records of the old wallet left out.
  final int skipped;

  /// Fields where the old wallet recorded another sender or method than the user typed for the
  /// payment here. Not empty only when [applied] is false: the user's choices are still to be
  /// made, and the import runs again with them (`useOldWallet`).
  final List<ImportConflict> conflicts;

  /// False while [conflicts] wait for the user's choices.
  final bool applied;

  /// Fields the user chose the old wallet's value for.
  final int replaced;

  const LegacyHistoryImport({
    required this.status,
    this.transactions = 0,
    this.linked = 0,
    this.skipped = 0,
    this.conflicts = const [],
    this.applied = true,
    this.replaced = 0,
  });

  @override
  int get hashCode =>
      status.hashCode ^
      transactions.hashCode ^
      linked.hashCode ^
      skipped.hashCode ^
      Object.hashAll(conflicts) ^
      applied.hashCode ^
      replaced.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyHistoryImport &&
          status == other.status &&
          transactions == other.transactions &&
          linked == other.linked &&
          skipped == other.skipped &&
          _listEquals(conflicts, other.conflicts) &&
          applied == other.applied &&
          replaced == other.replaced;
}

class ImportReport {
  /// Records that matched a transaction already shown and filled in its details.
  final int merged;

  /// Records with no match, now shown as imported history.
  final int added;

  /// Records already known from an earlier import.
  final int skipped;
  final int contactsAdded;

  /// Fields where the file has another value than one the user entered here (label, note, or
  /// a restored row's sender or method). Not empty only when [applied] is false: nothing was
  /// written, and the import runs again with the user's choices.
  final List<ImportConflict> conflicts;

  /// False when [conflicts] stopped the import before anything was written.
  final bool applied;

  /// Fields the user chose the file's value for.
  final int replaced;

  /// Pairings the file brought back (RFC 10.5).
  final int pairingsAdded;

  /// Of those, the ones the file says were in use on another device: they wait for
  /// [PairingApi.useImportedPairings] before this device collects for them (RFC 9.5).
  final int pairingsOtherDevice;

  /// Notes, labels, and a scan-found payment's sender or method the file filled in where
  /// this wallet had none.
  final int notesAdded;
  final int labelsAdded;
  final int detailsAdded;

  /// Invoices (issued or paid) whose outcome the file brought back.
  final int invoicesAdded;

  /// Contacts this wallet starred again.
  final int starsAdded;

  /// The wallet's name the file carries, for the app to give back where it names wallets.
  final String? walletName;

  /// The app settings the file carries (`backup_settings.dart`), for the app to apply; null
  /// for a file without any.
  final Map<String, Object?>? settings;

  const ImportReport({
    required this.merged,
    required this.added,
    required this.skipped,
    required this.contactsAdded,
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

  ImportReport copyWith({
    int? contactsAdded,
    int? starsAdded,
    int? pairingsAdded,
    int? pairingsOtherDevice,
  }) => ImportReport(
    merged: merged,
    added: added,
    skipped: skipped,
    contactsAdded: contactsAdded ?? this.contactsAdded,
    conflicts: conflicts,
    applied: applied,
    replaced: replaced,
    pairingsAdded: pairingsAdded ?? this.pairingsAdded,
    pairingsOtherDevice: pairingsOtherDevice ?? this.pairingsOtherDevice,
    notesAdded: notesAdded,
    labelsAdded: labelsAdded,
    detailsAdded: detailsAdded,
    invoicesAdded: invoicesAdded,
    starsAdded: starsAdded ?? this.starsAdded,
    walletName: walletName,
    settings: settings,
  );

  /// This report with [added] pairings, [otherDevice] of them maybe in use elsewhere too.
  ImportReport withPairings(int added, {int otherDevice = 0}) =>
      copyWith(pairingsAdded: added, pairingsOtherDevice: otherDevice);

  @override
  int get hashCode => Object.hash(
    merged,
    added,
    skipped,
    contactsAdded,
    Object.hashAll(conflicts),
    applied,
    replaced,
    pairingsAdded,
    pairingsOtherDevice,
    notesAdded,
    labelsAdded,
    detailsAdded,
    invoicesAdded,
    starsAdded,
    walletName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportReport &&
          runtimeType == other.runtimeType &&
          merged == other.merged &&
          added == other.added &&
          skipped == other.skipped &&
          contactsAdded == other.contactsAdded &&
          _listEquals(conflicts, other.conflicts) &&
          applied == other.applied &&
          replaced == other.replaced &&
          pairingsAdded == other.pairingsAdded &&
          pairingsOtherDevice == other.pairingsOtherDevice &&
          notesAdded == other.notesAdded &&
          labelsAdded == other.labelsAdded &&
          detailsAdded == other.detailsAdded &&
          invoicesAdded == other.invoicesAdded &&
          starsAdded == other.starsAdded &&
          walletName == other.walletName &&
          jsonEncode(settings) == jsonEncode(other.settings);
}

/// The longest label [WalletSession.setTxLabel] keeps, in characters.
const int txLabelMaxLength = 60;

/// The transports a user may name for a restored transaction, as LEPIC names them.
const Set<String> txTransports = {'epicbox', 'http', 'tor', 'file'};

/// A field of a transaction the user entered rather than the chain or the wallet. A label
/// fits any transaction; the others only one a scan restored ([TxSource.restored]).
enum ManualField {
  label,

  /// Who paid, typed by the user. Never verified and never used for payment proofs.
  counterparty,

  /// How it came, as LEPIC names transports: `epicbox`, `http`, `tor`, `file`.
  transport,
  note,
}

/// A field where a history file disagrees with what the user entered here.
class ImportConflict {
  /// [TxEntry.key] of the transaction, as shown before the import.
  final String key;
  final ManualField field;

  /// The value here; null when there is none.
  final String? mine;

  /// The file's value.
  final String theirs;

  /// The transaction's time and net amount (negative for a send), to show which one it is.
  final int timeUnix;
  final BigInt amount;

  const ImportConflict({
    required this.key,
    required this.field,
    this.mine,
    required this.theirs,
    required this.timeUnix,
    required this.amount,
  });

  /// What `importHistory(useBackup:)` names this conflict by.
  String get id => '$key|${field.name}';

  @override
  int get hashCode => Object.hash(key, field, mine, theirs, timeUnix, amount);

  @override
  bool operator ==(Object other) =>
      other is ImportConflict &&
      key == other.key &&
      field == other.field &&
      mine == other.mine &&
      theirs == other.theirs &&
      timeUnix == other.timeUnix &&
      amount == other.amount;
}

class ListenerEvent {
  final ListenerEventKind kind;
  final String? slateId;

  /// Local id of the transaction, for `Received`, `Repeated` and `Finalized`, when the core
  /// names it.
  final int? txId;
  final String message;

  /// For `Received`, `Finalized`, `Expired` and `Delayed`: the slate's amount (what arrived,
  /// or what we sent), in the smallest unit. `None` for every other kind.
  final BigInt? amount;

  /// For `Disconnected`: why the connection ended, as LEPIC reports it (close frame, I/O error,
  /// timeout). No secrets.
  final String? reason;

  /// For `Disconnected`: milliseconds LEPIC waits before the next attempt.
  final int? retryInMs;

  const ListenerEvent({
    required this.kind,
    this.slateId,
    this.txId,
    required this.message,
    this.amount,
    this.reason,
    this.retryInMs,
  });

  @override
  int get hashCode =>
      kind.hashCode ^
      slateId.hashCode ^
      txId.hashCode ^
      message.hashCode ^
      amount.hashCode ^
      reason.hashCode ^
      retryInMs.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListenerEvent &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          slateId == other.slateId &&
          txId == other.txId &&
          message == other.message &&
          amount == other.amount &&
          reason == other.reason &&
          retryInMs == other.retryInMs;
}

/// What the epicbox listener did.
enum ListenerEventKind {
  /// Subscribed at the relay; `message` is the address it listens on.
  connected,

  /// The connection dropped or could not be made; it retries with backoff.
  disconnected,

  /// Signed an incoming send and returned it to the sender.
  received,

  /// A payment answered before arrived again and got the same answer. Nothing changed; it is
  /// not a second payment. `txId` names the transaction from the first time.
  repeated,

  /// Finalized and posted one of our sends.
  finalized,

  /// A slate could not be handled, or the relay reported an error.
  error,

  /// The answer to one of our sends came at or too near its 14-day limit. The send was
  /// cancelled, not finished: nothing was sent and the funds are unlocked. `amount` is set.
  expired,

  /// The answer to one of our sends arrived, but the node could not be reached to check its
  /// 14-day limit, even after retrying for about 30 s. Nothing was finished yet; the epicbox
  /// server delivers it again and it finishes once the node answers. Sent once per slate
  /// per listener run.
  delayed,

  /// The listener ended; no more events follow.
  stopped,
}

/// Who can reach the HTTP listener.
enum HttpExposure {
  /// This computer only, on `127.0.0.1`.
  localOnly,

  /// Every network interface, on `0.0.0.0`, for a port forwarded from the internet. Anyone
  /// who reaches the port can send this wallet payments.
  internet,
}

enum HttpListenerEventKind {
  /// Listening on `port`.
  started,

  /// Another program holds `port`. The listener did not start; no more events follow.
  portInUse,

  /// `port` could not be listened on. The listener did not start; no more events follow.
  bindFailed,

  /// Signed a payment and answered it; `repeated` when the same payment came again and got
  /// the first answer, which is not a second payment.
  received,

  /// Refused a payment for `refusal`. Nothing was stored.
  refused,

  /// The listener stopped and its port is free; no more events follow.
  stopped,
}

/// Why the HTTP listener refused a payment.
enum HttpRefusal {
  /// The slate was checked and refused for good.
  rejected,

  /// The wallet could not take it now (locked, node unreachable, scan pending).
  unavailable,
}

/// What the HTTP listener did. Never names the sender, its address or the slate.
class HttpListenerEvent {
  final HttpListenerEventKind kind;

  /// For `started`, `portInUse` and `bindFailed`.
  final int? port;

  /// For `received`.
  final int? txId;

  /// For `received`, in the smallest unit.
  final BigInt? amount;

  /// For `received`.
  final bool repeated;

  /// For `refused`.
  final HttpRefusal? refusal;

  const HttpListenerEvent({
    required this.kind,
    this.port,
    this.txId,
    this.amount,
    this.repeated = false,
    this.refusal,
  });

  @override
  int get hashCode =>
      kind.hashCode ^
      port.hashCode ^
      txId.hashCode ^
      amount.hashCode ^
      repeated.hashCode ^
      refusal.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HttpListenerEvent &&
          kind == other.kind &&
          port == other.port &&
          txId == other.txId &&
          amount == other.amount &&
          repeated == other.repeated &&
          refusal == other.refusal;
}

/// A send over HTTP the other wallet answered and this wallet finalized.
class HttpSent {
  final int txId;
  final String slateId;

  /// The node accepted it. False: finalized and stored, but the node refused it; repost it.
  final bool posted;

  const HttpSent({
    required this.txId,
    required this.slateId,
    required this.posted,
  });

  @override
  int get hashCode => txId.hashCode ^ slateId.hashCode ^ posted.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HttpSent &&
          txId == other.txId &&
          slateId == other.slateId &&
          posted == other.posted;
}

/// What the wallet's tor did. Never names a sender, the slate or a key.
/// A TLS host that is also an onion service with the host's certificate: connections to
/// [host]:[port] through tor dial [onion]:[onionPort] instead (LEPIC's onion routes).
typedef TorOnionRoute = ({String host, int port, String onion, int onionPort});

enum TorEventKind {
  /// Starting and connecting to the Tor network, [TorEvent.progress] percent done.
  starting,

  /// Connected to the Tor network: sends to onions work from now on.
  bootstrapped,

  /// The onion is being published.
  publishing,

  /// Other wallets can reach this one at [TorEvent.onion].
  ready,

  /// Tor failed for [TorEvent.failure]. After [TorFailure.listener] or [TorFailure.keys] tor
  /// keeps running for sends; after any other `stopped` follows.
  failed,

  /// A send or resend over Tor started to reach the other wallet; up to about 150 seconds.
  sending,

  /// Signed a payment that came in over Tor and answered it.
  received,

  /// Refused a payment that came in over Tor for [TorEvent.refusal].
  refused,

  /// Tor and its listener stopped; no more events follow.
  stopped,
}

/// Why the wallet's tor is not working.
enum TorFailure {
  /// No tor binary at the path given to `startTor`.
  missing,

  /// Tor did not start, or its control port did not answer.
  start,

  /// No progress connecting: no network, or the network blocks Tor.
  network,

  /// The computer's clock is wrong.
  clock,

  /// The wallet's own listener did not start, so the onion would lead nowhere.
  listener,

  /// Tor exited after it had connected.
  stopped,

  /// The onion was not published in time.
  publish,

  /// Tor refused the onion key or published another onion.
  keys,
}

class TorEvent {
  final TorEventKind kind;

  /// For `starting`, 0 to 100.
  final int? progress;

  /// For `ready`: `<56 characters>.onion`.
  final String? onion;

  /// For `failed`.
  final TorFailure? failure;

  /// For `received`.
  final int? txId;

  /// For `received`, in the smallest unit.
  final BigInt? amount;

  /// For `received`.
  final bool repeated;

  /// For `refused`.
  final HttpRefusal? refusal;

  /// For `bootstrapped`, `publishing` and `ready`: the port of tor's SOCKS proxy on
  /// 127.0.0.1, for the app's own requests. It changes when tor restarts.
  final int? socksPort;

  const TorEvent({
    required this.kind,
    this.progress,
    this.onion,
    this.failure,
    this.txId,
    this.amount,
    this.repeated = false,
    this.refusal,
    this.socksPort,
  });

  @override
  int get hashCode =>
      kind.hashCode ^
      progress.hashCode ^
      onion.hashCode ^
      failure.hashCode ^
      txId.hashCode ^
      amount.hashCode ^
      repeated.hashCode ^
      refusal.hashCode ^
      socksPort.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TorEvent &&
          kind == other.kind &&
          progress == other.progress &&
          onion == other.onion &&
          failure == other.failure &&
          txId == other.txId &&
          amount == other.amount &&
          repeated == other.repeated &&
          refusal == other.refusal &&
          socksPort == other.socksPort;
}

enum TorStatusKind {
  /// Not started, stopped, or ended after a failure.
  off,
  starting,

  /// Sends work; the onion is not published, or could not be ([TorStatus.failure]).
  bootstrapped,
  publishing,

  /// Sends work and other wallets can reach this one at [TorStatus.onion].
  ready,
}

/// The wallet's tor now.
class TorStatus {
  final TorStatusKind kind;

  /// For `starting`, 0 to 100.
  final int? progress;

  /// For `ready`.
  final String? onion;

  /// Why the onion is not published while tor runs for sends: `listener` or `keys`.
  final TorFailure? failure;

  /// tor's SOCKS port on 127.0.0.1 while it can carry requests. It moves when tor's network
  /// is turned off and on (a refresh after a network change).
  final int? socksPort;

  const TorStatus({
    required this.kind,
    this.progress,
    this.onion,
    this.failure,
    this.socksPort,
  });

  static const off = TorStatus(kind: TorStatusKind.off);

  @override
  int get hashCode =>
      kind.hashCode ^
      progress.hashCode ^
      onion.hashCode ^
      failure.hashCode ^
      socksPort.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TorStatus &&
          kind == other.kind &&
          progress == other.progress &&
          onion == other.onion &&
          failure == other.failure &&
          socksPort == other.socksPort;
}

class NodeTip {
  final BigInt height;
  final String nodeVersion;

  /// Whether the node says it can take transactions; null for nodes that do not say (before
  /// 4.1.0), which are judged by their height alone.
  final bool? readyForTxs;

  const NodeTip({
    required this.height,
    required this.nodeVersion,
    this.readyForTxs,
  });

  @override
  int get hashCode => height.hashCode ^ nodeVersion.hashCode ^ readyForTxs.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeTip &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          nodeVersion == other.nodeVersion &&
          readyForTxs == other.readyForTxs;
}

/// Progress of `EpicWallet::refresh`. Only the last event of a successful refresh has `summary`.
class RefreshProgress {
  /// 0..=100, never falling.
  final int percent;

  /// Short, for the user: "Checking your funds", "Scanning the chain", "Up to date".
  final String message;

  /// The balances after the refresh; set on the last event only.
  final WalletSummary? summary;

  const RefreshProgress({
    required this.percent,
    required this.message,
    this.summary,
  });

  @override
  int get hashCode => percent.hashCode ^ message.hashCode ^ summary.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefreshProgress &&
          runtimeType == other.runtimeType &&
          percent == other.percent &&
          message == other.message &&
          summary == other.summary;
}

/// Progress of a scan or refresh, forwarded from epic-wallet's `StatusMessage`.
class ScanProgress {
  /// 0..=100, or `None` for messages that carry no percentage.
  final int? percent;
  final String message;
  final bool finished;

  /// What the scan did; on the `finished` event of a core that reports it, else null.
  final ScanResult? result;

  const ScanProgress({
    this.percent,
    required this.message,
    required this.finished,
    this.result,
  });

  @override
  int get hashCode => percent.hashCode ^ message.hashCode ^ finished.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanProgress &&
          runtimeType == other.runtimeType &&
          percent == other.percent &&
          message == other.message &&
          finished == other.finished;
}

/// What a completed scan did, as LEPIC counts it. [resumed]: it continued a stopped scan, and
/// the counts cover only the part scanned this time. [unlocked] and [deleted] come only with
/// `deleteUnconfirmed`.
class ScanResult {
  const ScanResult({
    this.resumed = false,
    this.found = 0,
    this.restored = 0,
    this.revived = 0,
    this.unlocked = 0,
    this.deleted = 0,
  });

  final bool resumed;

  /// Outputs found on the chain, stored before or not.
  final int found;

  /// Found but not stored; now stored, each with a received transaction.
  final int restored;

  /// Stored as spent but unspent on the chain; their transactions were cancelled.
  final int revived;

  /// Locked but on the chain; spendable again, their transactions cancelled.
  final int unlocked;

  /// Unconfirmed and not on the chain; deleted, their transactions cancelled.
  final int deleted;
}

/// A transaction slate travelling between two wallets as JSON.
class Slate {
  final String slateId;
  final String json;

  const Slate({required this.slateId, required this.json});

  @override
  int get hashCode => slateId.hashCode ^ json.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Slate &&
          runtimeType == other.runtimeType &&
          slateId == other.slateId &&
          json == other.json;
}

/// The answer to a received slate.
class ReceivedSlate extends Slate {
  /// The slate was received before: [json] is the answer given then, byte for byte, and
  /// nothing changed in the wallet. Show it as already answered, not as a second payment.
  final bool repeated;

  const ReceivedSlate({
    required super.slateId,
    required super.json,
    this.repeated = false,
  });

  @override
  int get hashCode => super.hashCode ^ repeated.hashCode;

  @override
  bool operator ==(Object other) =>
      super == other && other is ReceivedSlate && repeated == other.repeated;
}

/// Which side of the money a slate message's author is on.
enum SlateRole { sender, receiver }

/// A participant's message as the slate carries it, epic-wallet's `send --message`. It travels
/// with the slate, so the other party sees it, unlike [TxEntry.note].
class SlateMessage {
  final SlateRole role;
  final String text;

  const SlateMessage({required this.role, required this.text});

  @override
  int get hashCode => role.hashCode ^ text.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlateMessage &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          text == other.text;
}

/// The longest slate message LEPIC signs, in UTF-8 bytes; it cuts a longer one there.
const int slateMessageMaxBytes = 256;

/// The text of the first message by [role] in [messages], or null.
String? messageBy(List<SlateMessage> messages, SlateRole role) =>
    messages.where((m) => m.role == role).firstOrNull?.text;

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// How far the QR texts of a payment scanned so far got. [json] is set once every part is
/// recovered; it is the file's text, not yet read as a payment.
class QrSlateProgress {
  final bool complete;

  /// Parts recovered so far, from the plain parts and the extra ones.
  final int received;

  /// Parts of the code; 0 when no text was given.
  final int count;
  final String? json;

  const QrSlateProgress({
    required this.complete,
    required this.received,
    required this.count,
    this.json,
  });

  @override
  int get hashCode => Object.hash(complete, received, count, json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrSlateProgress &&
          complete == other.complete &&
          received == other.received &&
          count == other.count &&
          json == other.json;
}

/// A slate's header, read without touching the wallet.
class SlateInfo {
  final String slateId;
  final BigInt amount;
  final BigInt fee;
  final SlateStage stage;

  /// The parties' messages, in the order they joined. Their signatures are not checked.
  final List<SlateMessage> messages;

  const SlateInfo({
    required this.slateId,
    required this.amount,
    required this.fee,
    required this.stage,
    this.messages = const [],
  });

  @override
  int get hashCode =>
      slateId.hashCode ^
      amount.hashCode ^
      fee.hashCode ^
      stage.hashCode ^
      Object.hashAll(messages);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlateInfo &&
          runtimeType == other.runtimeType &&
          slateId == other.slateId &&
          amount == other.amount &&
          fee == other.fee &&
          stage == other.stage &&
          _listEquals(messages, other.messages);
}

/// A payment request paid from a file ([WalletSession.payRequestFile]): the answer (I2) to
/// hand back to whoever asked, who finishes and posts it.
class PaidRequestFile {
  final int txId;
  final String slateId;

  /// What the issuer receives.
  final BigInt amount;

  /// What this wallet pays on top.
  final BigInt fee;

  /// The answer slate's JSON.
  final String json;

  const PaidRequestFile({
    required this.txId,
    required this.slateId,
    required this.amount,
    required this.fee,
    required this.json,
  });

  @override
  int get hashCode => Object.hash(txId, slateId, amount, fee, json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaidRequestFile &&
          txId == other.txId &&
          slateId == other.slateId &&
          amount == other.amount &&
          fee == other.fee &&
          json == other.json;
}

/// What a slate file asks this wallet to do.
enum SlateStage {
  /// Someone sends to us: sign it with `receive_slate` and return the response.
  send,

  /// The recipient's answer to one of our sends: `finalize_and_post` it.
  response,

  /// A payment request (an invoice, I1) someone asks this wallet to pay: reviewed, then paid
  /// with [WalletSession.payRequestFile] behind the PIN, which returns the answer file.
  request,

  /// The payer's answer to a request this wallet issued (I2, or the finalized I3):
  /// `finalize_and_post` finishes and posts it, as it does a [response].
  requestAnswer,
}

/// Whose spend a transaction row is. A row of this wallet's own log is [thisWallet].
enum TxOrigin {
  thisWallet,

  /// The chain shows coins of this wallet spent that this wallet's log has no send for: another
  /// wallet using the same recovery phrase sent them. Outgoing and confirmed, the amount is the
  /// spent inputs minus the change found; the fee and the recipient are unknown.
  otherWallet,

  /// A send another device linked to this wallet made (Linked devices); [TxEntry.deviceName]
  /// says which.
  linkedDevice,
}

/// How a linked device's payment that did not go through ended, as this device's row of it
/// reads ([TxEntry.deviceEnding]).
enum DeviceEnding {
  /// The coins were released on this device (by hand, or the device was removed); the other
  /// device may still send the payment.
  releasedHere,

  /// The other device cancelled it.
  cancelled,

  /// It failed on the other device; [TxEntry.deviceWhy] says why, as a code.
  failed,

  /// It ran out of time: the other device said so, or this device's fallback did.
  expired,
}

/// One transaction: epic-wallet's log merged with the app's history archive.
class TxEntry {
  /// Stable across restores: `s:<slate>`, else `k:<kernel>`, else `c:<commit>`, else `l:<id>`.
  final String key;

  /// Local log id, used for cancel. `None` for imported records.
  final int? id;
  final String? slateId;
  final TxKind kind;
  final TxStatus status;
  final TxSource source;
  final int createdAtUnix;

  /// Best known time: the block time for restored rows when known, else `created_at_unix`.
  final int timeUnix;
  final bool confirmed;
  final BigInt? blockHeight;
  final int? blockTimeUnix;
  final BigInt amountCredited;
  final BigInt amountDebited;
  final BigInt? fee;
  final int numInputs;
  final int numOutputs;
  final String? kernelExcess;

  /// Hex commitments of the outputs this transaction created for us (receive or change).
  final List<String> outputCommits;

  /// Epicbox address or URL of the other side, when known.
  final String? counterparty;

  /// The linked device that made this send, for a row of [TxOrigin.linkedDevice]; null else.
  final String? deviceName;

  /// For a row of [TxOrigin.linkedDevice] that did not go through (status cancelled): how it
  /// ended. Null for a payment under way or confirmed.
  final DeviceEnding? deviceEnding;

  /// The other device's code for a failed payment (`notDelivered`, `refused`, `inputsSpent`,
  /// `other`); null when it gave none.
  final String? deviceWhy;

  /// What carried the slate, as LEPIC names it (`epicbox`, `file`, `http`, `tor`), when known.
  /// Not sent over the remote protocol.
  final String? transport;

  /// The user's private note. It stays on this device and in history backups.
  final String? note;

  /// The user's name for this transaction, shown as its title. Null when there is none.
  final String? label;

  /// Which fields the user entered: [label] when set, and on a restored row the sender
  /// ([counterparty]), method ([transport]) and [note] typed in its details. Shown as
  /// "Added by you"; a manual [counterparty] is never used for payment proofs.
  final Set<ManualField> manualFields;

  /// When the user last changed [manualFields] (unix seconds); null when none is set.
  final int? manualEditedAtUnix;

  /// The parties' signed slate messages, which both sides see. Empty for a restored or imported
  /// row.
  final List<SlateMessage> messages;
  final BigInt? ttlCutoffHeight;

  /// True when `cancel_transaction(id)` is allowed.
  final bool cancellable;

  /// True for a finalized send that is not confirmed and has its final transaction stored:
  /// `repost_transaction(key)` can post it to the node again.
  final bool repostable;

  /// True for an Epicbox send no attempt has delivered to the relay yet (every attempt failed,
  /// or the app was killed before the first): [WalletService.resendEpicbox] sends it again.
  /// Never true for the send being made right now.
  final bool undelivered;

  /// Why the status is what it is, when that is not obvious, e.g. an imported send that never
  /// reached the chain.
  final String? statusDetail;

  /// True for a finalized send the node refused and whose kernel was still not on chain a day
  /// of blocks after it was finalized: `release_stuck_send(key)` unlocks its funds.
  final bool releasable;

  /// When this wallet finalized the send (unix seconds), if it did.
  final int? finalizedAtUnix;

  /// For a cancelled payment: why, when known.
  final CancelReason? cancelReason;

  /// Who started it: the sender ([TxFlow.payment]) or the receiver with an invoice
  /// ([TxFlow.invoice]). Imported and restored rows are payments.
  final TxFlow flow;

  /// For a row a scan found with no record ([TxSource.restored]): which scan, when LEPIC says.
  /// Null for other rows and for entries stored before LEPIC recorded it.
  final TxFoundDuring? foundDuring;

  /// False when [timeUnix] is the time of the scan, not of the output's block (LEPIC could
  /// not read the block header). True for every other row.
  final bool datedByBlock;

  /// When the sender of this incoming Epicbox payment reported that it posted the transaction
  /// (unix seconds), while LEPIC still holds it waiting and the report is under an hour old;
  /// null otherwise. The sender's word only: [senderReportsPosted] says when to show it.
  final int? senderReportedPostedAtUnix;

  /// When the sender of this incoming payment, already answered by this wallet, reported that
  /// it cancelled it (unix seconds); null otherwise. LEPIC keeps it after the payment ends here
  /// and drops it once the payment confirms. [senderCancelled] says when to show it.
  final int? senderReportedCancelledAtUnix;

  /// The pairing this payment was exchanged with (sealed to or from it, through its mailbox
  /// or as a sealed file), as LEPIC links it; null for any other row. The row and its details
  /// name the contact by it, as a mailbox payment has no address.
  final String? pairingId;

  /// Whose spend this is; [TxOrigin.thisWallet] for everything this wallet sent or received.
  final TxOrigin origin;

  /// Hex commitments of the inputs the transaction spent, when LEPIC lists them (the rows of
  /// [TxOrigin.otherWallet]); empty otherwise.
  final List<String> spentCommits;

  /// A [TxOrigin.otherWallet] send that only the node's answers show so far: no completed scan
  /// has covered its blocks yet (LEPIC clears it after the next one). False for every other row.
  final bool unverified;

  const TxEntry({
    required this.key,
    this.id,
    this.slateId,
    required this.kind,
    required this.status,
    required this.source,
    required this.createdAtUnix,
    required this.timeUnix,
    required this.confirmed,
    this.blockHeight,
    this.blockTimeUnix,
    required this.amountCredited,
    required this.amountDebited,
    this.fee,
    required this.numInputs,
    required this.numOutputs,
    this.kernelExcess,
    required this.outputCommits,
    this.counterparty,
    this.deviceName,
    this.deviceEnding,
    this.deviceWhy,
    this.transport,
    this.note,
    this.label,
    this.manualFields = const {},
    this.manualEditedAtUnix,
    this.messages = const [],
    this.ttlCutoffHeight,
    required this.cancellable,
    required this.repostable,
    this.undelivered = false,
    this.statusDetail,
    required this.releasable,
    this.finalizedAtUnix,
    this.cancelReason,
    this.flow = TxFlow.payment,
    this.foundDuring,
    this.datedByBlock = true,
    this.senderReportedPostedAtUnix,
    this.senderReportedCancelledAtUnix,
    this.pairingId,
    this.origin = TxOrigin.thisWallet,
    this.spentCommits = const [],
    this.unverified = false,
  });

  /// This row as one the linked device [name] received (Linked devices).
  TxEntry withDeviceName(String name) => TxEntry(
    key: key,
    id: id,
    slateId: slateId,
    kind: kind,
    status: status,
    source: source,
    createdAtUnix: createdAtUnix,
    timeUnix: timeUnix,
    confirmed: confirmed,
    blockHeight: blockHeight,
    blockTimeUnix: blockTimeUnix,
    amountCredited: amountCredited,
    amountDebited: amountDebited,
    fee: fee,
    numInputs: numInputs,
    numOutputs: numOutputs,
    kernelExcess: kernelExcess,
    outputCommits: outputCommits,
    counterparty: counterparty,
    deviceName: name,
    deviceEnding: deviceEnding,
    deviceWhy: deviceWhy,
    transport: transport,
    note: note,
    label: label,
    manualFields: manualFields,
    manualEditedAtUnix: manualEditedAtUnix,
    messages: messages,
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    undelivered: undelivered,
    statusDetail: statusDetail,
    releasable: releasable,
    finalizedAtUnix: finalizedAtUnix,
    cancelReason: cancelReason,
    flow: flow,
    foundDuring: foundDuring,
    datedByBlock: datedByBlock,
    senderReportedPostedAtUnix: senderReportedPostedAtUnix,
    senderReportedCancelledAtUnix: senderReportedCancelledAtUnix,
    pairingId: pairingId,
    origin: origin,
    spentCommits: spentCommits,
    unverified: unverified,
  );

  /// A request this wallet sent: an invoice it issued, paid or not. LEPIC keeps it as an
  /// incoming transaction like a signed receive.
  bool get isRequest =>
      flow == TxFlow.invoice &&
      (kind == TxKind.received || kind == TxKind.receivedCancelled);

  /// A request this wallet sent that the payer has not paid yet: LEPIC still holds it as
  /// received, the only state in which it can be cancelled.
  bool get awaitingPayer =>
      isRequest &&
      status == TxStatus.awaitingConfirmation &&
      cancellable &&
      blockHeight == null;

  @override
  int get hashCode =>
      key.hashCode ^
      id.hashCode ^
      slateId.hashCode ^
      kind.hashCode ^
      status.hashCode ^
      source.hashCode ^
      createdAtUnix.hashCode ^
      timeUnix.hashCode ^
      confirmed.hashCode ^
      blockHeight.hashCode ^
      blockTimeUnix.hashCode ^
      amountCredited.hashCode ^
      amountDebited.hashCode ^
      fee.hashCode ^
      numInputs.hashCode ^
      numOutputs.hashCode ^
      kernelExcess.hashCode ^
      outputCommits.hashCode ^
      counterparty.hashCode ^
      deviceName.hashCode ^
      deviceEnding.hashCode ^
      deviceWhy.hashCode ^
      transport.hashCode ^
      note.hashCode ^
      label.hashCode ^
      Object.hashAllUnordered(manualFields) ^
      manualEditedAtUnix.hashCode ^
      Object.hashAll(messages) ^
      ttlCutoffHeight.hashCode ^
      cancellable.hashCode ^
      repostable.hashCode ^
      undelivered.hashCode ^
      statusDetail.hashCode ^
      releasable.hashCode ^
      finalizedAtUnix.hashCode ^
      cancelReason.hashCode ^
      flow.hashCode ^
      foundDuring.hashCode ^
      datedByBlock.hashCode ^
      senderReportedPostedAtUnix.hashCode ^
      senderReportedCancelledAtUnix.hashCode ^
      pairingId.hashCode ^
      origin.hashCode ^
      Object.hashAll(spentCommits) ^
      unverified.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxEntry &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          id == other.id &&
          slateId == other.slateId &&
          kind == other.kind &&
          status == other.status &&
          source == other.source &&
          createdAtUnix == other.createdAtUnix &&
          timeUnix == other.timeUnix &&
          confirmed == other.confirmed &&
          blockHeight == other.blockHeight &&
          blockTimeUnix == other.blockTimeUnix &&
          amountCredited == other.amountCredited &&
          amountDebited == other.amountDebited &&
          fee == other.fee &&
          numInputs == other.numInputs &&
          numOutputs == other.numOutputs &&
          kernelExcess == other.kernelExcess &&
          outputCommits == other.outputCommits &&
          counterparty == other.counterparty &&
          deviceName == other.deviceName &&
          deviceEnding == other.deviceEnding &&
          deviceWhy == other.deviceWhy &&
          transport == other.transport &&
          note == other.note &&
          label == other.label &&
          manualFields.length == other.manualFields.length &&
          manualFields.containsAll(other.manualFields) &&
          manualEditedAtUnix == other.manualEditedAtUnix &&
          _listEquals(messages, other.messages) &&
          ttlCutoffHeight == other.ttlCutoffHeight &&
          cancellable == other.cancellable &&
          repostable == other.repostable &&
          undelivered == other.undelivered &&
          statusDetail == other.statusDetail &&
          releasable == other.releasable &&
          finalizedAtUnix == other.finalizedAtUnix &&
          cancelReason == other.cancelReason &&
          flow == other.flow &&
          foundDuring == other.foundDuring &&
          datedByBlock == other.datedByBlock &&
          senderReportedPostedAtUnix == other.senderReportedPostedAtUnix &&
          senderReportedCancelledAtUnix == other.senderReportedCancelledAtUnix &&
          pairingId == other.pairingId &&
          origin == other.origin &&
          _listEquals(spentCommits, other.spentCommits) &&
          unverified == other.unverified;
}

/// [tx] is "to be posted elsewhere": a send finalized and not posted ([TxEntry.repostable]:
/// LEPIC stores it so, as one the node refused, when Kill switch finalizes it without a node)
/// while [killSwitch] holds every connection, so the finished payment is saved or shown to
/// post it from a device that is online. Out of Kill switch the wallet posts it itself (the
/// desktop's `Tx.notPosted` is the same flag).
bool toPostElsewhere(TxEntry tx, {required bool killSwitch}) => killSwitch && tx.repostable && !tx.confirmed;

/// A finished payment (a send finalized and not posted) read without posting it: what
/// "Post a finished payment" shows before it posts ([WalletSession.inspectFinished]).
class FinishedPayment {
  const FinishedPayment({required this.slateId, required this.amount, required this.fee, this.kernelExcess});

  final String slateId;
  final BigInt amount;
  final BigInt fee;
  final String? kernelExcess;

  @override
  bool operator ==(Object other) =>
      other is FinishedPayment && other.slateId == slateId && other.amount == amount && other.fee == fee && other.kernelExcess == kernelExcess;

  @override
  int get hashCode => Object.hash(slateId, amount, fee, kernelExcess);
}

/// How long a sender's posted report shows, as LEPIC keeps it.
const senderReportWindow = Duration(hours: 1);

/// Whether [tx] shows that its sender reports it posted: an incoming Epicbox payment (not a
/// request) still waiting for its sender, with a report under [senderReportWindow] old at
/// [now]. Advisory: the payment counts only once the chain confirms it, and then this is false.
/// Link (HTTP, Tor) and Direct (QR Payment, File Transfer) payments never show it.
bool senderReportsPosted(TxEntry tx, {required DateTime now}) {
  final at = tx.senderReportedPostedAtUnix;
  if (at == null) return false;
  if (tx.kind != TxKind.received || tx.isRequest || tx.transport != 'epicbox') return false;
  if (tx.status != TxStatus.awaitingConfirmation || tx.blockHeight != null) return false;
  return now.difference(DateTime.fromMillisecondsSinceEpoch(at * 1000)) < senderReportWindow;
}

/// Whether [tx] is an incoming payment (not a request) whose sender reported that it cancelled
/// it, and which has not confirmed: still waiting here ([senderCancelPending]) or already
/// released. Reads "Cancelled by the sender".
bool senderCancelled(TxEntry tx) =>
    tx.senderReportedCancelledAtUnix != null &&
    !tx.isRequest &&
    (tx.kind == TxKind.received || tx.kind == TxKind.receivedCancelled) &&
    tx.status != TxStatus.confirmed &&
    !tx.confirmed &&
    tx.blockHeight == null;

/// [senderCancelled] and still waiting for its sender here: the app releases it by itself
/// (sender_cancel.dart), and Cancel is offered at once, without [receiveCancelHold].
bool senderCancelPending(TxEntry tx) =>
    senderCancelled(tx) && tx.kind == TxKind.received && tx.status == TxStatus.awaitingConfirmation;

/// How long after this wallet signs an incoming payment its Cancel stays out of the way. The
/// sender finalizes and posts in that time, and this wallet, having returned its signature,
/// cannot stop it: a cancel then would only mislead. Nothing of this wallet's is locked
/// meanwhile, so waiting costs nothing. After the hold, Cancel is there to clear a payment the
/// sender never posted; LEPIC asks the node first either way and refuses one the network has.
const receiveCancelHold = Duration(minutes: 15);

/// Where Cancel stands for an incoming payment this wallet signed ([TxEntry.createdAtUnix] is
/// the moment it took the payment in and returned its half). Pure: the screens read it with
/// their clock. See [incomingCancelOf].
class IncomingCancel {
  const IncomingCancel({
    required this.signedAgo,
    required this.holdLeft,
    required this.senderReportsPosted,
    this.senderCancelled = false,
  });

  /// How long ago this wallet signed, never negative.
  final Duration signedAgo;

  /// What is left of [receiveCancelHold]; zero once it is over.
  final Duration holdLeft;

  /// The sender reports it posted ([senderReportsPosted]): while that report stands, Cancel is
  /// not offered, as the payment is most likely on its way to a block.
  final bool senderReportsPosted;

  /// The sender reports it cancelled the payment ([senderCancelPending]): Cancel is offered at
  /// once, as an ordinary button, whatever the hold and the posted report say.
  final bool senderCancelled;

  /// Whether the screen offers Cancel: the sender cancelled, or the hold is over and no sender
  /// report of a post stands.
  bool get offered => senderCancelled || (holdLeft == Duration.zero && !senderReportsPosted);

  /// Whole minutes of the hold left, at least 1 while any is left, for a "becomes possible in
  /// N minutes" line.
  int get holdMinutesLeft => holdLeft == Duration.zero ? 0 : (holdLeft.inSeconds / 60).ceil();
}

/// [IncomingCancel] for [tx] at [now]. For a payment that is not an incoming one still waiting
/// for its sender ([TxKind.received], no block, not a request) Cancel is simply offered, so
/// callers keep the other rules (LEPIC's `cancellable`, invoices) in one place.
IncomingCancel incomingCancelOf(TxEntry tx, {required DateTime now}) {
  final waitingSender = tx.kind == TxKind.received &&
      !tx.isRequest &&
      tx.status == TxStatus.awaitingConfirmation &&
      tx.blockHeight == null;
  if (!waitingSender) {
    return const IncomingCancel(signedAgo: Duration.zero, holdLeft: Duration.zero, senderReportsPosted: false);
  }
  return incomingCancelAt(
    signedAt: DateTime.fromMillisecondsSinceEpoch(tx.createdAtUnix * 1000),
    now: now,
    senderReportsPosted: senderReportsPosted(tx, now: now),
    senderCancelled: senderCancelPending(tx),
  );
}

/// [IncomingCancel] for a payment signed at [signedAt], for screens whose rows keep the time
/// and the sender's report but not the entry (the desktop's `Tx`).
IncomingCancel incomingCancelAt({
  required DateTime signedAt,
  required DateTime now,
  required bool senderReportsPosted,
  bool senderCancelled = false,
}) {
  var ago = now.difference(signedAt);
  if (ago.isNegative) ago = Duration.zero;
  final left = receiveCancelHold - ago;
  return IncomingCancel(
    signedAgo: ago,
    holdLeft: left.isNegative ? Duration.zero : left,
    senderReportsPosted: senderReportsPosted,
    senderCancelled: senderCancelled,
  );
}

/// Which scan found an output with no record (LEPIC `FoundDuring`).
enum TxFoundDuring {
  /// The first scan after a restore from the recovery phrase: the wallet held it before.
  restore,

  /// Any later scan (a balance recheck), or the first scan of a new wallet.
  rescan,
}

enum TxKind { coinbase, received, sent, receivedCancelled, sentCancelled }

/// Which side started a transaction. With [TxKind] it tells the four kinds apart: an
/// incoming payment was received and an outgoing one sent; an incoming invoice was issued by
/// this wallet (a request) and an outgoing one paid by it.
enum TxFlow { payment, invoice }

/// Where a transaction row comes from.
enum TxSource {
  /// Made by this wallet (live in epic-wallet's log).
  wallet,

  /// Rebuilt by a scan from an unspent output; details beyond amount and height are unknown.
  restored,

  /// From an imported history file, with no live row in this wallet.
  imported,
}

/// Where a transaction stands, as far as this wallet can tell.
enum TxStatus {
  /// Our send, not yet signed by the recipient (not finalized).
  awaitingRecipient,

  /// Finalized send, or a receive we signed, not yet seen on chain.
  awaitingConfirmation,
  confirmed,
  cancelled,
}

/// Everything needed to locate a wallet on disk and reach its node and epicbox relay.
class WalletConfig {
  /// Directory owned by this wallet. The wallet creates `wallet_data/` inside it.
  final String dataDir;
  final Chain chain;

  /// Node base URL, e.g. `https://node.example.org` or `http://127.0.0.1:<port>`.
  final String nodeUrl;

  /// Basic-auth secret (user `epic`) sent with every node request. Optional: public nodes need
  /// none. With owner access the node's own sync status gates a refresh; without it the core
  /// judges sync from the foreign API tip (see `core/node.rs`).
  final String? nodeApiSecret;

  /// Epicbox relay domain used for the wallet's address, e.g. `epicbox.example.org`.
  final String epicboxDomain;
  final int epicboxPort;

  /// The wallet's id in the desktop wallet registry. Null for the single wallet of a phone and
  /// for registry wallet 1 of 0.1.0 (`legacy-<chain>`), whose store keys keep the old prefix.
  final String? walletId;

  const WalletConfig({
    required this.dataDir,
    required this.chain,
    required this.nodeUrl,
    this.nodeApiSecret,
    required this.epicboxDomain,
    required this.epicboxPort,
    this.walletId,
    this.offline = false,
  });

  /// Kill switch: the session refuses its node and relay at once (LEPIC's `WalletConfig.offline`
  /// once the pinned LEPIC has it, [walletOfflineSessions]); cold File and QR payments use the
  /// last confirmed tip and finalizing stores without posting. Entering or leaving Kill switch
  /// opens the session again.
  final bool offline;

  WalletConfig withOffline(bool on) => WalletConfig(
    dataDir: dataDir,
    chain: chain,
    nodeUrl: nodeUrl,
    nodeApiSecret: nodeApiSecret,
    epicboxDomain: epicboxDomain,
    epicboxPort: epicboxPort,
    walletId: walletId,
    offline: on,
  );

  @override
  int get hashCode =>
      walletId.hashCode ^
      dataDir.hashCode ^
      chain.hashCode ^
      nodeUrl.hashCode ^
      nodeApiSecret.hashCode ^
      epicboxDomain.hashCode ^
      epicboxPort.hashCode ^
      offline.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletConfig &&
          runtimeType == other.runtimeType &&
          dataDir == other.dataDir &&
          walletId == other.walletId &&
          chain == other.chain &&
          nodeUrl == other.nodeUrl &&
          nodeApiSecret == other.nodeApiSecret &&
          epicboxDomain == other.epicboxDomain &&
          epicboxPort == other.epicboxPort &&
          offline == other.offline;
}

/// The single error type every API call returns. Dart receives it as a thrown exception.
class WalletError implements Exception {
  final WalletErrorKind kind;
  final String message;

  const WalletError({required this.kind, required this.message});

  @override
  int get hashCode => kind.hashCode ^ message.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletError &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          message == other.message;

  @override
  String toString() => 'WalletError(${kind.name}): $message';
}

enum WalletErrorKind {
  invalidMnemonic,
  wrongPassword,
  walletAlreadyExists,
  walletNotFound,
  nodeUnreachable,
  notEnoughFunds,
  invalidSlate,
  invalidArgument,

  /// The epicbox relay or the recipient's HTTP listener could not be reached, or refused.
  transportFailed,

  /// No pending invoice has the id given to pay or decline: it was paid, declined, withdrawn
  /// or has expired. Nothing was changed.
  invoiceNotFound,

  /// The amount given to pay an invoice is not the invoiced amount. Nothing was paid.
  amountMismatch,

  /// The invoice was paid already (here, or its answer was stored). Nothing more was paid.
  invoiceAlreadyPaid,

  /// The invoice's kernel is locked until a block above the chain's tip; it cannot be paid.
  /// Nothing was stored.
  invoiceLockedAboveTip,

  /// The invoice or its answer differs from what was stored for it. Nothing was paid.
  invoiceChanged,

  /// The invoice's time limit (or height) does not fit this chain: made on another network, or
  /// by a wallet whose node is far off. Nothing was paid.
  invoiceNotForThisChain,

  /// A wallet is still open on another network, or a call on this wallet is still running
  /// (network switch, delete). Waiting a moment and trying again usually works.
  chainBusy,

  /// A call on this wallet is still running, or the wallet is being deleted. `delete_wallet`
  /// returns it after waiting 20 s. Trying again in a moment usually works.
  walletBusy,

  /// The network mode refused the connection (Node only, Kill switch): LEPIC's own gate.
  networkOff,

  /// The recipient answered at or too near the payment's 14-day limit. The payment was
  /// cancelled instead of finished: nothing was sent and the funds are unlocked.
  paymentExpired,

  /// The wallet was rebuilt from its phrase (a restore, or a damaged database) and the scan
  /// from block 0 has not finished yet: no new output key is handed out, so receiving, sending
  /// and invoices are refused until it does. A scan with no start height finishes it.
  restoreScanRequired,

  /// [WalletService.resetPassword] was given a valid phrase of another wallet: nothing changed.
  phraseMismatch,

  /// The wallet database was damaged; the core set it aside. Opening the wallet again rebuilds
  /// it, then a scan brings the funds back. History, labels and messages are not in the new one.
  damagedDatabase,

  /// The address given to an HTTP send is not an `http(s)://host[:port][/path]` URL, or
  /// names a `.onion` host. Nothing was stored.
  httpUrlInvalid,

  /// Plain `http` to another computer without the user's consent. Nothing was stored.
  plainHttpNotAllowed,

  /// The address given to a Tor send is not an onion v3 address, or has a typo. Nothing was
  /// stored.
  onionAddressInvalid,

  /// The wallet's tor is not running or not yet connected. Before the send nothing was
  /// stored; when tor stopped during the delivery the send is stored and waits.
  torNotRunning,

  /// The other wallet is not online with Tor on, or was not reached in time. The send is
  /// stored and waits with its inputs locked: resend it later or cancel it.
  onionUnreachable,

  /// A scanned text is not a payment QR at all (an address, a link, a number).
  notQrSlate,

  /// A scanned text is a QR code of another kind of data than a payment.
  foreignQrCode,

  /// Scanned parts belong to two different payments.
  mixedQrCodes,

  /// A payment QR that is damaged or from a newer version.
  invalidQrCode,

  /// A payment QR that holds more than the wallet accepts.
  qrCodeTooLarge,

  /// A pairing step did not go through; the message is a [PairingFailure] name.
  pairingFailed,

  /// Posting a send failed because the chain shows its inputs already spent: another wallet
  /// using the same recovery phrase spent them. The send is released; a refresh follows.
  inputsSpentElsewhere,

  /// Posting failed because another payment of this wallet that is on chain already spent its
  /// coins: a cancelled payment that went through after all (a spend back refused), or a spend
  /// back that won (the cancelled payment's late post refused). It is ended; a refresh follows.
  inputsSpentByOwnPayment,

  /// Posting failed because the other party's coins in it are already spent: on the receiving
  /// side, a payment its payer cancelled and spent back. It is ended.
  peerInputsSpent,
  io,
  other,
}

/// The key part of an epicbox address, before `@`. Services are matched on it alone: the
/// relay checks the signature with the key, never the domain, so the domain proves nothing.
String epicboxKey(String address) => address.trim().split('@').first;

/// The longest an invoice may stay open (UP-14); the default is 24 h. One that asks for more
/// is dropped.
const Duration maxInvoiceExpiry = Duration(hours: 48);

/// An invoice from a paired contact the user allows, parked until the user approves or
/// declines it. Nothing pays it but a call the user makes after the PIN or biometric gate.
class PendingInvoice {
  final String slateId;

  /// The address the invoice came from, for display only: its sender is [pairingId].
  final String senderAddress;

  /// The pairing whose key signed it (RFC 11.2); its record names the sender. Null only on a
  /// core without pairing.
  final String? pairingId;

  /// What the contact says the request is for (a deposit reference), untrusted like
  /// [message].
  final String? reference;

  /// What the service asks for, in the smallest unit. Paying needs this exact amount.
  final BigInt amount;

  /// The service's message: untrusted text. Render it as one plain line, never as a link.
  final String? message;
  final DateTime receivedAt;

  /// After this the invoice is gone and cannot be paid.
  final DateTime expiresAt;

  const PendingInvoice({
    required this.slateId,
    required this.senderAddress,
    required this.amount,
    this.message,
    required this.receivedAt,
    required this.expiresAt,
    this.pairingId,
    this.reference,
  });

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// Time left at [now], never negative.
  Duration timeLeftAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  int get hashCode =>
      slateId.hashCode ^
      senderAddress.hashCode ^
      amount.hashCode ^
      message.hashCode ^
      receivedAt.hashCode ^
      expiresAt.hashCode ^
      pairingId.hashCode ^
      reference.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingInvoice &&
          slateId == other.slateId &&
          senderAddress == other.senderAddress &&
          amount == other.amount &&
          message == other.message &&
          receivedAt == other.receivedAt &&
          expiresAt == other.expiresAt &&
          pairingId == other.pairingId &&
          reference == other.reference;
}

/// Where an invoice the user approved stands.
enum InvoiceStatus {
  /// Signed and stored, but the reply did not reach the service. Resend it; the user does
  /// not approve again.
  replyFailed,

  /// The reply reached the relay; the service finalizes and posts it.
  replied,

  /// The service reports it posted the payment (a receipt, with the kernel excess). It
  /// informs only: confirmation comes from the chain.
  posted,

  /// The service withdrew the invoice after the user paid it. Offer a cancel the user
  /// confirms; never cancel on its own.
  withdrawn,
}

/// An invoice the user approved, as a transaction's details show it.
class PaidInvoice {
  final String slateId;
  final String senderAddress;

  /// The pairing that sent the invoice, as on [PendingInvoice.pairingId].
  final String? pairingId;
  final String? reference;
  final BigInt amount;
  final String? message;
  final InvoiceStatus status;

  /// Local id of the payment, for `cancelTransaction`.
  final int? txId;

  /// From the `posted` receipt.
  final String? kernelExcess;

  const PaidInvoice({
    required this.slateId,
    required this.senderAddress,
    required this.amount,
    this.message,
    required this.status,
    this.txId,
    this.kernelExcess,
    this.pairingId,
    this.reference,
  });

  PaidInvoice withStatus(InvoiceStatus status, {String? kernelExcess}) =>
      PaidInvoice(
        slateId: slateId,
        senderAddress: senderAddress,
        pairingId: pairingId,
        reference: reference,
        amount: amount,
        message: message,
        status: status,
        txId: txId,
        kernelExcess: kernelExcess ?? this.kernelExcess,
      );

  @override
  int get hashCode =>
      slateId.hashCode ^
      senderAddress.hashCode ^
      amount.hashCode ^
      message.hashCode ^
      status.hashCode ^
      txId.hashCode ^
      kernelExcess.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaidInvoice &&
          slateId == other.slateId &&
          senderAddress == other.senderAddress &&
          amount == other.amount &&
          message == other.message &&
          status == other.status &&
          txId == other.txId &&
          kernelExcess == other.kernelExcess;
}

/// What happened to an invoice. `posted`, `declined` and `withdrawn` are the notices; they
/// inform and never move funds.
enum InvoiceEventKind {
  /// A trusted service's invoice was parked for review.
  received,

  /// Receipt: the service reports it posted a paid invoice. `kernelExcess` is set.
  posted,

  /// This wallet declined the invoice and told the service.
  declined,

  /// The service withdrew the invoice (cancelled it, or its own expiry).
  withdrawn,

  /// The invoice's time ran out before the user answered it.
  expired,

  /// The payment of an invoice this wallet does not know arrived and was refused: another
  /// install on the same recovery phrase may have issued it. Its id and sender are not
  /// verified: inform the user only, never act on it.
  unknownInvoicePayment,

  /// The answer to a send this wallet does not know arrived: another install on the same
  /// recovery phrase may have made it, and LEPIC leaves it on the relay for that one for a day.
  /// Inform only, as [unknownInvoicePayment].
  unknownSendAnswer,

  /// Another install on the same recovery phrase answered the same incoming payment and the
  /// sender completed that one, so LEPIC ended this install's receive. Its coins are on the
  /// phrase; a Recheck balance shows them here.
  receiveSuperseded,

  /// Not an invoice: the sender of an ordinary Epicbox payment this wallet answered reports
  /// that it posted the transaction (`kernelExcess` is set). Once per payment, only from its
  /// sender. Advisory: refresh now; the payment counts once the chain confirms it.
  paymentPosted,

  /// Not an invoice: the sender of a payment this wallet answered reports that it cancelled it.
  /// Only from its sender. The app releases the payment if it is still waiting
  /// (sender_cancel.dart); the node is asked first, so one already on the network stays.
  paymentCancelled,
}

class InvoiceEvent {
  final InvoiceEventKind kind;
  final String slateId;

  /// For [InvoiceEventKind.posted] and [InvoiceEventKind.paymentPosted] only.
  final String? kernelExcess;

  const InvoiceEvent({
    required this.kind,
    required this.slateId,
    this.kernelExcess,
  });

  @override
  int get hashCode => kind.hashCode ^ slateId.hashCode ^ kernelExcess.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceEvent &&
          kind == other.kind &&
          slateId == other.slateId &&
          kernelExcess == other.kernelExcess;
}

/// What one drain of the invoice address did.
class InvoiceDrainReport {
  /// Invoices from trusted services, now pending.
  final int parked;

  /// Invoice replies finalized (the issuer side; the app pays only, so 0 for now).
  final int finalized;

  /// Messages from senders not on the list, or notices from anyone but the invoice's service,
  /// dropped unread. The user is not told; Advanced shows a count.
  final int dropped;

  /// Notices accepted (receipts, withdrawals).
  final int notices;

  const InvoiceDrainReport({
    this.parked = 0,
    this.finalized = 0,
    this.dropped = 0,
    this.notices = 0,
  });

  @override
  int get hashCode =>
      parked.hashCode ^
      finalized.hashCode ^
      dropped.hashCode ^
      notices.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceDrainReport &&
          parked == other.parked &&
          finalized == other.finalized &&
          dropped == other.dropped &&
          notices == other.notices;
}

/// How long an invoice stays payable: UP-14's default day, for invoices the wallet pays and
/// the ones it issues. LEPIC's `pendingInvoices` and `sweepInvoices` take it in seconds.
const Duration invoiceExpiry = Duration(hours: 24);

/// [text] cut to at most [maxBytes] UTF-8 bytes on a character boundary, as Send cuts a
/// message, trimmed, and null when nothing is left.
String? cutMessage(String? text, {int maxBytes = slateMessageMaxBytes}) {
  final kept = StringBuffer();
  var bytes = 0;
  for (final c in (text ?? '').trim().characters) {
    final n = utf8.encode(c).length;
    if (bytes + n > maxBytes) break;
    kept.write(c);
    bytes += n;
  }
  final out = kept.toString().trim();
  return out.isEmpty ? null : out;
}

/// Where an invoice this wallet issued stands. Only [waiting] moves, and only once: every
/// other state is final.
enum IssuedInvoiceState {
  /// Sent to the payer, not paid yet. It can be withdrawn.
  waiting,

  /// The payer paid; this wallet finalized and posted the payment. Confirmation comes from
  /// the chain like any received payment.
  paid,

  /// The payer declined it, and the app withdrew it.
  declined,

  /// The user withdrew it.
  withdrawn,

  /// Its time ran out unpaid, and the wallet cancelled it.
  expired,

  /// The payer's wallet cannot pay invoices and sent it back, as a stock `epic-wallet` does;
  /// the app withdrew it. That payer can still send a payment, as a file or to the address.
  bounced,
}

/// An invoice this wallet issued: a request to the payer at [payerAddress], their invoice
/// address, to pay [amount]. Its payment arrives on the wallet's payments address. Nothing
/// about it ever pays from this wallet.
class IssuedInvoice {
  final String slateId;

  /// Local id of the invoice's transaction, for a withdrawal. Null for a request a history
  /// backup brought back: LEPIC no longer holds it, so it is shown and never acted on.
  final int? txId;
  final String payerAddress;

  /// The paired contact asked (RFC 11.2), when the engine names it; its mailbox is never
  /// shown as an address, so [payerAddress] is empty then.
  final String? pairingId;

  /// What the payer is asked for, in the smallest unit.
  final BigInt amount;

  /// The message signed into the invoice, as cut for it.
  final String? message;
  final DateTime issuedAt;

  /// When the wallet cancels it unpaid.
  final DateTime expiresAt;
  final IssuedInvoiceState state;

  const IssuedInvoice({
    required this.slateId,
    required this.txId,
    required this.payerAddress,
    required this.amount,
    this.message,
    required this.issuedAt,
    required this.expiresAt,
    required this.state,
    this.pairingId,
  });

  /// Only an unpaid, unanswered invoice this wallet still holds can be withdrawn.
  bool get withdrawable => state == IssuedInvoiceState.waiting && txId != null;

  /// Saved as a payment file for anyone ([PairingApi.requestFile]): no payer address and no
  /// paired contact.
  bool get byFile => payerAddress.isEmpty && pairingId == null;

  /// Time left at [now], never negative.
  Duration timeLeftAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  IssuedInvoice withState(IssuedInvoiceState state) => withPairing(pairingId, state: state);

  /// This invoice for the paired contact [pairingId].
  IssuedInvoice withPairing(String? pairingId, {IssuedInvoiceState? state}) => IssuedInvoice(
    slateId: slateId,
    txId: txId,
    payerAddress: payerAddress,
    pairingId: pairingId,
    amount: amount,
    message: message,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    state: state ?? this.state,
  );

  @override
  int get hashCode =>
      slateId.hashCode ^
      txId.hashCode ^
      payerAddress.hashCode ^
      pairingId.hashCode ^
      amount.hashCode ^
      message.hashCode ^
      issuedAt.hashCode ^
      expiresAt.hashCode ^
      state.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssuedInvoice &&
          slateId == other.slateId &&
          txId == other.txId &&
          payerAddress == other.payerAddress &&
          pairingId == other.pairingId &&
          amount == other.amount &&
          message == other.message &&
          issuedAt == other.issuedAt &&
          expiresAt == other.expiresAt &&
          state == other.state;
}

/// The message the receiver of the money signed into [tx]: the issuer's, in an invoice.
String? _receiverMessage(TxEntry tx) =>
    tx.messages.where((m) => m.role == SlateRole.receiver).firstOrNull?.text;

/// The request [tx] is, from LEPIC's transaction, or null when it is not one. [recorded] is
/// the state the app kept for it: an ending it learned (declined, withdrawn, bounced) wins,
/// since LEPIC says only cancelled; otherwise the transaction says waiting, paid or, once
/// cancelled, expired. The payer is LEPIC's counterparty, empty when it kept none.
IssuedInvoice? issuedInvoiceOf(TxEntry tx, {IssuedInvoiceState? recorded}) {
  final slateId = tx.slateId;
  // Only a request LEPIC made holds an id it can act on; one a history backup brought back,
  // perhaps onto a row a scan found, is shown and never acted on.
  final txId = tx.source == TxSource.wallet ? tx.id : null;
  if (!tx.isRequest || slateId == null) return null;
  if (txId == null) {
    // From a history backup: shown with the end the backup recorded, or paid when its payment
    // is on the chain (a request paid by file is settled only later). One still open when the
    // backup was made cannot be finished here; its history row says it is from a backup.
    final onChain = tx.status == TxStatus.confirmed || tx.blockHeight != null;
    if (recorded == null || recorded == IssuedInvoiceState.waiting) {
      if (!onChain || tx.status == TxStatus.cancelled) return null;
      recorded = IssuedInvoiceState.paid;
    }
  }
  final issuedAt = DateTime.fromMillisecondsSinceEpoch(tx.createdAtUnix * 1000);
  final fromTx = tx.status == TxStatus.cancelled
      ? IssuedInvoiceState.expired
      : tx.awaitingPayer
      ? IssuedInvoiceState.waiting
      : IssuedInvoiceState.paid;
  return IssuedInvoice(
    slateId: slateId,
    txId: txId,
    payerAddress: tx.counterparty ?? '',
    amount: tx.amountCredited,
    message: _receiverMessage(tx),
    issuedAt: issuedAt,
    expiresAt: issuedAt.add(invoiceExpiry),
    state: recorded == null || recorded == IssuedInvoiceState.waiting
        ? fromTx
        : recorded,
    pairingId: tx.pairingId,
  );
}

/// The requests among [txs], newest first, each with the state [recorded] gives for its slate
/// id. A cancelled one without a record is left out: the relay never took it, so it was
/// never sent; the history row still shows it.
List<IssuedInvoice> requestsOf(
  Iterable<TxEntry> txs,
  IssuedInvoiceState? Function(String? slateId) recorded,
) =>
    [
      for (final t in txs)
        if (t.status != TxStatus.cancelled || recorded(t.slateId) != null)
          ?issuedInvoiceOf(t, recorded: recorded(t.slateId)),
    ]..sort((a, b) {
      final byTime = b.issuedAt.compareTo(a.issuedAt);
      return byTime != 0 ? byTime : (b.txId ?? -1).compareTo(a.txId ?? -1);
    });

/// The invoice [tx] paid, from LEPIC's transaction, or null when it paid none. [status] and
/// [kernelExcess] are what the app recorded of the reply and the receipt; without a record
/// the reply is taken as delivered, since LEPIC stored the payment.
PaidInvoice? paidInvoiceOf(
  TxEntry tx, {
  InvoiceStatus? status,
  String? kernelExcess,
}) {
  final slateId = tx.slateId;
  final outgoing = tx.kind == TxKind.sent || tx.kind == TxKind.sentCancelled;
  if (tx.flow != TxFlow.invoice || !outgoing || slateId == null) return null;
  return PaidInvoice(
    slateId: slateId,
    senderAddress: tx.counterparty ?? '',
    amount: tx.amountDebited - tx.amountCredited - (tx.fee ?? BigInt.zero),
    message: _receiverMessage(tx),
    status: status ?? InvoiceStatus.replied,
    txId: tx.source == TxSource.wallet ? tx.id : null,
    kernelExcess: kernelExcess,
  );
}

/// What happened to an invoice this wallet issued: the state it moved to, once.
enum IssuerEventKind {
  paid,
  declined,
  withdrawn,
  expired,

  /// The payer's wallet sent it back unpaid: it cannot pay invoices. Tell the user to ask
  /// that person for a payment file instead.
  bounced,
}

/// The event an issued invoice raises on moving to [state]; none for [waiting], where every
/// invoice starts.
IssuerEventKind? issuerEventFor(IssuedInvoiceState state) => switch (state) {
  IssuedInvoiceState.waiting => null,
  IssuedInvoiceState.paid => IssuerEventKind.paid,
  IssuedInvoiceState.declined => IssuerEventKind.declined,
  IssuedInvoiceState.withdrawn => IssuerEventKind.withdrawn,
  IssuedInvoiceState.expired => IssuerEventKind.expired,
  IssuedInvoiceState.bounced => IssuerEventKind.bounced,
};

class IssuerEvent {
  final IssuerEventKind kind;
  final String slateId;

  /// The payer's invoice address, when known, so a notice can name them.
  final String? payerAddress;

  /// The paired contact asked, as on [IssuedInvoice.pairingId].
  final String? pairingId;

  const IssuerEvent({
    required this.kind,
    required this.slateId,
    this.payerAddress,
    this.pairingId,
  });

  @override
  int get hashCode => kind.hashCode ^ slateId.hashCode ^ payerAddress.hashCode ^ pairingId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssuerEvent &&
          kind == other.kind &&
          slateId == other.slateId &&
          payerAddress == other.payerAddress &&
          pairingId == other.pairingId;
}

/// What one drain of the payments address did.
class PaymentsDrainReport {
  /// Payments to this wallet signed and answered.
  final int received;

  /// Answers finalized and posted: sends of this wallet, and paid invoices it issued.
  final int finalized;

  /// Invoices this wallet issued that came back unpaid.
  final int bounced;

  const PaymentsDrainReport({
    this.received = 0,
    this.finalized = 0,
    this.bounced = 0,
  });

  @override
  int get hashCode => received.hashCode ^ finalized.hashCode ^ bounced.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentsDrainReport &&
          received == other.received &&
          finalized == other.finalized &&
          bounced == other.bounced;
}

/// Mirrors epic-wallet's `WalletInfo`.
class WalletSummary {
  final BigInt lastConfirmedHeight;
  final BigInt minimumConfirmations;
  final BigInt total;
  final BigInt spendable;
  final BigInt awaitingConfirmation;
  final BigInt awaitingFinalization;
  final BigInt immature;
  final BigInt locked;

  /// False when the refresh against the node failed and the numbers come from the local DB.
  final bool validatedWithNode;

  const WalletSummary({
    required this.lastConfirmedHeight,
    required this.minimumConfirmations,
    required this.total,
    required this.spendable,
    required this.awaitingConfirmation,
    required this.awaitingFinalization,
    required this.immature,
    required this.locked,
    required this.validatedWithNode,
  });

  WalletSummary copyWith({BigInt? minimumConfirmations}) => WalletSummary(
    lastConfirmedHeight: lastConfirmedHeight,
    minimumConfirmations: minimumConfirmations ?? this.minimumConfirmations,
    total: total,
    spendable: spendable,
    awaitingConfirmation: awaitingConfirmation,
    awaitingFinalization: awaitingFinalization,
    immature: immature,
    locked: locked,
    validatedWithNode: validatedWithNode,
  );

  @override
  int get hashCode =>
      lastConfirmedHeight.hashCode ^
      minimumConfirmations.hashCode ^
      total.hashCode ^
      spendable.hashCode ^
      awaitingConfirmation.hashCode ^
      awaitingFinalization.hashCode ^
      immature.hashCode ^
      locked.hashCode ^
      validatedWithNode.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletSummary &&
          runtimeType == other.runtimeType &&
          lastConfirmedHeight == other.lastConfirmedHeight &&
          minimumConfirmations == other.minimumConfirmations &&
          total == other.total &&
          spendable == other.spendable &&
          awaitingConfirmation == other.awaitingConfirmation &&
          awaitingFinalization == other.awaitingFinalization &&
          immature == other.immature &&
          locked == other.locked &&
          validatedWithNode == other.validatedWithNode;
}

/// Confirmations before an output counts as spendable, until a balance says otherwise: the
/// core's default (6; LEPIC ADR 0027: the old GUI counted 3, upstream's CLI 10). Each wallet
/// stores its own count, 1–30 ([WalletSession.minimumConfirmations]), and the app never counts
/// with its own number once a balance is there; see `countedConfirmationsProvider` in
/// providers.dart. It lives here, in plain Dart, so the wallet core
/// (lepic_wallet_service.dart and what it imports) builds without Flutter.
const int defaultMinimumConfirmations = 6;

/// The smallest and largest minimum confirmations a wallet accepts, as LEPIC validates them.
const int minMinimumConfirmations = 1;
const int maxMinimumConfirmations = 30;

// Pairing (LEPIC RFC 0002): two wallets pair once, then payment files and invoices between
// them are sealed. The core keeps the records; these are the app's view of them. Event and
// record fields carry ids and names, never keys or secrets (RFC 10.4).

/// Where a pairing stands (RFC 7.6, 10.2).
enum PairingState {
  /// This wallet made an invite nobody has answered yet.
  pendingInvite,

  /// This wallet answered an invite and waits for the inviter's confirm.
  pendingReply,

  /// Paired; the four words are not checked yet ("Paired, not verified").
  paired,

  /// Paired and the user confirmed the four words match.
  verified,

  /// A key check found other keys for a known contact: sealing and invoices pause until the
  /// user checks the words again or keeps the old or the new keys (RFC 7.8, cases C-12).
  keysChanged;

  /// Paired in some form: a peer card is held.
  bool get isPaired => this == PairingState.paired || this == PairingState.verified || this == PairingState.keysChanged;

  bool get isPending => this == PairingState.pendingInvite || this == PairingState.pendingReply;
}

/// What the other side's card says it is (card tag 03).
enum PairingParty { person, shop, exchange }

/// Seal payments for a contact (RFC 7.6, 9.3).
enum SealMode {
  /// Payment files to the contact are sealed (the default).
  on,

  /// The user turned it off: files are plain.
  off,

  /// The last file went plain after the contact could not open a sealed one; the next send
  /// asks, sealed preselected, and the next sealed answer turns it back on.
  degraded,
}

/// How a pairing began.
enum PairingWay {
  /// Each phone scanned the other's code.
  inPerson,

  /// An invite link, shared or pasted.
  link,

  /// Five pairing words, read out or typed.
  words,
}

/// What the user decided on the four words.
enum PairingCheck { match, mismatch, skip }

/// What the user chose for a contact whose keys changed (RFC 7.8).
enum KeysChoice { keepOld, useNew }

/// One entry of the word table: an emoji and its name (`sas_table.dart`).
class SasWord {
  const SasWord(this.emoji, this.name);

  final String emoji;
  final String name;

  @override
  int get hashCode => Object.hash(emoji, name);

  @override
  bool operator ==(Object other) => other is SasWord && emoji == other.emoji && name == other.name;

  @override
  String toString() => '$emoji $name';
}

/// What the other side's card says its wallet does (card tag 0B).
class PairingCaps {
  const PairingCaps({
    this.opensSealed = true,
    this.paysInvoices = true,
    this.issuesInvoices = false,
    this.sharedInbox = false,
    this.sendsWithdrawals = false,
  });

  /// From the card's u16 bits: 0 opens sealed files, 1 pays invoices, 2 issues invoices, 3 a
  /// service's shared inbox, 4 sends withdrawals.
  factory PairingCaps.fromBits(int bits) => PairingCaps(
    opensSealed: bits & 1 != 0,
    paysInvoices: bits & 2 != 0,
    issuesInvoices: bits & 4 != 0,
    sharedInbox: bits & 8 != 0,
    sendsWithdrawals: bits & 16 != 0,
  );

  final bool opensSealed;
  final bool paysInvoices;
  final bool issuesInvoices;
  final bool sharedInbox;
  final bool sendsWithdrawals;

  int get bits =>
      (opensSealed ? 1 : 0) | (paysInvoices ? 2 : 0) | (issuesInvoices ? 4 : 0) | (sharedInbox ? 8 : 0) | (sendsWithdrawals ? 16 : 0);

  @override
  int get hashCode => bits;

  @override
  bool operator ==(Object other) => other is PairingCaps && bits == other.bits;
}

/// One pairing, as the core keeps it (RFC 7.6), pending ones included.
class PairingRecord {
  const PairingRecord({
    required this.id,
    required this.state,
    required this.way,
    required this.inviter,
    required this.createdAt,
    this.name,
    this.label,
    this.kind = PairingParty.person,
    this.caps = const PairingCaps(),
    this.sas = const [],
    this.verifiedAt,
    this.checkSkipped = false,
    this.allowInvoices = false,
    this.asksInvoices = false,
    this.seal = SealMode.on,
    this.homeRelay = '',
    this.contactId,
    this.paymentsAddress,
    this.lastSealedIn,
    this.expiresAt,
    this.inviteLink,
    this.inviteWords = const [],
    this.relayDown = false,
    this.otherDevice = false,
    this.checksKeys = false,
    this.removedByPeer = false,
  });

  /// The record's local id: never sent, never a key.
  final String id;
  final PairingState state;
  final PairingWay way;

  /// This wallet made the invite (A); false when it answered one (B) or paired in person.
  final bool inviter;
  final DateTime createdAt;

  /// The name the other side chose for itself (its card's claim), null until it is known.
  /// Never trusted: the user's own label is the address-book contact's name.
  final String? name;

  /// For an invite this wallet made: the name of whom it is for, when the user started it
  /// from a contact. Shown in Pending invites.
  final String? label;
  final PairingParty kind;
  final PairingCaps caps;

  /// The four words of the check; empty until paired.
  final List<SasWord> sas;
  final DateTime? verifiedAt;

  /// The user chose Skip for now on the words.
  final bool checkSkipped;

  /// The contact may send this wallet requests to pay. Only on for a [PairingState.verified]
  /// record (RFC 11.1).
  final bool allowInvoices;

  /// The invite asked to allow invoices (an exchange's): preselected, effective only once the
  /// words match.
  final bool asksInvoices;
  final SealMode seal;

  /// The relay the contact delivers through ("Delivered via"), `domain[:port]`.
  final String homeRelay;

  /// The address-book contact this pairing is attached to (RFC 7.6 `app_contact`), or null.
  /// The only link between the two: the shared address book knows nothing of pairings.
  final String? contactId;

  /// The contact's ordinary Epicbox address from its card (tag 09), for plain sends.
  final String? paymentsAddress;

  /// When the last sealed message from the contact opened; since pairing when none has.
  final DateTime? lastSealedIn;

  /// For a pending invite or answer: when it stops being answered.
  final DateTime? expiresAt;

  /// For an invite this wallet made: the link, to share or copy again.
  final String? inviteLink;

  /// For an invite offered as pairing words: the five words.
  final List<SasWord> inviteWords;

  /// The contact's relay is not answering (RFC 8.4 backoff, cases C-05).
  final bool relayDown;

  /// Imported from a backup whose pairings were in use on another device and not yet taken
  /// over here (RFC 9.5).
  final bool otherDevice;

  /// A new pairing added to a contact that has one already, still checking whether that old
  /// pairing's keys are back (RFC 7.8): the contact keeps using the old one meanwhile.
  final bool checksKeys;

  /// The other side removed this pairing and said so (RFC 7.6): nothing sent through it
  /// arrives any more. Kept, with its history, until the user removes it here too.
  final bool removedByPeer;

  /// When the contact was last heard from through this pairing: its last sealed message, or
  /// the pairing itself when that is later.
  DateTime get heardAt {
    final sealed = lastSealedIn;
    return sealed != null && sealed.isAfter(createdAt) ? sealed : createdAt;
  }

  /// The name to show: the label, else the claimed name, else empty.
  String get shownName => label ?? name ?? '';

  /// Allow invoices can be switched on.
  bool get canAllowInvoices => state == PairingState.verified;

  /// Seal and invoices are paused until the user decides on changed keys.
  bool get paused => state == PairingState.keysChanged;

  /// Payment files to the contact are sealed now.
  bool get seals => state.isPaired && !paused && !removedByPeer && seal != SealMode.off && caps.opensSealed;

  /// A payment can go through the contact's mailbox (RFC 9.1): paired or verified, not removed
  /// by the other side, and its wallet opens sealed messages. The seal switch plays no part.
  bool get paysByMailbox =>
      (state == PairingState.paired || state == PairingState.verified) && !removedByPeer && caps.opensSealed;

  /// Waiting for the user to check the words after pairing.
  bool get awaitsCheck => state == PairingState.paired && !checkSkipped;

  bool expiredAt(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);

  PairingRecord copyWith({
    PairingState? state,
    String? name,
    String? label,
    List<SasWord>? sas,
    DateTime? verifiedAt,
    bool clearVerified = false,
    bool? checkSkipped,
    bool? allowInvoices,
    SealMode? seal,
    String? contactId,
    bool clearContact = false,
    DateTime? lastSealedIn,
    DateTime? expiresAt,
    bool? relayDown,
    bool? otherDevice,
    String? homeRelay,
    PairingCaps? caps,
    PairingParty? kind,
    String? paymentsAddress,
    List<SasWord>? inviteWords,
    bool? removedByPeer,
  }) => PairingRecord(
    id: id,
    state: state ?? this.state,
    way: way,
    inviter: inviter,
    createdAt: createdAt,
    name: name ?? this.name,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    caps: caps ?? this.caps,
    sas: sas ?? this.sas,
    verifiedAt: clearVerified ? null : verifiedAt ?? this.verifiedAt,
    checkSkipped: checkSkipped ?? this.checkSkipped,
    allowInvoices: allowInvoices ?? this.allowInvoices,
    asksInvoices: asksInvoices,
    seal: seal ?? this.seal,
    homeRelay: homeRelay ?? this.homeRelay,
    contactId: clearContact ? null : contactId ?? this.contactId,
    paymentsAddress: paymentsAddress ?? this.paymentsAddress,
    lastSealedIn: lastSealedIn ?? this.lastSealedIn,
    expiresAt: expiresAt ?? this.expiresAt,
    inviteLink: inviteLink,
    inviteWords: inviteWords ?? this.inviteWords,
    relayDown: relayDown ?? this.relayDown,
    otherDevice: otherDevice ?? this.otherDevice,
    checksKeys: checksKeys,
    removedByPeer: removedByPeer ?? this.removedByPeer,
  );
}

/// The pairing the address-book contact [contactId] uses, of [pairings] (newest first), or
/// null when none attached to it is paired. A contact can carry several: a re-pair after the
/// other side restored its wallet adds one, and when the key check is refused the old ones
/// stay. Only one is still read by the other side, so a payment goes through the one heard
/// from last ([PairingRecord.heardAt]), never simply the newest. One whose keys
/// changed comes first, as the contact waits on the user's choice; one still checking keys
/// is taken only when nothing else is, and one the other side removed (RFC 7.6) last of all.
PairingRecord? contactPairingOf(Iterable<PairingRecord> pairings, String contactId) {
  final attached = [
    for (final r in pairings)
      if (r.contactId == contactId && r.state.isPaired) r,
  ];
  final alive = [for (final r in attached) if (!r.removedByPeer) r];
  if (alive.isEmpty) return attached.firstOrNull;
  final changed = alive.where((r) => r.state == PairingState.keysChanged).firstOrNull;
  if (changed != null) return changed;
  final settled = [for (final r in alive) if (!r.checksKeys) r];
  final pool = settled.isEmpty ? alive : settled;
  PairingRecord? best;
  for (final r in pool) {
    if (best == null || r.heardAt.isAfter(best.heardAt)) best = r;
  }
  return best;
}

/// An invite opened from a link or pairing words, before the user answers it (RFC 7.2).
class PairingInvitePreview {
  const PairingInvitePreview({
    required this.token,
    required this.name,
    required this.expiresAt,
    this.kind = PairingParty.person,
    this.asksInvoices = false,
    this.homeRelay = '',
    this.wordsAvailable = true,
  });

  /// Opaque: hands the opened invite back to [PairingApi.acceptInvite].
  final String token;

  /// The name the inviter chose: a claim, not checked yet.
  final String name;
  final DateTime expiresAt;
  final PairingParty kind;

  /// The invite asks the user to allow the inviter's invoices (an exchange's, RFC 12.2).
  final bool asksInvoices;
  final String homeRelay;

  /// The relay the answer goes to is reachable now; false sends the answer by hand.
  final bool wordsAvailable;
}

/// This wallet's code for in-person pairing (RFC 7.4): a fresh card per showing.
class PairingCard {
  const PairingCard({required this.id, required this.link});

  /// Opaque: names the card to [PairingApi.scanCard], so both scans pair one slot.
  final String id;

  /// `epiccash://contact/1/…`, for the QR code.
  final String link;
}

/// Why a pairing step did not go through. The core's `WalletError` carries it as
/// [WalletErrorKind.pairingFailed] with the name as message; [pairingFailureOf] reads it.
enum PairingFailure {
  /// The invite's time ran out (C-14).
  expired,

  /// The invite was answered already (C-15).
  alreadyUsed,

  /// The inviter cancelled it.
  cancelled,

  /// No confirm within an hour (C-16).
  noAnswer,

  /// This wallet answered an invite and the inviter's confirmation never came within the
  /// invite's window: the answer was removed, nothing is kept (no half pairing).
  notCompleted,

  /// The confirm did not match the invite's commitment: changed on the way.
  changedOnTheWay,

  /// Made by a newer wallet.
  newerVersion,

  /// The words open no invite (C-33).
  notFound,

  /// Not a pairing link, or damaged (C-28: a partial scan).
  invalid,

  /// No relay could be reached for the answer or the words.
  relayUnreachable,

  /// Pairing words: not one built-in relay took the invite or could be asked for it.
  noRelay,

  /// Pairing words: as [noRelay], the relays' handshakes refused as a network filter does
  /// (relay_block.dart).
  relaysBlocked,

  /// The card scanned is this wallet's own.
  ownCard,

  /// A sealed file for another wallet or install (RFC 9.5).
  sealedForOther,

  /// Made by a wallet on the other network (mainnet or the test network).
  wrongNetwork,
}

/// The [PairingFailure] behind [error], or null for any other error.
PairingFailure? pairingFailureOf(Object error) {
  if (error is! WalletError || error.kind != WalletErrorKind.pairingFailed) return null;
  return PairingFailure.values.asNameMap()[error.message] ?? PairingFailure.invalid;
}

/// The error a pairing call throws for [failure].
WalletError pairingError(PairingFailure failure) => WalletError(kind: WalletErrorKind.pairingFailed, message: failure.name);

/// What the engine tells the app about pairings (RFC 10.4). Fields carry ids, names and
/// amounts, never keys.
enum PairingEventKind {
  /// The inviter: someone answered the invite; the words check is next.
  replied,

  /// The answerer: the inviter confirmed; the words check is next.
  confirmed,

  /// A pending pairing ended without pairing ([PairingEvent.failure] says why).
  failed,

  /// A paired contact's card changed (higher seq).
  contactUpdated,

  /// A re-pair found the old keys: nothing changed for the user.
  keysRestored,

  /// A key check found other keys (C-12).
  keysChanged,

  /// A re-pair was added to a contact, but its key check was refused (RFC 7.8: one a day per
  /// slot): the new pairing is the contact's, and its old keys were not checked.
  keyCheckRefused,

  /// A sealed message from a contact opened.
  sealedReceived,

  /// A sealed file was for another wallet or install.
  sealedUnopenable,

  /// A contact the user allows sent a request to pay.
  invoiceFromContact,

  /// A contact sent a withdrawal; the wallet answered it.
  withdrawalFromContact,

  /// A contact's relay stopped answering.
  homeRelayUnreachable,

  /// A message waiting in the outbox reached the contact's relay.
  outboxDelivered,

  /// A message has not reached the contact's relay for a day.
  outboxStuck,

  /// A second wallet answered an invite that was already used (C-15).
  secondReply,

  /// Same-amount requests from one contact within 10 minutes.
  duplicateRequests,

  /// A contact went over the parked-invoice cap; extra requests were dropped.
  tooManyRequests,

  /// A contact withdrew a request (before or after it was paid).
  requestWithdrawn,

  /// A contact's answer to a payment sent through its mailbox was finalized and posted
  /// ([PairingEvent.slateId]); may come again for the same payment.
  paymentFinalized,

  /// The other side removed the pairing [PairingEvent.pairingId] and said so (RFC 7.6).
  unpaired,
}

class PairingEvent {
  const PairingEvent(
    this.kind, {
    this.pairingId,
    this.name = '',
    this.failure,
    this.slateId,
    this.amount,
    this.count = 0,
  });

  final PairingEventKind kind;
  final String? pairingId;

  /// The contact's name as the app shows it (its label, else its claimed name).
  final String name;
  final PairingFailure? failure;
  final String? slateId;
  final BigInt? amount;
  final int count;

  @override
  int get hashCode => Object.hash(kind, pairingId, name, failure, slateId, amount, count);

  @override
  bool operator ==(Object other) =>
      other is PairingEvent &&
      kind == other.kind &&
      pairingId == other.pairingId &&
      name == other.name &&
      failure == other.failure &&
      slateId == other.slateId &&
      amount == other.amount &&
      count == other.count;
}

/// A second answer to an invite already used, kept only to show it (C-15): nothing is stored.
class PairingStray {
  const PairingStray({required this.id, required this.inviteId, required this.name});

  final String id;

  /// The pairing that took the invite.
  final String inviteId;

  /// The name the second answer claimed.
  final String name;
}

/// What a slate that came through a pairing was for (RFC 3.3, TLV `04`).
enum SlatePurpose { payment, deposit, withdrawal, refund, request }

/// A transaction a paired contact took part in, by its slate ([PairingApi.slateOf]): who, what
/// for, and the contact's own reference (shown, never trusted for crediting).
class PairingSlate {
  const PairingSlate({required this.pairingId, required this.purpose, this.reference});

  final String pairingId;
  final SlatePurpose purpose;
  final String? reference;

  @override
  int get hashCode => Object.hash(pairingId, purpose, reference);

  @override
  bool operator ==(Object other) =>
      other is PairingSlate && other.pairingId == pairingId && other.purpose == purpose && other.reference == reference;
}

/// A payment file or paste as [PairingApi.openSlate] opened it. A plain one comes back as it
/// is ([slateJson]); a sealed one says what it holds, and is acted on sealed
/// ([PairingApi.receiveSealed], [PairingApi.finalizeSealed]).
class OpenedSlate {
  const OpenedSlate({
    this.slateJson,
    this.pairingId,
    this.sealed = false,
    this.stage,
    this.slateId,
    this.amount,
    this.fee,
    this.purpose,
    this.reference,
    this.messages = const [],
  });

  /// The slate as plain JSON: the text itself for a plain file; for a sealed one only when
  /// the engine hands it out (the fake does, LEPIC does not).
  final String? slateJson;

  /// The paired contact it came from (sealed, or plain from a known card), or null.
  final String? pairingId;

  /// It was sealed. False with a [pairingId] is a paired contact's plain file.
  final bool sealed;

  /// What a sealed file holds, for the screen before the user acts on it.
  final SlateStage? stage;
  final String? slateId;
  final BigInt? amount;
  final BigInt? fee;
  final SlatePurpose? purpose;
  final String? reference;

  /// A sealed file's messages whose signatures verify, cleaned (LEPIC hands them out).
  final List<SlateMessage> messages;
}

/// The answer to a sealed payment ([PairingApi.receiveSealed]): sealed to the sender when it
/// can be, else plain slate JSON, to send back the way the payment came.
class SealedReply {
  const SealedReply({required this.slateId, required this.answer, required this.sealed, this.repeated = false});

  final String slateId;
  final String answer;
  final bool sealed;

  /// The payment was answered before; this is the same answer.
  final bool repeated;
}

/// A sealed payment request paid ([PairingApi.paySealedRequest]): [paid] with its answer in
/// [PaidRequestFile.json], sealed to the contact that sent the request when [sealed], else
/// plain slate JSON.
class PaidSealedRequest {
  const PaidSealedRequest({required this.paid, required this.sealed});

  final PaidRequestFile paid;
  final bool sealed;
}

/// Why the pairing mailboxes are collected now (RFC 8.4): the app opened, resumed or was
/// unlocked; the foreground tick; a pull to refresh; a push wake-up.
enum PairingCollectTrigger { open, foreground, pull, push }

/// One opaque payload a private pairing received (`contact_post_payload` on the other side),
/// kept by the engine until [PairingApi.ackPayloads] takes it off. Only private pairings
/// (linked devices) carry payloads; the engine reads nothing in [bytes].
class PairingPayload {
  const PairingPayload({required this.id, required this.pairingId, required this.bytes, required this.receivedAt});

  /// The engine's id for the payload, for [PairingApi.ackPayloads].
  final String id;

  /// The private pairing it came through.
  final String pairingId;
  final List<int> bytes;
  final DateTime receivedAt;
}
