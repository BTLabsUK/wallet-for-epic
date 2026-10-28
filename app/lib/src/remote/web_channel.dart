// SPDX-License-Identifier: Apache-2.0
/// [RpcChannel] over a browser WebSocket, through `dart:js_interop` alone, so `remote/` keeps
/// to its import rule.
library;

import 'dart:async';
import 'dart:js_interop';

import 'channel.dart';

/// `<origin>/api/ws` of the page at [page]: `wss:` under `https:`, `ws:` under `http:`.
Uri demoSocketUrl(Uri page) => Uri(
  scheme: page.scheme == 'https' ? 'wss' : 'ws',
  host: page.host,
  port: page.hasPort ? page.port : null,
  path: '/api/ws',
);

/// One WebSocket to [url]. The socket opens when [openAfter] completes (the app passes the end
/// of its first frame, so nothing touches the network before the first screen shows), and
/// frames sent before it is open wait for it. A socket that fails or closes ends [incoming];
/// the client then fails its calls as a lost connection. Binary frames are ignored: the
/// protocol is text.
class WebSocketChannel implements RpcChannel {
  WebSocketChannel(this.url, {Future<void>? openAfter}) {
    // Nobody has to wait for [opened]; a failed open is then not an uncaught error.
    _opened.future.ignore();
    if (openAfter == null) {
      _open();
    } else {
      openAfter.then((_) => _open(), onError: (Object _) => _open());
    }
  }

  final Uri url;
  final StreamController<String> _in = StreamController<String>();
  final List<String> _waiting = [];
  final Completer<void> _opened = Completer<void>();
  _WebSocket? _socket;
  bool _connected = false;
  bool _ended = false;

  @override
  Stream<String> get incoming => _in.stream;

  /// Completes once the socket is open, or fails with [WebSocketClosed] when it closed before
  /// that, so a reconnecting client can tell a failed connect from a dropped connection.
  Future<void> get opened => _opened.future;

  /// Opens a channel to [url] and waits until it is open; for
  /// `RemoteWalletService.reconnecting`.
  static Future<WebSocketChannel> connect(
    Uri url, {
    Future<void>? openAfter,
  }) async {
    final channel = WebSocketChannel(url, openAfter: openAfter);
    await channel.opened;
    return channel;
  }

  void _open() {
    if (_ended) return;
    final socket = _WebSocket(url.toString());
    _socket = socket;
    socket.onopen = ((JSAny _) {
      _connected = true;
      if (!_opened.isCompleted) _opened.complete();
      for (final frame in _waiting) {
        socket.send(frame);
      }
      _waiting.clear();
    }).toJS;
    socket.onmessage = ((_MessageEvent event) {
      final data = event.data;
      if (!_in.isClosed && data.isA<JSString>()) {
        _in.add((data as JSString).toDart);
      }
    }).toJS;
    // An error is always followed by close; close is where the channel ends.
    socket.onclose = ((JSAny _) => _end()).toJS;
  }

  @override
  void send(String frame) {
    if (_ended) return;
    if (_connected) {
      _socket!.send(frame);
    } else {
      _waiting.add(frame);
    }
  }

  @override
  Future<void> close() async {
    final socket = _socket;
    _end();
    socket?.close(1000);
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _connected = false;
    if (!_opened.isCompleted) _opened.completeError(const WebSocketClosed());
    _waiting.clear();
    if (!_in.isClosed) unawaited(_in.close());
  }
}

/// The socket closed before it opened.
class WebSocketClosed implements Exception {
  const WebSocketClosed();

  @override
  String toString() => 'WebSocketClosed';
}

@JS('WebSocket')
extension type _WebSocket._(JSObject _) implements JSObject {
  external _WebSocket(String url);
  external void send(String data);
  external void close(int code);
  external set onopen(JSFunction handler);
  external set onmessage(JSFunction handler);
  external set onclose(JSFunction handler);
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}
