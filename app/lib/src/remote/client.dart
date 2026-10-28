/// [WalletService] and [WalletSession] over an [RpcChannel], for a wallet that runs elsewhere.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../models.dart';
import '../pairing_api.dart';
import '../wallet_service.dart'
    show PinWallet, WalletService, WalletSession, onionAddressFormat;
import 'channel.dart';
import 'codec.dart';
import 'local_checks.dart';
import 'protocol.dart';

/// Opens a new connection to the server, or throws when it cannot.
typedef ChannelConnector = Future<RpcChannel> Function();

/// Where the connection of a [RemoteWalletService] stands.
enum RemoteConnection {
  /// Not connected and not trying: before the first call, or after
  /// [RemoteWalletService.disconnect]. The next call connects.
  idle,

  /// The first attempt after [idle]. Calls made meanwhile wait for it.
  connecting,

  connected,

  /// The connection dropped and the client is retrying. Calls fail at once meanwhile.
  reconnecting,

  /// For good: [RemoteWalletService.close], or a single channel that closed.
  closed,
}

/// The client side of the wallet protocol. Every call becomes a request frame; the server's
/// [WalletDispatcher] answers it.
///
/// Over one channel ([RemoteWalletService.new]), once the channel closes, every pending call
/// and stream fails with [connectionClosed], and so does every later call.
///
/// With a connector ([RemoteWalletService.reconnecting]), the first call connects. A dropped
/// connection fails what was pending with [connectionClosed] and is retried after
/// [firstRetry], doubling up to [maxRetry]; calls fail at once until it is back. Session
/// handles stay valid across connections as long as the server keeps them; a call on one it
/// no longer knows fails with [unknownSession] and its handle goes to [lostSessions].
class RemoteWalletService implements WalletService {
  RemoteWalletService(RpcChannel channel)
    : _connect = null,
      firstRetry = Duration.zero,
      maxRetry = Duration.zero,
      closingPushes = const {},
      _state = RemoteConnection.connected {
    _attach(channel);
  }

  RemoteWalletService.reconnecting(
    ChannelConnector connect, {
    this.firstRetry = const Duration(seconds: 1),
    this.maxRetry = const Duration(seconds: 30),
    this.closingPushes = const {},
  }) : _connect = connect,
       _state = RemoteConnection.idle;

  final ChannelConnector? _connect;

  /// The wait before the first retry after a drop.
  final Duration firstRetry;

  /// The longest wait between retries.
  final Duration maxRetry;

  /// Pushes after which the server closes the connection on purpose, such as `demoEnded`:
  /// the client goes [RemoteConnection.idle] instead of retrying.
  final Set<String> closingPushes;

  RemoteConnection _state;
  RpcChannel? _channel;
  StreamSubscription<String>? _incoming;

  /// Frames sent while [RemoteConnection.connecting], flushed once connected.
  final List<String> _queued = [];
  Timer? _retry;
  late Duration _delay = firstRetry;

  int _lastId = 0;
  final Map<int, Completer<Object?>> _calls = {};
  final Map<int, StreamController<Object?>> _streams = {};
  final StreamController<RpcPush> _pushes =
      StreamController<RpcPush>.broadcast();
  final StreamController<RemoteConnection> _connection =
      StreamController<RemoteConnection>.broadcast();
  final StreamController<String> _lost = StreamController<String>.broadcast();

  /// What the server sends outside any call, such as `demoEnded`. Over one channel it ends
  /// with the channel; with a connector it spans every connection and ends at [close].
  ///
  /// A broadcast stream: a push that arrives while nobody listens is dropped, so subscribe
  /// right after constructing the service.
  Stream<RpcPush> get pushes => _pushes.stream;

  /// The connection now.
  RemoteConnection get connection => _state;

  /// Every change of [connection].
  Stream<RemoteConnection> get connectionChanges => _connection.stream;

