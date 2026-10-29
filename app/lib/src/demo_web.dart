// SPDX-License-Identifier: Apache-2.0
/// The web demo's [DemoApi] against the demo server (`app/README.md` "Web demo"): the visitor's
/// demo over same-origin `/api/demo` with its cookie, test coins straight from the floonet
/// faucet, and the end the server pushes over the wallet socket.
///
/// Platform-neutral: the HTTP side is a [DemoHttp], which the browser build makes with
/// `fetch` (`demo_web_platform.dart`) and tests fake.
library;

import 'dart:async';
import 'dart:convert';

import 'demo.dart';
import 'l10n.dart';
import 'settings_file/host_settings.dart' show SettingsSyntaxError, parseSettingsToml;

/// The push the demo server sends over the wallet socket when a demo ends. The server's
/// `demoEndedPush` names the same; a test keeps them equal.
const String demoEndedPushName = 'demoEnded';

/// The floonet faucet's claim endpoint, from the `faucet` key of the `[demo]` table of the
/// demo's settings file (`demo/settings.toml`). Its answers must carry
/// `Access-Control-Allow-Origin: *`. Null when [settingsText] names none.
Uri? demoFaucetFrom(String? settingsText) {
  if (settingsText == null) return null;
  try {
    final demo = parseSettingsToml(settingsText)['demo'];
    final faucet = demo is Map ? demo['faucet'] : null;
    return faucet is String ? Uri.tryParse(faucet) : null;
  } on SettingsSyntaxError {
    return null;
  }
}

/// The cooldown when the faucet's 429 does not say: one claim per IP every 39 s.
const int defaultFaucetCooldownSeconds = 39;

/// An HTTP answer: its status and body text.
class DemoReply {
  const DemoReply(this.status, this.body);

  final int status;
  final String body;

  bool get ok => status >= 200 && status < 300;
}

/// The two kinds of request the demo makes. Each throws when no answer came (offline, DNS,
/// TLS, a refused CORS check).
abstract interface class DemoHttp {
  /// A same-origin request to the demo server, with its cookie.
  Future<DemoReply> api(String method, Uri url);

  /// A cross-origin `POST` with no body, no custom header and no credentials, so the
  /// browser sends it without a preflight.
  Future<DemoReply> simplePost(Uri url);
}

/// [DemoApi] over the demo server at [origin].
class ServerDemoApi implements DemoApi {
  ServerDemoApi({
    required this._http,
    required Uri origin,
    required this._ended,
    Future<Uri?> Function()? faucet,
  }) : _demo = origin.resolve('/api/demo'),
       _faucet = faucet ?? (() async => null);

  final DemoHttp _http;
  final Uri _demo;
  final Stream<void> _ended;
  final Future<Uri?> Function() _faucet;

  @override
  Stream<void> get ended => _ended;

  Future<DemoReply> _api(String method) async {
    try {
      return await _http.api(method, _demo);
    } catch (_) {
      throw _unreachable();
    }
  }

  @override
  Future<DemoStatus> status() async {
    final reply = await _api('GET');
    if (!reply.ok) throw _unreachable();
    return parseDemoStatus(reply.body);
  }

  @override
  Future<DemoActive> start() async {
    final reply = await _api('POST');
    if (reply.status == 429) throw demoStartRefused(reply.body);
    if (!reply.ok) throw _unreachable();
    final status = parseDemoStatus(reply.body);
    if (status is! DemoActive) throw _unreachable();
    return status;
  }

  @override
  Future<void> end() async {
    final reply = await _api('DELETE');
    if (!reply.ok) throw _unreachable();
  }

  @override
  Future<TestCoinsResult> claimTestCoins(String address) async {
    final DemoReply reply;
    try {
      final faucet = await _faucet();
      if (faucet == null) return const TestCoinsFailed();
      final url = faucet.replace(
        queryParameters: {'method': 'epicbox', 'destination': address},
      );
      reply = await _http.simplePost(url);
    } catch (_) {
      return const TestCoinsFailed();
    }
    if (reply.ok) return const TestCoinsPaid();
    if (reply.status == 429) {
      return TestCoinsCooldown(faucetCooldownSeconds(reply.body));
    }
    return const TestCoinsFailed();
  }
}

LocalizedFormatException _unreachable() =>
    LocalizedFormatException((l) => l.demoServerUnreachable);

Map<String, Object?>? _json(String body) {
  try {
    final json = jsonDecode(body);
    return json is Map<String, Object?> ? json : null;
  } on FormatException {
    return null;
  }
}

/// `GET /api/demo`'s answer: `{"state": "none" | "ended"}`, or
/// `{"state": "active", "expires": ms}` with the expiry in UTC milliseconds. Anything else
/// reads as the server not answering.
DemoStatus parseDemoStatus(String body) {
  final json = _json(body);
  switch (json?['state']) {
    case 'none':
      return const DemoNone();
    case 'ended':
      return const DemoEnded();
    case 'active':
      final expires = json?['expires'];
      if (expires is int) {
        return DemoActive(
          DateTime.fromMillisecondsSinceEpoch(expires, isUtc: true),
        );
      }
  }
  throw _unreachable();
}

/// The words for a 429 from `POST /api/demo`: `{"error": "full" | "rate", "retryAfter": s}`.
LocalizedFormatException demoStartRefused(String body) {
  final json = _json(body);
  final seconds = json?['retryAfter'];
  final minutes = seconds is int && seconds > 0 ? (seconds / 60).ceil() : 1;
  return switch (json?['error']) {
    'rate' => LocalizedFormatException((l) => l.demoStartTooMany(minutes)),
    _ => LocalizedFormatException((l) => l.demoStartFull(minutes)),
  };
}

/// The seconds a faucet 429 asks to wait. The browser cannot read a cross-origin
/// `Retry-After`, so this reads the body: the faucet answers
/// `{"code": "cooldown", "message": "Please wait 31s between requests."}` (seen 2026-10-06), so
/// a number field first, then the first `<n>s` or `<n> s` in `message`, else the faucet's
/// interval.
int faucetCooldownSeconds(String body) {
  final json = _json(body);
  if (json == null) return defaultFaucetCooldownSeconds;
  for (final key in const [
    'retry_after_seconds',
    'retry_after',
    'retryAfter',
  ]) {
    final value = json[key];
    if (value is num && value > 0) return value.ceil();
  }
  final message = json['message'];
  if (message is String) {
    final match = RegExp(r'(\d+)\s?s\b').firstMatch(message);
    final seconds = int.tryParse(match?.group(1) ?? '');
    if (seconds != null && seconds > 0) return seconds;
  }
  return defaultFaucetCooldownSeconds;
}
