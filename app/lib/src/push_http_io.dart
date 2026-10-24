/// The push registration's HTTP on the phone and desktop: `dart:io`, always direct.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'advanced.dart' show NetworkMode;
import 'network_gate.dart';

/// POSTs [body] as JSON and returns the status. Never through [TorNet]: a push request must
/// not leave over Tor, and the caller does not send one while Tor is on. Throws on any
/// failure to get an answer, and [TimeoutException] after [timeout].
Future<int> directPost(Uri url, String body, Duration timeout) async {
  // Offline: nothing leaves (network_gate.dart). Tor only lets the unregister made as the
  // switch turns on go, as the Tor switch itself does; it never registers.
  if (NetGate.offline) throw const NetBlocked(NetworkMode.offline, 'push');
  final bytes = utf8.encode(body);
  // No User-Agent and no proxy: the relay sees an ordinary client at this phone's address.
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null
    ..findProxy = ((_) => 'DIRECT');
  try {
    return await () async {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    }().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}
