// SPDX-License-Identifier: Apache-2.0
/// A SOCKS5 client for the wallet's own tor (RFC 1928, username/password of RFC 1929), so the
/// app's HTTP can go through it while the Tor switch is on. Names always go to tor as names
/// (address type 3): this computer never looks one up. `dart:io` only.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Where tor's SOCKS port listens: an IP literal on this computer, so connecting to it needs
/// no lookup either.
class SocksProxy {
  const SocksProxy(this.host, this.port);

  final String host;
  final int port;

  @override
  bool operator ==(Object other) => other is SocksProxy && host == other.host && port == other.port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => 'SocksProxy($host:$port)';
}

/// Why tor did not open the connection. An [IOException], as a refused socket is.
class SocksError implements IOException {
  const SocksError(this.message, {this.reply});

  /// A BT Labs host without an onion, which tor does not reach (by design).
  static const noBtLabsOnion = 'no onion for this BT Labs server';

  final String message;

  /// The SOCKS reply code, when tor answered with one.
  final int? reply;

  @override
  String toString() => 'SocksError: $message';
}

/// Fresh credentials for every connection: tor isolates circuits by them
/// (IsolateSOCKSAuth), so two requests never share an exit by accident.
String _randomCredential() {
  final r = Random.secure();
  return List.generate(12, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

String _replyText(int code) => switch (code) {
  1 => 'general failure',
  2 => 'not allowed',
  3 => 'network unreachable',
  4 => 'host unreachable',
  5 => 'connection refused',
  6 => 'TTL expired',
  7 => 'command not supported',
  8 => 'address type not supported',
  _ => 'reply $code',
};

/// Opens a connection to [host]:[port] through [proxy]. [host] goes to tor as a name, never
/// looked up here. The socket is plain; [socksConnectTls] for TLS.
Future<Socket> socksConnect(
  SocksProxy proxy,
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 60),
}) async => (await _handshake(proxy, host, port, timeout)).hand();

/// [socksConnect], then TLS checked for [tlsHost] (the URL's own host; for an onion of a
/// BT Labs server, that server's name).
Future<SecureSocket> socksConnectTls(
  SocksProxy proxy,
  String host,
  int port, {
  required String tlsHost,
  Duration timeout = const Duration(seconds: 60),
  SecurityContext? context,
}) async {
  final reader = await _handshake(proxy, host, port, timeout);
  try {
    // TLS takes the connection under the stream over; the handshake's reading ends with it.
    final secure = await SecureSocket.secure(reader.socket, host: tlsHost, context: context).timeout(timeout);
    unawaited(reader.release());
    return secure;
  } catch (_) {
    reader.socket.destroy();
    rethrow;
  }
}

Future<_Reader> _handshake(SocksProxy proxy, String host, int port, Duration timeout) async {
  final name = utf8.encode(host);
  if (name.isEmpty || name.length > 255) throw const SocksError('bad host name');
  if (port < 1 || port > 65535) throw const SocksError('bad port');
  final socket = await Socket.connect(proxy.host, proxy.port, timeout: timeout);
  final reader = _Reader(socket);
  try {
    await () async {
      // Greeting: version 5, one method, username/password.
      socket.add([5, 1, 2]);
      final choice = await reader.take(2);
      if (choice[0] != 5 || choice[1] != 2) throw const SocksError('proxy refused username/password');
      final user = utf8.encode(_randomCredential());
      final pass = utf8.encode(_randomCredential());
      socket.add([1, user.length, ...user, pass.length, ...pass]);
      final auth = await reader.take(2);
      if (auth[1] != 0) throw const SocksError('proxy refused the credentials');
      // CONNECT to a domain name (type 3).
      socket.add([5, 1, 0, 3, name.length, ...name, port >> 8, port & 0xff]);
      final head = await reader.take(4);
      if (head[0] != 5) throw const SocksError('not a SOCKS5 proxy');
      if (head[1] != 0) throw SocksError(_replyText(head[1]), reply: head[1]);
      final rest = switch (head[3]) {
        1 => 4,
        4 => 16,
        3 => (await reader.take(1))[0],
        _ => throw const SocksError('bad reply'),
      };
      await reader.take(rest + 2);
    }().timeout(timeout);
  } catch (_) {
    socket.destroy();
    rethrow;
  }
  return reader;
}

/// Reads the handshake from [socket]'s stream, then hands the stream on: a [Socket] whose
/// data is whatever follows. The socket itself stays usable by [SecureSocket.secure], which
/// takes the connection under the stream over.
class _Reader {
  _Reader(this.socket) {
    _sub = socket.listen(
      (data) {
        _chunks.add(data);
        _have += data.length;
        _feed();
      },
      onError: (Object e, StackTrace s) => _fail(e),
      onDone: () => _fail(const SocksError('proxy closed the connection')),
    );
  }

  final Socket socket;
  late final StreamSubscription<Uint8List> _sub;
  final _chunks = Queue<Uint8List>();
  int _have = 0;
  int _want = 0;
  Completer<Uint8List>? _waiter;
  Object? _error;

  Future<Uint8List> take(int n) {
    if (_error != null) return Future.error(_error!);
    _want = n;
    final c = _waiter = Completer<Uint8List>();
    _feed();
    return c.future;
  }