  /// Handles of sessions the server answered [unknownSession] for: it dropped them, as after
  /// its idle timeout. The wallet behind one is locked.
  Stream<String> get lostSessions => _lost.stream;

  /// True once the service is closed for good.
  bool get closed => _state == RemoteConnection.closed;

  /// Closes the connection for good; pending calls fail as for a dropped connection.
  Future<void> close() async {
    if (closed) return;
    final channel = _drop(RemoteConnection.closed);
    await _pushes.close();
    await _connection.close();
    await _lost.close();
    await channel?.close();
  }

  /// Closes the connection and stops retrying, as when the demo behind it ended. Pending
  /// calls fail; the next call connects again. Nothing happens over one channel, or once
  /// closed.
  Future<void> disconnect() async {
    if (_connect == null || closed || _state == RemoteConnection.idle) return;
    await _drop(RemoteConnection.idle)?.close();
  }

  /// Leaves the current channel, fails what was pending and moves to [next]. Returns the
  /// channel, for the caller to close.
  RpcChannel? _drop(RemoteConnection next) {
    _retry?.cancel();
    _retry = null;
    final channel = _channel;
    _channel = null;
    unawaited(_incoming?.cancel());
    _incoming = null;
    _failPending();
    _setState(next);
    return channel;
  }

  void _setState(RemoteConnection next) {
    if (_state == next) return;
    _state = next;
    if (!_connection.isClosed) _connection.add(next);
  }

  void _attach(RpcChannel channel) {
    _channel = channel;
    _incoming = channel.incoming.listen(
      _onFrame,
      onDone: () => _onClosed(channel),
      onError: (Object _) => _onClosed(channel),
    );
  }

  /// Whether a call can go out now. From [RemoteConnection.idle] it starts connecting, and
  /// the call waits for that.
  bool _ready() {
    switch (_state) {
      case RemoteConnection.connected || RemoteConnection.connecting:
        return true;
      case RemoteConnection.idle:
        _startConnect();
        return true;
      case RemoteConnection.reconnecting || RemoteConnection.closed:
        return false;
    }
  }

  void _startConnect() {
    _setState(RemoteConnection.connecting);
    unawaited(
      _connect!().then(
        (channel) {
          if (_state != RemoteConnection.connecting) {
            unawaited(channel.close());
            return;
          }
          _connected(channel);
          final frames = [..._queued];
          _queued.clear();
          frames.forEach(channel.send);
        },
        onError: (Object _) {
          if (_state != RemoteConnection.connecting) return;
          _failPending();
          _delay = firstRetry;
          _scheduleRetry();
        },
      ),
    );
  }

  void _connected(RpcChannel channel) {
    _attach(channel);
    _delay = firstRetry;
    _setState(RemoteConnection.connected);
  }

  void _scheduleRetry() {
    _setState(RemoteConnection.reconnecting);
    _retry?.cancel();
    final wait = _delay;
    final doubled = _delay * 2;
    _delay = doubled > maxRetry ? maxRetry : doubled;
    _retry = Timer(wait, () {
      _retry = null;
      unawaited(
        _connect!().then(
          (channel) {
            if (_state != RemoteConnection.reconnecting) {
              unawaited(channel.close());
              return;
            }
            _connected(channel);
          },
          onError: (Object _) {
            if (_state == RemoteConnection.reconnecting) _scheduleRetry();
          },
        ),
      );
    });
  }

  void _send(Map<String, Object?> frame) {
    final text = jsonEncode(frame);
    switch (_state) {
      case RemoteConnection.connected:
        _channel?.send(text);
      case RemoteConnection.connecting:
        _queued.add(text);
      case RemoteConnection.idle ||
          RemoteConnection.reconnecting ||
          RemoteConnection.closed:
        break;
    }
  }

  Map<String, Object?> _request(
    int id,
    String member,
    Map<String, Object?> params,
    String? session,
  ) => {'id': id, 'm': member, 'p': params, 's': ?session};

