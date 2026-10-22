import 'dart:io';

import 'package:epic_wallet/src/net/http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  var size = 0;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..add(List<int>.filled(size, 0x20))
        ..close();
    });
  });

  tearDown(() => server.close(force: true));

  Uri url() => Uri.parse('http://127.0.0.1:${server.port}/f');

  test('httpGet reads a body of exactly maxBytes', () async {
    size = 65536;
    final reply = await httpGet(url(), maxBytes: 65536);
    expect(reply.body.length, 65536);
  });

  test('httpGet stops one byte past maxBytes', () async {
    size = 65537;
    await expectLater(httpGet(url(), maxBytes: 65536), throwsA(isA<NetTooLarge>()));
  });

  test('without maxBytes the whole body is read', () async {
    size = 200000;
    expect((await httpGet(url())).body.length, 200000);
  });
}
