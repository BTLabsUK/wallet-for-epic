// SPDX-License-Identifier: Apache-2.0
// Shared set-up for the demo server tests: a server on a loopback port over a temp data root,
// and a small HTTP client that keeps the demo cookie.

import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/config.dart';
import 'package:epic_wallet/src/demo_server/demo_log.dart';
import 'package:epic_wallet/src/demo_server/server.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lines the server logged in this test.
final List<String> logged = [];

/// A started server and the fakes it made, one per demo.
class Harness {
  Harness._(this.root, this.server, this.services);

  final Directory root;
  final DemoServer server;

  /// The fake behind each demo, by demo id.
  final Map<String, FakeWalletService> services;

  String get base => 'http://127.0.0.1:${server.port}';
  String get origin => base;

  static Future<Harness> start({
    Directory? root,
    DemoServerConfig Function(String dataRoot)? config,
    FakeWalletService Function()? fake,
  }) async {
    serverLogSink = logged.add;
    final dir = root ?? await Directory.systemTemp.createTemp('wfe-demo-test-');
    final services = <String, FakeWalletService>{};
    final server = DemoServer(
      config:
          config?.call(dir.path) ??
          DemoServerConfig(dataRoot: dir.path, port: 0),
      serviceFor: (paths) =>
          services[paths.id] = fake?.call() ?? FakeWalletService(),
    );
    await server.start();
    final h = Harness._(dir, server, services);
    addTearDown(h.close);
    return h;
  }

  Future<void> close() async {
    await server.stop();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

class Reply {
  Reply(this.status, this.headers, this.body);

  final int status;
  final HttpHeaders headers;
  final String body;

  Map<String, Object?> get json => jsonDecode(body) as Map<String, Object?>;

  /// The raw `Set-Cookie` header for the demo cookie.
  String? get setCookie => headers[HttpHeaders.setCookieHeader]
      ?.where((c) => c.startsWith('$demoCookie='))
      .firstOrNull;
}

/// One browser: keeps the demo cookie between calls, like a page on the server's origin.
class Visitor {
  Visitor(this.h, {this.forwardedFor, String? origin})
    : origin = origin ?? h.origin;

  final Harness h;
  final String? forwardedFor;
  final String origin;
  String? cookie;

  Future<Reply> call(String method, String path) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(method, Uri.parse('${h.base}$path'));
      req.headers.set('origin', origin);
      if (forwardedFor != null) {
        req.headers.set('x-forwarded-for', forwardedFor!);
      }
      if (cookie != null) {
        req.headers.set(HttpHeaders.cookieHeader, '$demoCookie=$cookie');
      }
      final res = await req.close();
      final body = await utf8.decodeStream(res);
      final reply = Reply(res.statusCode, res.headers, body);
      final set = reply.setCookie;
      if (set != null) {
        final value = set.substring(demoCookie.length + 1).split(';').first;
        cookie = value.isEmpty ? null : value;
      }
      return reply;
    } finally {
      client.close(force: true);
    }
  }

  Future<Reply> start() => call('POST', '/api/demo');
  Future<Reply> status() => call('GET', '/api/demo');
  Future<Reply> end() => call('DELETE', '/api/demo');
}
