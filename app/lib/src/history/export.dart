// SPDX-License-Identifier: Apache-2.0
/// History files: the payload LEPIC seals as a `.wfeh` file, and the plain CSV. A port of
/// `app/rust/src/core/export.rs`; the encryption is LEPIC's (`EpicWallet.sealAppData`), in the
/// same `WFEH` version 1 format, so files of the old core open and the other way round.
///
/// The payload holds what the user built up that the recovery phrase and a scan cannot give
/// back: payments with their notes and labels ([Record]), invoices both ways, the shared
/// address book with this wallet's stars, pairings, the wallet's name and the app's settings
/// worth restoring. Never in it: keys, the seed or phrase, the password, the PIN or its sealed
/// text, addresses the seed derives, push tokens, node secrets.
///
/// Version 2 added the invoices, the wallet's name, the settings and, per record, its flow,
/// pairing and slate messages. Version 1 files still open; apps that read only version 1
/// refuse a version 2 file as newer.
library;

import 'dart:convert';

import '../wallet_service.dart';
import 'merge.dart' show userFieldName;
import 'meta_store.dart';

const String historyFormat = 'wfe-history';
const int historyPayloadVersion = 2;

/// The old core's sentences for history files. `errors.dart` translates them by this text.
const String historyNotOurs = 'This is not a history file exported by this app';
const String historyNewer =
    'This history file was made by a newer version of the app';
const String historyDamaged = 'This history file is damaged';
const String historyOtherWallet =
    'This history file belongs to a different wallet';

String historyOtherChain(String file, String wallet) =>
    'This history file is from $file, but this wallet is on $wallet';

WalletError historyError(String message) =>
    WalletError(kind: WalletErrorKind.invalidArgument, message: message);

/// The chain as the old core names it in a payload (`format!("{:?}", chain)`).
String chainName(Chain chain) => switch (chain) {
  Chain.mainnet => 'Mainnet',
  Chain.floonet => 'Floonet',
  Chain.usernet => 'Usernet',
};

/// What a history file carries, before encryption.
class HistoryPayload {
  HistoryPayload({
    this.format = historyFormat,
    this.version = historyPayloadVersion,
    required this.chain,
    required this.walletFp,
    required this.exportedAtUnix,
    required this.appVersion,
    this.lastConfirmedHeight,
    List<Record>? txs,
    List<ContactRec>? contacts,
    this.pairings,
    List<String>? favourites,
    Map<String, IssuedInvoiceRec>? issuedInvoices,
    Map<String, PaidInvoiceRec>? paidInvoices,
    this.walletName,
    this.settings,
  }) : txs = txs ?? [],
       contacts = contacts ?? [],
       favourites = favourites ?? [],
       issuedInvoices = issuedInvoices ?? {},
       paidInvoices = paidInvoices ?? {};

  /// This payload with [pairings], the core's pairing backup.
  HistoryPayload withPairings(Map<String, Object?>? pairings) => HistoryPayload(
    format: format,
    version: version,
    chain: chain,
    walletFp: walletFp,
    exportedAtUnix: exportedAtUnix,
    appVersion: appVersion,
    lastConfirmedHeight: lastConfirmedHeight,
    txs: txs,
    contacts: contacts,
    pairings: pairings,
    favourites: favourites,
    issuedInvoices: issuedInvoices,
    paidInvoices: paidInvoices,
    walletName: walletName,
    settings: settings,
  );

  /// This payload with the wallet's [walletName] and the app's [settings], which only the app
  /// knows.
  HistoryPayload withExtras({String? walletName, Map<String, Object?>? settings}) => HistoryPayload(
    format: format,
    version: version,
    chain: chain,
    walletFp: walletFp,
    exportedAtUnix: exportedAtUnix,
    appVersion: appVersion,
    lastConfirmedHeight: lastConfirmedHeight,
    txs: txs,
    contacts: contacts,
    pairings: pairings,
    favourites: favourites,
    issuedInvoices: issuedInvoices,
    paidInvoices: paidInvoices,
    walletName: walletName,
    settings: settings,
  );

  /// Reads a payload as serde reads it. Throws [MetaFormatException] for a wrong shape.
  factory HistoryPayload.fromJson(Object? json) {
    final m = asObject(json, 'payload');
    String str(String k) =>
        m[k] is String ? m[k] as String : throw MetaFormatException(k);
    List<Object?> list(String k) => m[k] == null
        ? const []
        : m[k] is List
        ? m[k] as List
        : throw MetaFormatException(k);
    final version = m['version'];
    final exported = m['exported_at_unix'];
    final height = m['last_confirmed_height'];
    if (version is! int || version < 0) {
      throw const MetaFormatException('version');
    }
    if (exported is! int) throw const MetaFormatException('exported_at_unix');
    if (height != null && (height is! int || height < 0)) {
      throw const MetaFormatException('last_confirmed_height');
    }
    final pairings = m['pairings'] == null
        ? null
        : asObject(m['pairings'], 'pairings');
    Map<String, Object?> map(String k) =>
        m[k] == null ? const {} : asObject(m[k], k);
    final name = map('wallet')['name'];
    if (name != null && name is! String) throw const MetaFormatException('wallet name');
    return HistoryPayload(
      format: str('format'),
      version: version,
      chain: str('chain'),
      walletFp: str('wallet_fp'),
      exportedAtUnix: exported,
      appVersion: str('app_version'),
      lastConfirmedHeight: height == null ? null : BigInt.from(height as int),
      txs: [for (final r in list('txs')) Record.fromJson(r)],
      contacts: [for (final c in list('contacts')) ContactRec.fromJson(c)],
      pairings: pairings,
      favourites: [
        for (final f in list('favourites'))
          f is String ? f : throw const MetaFormatException('favourites'),
      ],
      issuedInvoices: map('issued_invoices').map((k, v) => MapEntry(k, IssuedInvoiceRec.fromJson(v))),
      paidInvoices: map('paid_invoices').map((k, v) => MapEntry(k, PaidInvoiceRec.fromJson(v))),
      walletName: name as String?,
      settings: m['settings'] == null ? null : asObject(m['settings'], 'settings'),
    );
  }

