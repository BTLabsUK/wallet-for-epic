/// [WalletService] over the LEPIC library (`package:lepic`, pinned by `tools/lepic.rev`).
///
/// The app's only core. It implements [WalletService], so the UI and its fakes never see
/// LEPIC's own types. Notes, contacts, imported records and history files are the app's own, in
/// `history/` (H-01).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:lepic/lepic.dart' as lepic;

import 'app_log.dart';
import 'history/export.dart';
import 'history/meta_store.dart';
import 'history/wallet_history.dart';
import 'secret_store.dart';
import 'wallet_service.dart';

/// Loads the LEPIC library, which the package's build hook bundles on Android, iOS and x86_64
/// Linux (`tools/lepic.sh build`). Windows has none (UP-3, deferred).
Future<void> initLepic() => lepic.RustLib.init();

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
    lepic.WalletErrorKind.transportFailed => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.chainBusy => WalletErrorKind.chainBusy,
    lepic.WalletErrorKind.walletBusy => WalletErrorKind.walletBusy,
    lepic.WalletErrorKind.paymentExpired => WalletErrorKind.paymentExpired,
    lepic.WalletErrorKind.io => WalletErrorKind.io,
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
  return WalletError(kind: kind, message: error.message);
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

/// LEPIC's listener event as the app's. `repeated` stays apart from `received`: it is a slate
/// answered before, not a new payment.
ListenerEvent lepicListenerEvent(lepic.ListenerEvent e) => ListenerEvent(
  kind: switch (e.kind) {
    lepic.ListenerEventKind.connected => ListenerEventKind.connected,
    lepic.ListenerEventKind.disconnected => ListenerEventKind.disconnected,
    lepic.ListenerEventKind.received => ListenerEventKind.received,
    lepic.ListenerEventKind.repeated => ListenerEventKind.repeated,
    lepic.ListenerEventKind.finalized => ListenerEventKind.finalized,
    lepic.ListenerEventKind.error => ListenerEventKind.error,
    lepic.ListenerEventKind.stopped => ListenerEventKind.stopped,
  },
  txId: e.txId,
  message: e.message,
);

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

