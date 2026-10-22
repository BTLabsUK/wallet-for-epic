/// One small HTTP GET and POST for the app's side calls: the price, relay health and feedback.
///
/// The phone and desktop use `dart:io`'s `HttpClient` (`http_io.dart`); the browser uses
/// `fetch` (`http_web.dart`). Both answer with an [HttpReply] for any status, throw
/// [TimeoutException] when [timeout] passes, and throw [NetError] when the server cannot be
/// reached (offline, DNS, TLS, or on the web a refused CORS check).
///
/// Requests carry no User-Agent, no cookies and only the headers the caller names, so the
/// status site, the update manifest and the contacts file see no app, version, system or
/// wallet. Every fetch of public data goes through [httpGet].
library;

export 'http_types.dart';
export 'http_io.dart' if (dart.library.js_interop) 'http_web.dart';
