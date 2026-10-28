// SPDX-License-Identifier: Apache-2.0
/// [RpcChannel] over a `dart:io` [WebSocket]: the server's side of `/api/ws`, and a client
/// for tests and the VM end-to-end run.
library;

import 'dart:async';
import 'dart:io';

import '../remote/channel.dart';

/// Text frames only. A binary frame closes the socket with 1003 (unsupported data).
class IoWebSocketChannel implements RpcChannel {
  IoWebSocketChannel(this._socket) {
    _socket.listen(
      (data) {
        if (data is String) {
          _in.add(data);
        } else {
          unawaited(close(WebSocketStatus.unsupportedData));
        }
      },
      onDone: () {
        if (!_in.isClosed) unawaited(_in.close());
      },
      onError: (Object _) {
        if (!_in.isClosed) unawaited(_in.close());
      },
      cancelOnError: true,
    );
  }

  /// Connects to [url] with [headers], such as `Origin` and `Cookie`.
  static Future<IoWebSocketChannel> connect(
    String url, {
    Map<String, Object> headers = const {},
  }) async =>
      IoWebSocketChannel(await WebSocket.connect(url, headers: headers));

  final WebSocket _socket;
  final StreamController<String> _in = StreamController<String>();

  @override
  Stream<String> get incoming => _in.stream;

  @override
  void send(String frame) {
    if (_in.isClosed || _socket.closeCode != null) return;
    _socket.add(frame);
  }

  @override
  Future<void> close([int code = WebSocketStatus.normalClosure]) async {
    if (!_in.isClosed) unawaited(_in.close());
    await _socket.close(code);
  }
}