/// How long a waiting invoice stays payable: UP-14's default day. LEPIC's `pendingInvoices`
/// and `sweepInvoices` take it in seconds, the same value for both.
const Duration invoiceExpiry = Duration(hours: 24);

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
  return TxEntry(
    key: 'l:${d.txId}',
    id: d.txId,
    slateId: d.slateId,
    kind: switch ((outgoing, ended)) {
      (true, false) => TxKind.sent,
      (true, true) => TxKind.sentCancelled,
      (false, false) => TxKind.received,
      (false, true) => TxKind.receivedCancelled,
    },
    status: status,
    // A scan rebuilds a received output without its slate.
    source: !outgoing && d.slateId == null
        ? TxSource.restored
        : TxSource.wallet,
    createdAtUnix: createdAt,
    timeUnix: confirmedAt ?? createdAt,
    confirmed: status == TxStatus.confirmed,
    blockHeight: d.confirmedHeight,
    blockTimeUnix: confirmedAt,
    amountCredited: d.amountCredited,
    amountDebited: d.amountDebited,
    fee: d.fee,
    numInputs: 0,
    numOutputs: 0,
    kernelExcess: d.kernelExcess,
    outputCommits: const [],
    counterparty: d.counterparty,
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
  );
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
  LepicWalletService({
    required this._secrets,
    lepic.LepicRuntime Function()? runtime,
  }) : _makeRuntime = runtime ?? _defaultRuntime;

  final SecretStore _secrets;
  final lepic.LepicRuntime Function() _makeRuntime;
  lepic.LepicRuntime? _runtimeValue;

  /// Chain of the last wallet config seen, for [validateEpicboxAddress] and [inspectSlate],
  /// which the interface asks without one.
  Chain _chain = Chain.mainnet;

  static lepic.LepicRuntime _defaultRuntime() {
    final runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.info);
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
    return lepic.WalletConfig(
      dataDir: dir.path,
      chain: _lepicChain(config.chain),
      nodeUrl: config.nodeUrl,
      nodeApiSecret: config.nodeApiSecret,
      epicboxDomain: config.epicboxDomain,
      epicboxPort: config.epicboxPort,
    );
  }

  _PrefixedStore _storeKeys(WalletConfig config) =>
      _PrefixedStore(_secrets, 'lepic:${config.chain.name}:${config.dataDir}:');

  lepic.AppSecretStore _store(WalletConfig config) =>
      lepic.lepicSecretStore(_storeKeys(config));

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
  Future<bool> walletExists({required WalletConfig config}) => _guard(
    () => lepic.walletExists(runtime: _runtime, store: _store(config)),
  );

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) => _guard(() async {
    final tip = await lepic.nodeTip(runtime: _runtime, config: _config(config));
    return NodeTip(height: tip.height, nodeVersion: tip.nodeVersion);
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
        store: _store(config),
        mnemonic: mnemonic,
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
        store: _store(config),
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
      store: _store(config),
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
        store: _store(config),
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
    final text = await _storeKeys(config).read('lepic.pin-failures');
    if (text == null) return 0;
    return int.tryParse(text.trim()) ?? 0x7fffffff;
  }

  @override
  Future<void> deleteWallet({required WalletConfig config}) => _guard(() async {
    await lepic.deleteWallet(
      runtime: _runtime,
      config: _config(config),
      store: _store(config),
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
  LepicWalletSession(this._wallet, {WalletHistory? history})
    : _history = history ?? WalletHistory.memory();

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

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) => _guard(() async {
    final slate = await _wallet.createSendSlate(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      message: _message(message),
    );
    return Slate(slateId: slate.slateId, json: slate.json);
  });

  @override
  Future<String> epicboxAddress() => _guard(_wallet.epicboxAddress);

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _guard(() async {
    final e = await _wallet.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
    );
    return FeeEstimate(amount: e.amount, fee: e.fee);
  });

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _guard(() async {
        final e = await _wallet.estimateMax(
          minimumConfirmations: minimumConfirmations,
        );
        return FeeEstimate(amount: e.amount, fee: e.fee);
      });

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
  }) => _guard(() async {
    final tx = await _wallet.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: _message(message),
    );
    return _entry(tx.txId);
  });

  @override
  Stream<ListenerEvent> startListener() =>
      _guardStream(_wallet.startListener().map(lepicListenerEvent));

  @override
  Future<void> stopListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopListener);
  }

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) => _guard(
    () async =>
        lepicReceivedSlate(await _wallet.receiveSlate(slateJson: slateJson)),
  );

  @override
  Stream<ScanProgress> scan({BigInt? startHeight}) => _guardStream(
    _wallet
        .scan(startHeight: startHeight)
        .map(
          (p) => ScanProgress(
            percent: p.percent,
            message: p.message,
            finished: p.finished,
          ),
        ),
  );

  /// LEPIC counts balances with its own 10 confirmations, the app's value too
  /// (`providers.dart`), so [minimumConfirmations] changes nothing.
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

  /// LEPIC's balance rule, the app's `minimumConfirmations` too (`providers.dart`).
  static final BigInt _minimumConfirmations = BigInt.from(10);

  BigInt get _expirySecs => BigInt.from(invoiceExpiry.inSeconds);

  StreamSubscription<lepic.WalletEvent>? _walletEvents;
  final StreamController<InvoiceEvent> _invoiceEvents =
      StreamController<InvoiceEvent>.broadcast();

  /// Events are handled one at a time, so the archive changes in the order LEPIC reported.
  Future<void> _eventTail = Future.value();

  /// Subscribes to LEPIC's events on the first invoice call, so a notice found by a drain
  /// updates the archive before the app's event goes out.
  void _watchEvents() {
    if (_walletEvents != null || _wallet.isDisposed) return;
    _walletEvents = _wallet.events().listen(
      (e) => _eventTail = _eventTail
          .then((_) => _onWalletEvent(e))
          // One failed event must not stop the ones after it.
          .catchError(
            (Object error) => logWarn(
              'invoices',
              'invoice event failed: ${error.runtimeType}',
            ),
          ),
      onError: (Object error) =>
          logWarn('invoices', 'wallet events ended: $error'),
    );
  }

  Future<void> _onWalletEvent(lepic.WalletEvent e) async {
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
    try {
      final sweep = await _wallet.sweepInvoices(expirySecs: _expirySecs);
      if (sweep.cancellable.isNotEmpty) {
        logInfo(
          'invoices',
          '${sweep.cancellable.length} invoice payments past their time to live',
        );
      }
    } on lepic.WalletError catch (error) {
      // The drain itself worked; expired invoices are swept on the next one.
      logWarn('invoices', 'invoice sweep failed: ${error.kind.name}');
    }
    return lepicInvoiceReport(report);
  });

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
        minimumConfirmations: _minimumConfirmations,
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
      await _history.putPaidInvoice(result);
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
        final paid = _history.paidInvoice(slateId);
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
        return _history.paidInvoice(slateId) ??
            paid.withStatus(InvoiceStatus.replied);
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
  Future<PaidInvoice?> paidInvoice({required String slateId}) async =>
      _history.paidInvoice(slateId);

  @override
  Stream<InvoiceEvent> invoiceEvents() {
    _watchEvents();
    return _invoiceEvents.stream;
  }
}
