/// [WalletService] and [WalletSession] over an [RpcChannel], for a wallet that runs elsewhere.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../models.dart';
import '../wallet_service.dart' show PinWallet, WalletService, WalletSession;
import 'channel.dart';
import 'codec.dart';
import 'local_checks.dart';
import 'protocol.dart';

/// The client side of the wallet protocol. Every call becomes a request frame; the server's
/// [WalletDispatcher] answers it.
///
/// Once the channel closes, every pending call and stream fails with [connectionClosed], and
/// so does every later call.
class RemoteWalletService implements WalletService {
  RemoteWalletService(this._channel) {
    _channel.incoming.listen(
      _onFrame,
      onDone: _onClosed,
      onError: (Object _) => _onClosed(),
    );
  }

  final RpcChannel _channel;
  int _lastId = 0;
  bool _closed = false;
  final Map<int, Completer<Object?>> _calls = {};
  final Map<int, StreamController<Object?>> _streams = {};
  final StreamController<RpcPush> _pushes =
      StreamController<RpcPush>.broadcast();

  /// What the server sends outside any call, such as `demoEnded`. Ends with the channel.
  ///
  /// A broadcast stream: a push that arrives while nobody listens is dropped, so subscribe
  /// right after constructing the service.
  Stream<RpcPush> get pushes => _pushes.stream;

  /// True once the channel has closed.
  bool get closed => _closed;

  /// Closes the channel; pending calls fail as for a dropped connection.
  Future<void> close() => _channel.close();

  void _send(Map<String, Object?> frame) => _channel.send(jsonEncode(frame));

  Map<String, Object?> _request(
    int id,
    String member,
    Map<String, Object?> params,
    String? session,
  ) => {'id': id, 'm': member, 'p': params, 's': ?session};

  Future<T> _call<T>(
    String member,
    Map<String, Object?> params,
    WireCodec<T> result, {
    String? session,
  }) {
    if (_closed) return Future<T>.error(connectionClosed);
    final id = ++_lastId;
    final completer = Completer<Object?>();
    _calls[id] = completer;
    _send(_request(id, member, params, session));
    return completer.future.then(result.decode);
  }

  /// A stream that sends its request when listened to and a cancel when cancelled early.
  Stream<T> _stream<T>(
    String member,
    Map<String, Object?> params,
    WireCodec<T> item, {
    String? session,
  }) {
    late final StreamController<T> out;
    int? id;
    StreamSubscription<Object?>? sub;
    out = StreamController<T>(
      onListen: () {
        if (_closed) {
          out
            ..addError(connectionClosed)
            ..close();
          return;
        }
        final raw = StreamController<Object?>();
        id = ++_lastId;
        _streams[id!] = raw;
        sub = raw.stream.listen(
          (json) {
            final T value;
            try {
              value = item.decode(json);
            } on WalletError catch (e) {
              _cancel(id!);
              out
                ..addError(e)
                ..close();
              return;
            }
            out.add(value);
          },
          onError: out.addError,
          onDone: out.close,
        );
        _send(_request(id!, member, params, session));
      },
      onCancel: () {
        final open = id != null && _streams.containsKey(id);
        if (open) _cancel(id!);
        return sub?.cancel();
      },
    );
    return out.stream;
  }

  void _cancel(int id) {
    if (_streams.remove(id) == null) return;
    if (!_closed) _send({'id': id, 'cancel': true});
  }

  /// Sends [member] without waiting for, or reading, an answer.
  void _notify(String member, String session) {
    if (_closed) return;
    _send(_request(++_lastId, member, const {}, session));
  }

