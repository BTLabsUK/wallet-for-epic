/// `http.dart` on the phone and desktop, over `dart:io`'s `HttpClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'http_types.dart';

Future<HttpReply> httpGet(
  Uri url, {
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
}) => _send('GET', url, headers, null, timeout);

/// Posts [body] with a declared length, not chunked encoding, which simple receivers cannot
/// read.
Future<HttpReply> httpPost(
  Uri url, {
  required List<int> body,
  required String contentType,
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
}) => _send(
  'POST',
  url,
  {...headers, HttpHeaders.contentTypeHeader: contentType},
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
  // No User-Agent (Dart's default names Dart and its version) and no cookie jar: a request
  // looks like any other client's.
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null;
  try {
    return await () async {
      final request = await client.openUrl(method, url);
      headers.forEach(request.headers.set);
      if (body != null) {
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close();
      final text = await response
          .transform(const Utf8Decoder(allowMalformed: true))
          .join();
      return HttpReply(response.statusCode, text);
    }().timeout(timeout);
  } on IOException catch (error) {
    throw NetError(error.runtimeType.toString());
  } finally {
    client.close(force: true);
  }
}