  final String format;
  final int version;

  /// [chainName] of the wallet that wrote it.
  final String chain;

  /// [walletFingerprint] of the wallet that wrote it.
  final String walletFp;
  final int exportedAtUnix;
  final String appVersion;
  final BigInt? lastConfirmedHeight;
  final List<Record> txs;
  final List<ContactRec> contacts;

  /// The wallet's pairing backup (RFC 0002 10.5): the core's own versioned object, carried
  /// as it is. Null when the wallet has no pairings or its core none.
  final Map<String, Object?>? pairings;

  /// Ids (in [contacts]) of the contacts the wallet starred. Written only when not empty, so
  /// a file without stars stays as older apps wrote it; older apps read past it.
  final List<String> favourites;

  /// What became of the invoices this wallet issued and paid, by slate id, as the archive keeps
  /// them ([Meta.issuedInvoices], [Meta.paidInvoices]). Version 2.
  final Map<String, IssuedInvoiceRec> issuedInvoices;
  final Map<String, PaidInvoiceRec> paidInvoices;

  /// The wallet's name where the app names wallets (the desktop). Version 2.
  final String? walletName;

  /// The app's settings worth restoring, as the app wrote them (`backup_settings.dart`); this
  /// layer carries them as they are. Version 2.
  final Map<String, Object?>? settings;

  // The pairings only when set, so a file without them stays as the old core wrote it.
  Map<String, Object?> toJson() => {
    'format': format,
    'version': version,
    'chain': chain,
    'wallet_fp': walletFp,
    'exported_at_unix': exportedAtUnix,
    'app_version': appVersion,
    'last_confirmed_height': lastConfirmedHeight,
    'txs': [for (final r in txs) r.toJson()],
    'contacts': [for (final c in contacts) c.toJson()],
    'pairings': ?pairings,
    if (favourites.isNotEmpty) 'favourites': favourites,
    if (issuedInvoices.isNotEmpty)
      'issued_invoices': {for (final e in issuedInvoices.entries) e.key: e.value.toJson()},
    if (paidInvoices.isNotEmpty)
      'paid_invoices': {for (final e in paidInvoices.entries) e.key: e.value.toJson()},
    if (walletName != null) 'wallet': {'name': walletName},
    'settings': ?settings,
  };

  List<int> encode() => utf8.encode(encodeJson(toJson()));

  /// Parses the opened bytes of a history file. Every malformed input is a [WalletError] with
  /// one of the old core's sentences; nothing here throws anything else on hostile bytes.
  static HistoryPayload decode(List<int> plain) {
    final HistoryPayload payload;
    try {
      payload = HistoryPayload.fromJson(jsonDecode(utf8.decode(plain)));
    } on FormatException {
      throw historyError(historyDamaged);
    } on MetaFormatException {
      throw historyError(historyDamaged);
    }
    if (payload.format != historyFormat ||
        payload.version > historyPayloadVersion) {
      throw historyError(historyNewer);
    }
    return payload;
  }
}

/// `amount` in EPIC with 8 decimals, e.g. `-1.50000000`.
String epicDecimal(BigInt amount) {
  final sign = amount.isNegative ? '-' : '';
  final a = amount.abs();
  final unit = BigInt.from(100000000);
  return '$sign${a ~/ unit}.${(a % unit).toString().padLeft(8, '0')}';
}

/// One CSV field: quoted when it holds a comma, quote or line break, and with a leading `'`
/// when text could be read as a spreadsheet formula (counterparty and note come from others).
String csvField(String value, {required bool text}) {
  var v = value;
  if (text && RegExp('^[=+\\-@\t\r]').hasMatch(v)) v = "'$v";
  if (RegExp('[,"\n\r]').hasMatch(v)) return '"${v.replaceAll('"', '""')}"';
  return v;
}