  void _onFrame(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return;
    }
    if (json is! Map<String, Object?>) return;
    final push = json['push'];
    if (push is String) {
      _pushes.add(RpcPush(push, {...json}..remove('push')));
      return;
    }
    final id = json['id'];
    if (id is! int) return;
    final error = json.containsKey('e') ? _error(json['e']) : null;
    final call = _calls.remove(id);
    if (call != null) {
      error != null ? call.completeError(error) : call.complete(json['r']);
      return;
    }
    final stream = _streams[id];
    if (stream == null) return;
    if (error != null) {
      _streams.remove(id);
      stream
        ..addError(error)
        ..close();
    } else if (json['end'] == true) {
      _streams.remove(id);
      stream.close();
    } else if (json.containsKey('ev')) {
      stream.add(json['ev']);
    }
  }

  static WalletError _error(Object? json) {
    try {
      return walletErrorWire.decode(json);
    } on WalletError catch (e) {
      return e;
    }
  }

  void _onClosed() {
    if (_closed) return;
    _closed = true;
    final calls = [..._calls.values];
    final streams = [..._streams.values];
    _calls.clear();
    _streams.clear();
    for (final c in calls) {
      c.completeError(connectionClosed);
    }
    for (final s in streams) {
      s
        ..addError(connectionClosed)
        ..close();
    }
    _pushes.close();
  }

  RemoteWalletSession _session(SessionRef ref) =>
      RemoteWalletSession._(this, ref.handle, ref.invoices);

  Future<WalletSession> _open(String member, Map<String, Object?> params) =>
      _call(member, params, sessionRefWire).then(_session);

  // WalletService.

  @override
  bool validateMnemonic({required String phrase}) => validMnemonic(phrase);

  /// The address syntax only; the server's send has the final word.
  @override
  bool validateEpicboxAddress({required String address}) =>
      epicboxAddressFormat(address);

  @override
  Future<SlateInfo> inspectSlate({required String json}) =>
      _call(ServiceMember.inspectSlate.name, {'json': json}, slateInfoWire);

  @override
  Future<bool> walletExists({required WalletConfig config}) => _call(
    ServiceMember.walletExists.name,
    {'config': walletConfigWire.encode(config)},
    boolWire,
  );

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) => _call(
    ServiceMember.nodeTip.name,
    {'config': walletConfigWire.encode(config)},
    nodeTipWire,
  );

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  }) => _open(ServiceMember.create.name, {
    'config': walletConfigWire.encode(config),
    'mnemonic': mnemonic,
    'password': password,
  });

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) => _open(ServiceMember.open.name, {
    'config': walletConfigWire.encode(config),
    'password': password,
  });

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    final ref = await _call(ServiceMember.createWithPin.name, {
      'config': walletConfigWire.encode(config),
      'mnemonic': mnemonic,
      'pin': pin,
    }, pinWalletRefWire);
    return (session: _session(ref.session), sealedPassword: ref.sealedPassword);
  }

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) => _open(ServiceMember.openWithPin.name, {
    'config': walletConfigWire.encode(config),
    'pin': pin,
    'sealedPassword': sealedPassword,
  });

  @override
  Future<int> pinFailures({required WalletConfig config}) => _call(
    ServiceMember.pinFailures.name,
    {'config': walletConfigWire.encode(config)},
    intWire,
  );

  @override
  Future<void> deleteWallet({required WalletConfig config}) => _call(
    ServiceMember.deleteWallet.name,
    {'config': walletConfigWire.encode(config)},
    voidWire,
  );
}

/// A session held by the server under [handle].
class RemoteWalletSession implements WalletSession {
  RemoteWalletSession._(this._service, this.handle, this.supportsInvoices);

  final RemoteWalletService _service;

  /// The server's name for this session.
  final String handle;

  /// As the server reported it when the session opened.
  @override
  final bool supportsInvoices;

  Future<T> _call<T>(
    SessionMember member,
    WireCodec<T> result, [
    Map<String, Object?> params = const {},
  ]) => _service._call(member.name, params, result, session: handle);

  Stream<T> _stream<T>(
    SessionMember member,
    WireCodec<T> item, [
    Map<String, Object?> params = const {},
  ]) => _service._stream(member.name, params, item, session: handle);

  @override
  void dispose() => _service._notify(SessionMember.dispose.name, handle);

