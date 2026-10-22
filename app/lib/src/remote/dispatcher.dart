/// Serves any [WalletService] over an [RpcChannel]: the server side of the wallet protocol.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import '../models.dart';
import '../wallet_service.dart' show WalletService, WalletSession;
import 'channel.dart';
import 'codec.dart';
import 'protocol.dart';

/// Open sessions by handle. A dispatcher makes its own unless given one, so a server can let
/// sessions outlive a socket by sharing one table between the sockets of one visitor.
class WalletSessions {
  final Map<String, WalletSession> _byHandle = {};
  final Random _random = Random.secure();

  /// Registers [session] under a new random 128-bit handle.
  String add(WalletSession session) {
    String handle;
    do {
      handle = [
        for (var i = 0; i < 16; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
    } while (_byHandle.containsKey(handle));
    _byHandle[handle] = session;
    return handle;
  }

  WalletSession? operator [](String handle) => _byHandle[handle];

  WalletSession? remove(String handle) => _byHandle.remove(handle);

  bool get isEmpty => _byHandle.isEmpty;

  /// Disposes and forgets every session.
  void disposeAll() {
    final sessions = [..._byHandle.values];
    _byHandle.clear();
    for (final s in sessions) {
      s.dispose();
    }
  }
}

/// Decides whether a call is refused before the service sees it. [params] are the request's
/// raw JSON parameters.
typedef RefuseCall = bool Function(String member, Map<String, Object?> params);

/// Answers the requests that arrive on a channel by calling [WalletService] and its sessions.
///
/// A [WalletError] reaches the client with its kind and message. Anything else thrown is
/// passed to `onError` and reaches the client as [serverError], with no detail. When the
/// channel ends, running streams are cancelled and, unless the sessions table was given, its
/// sessions are disposed.
class WalletDispatcher {
  WalletDispatcher(
    this._service,
    this._channel, {
    WalletSessions? sessions,
    this._refuse,
    this._rewriteConfig,
    this.maxFrameBytes = defaultMaxFrameBytes,
    this.maxInFlight = defaultMaxInFlight,
    void Function(Object error, StackTrace stack)? onError,
  }) : _sessions = sessions ?? WalletSessions(),
       _ownsSessions = sessions == null,
       _onError = onError ?? _logError {
    _channel.incoming.listen(
      _onFrame,
      onDone: _shutDown,
      onError: (Object _) => _shutDown(),
    );
  }

  final WalletService _service;
  final RpcChannel _channel;
  final WalletSessions _sessions;
  final bool _ownsSessions;
  final RefuseCall? _refuse;
  final WalletConfig Function(WalletConfig)? _rewriteConfig;
  final void Function(Object, StackTrace) _onError;

  /// Frames longer than this, in UTF-8 bytes, are refused unread.
  final int maxFrameBytes;

  /// Calls and streams this channel may have running at once; one more is refused with
  /// [tooManyInFlight] until one ends.
  final int maxInFlight;

  final Map<int, StreamSubscription<Object?>> _streams = {};
  final Set<int> _active = {};
  bool _closed = false;
  final Completer<void> _done = Completer<void>();

  /// Completes once the channel has ended and everything is cleaned up.
  Future<void> get done => _done.future;

  static void _logError(Object error, StackTrace stack) => developer.log(
    'wallet call failed',
    name: 'wfe.remote',
    error: error,
    stackTrace: stack,
  );

  /// Sends a push frame, `{"push": name, ...data}`.
  void push(String name, [Map<String, Object?> data = const {}]) =>
      _send({...data, 'push': name});

  /// Closes the channel and cleans up as when the client goes away.
  Future<void> close() async {
    await _channel.close();
    _shutDown();
  }

  void _shutDown() {
    if (_closed) return;
    _closed = true;
    final streams = [..._streams.values];
    _streams.clear();
    for (final s in streams) {
      unawaited(s.cancel());
    }
    if (_ownsSessions) _sessions.disposeAll();
    _done.complete();
  }

  void _send(Map<String, Object?> frame) {
    if (_closed) return;
    _channel.send(jsonEncode(frame));
  }

  void _sendError(int id, WalletError error) =>
      _send({'id': id, 'e': walletErrorWire.encode(error)});

  static final RegExp _leadingId = RegExp(r'^\s*\{\s*"id"\s*:\s*(\d{1,15})\D');

  bool _tooLarge(String text) =>
      text.length > maxFrameBytes ||
      (text.length * 3 > maxFrameBytes &&
          utf8.encode(text).length > maxFrameBytes);

  void _onFrame(String text) {
    if (_closed) return;
    // Clients write the id first, so an unreadable frame can still be answered.
    int? leadingId() {
      final m = _leadingId.firstMatch(text);
      return m == null ? null : int.parse(m.group(1)!);
    }

    if (_tooLarge(text)) {
      final id = leadingId();
      if (id != null) _sendError(id, frameTooLarge);
      return;
    }
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      final id = leadingId();
      if (id != null) _sendError(id, badFrame);
      return;
    }
    if (json is! Map<String, Object?>) return;
    final id = json['id'];
    if (id is! int) return;
    if (json['cancel'] == true) {
      // Only a stream ends early; a one-shot call keeps its id until it answers.
      final stream = _streams.remove(id);
      if (stream != null) {
        _active.remove(id);
        unawaited(stream.cancel());
      }
      return;
    }
    final member = json['m'];
    final params = json['p'] ?? const <String, Object?>{};
    final session = json['s'];
    if (member is! String ||
        params is! Map<String, Object?> ||
        (session != null && session is! String)) {
      _sendError(id, badFrame);
      return;
    }
    if (_active.contains(id)) {
      _sendError(id, idInUse);
      return;
    }
    if (_active.length >= maxInFlight) {
      _sendError(id, tooManyInFlight);
      return;
    }
    _active.add(id);
    _handle(id, member, params, session as String?);
  }

  void _handle(
    int id,
    String member,
    Map<String, Object?> params,
    String? handle,
  ) {
    final _Outcome outcome;
    try {
      outcome = _dispatch(member, params, handle);
    } catch (e, st) {
      _fail(id, e, st);
      return;
    }
    switch (outcome) {
      case _Once(:final future):
        future.then((r) {
          _active.remove(id);
          _send({'id': id, 'r': r});
        }, onError: (Object e, StackTrace st) => _fail(id, e, st));
      case _Many(:final stream):
        _streams[id] = stream.listen(
          (event) => _send({'id': id, 'ev': event}),
          onError: (Object e, StackTrace st) {
            _streams.remove(id);
            _fail(id, e, st);
          },
          onDone: () {
            _streams.remove(id);
            _active.remove(id);
            _send({'id': id, 'end': true});
          },
          cancelOnError: true,
        );
    }
  }

  void _fail(int id, Object error, StackTrace stack) {
    _active.remove(id);
    if (error is WalletError) {
      _sendError(id, error);
    } else {
      _onError(error, stack);
      _sendError(id, serverError);
    }
  }

  _Outcome _dispatch(String name, Map<String, Object?> params, String? handle) {
    final p = WireReader(params, name);
    if (handle == null) {
      final member = ServiceMember.values.asNameMap()[name];
      if (member == null) throw unknownMember(name);
      if (_refuse?.call(name, params) ?? false) throw refusedMember(name);
      return _serve(member, p);
    }
    final member = SessionMember.values.asNameMap()[name];
    if (member == null) throw unknownMember(name);
    if (_refuse?.call(name, params) ?? false) throw refusedMember(name);
    final session = _sessions[handle];
    if (session == null) throw unknownSession;
    return _serveSession(member, session, handle, p);
  }

  WalletConfig _config(WireReader p) {
    final config = p.of('config', walletConfigWire);
    return _rewriteConfig?.call(config) ?? config;
  }

  /// A session that opens after its own sessions were disposed is disposed at once.
  SessionRef _register(WalletSession session) {
    if (_closed && _ownsSessions) {
      session.dispose();
      throw connectionClosed;
    }
    return (handle: _sessions.add(session), invoices: session.supportsInvoices);
  }

  _Outcome _serve(ServiceMember member, WireReader p) => switch (member) {
    ServiceMember.inspectSlate => _once(
      _service.inspectSlate(json: p.of('json', stringWire)),
      slateInfoWire,
    ),
    ServiceMember.walletExists => _once(
      _service.walletExists(config: _config(p)),
      boolWire,
    ),
    ServiceMember.nodeTip => _once(
      _service.nodeTip(config: _config(p)),
      nodeTipWire,
    ),
    ServiceMember.create => _once(
      _service
          .create(
            config: _config(p),
            mnemonic: p.of('mnemonic', optString),
            password: p.of('password', stringWire),
          )
          .then(_register),
      sessionRefWire,
    ),
    ServiceMember.open => _once(
      _service
          .open(config: _config(p), password: p.of('password', stringWire))
          .then(_register),
      sessionRefWire,
    ),
    ServiceMember.createWithPin => _once(
      _service
          .createWithPin(
            config: _config(p),
            mnemonic: p.of('mnemonic', optString),
            pin: p.of('pin', stringWire),
          )
          .then(
            (w) => (
              session: _register(w.session),
              sealedPassword: w.sealedPassword,
            ),
          ),
      pinWalletRefWire,
    ),
    ServiceMember.openWithPin => _once(
      _service
          .openWithPin(
            config: _config(p),
            pin: p.of('pin', stringWire),
            sealedPassword: p.of('sealedPassword', stringWire),
          )
          .then(_register),
      sessionRefWire,
    ),
    ServiceMember.pinFailures => _once(
      _service.pinFailures(config: _config(p)),
      intWire,
    ),
    ServiceMember.deleteWallet => _once(
      _service.deleteWallet(config: _config(p)),
      voidWire,
    ),
  };

  _Outcome _serveSession(
    SessionMember member,
    WalletSession s,
    String handle,
    WireReader p,
  ) => switch (member) {
    SessionMember.dispose => _once(
      Future(() {
        _sessions.remove(handle);
        s.dispose();
      }),
      voidWire,
    ),
    SessionMember.mnemonic => _once(
      s.mnemonic(password: p.of('password', stringWire)),
      stringWire,
    ),
    SessionMember.mnemonicWithPin => _once(
      s.mnemonicWithPin(
        pin: p.of('pin', stringWire),
        sealedPassword: p.of('sealedPassword', stringWire),
      ),
      stringWire,
    ),
    SessionMember.changePin => _once(
      s.changePin(
        sealedPassword: p.of('sealedPassword', stringWire),
        oldPin: p.of('oldPin', stringWire),
        newPin: p.of('newPin', stringWire),
      ),
      stringWire,
    ),
    SessionMember.confirmPinChange => _once(
      s.confirmPinChange(sealedPassword: p.of('sealedPassword', stringWire)),
      voidWire,
    ),
    SessionMember.cancelTransaction => _once(
      s.cancelTransaction(txId: p.of('txId', intWire)),
      voidWire,
    ),
    SessionMember.repostTransaction => _once(
      s.repostTransaction(key: p.of('key', stringWire)),
      voidWire,
    ),
    SessionMember.releaseStuckSend => _once(
      s.releaseStuckSend(key: p.of('key', stringWire)),
      voidWire,
    ),
    SessionMember.createSendSlate => _once(
      s.createSendSlate(
        amount: p.of('amount', bigIntWire),
        minimumConfirmations: p.of('minimumConfirmations', bigIntWire),
        message: p.of('message', optString),
      ),
      slateWire,
    ),
    SessionMember.epicboxAddress => _once(s.epicboxAddress(), stringWire),
    SessionMember.estimateFee => _once(
      s.estimateFee(
        amount: p.of('amount', bigIntWire),
        minimumConfirmations: p.of('minimumConfirmations', bigIntWire),
      ),
      feeEstimateWire,
    ),
    SessionMember.finalizeAndPost => _once(
      s.finalizeAndPost(slateJson: p.of('slateJson', stringWire)),
      txEntryWire,
    ),
    SessionMember.sendEpicbox => _once(
      s.sendEpicbox(
        amount: p.of('amount', bigIntWire),
        minimumConfirmations: p.of('minimumConfirmations', bigIntWire),
        address: p.of('address', stringWire),
        message: p.of('message', optString),
      ),
      txEntryWire,
    ),
    SessionMember.startListener => _many(s.startListener(), listenerEventWire),
    SessionMember.stopListener => _once(s.stopListener(), voidWire),
    SessionMember.receiveSlate => _once(
      s.receiveSlate(slateJson: p.of('slateJson', stringWire)),
      receivedSlateWire,
    ),
    SessionMember.scan => _many(
      _stopsOnCancel(s.scan(startHeight: p.of('startHeight', optBigInt)), s.cancelScan),
      scanProgressWire,
    ),
    SessionMember.summary => _once(
      s.summary(
        refresh: p.of('refresh', boolWire),
        minimumConfirmations: p.of('minimumConfirmations', bigIntWire),
      ),
      walletSummaryWire,
    ),
    SessionMember.refresh => _many(
      s.refresh(minimumConfirmations: p.of('minimumConfirmations', bigIntWire)),
      refreshProgressWire,
    ),
    SessionMember.transactions => _once(
      s.transactions(refresh: p.of('refresh', boolWire)),
      listOf(txEntryWire),
    ),
    SessionMember.enrichHistory => _once(s.enrichHistory(), intWire),
    SessionMember.setTxNote => _once(
      s.setTxNote(key: p.of('key', stringWire), note: p.of('note', optString)),
      voidWire,
    ),
    SessionMember.contacts => _once(s.contacts(), listOf(contactWire)),
    SessionMember.saveContact => _once(
      s.saveContact(contact: p.of('contact', contactWire)),
      contactWire,
    ),
    SessionMember.deleteContact => _once(
      s.deleteContact(id: p.of('id', stringWire)),
      voidWire,
    ),
    SessionMember.exportHistory => _once(s.exportHistory(), bytesWire),
    SessionMember.exportHistoryCsv => _once(s.exportHistoryCsv(), stringWire),
    SessionMember.importHistory => _once(
      s.importHistory(data: p.of('data', bytesWire)),
      importReportWire,
    ),
    SessionMember.estimateMax => _once(
      s.estimateMax(
        minimumConfirmations: p.of('minimumConfirmations', bigIntWire),
      ),
      feeEstimateWire,
    ),
    SessionMember.invoiceAddress => _once(s.invoiceAddress(), stringWire),
    SessionMember.rotateInvoiceAddress => _once(
      s.rotateInvoiceAddress(),
      stringWire,
    ),
    SessionMember.trustedServices => _once(
      s.trustedServices(),
      listOf(trustedServiceWire),
    ),
    SessionMember.addTrustedService => _once(
      s.addTrustedService(
        address: p.of('address', stringWire),
        label: p.of('label', stringWire),
      ),
      trustedServiceWire,
    ),
    SessionMember.removeTrustedService => _once(
      s.removeTrustedService(address: p.of('address', stringWire)),
      voidWire,
    ),
    SessionMember.drainInvoices => _once(
      s.drainInvoices(),
      invoiceDrainReportWire,
    ),
    SessionMember.pendingInvoices => _once(
      s.pendingInvoices(),
      listOf(pendingInvoiceWire),
    ),
    SessionMember.payInvoice => _once(
      s.payInvoice(
        slateId: p.of('slateId', stringWire),
        amount: p.of('amount', bigIntWire),
      ),
      paidInvoiceWire,
    ),
    SessionMember.resendInvoiceReply => _once(
      s.resendInvoiceReply(slateId: p.of('slateId', stringWire)),
      paidInvoiceWire,
    ),
    SessionMember.declineInvoice => _once(
      s.declineInvoice(slateId: p.of('slateId', stringWire)),
      voidWire,
    ),
    SessionMember.paidInvoice => _once(
      s.paidInvoice(slateId: p.of('slateId', stringWire)),
      nullable(paidInvoiceWire),
    ),
    SessionMember.invoiceEvents => _many(s.invoiceEvents(), invoiceEventWire),
    SessionMember.issueInvoice => _once(
      s.issueInvoice(
        amount: p.of('amount', bigIntWire),
        address: p.of('address', stringWire),
        message: p.of('message', optString),
      ),
      issuedInvoiceWire,
    ),
    SessionMember.issuedInvoices => _once(
      s.issuedInvoices(),
      listOf(issuedInvoiceWire),
    ),
    SessionMember.issuedInvoice => _once(
      s.issuedInvoice(slateId: p.of('slateId', stringWire)),
      nullable(issuedInvoiceWire),
    ),
    SessionMember.withdrawInvoice => _once(
      s.withdrawInvoice(slateId: p.of('slateId', stringWire)),
      issuedInvoiceWire,
    ),
    SessionMember.drainPayments => _once(
      s.drainPayments(),
      paymentsDrainReportWire,
    ),
    SessionMember.issuerEvents => _many(s.issuerEvents(), issuerEventWire),
    SessionMember.peerCapability => _once(
      s.peerCapability(address: p.of('address', stringWire)),
      peerCapabilityWire,
    ),
  };
}

_Outcome _once<T>(Future<T> future, WireCodec<T> codec) =>
    _Once(future.then(codec.encode));

_Outcome _many<T>(Stream<T> stream, WireCodec<T> codec) =>
    _Many(stream.map(codec.encode));

/// What a member gives back: one value, or a stream of them.
sealed class _Outcome {}

final class _Once extends _Outcome {
  _Once(this.future);
  final Future<Object?> future;
}

final class _Many extends _Outcome {
  _Many(this.stream);
  final Stream<Object?> stream;
}

/// [source], whose early cancel (the client's Stop, or the channel ending) also calls [stop]:
/// the wallet's scan goes on unless asked to stop.
Stream<T> _stopsOnCancel<T>(Stream<T> source, void Function() stop) {
  StreamSubscription<T>? sub;
  var done = false;
  late final StreamController<T> out;
  out = StreamController<T>(
    onListen: () => sub = source.listen(out.add, onError: out.addError, onDone: () {
      done = true;
      out.close();
    }),
    onCancel: () {
      if (!done) stop();
      return sub?.cancel();
    },
  );
  return out.stream;
}
