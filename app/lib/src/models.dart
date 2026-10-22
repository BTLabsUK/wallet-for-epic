/// The wallet's data types, shared by the UI, [WalletService] and the LEPIC adapter.
///
/// They began as the generated types of the earlier Rust core and keep its field names, so
/// the UI and the tests did not change when the core did.
library;

import 'dart:convert';

import 'package:characters/characters.dart';

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

/// An address book entry. An empty `id` in `save_contact` creates a new one.
class Contact {
  final String id;
  final String name;
  final String address;
  final String? note;

  const Contact({
    required this.id,
    required this.name,
    required this.address,
    this.note,
  });

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ address.hashCode ^ note.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          note == other.note;
}

/// `amount` is the amount to send, as requested; `fee` comes on top of it.
class FeeEstimate {
  final BigInt amount;
  final BigInt fee;

  const FeeEstimate({required this.amount, required this.fee});

  @override
  int get hashCode => amount.hashCode ^ fee.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeEstimate &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          fee == other.fee;
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

  const LegacyHistoryImport({
    required this.status,
    this.transactions = 0,
    this.linked = 0,
    this.skipped = 0,
  });

  @override
  int get hashCode =>
      status.hashCode ^ transactions.hashCode ^ linked.hashCode ^ skipped.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyHistoryImport &&
          status == other.status &&
          transactions == other.transactions &&
          linked == other.linked &&
          skipped == other.skipped;
}

class ImportReport {
  /// Records that matched a transaction already shown and filled in its details.
  final int merged;

  /// Records with no match, now shown as imported history.
  final int added;

  /// Records already known from an earlier import.
  final int skipped;
  final int contactsAdded;

  const ImportReport({
    required this.merged,
    required this.added,
    required this.skipped,
    required this.contactsAdded,
  });

  @override
  int get hashCode =>
      merged.hashCode ^
      added.hashCode ^
      skipped.hashCode ^
      contactsAdded.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportReport &&
          runtimeType == other.runtimeType &&
          merged == other.merged &&
          added == other.added &&
          skipped == other.skipped &&
          contactsAdded == other.contactsAdded;
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

  const ListenerEvent({
    required this.kind,
    this.slateId,
    this.txId,
    required this.message,
    this.amount,
  });

  @override
  int get hashCode =>
      kind.hashCode ^
      slateId.hashCode ^
      txId.hashCode ^
      message.hashCode ^
      amount.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListenerEvent &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          slateId == other.slateId &&
          txId == other.txId &&
          message == other.message &&
          amount == other.amount;
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

/// The running HTTP listener.
class HttpListenerInfo {
  final int port;
  final HttpExposure exposure;

  const HttpListenerInfo({required this.port, required this.exposure});

  @override
  int get hashCode => port.hashCode ^ exposure.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HttpListenerInfo &&
          port == other.port &&
          exposure == other.exposure;
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

  const TorEvent({
    required this.kind,
    this.progress,
    this.onion,
    this.failure,
    this.txId,
    this.amount,
    this.repeated = false,
    this.refusal,
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
      refusal.hashCode;

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
          refusal == other.refusal;
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

  const TorStatus({
    required this.kind,
    this.progress,
    this.onion,
    this.failure,
  });

  static const off = TorStatus(kind: TorStatusKind.off);

  @override
  int get hashCode =>
      kind.hashCode ^ progress.hashCode ^ onion.hashCode ^ failure.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TorStatus &&
          kind == other.kind &&
          progress == other.progress &&
          onion == other.onion &&
          failure == other.failure;
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

/// What a slate file asks this wallet to do.
enum SlateStage {
  /// Someone sends to us: sign it with `receive_slate` and return the response.
  send,

  /// The recipient's answer to one of our sends: `finalize_and_post` it.
  response,

  /// A payment request (invoice). Not supported.
  invoice,
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

  /// What carried the slate, as LEPIC names it (`epicbox`, `file`, `http`, `tor`), when known.
  /// Not sent over the remote protocol.
  final String? transport;

  /// The user's private note. It stays on this device and in history backups.
  final String? note;

  /// The parties' signed slate messages, which both sides see. Empty for a restored or imported
  /// row.
  final List<SlateMessage> messages;
  final BigInt? ttlCutoffHeight;

  /// True when `cancel_transaction(id)` is allowed.
  final bool cancellable;

  /// True for a finalized send that is not confirmed and has its final transaction stored:
  /// `repost_transaction(key)` can post it to the node again.
  final bool repostable;

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
    this.transport,
    this.note,
    this.messages = const [],
    this.ttlCutoffHeight,
    required this.cancellable,
    required this.repostable,
    this.statusDetail,
    required this.releasable,
    this.finalizedAtUnix,
    this.cancelReason,
    this.flow = TxFlow.payment,
    this.foundDuring,
    this.datedByBlock = true,
  });

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
      transport.hashCode ^
      note.hashCode ^
      Object.hashAll(messages) ^
      ttlCutoffHeight.hashCode ^
      cancellable.hashCode ^
      repostable.hashCode ^
      statusDetail.hashCode ^
      releasable.hashCode ^
      finalizedAtUnix.hashCode ^
      cancelReason.hashCode ^
      flow.hashCode ^
      foundDuring.hashCode ^
      datedByBlock.hashCode;

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
          transport == other.transport &&
          note == other.note &&
          _listEquals(messages, other.messages) &&
          ttlCutoffHeight == other.ttlCutoffHeight &&
          cancellable == other.cancellable &&
          repostable == other.repostable &&
          statusDetail == other.statusDetail &&
          releasable == other.releasable &&
          finalizedAtUnix == other.finalizedAtUnix &&
          cancelReason == other.cancelReason &&
          flow == other.flow &&
          foundDuring == other.foundDuring &&
          datedByBlock == other.datedByBlock;
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

/// What this wallet learned about a payer from its own messages, for the request form.
enum PeerCapability {
  /// Nothing yet.
  unknown,

  /// It proved it runs LEPIC: it pays requests.
  lepic,

  /// It sent a request back unpaid, as a stock `epic-wallet` does: it cannot pay requests.
  noInvoices,
}

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

  /// Node base URL, e.g. `https://node.btlabs.uk` or `http://127.0.0.1:23413`.
  final String nodeUrl;

  /// Basic-auth secret (user `epic`) sent with every node request. Optional: public nodes need
  /// none. With owner access the node's own sync status gates a refresh; without it the core
  /// judges sync from the foreign API tip (see `core/node.rs`).
  final String? nodeApiSecret;

  /// Epicbox relay domain used for the wallet's address, e.g. `epicbox.epiccash.com`.
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
  });