  @override
  Future<String> mnemonic({required String password}) =>
      _call(SessionMember.mnemonic, stringWire, {'password': password});

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) => _call(SessionMember.mnemonicWithPin, stringWire, {
    'pin': pin,
    'sealedPassword': sealedPassword,
  });

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) => _call(SessionMember.changePin, stringWire, {
    'sealedPassword': sealedPassword,
    'oldPin': oldPin,
    'newPin': newPin,
  });

  @override
  Future<void> confirmPinChange({required String sealedPassword}) => _call(
    SessionMember.confirmPinChange,
    voidWire,
    {'sealedPassword': sealedPassword},
  );

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _call(SessionMember.cancelTransaction, voidWire, {'txId': txId});

  @override
  Future<void> repostTransaction({required String key}) =>
      _call(SessionMember.repostTransaction, voidWire, {'key': key});

  @override
  Future<void> releaseStuckSend({required String key}) =>
      _call(SessionMember.releaseStuckSend, voidWire, {'key': key});

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) => _call(SessionMember.createSendSlate, slateWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'message': message,
  });

  @override
  Future<String> epicboxAddress() =>
      _call(SessionMember.epicboxAddress, stringWire);

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.estimateFee, feeEstimateWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) => _call(
    SessionMember.finalizeAndPost,
    txEntryWire,
    {'slateJson': slateJson},
  );

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
  }) => _call(SessionMember.sendEpicbox, txEntryWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'address': address,
    'message': message,
  });

  @override
  Stream<ListenerEvent> startListener() =>
      _stream(SessionMember.startListener, listenerEventWire);

  @override
  Future<void> stopListener() => _call(SessionMember.stopListener, voidWire);

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) => _call(
    SessionMember.receiveSlate,
    receivedSlateWire,
    {'slateJson': slateJson},
  );

  @override
  Stream<ScanProgress> scan({BigInt? startHeight}) => _stream(
    SessionMember.scan,
    scanProgressWire,
    {'startHeight': optBigInt.encode(startHeight)},
  );

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.summary, walletSummaryWire, {
    'refresh': refresh,
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations}) =>
      _stream(SessionMember.refresh, refreshProgressWire, {
        'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
      });

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) => _call(
    SessionMember.transactions,
    listOf(txEntryWire),
    {'refresh': refresh},
  );

  @override
  Future<int> enrichHistory() => _call(SessionMember.enrichHistory, intWire);

  @override
  Future<void> setTxNote({required String key, String? note}) =>
      _call(SessionMember.setTxNote, voidWire, {'key': key, 'note': note});

  @override
  Future<List<Contact>> contacts() =>
      _call(SessionMember.contacts, listOf(contactWire));

  @override
  Future<Contact> saveContact({required Contact contact}) => _call(
    SessionMember.saveContact,
    contactWire,
    {'contact': contactWire.encode(contact)},
  );

  @override
  Future<void> deleteContact({required String id}) =>
      _call(SessionMember.deleteContact, voidWire, {'id': id});

  @override
  Future<Uint8List> exportHistory() =>
      _call(SessionMember.exportHistory, bytesWire);

  @override
  Future<String> exportHistoryCsv() =>
      _call(SessionMember.exportHistoryCsv, stringWire);

  @override
  Future<ImportReport> importHistory({required Uint8List data}) => _call(
    SessionMember.importHistory,
    importReportWire,
    {'data': bytesWire.encode(data)},
  );

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _call(SessionMember.estimateMax, feeEstimateWire, {
        'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
      });

  @override
  Future<String> invoiceAddress() =>
      _call(SessionMember.invoiceAddress, stringWire);

  @override
  Future<String> rotateInvoiceAddress() =>
      _call(SessionMember.rotateInvoiceAddress, stringWire);

  @override
  Future<List<TrustedService>> trustedServices() =>
      _call(SessionMember.trustedServices, listOf(trustedServiceWire));

  @override
  Future<TrustedService> addTrustedService({
    required String address,
    required String label,
  }) => _call(SessionMember.addTrustedService, trustedServiceWire, {
    'address': address,
    'label': label,
  });

  @override
  Future<void> removeTrustedService({required String address}) =>
      _call(SessionMember.removeTrustedService, voidWire, {'address': address});

  @override
  Future<InvoiceDrainReport> drainInvoices() =>
      _call(SessionMember.drainInvoices, invoiceDrainReportWire);

  @override
  Future<List<PendingInvoice>> pendingInvoices() =>
      _call(SessionMember.pendingInvoices, listOf(pendingInvoiceWire));

  @override
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  }) => _call(SessionMember.payInvoice, paidInvoiceWire, {
    'slateId': slateId,
    'amount': bigIntWire.encode(amount),
  });

  @override
  Future<PaidInvoice> resendInvoiceReply({required String slateId}) => _call(
    SessionMember.resendInvoiceReply,
    paidInvoiceWire,
    {'slateId': slateId},
  );

  @override
  Future<void> declineInvoice({required String slateId}) =>
      _call(SessionMember.declineInvoice, voidWire, {'slateId': slateId});

  @override
  Future<PaidInvoice?> paidInvoice({required String slateId}) => _call(
    SessionMember.paidInvoice,
    nullable(paidInvoiceWire),
    {'slateId': slateId},
  );

  @override
  Stream<InvoiceEvent> invoiceEvents() =>
      _stream(SessionMember.invoiceEvents, invoiceEventWire);

  @override
  Future<IssuedInvoice> issueInvoice({
    required BigInt amount,
    required String address,
    String? message,
  }) => _call(SessionMember.issueInvoice, issuedInvoiceWire, {
    'amount': bigIntWire.encode(amount),
    'address': address,
    'message': message,
  });

  @override
  Future<List<IssuedInvoice>> issuedInvoices() =>
      _call(SessionMember.issuedInvoices, listOf(issuedInvoiceWire));

  @override
  Future<IssuedInvoice?> issuedInvoice({required String slateId}) => _call(
    SessionMember.issuedInvoice,
    nullable(issuedInvoiceWire),
    {'slateId': slateId},
  );

  @override
  Future<IssuedInvoice> withdrawInvoice({required String slateId}) => _call(
    SessionMember.withdrawInvoice,
    issuedInvoiceWire,
    {'slateId': slateId},
  );

  @override
  Future<PaymentsDrainReport> drainPayments() =>
      _call(SessionMember.drainPayments, paymentsDrainReportWire);

  @override
  Stream<IssuerEvent> issuerEvents() =>
      _stream(SessionMember.issuerEvents, issuerEventWire);

  @override
  Future<PeerCapability> peerCapability({required String address}) => _call(
    SessionMember.peerCapability,
    peerCapabilityWire,
    {'address': address},
  );
}
