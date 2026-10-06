/// What `http.dart`'s calls return and throw, the same on every platform.
library;

/// A server's answer: its status and its body as UTF-8 text.
class HttpReply {
  const HttpReply(this.status, this.body);

  final int status;
  final String body;

  /// A 2xx status.
  bool get ok => status >= 200 && status < 300;
}

/// The request never got an answer: offline, DNS, TLS, refused, or on the web a CORS check.
class NetError implements Exception {
  const NetError(this.message);

  final String message;

  @override
  String toString() => 'NetError: $message';
}

/// The time a call gets when the caller names none.
const Duration defaultHttpTimeout = Duration(seconds: 15);
