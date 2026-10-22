/// `http.dart` on the phone and desktop, over `dart:io`'s `HttpClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'http_types.dart';

/// With [maxBytes], a body longer than that is not read to its end: the call throws
/// [NetError] as soon as it passes the limit.
Future<HttpReply> httpGet(
  Uri url, {
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
  int? maxBytes,
}) => _send('GET', url, headers, null, timeout, maxBytes);

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
  null,
);

Future<HttpReply> _send(
  String method,
  Uri url,
  Map<String, String> headers,
  List<int>? body,
  Duration timeout,
  int? maxBytes,
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
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        bytes.add(chunk);
        if (maxBytes != null && bytes.length > maxBytes) {
          throw NetError('body over $maxBytes bytes');
        }
      }
      final text = const Utf8Decoder(allowMalformed: true)
          .convert(bytes.takeBytes());
      return HttpReply(response.statusCode, text);
    }().timeout(timeout);
  } on IOException catch (error) {
    throw NetError(error.runtimeType.toString());
  } finally {
    client.close(force: true);
  }
}
