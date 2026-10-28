/// A node on the local network, as LEPIC can reach it.
///
/// LEPIC talks plain http to loopback nodes only (anything else must be https or an onion),
/// but the app writes a node typed as a local address with http (`gui_rules.dart`
/// isPrivateHost): such nodes answer plain http, as epic's own API does. So a plain-http node
///
/// - on this computer (`localhost`, 127/8, ::1) goes to LEPIC as it is;
/// - at a literal local-network address ([isLocalIpBytes]: 10/8, 172.16/12, 192.168/16,
///   169.254/16, fc00::/7, fe80::/10) is handed to LEPIC as `http://127.0.0.1:<port>/<token>`,
///   a relay on this computer that passes each request on to the node;
/// - at a `.local` or `.lan` name is looked up once; when every address found is local, the
///   relay goes to the first one (never looked up again), else LEPIC gets the name and refuses
///   it as before;
/// - at a literal CGNAT address (100.64.0.0/10: a Tailscale tailnet, but also a provider's
///   carrier-grade NAT, which cannot be told apart) goes through the relay only once the user
///   agreed for that node ([allowPlainHttpNode], asked when the node is added). On the first run
///   with agreements (no `lan_nodes.json` yet) every such node the app uses is agreed for, so a
///   tailnet node set up before keeps working. Otherwise LEPIC gets it as it is and refuses it.
///
/// Anything else (https, a public address, another name, an onion) goes as it is. The relay
/// answers only requests whose path starts with its random token, which only LEPIC and the
/// app's own node client are given, so another program or app on this device cannot use it to
/// reach the node. Plain http still crosses the local network unencrypted, a node API secret
/// with it: the node rows warn when one would. LEPIC takes loopback directly, never over Tor,
/// whose exits cannot reach a local address anyway. LEPIC's ADR 0006 records the exception.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../data_folder.dart' show appDataDirectory;
import 'local_address.dart';

/// The relays, one per node address (`ip|port`), kept for the app's life.
final Map<String, Future<_Relay>> _relays = {};

class _Relay {
  _Relay(this.server, this.token, this.client);

  final HttpServer server;
  final String token;
  final HttpClient client;

  Future<void> close() async {
    client.close(force: true);
    await server.close(force: true);
  }
}

/// How long a connection to the node may take before the relay gives up on it.
const _connectTimeout = Duration(seconds: 15);

/// Headers that belong to one connection, never passed on.
const _hopHeaders = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'proxy-connection',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'host',
};

/// Looks a `.local` / `.lan` node up for [lanNodeUrl]. Tests replace it.
HostLookup lanNodeLookup = (host) async => [for (final a in await InternetAddress.lookup(host)) a.address];

/// [url] as LEPIC is given it (see the library comment).
Future<String> lanNodeUrl(String url) async {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.scheme != 'http' || !u.hasAuthority || u.host.isEmpty) return url;
  // A zone in a URL is percent-encoded (fe80::1%25eth0); a socket takes it plain.
  final host = Uri.decodeComponent(u.host);
  final String target;
  switch (hostKind(host)) {
    case HostKind.local:
      if (host.toLowerCase() == 'localhost' || isLoopbackIp(host)) return url;
      target = host;
    case HostKind.name:
      if (!isLocalNetworkName(host)) return url;
      final found = await resolveLocal(host, lanNodeLookup);
      if (found == null) return url;
      target = found;
    case HostKind.public:
      if (!isCgnatIp(host) || !await _agreedOrEarlier(url)) return url;
      target = host;
    case HostKind.onion:
      return url;
  }
  final port = u.port;
  final key = '$target|$port';
  final relay = await _relays.putIfAbsent(key, () => _relay(key, target, port));
  final path = u.path.endsWith('/') ? u.path.substring(0, u.path.length - 1) : u.path;
  return u.replace(host: InternetAddress.loopbackIPv4.address, port: relay.server.port, path: '/${relay.token}$path').toString();
}

Future<_Relay> _relay(String key, String host, int port) async {
  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  } catch (_) {
    _relays.remove(key);
    rethrow;
  }
  final client = HttpClient()
    ..connectionTimeout = _connectTimeout
    ..autoUncompress = false
    ..findProxy = ((_) => 'DIRECT');
  final relay = _Relay(server, _newToken(), client);
  server.listen((request) => unawaited(_forward(relay, request, host, port)));
  return relay;
}

