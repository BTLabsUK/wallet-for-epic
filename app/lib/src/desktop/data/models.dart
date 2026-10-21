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
  });

  final int spendable;
  final int awaitingConfirmation;

  /// Locked by unfinished sends.
  final int locked;
  final int awaitingFinalization;

  int get total => spendable + awaitingConfirmation + locked;
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

  bool get incoming => direction == TxDirection.received;
  bool get pending => state == TxState.waitingRecipient || state == TxState.posted || state == TxState.confirming;
}

@immutable
class Contact {
  const Contact({required this.id, required this.name, required this.address, this.note, this.favourite = false, this.lastUsed});

  final String id;
  final String name;
  final String address;
  final String? note;
  final bool favourite;
  final DateTime? lastUsed;
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
}

@immutable
class WalletAccount {
  const WalletAccount({required this.name, required this.network, required this.folder, required this.created});

  final String name;

  /// "mainnet" or "floonet".
  final String network;
  final String folder;
  final DateTime created;
}

enum ThemeChoice { system, dark, light }

@immutable
class DeskSettings {
  const DeskSettings({
    this.theme = ThemeChoice.dark,
    this.language = 'English',
    this.hideAmounts = false,
    this.nodeFailover = true,
    this.epicboxFailover = true,
    this.directHttp = false,
    this.tor = false,
    this.publicMode = false,
    this.autoLockMinutes = 15,
    this.fiat = 'USD',
  });

  final ThemeChoice theme;
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

  DeskSettings copyWith({
    ThemeChoice? theme,
    String? language,
    bool? hideAmounts,
    bool? nodeFailover,
    bool? epicboxFailover,
    bool? directHttp,
    bool? tor,
    bool? publicMode,
    int? autoLockMinutes,
    String? fiat,
  }) => DeskSettings(
    theme: theme ?? this.theme,
    language: language ?? this.language,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    nodeFailover: nodeFailover ?? this.nodeFailover,
    epicboxFailover: epicboxFailover ?? this.epicboxFailover,
    directHttp: directHttp ?? this.directHttp,
    tor: tor ?? this.tor,
    publicMode: publicMode ?? this.publicMode,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    fiat: fiat ?? this.fiat,
  );
}

/// What Send hands over.
@immutable
class SendRequest {
  const SendRequest({required this.method, required this.amount, this.to, this.message, this.sendAll = false});

  final TxMethod method;
  final int amount;

  /// Address or URL; null for a file send.
  final String? to;
  final String? message;
  final bool sendAll;
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
  const SendFailed(this.message);
  final String message;
}

/// A wallet folder found on this computer (switching, import, "found" screen).
@immutable
class WalletEntry {
  const WalletEntry({required this.name, required this.folder, required this.network, this.current = false, this.lastOpened});

  final String name;
  final String folder;
  final String network;
  final bool current;
  final DateTime? lastOpened;
}
