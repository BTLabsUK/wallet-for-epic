// SPDX-License-Identifier: Apache-2.0
@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/net/http.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loopback server in the VM, reached from the browser over CORS. `/nocors` answers without
/// the CORS header, which the browser turns into a failed fetch.
const String _server = r'''
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel<Object?> channel) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response;
    if (request.uri.path != '/nocors') {
      response.headers
        ..set('access-control-allow-origin', '*')
        ..set('access-control-allow-headers', 'content-type, x-test')
        ..set('access-control-allow-methods', 'GET, POST');
    }
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      await response.close();
      return;
    }
    switch (request.uri.path) {
      case '/ok':
        response.write('hello ${request.headers.value('x-test')} é');
      case '/status':
        response.statusCode = 503;
        response.write('busy');
      case '/slow':
        await Future<void>.delayed(const Duration(seconds: 3));
      case '/echo':
        final body = await utf8.decodeStream(request);
        response.write('${request.headers.value('content-type')}|$body');
      case '/nocors':
        response.write('hidden');
    }
    await response.close();
  });
  channel.sink.add(server.port);
}
''';

void main() {
  late Uri base;

  setUpAll(() async {
    final channel = spawnHybridCode(_server);
    // A number, not an int, under dart2wasm.
    final port = (await channel.stream.first as num).toInt();
    base = Uri.parse('http://127.0.0.1:$port');
  });

  test('GET returns status, headers reach the server, UTF-8 body', () async {
    final reply = await httpGet(base.resolve('/ok'), headers: {'x-test': 'hi'});
    expect(reply.status, 200);
    expect(reply.body, 'hello hi é');
  });

  test('an error status is an answer, not an exception', () async {
    final reply = await httpGet(base.resolve('/status'));
    expect(reply.status, 503);
    expect(reply.ok, isFalse);
  });

  test('POST sends the body and content type', () async {
    final reply = await httpPost(
      base.resolve('/echo'),
      body: utf8.encode('Café report\n'),
      contentType: 'text/plain; charset=utf-8',
    );
    expect(reply.status, 200);
    expect(reply.body, 'text/plain; charset=utf-8|Café report\n');
  });

  test('a call past its timeout throws TimeoutException', () async {
    await expectLater(
      httpGet(
        base.resolve('/slow'),
        timeout: const Duration(milliseconds: 300),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a refused CORS check throws NetError', () async {
    await expectLater(
      httpGet(base.resolve('/nocors')),
      throwsA(isA<NetError>()),
    );
  });

  test('an unreachable server throws NetError', () async {
    await expectLater(
      httpGet(Uri.parse('http://127.0.0.1:9/')),
      throwsA(isA<NetError>()),
    );
  });
}
