/// [WalletService] over the LEPIC library (`package:lepic`, pinned by `tools/lepic.rev`).
///
/// The app's only core. It implements [WalletService], so the UI and its fakes never see
/// LEPIC's own types. Notes, contacts, imported records and history files are the app's own, in
/// `history/` (H-01).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:lepic/lepic.dart' as lepic;
import 'package:meta/meta.dart' show visibleForTesting;

import 'history/export.dart';
import 'history/meta_store.dart';
import 'history/wallet_history.dart';
import 'log.dart';
import 'redact.dart';
import 'secret_store_api.dart';
import 'wallet_service.dart';

/// Loads the LEPIC library, which the package's build hook bundles on Android, iOS and x86_64
/// Linux (`tools/lepic.sh build`). Windows has none (UP-3, deferred).
///
/// Outside a Flutter bundle (a plain `dart run`, the demo server) the load by name fails, so
/// those pass [libraryPath], the library file itself, for example
/// `third_party/lepic/bindings/flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so`.
Future<void> initLepic({String? libraryPath}) => lepic.RustLib.init(
  externalLibrary: libraryPath == null
      ? null
      : ExternalLibrary.open(libraryPath),
);

/// Logs one entry of `LepicRuntime.logs()` under its own target:
/// `lepic_wallet::send: slate received in send slate_id=… height=…`. Trace entries are
/// dropped; debug ones reach the log only while [AppLog.detailed] is on.
void logLepicEntry(lepic.LogEntry entry) {
  final level = switch (entry.level) {
    lepic.LogLevel.error => LogLevel.error,
    lepic.LogLevel.warn => LogLevel.warn,
    lepic.LogLevel.info => LogLevel.info,
    lepic.LogLevel.debug => LogLevel.debug,
    lepic.LogLevel.trace => null,
  };
  if (level == null) return;
  final line = StringBuffer(entry.message);
  if (entry.spans.isNotEmpty) line.write(' in ${entry.spans.join('>')}');
  for (final field in entry.fields) {
    final value = field.name == 'error'
        ? redactQuoted(field.value)
        : lepicKeptFields.contains(field.name)
        ? field.value
        : redacted;
    line.write(' ${field.name}=$value');
  }
  AppLog.record(level, entry.target, line.toString());
}

/// LEPIC's error as the app's. The switch is exhaustive, so a kind LEPIC adds breaks the build
/// here instead of reaching the UI unmapped.
WalletError mapLepicError(lepic.WalletError error) {
  final kind = switch (error.kind) {
    lepic.WalletErrorKind.invalidMnemonic => WalletErrorKind.invalidMnemonic,
    lepic.WalletErrorKind.wrongPassword => WalletErrorKind.wrongPassword,
    lepic.WalletErrorKind.walletAlreadyExists =>
      WalletErrorKind.walletAlreadyExists,
    lepic.WalletErrorKind.walletNotFound => WalletErrorKind.walletNotFound,
    lepic.WalletErrorKind.nodeUnreachable => WalletErrorKind.nodeUnreachable,
    lepic.WalletErrorKind.notEnoughFunds => WalletErrorKind.notEnoughFunds,
    lepic.WalletErrorKind.invalidSlate => WalletErrorKind.invalidSlate,
    lepic.WalletErrorKind.invalidArgument => WalletErrorKind.invalidArgument,
    // A split that cannot be built from the coins at hand; one short error for both.
    lepic.WalletErrorKind.changeTooSmall ||
    lepic.WalletErrorKind.tooHeavy => WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.transportFailed => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.chainBusy => WalletErrorKind.chainBusy,
    lepic.WalletErrorKind.walletBusy => WalletErrorKind.walletBusy,
    lepic.WalletErrorKind.paymentExpired => WalletErrorKind.paymentExpired,
    lepic.WalletErrorKind.io => WalletErrorKind.io,
    lepic.WalletErrorKind.damagedDatabase => WalletErrorKind.damagedDatabase,
    lepic.WalletErrorKind.httpUrlInvalid => WalletErrorKind.httpUrlInvalid,
    lepic.WalletErrorKind.plainHttpNotAllowed =>
      WalletErrorKind.plainHttpNotAllowed,
    lepic.WalletErrorKind.onionAddressInvalid =>
      WalletErrorKind.onionAddressInvalid,
    lepic.WalletErrorKind.torNotRunning => WalletErrorKind.torNotRunning,
    lepic.WalletErrorKind.onionUnreachable => WalletErrorKind.onionUnreachable,
    lepic.WalletErrorKind.secretStore => WalletErrorKind.io,
    lepic.WalletErrorKind.foreignWallet => WalletErrorKind.invalidArgument,
    // The old core refused a cancel of a payment on chain, and a history file of another
    // wallet or a damaged one, as invalidArgument; the UI words them from that.
    lepic.WalletErrorKind.onChain ||
    lepic.WalletErrorKind.inPool ||
    lepic.WalletErrorKind.notReleasable ||
    lepic.WalletErrorKind.foreignAppData ||
    lepic.WalletErrorKind.damagedAppData => WalletErrorKind.invalidArgument,
    // The app's invoice calls name a missing invoice and a wrong amount invalidArgument, and
    // an undelivered reply a transport failure (`wallet_service.dart`).
    lepic.WalletErrorKind.invoiceNotFound ||
    lepic.WalletErrorKind.amountMismatch => WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.notDelivered => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.restoreScanRequired ||
    lepic.WalletErrorKind.changedDuringCancel ||
    lepic.WalletErrorKind.other ||
    lepic.WalletErrorKind.locked ||
    lepic.WalletErrorKind.notPosted ||
    lepic.WalletErrorKind.cancelled ||
    lepic.WalletErrorKind.unsupported ||
    lepic.WalletErrorKind.panic => WalletErrorKind.other,
  };
  final split =
      error.kind == lepic.WalletErrorKind.changeTooSmall ||
      error.kind == lepic.WalletErrorKind.tooHeavy;
  return WalletError(
    kind: kind,
    message: split ? sendUnbuildable : error.message,
  );
}

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on lepic.WalletError catch (error) {
    throw mapLepicError(error);
  }
}

T _guardSync<T>(T Function() call) {
  try {
    return call();
  } on lepic.WalletError catch (error) {
    throw mapLepicError(error);
  }
}

Stream<T> _guardStream<T>(Stream<T> stream) => stream.transform(
  StreamTransformer.fromHandlers(
    handleError: (error, stack, sink) => sink.addError(
      error is lepic.WalletError ? mapLepicError(error) : error,
      stack,
    ),
  ),
);

/// Usernet is `Chain.mainnet` to LEPIC: epic-wallet derives mainnet Epicbox addresses there
/// too, and LEPIC's interop chain runs that way (LEPIC V-09).
lepic.Chain _lepicChain(Chain chain) => switch (chain) {
  Chain.mainnet || Chain.usernet => lepic.Chain.mainnet,
  Chain.floonet => lepic.Chain.floonet,
};

WalletSummary _summary(lepic.WalletSummary s) => WalletSummary(
  lastConfirmedHeight: s.lastConfirmedHeight,
  minimumConfirmations: s.minimumConfirmations,
  total: s.total,
  spendable: s.spendable,
  awaitingConfirmation: s.awaitingConfirmation,
  awaitingFinalization: s.awaitingFinalization,
  immature: s.immature,
  locked: s.locked,
  validatedWithNode: s.validatedWithNode,
);

lepic.HttpExposure _lepicExposure(HttpExposure e) => switch (e) {
  HttpExposure.localOnly => lepic.HttpExposure.localOnly,
  HttpExposure.internet => lepic.HttpExposure.internet,
};

/// LEPIC's HTTP listener event as the app's.
HttpListenerEvent lepicHttpEvent(lepic.HttpListenerEvent e) => HttpListenerEvent(
  kind: switch (e.kind) {
    lepic.HttpListenerEventKind.started => HttpListenerEventKind.started,
    lepic.HttpListenerEventKind.portInUse => HttpListenerEventKind.portInUse,
    lepic.HttpListenerEventKind.bindFailed => HttpListenerEventKind.bindFailed,
    lepic.HttpListenerEventKind.received => HttpListenerEventKind.received,
    lepic.HttpListenerEventKind.refused => HttpListenerEventKind.refused,
    lepic.HttpListenerEventKind.stopped => HttpListenerEventKind.stopped,
  },
  port: e.port,
  txId: e.txId,
  amount: e.amount,
  repeated: e.repeated,
  refusal: switch (e.refusal) {
    lepic.HttpRefusal.rejected => HttpRefusal.rejected,
    lepic.HttpRefusal.unavailable => HttpRefusal.unavailable,
    null => null,
  },
);

HttpRefusal? _refusal(lepic.HttpRefusal? r) => switch (r) {
  lepic.HttpRefusal.rejected => HttpRefusal.rejected,
  lepic.HttpRefusal.unavailable => HttpRefusal.unavailable,
  null => null,
};

