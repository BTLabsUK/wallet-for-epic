// SPDX-License-Identifier: Apache-2.0
/// A client for an Epic node's JSON-RPC API (epic-server 4.1.0): the foreign API for what any
/// node answers, the owner API (Basic auth with the node's `.api_secret`) for status and peers.
///
/// Every failure is a [NodeRpcException]; its message never holds the secret. The HTTP is
/// injectable ([RpcTransport]) so tests need no node.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../net/lan_node_relay.dart';
import '../net/local_address.dart';
import '../net/tor_net.dart';
import '../network_gate.dart' show NetDial, NetGate;
import 'node_api_types.dart';

/// One HTTP exchange: POST [body] to [url], or GET when [body] is empty. Answers with any
/// status; throws [TimeoutException] after [timeout] and any other error when the node cannot be
/// reached.
typedef RpcTransport =
    Future<({int status, String body})> Function(
      Uri url,
      String body,
      Map<String, String> headers,
      Duration timeout,
    );

/// A plain-http node URL off loopback as the client reaches it: [lanNodeUrl]. Tests replace it.
Future<String> Function(String url) relayUrl = lanNodeUrl;

/// The largest reply read; `get_peers` can list thousands of peers.
const int maxReplyBytes = 16 * 1024 * 1024;

class NodeApiClient {
  /// [baseUrl] is `http://127.0.0.1:<port>` or `https://node.example`: plain http only for a
  /// node on this computer, the local network or a tailnet ([isLocalNodeUrl]), reached through
  /// the node relay ([lanNodeUrl]) as the wallet core reaches it, so the request (and an owner
  /// secret) goes only to the address looked up once. Plain http to anything else fails each
  /// call with [NodeRpcError.invalidArgument]. [secret] is awaited for each owner call, as the
  /// file may appear after the node starts.
  NodeApiClient(
    this._baseUrl, {
    FutureOr<String?> Function()? secret,
    RpcTransport? transport,
    this.timeout = const Duration(seconds: 5),
  }) : _readSecret = secret,
       _transport = transport ?? _ioTransport;

  final String _baseUrl;
  final FutureOr<String?> Function()? _readSecret;
  final RpcTransport _transport;
  final Duration timeout;

  /// The node address as given.
  String get baseUrl => _baseUrl;

  /// Null when the node has no such method (before 4.1.0).
  Future<bool?> readyForTxs() async {
    try {
      return parseReadyForTxs(await _rpc('foreign', 'ready_for_txs'));
    } on NodeRpcException catch (e) {
      if (e.kind == NodeRpcError.methodNotFound) return null;
      rethrow;
    }
  }

  Future<NodeTipInfo> tip() async => parseTip(await _rpc('foreign', 'get_tip'));

  /// `get_pool_size`: the transactions waiting in the node's mempool.
  Future<int> poolSize() async {
    final ok = await _rpc('foreign', 'get_pool_size');
    if (ok is int && ok >= 0) return ok;
    throw const NodeRpcException(NodeRpcError.badResponse, 'get_pool_size: not a count');
  }

  /// `get_version`, else the legacy `GET /v1/version`.
  Future<NodeVersionInfo> version() async {
    try {
      return parseVersion(await _rpc('foreign', 'get_version'));
    } on NodeRpcException catch (e) {
      if (e.kind != NodeRpcError.methodNotFound && e.kind != NodeRpcError.badResponse) rethrow;
      return parseVersion(await _legacyGet('/v1/version', auth: false));
    }
  }

  /// The time of the block at [height], or null when its header has none.
  Future<DateTime?> headerTime(int height) async =>
      parseHeaderTime(await _rpc('foreign', 'get_header', [height, null, null]));

  /// Owner `get_status`, else the legacy `GET /v1/status`.
  Future<NodeStatusInfo> status() async {
    try {
      return parseStatus(await _rpc('owner', 'get_status'));
    } on NodeRpcException catch (e) {
      if (e.kind != NodeRpcError.methodNotFound) rethrow;
      return parseStatus(await _legacyGet('/v1/status', auth: true));
    }
  }