  /// Reports [error] on [session] to [lostSessions] when the server no longer knows it.
  void _checkLost(Object error, String? session) {
    if (session == null || error is! WalletError) return;
    if (error.kind == unknownSession.kind &&
        error.message == unknownSession.message &&
        !_lost.isClosed) {
      _lost.add(session);
    }
  }

  Future<T> _call<T>(
    String member,
    Map<String, Object?> params,
    WireCodec<T> result, {
    String? session,
  }) {
    if (!_ready()) return Future<T>.error(connectionClosed);
    final id = ++_lastId;
    final completer = Completer<Object?>();
    _calls[id] = completer;
    _send(_request(id, member, params, session));
    return completer.future.then(
      result.decode,
      onError: (Object error, StackTrace stack) {
        _checkLost(error, session);
        Error.throwWithStackTrace(error, stack);
      },
    );
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
        if (!_ready()) {
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
          onError: (Object error, StackTrace stack) {
            _checkLost(error, session);
            out.addError(error, stack);
          },
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
    _send({'id': id, 'cancel': true});
  }

  /// Sends [member] without waiting for, or reading, an answer. Dropped while not connected:
  /// it never opens a connection.
  void _notify(String member, String session) {
    if (_state != RemoteConnection.connected &&
        _state != RemoteConnection.connecting) {
      return;
    }
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
      if (!_pushes.isClosed) {
        _pushes.add(RpcPush(push, {...json}..remove('push')));
      }
      if (_connect != null && closingPushes.contains(push)) {
        unawaited(_drop(RemoteConnection.idle)?.close());
      }
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

  void _failPending() {
    _queued.clear();
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
  }

  void _onClosed(RpcChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    _incoming = null;
    _failPending();
    if (_connect == null) {
      _setState(RemoteConnection.closed);
      _pushes.close();
      _connection.close();
      _lost.close();
      return;
    }
    _delay = firstRetry;
    _scheduleRetry();
  }

  RemoteWalletSession _session(SessionRef ref) =>
      RemoteWalletSession._(this, ref.handle, ref.invoices, ref.pairing, ref.requestFiles);

  Future<WalletSession> _open(String member, Map<String, Object?> params) =>
      _call(member, params, sessionRefWire).then(_session);

  // WalletService.

  @override
  bool validateMnemonic({required String phrase}) => validMnemonic(phrase);

  /// Answered by the core only, which a call cannot reach synchronously; the open wallet's
  /// [WalletSession.fingerprint] goes to the server.
  @override
  String walletFingerprint({required String mnemonic, required Chain chain}) =>
      throw const WalletError(
        kind: WalletErrorKind.other,
        message: 'no wallet fingerprint in the browser',
      );

  /// The address syntax only; the server's send has the final word.
  @override
  bool validateEpicboxAddress({required String address}) =>
      epicboxAddressFormat(address);

  /// The syntax cannot tell the chains apart; the server's send has the final word.
  @override
  bool epicboxAddressOtherChain({required String address}) => false;

  /// The address syntax only.
  @override
  bool validateOnionAddress({required String address}) =>
      onionAddressFormat(address);

  @override
  Future<SlateInfo> inspectSlate({required String json}) =>
      _call(ServiceMember.inspectSlate.name, {'json': json}, slateInfoWire);

  /// The payment QR is for people next to each other, so the remote protocol does not offer
  /// it.
  @override
  Future<List<String>> encodeQrSlate({
    required String json,
    required int maxFragmentLen,
  }) async => throw const WalletError(
    kind: WalletErrorKind.invalidArgument,
    message: 'the payment QR is not offered remotely',
  );

  @override
  Future<QrSlateProgress> decodeQrSlate({required List<String> parts}) async =>
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the payment QR is not offered remotely',
      );

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

  /// Import reads a file on the computer the app runs on, so the remote protocol does not
  /// offer it.
  @override
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  }) async => throw const WalletError(
    kind: WalletErrorKind.invalidArgument,
    message: 'import is not offered remotely',
  );

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

  @override
  Future<void> resetPassword({
    required WalletConfig config,
    required String mnemonic,
    required String newPassword,
  }) => _call(
    ServiceMember.resetPassword.name,
    {
      'config': walletConfigWire.encode(config),
      'mnemonic': mnemonic,
      'newPassword': newPassword,
    },
    voidWire,
  );
}

