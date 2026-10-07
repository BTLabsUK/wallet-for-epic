@TestOn('browser')
library;

// W-06 in the browser: the web DemoApi's fetch side (the faucet claim goes without a
// preflight or a cookie) and the socket's `opened`, which the reconnecting client waits on.

import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/demo_web_platform.dart';
import 'package:epic_wallet/src/remote/web_channel.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loopback server in the VM. It answers CORS for any origin, records every request as
/// `METHOD path cookie=<yes|no> type=<content-type>`, serves the record at `/log`, and
/// upgrades `/ws` to a WebSocket.
const String _server = r'''
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel<Object?> channel) async {
  final log = <String>[];
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.uri.path == '/ws') {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen(socket.add);
      return;
    }
    final response = request.response;
    response.headers
      ..set('access-control-allow-origin', '*')
      ..set('access-control-allow-methods', 'GET, POST, DELETE');
    if (request.uri.path == '/log') {
      response.write(log.join('\n'));
      await response.close();
      return;
    }
    log.add('${request.method} ${request.uri.path} '
        'cookie=${request.headers.value('cookie') == null ? 'no' : 'yes'} '
        'type=${request.headers.contentType?.mimeType}');
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
    } else if (request.uri.path == '/faucet') {
      response.statusCode = 429;
      response.write('{"code":"cooldown","message":"Please wait 31s between requests."}');
    } else {
      response.write('{"state":"none"}');
    }
    await response.close();
  });
  channel.sink.add(server.port);
}
''';

void main() {
  late Uri base;

  setUpAll(() async {
    final port = (await spawnHybridCode(_server).stream.first as num).toInt();
    base = Uri.parse('http://127.0.0.1:$port');
  });

  Future<List<String>> log() async {
    final reply = await browserDemoHttp().api('GET', base.resolve('/log'));
    return const LineSplitter().convert(reply.body);
  }

  test('api calls answer status and body, for every method', () async {
    final http = browserDemoHttp();
    for (final method in ['GET', 'POST', 'DELETE']) {
      final reply = await http.api(method, base.resolve('/api/demo'));
      expect(reply.status, 200, reason: method);
      expect(reply.body, '{"state":"none"}');
    }
  });

  test('the faucet claim is a simple POST: no preflight, no cookie', () async {
    final reply = await browserDemoHttp().simplePost(
      base.resolve('/faucet?method=epicbox&destination=x'),
    );
    expect(reply.status, 429);
    expect(reply.body, contains('31s'));
    final lines = await log();
    final faucet = lines.where((l) => l.contains('/faucet')).toList();
    expect(faucet, hasLength(1), reason: 'no OPTIONS before it: $lines');
    expect(faucet.single, startsWith('POST /faucet cookie=no'));
  });

  test('no answer throws', () async {
    await expectLater(
      browserDemoHttp().api('GET', Uri.parse('http://127.0.0.1:9/api/demo')),
      throwsA(anything),
    );
  });

  test('connect waits until the socket is open', () async {
    final channel = await WebSocketChannel.connect(
      Uri.parse('ws://${base.authority}/ws'),
    );
    final frames = StreamIterator(channel.incoming);
    channel.send('ping');
    expect(await frames.moveNext(), isTrue);
    expect(frames.current, 'ping');
    await channel.close();
  });

  test('connect fails when the socket closes before it opens', () async {
    await expectLater(
      WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:9/api/ws'))
          .timeout(const Duration(seconds: 10)),
      throwsA(isA<WebSocketClosed>()),
    );
  });
}
