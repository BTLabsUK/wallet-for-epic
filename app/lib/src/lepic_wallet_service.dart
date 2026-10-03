/// [WalletService] over the LEPIC library (`package:lepic`, pinned by `tools/lepic.rev`).
///
/// Selected with `--dart-define=WFE_CORE=lepic` (`core_backend.dart`). It speaks the same
/// interface as [RustWalletService], so the UI does not know which core runs. LEPIC lacks some
/// calls the UI uses; [lepicMissing] lists them, and each throws [lepicUnsupported] until the
/// matching request to LEPIC lands and the pin moves. Two calls answer
/// partly: `transactions` lists only this session's sends (UP-1) and `contacts` is empty (H-01).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:lepic/lepic.dart' as lepic;

import 'app_log.dart';
import 'secret_store.dart';
import 'wallet_service.dart';

/// Calls of [WalletService] and [WalletSession] that LEPIC cannot serve yet, with the request
/// that unblocks each. `test/lepic_mapping_test.dart` keeps this list and the code in step.
const Map<String, String> lepicMissing = {
  'generateMnemonic': 'none: LEPIC generates the seed inside create',
  'inspectSlate': 'UP-4',
  'releaseStuckSend': 'UP-9',
  'estimateFee': 'UP-2',
  'estimateMax': 'UP-2',
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

/// Loads the LEPIC library. Android and iOS bundle it through the package's build hook; on a
/// desktop `LEPIC_FFI_LIB` names it (`tools/lepic.sh lib` prints the path), since LEPIC bundles
/// no desktop library yet (UP-3).
Future<void> initLepic() async {
  final path = Platform.environment['LEPIC_FFI_LIB'];
  await lepic.RustLib.init(
    externalLibrary: path == null ? null : ExternalLibrary.open(path),
  );
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
    lepic.WalletErrorKind.transportFailed => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.chainBusy => WalletErrorKind.chainBusy,
    lepic.WalletErrorKind.walletBusy => WalletErrorKind.walletBusy,
    lepic.WalletErrorKind.paymentExpired => WalletErrorKind.paymentExpired,
    lepic.WalletErrorKind.io => WalletErrorKind.io,
    lepic.WalletErrorKind.secretStore => WalletErrorKind.io,
    lepic.WalletErrorKind.foreignWallet => WalletErrorKind.invalidArgument,
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

/// How long a LEPIC stream that ended without its last event waits for the call's error.
const Duration _lateErrorWait = Duration(seconds: 2);

/// A LEPIC stream that ends with the call's error. The generated bindings at the pin do not
/// await the call behind a stream (`unawaited(handler.executeNormal(...))` in
/// `frb_generated.dart`), so a failure closes the stream with no error and the error escapes to
/// the zone (UP-11). This catches it in a zone of its own. A stream that ends without an event
/// [isLast] accepts gets that error, or a generic one if none arrives within [_lateErrorWait].
Stream<T> _lepicStream<T>(Stream<T> Function() open, bool Function(T) isLast) {
  late final StreamController<T> controller;
  void fail(Object error, [StackTrace? stack]) {
    if (controller.isClosed) return;
    controller.addError(
      error is lepic.WalletError ? mapLepicError(error) : error,
      stack,
    );
    controller.close();
  }

  StreamSubscription<T>? subscription;
  controller = StreamController<T>(
    onListen: () => runZonedGuarded(() {
      var finished = false;
      subscription = open().listen(
        (event) {
          finished = isLast(event);
          controller.add(event);
        },
        onError: fail,
        onDone: () {
          if (finished) {
            controller.close();
            return;
          }
          Timer(
            _lateErrorWait,
            () => fail(
              const WalletError(
                kind: WalletErrorKind.other,
                message: 'LEPIC ended the call without a result',
              ),
            ),
          );
        },
      );
    }, fail),
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}

lepic.Chain _lepicChain(Chain chain) => switch (chain) {
  Chain.mainnet => lepic.Chain.mainnet,
  Chain.floonet => lepic.Chain.floonet,
  Chain.usernet => throw const WalletError(
    kind: WalletErrorKind.invalidArgument,
    message: 'LEPIC has no usernet (UP-8)',
  ),
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

  /// The app's rule is `<key>@<relay>[:port]`, as the old core checks: the relay is part of the
  /// address. LEPIC also accepts a bare key, so the relay part is required here.
  @override
  bool validateEpicboxAddress({required String address}) =>
      _chain != Chain.usernet &&
      address.contains('@') &&
      lepic.validateEpicboxAddress(
        address: address,
        chain: _lepicChain(_chain),
      );

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

  /// Sends made through this session. LEPIC has no transaction list yet (UP-1), so these are
  /// the only rows [transactions] can show.
  final List<TxEntry> _sent = [];

  @override
  void dispose() {
    if (_wallet.isDisposed) return;
    _wallet.lock();
    _wallet.dispose();
  }

  TxEntry _sendEntry({
    required int txId,
    required String slateId,
    required TxStatus status,
    BigInt? amount,
    BigInt? fee,
    String? counterparty,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final entry = TxEntry(
      key: 'l:$txId',
      id: txId,
      slateId: slateId,
      kind: TxKind.sent,
      status: status,
      source: TxSource.wallet,
      createdAtUnix: now,
      timeUnix: now,
      confirmed: false,
      amountCredited: BigInt.zero,
      amountDebited: (amount ?? BigInt.zero) + (fee ?? BigInt.zero),
      fee: fee,
      numInputs: 0,
      numOutputs: 0,
      outputCommits: const [],
      counterparty: counterparty,
      cancellable: status == TxStatus.awaitingRecipient,
      repostable: false,
      releasable: false,
    );
    _sent
      ..removeWhere((t) => t.key == entry.key)
      ..insert(0, entry);
    return entry;
  }

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
  }) async => throw lepicUnsupported('estimateFee');

  @override
  Future<FeeEstimate> estimateMax({
    required BigInt minimumConfirmations,
  }) async => throw lepicUnsupported('estimateMax');

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) =>
      _guard(() async {
        final tx = await _wallet.finalizeAndPost(slateJson: slateJson);
        return _sendEntry(
          txId: tx.txId,
          slateId: tx.slateId,
          status: TxStatus.awaitingConfirmation,
        );
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
    return _sendEntry(
      txId: tx.txId,
      slateId: tx.slateId,
      status: TxStatus.awaitingRecipient,
      amount: tx.amount,
      fee: tx.fee,
      counterparty: address,
    );
  });

  @override
  Stream<ListenerEvent> startListener() => _lepicStream(
    () => _wallet.startListener().map(_listenerEvent),
    (e) => e.kind == ListenerEventKind.stopped,
  );

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
  Stream<ScanProgress> scan({BigInt? startHeight}) => _lepicStream(
    () => _wallet
        .scan(startHeight: startHeight)
        .map(
          (p) => ScanProgress(
            percent: p.percent,
            message: p.message,
            finished: p.finished,
          ),
        ),
    (p) => p.finished,
  );

  /// LEPIC counts balances with its own 10 confirmations, the app's value too
  /// (`providers.dart`), so [minimumConfirmations] changes nothing.
  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _guard(() async => _summary(await _wallet.summary(refresh: refresh)));

  @override
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations}) =>
      _lepicStream(
        () => _wallet.refresh().map(
          (p) => RefreshProgress(
            percent: p.percent,
            message: p.message,
            summary: p.summary == null ? null : _summary(p.summary!),
          ),
        ),
        (p) => p.summary != null,
      );

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) async => [
    ..._sent,
  ];

  /// Nothing to enrich: the rows are this session's sends only.
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
