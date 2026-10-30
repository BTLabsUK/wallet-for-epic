// SPDX-License-Identifier: Apache-2.0
/// A [WalletService] whose PIN and password calls wait for a [WorkGate] slot.
///
/// LEPIC runs Argon2id at 64 MiB for each of them, so the server caps how many run at once
/// across all demos. Everything else passes straight through, except the calls that open a
/// wallet, which also follow the demo's lifetime (`beforeOpen`, `ended`, `afterLateOpen`).
library;

import 'dart:typed_data';

import '../wallet_service.dart';
import 'limits.dart';

/// What an open gets once its demo has ended.
const WalletError demoEndedError = WalletError(
  kind: WalletErrorKind.other,
  message: 'this demo has ended',
);

class GatedWalletService implements WalletService {
  GatedWalletService(
    this._inner,
    this._gate, {
    this.beforeOpen,
    this.ended,
    this.afterLateOpen,
    this.afterCreate,
  });

  final WalletService _inner;
  final WorkGate _gate;

  /// Runs before `create`, `open`, `createWithPin` and `openWithPin`, once their turn at the
  /// gate comes. The demo server closes the demo's open sessions there: LEPIC refuses a second
  /// open of one directory (`walletBusy`), and a reloaded page that lost its handle must be
  /// able to unlock again.
  final void Function()? beforeOpen;

  /// True once the demo has ended. An open then never starts, and one that was queued or
  /// running when it ended has its session disposed and fails with [demoEndedError], so no
  /// wallet stays open past its demo.
  final bool Function()? ended;

  /// Runs after an open that finished, or failed, after the demo ended: the open may have
  /// re-created files the end already removed.
  final Future<void> Function()? afterLateOpen;

  /// Runs on a newly created wallet's session before the visitor gets it: the demo sets its
  /// wallet's minimum confirmations to 1 there.
  final Future<void> Function(WalletSession session)? afterCreate;

  bool get _ended => ended?.call() ?? false;

  Future<WalletSession> _created(WalletSession s) async {
    await afterCreate?.call(s);
    return s;
  }

  Future<T> _opening<T>(
    Future<T> Function() open,
    WalletSession Function(T) sessionOf,
  ) => _gate.run(() async {
    if (_ended) throw demoEndedError;
    beforeOpen?.call();
    final T result;
    try {
      result = await open();
    } catch (_) {
      if (_ended) {
        await afterLateOpen?.call();
        throw demoEndedError;
      }
      rethrow;
    }
    if (_ended) {
      sessionOf(result).dispose();
      await afterLateOpen?.call();
      throw demoEndedError;
    }
    return result;
  });

  static WalletSession _itself(WalletSession s) => s;

  WalletSession _wrap(WalletSession s) => GatedWalletSession(s, _gate);

  @override
  bool validateMnemonic({required String phrase}) =>
      _inner.validateMnemonic(phrase: phrase);

  @override
  String walletFingerprint({required String mnemonic, required Chain chain}) =>
      _inner.walletFingerprint(mnemonic: mnemonic, chain: chain);

  @override
  Future<SlateInfo> inspectSlate({required String json}) =>
      _inner.inspectSlate(json: json);

  @override
  Future<List<String>> encodeQrSlate({
    required String json,
    required int maxFragmentLen,
  }) => _inner.encodeQrSlate(json: json, maxFragmentLen: maxFragmentLen);

  @override
  Future<QrSlateProgress> decodeQrSlate({required List<String> parts}) =>
      _inner.decodeQrSlate(parts: parts);

  @override
  bool validateEpicboxAddress({required String address}) =>
      _inner.validateEpicboxAddress(address: address);

  @override
  bool epicboxAddressOtherChain({required String address}) =>
      _inner.epicboxAddressOtherChain(address: address);

  @override
  bool validateOnionAddress({required String address}) =>
      _inner.validateOnionAddress(address: address);