TorFailure? _torFailure(lepic.TorFailureKind? f) => switch (f) {
  lepic.TorFailureKind.missing => TorFailure.missing,
  lepic.TorFailureKind.start => TorFailure.start,
  lepic.TorFailureKind.network => TorFailure.network,
  lepic.TorFailureKind.clock => TorFailure.clock,
  lepic.TorFailureKind.listener => TorFailure.listener,
  lepic.TorFailureKind.stopped => TorFailure.stopped,
  lepic.TorFailureKind.publish => TorFailure.publish,
  lepic.TorFailureKind.keys => TorFailure.keys,
  null => null,
};

/// LEPIC's tor event as the app's.
TorEvent lepicTorEvent(lepic.TorEvent e) => TorEvent(
  kind: switch (e.kind) {
    lepic.TorEventKind.starting => TorEventKind.starting,
    lepic.TorEventKind.bootstrapped => TorEventKind.bootstrapped,
    lepic.TorEventKind.publishing => TorEventKind.publishing,
    lepic.TorEventKind.ready => TorEventKind.ready,
    lepic.TorEventKind.failed => TorEventKind.failed,
    lepic.TorEventKind.sending => TorEventKind.sending,
    lepic.TorEventKind.received => TorEventKind.received,
    lepic.TorEventKind.refused => TorEventKind.refused,
    lepic.TorEventKind.stopped => TorEventKind.stopped,
  },
  progress: e.progress,
  onion: e.onion,
  failure: _torFailure(e.failure),
  txId: e.txId,
  amount: e.amount,
  repeated: e.repeated,
  refusal: _refusal(e.refusal),
);

/// LEPIC's listener event as the app's, or null for `invoiceBounced`, which is an issuer
/// event: the session handles it ([lepicListenerBounce]) and the listener's own stream does
/// not show it. `repeated` stays apart from `received`: it is a slate answered before, not a
/// new payment.
ListenerEvent? lepicListenerEvent(lepic.ListenerEvent e) {
  final kind = switch (e.kind) {
    lepic.ListenerEventKind.connected => ListenerEventKind.connected,
    lepic.ListenerEventKind.disconnected => ListenerEventKind.disconnected,
    lepic.ListenerEventKind.received => ListenerEventKind.received,
    lepic.ListenerEventKind.repeated => ListenerEventKind.repeated,
    lepic.ListenerEventKind.finalized => ListenerEventKind.finalized,
    lepic.ListenerEventKind.error => ListenerEventKind.error,
    lepic.ListenerEventKind.stopped => ListenerEventKind.stopped,
    lepic.ListenerEventKind.invoiceBounced => null,
  };
  return kind == null
      ? null
      : ListenerEvent(kind: kind, txId: e.txId, message: e.message);
}

/// The slate id of the issued invoice a listener event says came back unpaid, or null for
/// any other event.
String? lepicListenerBounce(lepic.ListenerEvent e) =>
    e.kind == lepic.ListenerEventKind.invoiceBounced ? e.slateId : null;

/// LEPIC's view of a peer as the app's.
/// The app's send options as LEPIC's.
lepic.SendOptions lepicSendOptions(SendOptions o) => lepic.SendOptions(
  strategy: switch (o.strategy) {
    SelectionStrategy.smallest => lepic.SelectionStrategy.smallest,
    SelectionStrategy.all => lepic.SelectionStrategy.all,
  },
  changeOutputs: o.changeOutputs,
);

FeeEstimate lepicFeeEstimate(lepic.FeeEstimate e) => FeeEstimate(
  amount: e.amount,
  fee: e.fee,
  inputCount: e.inputCount,
  change: e.change,
  locked: e.locked,
  changeOutputs: e.changeOutputs,
);

WalletOutput lepicWalletOutput(lepic.WalletOutput o) => WalletOutput(
  commitment: o.commitment,
  value: o.value,
  status: switch (o.status) {
    lepic.OutputStatus.unconfirmed => WalletOutputStatus.unconfirmed,
    lepic.OutputStatus.unspent => WalletOutputStatus.unspent,
    lepic.OutputStatus.locked => WalletOutputStatus.locked,
    lepic.OutputStatus.spent => WalletOutputStatus.spent,
  },
  category: switch (o.category) {
    null => null,
    lepic.OutputCategory.spendable => OutputCategory.spendable,
    lepic.OutputCategory.awaitingConfirmation =>
      OutputCategory.awaitingConfirmation,
    lepic.OutputCategory.awaitingFinalization =>
      OutputCategory.awaitingFinalization,
    lepic.OutputCategory.immature => OutputCategory.immature,
    lepic.OutputCategory.locked => OutputCategory.locked,
  },
  isCoinbase: o.isCoinbase,
  height: o.height,
  lockHeight: o.lockHeight,
  mmrIndex: o.mmrIndex,
  confirmations: o.confirmations,
  txId: o.txId,
);

SelfSentTx lepicSelfSentTx(lepic.SelfSentTx t) => SelfSentTx(
  txId: t.txId,
  receivedTxId: t.receivedTxId,
  amount: t.amount,
  fee: t.fee,
  inputCount: t.inputCount,
  outputCount: t.outputCount,
);

PeerCapability lepicPeerCapability(lepic.PeerCapability c) => switch (c) {
  lepic.PeerCapability.unknown => PeerCapability.unknown,
  lepic.PeerCapability.lepic => PeerCapability.lepic,
  lepic.PeerCapability.noInvoices => PeerCapability.noInvoices,
};

/// LEPIC's answer to a received slate as the app's, keeping whether it was a repeat.
ReceivedSlate lepicReceivedSlate(lepic.ReceivedSlate s) =>
    ReceivedSlate(slateId: s.slateId, json: s.json, repeated: s.repeated);

/// LEPIC's slate messages as the app's.
List<SlateMessage> lepicMessages(List<lepic.SlateMessage> messages) => [
  for (final m in messages)
    SlateMessage(
      role: switch (m.role) {
        lepic.SlateRole.sender => SlateRole.sender,
        lepic.SlateRole.receiver => SlateRole.receiver,
      },
      text: m.text,
    ),
];

/// A message as LEPIC takes it: trimmed, and none when blank.
String? _message(String? text) {
  final t = text?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// LEPIC's reading of a slate as the old core's. LEPIC names every step; the app tells only a
/// send to sign from an answer to finalize, as the old core did: a finalized S3 reads as an
/// answer, and every invoice step as an invoice, which the app refuses.
SlateInfo lepicSlateInfo(lepic.SlateInfo info) => SlateInfo(
  slateId: info.slateId,
  amount: info.amount,
  fee: info.fee,
  stage: switch (info.stage) {
    lepic.SlateStage.s1 => SlateStage.send,
    lepic.SlateStage.s2 || lepic.SlateStage.s3 => SlateStage.response,
    lepic.SlateStage.i1 ||
    lepic.SlateStage.i2 ||
    lepic.SlateStage.i3 => SlateStage.invoice,
  },
  messages: lepicMessages(info.messages),
);

/// LEPIC's waiting invoice as the app's. LEPIC cleaned the message for display already.
PendingInvoice lepicPendingInvoice(lepic.IncomingInvoice i) => PendingInvoice(
  slateId: i.slateId,
  senderAddress: i.senderAddress,
  amount: i.amount,
  message: i.message,
  receivedAt: DateTime.fromMillisecondsSinceEpoch(i.receivedAtMs),
  expiresAt: DateTime.fromMillisecondsSinceEpoch(i.expiresAtMs),
);

/// LEPIC's drain of the invoice address as the app's.
InvoiceDrainReport lepicInvoiceReport(lepic.InvoiceReport r) =>
    InvoiceDrainReport(
      parked: r.parked,
      finalized: r.finalized,
      dropped: r.dropped,
      notices: r.notices,
    );

/// The invoice event in a LEPIC wallet event, or null for any other event and for the
/// issuer's side (`invoiceFinalized`, `invoiceDeclined`, an expired invoice this wallet
/// issued), which the app, a payer only, does not show. The app's own `declined` comes from
/// [LepicWalletSession.declineInvoice].
InvoiceEvent? lepicInvoiceEvent(lepic.WalletEvent e) {
  final slateId = e.slateId;
  if (slateId == null) return null;
  final kind = switch (e.kind) {
    lepic.WalletEventKind.invoiceReceived => InvoiceEventKind.received,
    lepic.WalletEventKind.invoicePosted => InvoiceEventKind.posted,
    lepic.WalletEventKind.invoiceWithdrawn => InvoiceEventKind.withdrawn,
    lepic.WalletEventKind.invoiceExpired when e.txId == null =>
      InvoiceEventKind.expired,
    _ => null,
  };
  if (kind == null) return null;
  return InvoiceEvent(
    kind: kind,
    slateId: slateId,
    kernelExcess: kind == InvoiceEventKind.posted ? e.kernelExcess : null,
  );
}

/// The issuer's side of a LEPIC wallet event: the state an invoice this wallet issued moved
/// to, or null for any other event. `invoiceExpired` is the issuer's only with a `txId`
/// (LEPIC cancelled it); without one it was a waiting invoice to pay.
({String slateId, IssuedInvoiceState state})? lepicIssuerEvent(
  lepic.WalletEvent e,
) {
  final slateId = e.slateId;
  if (slateId == null) return null;
  final state = switch (e.kind) {
    lepic.WalletEventKind.invoiceFinalized => IssuedInvoiceState.paid,
    lepic.WalletEventKind.invoiceDeclined => IssuedInvoiceState.declined,
    lepic.WalletEventKind.invoiceExpired when e.txId != null =>
      IssuedInvoiceState.expired,
    lepic.WalletEventKind.invoiceBounced => IssuedInvoiceState.bounced,
    _ => null,
  };
  return state == null ? null : (slateId: slateId, state: state);
}

/// [label] as LEPIC stores it beside a sender: no control characters, at most 64 bytes, cut
/// on a character boundary. The app's full label stays in `wfe_meta.json`.
String lepicSenderLabel(String label) {
  final clean = label
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f-\u009f]'), ' ')
      .trim();
  final out = StringBuffer();
  var bytes = 0;
  for (final rune in clean.runes) {
    final char = String.fromCharCode(rune);
    final size = utf8.encode(char).length;
    if (bytes + size > 64) break;
    out.write(char);
    bytes += size;
  }
  return out.toString().trim();
}

