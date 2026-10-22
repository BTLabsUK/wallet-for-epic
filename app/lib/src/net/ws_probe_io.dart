/// `ws_probe.dart` on the phone and desktop, over `dart:io`.
library;

import 'dart:async';
import 'dart:io';

/// Opens a WebSocket to [url] and closes it again; true when the handshake succeeded within
/// [timeout].
Future<bool> probeWebSocket(Uri url, {required Duration timeout}) async {
  // No User-Agent: nothing that names the app or its version (F35).
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null;
  try {
    final socket = await WebSocket.connect(
      url.toString(),
      customClient: client,
    ).timeout(timeout);
    unawaited(socket.close(WebSocketStatus.normalClosure));
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
