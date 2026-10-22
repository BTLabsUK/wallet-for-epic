/// The desktop UI's view of a wallet. Plain immutable types; the UI reads only these and the
/// [DeskWalletApi] in `api.dart`. The mock (`mock_wallet.dart`) fills them with canned data; a
/// LEPIC adapter will map `WalletService` and `models.dart` onto them later.
library;

import 'package:flutter/foundation.dart';

/// Amounts are kept in nanoepic (1 EPIC = 10^8), as the wallet does.
const int nanoPerEpic = 100000000;

String formatEpic(int nano, {int decimals = 8, bool trim = true}) {
  final neg = nano < 0;
  final v = nano.abs();
  final whole = v ~/ nanoPerEpic;
  var frac = (v % nanoPerEpic).toString().padLeft(8, '0').substring(0, decimals);
  if (trim) frac = frac.replaceFirst(RegExp(r'0+$'), '');
  final w = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '-' : ''}$w${frac.isEmpty ? '' : '.$frac'}';
}

@immutable
class Balance {
  const Balance({
    required this.spendable,
    required this.awaitingConfirmation,
    required this.locked,
    required this.awaitingFinalization,
    this.immature = 0,
  });

  final int spendable;
  final int awaitingConfirmation;

  /// Locked by unfinished sends.
  final int locked;
  final int awaitingFinalization;

  /// Mining rewards below their lock height.
  final int immature;

  int get total => spendable + awaitingConfirmation + locked + immature;
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

/// One coin of the balance (an output and its commitment).
@immutable
class Output {
  const Output({
    required this.commitment,
    required this.value,
    required this.status,
    this.height,
    this.confirmations = 0,
    this.lockHeight,
  });

  final String commitment;
  final int value;
  final OutputStatus status;
  final int? height;
  final int confirmations;

  /// Height a mining reward unlocks at.
  final int? lockHeight;
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
    this.counterparty,
    this.contactName,
    this.message,
    this.height,
    this.kernel,
    this.hasProof = false,
    this.coinbase = false,
    this.foundByScan = false,
    this.confirmedAt,
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
    this.syncProgress,
    this.lastUpdate,
    this.notice,
  });

  final NodeServer node;
  final ServiceHealth nodeHealth;
  final int nodeHeight;
  final EpicboxServer epicbox;
  final ServiceHealth epicboxHealth;

  /// Direct receive over HTTP (port 3415) on or off.
  final ServiceHealth httpListener;
  final ServiceHealth tor;

  /// 0..1 while the wallet scans; null when idle.
  final double? syncProgress;
  final DateTime? lastUpdate;

  /// A one-line state the wallet is in, e.g. a database being rebuilt; null when none.
  final String? notice;
}

/// New wallet passwords must have at least this many characters (LEPIC refuses shorter ones).
const int minPasswordLength = 8;

/// One step of a rescan: the core's message and, when it gives one, the percentage.
@immutable
class ScanStep {
  const ScanStep(this.message, {this.percent});

  final String message;
  final int? percent;
}

/// A wallet error, in a short sentence for the screen.
class DeskError implements Exception {
  const DeskError(this.message, {this.wrongPassword = false, this.locked = false});

  final String message;
  final bool wrongPassword;

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
    this.autoLockMinutes = 15,
    this.fiat = 'USD',
    this.newLookSeen = false,
  });

  final ThemeChoice theme;

  /// Interface scale in percent, one of [deskScales]: text and layout together.
  final int scale;
  final String language;
  final bool hideAmounts;

  /// Switch to the next healthy node when the current one stops answering.
  final bool nodeFailover;
  final bool epicboxFailover;

  /// Receive directly over HTTP on port 3415.
  final bool directHttp;
  final bool tor;

  /// The HTTP listener answers on all interfaces, not only this computer.
  final bool publicMode;
  final int? autoLockMinutes;
  final String fiat;

  /// The one-time "new look" notice on Overview was closed.
  final bool newLookSeen;

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
    int? autoLockMinutes,
    String? fiat,
    bool? newLookSeen,
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
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    fiat: fiat ?? this.fiat,
    newLookSeen: newLookSeen ?? this.newLookSeen,
  );
}

/// What Send hands over.
@immutable
class SendRequest {
  const SendRequest({required this.method, required this.amount, this.to, this.message, this.sendAll = false, this.dandelion = true});

  final TxMethod method;
  final int amount;

  /// Address or URL; null for a file send.
  final String? to;
  final String? message;
  final bool sendAll;

  /// Broadcast through Dandelion++ (stem first); false fluffs it at once.
  final bool dandelion;
}

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