/// The local transaction id in a history key this service made (`l:<id>`).
int lepicTxId(String key) {
  final id = key.startsWith('l:') ? int.tryParse(key.substring(2)) : null;
  if (id == null) {
    throw WalletError(
      kind: WalletErrorKind.invalidArgument,
      message: 'not a LEPIC transaction key: $key',
    );
  }
  return id;
}

/// A LEPIC transaction as a history row. Keys are `l:<tx id>` ([lepicTxId]). Notes, contacts
/// and imported rows are the app's (H-01), so `note` stays empty here; `messages` are the
/// slate's, which LEPIC verified.
TxEntry lepicTxEntry(lepic.TransactionDetails d) {
  final outgoing = d.direction == lepic.TxDirection.outgoing;
  final ended =
      d.status == lepic.TxStatus.cancelled ||
      d.status == lepic.TxStatus.expired;
  final status = switch (d.status) {
    lepic.TxStatus.sent => TxStatus.awaitingRecipient,
    lepic.TxStatus.received ||
    lepic.TxStatus.finalized ||
    lepic.TxStatus.posted => TxStatus.awaitingConfirmation,
    lepic.TxStatus.confirmed => TxStatus.confirmed,
    lepic.TxStatus.cancelled || lepic.TxStatus.expired => TxStatus.cancelled,
  };
  final createdAt = d.createdAtMs ~/ 1000;
  final confirmedAt = d.confirmedAtMs == null ? null : d.confirmedAtMs! ~/ 1000;
  final imported = d.imported;
  // An output a scan found with no record; also one the old wallet's own scan found, which it
  // knew no more about.
  final foundByScan =
      d.origin == lepic.TxOrigin.foundByScan ||
      (imported != null &&
          imported.kind == lepic.ImportedTxKind.received &&
          d.slateId == null);
  return TxEntry(
    key: 'l:${d.txId}',
    id: d.txId,
    slateId: d.slateId,
    kind: imported?.kind == lepic.ImportedTxKind.coinbase
        ? TxKind.coinbase
        : switch ((outgoing, ended)) {
            (true, false) => TxKind.sent,
            (true, true) => TxKind.sentCancelled,
            (false, false) => TxKind.received,
            (false, true) => TxKind.receivedCancelled,
          },
    status: status,
    source: foundByScan ? TxSource.restored : TxSource.wallet,
    createdAtUnix: createdAt,
    timeUnix: confirmedAt ?? createdAt,
    confirmed: status == TxStatus.confirmed,
    blockHeight: d.confirmedHeight,
    blockTimeUnix: confirmedAt,
    amountCredited: d.amountCredited,
    amountDebited: d.amountDebited,
    fee: d.fee,
    numInputs: imported?.inputCount ?? 0,
    numOutputs: imported?.outputCount ?? 0,
    kernelExcess: d.kernelExcess,
    outputCommits: const [],
    counterparty: d.counterparty,
    transport: d.transport,
    messages: lepicMessages(d.messages),
    ttlCutoffHeight: d.ttlCutoffHeight,
    cancellable:
        d.status == lepic.TxStatus.sent || d.status == lepic.TxStatus.received,
    // Finalized but refused by the node: LEPIC stores it for a repost.
    repostable: d.status == lepic.TxStatus.finalized,
    releasable: d.releasable,
    cancelReason: d.status == lepic.TxStatus.expired
        ? CancelReason.expiry
        : null,
    statusDetail: imported == null ? null : importedDetail(d, imported),
    flow: switch (d.flow) {
      lepic.TxFlow.payment => TxFlow.payment,
      lepic.TxFlow.invoice => TxFlow.invoice,
    },
  );
}

/// Where an imported transaction came from and how the blockchain judged it, in words.
String importedDetail(lepic.TransactionDetails d, lepic.ImportedTx imported) {
  final open =
      d.status == lepic.TxStatus.sent ||
      d.status == lepic.TxStatus.received ||
      d.status == lepic.TxStatus.finalized ||
      d.status == lepic.TxStatus.posted;
  return switch (imported.check) {
    lepic.ChainCheck.cancelledButOnChain =>
      'The older wallet had cancelled this, but the blockchain has it, so the funds count.',
    lepic.ChainCheck.unspentNotOnChain =>
      'The older wallet showed these funds as unspent, but the blockchain does not have them, '
          'so they are not in the balance.',
    _ when open =>
      'Started in the older wallet and not finished there. Finish or cancel it in the older '
          'wallet; cancelling it here only hides it.',
    _ => 'Imported from the older wallet, where it was transaction ${imported.sourceId}.',
  };
}

/// Prefixes every key, so each wallet's LEPIC vault stays apart from the app's other secrets.
class _PrefixedStore implements lepic.SecretStore {
  _PrefixedStore(this._inner, this._prefix);

  final SecretStore _inner;
  final String _prefix;

  @override
  Future<String?> read(String key) => _inner.read('$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _inner.write('$_prefix$key', value);

  @override
  Future<void> delete(String key) => _inner.delete('$_prefix$key');
}

class LepicWalletService implements WalletService {
  /// [runtime] is called once, on first use; tests pass a `MockChain` runtime.
  ///
  /// With [oneWalletPerChain] (the app on a device), a chain's store keys stay the same when
  /// its data directory moves ([_storePrefix]). The demo server and tests keep several wallets
  /// of one chain in one store, so theirs follow the directory.
  LepicWalletService({
    required this._secrets,
    lepic.LepicRuntime Function()? runtime,
    this.oneWalletPerChain = false,
  }) : _makeRuntime = runtime ?? _defaultRuntime;

  final SecretStore _secrets;
  final bool oneWalletPerChain;

  /// The prefix pinned for each chain, once read.
  final Map<Chain, String> _pinnedPrefixes = {};
  final lepic.LepicRuntime Function() _makeRuntime;
  lepic.LepicRuntime? _runtimeValue;

  /// Chain of the last wallet config seen, for [validateEpicboxAddress] and [inspectSlate],
  /// which the interface asks without one.
  Chain _chain = Chain.mainnet;

  /// One runtime for every service built without `runtime:`: the demo server makes a service
  /// per demo, and they share LEPIC's pool and log stream. The phone builds one service.
  static lepic.LepicRuntime? _shared;

  static lepic.LepicRuntime _defaultRuntime() => _shared ??= _newRuntime();

  static lepic.LepicRuntime _newRuntime() {
    // LEPIC has no level setter: Detailed logging reaches it when the runtime starts.
    final runtime = lepic.LepicRuntime(
      logLevel: AppLog.detailed ? lepic.LogLevel.debug : lepic.LogLevel.info,
    );
    // The stream's error reaches the zone instead (UP-11); onError covers a future pin.
    runtime.logs().listen(
      logLepicEntry,
      onError: (Object error) => logWarn('lepic', 'log stream ended: $error'),
    );
    return runtime;
  }

  lepic.LepicRuntime get _runtime => _runtimeValue ??= _makeRuntime();