  @override
  Future<bool> walletExists({required WalletConfig config}) =>
      _inner.walletExists(config: config);

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) =>
      _inner.nodeTip(config: config);

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  }) async => _wrap(
    await _created(
      await _opening(
        () => _inner.create(config: config, mnemonic: mnemonic, password: password),
        _itself,
      ),
    ),
  );

  @override
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  }) async => _wrap(
    await _opening(
      () => _inner.importWalletSeed(
        config: config,
        seedFile: seedFile,
        seedPassword: seedPassword,
        password: password,
      ),
      _itself,
    ),
  );

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) async => _wrap(
    await _opening(
      () => _inner.open(config: config, password: password),
      _itself,
    ),
  );

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    final w = await _opening(
      () => _inner.createWithPin(config: config, mnemonic: mnemonic, pin: pin),
      (w) => w.session,
    );
    await _created(w.session);
    return (session: _wrap(w.session), sealedPassword: w.sealedPassword);
  }

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) async => _wrap(
    await _opening(
      () => _inner.openWithPin(
        config: config,
        pin: pin,
        sealedPassword: sealedPassword,
      ),
      _itself,
    ),
  );

  @override
  Future<int> pinFailures({required WalletConfig config}) =>
      _inner.pinFailures(config: config);

  @override
  Future<void> deleteWallet({required WalletConfig config}) =>
      _inner.deleteWallet(config: config);

  @override
  Future<void> resetPassword({
    required WalletConfig config,
    required String mnemonic,
    required String newPassword,
  }) => _inner.resetPassword(
    config: config,
    mnemonic: mnemonic,
    newPassword: newPassword,
  );
}

/// A session whose PIN calls wait for a [WorkGate] slot.
class GatedWalletSession implements WalletSession {
  GatedWalletSession(this._inner, this._gate);

  final WalletSession _inner;
  final WorkGate _gate;

  @override
  void dispose() => _inner.dispose();