  @override
  int get hashCode =>
      walletId.hashCode ^
      dataDir.hashCode ^
      chain.hashCode ^
      nodeUrl.hashCode ^
      nodeApiSecret.hashCode ^
      epicboxDomain.hashCode ^
      epicboxPort.hashCode;

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
          epicboxPort == other.epicboxPort;
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

  /// A wallet is still open on another network, or a call on this wallet is still running
  /// (network switch, delete). Waiting a moment and trying again usually works.
  chainBusy,

  /// A call on this wallet is still running, or the wallet is being deleted. `delete_wallet`
  /// returns it after waiting 20 s. Trying again in a moment usually works.
  walletBusy,

  /// The recipient answered at or too near the payment's 14-day limit. The payment was
  /// cancelled instead of finished: nothing was sent and the funds are unlocked.
  paymentExpired,

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
  io,
  other,
}

/// The key part of an epicbox address, before `@`. Services are matched on it alone: the
/// relay checks the signature with the key, never the domain, so the domain proves nothing.
String epicboxKey(String address) => address.trim().split('@').first;

/// A service the user allows to send invoices to their invoice address, by the full epicbox
/// address the service shows. The wallet stores the address; the label is the app's, kept in
/// `wfe_meta.json` by address. It is null only when that file lost it.
class TrustedService {
  final String address;
  final String? label;

  const TrustedService({required this.address, this.label});

  @override
  int get hashCode => address.hashCode ^ label.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustedService &&
          address == other.address &&
          label == other.label;
}

/// The label the user gave the service at [address], matched on the key. Never anything the
/// invoice says about itself.
String? serviceLabel(List<TrustedService> services, String address) {
  final key = epicboxKey(address);
  return services.where((s) => epicboxKey(s.address) == key).firstOrNull?.label;
}

/// The longest an invoice may stay open (UP-14); the default is 24 h. One that asks for more
/// is dropped.
const Duration maxInvoiceExpiry = Duration(hours: 48);

/// An invoice from a trusted service, parked until the user approves or declines it. Nothing
/// pays it but a call the user makes after the PIN or biometric gate.
class PendingInvoice {
  final String slateId;

  /// The epicbox address the invoice came from. Its key (before `@`) signed the message; the
  /// relay part after it is what the sender wrote, so match services on the key only.
  final String senderAddress;

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
      expiresAt.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingInvoice &&
          slateId == other.slateId &&
          senderAddress == other.senderAddress &&
          amount == other.amount &&
          message == other.message &&
          receivedAt == other.receivedAt &&
          expiresAt == other.expiresAt;
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
  });

  PaidInvoice withStatus(InvoiceStatus status, {String? kernelExcess}) =>
      PaidInvoice(
        slateId: slateId,
        senderAddress: senderAddress,
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
}

class InvoiceEvent {
  final InvoiceEventKind kind;
  final String slateId;

  /// For [InvoiceEventKind.posted] only.
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

  /// Local id of the invoice's transaction, for a withdrawal.
  final int txId;
  final String payerAddress;

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
  });

  /// Only an unpaid, unanswered invoice can be withdrawn.
  bool get withdrawable => state == IssuedInvoiceState.waiting;

  /// Time left at [now], never negative.
  Duration timeLeftAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  IssuedInvoice withState(IssuedInvoiceState state) => IssuedInvoice(
    slateId: slateId,
    txId: txId,
    payerAddress: payerAddress,
    amount: amount,
    message: message,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    state: state,
  );

  @override
  int get hashCode =>
      slateId.hashCode ^
      txId.hashCode ^
      payerAddress.hashCode ^
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
  final txId = tx.id;
  if (!tx.isRequest || slateId == null || txId == null) return null;
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
      return byTime != 0 ? byTime : b.txId.compareTo(a.txId);
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
    txId: tx.id,
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

  const IssuerEvent({
    required this.kind,
    required this.slateId,
    this.payerAddress,
  });

  @override
  int get hashCode => kind.hashCode ^ slateId.hashCode ^ payerAddress.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssuerEvent &&
          kind == other.kind &&
          slateId == other.slateId &&
          payerAddress == other.payerAddress;
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