  /// LEPIC keeps its database in a subdirectory, so it never meets epic-wallet's `wallet_data/`
  /// or the app's `wfe_meta.json` beside it.
  lepic.WalletConfig _config(WalletConfig config) {
    _chain = config.chain;
    final dir = Directory('${config.dataDir}${Platform.pathSeparator}lepic')
      ..createSync(recursive: true);
    return _lepicConfig(config, dir.path);
  }

  static lepic.WalletConfig _lepicConfig(WalletConfig config, String dataDir) =>
    lepic.WalletConfig(
      dataDir: dataDir,
      chain: _lepicChain(config.chain),
      nodeUrl: config.nodeUrl,
      nodeApiSecret: config.nodeApiSecret,
      epicboxDomain: config.epicboxDomain,
      epicboxPort: config.epicboxPort,
    );

  /// `<anything>/wallets/<32 hex>/<chain>`, the folder of a registry wallet.
  static final RegExp _registryFolder = RegExp(
    r'[\\/]wallets[\\/][0-9a-f]{32}[\\/](mainnet|floonet|usernet)[\\/]?$',
  );

  /// The prefix of the wallet's LEPIC entries in the app's store.
  ///
  /// It used to name the absolute data directory, which moves with an app container or a
  /// profile. With [oneWalletPerChain] the prefix is pinned once per chain under
  /// [storePrefixKey]: a wallet created before pinning keeps the path prefix its entries
  /// already have, and a new wallet gets a random id. Nothing is copied or deleted. Until a
  /// prefix is pinned, everything but [creating] uses the path prefix. A registry wallet
  /// ([WalletConfig.walletId], other than `legacy-…`) skips all that: its prefix is
  /// `lepic:<chain>:id-<walletId>:`.
  Future<String> _storePrefix(
    WalletConfig config, {
    bool creating = false,
  }) async {
    final chain = config.chain;
    final id = config.walletId;
    if (id != null && !id.startsWith('legacy-')) {
      return 'lepic:${chain.name}:id-$id:';
    }
    final pathPrefix = 'lepic:${chain.name}:${config.dataDir}:';
    if (!oneWalletPerChain) return pathPrefix;
    if (id == null && _registryFolder.hasMatch(config.dataDir)) {
      // A registry wallet's config lost its id: wallet 1's pinned prefix would be wrong.
      throw StateError('a registry wallet config needs its walletId');
    }
    final cached = _pinnedPrefixes[chain];
    if (cached != null) return cached;
    final pinKey = storePrefixKey(chain);
    final pinned = await _secrets.read(pinKey);
    if (pinned != null) return _pinnedPrefixes[chain] = pinned;
    final String prefix;
    if (await lepic.walletExists(
      runtime: _runtime,
      store: lepic.lepicSecretStore(_PrefixedStore(_secrets, pathPrefix)),
    )) {
      prefix = pathPrefix;
    } else if (creating) {
      final random = Random.secure();
      final id = [
        for (var i = 0; i < 16; i++)
          random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
      prefix = 'lepic:${chain.name}:id-$id:';
    } else {
      return pathPrefix;
    }
    await _secrets.write(pinKey, prefix);
    if (await _secrets.read(pinKey) != prefix) {
      throw StateError('the store did not keep the wallet key prefix');
    }
    logInfo('lepic', 'pinned the ${chain.name} wallet store keys');
    return _pinnedPrefixes[chain] = prefix;
  }

  /// [_storePrefix] for tests. A registry wallet's prefix needs no runtime or pin.
  @visibleForTesting
  Future<String> storePrefixFor(WalletConfig config) => _storePrefix(config);

  /// Where the store keeps the pinned prefix of [chain]'s wallet entries.
  static String storePrefixKey(Chain chain) =>
      'lepic:${chain.name}:storePrefix';

  Future<_PrefixedStore> _storeKeys(
    WalletConfig config, {
    bool creating = false,
  }) async =>
      _PrefixedStore(_secrets, await _storePrefix(config, creating: creating));

  Future<lepic.AppSecretStore> _store(
    WalletConfig config, {
    bool creating = false,
  }) async =>
      lepic.lepicSecretStore(await _storeKeys(config, creating: creating));

  @override
  bool validateMnemonic({required String phrase}) =>
      lepic.validateMnemonic(phrase: phrase);

  @override
  Future<SlateInfo> inspectSlate({required String json}) => _guard(
    () async => lepicSlateInfo(
      await lepic.inspectSlate(json: json, chain: _lepicChain(_chain)),
    ),
  );

  @override
  bool validateEpicboxAddress({required String address}) => lepic
      .validateEpicboxAddress(address: address, chain: _lepicChain(_chain));

  @override
  bool validateOnionAddress({required String address}) =>
      lepic.validateOnionAddress(address: address);

  @override
  Future<bool> walletExists({required WalletConfig config}) => _guard(
    () async =>
        lepic.walletExists(runtime: _runtime, store: await _store(config)),
  );

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) => _guard(() async {
    // LEPIC asks the node only: no wallet folder is made (the setup screen's test passes an
    // empty one, which made `/lepic` and failed) and the open wallet's chain stays.
    final tip = await lepic.nodeTip(
      runtime: _runtime,
      config: _lepicConfig(config, config.dataDir),
    );
    return NodeTip(
      height: tip.height,
      nodeVersion: tip.nodeVersion,
      readyForTxs: tip.readyForTxs,
    );
  });

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  }) => _guard(
    () async => _session(
      config,
      await lepic.EpicWallet.create(
        runtime: _runtime,
        config: _config(config),
        store: await _store(config, creating: true),
        mnemonic: mnemonic,
        password: password,
      ),
    ),
  );

  @override
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  }) => _guard(
    () async => _session(
      config,
      await lepic.EpicWallet.importWalletSeed(
        runtime: _runtime,
        config: _config(config),
        store: await _store(config, creating: true),
        seedFile: seedFile,
        seedPassword: seedPassword,
        password: password,
      ),
    ),
  );

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) => _guard(
    () async => _session(
      config,
      await lepic.EpicWallet.open(
        runtime: _runtime,
        config: _config(config),
        store: await _store(config),
        password: password,
      ),
    ),
  );

  /// [wallet] with its history archive, `<dataDir>/wfe_meta.json`. A wallet whose archive
  /// cannot be read is closed again.
  Future<LepicWalletSession> _session(
    WalletConfig config,
    lepic.EpicWallet wallet,
  ) async {
    try {
      return await LepicWalletSession.openOn(
        wallet,
        config.dataDir,
        config.chain,
      );
    } catch (_) {
      wallet.lock();
      wallet.dispose();
      rethrow;
    }
  }

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) => _guard(() async {
    final created = await lepic.EpicWallet.createWithPin(
      runtime: _runtime,
      config: _config(config),
      store: await _store(config, creating: true),
      mnemonic: mnemonic,
      pin: pin,
    );
    return (
      session: await _session(config, created.wallet) as WalletSession,
      sealedPassword: created.sealedPassword,
    );
  });

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) => _guard(
    () async => _session(
      config,
      await lepic.EpicWallet.openWithPin(
        runtime: _runtime,
        config: _config(config),
        store: await _store(config),
        pin: pin,
        sealedPassword: sealedPassword,
      ),
    ),
  );

  /// LEPIC keeps the count in the wallet's store as `lepic.pin-failures` (documented on
  /// `EpicWallet.openWithPin`). A count that does not parse costs LEPIC the longest wait, so it
  /// reads as a large one here too.
  @override
  Future<int> pinFailures({required WalletConfig config}) async {
    final text = await (await _storeKeys(config)).read('lepic.pin-failures');
    if (text == null) return 0;
    return int.tryParse(text.trim()) ?? 0x7fffffff;
  }

  @override
  Future<void> deleteWallet({required WalletConfig config}) => _guard(() async {
    await lepic.deleteWallet(
      runtime: _runtime,
      config: _config(config),
      store: await _store(config),
    );
    // After LEPIC, which refuses while a wallet on the directory is open.
    await MetaStore.deleteFiles(config.dataDir);
  });
}

/// What a history file names as the program that wrote it. Informational only.
const String historyAppVersion = 'wfe-lepic';

/// An open LEPIC wallet. Public so tests can wrap a stand-in `EpicWallet`; without [history]
/// it keeps notes and contacts in memory only.
class LepicWalletSession implements WalletSession {
  /// [validateAddress] stands in for LEPIC's `validateEpicboxAddress` on the history's
  /// chain, so tests need no native library.
  LepicWalletSession(
    this._wallet, {
    WalletHistory? history,
    this._validateAddress,
  }) : _history = history ?? WalletHistory.memory();

  final bool Function(String address)? _validateAddress;

  bool _validAddress(String address) =>
      _validateAddress?.call(address) ??
      lepic.validateEpicboxAddress(
        address: address,
        chain: _lepicChain(_history.chain),
      );

