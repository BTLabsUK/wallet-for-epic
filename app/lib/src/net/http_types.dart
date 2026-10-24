/// What `http.dart`'s calls return and throw, the same on every platform.
library;

import 'dart:typed_data';

/// A server's answer: its status and its body as UTF-8 text.
class HttpReply {
  const HttpReply(this.status, this.body);

  final int status;
  final String body;

  /// A 2xx status.
  bool get ok => status >= 200 && status < 300;
}

/// A server's answer with a binary body ([httpGetBytes]).
class HttpBytes {
  const HttpBytes(this.status, this.bytes);

  final int status;
  final Uint8List bytes;
}

/// The request never got an answer: offline, DNS, TLS, refused, or on the web a CORS check.
class NetError implements Exception {
  const NetError(this.message);

  final String message;

  @override
  String toString() => 'NetError: $message';
}

/// The answer was longer than the caller's `maxBytes`; it was not read to its end.
class NetTooLarge extends NetError {
  const NetTooLarge(int maxBytes) : super('body over $maxBytes bytes');
}

/// The time a call gets when the caller names none.
const Duration defaultHttpTimeout = Duration(seconds: 15);
