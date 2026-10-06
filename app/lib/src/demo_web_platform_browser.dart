/// `demo_web_platform.dart` in the browser, with `package:web` only.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'demo_web.dart';

DemoHttp browserDemoHttp() => const _FetchDemoHttp();

/// Opens [uri] in a new tab, with no way back to this page (`noopener`).
Future<void> openInNewTab(Uri uri) async {
  web.window.open(uri.toString(), '_blank', 'noopener,noreferrer');
}

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
