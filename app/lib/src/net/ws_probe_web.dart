// SPDX-License-Identifier: Apache-2.0
/// `ws_probe.dart` in the browser, with `dart:js_interop` only.
library;

import 'dart:async';
import 'dart:js_interop';

import '../network_gate.dart' show NetDial, NetGate;
import 'probe_not_run.dart';

/// Opens a WebSocket to [url] and closes it again; true when it opened within [timeout].
Future<bool> probeWebSocket(Uri url, {required Duration timeout}) {
  // The network mode refuses it (Node only, Kill switch): not run, not a false.
  if (!NetGate.allows(NetDial.webSocket, url.host)) throw const ProbeNotRun();
  final done = Completer<bool>();
  final _Socket socket;
  try {
    socket = _Socket(url.toString());
  } catch (_) {
    // A malformed URL or one the page's policy refuses.
    return Future.value(false);
  }
  void finish(bool open) {
    if (done.isCompleted) return;
    done.complete(open);
    try {
      socket.close(1000);
    } catch (_) {
      // Already closed.
    }
  }

  final timer = Timer(timeout, () => finish(false));
  socket.onopen = ((JSAny _) => finish(true)).toJS;
  // An error is always followed by close.
  socket.onclose = ((JSAny _) => finish(false)).toJS;
  return done.future.whenComplete(timer.cancel);
}

@JS('WebSocket')
extension type _Socket._(JSObject _) implements JSObject {
  external _Socket(String url);
  external void close(int code);
  external set onopen(JSFunction handler);
  external set onclose(JSFunction handler);
}