  /// [wallet] with the archive in [dataDir], and LEPIC given the invoice index kept there,
  /// as every open does. Public so tests can drive it with a stand-in wallet.
  @visibleForTesting
  static Future<LepicWalletSession> openOn(
    lepic.EpicWallet wallet,
    String dataDir,
    Chain chain,
  ) async {
    final history = await WalletHistory.open(dataDir, chain);
    final session = LepicWalletSession(wallet, history: history);
    await session.restoreInvoiceIndex();
    return session;
  }

  final lepic.EpicWallet _wallet;
  final WalletHistory _history;

  @override
  void dispose() {
    _walletEvents?.cancel();
    _walletEvents = null;
    _invoiceEvents.close();
    _issuerEvents.close();
    _history.close();
    if (_wallet.isDisposed) return;
    _wallet.lock();
    _wallet.dispose();
  }

  /// LEPIC's rows, before the archive is merged in.
  Future<List<TxEntry>> _live() async => [
    for (final d in await _wallet.transactions()) lepicTxEntry(d),
  ];

  /// The stored row of [txId], as the history shows it.
  Future<TxEntry> _entry(int txId) async {
    final live = await _live();
    final shown = _history
        .transactions(live)
        .where((t) => t.id == txId)
        .firstOrNull;
    return shown ?? lepicTxEntry(await _wallet.transaction(txId: txId));
  }

  /// The LEPIC id behind a history key: `l:<id>`, or the row shown under [key].
  Future<int> _txIdOf(String key) async {
    if (key.startsWith('l:')) return lepicTxId(key);
    final id = _history
        .transactions(await _live())
        .where((t) => t.key == key)
        .firstOrNull
        ?.id;
    return id ?? lepicTxId(key);
  }

