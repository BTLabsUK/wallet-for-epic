// SPDX-License-Identifier: Apache-2.0
/// A [WalletSession] that passes every call to another: a test overrides the calls it hooks.
library;

import 'dart:typed_data';

import 'package:epic_wallet/src/wallet_service.dart';

/// Passes every call to the session it wraps.
class DelegatingWalletSession implements WalletSession, ListingKeys {
  DelegatingWalletSession(this._inner);

  final WalletSession _inner;

  @override
  void dispose() => _inner.dispose();

  @override
  Future<String> listingAddress(String dkeyHex, int generation) => _inner.listingKeys!.listingAddress(dkeyHex, generation);

  @override
  Future<Uint8List> signWithListing(String dkeyHex, int generation, String domain, Uint8List message) =>
      _inner.listingKeys!.signWithListing(dkeyHex, generation, domain, message);

  @override
  Future<PaymentsDrainReport> drainListing(String dkeyHex, int generation) => _inner.listingKeys!.drainListing(dkeyHex, generation);

  @override
  StoreOpenOutcome get storeOpen => _inner.storeOpen;

  @override
  bool get contactsAvailable => _inner.contactsAvailable;

  @override
  DateTime? get lastActivityAtOpen => _inner.lastActivityAtOpen;

  @override
  Future<String> mnemonic({required String password}) =>
      _inner.mnemonic(password: password);

  @override
  Future<bool> checkPassword({required String password}) =>
      _inner.checkPassword(password: password);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _inner.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) => _inner.mnemonicWithPin(pin: pin, sealedPassword: sealedPassword);

  @override
  Future<void> checkPin({
    required String pin,
    required String sealedPassword,
  }) => _inner.checkPin(pin: pin, sealedPassword: sealedPassword);

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) => _inner.changePin(
    sealedPassword: sealedPassword,
    oldPin: oldPin,
    newPin: newPin,
  );

  @override
  Future<void> confirmPinChange({required String sealedPassword}) =>
      _inner.confirmPinChange(sealedPassword: sealedPassword);

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _inner.cancelTransaction(txId: txId);

  @override
  Future<void> forgetPeers({required Duration olderThan}) =>
      _inner.forgetPeers(olderThan: olderThan);

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

  // HTTP sends and the HTTP listener reach other computers or open a port: not offered to the
  // tests that wrap a session.
  static const WalletError _noHttp = WalletError(
    kind: WalletErrorKind.other,
    message: 'direct HTTP is not offered here',
  );

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
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

  // Tor runs a process and reaches other computers from the server: not offered here.
  static const WalletError _noTor = WalletError(
    kind: WalletErrorKind.other,
    message: 'Tor is not offered here',
  );

  static const WalletError _noDeviceLink = WalletError(
    kind: WalletErrorKind.other,
    message: 'Linked devices are not offered here',
  );

  @override
  Future<String> signDeviceLink(List<int> transcript) async => throw _noDeviceLink;

  @override
  Future<bool> verifyDeviceLink({required List<int> transcript, required String signature}) async => false;

  @override
  Stream<UnmatchedNotice> unmatchedNotices() => const Stream.empty();

  @override
  Future<bool> applyForwardedNotice({required String sender, required String notice}) async => false;

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
  Future<void> setNodeAndHttpOverTor(bool on) async {}

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
        message: 'Importing an old wallet is not offered here',
      );

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _inner.estimateMax(minimumConfirmations: minimumConfirmations);

  @override
  Set<String> get heldOutputs => _inner.heldOutputs;

  @override
  set heldOutputs(Set<String> commitments) => _inner.heldOutputs = commitments;

  @override
  Future<KernelLocation?> kernelOnChain(String excessHex, {int? minHeight}) =>
      _inner.kernelOnChain(excessHex, minHeight: minHeight);

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
  Future<InvoiceCollectReport> collectInvoices() => _inner.collectInvoices();

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
