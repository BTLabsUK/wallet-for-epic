/// A node on the local network, as LEPIC can reach it.
///
/// LEPIC talks plain http to loopback nodes only (anything else must be https or an onion),
/// but the app writes a node typed as a local-network address with http (`gui_rules.dart`
/// isPrivateHost): such nodes answer plain http, as epic's own API does. So a plain-http node at
/// a literal local address ([isLocalAddressUrl]: 10/8, 172.16/12, 192.168/16, link-local, IPv6
/// ULA) is handed to LEPIC as `http://127.0.0.1:<port>`, a relay on this computer that pipes
/// every connection to the node, unchanged. Its traffic never leaves the local network; LEPIC
/// takes loopback directly, never over Tor, whose exits cannot reach a local address anyway.
library;

import 'dart:async';
import 'dart:io';

import 'local_address.dart';
import 'tor_net.dart' show isLoopbackUrl;

/// The relays, one per node (`host:port`), kept for the app's life.
final Map<String, Future<ServerSocket>> _relays = {};

/// How long a connection to the node may take before the relay gives up on it.
const _connectTimeout = Duration(seconds: 15);

/// [url] as LEPIC is given it: a plain-http node at a literal local-network address goes
/// through a loopback relay to it; anything else (https, loopback, a name, a public address)
/// as it is.
Future<String> lanNodeUrl(String url) async {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.scheme != 'http' || !u.hasAuthority || u.host.isEmpty) return url;
  if (isLoopbackUrl(u) || !isLocalAddressUrl(url)) return url;
  final host = u.host, port = u.port;
  final server = await _relays.putIfAbsent('$host:$port', () => _relay(host, port));
  return u.replace(host: InternetAddress.loopbackIPv4.address, port: server.port).toString();
}

Future<ServerSocket> _relay(String host, int port) async {
  final ServerSocket server;
  try {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  } catch (_) {
    _relays.remove('$host:$port');
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
