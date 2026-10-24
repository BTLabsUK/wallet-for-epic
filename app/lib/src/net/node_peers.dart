/// The peer count of a node, for the Offline line that a payment waits in the node's pool
/// while the node has none. Owner `get_status` answers without the node's secret (epic 4.1.0).
/// Over `http.dart`, so also on the web.
library;

import 'dart:convert';

import 'http.dart';

/// How many peers the node at [url] has, or null when it does not say (no answer, an error, a
/// reply without the count). [post] stands in for [httpPost] in tests.
Future<int?> nodePeerCount(
  String url, {
  Future<HttpReply> Function(Uri url, List<int> body)? post,
}) async {
  try {
    final base = Uri.parse(url.trim());
    final path = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
    final to = base.replace(path: '$path/v2/owner', query: null, fragment: null);
    final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'get_status', 'params': []}));
    final reply = await (post ??
        (u, b) => httpPost(u, body: b, contentType: 'application/json', timeout: const Duration(seconds: 3)))(to, body);
    if (reply.status != 200) return null;
    final json = jsonDecode(reply.body);
    final ok = json is Map && json['result'] is Map ? (json['result'] as Map)['Ok'] : null;
    final peers = ok is Map ? ok['connections'] : null;
    return peers is int && peers >= 0 ? peers : null;
  } on Object {
    return null;
  }
}