  @override
  Future<String> mnemonic({required String password}) =>
      _gate.run(() => _inner.mnemonic(password: password));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _gate.run(
    () => _inner.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) => _gate.run(
    () => _inner.mnemonicWithPin(pin: pin, sealedPassword: sealedPassword),
  );

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) => _gate.run(
    () => _inner.changePin(
      sealedPassword: sealedPassword,
      oldPin: oldPin,
      newPin: newPin,
    ),
  );

  @override
  Future<void> confirmPinChange({required String sealedPassword}) =>
      _inner.confirmPinChange(sealedPassword: sealedPassword);

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _inner.cancelTransaction(txId: txId);

  @override
  Future<void> repostTransaction({required String key}) =>
      _inner.repostTransaction(key: key);

  @override
  Future<void> resendEpicbox({required String key}) =>
      _inner.resendEpicbox(key: key);

  @override
  Future<String> finishedPaymentText({required int txId}) => _inner.finishedPaymentText(txId: txId);

  @override
  Future<FinishedPayment> inspectFinished(String text) => _inner.inspectFinished(text);

  @override
  Future<void> postFinished(String text) => _inner.postFinished(text);

  @override
  Future<void> releaseStuckSend({required String key}) =>
      _inner.releaseStuckSend(key: key);

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _inner.createSendSlate(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    message: message,
    options: options,
  );

  @override
  Future<String> epicboxAddress() => _inner.epicboxAddress();

  @override
  Future<String> fingerprint() => _inner.fingerprint();

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) => _inner.estimateFee(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    options: options,
  );

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) =>
      _inner.finalizeAndPost(slateJson: slateJson);

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) => _inner.sendEpicbox(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    address: address,
    message: message,
    options: options,
  );

  @override
  Stream<ListenerEvent> startListener() => _inner.startListener();

  @override
  Future<void> stopListener() => _inner.stopListener();

  // HTTP sends and the HTTP listener reach other computers or open a port on the demo server:
  // not offered here.
  static const WalletError _noHttp = WalletError(
    kind: WalletErrorKind.other,
    message: 'direct HTTP is not offered remotely',
  );

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
    String? proofAddress,
  }) async => throw _noHttp;

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) async => throw _noHttp;

  @override
  Stream<HttpListenerEvent> startHttpListener({
    required HttpExposure exposure,
    required int port,
  }) => Stream.error(_noHttp);

  @override
  Future<void> stopHttpListener() async {}

  @override
  Future<HttpListenerInfo?> httpListenerStatus() async => null;

  // Tor runs a process and reaches other computers from the server: not offered here.
  static const WalletError _noTor = WalletError(
    kind: WalletErrorKind.other,
    message: 'Tor is not offered remotely',
  );

  static const WalletError _noDeviceLink = WalletError(
    kind: WalletErrorKind.other,
    message: 'Linked devices are not offered remotely',
  );

  @override
  Future<String> signWithAddressKey(List<int> message) async => throw _noDeviceLink;

  @override
  Future<bool> verifyAddressSignature({required String key, required List<int> message, required String signature}) async => false;

  @override
  Future<String> onionAddress() async => throw _noTor;

  @override
  Stream<TorEvent> startTor({required String torBinary, String? libDir}) =>
      Stream.error(_noTor);

  @override
  Future<void> stopTor() async {}

  @override
  Future<void> setEpicboxOverTor(bool on) async {}

  @override
  Future<void> expectTor() async {}

  @override
  Future<bool> epicboxOverTor() async => false;

  @override
  Future<void> setOnionRoutes(List<TorOnionRoute> routes) async {}

  @override
  Future<TorStatus> torStatus() async => TorStatus.off;

  @override
  Future<void> refreshTor({required bool networkChanged}) async {}

  @override
  Future<void> torNetworkLost() async {}

  @override
  Future<HttpSent> sendTor({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String onion,
    String? message,
    SendOptions? options,
  }) async => throw _noTor;

  @override
  Future<HttpSent> resendTor({
    required int txId,
    required String onion,
  }) async => throw _noTor;

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) =>
      _inner.receiveSlate(slateJson: slateJson);

  @override
  Stream<ScanProgress> scan({
    BigInt? startHeight,
    bool deleteUnconfirmed = false,
  }) => _inner.scan(
    startHeight: startHeight,
    deleteUnconfirmed: deleteUnconfirmed,
  );

  @override
  void cancelScan() => _inner.cancelScan();

  @override
  Future<bool> restoreScanRequired() => _inner.restoreScanRequired();

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _inner.summary(
    refresh: refresh,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<int> minimumConfirmations() => _inner.minimumConfirmations();

  @override
  Future<void> setMinimumConfirmations(int count) => _inner.setMinimumConfirmations(count);

  @override
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations}) =>
      _inner.refresh(minimumConfirmations: minimumConfirmations);

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) =>
      _inner.transactions(refresh: refresh);

  @override
  Future<int> enrichHistory() => _inner.enrichHistory();

  @override
  Future<void> setTxNote({required String key, String? note}) =>
      _inner.setTxNote(key: key, note: note);

  @override
  Future<void> setTxLabel({required String key, String? label}) =>
      _inner.setTxLabel(key: key, label: label);

  @override
  Future<void> setTxDetails({
    required String key,
    String? counterparty,
    String? transport,
    String? note,
  }) => _inner.setTxDetails(
    key: key,
    counterparty: counterparty,
    transport: transport,
    note: note,
  );

  @override
  Future<List<Contact>> contacts() => _inner.contacts();

  @override
  Future<Contact> saveContact({required Contact contact}) =>
      _inner.saveContact(contact: contact);

  @override
  Future<void> deleteContact({required String id}) =>
      _inner.deleteContact(id: id);

  @override
  Future<List<String>> favouriteContacts() => _inner.favouriteContacts();

  @override
  Future<void> setFavouriteContact({required String id, required bool favourite}) =>
      _inner.setFavouriteContact(id: id, favourite: favourite);

  @override
  Future<Uint8List> exportHistory({String? walletName, Map<String, Object?>? settings}) =>
      _inner.exportHistory(walletName: walletName, settings: settings);

  @override
  Future<String> exportHistoryCsv() => _inner.exportHistoryCsv();

  @override
  Future<ImportReport> importHistory({
    required Uint8List data,
    Map<String, bool>? useBackup,
  }) => _inner.importHistory(data: data, useBackup: useBackup);

  // The server's disk is not the visitor's to read.
  @override
  Future<LegacyHistoryImport> importLegacyHistory({
    required String sourceDir,
    Map<String, bool>? useOldWallet,
  }) async =>
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'Importing an old wallet is not offered remotely',
      );

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _inner.estimateMax(minimumConfirmations: minimumConfirmations);

  @override
  Set<String> get heldOutputs => _inner.heldOutputs;

  @override
  set heldOutputs(Set<String> commitments) => _inner.heldOutputs = commitments;

  @override
  Future<List<WalletOutput>> outputs() => _inner.outputs();

  @override
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _inner.estimateSplit(
    outputs: outputs,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _inner.splitOutputs(
    outputs: outputs,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<FeeEstimate> estimateConsolidate({
    required BigInt minimumConfirmations,
  }) => _inner.estimateConsolidate(minimumConfirmations: minimumConfirmations);

  @override
  Future<SelfSentTx> consolidateOutputs({
    required BigInt minimumConfirmations,
  }) => _inner.consolidateOutputs(minimumConfirmations: minimumConfirmations);

  @override
  Future<void> setServers({required WalletConfig config}) =>
      _inner.setServers(config: config);

  @override
  Future<NodeTip> nodeTipFor({required WalletConfig config}) =>
      _inner.nodeTipFor(config: config);

  @override
  Future<SelfSentTx> spendOutputsToSelf({
    required List<String> commitments,
    required BigInt minimumConfirmations,
    int outputs = 1,
  }) => _inner.spendOutputsToSelf(
    commitments: commitments,
    minimumConfirmations: minimumConfirmations,
    outputs: outputs,
  );

  @override
  bool get supportsInvoices => _inner.supportsInvoices;

  @override
  bool get supportsRequestFiles => _inner.supportsRequestFiles;

  // Pairing needs no PIN and no Argon2id run of the wallet's: it passes straight through.
  @override
  PairingApi get pairing => _inner.pairing;

  @override
  Future<InvoiceDrainReport> drainInvoices() => _inner.drainInvoices();

  @override
  Future<List<PendingInvoice>> pendingInvoices() => _inner.pendingInvoices();

  @override
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  }) => _inner.payInvoice(slateId: slateId, amount: amount);

  @override
  Future<PaidRequestFile> payRequestFile({required String slateJson, required BigInt amount}) =>
      _inner.payRequestFile(slateJson: slateJson, amount: amount);

  @override
  Future<PaidInvoice> resendInvoiceReply({required String slateId}) =>
      _inner.resendInvoiceReply(slateId: slateId);

  @override
  Future<void> declineInvoice({required String slateId}) =>
      _inner.declineInvoice(slateId: slateId);

  @override
  Future<PaidInvoice?> paidInvoice({required String slateId}) =>
      _inner.paidInvoice(slateId: slateId);

  @override
  Stream<InvoiceEvent> invoiceEvents() => _inner.invoiceEvents();

  @override
  Future<List<IssuedInvoice>> issuedInvoices() => _inner.issuedInvoices();

  @override
  Future<IssuedInvoice?> issuedInvoice({required String slateId}) =>
      _inner.issuedInvoice(slateId: slateId);

  @override
  Future<IssuedInvoice> withdrawInvoice({required String slateId}) =>
      _inner.withdrawInvoice(slateId: slateId);

  @override
  Future<PaymentsDrainReport> drainPayments() => _inner.drainPayments();

  @override
  Stream<IssuerEvent> issuerEvents() => _inner.issuerEvents();
}
