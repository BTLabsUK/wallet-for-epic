// SPDX-License-Identifier: Apache-2.0
/// `http.dart` in the browser, over `fetch`, with `dart:js_interop` only.
///
/// Cross-origin calls need the server's CORS answer; a refused check reads as [NetError], the
/// same as being offline, because the browser does not say which it was.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import '../network_gate.dart';
import 'http_types.dart';

/// With [maxBytes], a longer body throws [NetTooLarge] (checked once read: `fetch` gives no
/// cheap byte stream here). With [followRedirects] false a redirect is not followed and reads as
/// status 0, the browser's opaque redirect.
Future<HttpReply> httpGet(
  Uri url, {
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
  int? maxBytes,
  bool followRedirects = true,
}) async {
  final reply = await _send('GET', url, headers, null, timeout, followRedirects: followRedirects);
  if (maxBytes != null && utf8.encode(reply.body).length > maxBytes) {
    throw NetTooLarge(maxBytes);
  }
  return reply;
}

/// [httpGet] for a binary body (an icon).
Future<HttpBytes> httpGetBytes(
  Uri url, {
  Duration timeout = defaultHttpTimeout,
  required int maxBytes,
  bool followRedirects = true,
}) async {
  final abort = _AbortController();
  var timedOut = false;
  final timer = Timer(timeout, () {
    timedOut = true;
    abort.abort();
  });
  try {
    final init = _RequestInit(
      method: 'GET',
      headers: const <String, String>{}.jsify()! as JSObject,
      signal: abort.signal,
      redirect: followRedirects ? 'follow' : 'manual',
    );
    final response = await _fetch(url.toString(), init).toDart;
    final bytes = (await response.arrayBuffer().toDart).toDart.asUint8List();
    if (bytes.length > maxBytes) throw NetTooLarge(maxBytes);
    return HttpBytes(response.status, bytes);
  } on NetTooLarge {
    rethrow;
  } catch (error) {
    if (timedOut) throw TimeoutException('GET $url', timeout);
    throw NetError('fetch failed');
  } finally {
    timer.cancel();
  }
}

Future<HttpReply> httpPost(
  Uri url, {
  required List<int> body,
  required String contentType,
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
  int? maxBytes,
  bool direct = false,
}) => _send(
  'POST',
  url,
  {...headers, 'content-type': contentType},
  body,
  timeout,
);

Future<HttpReply> _send(
  String method,
  Uri url,
  Map<String, String> headers,
  List<int>? body,
  Duration timeout, {
  bool followRedirects = true,
}) async {
  // The network mode's gate (network_gate.dart): Kill switch lets nothing leave the page,
  // Node only the node in use.
  try {
    NetGate.dial(NetDial.http, url.host);
  } on NetBlocked {
    throw const NetError(netModeError);
  }
  final abort = _AbortController();
  var timedOut = false;
  final timer = Timer(timeout, () {
    timedOut = true;
    abort.abort();
  });
  try {
    final init = body == null
        ? _RequestInit(
            method: method,
            headers: headers.jsify()! as JSObject,
            signal: abort.signal,
            redirect: followRedirects ? 'follow' : 'manual',
          )
        : _RequestInit(
            method: method,
            headers: headers.jsify()! as JSObject,
            signal: abort.signal,
            redirect: followRedirects ? 'follow' : 'manual',
            body: Uint8List.fromList(body).toJS,
          );
    final response = await _fetch(url.toString(), init).toDart;
    final text = await response.text().toDart;
    return HttpReply(response.status, text.toDart);
  } catch (error) {
    if (timedOut) throw TimeoutException('$method $url', timeout);
    // fetch rejects with a TypeError for every network failure, CORS included.
    throw NetError('fetch failed');
  } finally {
    timer.cancel();
  }
}

@JS('fetch')
external JSPromise<_Response> _fetch(String url, _RequestInit init);

extension type _RequestInit._(JSObject _) implements JSObject {
  external factory _RequestInit({
    String method,
    JSObject headers,
    JSObject signal,
    String redirect,
    JSAny body,
  });
}

extension type _Response._(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external _AbortController();
  external JSObject get signal;
  external void abort();
}