/// A session held by the server under [handle].
class RemoteWalletSession implements WalletSession {
  RemoteWalletSession._(this._service, this.handle, this.supportsInvoices, bool pairs, this.supportsRequestFiles) {
    pairing = pairs ? RemotePairing._(this) : const NoPairing();
  }

  final RemoteWalletService _service;

  /// The server's name for this session.
  final String handle;

  /// As the server reported it when the session opened.
  @override
  final bool supportsInvoices;

  /// As the server reported it when the session opened.
  @override
  final bool supportsRequestFiles;

  /// [RemotePairing] when the server's core pairs, else [NoPairing].
  @override
  late final PairingApi pairing;

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
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _call(SessionMember.changePassword, voidWire, {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  });

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
  Future<void> resendEpicbox({required String key}) =>
      _call(SessionMember.resendEpicbox, voidWire, {'key': key});

  @override
  Future<void> releaseStuckSend({required String key}) =>
      _call(SessionMember.releaseStuckSend, voidWire, {'key': key});

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _call(SessionMember.createSendSlate, slateWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'message': message,
    'options': optSendOptions.encode(options),
  });

  @override
  Future<String> epicboxAddress() =>
      _call(SessionMember.epicboxAddress, stringWire);

  @override
  Future<bool> restoreScanRequired() =>
      _call(SessionMember.restoreScanRequired, boolWire);

  @override
  Future<String> fingerprint() => _call(SessionMember.fingerprint, stringWire);

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) => _call(SessionMember.estimateFee, feeEstimateWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'options': optSendOptions.encode(options),
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
    SendOptions? options,
  }) => _call(SessionMember.sendEpicbox, txEntryWire, {
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'address': address,
    'message': message,
    'options': optSendOptions.encode(options),
  });

  @override
  Stream<ListenerEvent> startListener() =>
      _stream(SessionMember.startListener, listenerEventWire);

  @override
  Future<void> stopListener() => _call(SessionMember.stopListener, voidWire);

  // HTTP sends and the HTTP listener reach other computers or open a port on the server:
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
  Future<ReceivedSlate> receiveSlate({required String slateJson}) => _call(
    SessionMember.receiveSlate,
    receivedSlateWire,
    {'slateJson': slateJson},
  );

  /// The running [scan]: [cancelScan] ends it.
  StreamController<ScanProgress>? _scanning;
  StreamSubscription<ScanProgress>? _scanSub;

  /// The remote protocol carries no deleteUnconfirmed; asking for it is refused.
  @override
  Stream<ScanProgress> scan({
    BigInt? startHeight,
    bool deleteUnconfirmed = false,
  }) {
    if (deleteUnconfirmed) {
      return Stream.error(UnsupportedError('deleteUnconfirmed over the remote wallet'));
    }
    late final StreamController<ScanProgress> out;
    void end() {
      if (identical(_scanning, out)) {
        _scanning = null;
        _scanSub = null;
      }
    }

    out = StreamController<ScanProgress>(
      onListen: () {
        _scanning = out;
        _scanSub = _stream(SessionMember.scan, scanProgressWire, {
          'startHeight': optBigInt.encode(startHeight),
        }).listen(out.add, onError: out.addError, onDone: () {
          end();
          out.close();
        });
      },
      onCancel: () {
        final sub = identical(_scanning, out) ? _scanSub : null;
        end();
        return sub?.cancel();
      },
    );
    return out.stream;
  }

  /// No call of its own in the protocol: the scan stream is cancelled, which sends the
  /// server a cancel; the server stops its scan ([WalletSession.cancelScan]) when its scan
  /// stream is cancelled. The stream here then ends without a `finished` event.
  @override
  void cancelScan() {
    final out = _scanning;
    final sub = _scanSub;
    if (out == null) return;
    _scanning = null;
    _scanSub = null;
    unawaited(sub?.cancel());
    unawaited(out.close());
  }

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.summary, walletSummaryWire, {
    'refresh': refresh,
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<int> minimumConfirmations() => _call(SessionMember.minimumConfirmations, intWire);

  @override
  Future<void> setMinimumConfirmations(int count) =>
      _call(SessionMember.setMinimumConfirmations, voidWire, {'count': count});

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
  Future<void> setTxLabel({required String key, String? label}) =>
      _call(SessionMember.setTxLabel, voidWire, {'key': key, 'label': label});

  @override
  Future<void> setTxDetails({
    required String key,
    String? counterparty,
    String? transport,
    String? note,
  }) => _call(SessionMember.setTxDetails, voidWire, {
    'key': key,
    'counterparty': counterparty,
    'transport': transport,
    'note': note,
  });

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
  Future<List<String>> favouriteContacts() =>
      _call(SessionMember.favouriteContacts, listOf(stringWire));

  @override
  Future<void> setFavouriteContact({required String id, required bool favourite}) => _call(
    SessionMember.setFavouriteContact,
    voidWire,
    {'id': id, 'favourite': favourite},
  );

  @override
  Future<Uint8List> exportHistory({String? walletName, Map<String, Object?>? settings}) =>
      _call(SessionMember.exportHistory, bytesWire, {
        'walletName': walletName,
        'settings': settings == null ? null : jsonEncode(settings),
      });

  @override
  Future<String> exportHistoryCsv() =>
      _call(SessionMember.exportHistoryCsv, stringWire);

  @override
  Future<ImportReport> importHistory({
    required Uint8List data,
    Map<String, bool>? useBackup,
  }) => _call(SessionMember.importHistory, importReportWire, {
    'data': bytesWire.encode(data),
    'useBackup': nullable(mapOf(boolWire)).encode(useBackup),
  });

  // An old wallet's folder is on the server's disk, which a remote client does not choose.
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
      _call(SessionMember.estimateMax, feeEstimateWire, {
        'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
      });

  // Linked devices hold coins in the app that holds the wallet, not over the remote protocol.
  @override
  Set<String> heldOutputs = const {};

  @override
  Future<List<WalletOutput>> outputs() =>
      _call(SessionMember.outputs, listOf(walletOutputWire));

  @override
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.estimateSplit, feeEstimateWire, {
    'outputs': outputs,
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.splitOutputs, selfSentTxWire, {
    'outputs': outputs,
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<FeeEstimate> estimateConsolidate({
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.estimateConsolidate, feeEstimateWire, {
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<SelfSentTx> consolidateOutputs({
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.consolidateOutputs, selfSentTxWire, {
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<SelfSentTx> spendOutputsToSelf({
    required List<String> commitments,
    required BigInt minimumConfirmations,
  }) => _call(SessionMember.spendOutputsToSelf, selfSentTxWire, {
    'commitments': listOf(stringWire).encode(commitments),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
  });

  @override
  Future<void> setServers({required WalletConfig config}) => _call(
    SessionMember.setServers,
    voidWire,
    {'config': walletConfigWire.encode(config)},
  );

  @override
  Future<NodeTip> nodeTipFor({required WalletConfig config}) => _call(
    SessionMember.nodeTipFor,
    nodeTipWire,
    {'config': walletConfigWire.encode(config)},
  );

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
  Future<PaidRequestFile> payRequestFile({required String slateJson, required BigInt amount}) =>
      _call(SessionMember.payRequestFile, paidRequestFileWire, {
        'slateJson': slateJson,
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
}

/// The server session's [WalletSession.pairing], call for call.
class RemotePairing implements PairingApi {
  RemotePairing._(this._session);

  final RemoteWalletSession _session;

  Future<T> _call<T>(SessionMember member, WireCodec<T> result, [Map<String, Object?> params = const {}]) =>
      _session._call(member, result, params);

  @override
  bool get supported => true;

  // The server session words with its own Connection servers setting.
  @override
  void setConnectionServers(List<String>? hosts) {}

  @override
  Future<List<PairingRecord>> pairings() => _call(SessionMember.pairingList, listOf(pairingRecordWire));

  @override
  Future<PairingRecord?> pairing(String id) => _call(SessionMember.pairingGet, nullable(pairingRecordWire), {'id': id});

  @override
  Future<PairingRecord?> pairingForContact(String contactId) =>
      _call(SessionMember.pairingForContact, nullable(pairingRecordWire), {'contactId': contactId});

  @override
  Future<List<PairingStray>> strays() => _call(SessionMember.pairingStrays, listOf(pairingStrayWire));

  @override
  Future<void> removeStray(String id) => _call(SessionMember.pairingRemoveStray, voidWire, {'id': id});

  @override
  Future<PairingRecord> makeInvite({
    required String name,
    required Duration expiry,
    bool words = false,
    String? label,
    String? contactId,
  }) => _call(SessionMember.pairingMakeInvite, pairingRecordWire, {
    'name': name,
    'expirySecs': expiry.inSeconds,
    'words': words,
    'label': label,
    'contactId': contactId,
  });

  @override
  Future<void> cancelInvite(String id) => _call(SessionMember.pairingCancelInvite, voidWire, {'id': id});

  @override
  Future<PairingRecord> openReply(String link) => _call(SessionMember.pairingOpenReply, pairingRecordWire, {'link': link});

  @override
  Future<String> confirmLink(String id) => _call(SessionMember.pairingConfirmLink, stringWire, {'id': id});

  @override
  Future<PairingInvitePreview> openInvite(String link) =>
      _call(SessionMember.pairingOpenInvite, pairingPreviewWire, {'link': link});

  @override
  Future<PairingInvitePreview> openWords(List<String> words) =>
      _call(SessionMember.pairingOpenWords, pairingPreviewWire, {'words': words});

  @override
  Future<PairingRecord> acceptInvite({
    required String token,
    required String name,
    bool allowInvoices = false,
    String? contactId,
    bool byHand = false,
  }) => _call(SessionMember.pairingAccept, pairingRecordWire, {
    'token': token,
    'name': name,
    'allowInvoices': allowInvoices,
    'contactId': contactId,
    'byHand': byHand,
  });

  @override
  Future<String> replyLink(String id) => _call(SessionMember.pairingReplyLink, stringWire, {'id': id});

  @override
  Future<PairingRecord> openConfirm(String link) => _call(SessionMember.pairingOpenConfirm, pairingRecordWire, {'link': link});

  @override
  Future<PairingCard> showCard({required String name}) => _call(SessionMember.pairingShowCard, pairingCardWire, {'name': name});

  @override
  Future<PairingRecord> scanCard({required String cardId, required String text}) =>
      _call(SessionMember.pairingScanCard, pairingRecordWire, {'cardId': cardId, 'text': text});

  @override
  Future<PairingRecord?> checkWords(String id, PairingCheck check) => _call(
    SessionMember.pairingCheckWords,
    nullable(pairingRecordWire),
    {'id': id, 'check': pairingCheckWire.encode(check)},
  );

  @override
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground}) =>
      _call(SessionMember.pairingCollect, intWire, {'trigger': pairingCollectTriggerWire.encode(trigger)});

  @override
  Future<void> removePairing(String id) => _call(SessionMember.pairingRemove, voidWire, {'id': id});

  @override
  Future<PairingRecord> setSeal(String id, bool on) => _call(SessionMember.pairingSetSeal, pairingRecordWire, {'id': id, 'on': on});

  @override
  Future<int> setAllowInvoices(String id, bool on) => _call(SessionMember.pairingSetAllowInvoices, intWire, {'id': id, 'on': on});

  @override
  Future<PairingRecord> attach(String id, String? contactId) =>
      _call(SessionMember.pairingAttach, pairingRecordWire, {'id': id, 'contactId': contactId});

  @override
  Future<PairingRecord> resolveKeysChanged(String id, KeysChoice choice) => _call(
    SessionMember.pairingResolveKeys,
    pairingRecordWire,
    {'id': id, 'choice': keysChoiceWire.encode(choice)},
  );

  @override
  Future<IssuedInvoice> requestPayment({required String id, required BigInt amount, String? message}) => _call(
    SessionMember.pairingRequestPayment,
    issuedInvoiceWire,
    {'id': id, 'amount': bigIntWire.encode(amount), 'message': message},
  );

  @override
  Future<Slate> requestFile({required BigInt amount, String? message}) => _call(
    SessionMember.pairingRequestFile,
    slateWire,
    {'amount': bigIntWire.encode(amount), 'message': message},
  );

  @override
  Future<String> sealSlate({required String id, required String slateJson}) =>
      _call(SessionMember.pairingSealSlate, stringWire, {'id': id, 'slateJson': slateJson});

  @override
  Future<OpenedSlate> openSlate(String text) => _call(SessionMember.pairingOpenSlate, openedSlateWire, {'text': text});

  @override
  Future<SealedReply> receiveSealed(String text, {String? message}) =>
      _call(SessionMember.pairingReceiveSealed, sealedReplyWire, {'text': text, 'message': message});

  @override
  Future<TxEntry> finalizeSealed(String text) => _call(SessionMember.pairingFinalizeSealed, txEntryWire, {'text': text});

  @override
  Future<PaidSealedRequest> paySealedRequest(String text, {required BigInt amount}) =>
      _call(SessionMember.pairingPaySealedRequest, paidSealedRequestWire, {'text': text, 'amount': bigIntWire.encode(amount)});

  @override
  Future<TxEntry> sendViaMailbox({
    required String id,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _call(SessionMember.pairingSendViaMailbox, txEntryWire, {
    'id': id,
    'amount': bigIntWire.encode(amount),
    'minimumConfirmations': bigIntWire.encode(minimumConfirmations),
    'message': message,
    'options': optSendOptions.encode(options),
  });

  @override
  Future<String> plainSlate(String txKey) => _call(SessionMember.pairingPlainSlate, stringWire, {'key': txKey});

  @override
  Future<int> useImportedPairings() => _call(SessionMember.pairingUseImported, intWire);

  @override
  Future<PairingSlate?> slateOf(String slateId) =>
      _call(SessionMember.pairingSlateOf, nullable(pairingSlateWire), {'slateId': slateId});

  @override
  Stream<PairingEvent> events() => _session._stream(SessionMember.pairingEvents, pairingEventWire);

  // Linked devices run in the app that holds the wallet, not over the remote protocol.
  @override
  bool get privateSupported => false;

  @override
  Future<List<PairingRecord>> privatePairings() async => const [];

  @override
  Future<PairingRecord> makePrivateInvite({required String name, required String homeRelay, Duration expiry = privateInviteExpiry}) async =>
      throw pairingUnsupported('makePrivateInvite');

  @override
  Future<PairingRecord> acceptPrivateInvite({required String link, required String name}) async =>
      throw pairingUnsupported('acceptPrivateInvite');

  @override
  Future<int> collectPrivate({List<String>? only}) async => 0;

  @override
  Future<void> postPayload({required String id, required List<int> bytes}) async => throw pairingUnsupported('postPayload');

  @override
  Future<List<PairingPayload>> payloads() async => const [];

  @override
  Future<void> ackPayloads(List<String> ids) async {}
}