/// [unix] as `YYYY-MM-DDTHH:MM:SSZ`, by Howard Hinnant's days-to-civil conversion as the old
/// core does it, so no time a file names can make it throw.
String isoUtc(int unix) {
  int divFloor(int a, int b) =>
      (a - a % b) ~/ b; // `%` is never negative for b > 0
  final days = divFloor(unix, 86400);
  final secs = unix % 86400;
  final z = days + 719468;
  final era = divFloor(z, 146097);
  final doe = z % 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doy + 2) ~/ 153;
  final day = doy - (153 * mp + 2) ~/ 5 + 1;
  final month = mp < 10 ? mp + 3 : mp - 9;
  final year = yoe + era * 400 + (month <= 2 ? 1 : 0);
  String pad(int n, int w) => n < 0
      ? '-${(-n).toString().padLeft(w, '0')}'
      : n.toString().padLeft(w, '0');
  return '${pad(year, 4)}-${pad(month, 2)}-${pad(day, 2)}'
      'T${pad(secs ~/ 3600, 2)}:${pad(secs % 3600 ~/ 60, 2)}:${pad(secs % 60, 2)}Z';
}

/// Net amount the user sees: what a send delivered (without the fee) as a negative number, what
/// a receive brought in as a positive one.
BigInt netAmount(TxEntry tx) => switch (tx.kind) {
  TxKind.sent || TxKind.sentCancelled =>
    -(tx.amountDebited - tx.amountCredited - (tx.fee ?? BigInt.zero)),
  _ => tx.amountCredited - tx.amountDebited,
};

/// Confirmations after which the app calls a payment completed.
const int confirmationsTarget = defaultMinimumConfirmations;

/// The type column, in the words the app shows (`txKindLabel`).
String typeWord(TxKind kind) => switch (kind) {
  TxKind.coinbase => 'Mining reward',
  TxKind.received || TxKind.receivedCancelled => 'Received',
  TxKind.sent || TxKind.sentCancelled => 'Sent',
};

/// The status column, in the words of the app's status chip, with [tip] the wallet's last
/// confirmed height when known.
String statusWords(TxEntry tx, BigInt? tip, {int target = confirmationsTarget}) {
  final h = tx.blockHeight;
  final confirmations = h != null && tip != null
      ? (tip + BigInt.one - h).isNegative
            ? BigInt.zero
            : tip + BigInt.one - h
      : null;
  final needed = BigInt.from(target);
  final incoming =
      tx.kind == TxKind.received || tx.kind == TxKind.receivedCancelled;
  return switch (tx.status) {
    TxStatus.cancelled => 'Cancelled',
    _ when tx.id == null && tx.status != TxStatus.confirmed =>
      'Imported',
    TxStatus.awaitingRecipient => 'Waiting for recipient',
    TxStatus.awaitingConfirmation when h == null && incoming =>
      'Waiting for sender',
    TxStatus.awaitingConfirmation =>
      'Confirming ${confirmations ?? 0}/$target',
    TxStatus.confirmed when confirmations != null && confirmations < needed =>
      'Confirming $confirmations/$target',
    TxStatus.confirmed => 'Completed',
  };
}

/// The last three columns came later and only ever follow the first ten: `label` the user's
/// label, `method` its name (see [methodWord]), `user_fields` which of
/// `label;counterparty;method;note` the user entered rather than the wallet recorded.
const String csvHeader =
    'date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,block_height,'
    'label,method,user_fields';


/// The method as the CSV names it, in English like the rest of the file: `Epicbox`,
/// `Link · HTTP`, `Link · Tor` or `Direct · File Transfer` for the transports LEPIC names `epicbox`, `http`,
/// `tor` and `file`; empty when the transport is not known. A name this app does not know stays
/// as it is.
String methodWord(String? transport) => switch (transport) {
  null => '',
  'epicbox' => 'Epicbox',
  'http' => 'Link · HTTP',
  'tor' => 'Link · Tor',
  'file' => 'Direct · File Transfer',
  final other => other,
};

/// One row per payment, newest first as given.
String historyCsv(List<TxEntry> txs, BigInt? tip, {int target = confirmationsTarget}) {
  final out = StringBuffer('$csvHeader\n');
  for (final tx in txs) {
    out
      ..write(
        [
          csvField(isoUtc(tx.timeUnix), text: false),
          csvField(typeWord(tx.kind), text: false),
          csvField(statusWords(tx, tip, target: target), text: false),
          csvField(epicDecimal(netAmount(tx)), text: false),
          csvField(tx.fee == null ? '' : epicDecimal(tx.fee!), text: false),
          csvField(tx.counterparty ?? '', text: true),
          csvField(tx.note ?? '', text: true),
          csvField(tx.slateId ?? '', text: false),
          csvField(tx.kernelExcess ?? '', text: false),
          csvField(tx.blockHeight?.toString() ?? '', text: false),
          csvField(tx.label ?? '', text: true),
          // Through a pairing's mailbox: Epicbox, though LEPIC keeps it with no address, as a
          // file exchange until its answer is in.
          csvField(methodWord(tx.pairingId != null && tx.counterparty == null ? 'epicbox' : tx.transport), text: false),
          csvField(
            [
              for (final f in ManualField.values)
                if (tx.manualFields.contains(f)) userFieldName(f),
            ].join(';'),
            text: false,
          ),
        ].join(','),
      )
      ..write('\n');
  }
  return out.toString();
}
