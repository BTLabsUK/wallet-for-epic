// SPDX-License-Identifier: Apache-2.0
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
///   agreed for that node ([allowPlainHttpNode], asked when the node is added), kept in the
///   settings file's `[node] plain_http` (`plain_http_nodes.dart`). On the first run with
///   agreements (none in the file, no `lan_nodes.json` from before) every such node already in
///   the settings file's node list is agreed for when the app uses it, so a tailnet node set up
///   before keeps working. Otherwise LEPIC gets it as it is and refuses it.
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

import '../network_gate.dart' show NetDial, NetGate;
import '../settings_file/host_settings.dart' show HostSettings, hostSettings;
import '../settings_file/plain_http_nodes.dart';
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
      // Node only looks up the node in use's name only; Kill switch none.
      if (!NetGate.allows(NetDial.lookup, host)) return url;
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
  final relay = await _relays.putIfAbsent(key, () => _relay(key, target, port, host));
  final path = u.path.endsWith('/') ? u.path.substring(0, u.path.length - 1) : u.path;
  return u.replace(host: InternetAddress.loopbackIPv4.address, port: relay.server.port, path: '/${relay.token}$path').toString();
}

/// [name]: the node's host as the user wrote it, which the network mode's gate knows.
Future<_Relay> _relay(String key, String host, int port, String name) async {
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
  server.listen((request) => unawaited(_forward(relay, request, host, port, name)));
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
Future<void> _forward(_Relay relay, HttpRequest request, String host, int port, String name) async {
  final prefix = '/${relay.token}';
  final path = request.uri.path;
  // The network mode's gate: Node only passes requests on to the node in use only, Kill
  // switch none.
  if ((path != prefix && !path.startsWith('$prefix/')) || !NetGate.allows(NetDial.nodeRelay, name)) {
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

/// The settings the agreements are read from: `[node] plain_http` and the Node list of the
/// settings in use (`plain_http_nodes.dart`). Tests replace it.
HostSettings Function() lanNodeSettings = () => hostSettings;

/// No agreement anywhere when this run first looked (none in the settings file, and no
/// `lan_nodes.json` from before): the nodes in use were set up before agreements.
bool? _firstRun;

/// On the first run: the CGNAT nodes that were in the settings file's node list when first
/// asked, the only ones agreed for without asking. A node added later, or one the user
/// declined, never is.
Set<String>? _carried;

Future<bool> _isFirstRun() async {
  if (_firstRun case final known?) return known;
  var none = plainHttpNodesIn(lanNodeSettings()).isEmpty;
  if (none) {
    try {
      none = await readLanNodesFile() == null;
    } on Object {
      // Unreadable: as if there were one, nothing carried.
      none = false;
    }
  }
  return _firstRun ??= none;
}

/// Whether the user agreed to reach the CGNAT node [url] over plain http.
Future<bool> plainHttpNodeAllowed(String url) async => plainHttpAgreedIn(lanNodeSettings(), url);

/// Records that the user agreed to reach [url] (a CGNAT address, [needsPlainHttpConsent]) over
/// plain http, in the settings file's `[node] plain_http`; the next [lanNodeUrl] for it goes
/// through the relay.
Future<void> allowPlainHttpNode(String url) async {
  if (!needsPlainHttpConsent(url)) return;
  await _record(url);
}

Future<void> _record(String url) async {
  final s = lanNodeSettings();
  if (plainHttpAgreedIn(s, url)) return;
  final u = Uri.parse(url.trim());
  // As the node list holds it: scheme, host and port only.
  final node = Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null).toString();
  try {
    await writePlainHttpNodes({plainHttpKey: plainHttpWith(s, node)});
  } on Object {
    // Not written: asked for again on a later run.
  }
}

Future<bool> _agreedOrEarlier(String url) async {
  if (plainHttpAgreedIn(lanNodeSettings(), url)) return true;
  if (!await _isFirstRun()) return false;
  final key = plainHttpNodeKey(url);
  final carried = _carried ??= {
    for (final node in lanNodeSettings().nodeUrls)
      if (needsPlainHttpConsent(node)) ?plainHttpNodeKey(node),
  };
  if (!carried.contains(key)) return false;
  await _record(url);
  return true;
}

/// Forgets what this run looked up for the first run (tests).
void resetLanNodeAgreements() {
  _firstRun = null;
  _carried = null;
}
