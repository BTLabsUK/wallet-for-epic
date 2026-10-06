/// A [WalletService] whose PIN and password calls wait for a [WorkGate] slot.
///
/// LEPIC runs Argon2id at 64 MiB for each of them, so the server caps how many run at once
/// across all demos. Everything else passes straight through.
library;

import 'dart:typed_data';

import '../wallet_service.dart';
import 'limits.dart';

class GatedWalletService implements WalletService {
  GatedWalletService(this._inner, this._gate);

  final WalletService _inner;
  final WorkGate _gate;

  WalletSession _wrap(WalletSession s) => GatedWalletSession(s, _gate);

  @override
  bool validateMnemonic({required String phrase}) =>
      _inner.validateMnemonic(phrase: phrase);

  @override
  Future<SlateInfo> inspectSlate({required String json}) =>
      _inner.inspectSlate(json: json);

  @override
  bool validateEpicboxAddress({required String address}) =>
      _inner.validateEpicboxAddress(address: address);

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
    await _gate.run(
      () =>
          _inner.create(config: config, mnemonic: mnemonic, password: password),
    ),
  );

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) async => _wrap(
    await _gate.run(() => _inner.open(config: config, password: password)),
  );

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    final w = await _gate.run(
      () => _inner.createWithPin(config: config, mnemonic: mnemonic, pin: pin),
    );
    return (session: _wrap(w.session), sealedPassword: w.sealedPassword);
  }

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) async => _wrap(
    await _gate.run(
      () => _inner.openWithPin(
        config: config,
        pin: pin,
        sealedPassword: sealedPassword,
      ),
    ),
  );

  @override
  Future<int> pinFailures({required WalletConfig config}) =>
      _inner.pinFailures(config: config);

  @override
  Future<void> deleteWallet({required WalletConfig config}) =>
      _inner.deleteWallet(config: config);
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
  Future<void> releaseStuckSend({required String key}) =>
      _inner.releaseStuckSend(key: key);

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) => _inner.createSendSlate(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    message: message,
  );

  @override
  Future<String> epicboxAddress() => _inner.epicboxAddress();

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _inner.estimateFee(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
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
  }) => _inner.sendEpicbox(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    address: address,
    message: message,
  );

  @override
  Stream<ListenerEvent> startListener() => _inner.startListener();

  @override
  Future<void> stopListener() => _inner.stopListener();

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) =>
      _inner.receiveSlate(slateJson: slateJson);

  @override
  Stream<ScanProgress> scan({BigInt? startHeight}) =>
      _inner.scan(startHeight: startHeight);

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _inner.summary(
    refresh: refresh,
    minimumConfirmations: minimumConfirmations,
  );

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
  Future<List<Contact>> contacts() => _inner.contacts();

  @override
  Future<Contact> saveContact({required Contact contact}) =>
      _inner.saveContact(contact: contact);

  @override
  Future<void> deleteContact({required String id}) =>
      _inner.deleteContact(id: id);

  @override
  Future<Uint8List> exportHistory() => _inner.exportHistory();

  @override
  Future<String> exportHistoryCsv() => _inner.exportHistoryCsv();

  @override
  Future<ImportReport> importHistory({required Uint8List data}) =>
      _inner.importHistory(data: data);

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _inner.estimateMax(minimumConfirmations: minimumConfirmations);

  @override
  bool get supportsInvoices => _inner.supportsInvoices;

  @override
  Future<String> invoiceAddress() => _inner.invoiceAddress();

  @override
  Future<String> rotateInvoiceAddress() => _inner.rotateInvoiceAddress();

  @override
  Future<List<TrustedService>> trustedServices() => _inner.trustedServices();

  @override
  Future<TrustedService> addTrustedService({
    required String address,
    required String label,
  }) => _inner.addTrustedService(address: address, label: label);

  @override
  Future<void> removeTrustedService({required String address}) =>
      _inner.removeTrustedService(address: address);

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
  Future<IssuedInvoice> issueInvoice({
    required BigInt amount,
    required String address,
    String? message,
  }) => _inner.issueInvoice(amount: amount, address: address, message: message);

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

  @override
  Future<PeerCapability> peerCapability({required String address}) =>
      _inner.peerCapability(address: address);
}
