/// The desktop UI's view of a wallet. Plain immutable types; the UI reads only these and the
/// [DeskWalletApi] in `api.dart`. The mock (`mock_wallet.dart`) fills them with canned data; a
/// LEPIC adapter will map `WalletService` and `models.dart` onto them later.
library;

import 'package:flutter/foundation.dart';

import '../../models.dart' show SelectionStrategy, SendOptions;
import '../../providers.dart' show defaultMinimumConfirmations;
import '../../smart_outputs.dart' show smartOutputsDefault;

export '../../models.dart' show SelectionStrategy, SendOptions;
export '../../send_summary.dart' show SendEstimate, SendSummary;

/// Amounts are kept in nanoepic (1 EPIC = 10^8), as the wallet does.
const int nanoPerEpic = 100000000;

/// "1,234.5000": thousands grouped, trailing zeros trimmed down to [minDecimals] (4, as the
/// GUI shows amounts, so a zero balance reads 0.0000 and never a bare 0).
String formatEpic(int nano, {int decimals = 8, bool trim = true, int minDecimals = 4}) {
  final neg = nano < 0;
  final v = nano.abs();
  final whole = v ~/ nanoPerEpic;
  var frac = (v % nanoPerEpic).toString().padLeft(8, '0').substring(0, decimals);
  if (trim) frac = frac.replaceFirst(RegExp(r'0+$'), '');
  if (frac.length < minDecimals) frac = frac.padRight(minDecimals, '0');
  final w = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '-' : ''}$w${frac.isEmpty ? '' : '.$frac'}';
}

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

/// Confirmations before a mining reward can be spent.
const int coinbaseMaturity = 1440;

enum OutputStatus { unconfirmed, confirming, unspent, immature, locked, spent }

/// The word the Outputs page shows for an output, one place (design spec §2.2, §5.5).
enum OutputWord { spendable, confirming, finalizing, immature, mining, locked, spent }

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
    this.hasCategory = true,
    this.mmrIndex,
    this.txId,
  });

  final String commitment;
  final int value;
  final OutputStatus status;
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

  /// LEPIC gave the output a category; a reward still being mined has none.
  final bool hasCategory;

  /// Its position in the chain's output set, once found there.
  final int? mmrIndex;

  /// The transaction that made it or, once a send locks or spends it, that send ([Tx.id]).
  final int? txId;

  /// Can be spent now.
  bool get spendable => status == OutputStatus.unspent;

  /// Design spec §2.2, the one place: unconfirmed and awaiting finalization is finalizing; a
  /// reward without a category, mining; any other unconfirmed output, like one on chain under
  /// the confirmations needed, is confirming.
  OutputWord get word => switch (status) {
    OutputStatus.unspent => OutputWord.spendable,
    OutputStatus.confirming => OutputWord.confirming,
    OutputStatus.unconfirmed =>
      awaitingFinalization
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

/// The Outputs page's choices for one wallet (F13, D-5): the strategy sends use unless Send
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
    this.height,
    this.kernel,
    this.hasProof = false,
    this.coinbase = false,
    this.foundByScan = false,
    this.confirmedAt,
    this.detail,
  });

  final int id;
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
  final String? message;
  final int? height;
  final String? kernel;
  final bool hasProof;

  /// A mining reward: spendable only after [coinbaseMaturity] confirmations.
  final bool coinbase;

  /// A received output a scan found with no transaction record (another copy of the seed).
  final bool foundByScan;
  final DateTime? confirmedAt;

  /// Why the state is what it is, when that is not obvious: where an imported transaction came
  /// from, or what the blockchain says against the older wallet.
  final String? detail;

  bool get immature => coinbase && state != TxState.cancelled && confirmations > 0 && confirmations < coinbaseMaturity;

  bool get incoming => direction == TxDirection.received;
  bool get pending => state == TxState.waitingRecipient || state == TxState.posted || state == TxState.confirming;
}

@immutable
class Contact {
  const Contact({required this.id, required this.name, required this.address, this.note, this.favourite = false, this.lastUsed, this.hasPicture = false});

  final String id;
  final String name;
  final String address;
  final String? note;
  final bool favourite;
  final DateTime? lastUsed;

  /// A picture was added for the contact (the mock draws a placeholder).
  final bool hasPicture;
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
  });

  final String url;
  final String label;
  final String? operator;
  final ServiceHealth health;
  final int? latencyMs;
  final int? height;
  final String? version;

  /// Added by the user ("My nodes").
  final bool own;
}

/// One Epicbox relay.
@immutable
class EpicboxServer {
  const EpicboxServer({required this.domain, this.port = 443, this.operator, this.health = ServiceHealth.ok, this.latencyMs});

  final String domain;
  final int port;
  final String? operator;
  final ServiceHealth health;
  final int? latencyMs;
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
    this.torProgress,
    this.torProblem,
    this.torCanSend = false,
    this.torIncluded = true,
    this.torSlowStart = false,
    this.syncProgress,
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

  /// Why the HTTP listener is down, in a few words ("Port 3415 in use"); null otherwise.
  final String? httpProblem;

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

