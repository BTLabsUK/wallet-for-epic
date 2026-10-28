// SPDX-License-Identifier: Apache-2.0
// What integration_test/demo_e2e_test.dart needs to stand in for a browser: an HTTP side for
// ServerDemoApi that keeps the demo cookie, and the wallet socket with that cookie.

import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/server.dart' show demoCookie;
import 'package:epic_wallet/src/demo_server/ws_channel.dart';
import 'package:epic_wallet/src/demo_web.dart';
import 'package:epic_wallet/src/remote/client.dart';

/// One browser tab on the demo server's origin [base]: same-origin calls carry the cookie and
/// the `Origin` header, as a page there sends them.
class IoDemoHttp implements DemoHttp {
  IoDemoHttp(this.base);

  final Uri base;

  /// The demo id, as the server set it in its cookie.
  String? cookie;

  /// Faucet answers, for the claim's record.
  final List<DemoReply> faucetReplies = [];

  @override
  Future<DemoReply> api(String method, Uri url) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, url);
      request.headers.set('origin', base.origin);
      if (cookie case final id?) {
        request.headers.set(HttpHeaders.cookieHeader, '$demoCookie=$id');
      }
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      for (final c in response.cookies) {
        if (c.name == demoCookie) cookie = c.value.isEmpty ? null : c.value;
      }
      return DemoReply(response.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<DemoReply> simplePost(Uri url) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      final response = await request.close();
      final reply = DemoReply(
        response.statusCode,
        await utf8.decodeStream(response),
      );
      faucetReplies.add(reply);
      return reply;
    } finally {
      client.close(force: true);
    }
  }

  /// The wallet over `/api/ws`, reconnecting as the web app does.
  RemoteWalletService wallet() => RemoteWalletService.reconnecting(
    () => IoWebSocketChannel.connect(
      base.replace(scheme: 'ws', path: '/api/ws').toString(),
      headers: {
        'origin': base.origin,
        if (cookie case final id?) 'cookie': '$demoCookie=$id',
      },
    ),
    closingPushes: const {demoEndedPushName},
  );
}
