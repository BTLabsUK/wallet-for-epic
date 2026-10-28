// SPDX-License-Identifier: Apache-2.0
/// `demo_web_platform.dart` in the browser, with `package:web` only.
library;

import 'dart:js_interop';

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:web/web.dart' as web;

import 'demo.dart';
import 'demo_web.dart';
import 'providers.dart';
import 'remote/client.dart';
import 'remote/web_channel.dart';
import 'web/preview.dart';

/// The web demo on its server: the wallet over a reconnecting socket to `<origin>/api/ws`
/// and the server's [DemoApi]. Nothing for a `WFE_WEB_FAKE` build, which keeps the preview
/// wallet and [FakeDemoApi], or outside demo mode.
List<Override> webDemoOverrides() {
  if (webFakeBackend) return previewOverrides();
  if (!demoBuild) return const [];
  final page = Uri.base;
  var first = true;
  final wallet = RemoteWalletService.reconnecting(() {
    // The first socket waits for the end of a frame, so nothing touches the network
    // before the first screen shows.
    final openAfter = first ? WidgetsBinding.instance.endOfFrame : null;
    first = false;
    return WebSocketChannel.connect(demoSocketUrl(page), openAfter: openAfter);
  }, closingPushes: const {demoEndedPushName});
  final api = ServerDemoApi(
    http: browserDemoHttp(),
    origin: page,
    ended: wallet.pushes
        .where((push) => push.name == demoEndedPushName)
        .map((_) {}),
  );
  return [
    walletServiceProvider.overrideWithValue(wallet),
    demoApiProvider.overrideWithValue(api),
  ];
}

DemoHttp browserDemoHttp() => const _FetchDemoHttp();

class _FetchDemoHttp implements DemoHttp {
  const _FetchDemoHttp();

  /// The demo cookie goes with same-origin requests only, which `same-origin` names.
  @override
  Future<DemoReply> api(String method, Uri url) => _fetch(
    url,
    web.RequestInit(
      method: method,
      credentials: 'same-origin',
      cache: 'no-store',
    ),
  );

  /// No body, no header and no cookie: a CORS simple request, so no preflight.
  @override
  Future<DemoReply> simplePost(Uri url) => _fetch(
    url,
    web.RequestInit(method: 'POST', credentials: 'omit', mode: 'cors'),
  );

  Future<DemoReply> _fetch(Uri url, web.RequestInit init) async {
    final response = await web.window.fetch(url.toString().toJS, init).toDart;
    final text = await response.text().toDart;
    return DemoReply(response.status, text.toDart);
  }
}