  /// 0..1 while the wallet scans; null when idle.
  final double? syncProgress;
  final DateTime? lastUpdate;

  /// A one-line state the wallet is in, e.g. a database being rebuilt; null when none.
  final String? notice;
}

/// The Tor line of the status card and Settings › Receiving: what tor is doing now.
String torStatusLine(ServiceStatus s) {
  if (!s.torIncluded) return 'Tor not included in this build';
  return switch (s.tor) {
    ServiceHealth.off => 'Off',
    ServiceHealth.ok => 'Ready',
    ServiceHealth.down => s.torProblem ?? 'Tor stopped',
    ServiceHealth.slow => '${s.torProblem ?? 'Onion address not published'}. Sends work.',
    ServiceHealth.checking => s.torCanSend ? 'Publishing the onion address…' : 'Connecting to Tor… ${s.torProgress ?? 0} %',
  };
}

/// New wallet passwords must have at least this many characters (LEPIC refuses shorter ones).
const int minPasswordLength = 8;

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

/// A wallet error, in a short sentence for the screen.
class DeskError implements Exception {
  const DeskError(this.message, {this.wrongPassword = false, this.locked = false, this.newPasswordNeeded = false, this.sameWallet, this.unbuildable = false, this.notPostedTx});

  final String message;
  final bool wrongPassword;

  /// A restore whose phrase belongs to this listed wallet (O1): nothing was made. The restore
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
    this.language = 'English',
    this.hideAmounts = false,
    this.nodeFailover = true,
    this.epicboxFailover = true,
    this.directHttp = false,
    this.tor = false,
    this.publicMode = false,
    this.httpPort = 3415,
    this.httpAutostart = false,
    this.epicboxAutostart = true,
    this.torAutostart = false,
    this.autoLockMinutes = 15,
    this.fiat = 'USD',
    this.newLookSeen = false,
    this.internetGuideSeen = false,
    this.tourSeen = false,
  });

  final ThemeChoice theme;

  /// Interface scale in percent, one of [deskScales]: text and layout together.
  final int scale;
  final String language;
  final bool hideAmounts;

  /// Switch to the next healthy node when the current one stops answering.
  final bool nodeFailover;
  final bool epicboxFailover;

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
  final int? autoLockMinutes;
  final String fiat;

  /// The one-time "new look" notice on Overview was closed.
  final bool newLookSeen;

  /// The Receive from the internet guide was shown once: From the internet then switches
  /// straight away; the guide stays behind the (?) next to it. App-wide.
  final bool internetGuideSeen;
  /// The tour was shown once (opened, closed or skipped): it does not open by itself again.
  final bool tourSeen;

  DeskSettings copyWith({
    ThemeChoice? theme,
    int? scale,
    String? language,
    bool? hideAmounts,
    bool? nodeFailover,
    bool? epicboxFailover,
    bool? directHttp,
    bool? tor,
    bool? publicMode,
    int? httpPort,
    bool? httpAutostart,
    bool? epicboxAutostart,
    bool? torAutostart,
    int? autoLockMinutes,
    String? fiat,
    bool? newLookSeen,
    bool? internetGuideSeen,
    bool? tourSeen,
  }) => DeskSettings(
    theme: theme ?? this.theme,
    scale: scale ?? this.scale,
    language: language ?? this.language,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    nodeFailover: nodeFailover ?? this.nodeFailover,
    epicboxFailover: epicboxFailover ?? this.epicboxFailover,
    directHttp: directHttp ?? this.directHttp,
    tor: tor ?? this.tor,
    publicMode: publicMode ?? this.publicMode,
    httpPort: httpPort ?? this.httpPort,
    httpAutostart: httpAutostart ?? this.httpAutostart,
    epicboxAutostart: epicboxAutostart ?? this.epicboxAutostart,
    torAutostart: torAutostart ?? this.torAutostart,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    fiat: fiat ?? this.fiat,
    newLookSeen: newLookSeen ?? this.newLookSeen,
    internetGuideSeen: internetGuideSeen ?? this.internetGuideSeen,
    tourSeen: tourSeen ?? this.tourSeen,
  );
}

/// What Send hands over.
@immutable
class SendRequest {
  const SendRequest({required this.method, required this.amount, this.to, this.message, this.sendAll = false, this.dandelion = true, this.allowPlainHttp = false, this.options});

  final TxMethod method;
  final int amount;

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
  const SendFailed(this.message, {this.inActivity = false});
  final String message;

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
  gui('Older Epic Wallet'),
  cli('The epic program'),
  picked('Chosen folders');

  const OldWalletGroup(this.title);
  final String title;
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
  const ImportProof(this.text, {this.ok = true});
  final String text;
  final bool ok;
}

/// A wallet the import made: listed, selected, its history due from a scan at the first unlock.
@immutable
class ImportedWallet {
  const ImportedWallet({required this.id, required this.name, required this.proof});

  /// The new wallet's list id ([WalletEntry.id]).
  final String id;
  final String name;
  final List<ImportProof> proof;
}