  Future<List<ConnectedPeer>> connectedPeers() async =>
      parseConnectedPeers(await _rpc('owner', 'get_connected_peers'));

  /// The peers the node has stored, or only [addr] ("ip:port").
  Future<List<StoredPeer>> peers({String? addr}) async {
    if (addr != null) _checkAddress(addr);
    return parseStoredPeers(await _rpc('owner', 'get_peers', [addr]));
  }

  /// [addr] is "ip:port" or "[v6]:port"; anything else fails before sending.
  Future<void> banPeer(String addr) async {
    _checkAddress(addr);
    await _rpc('owner', 'ban_peer', [addr]);
  }

  Future<void> unbanPeer(String addr) async {
    _checkAddress(addr);
    await _rpc('owner', 'unban_peer', [addr]);
  }

  Future<Uri> _url(String path) async {
    final u = Uri.tryParse(_baseUrl.trim());
    if (u == null || u.host.isEmpty || u.userInfo.isNotEmpty) {
      throw const NodeRpcException(NodeRpcError.invalidArgument, 'node address is not a URL');
    }
    // The network mode's gate, on the node's own host (a LAN node's relay is its host too):
    // Node only lets the node in use through, Kill switch nothing.
    if (!NetGate.allows(NetDial.http, u.host)) {
      throw const NodeRpcException(NodeRpcError.unreachable, 'cannot reach the node: network mode');
    }
    var target = u;
    bool isLoopback(Uri x) => x.host.toLowerCase() == 'localhost' || (InternetAddress.tryParse(x.host)?.isLoopback ?? false);
    if (u.scheme == 'http' && !isLoopback(u) && isLocalNodeUrl(_baseUrl)) {
      try {
        target = Uri.parse(await relayUrl(_baseUrl));
      } on Object {
        throw const NodeRpcException(NodeRpcError.unreachable, 'cannot reach the node: relay');
      }
    }
    if (target.scheme != 'https' && !(target.scheme == 'http' && isLoopback(target))) {
      throw const NodeRpcException(
        NodeRpcError.invalidArgument,
        'a node that is not on this computer or the local network must be reached over https',
      );
    }
    final base = target.path.endsWith('/') ? target.path.substring(0, target.path.length - 1) : target.path;
    return Uri(scheme: target.scheme, host: target.host, port: target.hasPort ? target.port : null, path: '$base$path');
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      String? secret;
      try {
        secret = await _readSecret?.call();
      } on Object {
        secret = null;
      }
      if (secret != null && secret.isNotEmpty) {
        headers['Authorization'] = 'Basic ${base64.encode(utf8.encode('epic:$secret'))}';
      }
    }
    return headers;
  }

  /// One exchange, with the status and transport errors mapped. Returns the decoded body.
  Future<Object?> _send(Uri url, String body, {required bool auth}) async {
    final headers = await _headers(auth: auth);
    final ({int status, String body}) reply;
    try {
      reply = await _transport(url, body, headers, timeout).timeout(timeout);
    } on NodeRpcException {
      rethrow;
    } on TimeoutException {
      throw const NodeRpcException(NodeRpcError.timeout, 'the node did not answer in time');
    } on Object catch (e) {
      throw NodeRpcException(NodeRpcError.unreachable, 'cannot reach the node: ${e.runtimeType}');
    }
    switch (reply.status) {
      case 200:
        break;
      case 401:
        throw const NodeRpcException(NodeRpcError.unauthorized, 'the node refused the secret');
      case 404:
        throw const NodeRpcException(NodeRpcError.methodNotFound, 'not found (HTTP 404)');
      default:
        throw NodeRpcException(NodeRpcError.badResponse, 'HTTP ${reply.status}');
    }
    if (reply.body.length > maxReplyBytes) {
      throw const NodeRpcException(NodeRpcError.badResponse, 'reply too large');
    }
    try {
      return jsonDecode(reply.body);
    } on FormatException {
      throw const NodeRpcException(NodeRpcError.badResponse, 'reply is not JSON');
    }
  }

  Future<Object?> _legacyGet(String path, {required bool auth}) async => _send(await _url(path), '', auth: auth);

  /// A JSON-RPC call; returns the `Ok` payload.
  Future<Object?> _rpc(String api, String method, [List<Object?> params = const []]) async {
    final auth = api == 'owner';
    final url = await _url('/v2/$api');
    final decoded = await _send(
      url,
      jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
      auth: auth,
    );
    if (decoded is! Map) throw const NodeRpcException(NodeRpcError.badResponse, 'reply is not an object');
    final error = decoded['error'];
    if (error != null) {
      final code = error is Map ? error['code'] : null;
      final text = error is Map && error['message'] is String ? error['message'] as String : 'error';
      throw switch (code) {
        -32601 => NodeRpcException(NodeRpcError.methodNotFound, '$method: $text'),
        -32602 => NodeRpcException(NodeRpcError.invalidArgument, '$method: $text'),
        _ => NodeRpcException(NodeRpcError.badResponse, '$method: $text'),
      };
    }
    final result = decoded['result'];
    if (result is! Map) throw const NodeRpcException(NodeRpcError.badResponse, 'reply has no result');
    if (result.containsKey('Err')) {
      throw NodeRpcException(NodeRpcError.nodeError, _errText(result['Err']));
    }
    if (!result.containsKey('Ok')) throw const NodeRpcException(NodeRpcError.badResponse, 'result is not Ok or Err');
    return result['Ok'];
  }
}

