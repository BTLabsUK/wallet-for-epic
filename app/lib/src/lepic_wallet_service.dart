/// [WalletService] over the LEPIC library (`package:lepic`, pinned by `tools/lepic.rev`).
///
/// Selected with `--dart-define=WFE_CORE=lepic` (`core_backend.dart`). It speaks the same
/// interface as [RustWalletService], so the UI does not know which core runs. LEPIC lacks some
/// calls the UI uses; [lepicMissing] lists them, and each throws [lepicUnsupported] until the
/// matching request to LEPIC lands and the pin moves. `contacts` answers
/// with an empty book until notes and contacts move to Dart (H-01).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:lepic/lepic.dart' as lepic;

import 'app_log.dart';
import 'secret_store.dart';
import 'wallet_service.dart';

/// Calls of [WalletService] and [WalletSession] that LEPIC cannot serve yet, with the request
/// that unblocks each. `test/lepic_mapping_test.dart` keeps this list and the code in step.
const Map<String, String> lepicMissing = {
  'generateMnemonic': 'none: LEPIC generates the seed inside create',
  'inspectSlate':
      'A-03: LEPIC answers asynchronously, the app interface is synchronous',
  'releaseStuckSend': 'UP-9, LEPIC W-16',
  'sendHttp': 'OD-2, LEPIC speaks Epicbox and files only',
  'setTxNote': 'H-01',
  'saveContact': 'H-01',
  'deleteContact': 'H-01',
  'exportHistory': 'H-02, UP-5',
  'exportHistoryCsv': 'H-01',
  'importHistory': 'H-02, UP-5',
};

/// The error a call in [lepicMissing] throws.
WalletError lepicUnsupported(String call) => WalletError(
  kind: WalletErrorKind.other,
  message: '$call is not available on the LEPIC core yet',
);

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
    lepic.WalletErrorKind.foreignAppData ||
    lepic.WalletErrorKind.damagedAppData => WalletErrorKind.invalidArgument,
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

ListenerEvent _listenerEvent(lepic.ListenerEvent e) => ListenerEvent(
  kind: switch (e.kind) {
    lepic.ListenerEventKind.connected => ListenerEventKind.connected,
    lepic.ListenerEventKind.disconnected => ListenerEventKind.disconnected,
    lepic.ListenerEventKind.received => ListenerEventKind.received,
    lepic.ListenerEventKind.finalized => ListenerEventKind.finalized,
    lepic.ListenerEventKind.error => ListenerEventKind.error,
    lepic.ListenerEventKind.stopped => ListenerEventKind.stopped,
  },
  message: e.message,
);

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
/// and imported rows are the app's (H-01), so `note` stays empty here.
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
    ttlCutoffHeight: d.ttlCutoffHeight,
    cancellable:
        d.status == lepic.TxStatus.sent || d.status == lepic.TxStatus.received,
    // Finalized but refused by the node: LEPIC stores it for a repost.
    repostable: d.status == lepic.TxStatus.finalized,
    releasable: false,
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

  /// Chain of the last wallet config seen, for [validateEpicboxAddress], which the interface
  /// asks without one.
  Chain _chain = Chain.mainnet;

  static lepic.LepicRuntime _defaultRuntime() {
    final runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.info);
    runtime.logs().listen((entry) {
      final line = '${entry.target}: ${entry.message}';
      switch (entry.level) {
        case lepic.LogLevel.error || lepic.LogLevel.warn:
          logWarn('lepic', line);
        case _:
          logInfo('lepic', line);
      }
    });
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

  lepic.AppSecretStore _store(WalletConfig config) => lepic.lepicSecretStore(
    _PrefixedStore(_secrets, 'lepic:${config.chain.name}:${config.dataDir}:'),
  );

  @override
  String generateMnemonic({required int wordCount}) =>
      throw lepicUnsupported('generateMnemonic');

  @override
  bool validateMnemonic({required String phrase}) =>
      lepic.validateMnemonic(phrase: phrase);

  @override
  SlateInfo inspectSlate({required String json}) =>
      throw lepicUnsupported('inspectSlate');

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
    () async => LepicWalletSession(
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
    () async => LepicWalletSession(
      await lepic.EpicWallet.open(
        runtime: _runtime,
        config: _config(config),
        store: _store(config),
        password: password,
      ),
    ),
  );

  @override
  Future<void> deleteWallet({required WalletConfig config}) => _guard(
    () => lepic.deleteWallet(
      runtime: _runtime,
      config: _config(config),
      store: _store(config),
    ),
  );
}

/// An open LEPIC wallet. Public so tests can wrap a stand-in `EpicWallet`.
class LepicWalletSession implements WalletSession {
  LepicWalletSession(this._wallet);

  final lepic.EpicWallet _wallet;

  @override
  void dispose() {
    if (_wallet.isDisposed) return;
    _wallet.lock();
    _wallet.dispose();
  }

  /// The stored row of [txId], as the history shows it.
  Future<TxEntry> _entry(int txId) async =>
      lepicTxEntry(await _wallet.transaction(txId: txId));

  @override
  Future<String> mnemonic({required String password}) =>
      _guard(() => _wallet.mnemonic(password: password));

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _guard(() => _wallet.cancelTransaction(txId: txId));

  @override
  Future<void> repostTransaction({required String key}) =>
      _guard(() => _wallet.repostTransaction(txId: lepicTxId(key)));

  @override
  Future<void> releaseStuckSend({required String key}) async =>
      throw lepicUnsupported('releaseStuckSend');

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _guard(() async {
    final slate = await _wallet.createSendSlate(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
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
  Future<TxEntry> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
  }) async => throw lepicUnsupported('sendHttp');

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
  }) => _guard(() async {
    final tx = await _wallet.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
    );
    return _entry(tx.txId);
  });

  @override
  Stream<ListenerEvent> startListener() =>
      _guardStream(_wallet.startListener().map(_listenerEvent));

  @override
  Future<void> stopListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopListener);
  }

  @override
  Future<Slate> receiveSlate({required String slateJson}) => _guard(() async {
    final slate = await _wallet.receiveSlate(slateJson: slateJson);
    return Slate(slateId: slate.slateId, json: slate.json);
  });

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
        final rows = (await _wallet.transactions()).map(lepicTxEntry).toList()
          ..sort((a, b) => b.timeUnix.compareTo(a.timeUnix));
        return rows;
      });

  /// LEPIC stores heights and times as it confirms, so nothing is left to fill in.
  @override
  Future<int> enrichHistory() async => 0;

  @override
  Future<void> setTxNote({required String key, String? note}) async =>
      throw lepicUnsupported('setTxNote');

  /// No address book on this core yet (H-01); an empty one keeps the screens usable.
  @override
  Future<List<Contact>> contacts() async => const [];

  @override
  Future<Contact> saveContact({required Contact contact}) async =>
      throw lepicUnsupported('saveContact');

  @override
  Future<void> deleteContact({required String id}) async =>
      throw lepicUnsupported('deleteContact');

  @override
  Future<Uint8List> exportHistory() async =>
      throw lepicUnsupported('exportHistory');

  @override
  Future<String> exportHistoryCsv() async =>
      throw lepicUnsupported('exportHistoryCsv');

  @override
  Future<ImportReport> importHistory({required Uint8List data}) async =>
      throw lepicUnsupported('importHistory');
}
