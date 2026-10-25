/// A node on the local network, as LEPIC can reach it.
///
/// LEPIC talks plain http to loopback nodes only (anything else must be https or an onion),
/// but the app writes a node typed as a local address with http (`gui_rules.dart`
/// isPrivateHost): such nodes answer plain http, as epic's own API does. So a plain-http node
///
/// - on this computer (`localhost`, 127/8, ::1) goes to LEPIC as it is;
/// - at a literal local-network address ([isLocalIpBytes]: 10/8, 172.16/12, 192.168/16,
///   169.254/16, fc00::/7, fe80::/10) is handed to LEPIC as `http://127.0.0.1:<port>`, a relay
///   on this computer that pipes every connection to the node, unchanged;
/// - at a `.local` or `.lan` name is looked up once; when every address found is local, the
///   relay goes to the first one (never looked up again), else LEPIC gets the name and refuses
///   it as before;
/// - at a literal CGNAT address (100.64.0.0/10, a Tailscale tailnet: [isCgnatIp]) goes through
///   the relay as well (the owner, 2026-10-25), though Offline does not count it as local.
///
/// Anything else (https, a public address, another name, an onion) goes as it is. The relayed
/// traffic never leaves the local network; LEPIC takes loopback directly, never over Tor, whose
/// exits cannot reach a local address anyway.
library;

import 'dart:async';
import 'dart:io';

import 'local_address.dart';

/// The relays, one per node address (`ip|port`), kept for the app's life.
final Map<String, Future<ServerSocket>> _relays = {};

/// How long a connection to the node may take before the relay gives up on it.
const _connectTimeout = Duration(seconds: 15);

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
      if (!isCgnatIp(host)) return url;
      target = host;
    case HostKind.onion:
      return url;
  }
  final port = u.port;
  final key = '$target|$port';
  final server = await _relays.putIfAbsent(key, () => _relay(key, target, port));
  return u.replace(host: InternetAddress.loopbackIPv4.address, port: server.port).toString();
}

Future<ServerSocket> _relay(String key, String host, int port) async {
  final ServerSocket server;
  try {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  } catch (_) {
    _relays.remove(key);
    rethrow;
  }
  server.listen((client) => unawaited(_pipe(client, host, port)));
  return server;
}

/// One connection: [client] (LEPIC) to the node and back, byte for byte. A node that cannot be
/// reached closes the client at once, which LEPIC sees as the node not answering.
Future<void> _pipe(Socket client, String host, int port) async {
  final Socket node;
  try {
    node = await Socket.connect(host, port, timeout: _connectTimeout);
  } catch (_) {
    client.destroy();
    return;
  }
  void close() {
    client.destroy();
    node.destroy();
  }

  await Future.wait([
    client.cast<List<int>>().pipe(node).catchError((_) {}),
    node.cast<List<int>>().pipe(client).catchError((_) {}),
  ]).whenComplete(close);
}

/// Closes every relay (tests).
Future<void> closeLanNodeRelays() async {
  final all = [..._relays.values];
  _relays.clear();
  for (final r in all) {
    await (await r).close();
  }
}