/// 128 random bits, URL-safe.
String _newToken() {
  final random = Random.secure();
  return base64Url.encode([for (var i = 0; i < 16; i++) random.nextInt(256)]).replaceAll('=', '');
}

/// One request from LEPIC (or the app's node client) to the node and its answer back, headers
/// and body as they are. A request without the token is refused; a node that cannot be reached
/// closes the connection, which LEPIC sees as the node not answering.
Future<void> _forward(_Relay relay, HttpRequest request, String host, int port) async {
  final prefix = '/${relay.token}';
  final path = request.uri.path;
  if (path != prefix && !path.startsWith('$prefix/')) {
    request.response.statusCode = HttpStatus.forbidden;
    await request.response.close().catchError((_) {});
    return;
  }
  final rest = path.substring(prefix.length);
  final query = request.uri.hasQuery ? '?${request.uri.query}' : '';
  try {
    final out = await relay.client.open(request.method, host, port, '${rest.isEmpty ? '/' : rest}$query');
    out.followRedirects = false;
    request.headers.forEach((name, values) {
      if (!_hopHeaders.contains(name.toLowerCase())) out.headers.set(name, values);
    });
    await out.addStream(request);
    final answer = await out.close();
    final response = request.response..statusCode = answer.statusCode;
    answer.headers.forEach((name, values) {
      if (!_hopHeaders.contains(name.toLowerCase())) response.headers.set(name, values);
    });
    await response.addStream(answer);
    await response.close();
  } on Object {
    try {
      (await request.response.detachSocket(writeHeaders: false)).destroy();
    } on Object {
      // Already answered in part: the connection is gone either way.
    }
  }
}

/// Closes every relay (tests).
Future<void> closeLanNodeRelays() async {
  final all = [..._relays.values];
  _relays.clear();
  for (final r in all) {
    await (await r).close();
  }
}

/// Whether [url] is a plain-http node at a CGNAT address, which goes through the relay only
/// once the user agreed for it ([allowPlainHttpNode]).
bool needsPlainHttpConsent(String url) {
  final u = Uri.tryParse(url.trim());
  return u != null && u.scheme == 'http' && u.host.isNotEmpty && isCgnatIp(u.host);
}

/// Where the agreed nodes are kept: `lan_nodes.json` in the app's data folder. Tests replace it.
Future<File> Function() lanNodesFile = () async =>
    File('${(await appDataDirectory()).path}${Platform.pathSeparator}lan_nodes.json');

Set<String>? _agreed;

/// No agreement file when this run first looked: the nodes in use were set up before agreements.
bool _firstRun = false;

String _nodeKey(String url) {
  final u = Uri.parse(url.trim());
  return '${u.host.toLowerCase()}:${u.hasPort ? u.port : 80}';
}

Future<Set<String>> _load() async {
  final agreed = _agreed;
  if (agreed != null) return agreed;
  final loaded = <String>{};
  try {
    final file = await lanNodesFile();
    _firstRun = !await file.exists();
    if (!_firstRun) {
      final json = jsonDecode(await file.readAsString());
      if (json is Map && json['plainHttp'] is List) {
        loaded.addAll((json['plainHttp'] as List).whereType<String>());
      }
    }
  } on Object {
    // Unreadable: nothing agreed; the user can agree again.
  }
  return _agreed ??= loaded;
}

Future<void> _save(Set<String> agreed) async {
  try {
    final file = await lanNodesFile();
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode({'plainHttp': agreed.toList()..sort()}), flush: true);
    await tmp.rename(file.path);
  } on Object {
    // Kept for this run only.
  }
}

/// Whether the user agreed to reach the CGNAT node [url] over plain http.
Future<bool> plainHttpNodeAllowed(String url) async => (await _load()).contains(_nodeKey(url));

/// Records that the user agreed to reach [url] (a CGNAT address, [needsPlainHttpConsent]) over
/// plain http; the next [lanNodeUrl] for it goes through the relay.
Future<void> allowPlainHttpNode(String url) async {
  if (!needsPlainHttpConsent(url)) return;
  final agreed = await _load();
  if (agreed.add(_nodeKey(url))) await _save(agreed);
}

Future<bool> _agreedOrEarlier(String url) async {
  final agreed = await _load();
  if (agreed.contains(_nodeKey(url))) return true;
  if (!_firstRun) return false;
  agreed.add(_nodeKey(url));
  await _save(agreed);
  return true;
}

/// Forgets what [_load] read (tests).
void resetLanNodeAgreements() {
  _agreed = null;
  _firstRun = false;
}