  @override
  Future<String> mnemonic({required String password}) =>
      _guard(() => _wallet.mnemonic(password: password));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(
    () => _wallet.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) => _guard(
    () => _wallet.mnemonicWithPin(pin: pin, sealedPassword: sealedPassword),
  );

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) => _guard(
    () => _wallet.changePin(
      sealedPassword: sealedPassword,
      oldPin: oldPin,
      newPin: newPin,
    ),
  );

  @override
  Future<void> confirmPinChange({required String sealedPassword}) =>
      _guard(() => _wallet.confirmPinChange(sealedPassword: sealedPassword));

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _guard(() => _wallet.cancelTransaction(txId: txId));

  @override
  Future<void> repostTransaction({required String key}) =>
      _guard(() async => _wallet.repostTransaction(txId: await _txIdOf(key)));

  @override
  Future<void> releaseStuckSend({required String key}) =>
      _guard(() async => _wallet.releaseTransaction(txId: await _txIdOf(key)));

  /// The amount [estimateMax] last returned. A send of exactly the wallet's current maximum is
  /// a send-all and takes every coin into one change output, as the max estimate did, so fee
  /// and amount match.
  BigInt? _maxAmount;

  static const _sendAll = lepic.SendOptions(
    strategy: lepic.SelectionStrategy.all,
    changeOutputs: 1,
  );

  /// The caller's [options] when given. Else send-all when [amount] is still the wallet's
  /// maximum, checked again now: a max remembered from before the balance changed must not
  /// turn a typed amount into a send-all. Null (LEPIC's default) otherwise.
  Future<lepic.SendOptions?> _optionsFor(
    BigInt amount,
    BigInt minimumConfirmations, [
    SendOptions? options,
  ]) async {
    if (options != null) return lepicSendOptions(options);
    if (_maxAmount == null || amount != _maxAmount) return null;
    final now = await _wallet.estimateMax(
      minimumConfirmations: minimumConfirmations,
      options: _sendAll,
    );
    _maxAmount = now.amount;
    return now.amount == amount ? _sendAll : null;
  }

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _guard(() async {
    final slate = await _wallet.createSendSlate(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      message: _message(message),
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return Slate(slateId: slate.slateId, json: slate.json);
  });

  @override
  Future<String> epicboxAddress() => _guard(_wallet.epicboxAddress);

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) => _guard(() async {
    final e = await _wallet.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return lepicFeeEstimate(e);
  });

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _guard(() async {
        final e = await _wallet.estimateMax(
          minimumConfirmations: minimumConfirmations,
          options: _sendAll,
        );
        _maxAmount = e.amount;
        return lepicFeeEstimate(e);
      });

  @override
  Future<List<WalletOutput>> outputs() => _guard(() async {
    final list = await _wallet.outputs();
    return [for (final o in list) lepicWalletOutput(o)];
  });

  @override
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _guard(
    () async => lepicFeeEstimate(
      await _wallet.estimateSplit(
        outputs: outputs,
        minimumConfirmations: minimumConfirmations,
      ),
    ),
  );

  @override
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _guard(
    () async => lepicSelfSentTx(
      await _wallet.splitOutputs(
        outputs: outputs,
        minimumConfirmations: minimumConfirmations,
      ),
    ),
  );

  @override
  Future<FeeEstimate> estimateConsolidate({
    required BigInt minimumConfirmations,
  }) => _guard(
    () async => lepicFeeEstimate(
      await _wallet.estimateConsolidate(
        minimumConfirmations: minimumConfirmations,
      ),
    ),
  );

  @override
  Future<SelfSentTx> consolidateOutputs({
    required BigInt minimumConfirmations,
  }) => _guard(
    () async => lepicSelfSentTx(
      await _wallet.consolidateOutputs(
        minimumConfirmations: minimumConfirmations,
      ),
    ),
  );

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) =>
      _guard(() async {
        final tx = await _wallet.finalizeAndPost(slateJson: slateJson);
        return _entry(tx.txId);
      });

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) => _guard(() async {
    final tx = await _wallet.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: _message(message),
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return _entry(tx.txId);
  });

  @override
  Stream<ListenerEvent> startListener() => _guardStream(
    _wallet.startListener().expand((e) {
      final bounced = lepicListenerBounce(e);
      if (bounced != null) _onBounce(bounced);
      final event = lepicListenerEvent(e);
      return event == null ? const <ListenerEvent>[] : [event];
    }),
  );

  @override
  Future<void> stopListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopListener);
  }

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
  }) => _guard(() async {
    final tx = await _wallet.sendHttp(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      url: url,
      allowPlainHttp: allowPlainHttp,
      message: _message(message),
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
  });

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) => _guard(() async {
    final tx = await _wallet.resendHttp(
      txId: txId,
      url: url,
      allowPlainHttp: allowPlainHttp,
    );
    return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
  });

  @override
  Stream<HttpListenerEvent> startHttpListener({
    required HttpExposure exposure,
    required int port,
  }) => _guardStream(
    _wallet
        .startHttpListener(exposure: _lepicExposure(exposure), port: port)
        .map(lepicHttpEvent),
  );

  @override
  Future<void> stopHttpListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopHttpListener);
  }

  @override
  Future<String> onionAddress() => _guard(_wallet.onionAddress);

  @override
  Stream<TorEvent> startTor({required String torBinary, String? libDir}) =>
      _guardStream(
        _wallet
            .startTor(torBinary: torBinary, libDir: libDir)
            .map(lepicTorEvent),
      );

  @override
  Future<void> stopTor() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopTor);
  }

  @override
  Future<void> refreshTor({required bool networkChanged}) => _guard(
    () => _wallet.refreshTor(networkChanged: networkChanged),
  );

  @override
  Future<TorStatus> torStatus() async {
    if (_wallet.isDisposed) return TorStatus.off;
    final s = _guardSync(_wallet.torStatus);
    return TorStatus(
      kind: switch (s.kind) {
        lepic.TorStatusKind.off => TorStatusKind.off,
        lepic.TorStatusKind.starting => TorStatusKind.starting,
        lepic.TorStatusKind.bootstrapped => TorStatusKind.bootstrapped,
        lepic.TorStatusKind.publishing => TorStatusKind.publishing,
        lepic.TorStatusKind.ready => TorStatusKind.ready,
      },
      progress: s.progress,
      onion: s.onion,
      failure: _torFailure(s.failure),
    );
  }

  @override
  Future<HttpSent> sendTor({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String onion,
    String? message,
  }) => _guard(() async {
    final tx = await _wallet.sendTor(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      onion: onion,
      message: _message(message),
    );
    return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
  });

  @override
  Future<HttpSent> resendTor({required int txId, required String onion}) =>
      _guard(() async {
        final tx = await _wallet.resendTor(txId: txId, onion: onion);
        return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
      });

  @override
  Future<HttpListenerInfo?> httpListenerStatus() async {
    if (_wallet.isDisposed) return null;
    final info = _guardSync(_wallet.httpListenerStatus);
    return info == null
        ? null
        : HttpListenerInfo(
            port: info.port,
            exposure: switch (info.exposure) {
              lepic.HttpExposure.localOnly => HttpExposure.localOnly,
              lepic.HttpExposure.internet => HttpExposure.internet,
            },
          );
  }

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) => _guard(
    () async =>
        lepicReceivedSlate(await _wallet.receiveSlate(slateJson: slateJson)),
  );

  @override
  Stream<ScanProgress> scan({
    BigInt? startHeight,
    bool deleteUnconfirmed = false,
  }) => _guardStream(
    _wallet
        .scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed)
        // cancelScan ends the stream with `cancelled`: a stop, not a failure.
        .handleError(
          (Object _) {},
          test: (e) =>
              e is lepic.WalletError &&
              e.kind == lepic.WalletErrorKind.cancelled,
        )
        .map(
          (p) => ScanProgress(
            percent: p.percent,
            message: p.message,
            finished: p.finished,
            result: switch (p.result) {
              final r? => ScanResult(
                resumed: r.resumed,
                found: r.found.toInt(),
                restored: r.restored.toInt(),
                revived: r.revived.toInt(),
                unlocked: r.unlocked.toInt(),
                deleted: r.deleted.toInt(),
              ),
              null => null,
            },
          ),
        ),
  );

  @override
  void cancelScan() {
    if (!_wallet.isDisposed) _guardSync(_wallet.cancelScan);
  }

  /// LEPIC counts balances with its own confirmations and reports them in the summary
  /// (`countedConfirmationsProvider`), so [minimumConfirmations] changes nothing.
  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _guard(() async => _summary(await _wallet.summary(refresh: refresh)));

  /// As the old core: with the node out of reach the refresh still ends with the local balances,
  /// marked as not checked with the node, so Home shows them instead of an error.
  @override
  Stream<RefreshProgress> refresh({
    required BigInt minimumConfirmations,
  }) async* {
    try {
      // `await for`, not `yield*`: only it raises the stream's error here.
      await for (final p in _guardStream(_wallet.refresh())) {
        yield RefreshProgress(
          percent: p.percent,
          message: p.message,
          summary: p.summary == null ? null : _summary(p.summary!),
        );
      }
    } on WalletError catch (error) {
      if (error.kind != WalletErrorKind.nodeUnreachable) rethrow;
      final local = _summary(
        await _guard(() => _wallet.summary(refresh: false)),
      );
      yield RefreshProgress(
        percent: 100,
        message: 'Could not reach the node',
        summary: WalletSummary(
          lastConfirmedHeight: local.lastConfirmedHeight,
          minimumConfirmations: local.minimumConfirmations,
          total: local.total,
          spendable: local.spendable,
          awaitingConfirmation: local.awaitingConfirmation,
          awaitingFinalization: local.awaitingFinalization,
          immature: local.immature,
          locked: local.locked,
          validatedWithNode: false,
        ),
      );
    }
  }

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) =>
      _guard(() async {
        if (refresh) await _wallet.summary(refresh: true);
        return _history.transactions(await _live());
      });

  /// LEPIC stores heights and times as it confirms, so nothing is left to fill in.
  @override
  Future<int> enrichHistory() async => 0;

  @override
  Future<void> setTxNote({required String key, String? note}) =>
      _guard(() async => _history.setNote(await _live(), key, note));

  @override
  Future<List<Contact>> contacts() async => _history.contacts();

  @override
  Future<Contact> saveContact({required Contact contact}) =>
      _history.saveContact(contact);

  @override
  Future<void> deleteContact({required String id}) =>
      _history.deleteContact(id);

  /// The history as a `.wfeh` file LEPIC seals under a key from the seed, so only a wallet
  /// with the same recovery phrase opens it.
  @override
  Future<Uint8List> exportHistory() => _guard(() async {
    final payload = _history.exportPayload(
      await _live(),
      walletFp: walletFingerprint(await _wallet.epicboxAddress()),
      appVersion: historyAppVersion,
      lastConfirmedHeight: (await _wallet.summary(refresh: false))
          .lastConfirmedHeight,
    );
    return _wallet.sealAppData(payload: payload.encode());
  });

  @override
  Future<String> exportHistoryCsv() => _guard(() async {
    final tip = (await _wallet.summary(refresh: false)).lastConfirmedHeight;
    return _history.csv(await _live(), tip);
  });

  @override
  Future<ImportReport> importHistory({required Uint8List data}) =>
      _guard(() async {
        final payload = HistoryPayload.decode(await _openHistoryFile(data));
        final report = await _history.importPayload(
          payload,
          await _live(),
          walletFp: walletFingerprint(await _wallet.epicboxAddress()),
        );
        // The file may carry the invoice index from before a restore.
        await restoreInvoiceIndex();
        return report;
      });

  @override
  Future<LegacyHistoryImport> importLegacyHistory({required String sourceDir}) =>
      _guard(() async {
        final r = await _wallet.importLegacyHistory(sourceDir: sourceDir);
        return LegacyHistoryImport(
          status: switch (r.status) {
            lepic.LegacyImportStatus.imported => LegacyHistoryStatus.imported,
            lepic.LegacyImportStatus.alreadyImported =>
              LegacyHistoryStatus.alreadyImported,
            lepic.LegacyImportStatus.noHistory => LegacyHistoryStatus.noHistory,
            lepic.LegacyImportStatus.oldFormat => LegacyHistoryStatus.oldFormat,
            lepic.LegacyImportStatus.unreadable => LegacyHistoryStatus.unreadable,
            lepic.LegacyImportStatus.sourceBusy => LegacyHistoryStatus.sourceBusy,
            lepic.LegacyImportStatus.tooLarge => LegacyHistoryStatus.tooLarge,
            lepic.LegacyImportStatus.otherWallet => LegacyHistoryStatus.otherWallet,
            lepic.LegacyImportStatus.otherHistory =>
              LegacyHistoryStatus.otherHistory,
          },
          transactions: r.transactions,
          linked: r.linked,
          skipped: r.skipped,
        );
      });

  /// LEPIC's answer for a history file, in the old core's sentences the UI translates.
  Future<Uint8List> _openHistoryFile(Uint8List data) async {
    try {
      return await _wallet.openAppData(file: data);
    } on lepic.WalletError catch (e) {
      throw switch (e.kind) {
        lepic.WalletErrorKind.foreignAppData => historyError(
          historyOtherWallet,
        ),
        lepic.WalletErrorKind.damagedAppData => historyError(historyDamaged),
        lepic.WalletErrorKind.unsupported => historyError(historyNewer),
        lepic.WalletErrorKind.invalidArgument => historyError(historyNotOurs),
        _ => mapLepicError(e),
      };
    }
  }

  // Invoices over epicbox (UP-14). LEPIC keeps the invoice address, the allowlist and the
  // waiting invoices; the app keeps the labels, the invoice index and what became of each
  // invoice it paid, in `wfe_meta.json`. Nothing here pays but [payInvoice], which only the
  // review screen calls after the PIN or biometric gate; no event leads to it.

  /// The confirmations LEPIC's balance counts a coin spendable with, so an invoice is paid
  /// from what the balance shows as spendable.
  Future<BigInt> _balanceConfirmations() async =>
      (await _wallet.summary(refresh: false)).minimumConfirmations;

  BigInt get _expirySecs => BigInt.from(invoiceExpiry.inSeconds);

  StreamSubscription<lepic.WalletEvent>? _walletEvents;
  final StreamController<InvoiceEvent> _invoiceEvents =
      StreamController<InvoiceEvent>.broadcast();
  final StreamController<IssuerEvent> _issuerEvents =
      StreamController<IssuerEvent>.broadcast();

  /// Events are handled one at a time, so the archive changes in the order LEPIC reported.
  /// A withdrawal and a reconcile of issued invoices take their turn here too.
  Future<void> _eventTail = Future.value();

  /// Runs [step] after every event and step before it.
  Future<T> _inTurn<T>(Future<T> Function() step) {
    final result = _eventTail.then((_) => step());
    _eventTail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Subscribes to LEPIC's events on the first invoice call, so a notice found by a drain
  /// updates the archive before the app's event goes out.
  void _watchEvents() {
    if (_walletEvents != null || _wallet.isDisposed) return;
    _walletEvents = _wallet.events().listen(
      (e) => unawaited(
        _inTurn(() => _onWalletEvent(e))
        // One failed event must not stop the ones after it.
        .catchError(
          (Object error) =>
              logWarn('invoices', 'invoice event failed: ${error.runtimeType}'),
        ),
      ),
      onError: (Object error) =>
          logWarn('invoices', 'wallet events ended: $error'),
    );
  }

  Future<void> _onWalletEvent(lepic.WalletEvent e) async {
    final issued = lepicIssuerEvent(e);
    if (issued != null) return _onIssuerEvent(issued.slateId, issued.state);
    final event = lepicInvoiceEvent(e);
    if (event == null) return;
    try {
      switch (event.kind) {
        case InvoiceEventKind.posted:
          await _history.setPaidInvoiceStatus(
            event.slateId,
            InvoiceStatus.posted,
            kernelExcess: event.kernelExcess,
          );
        case InvoiceEventKind.withdrawn:
          // Only a paid one has a record; a waiting one LEPIC deleted itself.
          await _history.setPaidInvoiceStatus(
            event.slateId,
            InvoiceStatus.withdrawn,
          );
        case InvoiceEventKind.received ||
            InvoiceEventKind.declined ||
            InvoiceEventKind.expired:
          break;
      }
    } on WalletError catch (error) {
      logWarn(
        'invoices',
        'could not record an invoice notice: ${error.kind.name}',
      );
    }
    if (!_invoiceEvents.isClosed) _invoiceEvents.add(event);
  }

  /// Gives LEPIC the invoice index the archive kept, or records LEPIC's when it is ahead, so
  /// a restored wallet with its history file keeps the address services were given. Never
  /// fails the caller: without a relay LEPIC has no invoice address, and the app still opens.
  Future<void> restoreInvoiceIndex() async {
    try {
      final current = await _wallet.invoiceAddressIndex();
      final kept = _history.meta.invoiceIndex;
      if (kept != null && kept > current) {
        await _wallet.setInvoiceAddressIndex(index: kept);
        logInfo('invoices', 'invoice address index restored');
      } else if (current > _history.invoiceIndex) {
        await _history.setInvoiceIndex(current);
      }
    } on lepic.WalletError catch (error) {
      logWarn('invoices', 'invoice index not synced: ${error.kind.name}');
    } on WalletError catch (error) {
      logWarn('invoices', 'invoice index not recorded: ${error.kind.name}');
    }
  }

  @override
  bool get supportsInvoices => true;

  @override
  Future<String> invoiceAddress() => _guard(_wallet.invoiceAddress);

  @override
  Future<String> rotateInvoiceAddress() => _guard(() async {
    final address = await _wallet.rotateInvoiceAddress();
    final index = await _wallet.invoiceAddressIndex();
    if (index > _history.invoiceIndex) await _history.setInvoiceIndex(index);
    return address;
  });

  @override
  Future<List<TrustedService>> trustedServices() => _guard(() async {
    final senders = await _wallet.invoiceSenders();
    final labelled = _history.trustedServices([
      for (final s in senders) s.address,
    ]);
    return [
      for (var i = 0; i < senders.length; i++)
        labelled[i].label != null || senders[i].label.isEmpty
            ? labelled[i]
            : TrustedService(
                address: senders[i].address,
                label: senders[i].label,
              ),
    ];
  });

  @override
  Future<TrustedService> addTrustedService({
    required String address,
    required String label,
  }) => _guard(() async {
    final a = address.trim();
    final name = label.trim();
    if (name.isEmpty) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the service needs a label',
      );
    }
    final key = epicboxKey(a);
    final own = [
      await _wallet.epicboxAddress(),
      await _wallet.invoiceAddress(),
    ];
    if (own.any((o) => epicboxKey(o) == key)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'this is one of your own addresses',
      );
    }
    final previous = [
      for (final s in await _wallet.invoiceSenders())
        if (epicboxKey(s.address) == key && s.address != a) s.address,
    ];
    final sender = await _wallet.allowInvoiceSender(
      address: a,
      label: lepicSenderLabel(name),
    );
    for (final p in previous) {
      await _history.removeServiceLabel(p);
    }
    await _history.setServiceLabel(sender.address, name);
    return TrustedService(address: sender.address, label: name);
  });

  @override
  Future<void> removeTrustedService({required String address}) =>
      _guard(() async {
        final key = epicboxKey(address);
        await _wallet.removeInvoiceSender(address: address.trim());
        for (final a in _history.meta.serviceLabels.keys.toList()) {
          if (epicboxKey(a) == key) await _history.removeServiceLabel(a);
        }
      });

  @override
  Future<InvoiceDrainReport> drainInvoices() => _guard(() async {
    _watchEvents();
    final report = await _wallet.drainInvoices();
    await _sweep();
    return lepicInvoiceReport(report);
  });

  /// Expires invoices on both sides: waiting ones to pay are deleted, issued ones cancelled,
  /// each with its event. A failure is logged only; the next drain sweeps again.
  Future<void> _sweep() async {
    try {
      final sweep = await _wallet.sweepInvoices(expirySecs: _expirySecs);
      if (sweep.cancellable.isNotEmpty) {
        logInfo(
          'invoices',
          '${sweep.cancellable.length} invoice payments past their time to live',
        );
      }
    } on lepic.WalletError catch (error) {
      logWarn('invoices', 'invoice sweep failed: ${error.kind.name}');
    }
  }

  @override
  Future<List<PendingInvoice>> pendingInvoices() => _guard(() async {
    _watchEvents();
    return [
      for (final i in await _wallet.pendingInvoices(expirySecs: _expirySecs))
        lepicPendingInvoice(i),
    ];
  });

  /// The local id of the payment of the invoice [slateId], from LEPIC's store.
  Future<int?> _paymentTxId(String slateId) async =>
      (await _wallet.transactions())
          .where(
            (t) =>
                t.slateId == slateId &&
                t.direction == lepic.TxDirection.outgoing,
          )
          .firstOrNull
          ?.txId;

  @override
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  }) => _guard(() async {
    _watchEvents();
    final pending = (await _wallet.pendingInvoices(expirySecs: _expirySecs))
        .where((i) => i.slateId == slateId)
        .firstOrNull;
    if (pending == null) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'no pending invoice with that id',
      );
    }
    PaidInvoice paid({required InvoiceStatus status, int? txId}) => PaidInvoice(
      slateId: slateId,
      senderAddress: pending.senderAddress,
      amount: pending.amount,
      message: pending.message,
      status: status,
      txId: txId,
    );
    PaidInvoice result;
    try {
      final tx = await _wallet.payInvoice(
        slateId: slateId,
        amount: amount,
        minimumConfirmations: await _balanceConfirmations(),
      );
      result = paid(status: InvoiceStatus.replied, txId: tx.txId);
    } on lepic.WalletError catch (error) {
      if (error.kind != lepic.WalletErrorKind.notDelivered) rethrow;
      // Paid and stored with its inputs locked; the reply goes again with Retry.
      result = paid(
        status: InvoiceStatus.replyFailed,
        txId: await _paymentTxId(slateId),
      );
    }
    try {
      await _history.putPaidInvoice(slateId, result.status);
    } on WalletError catch (error) {
      // The payment stands either way; only its details screen loses the invoice.
      logWarn(
        'invoices',
        'could not record a paid invoice: ${error.kind.name}',
      );
    }
    return result;
  });

  @override
  Future<PaidInvoice> resendInvoiceReply({required String slateId}) =>
      _guard(() async {
        final paid = await _paidInvoice(slateId);
        if (paid == null) {
          throw const WalletError(
            kind: WalletErrorKind.invalidArgument,
            message: 'no paid invoice with that id',
          );
        }
        if (paid.status != InvoiceStatus.replyFailed) return paid;
        final txId = paid.txId ?? await _paymentTxId(slateId);
        if (txId == null) {
          throw const WalletError(
            kind: WalletErrorKind.invalidArgument,
            message: 'the payment of this invoice is not stored',
          );
        }
        await _wallet.resendInvoicePayment(txId: txId);
        await _history.setPaidInvoiceStatus(slateId, InvoiceStatus.replied);
        return paid.withStatus(InvoiceStatus.replied);
      });

  @override
  Future<void> declineInvoice({required String slateId}) => _guard(() async {
    _watchEvents();
    await _wallet.declineInvoice(slateId: slateId);
    if (!_invoiceEvents.isClosed) {
      _invoiceEvents.add(
        InvoiceEvent(kind: InvoiceEventKind.declined, slateId: slateId),
      );
    }
  });

  @override
  Future<PaidInvoice?> paidInvoice({required String slateId}) =>
      _guard(() => _paidInvoice(slateId));

  /// The invoice paid under [slateId], from LEPIC's payment (`flow` invoice, outgoing) and
  /// what the archive recorded of its reply and receipt; null when LEPIC has no such payment.
  Future<PaidInvoice?> _paidInvoice(String slateId) async {
    final record = _history.paidInvoiceRecord(slateId);
    for (final d in await _wallet.transactions()) {
      if (d.slateId != slateId) continue;
      final paid = paidInvoiceOf(
        lepicTxEntry(d),
        status: record?.status,
        kernelExcess: record?.kernelExcess,
      );
      if (paid != null) return paid;
    }
    return null;
  }

  @override
  Stream<InvoiceEvent> invoiceEvents() {
    _watchEvents();
    return _invoiceEvents.stream;
  }

  // Issuing invoices (I-05, I-07). LEPIC keeps an issued invoice as an incoming transaction
  // with `flow` invoice, so the requests come from its store; `wfe_meta.json`
  // (`issued_invoices`) keeps only the state the app learned, which LEPIC reports as
  // cancelled, and moves it once, from waiting, on LEPIC's events. Nothing here pays.

  /// The requests in LEPIC's store, newest first, with the states the archive recorded.
  Future<List<IssuedInvoice>> _requests() async => requestsOf([
    for (final d in await _wallet.transactions()) lepicTxEntry(d),
  ], _history.issuedInvoiceState);

  Future<IssuedInvoice?> _request(String slateId) async =>
      (await _requests()).where((i) => i.slateId == slateId).firstOrNull;

  /// Moves [slateId] to [state] and tells the app, once.
  Future<void> _settleIssued(
    String slateId,
    IssuedInvoiceState state, {
    String? payerAddress,
  }) async {
    final kind = issuerEventFor(state);
    if (kind == null) return;
    bool moved;
    try {
      moved = await _history.settleIssuedInvoice(slateId, state);
    } on WalletError catch (error) {
      logWarn(
        'invoices',
        'could not record an issued invoice: ${error.kind.name}',
      );
      return;
    }
    if (moved && !_issuerEvents.isClosed) {
      _issuerEvents.add(
        IssuerEvent(kind: kind, slateId: slateId, payerAddress: payerAddress),
      );
    }
  }

  /// An issuer event from LEPIC, for a request still waiting. A decline is final and a
  /// bounce means the payer cannot pay it, so the app withdraws the request itself, which
  /// frees the output LEPIC set aside for it. A repeated event finds it no longer waiting and
  /// changes nothing, so a bounce LEPIC delivers twice withdraws and tells once. A request
  /// without a record (its write failed) is moved and told too: a live event is news, unlike
  /// the catch-up in [_reconcileIssued], which stays silent for such a request.
  Future<void> _onIssuerEvent(String slateId, IssuedInvoiceState state) async {
    final recorded = _history.issuedInvoiceState(slateId);
    if (recorded != null && recorded != IssuedInvoiceState.waiting) return;
    final issued = await _request(slateId);
    if (issued == null) return;
    // LEPIC moved its transaction already for a payment or an expiry. A decline or a bounce
    // counts only for a request it still holds; anything else is settled by what LEPIC says.
    if (state == IssuedInvoiceState.declined ||
        state == IssuedInvoiceState.bounced) {
      if (!issued.withdrawable) return;
      try {
        await _wallet.cancelTransaction(txId: issued.txId);
      } on lepic.WalletError catch (error) {
        // The sweep cancels it when its time runs out.
        logWarn(
          'invoices',
          '${state.name} invoice not withdrawn: ${error.kind.name}',
        );
      }
    }
    await _settleIssued(slateId, state, payerAddress: issued.payerAddress);
  }

  /// A bounce the listener reported. LEPIC raises it on [lepic.EpicWallet.events] too; the
  /// second one changes nothing.
  void _onBounce(String slateId) {
    _watchEvents();
    unawaited(
      _inTurn(() => _onIssuerEvent(slateId, IssuedInvoiceState.bounced))
          .catchError(
            (Object error) =>
                logWarn('invoices', 'bounce not handled: ${error.runtimeType}'),
          ),
    );
  }

  @override
  Future<IssuedInvoice> issueInvoice({
    required BigInt amount,
    required String address,
    String? message,
  }) => _guard(() async {
    _watchEvents();
    final to = address.trim();
    if (!_validAddress(to)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not an epicbox address with a relay on this network',
      );
    }
    final key = epicboxKey(to);
    final own = [
      await _wallet.epicboxAddress(),
      await _wallet.invoiceAddress(),
    ];
    if (own.any((o) => epicboxKey(o) == key)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'this is one of your own addresses',
      );
    }
    if (amount <= BigInt.zero) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the amount must be above zero',
      );
    }
    final text = cutMessage(message);
    final before = {for (final t in await _wallet.transactions()) t.txId};
    final lepic.IssuedInvoice sent;
    try {
      sent = await _wallet.issueInvoiceEpicbox(
        amount: amount,
        address: to,
        message: text,
      );
    } on lepic.WalletError catch (error) {
      if (error.kind == lepic.WalletErrorKind.notDelivered) {
        await _dropUndelivered(before, amount, to);
      }
      rethrow;
    }
    final now = DateTime.now();
    final issued = IssuedInvoice(
      slateId: sent.slateId,
      txId: sent.txId,
      payerAddress: to,
      amount: sent.amount,
      message: text,
      issuedAt: now,
      expiresAt: now.add(invoiceExpiry),
      state: IssuedInvoiceState.waiting,
    );
    try {
      await _history.putIssuedInvoice(issued.slateId);
    } on WalletError catch (error) {
      // The request went out; only the app's view of it is lost. The sweep ends it.
      logWarn(
        'invoices',
        'could not record an issued invoice: ${error.kind.name}',
      );
    }
    logInfo('invoices', 'invoice issued');
    return issued;
  });

  /// Cancels the invoice LEPIC stored when the relay did not take it, so a failed request
  /// leaves nothing behind: LEPIC cannot send an issued invoice again. It is the incoming
  /// epicbox transaction for [amount] to the payer at [to] that was not there before the
  /// call. A payment the listener signed meanwhile for the same amount comes from another
  /// address, so it is never taken for it.
  Future<void> _dropUndelivered(
    Set<int> before,
    BigInt amount,
    String to,
  ) async {
    final key = epicboxKey(to);
    try {
      final stored = (await _wallet.transactions()).where(
        (t) =>
            !before.contains(t.txId) &&
            t.direction == lepic.TxDirection.incoming &&
            t.status == lepic.TxStatus.received &&
            t.amountCredited == amount &&
            t.transport == 'epicbox' &&
            t.counterparty != null &&
            epicboxKey(t.counterparty!) == key,
      );
      for (final t in stored) {
        await _wallet.cancelTransaction(txId: t.txId);
      }
    } on lepic.WalletError catch (error) {
      logWarn(
        'invoices',
        'undelivered invoice not cancelled: ${error.kind.name}',
      );
    }
  }

  @override
  Future<List<IssuedInvoice>> issuedInvoices() => _guard(() async {
    _watchEvents();
    return _inTurn(_reconcileIssued);
  });

  /// Settles waiting records from LEPIC's transactions, for events the app missed: the
  /// listener or a drain finalized one while nothing listened, or a sweep cancelled one.
  /// A request without a record (its write failed, or `wfe_meta.json` was lost) shows what
  /// LEPIC says and raises no notice. Returns the requests as settled.
  Future<List<IssuedInvoice>> _reconcileIssued() async {
    final requests = await _requests();
    return [
      for (final i in requests)
        if (i.state != IssuedInvoiceState.waiting &&
            _history.issuedInvoiceState(i.slateId) ==
                IssuedInvoiceState.waiting)
          await _settledAs(i)
        else
          i,
    ];
  }

  Future<IssuedInvoice> _settledAs(IssuedInvoice i) async {
    await _settleIssued(i.slateId, i.state, payerAddress: i.payerAddress);
    return i;
  }

  /// Reconciled as [issuedInvoices] is, so a details screen does not show a request as
  /// waiting after an event the app missed.
  @override
  Future<IssuedInvoice?> issuedInvoice({required String slateId}) =>
      _guard(() async {
        _watchEvents();
        final requests = await _inTurn(_reconcileIssued);
        return requests.where((i) => i.slateId == slateId).firstOrNull;
      });

  @override
  Future<IssuedInvoice> withdrawInvoice({required String slateId}) =>
      _guard(() async {
        _watchEvents();
        return _inTurn(() async {
          final issued = await _request(slateId);
          if (issued == null || !issued.withdrawable) {
            throw const WalletError(
              kind: WalletErrorKind.invalidArgument,
              message: 'only a waiting invoice can be withdrawn',
            );
          }
          // LEPIC sends a LEPIC payer the `withdrawn` notice.
          await _wallet.cancelTransaction(txId: issued.txId);
          await _settleIssued(
            slateId,
            IssuedInvoiceState.withdrawn,
            payerAddress: issued.payerAddress,
          );
          return issued.withState(IssuedInvoiceState.withdrawn);
        });
      });

  @override
  Future<PaymentsDrainReport> drainPayments() => _guard(() async {
    _watchEvents();
    // Each bounce raises `invoiceBounced` on the events, which withdraws that request.
    final report = await _wallet.drainEpicbox();
    await _sweep();
    return PaymentsDrainReport(
      received: report.received,
      finalized: report.finalized,
      bounced: report.bounced,
    );
  });

  @override
  Future<PeerCapability> peerCapability({required String address}) => _guard(
    () async => lepicPeerCapability(
      await _wallet.peerCapability(address: address.trim()),
    ),
  );

  @override
  Stream<IssuerEvent> issuerEvents() {
    _watchEvents();
    return _issuerEvents.stream;
  }
}
