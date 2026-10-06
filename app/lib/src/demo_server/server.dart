/// The demo server: one temporary floonet wallet per visitor, behind `/api/`.
///
/// `app/README.md` ("Web demo", the server) describes the API. Only `dart:io`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../network.dart';
import '../remote/dispatcher.dart';
import '../remote/protocol.dart' show ServiceMember;
import '../wallet_service.dart';
import 'config.dart';
import 'demo_log.dart';
import 'demo_store.dart';
import 'gated_service.dart';
import 'limits.dart';
import 'static_site.dart';
import 'ws_channel.dart';

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

/// Members the demo never serves: a visitor must not type a real phrase into a website or be
/// shown one there, and history files are hidden on the web.
const Set<String> refusedMembers = {
  'mnemonic',
  'mnemonicWithPin',
  'importHistory',
  'exportHistory',
  'exportHistoryCsv',
};

/// True for a call the demo refuses: [refusedMembers], and a create that restores a phrase.
bool refuseDemoCall(String member, Map<String, Object?> params) =>
    refusedMembers.contains(member) ||
    ((member == ServiceMember.create.name ||
            member == ServiceMember.createWithPin.name) &&
        params['mnemonic'] != null);

/// The push a socket gets when its demo ends.
const String demoEndedPush = 'demoEnded';

/// A demo that is live in this process. Its sessions belong to it, not to a socket, so a
/// reload finds its wallet still open within [DemoServerConfig.idleTimeout].
class _LiveDemo {
  _LiveDemo(this.record);

  final DemoRecord record;
  bool ended = false;

  /// Made on the first socket.
  WalletService? service;
  final WalletSessions sessions = WalletSessions();
  final Set<WalletDispatcher> sockets = {};

  /// Sockets accepted but still upgrading, counted against the per-demo cap.
  int upgrading = 0;
  Timer? idle;

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
  final DemoServiceFactory _serviceFor;
  final DateTime Function() _clock;
  final DemoStore _store;
  final ClientRateLimit _rate;
  final WorkGate _argon;
  final Map<String, _LiveDemo> _live = {};

  /// `POST /api/demo` calls between the cap check and [_live].
  int _creating = 0;
  final List<StaticSite> _sites = [];

  HttpServer? _http;
  Timer? _sweeper;
  late Set<String> _origins;

  /// The bound port, after [start].
  int get port => _http!.port;

  /// Live demos in this process.
  int get liveCount => _live.length;

  /// Sockets open on the demo [id].
  int socketsOf(String id) => _live[id]?.sockets.length ?? 0;

