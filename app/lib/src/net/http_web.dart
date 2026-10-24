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
/// cheap byte stream here).
Future<HttpReply> httpGet(
  Uri url, {
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
  int? maxBytes,
}) async {
  final reply = await _send('GET', url, headers, null, timeout);
  if (maxBytes != null && utf8.encode(reply.body).length > maxBytes) {
    throw NetTooLarge(maxBytes);
  }
  return reply;
}

Future<HttpReply> httpPost(
  Uri url, {
  required List<int> body,
  required String contentType,
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
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
  Duration timeout,
) async {
  // The Offline mode: nothing leaves the page (the demo server's own calls included).
  if (NetGate.offline) throw const NetError('Offline mode');
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
          )
        : _RequestInit(
            method: method,
            headers: headers.jsify()! as JSObject,
            signal: abort.signal,
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
    JSAny body,
  });
}

extension type _Response._(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
}

@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external _AbortController();
  external JSObject get signal;
  external void abort();
}
