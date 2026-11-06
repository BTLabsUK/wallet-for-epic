// SPDX-License-Identifier: Apache-2.0
/// `http.dart` on the phone and desktop, over `dart:io`'s `HttpClient`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'http_types.dart';
import 'tor_net.dart';

/// With [maxBytes], a body longer than that is not read to its end: the call throws
/// [NetTooLarge] as soon as it passes the limit. With [followRedirects] false a 3xx answer is
/// returned as its status and never followed.
Future<HttpReply> httpGet(
  Uri url, {
  Map<String, String> headers = const {},
  Duration timeout = defaultHttpTimeout,
  int? maxBytes,
  bool followRedirects = true,
}) => _send('GET', url, headers, null, timeout, maxBytes, followRedirects: followRedirects);

/// [httpGet] for a binary body (an icon): the bytes as they came, never decoded as text.
Future<HttpBytes> httpGetBytes(
  Uri url, {
  Duration timeout = defaultHttpTimeout,
  required int maxBytes,
  bool followRedirects = true,
}) async {
  final reply = await _sendRaw('GET', url, const {}, null, timeout, maxBytes, followRedirects: followRedirects);
  return HttpBytes(reply.status, reply.bytes);
}

/// Posts [body] with a declared length, not chunked encoding, which simple receivers cannot
/// read.
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
  {...headers, HttpHeaders.contentTypeHeader: contentType},
  body,
  timeout,
  maxBytes,
  direct: direct,
);

Future<HttpReply> _send(
  String method,
  Uri url,
  Map<String, String> headers,
  List<int>? body,
  Duration timeout,
  int? maxBytes, {
  bool direct = false,
  bool followRedirects = true,
}) async {
  final reply = await _sendRaw(method, url, headers, body, timeout, maxBytes, direct: direct, followRedirects: followRedirects);
  return HttpReply(
    reply.status,
    const Utf8Decoder(allowMalformed: true).convert(reply.bytes),
  );
}

Future<({int status, Uint8List bytes})> _sendRaw(
  String method,
  Uri url,
  Map<String, String> headers,
  List<int>? body,
  Duration timeout,
  int? maxBytes, {
  bool direct = false,
  bool followRedirects = true,
}) async {
  // The network mode first (Node only: the node in use alone; Kill switch: nothing).
  dialOrFail(NetDial.http, url);
  // With Tor on and not connected yet, held until it is: never direct meanwhile.
  // [direct]: a wallet on the local network, which Tor cannot reach (Send's reach check of a
  // plain http address there; the send itself goes direct too).
  final local = direct || isLoopbackUrl(url);
  if (!local) await TorNet.untilConnected();
  // No User-Agent (Dart's default names Dart and its version) and no cookie jar: a request
  // looks like any other client's.
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null;
  // Through tor while the Tor switch covers these requests; none while it is not connected.
  try {
    TorNet.configure(client, loopback: local);
  } on NetError {
    client.close(force: true);
    rethrow;
  }
  try {
    return await () async {
      final request = await client.openUrl(method, url);
      if (!followRedirects) request.followRedirects = false;
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
          throw NetTooLarge(maxBytes);
        }
      }
      return (status: response.statusCode, bytes: bytes.takeBytes());
    }().timeout(timeout);
  } on IOException catch (error) {
    throw NetError(error.runtimeType.toString());
  } finally {
    client.close(force: true);
  }
}