  /// True while the demo [id] holds open sessions.
  bool hasSessions(String id) => !(_live[id]?.sessions.isEmpty ?? true);

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
    if (config.webRoot case final web?) {
      _sites.add(StaticSite(root: web, prefix: '/app/', spaFallback: true));
    }
    if (config.landingRoot case final landing?) {
      _sites.add(StaticSite(root: landing, prefix: '/'));
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

  /// Stops listening, closes every socket and locks every wallet. Live demos stay on disk for
  /// the next start.
  Future<void> stop() async {
    _sweeper?.cancel();
    await _http?.close(force: true);
    _http = null;
    for (final d in [..._live.values]) {
      d.idle?.cancel();
      await _closeSockets(d);
      d.sessions.disposeAll();
    }
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

  Future<void> _closeSockets(_LiveDemo d, {String? push}) async {
    final sockets = [...d.sockets];
    d.sockets.clear();
    await Future.wait([
      for (final s in sockets)
        () async {
          if (push != null) s.push(push);
          await s.close().timeout(const Duration(seconds: 5), onTimeout: () {});
        }(),
    ]);
  }

  /// Tells the demo's sockets it ended, locks its wallet, deletes it and its directory.
  Future<void> _end(_LiveDemo d, String why) async {
    if (d.ended) return;
    d.ended = true;
    _live.remove(d.record.id);
    d.idle?.cancel();
    await _closeSockets(d, push: demoEndedPush);
    d.sessions.disposeAll();
    final service = d.service;
    if (service != null) {
      try {
        await service.deleteWallet(config: configFor(d.record.id));
      } on Object catch (e) {
        serverLog(ServerLogLevel.warn, 'demo ${d.short}: deleteWallet: $e');
      }
    }
    await _removeDir(d);
    serverLog(ServerLogLevel.info, 'demo ${d.short} ended ($why)');
  }

  WalletService _serviceOf(_LiveDemo d) => d.service ??= GatedWalletService(
    _serviceFor(
      DemoPaths(
        id: d.record.id,
        walletDir: _store.walletDirOf(d.record.id),
        secrets: _store.secretsOf(d.record.id),
      ),
    ),
    _argon,
    // One wallet per demo: an open replaces the sessions a lost page left behind.
    beforeOpen: d.sessions.disposeAll,
    // An open that was queued or running when the demo ended leaves nothing behind.
    ended: () => d.ended,
    afterLateOpen: () => _removeDir(d),
  );

  Future<void> _removeDir(_LiveDemo d) async {
    try {
      await _store.remove(d.record.id);
    } on Object catch (e) {
      serverLog(ServerLogLevel.error, 'demo ${d.short}: remove failed: $e');
    }
  }

  /// `/api/ws`: the cookie of a live demo and an allowed `Origin`, against cross-site
  /// WebSocket hijacking.
  Future<void> _socket(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      return _plain(request, HttpStatus.badRequest);
    }
    if (!_originAllowed(request, required: true)) {
      return _plain(request, HttpStatus.forbidden);
    }
    final id = _cookieId(request);
    final d = id == null ? null : _live[id];
    if (d == null || d.record.expiredAt(_clock())) {
      return _plain(request, HttpStatus.unauthorized);
    }
    if (d.sockets.length + d.upgrading >= config.maxSocketsPerDemo) {
      return _plain(request, HttpStatus.tooManyRequests);
    }
    d.upgrading++;
    final WebSocket socket;
    try {
      socket = await WebSocketTransformer.upgrade(request);
    } finally {
      d.upgrading--;
    }
    // A phone that drops off the network leaves a half-open socket; pings find it, so the
    // idle window starts.
    socket.pingInterval = const Duration(seconds: 30);
    if (d.ended) {
      await socket.close(WebSocketStatus.goingAway);
      return;
    }
    d.idle?.cancel();
    d.idle = null;
    final dispatcher = WalletDispatcher(
      _serviceOf(d),
      IoWebSocketChannel(socket),
      sessions: d.sessions,
      refuse: refuseDemoCall,
      rewriteConfig: (_) => configFor(d.record.id),
      maxFrameBytes: config.maxFrameBytes,
      onError: (e, st) => serverLog(
        ServerLogLevel.error,
        'demo ${d.short}: wallet call failed: $e\n$st',
      ),
    );
    d.sockets.add(dispatcher);
    unawaited(
      dispatcher.done.then((_) {
        if (!d.sockets.remove(dispatcher) || d.ended || d.sockets.isNotEmpty) {
          return;
        }
        d.idle = Timer(config.idleTimeout, () {
          d.idle = null;
          if (d.sockets.isNotEmpty || d.sessions.isEmpty) return;
          d.sessions.disposeAll();
          serverLog(ServerLogLevel.info, 'demo ${d.short} idle, wallet locked');
        });
      }),
    );
  }

  // HTTP.

  Future<void> _onRequest(HttpRequest request) async {
    final response = request.response;
    setSecurityHeaders(response.headers);
    try {
      final path = request.uri.path;
      if (path == '/api/health') return await _health(request);
      if (path == '/api/demo') return await _demo(request);
      if (path == '/api/ws') return await _socket(request);
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
    // Creates still writing their directory count too, so concurrent starts stay under the cap.
    if (_live.length + _creating >= config.maxLiveDemos) {
      final wait = _live.isEmpty
          ? const Duration(seconds: 1)
          : _live.values
                .map((d) => d.record.expires)
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .difference(now);
      serverLog(
        ServerLogLevel.warn,
        'live cap of ${config.maxLiveDemos} reached',
      );
      return _tooMany(request, 'full', wait);
    }
    final wait = _rate.take(_client(request), now);
    if (wait != null) return _tooMany(request, 'rate', wait);
    final DemoRecord record;
    _creating++;
    try {
      record = await _store.create(now: now, ttl: config.ttl);
    } finally {
      _creating--;
    }
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
