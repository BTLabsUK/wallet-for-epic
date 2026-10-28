// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/net/ws_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a server that takes the handshake answers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      await socket.close();
    });
    expect(
      await probeWebSocket(
        Uri.parse('ws://127.0.0.1:${server.port}'),
        timeout: const Duration(seconds: 2),
      ),
      isTrue,
    );
  });

  test('a plain web server or a closed port does not', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response.statusCode = 404;
      request.response.close();
    });
    expect(
      await probeWebSocket(
        Uri.parse('ws://127.0.0.1:${server.port}'),
        timeout: const Duration(seconds: 2),
      ),
      isFalse,
    );
    final port = server.port;
    await server.close(force: true);
    expect(
      await probeWebSocket(
        Uri.parse('ws://127.0.0.1:$port'),
        timeout: const Duration(seconds: 2),
      ),
      isFalse,
    );
  });

  test('a server that never answers is given up on at the timeout', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final held = <Socket>[];
    server.listen(held.add);
    final watch = Stopwatch()..start();
    expect(
      await probeWebSocket(
        Uri.parse('ws://127.0.0.1:${server.port}'),
        timeout: const Duration(milliseconds: 300),
      ),
      isFalse,
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    for (final socket in held) {
      socket.destroy();
    }
    await server.close();
  });
}
