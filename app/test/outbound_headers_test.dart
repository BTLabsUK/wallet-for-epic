// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/ws_probe.dart';

/// What leaves the device: no User-Agent, language, cookie or referrer on any request.
void main() {
  const banned = ['user-agent', 'accept-language', 'cookie', 'referer', 'origin'];

  late HttpServer server;
  late List<Map<String, String>> seen;

  setUp(() async {
    seen = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final names = <String, String>{};
      request.headers.forEach((n, v) => names[n] = v.join(','));
      seen.add(names);
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        await socket.close();
        return;
      }
      await request.drain<void>();
      request.response.write('ok');
      await request.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  void expectBare(Map<String, String> headers) {
    for (final name in banned) {
      expect(headers.containsKey(name), isFalse, reason: '$name was sent: $headers');
    }
  }

  test('httpGet sends no identifying headers', () async {
    await httpGet(Uri.parse('http://127.0.0.1:${server.port}/x'));
    expect(seen, hasLength(1));
    expectBare(seen.single);
  });

  test('httpPost sends no identifying headers', () async {
    await httpPost(
      Uri.parse('http://127.0.0.1:${server.port}/x'),
      body: [1, 2, 3],
      contentType: 'application/json',
    );
    expect(seen, hasLength(1));
    expectBare(seen.single);
  });

  test('probeWebSocket sends no identifying headers', () async {
    final ok = await probeWebSocket(
      Uri.parse('ws://127.0.0.1:${server.port}/'),
      timeout: const Duration(seconds: 5),
    );
    expect(ok, isTrue);
    expect(seen, hasLength(1));
    expectBare(seen.single);
  });
}
