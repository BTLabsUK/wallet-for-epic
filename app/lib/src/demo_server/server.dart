/// The demo server: one temporary floonet wallet per visitor, behind `/api/`.
///
/// `app/README.md` ("Web demo", the server) describes the API. Only `dart:io`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../network.dart';
import '../wallet_service.dart';
import 'config.dart';
import 'demo_log.dart';
import 'demo_store.dart';
import 'limits.dart';
import 'static_site.dart';

/// The cookie that names a visitor's demo.
const String demoCookie = 'wfe_demo';

/// Makes the wallet service of one demo. The server wraps it in its Argon2id gate.
typedef DemoServiceFactory = WalletService Function(DemoPaths paths);

/// Where one demo keeps its files.
class DemoPaths {
  const DemoPaths({
    required this.id,
    required this.walletDir,
    required this.secrets,
  });

  final String id;

  /// Given to the service as `WalletConfig.dataDir` in every call.
  final String walletDir;

  /// The demo's secret store file.
  final String secrets;
}

/// A demo that is live in this process.
class _LiveDemo {
  _LiveDemo(this.record);

  final DemoRecord record;
  bool ended = false;

  String get short => shortDemoId(record.id);
}

class DemoServer {
  DemoServer({
    required this.config,
    required this._serviceFor,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _store = DemoStore(config.dataRoot),
       _rate = ClientRateLimit(limit: config.newDemosPerClientPerHour),
       _argon = WorkGate(config.argonSlots);

  final DemoServerConfig config;
  // ignore: unused_field
  final DemoServiceFactory _serviceFor;
  final DateTime Function() _clock;
  final DemoStore _store;
  final ClientRateLimit _rate;
  // ignore: unused_field
  final WorkGate _argon;
  final Map<String, _LiveDemo> _live = {};
  final List<StaticSite> _sites = [];

  HttpServer? _http;
  Timer? _sweeper;
  late Set<String> _origins;

  /// The bound port, after [start].
  int get port => _http!.port;

  /// Live demos in this process.
  int get liveCount => _live.length;

  DemoStore get store => _store;

  /// The wallet config of every call a demo makes: its own directory on floonet, whatever
  /// the browser sent.
  WalletConfig configFor(String id) => floonetPreset.config(
    dataDir: _store.walletDirOf(id),
    nodeUrl: floonetPreset.nodeUrl,
  );

  /// Purges expired and broken demos, loads the live ones, binds and starts the sweeper.
  Future<void> start() async {
    await _store.prepare();
    final loaded = await _store.loadAndPurge(_clock());
    for (final r in loaded.live) {
      _live[r.id] = _LiveDemo(r);
    }
    serverLog(
      ServerLogLevel.info,
      'start-up: ${loaded.live.length} live demos, ${loaded.removed} removed',
    );
    if (config.landingRoot != null || config.webRoot != null) {
      if (config.webRoot case final web?) {
        _sites.add(StaticSite(root: web, prefix: '/app/', spaFallback: true));
      }
      if (config.landingRoot case final landing?) {
        _sites.add(StaticSite(root: landing, prefix: '/'));
      }
    }
    final http = await HttpServer.bind(config.bindAddress, config.port);
    http.autoCompress = false;
    http.serverHeader = null;
    http.idleTimeout = const Duration(seconds: 30);
    _http = http;
    _origins = config.effectiveOrigins(http.port);
    http.listen(_onRequest);
    _sweeper = Timer.periodic(config.sweepInterval, (_) => unawaited(sweep()));
    serverLog(
      ServerLogLevel.info,
      'listening on ${config.bindAddress}:${http.port}',
    );
  }

  /// Stops listening. Live demos stay on disk for the next start.
  Future<void> stop() async {
    _sweeper?.cancel();
    await _http?.close(force: true);
    _http = null;
  }

  /// Ends every expired demo. Runs every [DemoServerConfig.sweepInterval].
  Future<void> sweep() async {
    final now = _clock();
    _rate.prune(now);
    final expired = [
      for (final d in _live.values)
        if (d.record.expiredAt(now)) d,
    ];
    for (final d in expired) {
      await _end(d, 'expired');
    }
  }

  Future<void> _end(_LiveDemo d, String why) async {
    if (d.ended) return;
    d.ended = true;
    _live.remove(d.record.id);
    try {
      await _store.remove(d.record.id);
    } on Object catch (e) {
      serverLog(ServerLogLevel.error, 'demo ${d.short}: remove failed: $e');
    }
    serverLog(ServerLogLevel.info, 'demo ${d.short} ended ($why)');
  }

  // HTTP.

  Future<void> _onRequest(HttpRequest request) async {
    final response = request.response;
    setSecurityHeaders(response.headers);
    try {
      final path = request.uri.path;
      if (path == '/api/health') return await _health(request);
      if (path == '/api/demo') return await _demo(request);
      if (path.startsWith('/api/')) {
        return await _plain(request, HttpStatus.notFound);
      }
      if (request.method == 'GET' || request.method == 'HEAD') {
        for (final site in _sites) {
          if (site.matches(path) && await site.serve(request)) return;
        }
      }
      await _plain(request, HttpStatus.notFound);
    } on Object catch (e, st) {
      serverLog(ServerLogLevel.error, 'request failed: $e\n$st');
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } on Object {
        // The response was already under way.
      }
    }
  }

  Future<void> _plain(HttpRequest request, int status) async {
    request.response.statusCode = status;
    await request.response.close();
  }

  Future<void> _json(
    HttpRequest request,
    int status,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final r = request.response;
    r.statusCode = status;
    r.headers.contentType = ContentType.json;
    r.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    headers.forEach(r.headers.set);
    r.write(jsonEncode(body));
    await r.close();
  }

  Future<void> _health(HttpRequest request) async {
    if (request.method != 'GET') {
      return _plain(request, HttpStatus.methodNotAllowed);
    }
    await _json(request, HttpStatus.ok, {
      'ok': true,
      'live': _live.length,
      'cap': config.maxLiveDemos,
    });
  }

  /// The id in the request's cookie, when it is well formed.
  String? _cookieId(HttpRequest request) {
    for (final c in request.cookies) {
      if (c.name == demoCookie && isDemoId(c.value)) return c.value;
    }
    return null;
  }

  /// A request from a page is from an allowed origin. Requests without an `Origin` header
  /// (curl, a same-origin GET) pass; the cookie is SameSite=Strict besides.
  bool _originAllowed(HttpRequest request, {required bool required}) {
    final origin = request.headers.value('origin');
    if (origin == null) return !required;
    return _origins.contains(origin);
  }

  /// The client, for the rate limit only. Never logged or stored.
  String _client(HttpRequest request) {
    if (config.trustProxy) {
      final forwarded = request.headers.value('x-forwarded-for');
      if (forwarded != null && forwarded.trim().isNotEmpty) {
        return forwarded.split(',').last.trim();
      }
    }
    return request.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  Cookie _cookie(String value, Duration maxAge) {
    final c = Cookie(demoCookie, value)
      ..httpOnly = true
      ..secure = config.secureCookie
      ..sameSite = SameSite.strict
      ..path = '/'
      ..maxAge = maxAge.inSeconds;
    return c;
  }

  Map<String, Object?> _active(_LiveDemo d) => {
    'state': 'active',
    'expires': d.record.expires.millisecondsSinceEpoch,
  };

  Future<void> _demo(HttpRequest request) async {
    final method = request.method;
    if (method != 'GET' && !_originAllowed(request, required: false)) {
      return _plain(request, HttpStatus.forbidden);
    }
    final id = _cookieId(request);
    final live = id == null ? null : _live[id];
    switch (method) {
      case 'GET':
        if (live != null && !live.record.expiredAt(_clock())) {
          return _json(request, HttpStatus.ok, _active(live));
        }
        if (id == null) return _json(request, HttpStatus.ok, {'state': 'none'});
        // A cookie whose demo is gone: ended. Clearing it makes the next answer none.
        request.response.cookies.add(_cookie('', Duration.zero));
        return _json(request, HttpStatus.ok, {'state': 'ended'});
      case 'POST':
        if (live != null && !live.record.expiredAt(_clock())) {
          return _json(request, HttpStatus.ok, _active(live));
        }
        return _create(request);
      case 'DELETE':
        if (live != null) await _end(live, 'ended by the visitor');
        request.response.cookies.add(_cookie('', Duration.zero));
        return _plain(request, HttpStatus.noContent);
      default:
        return _plain(request, HttpStatus.methodNotAllowed);
    }
  }

  Future<void> _create(HttpRequest request) async {
    final now = _clock();
    if (_live.length >= config.maxLiveDemos) {
      final soonest = _live.values
          .map((d) => d.record.expires)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final wait = soonest.difference(now);
      serverLog(
        ServerLogLevel.warn,
        'live cap of ${config.maxLiveDemos} reached',
      );
      return _tooMany(request, 'full', wait);
    }
    final wait = _rate.take(_client(request), now);
    if (wait != null) return _tooMany(request, 'rate', wait);
    final record = await _store.create(now: now, ttl: config.ttl);
    final d = _LiveDemo(record);
    _live[record.id] = d;
    serverLog(ServerLogLevel.info, 'demo ${d.short} started');
    request.response.cookies.add(
      _cookie(record.id, record.expires.difference(now)),
    );
    await _json(request, HttpStatus.created, _active(d));
  }

  Future<void> _tooMany(HttpRequest request, String reason, Duration wait) {
    final seconds = wait.inSeconds < 1 ? 1 : wait.inSeconds + 1;
    return _json(
      request,
      HttpStatus.tooManyRequests,
      {'error': reason, 'retryAfter': seconds},
      headers: {HttpHeaders.retryAfterHeader: '$seconds'},
    );
  }
}
