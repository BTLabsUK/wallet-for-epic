// SPDX-License-Identifier: Apache-2.0
/// `ws_probe.dart` on the phone and desktop, over `dart:io`.
library;

import 'dart:async';
import 'dart:io';

import '../network_gate.dart';
import 'probe_not_run.dart';
import 'tor_net.dart';

/// Opens a WebSocket to [url] and closes it again; true when the handshake succeeded within
/// [timeout]. While Tor is on and not connected yet it waits for tor like every request
/// ([TorNet.untilConnected]); one still waiting throws [ProbeNotRun], not a false.
Future<bool> probeWebSocket(Uri url, {required Duration timeout}) async {
  if (!isLoopbackUrl(url)) {
    if (NetGate.offline) throw const ProbeNotRun();
    await TorNet.untilConnected();
    if (TorNet.mode == TorNetMode.waiting) throw const ProbeNotRun();
  }
  // No User-Agent: nothing that names the app or its version.
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null;
  try {
    // Through tor while the Tor switch covers the probes; none while it is not connected.
    TorNet.configure(client, loopback: isLoopbackUrl(url));
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