  void _feed() {
    final c = _waiter;
    if (c == null || _have < _want) return;
    final out = BytesBuilder(copy: false);
    var need = _want;
    while (need > 0) {
      final head = _chunks.removeFirst();
      if (head.length <= need) {
        out.add(head);
        need -= head.length;
      } else {
        out.add(Uint8List.sublistView(head, 0, need));
        _chunks.addFirst(Uint8List.sublistView(head, need));
        need = 0;
      }
    }
    _have -= _want;
    _waiter = null;
    c.complete(out.takeBytes());
  }

  void _fail(Object e) {
    _error ??= e;
    final c = _waiter;
    _waiter = null;
    if (c != null && !c.isCompleted) c.completeError(e);
  }

  /// The connected socket, its stream carrying what comes after the handshake.
  Socket hand() => _HandedSocket(socket, _sub, List.of(_chunks));

  /// Stops reading, once TLS has the connection.
  Future<void> release() => _sub.cancel();
}

/// [socket] with its stream taken over from the handshake's subscription.
class _HandedSocket extends StreamView<Uint8List> implements Socket {
  _HandedSocket(Socket socket, StreamSubscription<Uint8List> sub, List<Uint8List> buffered)
    : this._(socket, _pipe(sub, buffered));

  _HandedSocket._(this._socket, Stream<Uint8List> stream) : super(stream);

  final Socket _socket;

  static Stream<Uint8List> _pipe(StreamSubscription<Uint8List> sub, List<Uint8List> buffered) {
    late final StreamController<Uint8List> c;
    c = StreamController<Uint8List>(
      sync: true,
      onListen: () {
        for (final b in buffered) {
          c.add(b);
        }
        sub
          ..onData(c.add)
          ..onError(c.addError)
          ..onDone(c.close)
          ..resume();
      },
      onPause: sub.pause,
      onResume: sub.resume,
      onCancel: sub.cancel,
    );
    sub.pause();
    return c.stream;
  }

  @override
  Encoding get encoding => _socket.encoding;

  @override
  set encoding(Encoding value) => _socket.encoding = value;

  @override
  void add(List<int> data) => _socket.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _socket.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) => _socket.addStream(stream);

  @override
  Future close() => _socket.close();

  @override
  Future get done => _socket.done;

  @override
  Future flush() => _socket.flush();

  @override
  void write(Object? object) => _socket.write(object);

  @override
  void writeAll(Iterable objects, [String separator = '']) => _socket.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _socket.writeln(object);

  @override
  InternetAddress get address => _socket.address;

  @override
  int get port => _socket.port;

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  int get remotePort => _socket.remotePort;

  @override
  void destroy() => _socket.destroy();

  @override
  bool setOption(SocketOption option, bool enabled) => _socket.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) => _socket.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
}

/// Where a host is reached over Tor instead of its own address: BT Labs' onions from the signed
/// list. [tls] false is plain HTTP on the onion (the onion itself is the encryption).
typedef OnionTarget = ({String onion, int port, bool tls});

/// The onion for [host]:[port], or null to go through an exit to the host itself.
typedef OnionLookup = OnionTarget? Function(String host, int port);

/// An [HttpClient.connectionFactory] that opens every connection through [proxy]: to the
/// host's onion when [onions] knows one, otherwise to the host through an exit. https gets
/// TLS checked for the URL's own host. Plain http through an exit is refused: nothing leaves
/// Tor unencrypted except to an onion.
///
/// An https or wss URL never loses its certificate check to a list: a plain onion
/// ([OnionTarget.tls] false) carries it only when [pinnedPlain], the app's own built-in table,
/// names that same onion for the host. Any other plain onion for such a URL fails the request;
/// it does not fall back to an exit, which BT Labs' hosts are never reached through.
Future<ConnectionTask<Socket>> Function(Uri, String?, int?) socksConnectionFactory(
  SocksProxy proxy, {
  OnionLookup? onions,
  OnionLookup? pinnedPlain,
  Duration timeout = const Duration(seconds: 60),
  bool allowPlainExit = false,
  SecurityContext? context,
}) {
  return (Uri url, String? proxyHost, int? proxyPort) async {
    final secure = url.scheme == 'https' || url.scheme == 'wss';
    final port = url.hasPort ? url.port : (secure ? 443 : 80);
    final target = onions?.call(url.host, port);
    Future<Socket> open() async {
      if (target != null) {
        if (secure && !target.tls && pinnedPlain?.call(url.host, port) != target) {
          throw const SocksError('no TLS onion for an https request');
        }
        return target.tls
            ? socksConnectTls(proxy, target.onion, target.port, tlsHost: url.host, timeout: timeout, context: context)
            : socksConnect(proxy, target.onion, target.port, timeout: timeout);
      }
      final h = url.host.toLowerCase();
      if (h == 'btlabs.uk' || h.endsWith('.btlabs.uk')) {
        // Tor exits cannot reach BT Labs' own address: its servers only at their onions.
        throw const SocksError(SocksError.noBtLabsOnion);
      }
      if (!secure && !allowPlainExit) {
        throw const SocksError('plain http through a Tor exit is not allowed');
      }
      return secure
          ? socksConnectTls(proxy, url.host, port, tlsHost: url.host, timeout: timeout, context: context)
          : socksConnect(proxy, url.host, port, timeout: timeout);
    }

    final socket = open();
    // The client takes the error from the task; this keeps it from also counting as unhandled
    // when it comes before the client listens.
    socket.ignore();
    return ConnectionTask.fromSocket(socket, () {});
  };
}
