import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/net/http.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealHttp extends HttpOverrides {}

/// The io side of `net/http.dart` against a loopback server. The web side has the same cases
/// in `test/web/http_web_test.dart`.
void main() {
  late HttpServer server;
  late Uri base;
  final posted = <({String? type, int length, String body})>[];

  setUp(() async {
    HttpOverrides.global = _RealHttp();
    posted.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) async {
      final response = request.response;
      switch (request.uri.path) {
        case '/ok':
          response.write('hello ${request.headers.value('accept')} é');
        case '/status':
          response.statusCode = 503;
          response.write('busy');
        case '/slow':
          await Future<void>.delayed(const Duration(seconds: 2));
        case '/echo':
          posted.add((
            type: request.headers.value(HttpHeaders.contentTypeHeader),
            length: request.headers.contentLength,
            body: await utf8.decodeStream(request),
          ));
          response.statusCode = 204;
      }
      await response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    HttpOverrides.global = null;
  });

  test('GET returns status and UTF-8 body', () async {
    final reply = await httpGet(
      base.resolve('/ok'),
      headers: {'accept': 'application/json'},
    );
    expect(reply.status, 200);
    expect(reply.ok, isTrue);
    expect(reply.body, 'hello application/json é');
  });

  test('an error status is an answer, not an exception', () async {
    final reply = await httpGet(base.resolve('/status'));
    expect(reply.status, 503);
    expect(reply.ok, isFalse);
    expect(reply.body, 'busy');
  });

  test('POST sends a declared length and the content type', () async {
    final reply = await httpPost(
      base.resolve('/echo'),
      body: utf8.encode('Café report\n'),
      contentType: 'text/plain; charset=utf-8',
    );
    expect(reply.status, 204);
    expect(posted.single.type, 'text/plain; charset=utf-8');
    expect(posted.single.length, utf8.encode('Café report\n').length);
    expect(posted.single.body, 'Café report\n');
  });

  test('a call past its timeout throws TimeoutException', () async {
    await expectLater(
      httpGet(
        base.resolve('/slow'),
        timeout: const Duration(milliseconds: 200),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('an unreachable server throws NetError', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    await expectLater(
      httpGet(Uri.parse('http://127.0.0.1:$port/')),
      throwsA(isA<NetError>()),
    );
  });
}
