// SPDX-License-Identifier: Apache-2.0
@TestOn('browser')
library;

import 'dart:async';

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/remote/web_channel.dart';
import 'package:epic_wallet/src/secret_store_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loopback WebSocket server in the VM: echoes every text frame, and closes when it gets
/// `bye`.
const String _server = r'''
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel<Object?> channel) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen((frame) {
      if (frame == 'bye') {
        socket.close();
      } else {
        socket.add('echo $frame ${request.uri.path}');
      }
    });
  });
  channel.sink.add(server.port);
}
''';

void main() {
  group('store', () {
    test(
      'values round-trip through localStorage under the wfe. prefix',
      () async {
        const store = BrowserSecretStore();
        await store.delete('w03.key');
        expect(await store.read('w03.key'), isNull);
        await store.write('w03.key', 'sealed é');
        expect(await store.read('w03.key'), 'sealed é');
        // A second instance reads the same origin storage, as after a reload.
        expect(await const BrowserSecretStore().read('w03.key'), 'sealed é');
        await store.delete('w03.key');
        expect(await store.read('w03.key'), isNull);
      },
    );
  });

  group('log', () {
    test('the web log keeps lines in memory, redacted', () async {
      await startLogging();
      logInfo('w03', 'web log line');
      final tail = await AppLog.sink.tail(4096);
      expect(AppLog.sink, isA<MemoryLogSink>());
      expect(tail, contains('dart.w03: web log line'));
    });
  });

  group('socket', () {
    late int port;

    setUpAll(() async {
      port = (await spawnHybridCode(_server).stream.first as num).toInt();
    });

    test('demoSocketUrl is the origin\'s /api/ws, wss under https', () {
      expect(
        demoSocketUrl(Uri.parse('https://try.example.com/app/#/x')).toString(),
        'wss://try.example.com/api/ws',
      );
      expect(
        demoSocketUrl(Uri.parse('http://127.0.0.1:8790/app/')).toString(),
        'ws://127.0.0.1:8790/api/ws',
      );
    });

    test('frames sent before the socket opens go once it does', () async {
      final open = Completer<void>();
      final channel = WebSocketChannel(
        Uri.parse('ws://127.0.0.1:$port/api/ws'),
        openAfter: open.future,
      );
      final frames = StreamIterator(channel.incoming);
      channel.send('one');
      channel.send('two');
      open.complete();
      expect(await frames.moveNext(), isTrue);
      expect(frames.current, 'echo one /api/ws');
      expect(await frames.moveNext(), isTrue);
      expect(frames.current, 'echo two /api/ws');
      await channel.close();
      expect(await frames.moveNext(), isFalse);
    });

    test(
      'a close from the server ends incoming, and later sends are dropped',
      () async {
        final channel = WebSocketChannel(Uri.parse('ws://127.0.0.1:$port/'));
        final done = channel.incoming.toList();
        channel.send('bye');
        expect(await done.timeout(const Duration(seconds: 10)), isEmpty);
        channel.send('after');
      },
    );

    test('a socket that cannot connect ends incoming', () async {
      final channel = WebSocketChannel(Uri.parse('ws://127.0.0.1:9/api/ws'));
      channel.send('lost');
      expect(
        await channel.incoming.toList().timeout(const Duration(seconds: 10)),
        isEmpty,
      );
    });
  });
}