/// `{"Internal": "msg"}` -> "msg".
String _errText(Object? err) {
  if (err is String) return err;
  if (err is Map && err.length == 1 && err.values.single is String) return err.values.single as String;
  return jsonEncode(err);
}

/// "a.b.c.d:port" or "[v6]:port", port 1-65535.
void _checkAddress(String addr) {
  bool ok() {
    final String host;
    final String port;
    final bool v6;
    if (addr.startsWith('[')) {
      final close = addr.indexOf(']');
      if (close < 0 || addr.length <= close + 2 || addr[close + 1] != ':') return false;
      host = addr.substring(1, close);
      port = addr.substring(close + 2);
      v6 = true;
    } else {
      final colon = addr.indexOf(':');
      if (colon < 0 || colon != addr.lastIndexOf(':')) return false;
      host = addr.substring(0, colon);
      port = addr.substring(colon + 1);
      v6 = false;
    }
    if (host.contains('%') || !RegExp(r'^[0-9]{1,5}$').hasMatch(port)) return false;
    final p = int.parse(port);
    if (p < 1 || p > 65535) return false;
    final ip = InternetAddress.tryParse(host);
    return ip != null && ip.type == (v6 ? InternetAddressType.IPv6 : InternetAddressType.IPv4);
  }

  if (!ok()) {
    throw const NodeRpcException(NodeRpcError.invalidArgument, 'peer address must be ip:port or [ipv6]:port');
  }
}

Future<({int status, String body})> _ioTransport(
  Uri url,
  String body,
  Map<String, String> headers,
  Duration timeout,
) async {
  // No User-Agent: nothing that names the app or its version.
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = null;
  try {
    // A remote node through tor while the Tor switch covers it; a node on this computer, the
    // home network or a VPN direct, as the relay reaches its plain-http form (a tor exit
    // cannot reach it, and an own node's facts are asked of the node itself).
    TorNet.configure(client, loopback: isLoopbackUrl(url) || isLocalNodeUrl(url.toString()));
    return await () async {
      final req = body.isEmpty ? await client.getUrl(url) : await client.postUrl(url);
      req.followRedirects = false; // never carry the secret to another address
      headers.forEach(req.headers.set);
      if (body.isNotEmpty) {
        final bytes = utf8.encode(body);
        req.contentLength = bytes.length;
        req.add(bytes);
      }
      final res = await req.close();
      if (res.contentLength > maxReplyBytes) {
        throw const NodeRpcException(NodeRpcError.badResponse, 'reply too large');
      }
      final out = BytesBuilder(copy: false);
      await for (final chunk in res) {
        out.add(chunk);
        if (out.length > maxReplyBytes) {
          throw const NodeRpcException(NodeRpcError.badResponse, 'reply too large');
        }
      }
      return (status: res.statusCode, body: utf8.decode(out.takeBytes(), allowMalformed: true));
    }().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}
