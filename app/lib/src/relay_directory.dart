/// Epicbox relays and public nodes with their health, from the public monitor at
/// `status.btlabs.uk`.
///
/// The monitor probes every known relay and node every few seconds (endpoint
/// `/api/v1/status.json`, open CORS, `no-store`). The lists are advice for the network
/// settings screens. Nothing switches relay or node on its own: the relay is part of the
/// wallet's address, and the node is the user's pick (D4).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'net/http.dart';
import 'network.dart';

/// The monitor's status endpoint. Override with `--dart-define=WFE_STATUS_URL=...`.
const String relayStatusUrl = String.fromEnvironment(
  'WFE_STATUS_URL',
  defaultValue: 'https://status.btlabs.uk/api/v1/status.json',
);

/// One relay as the monitor last saw it.
class RelayStatus {
  const RelayStatus({
    required this.relay,
    required this.healthy,
    required this.verified,
    this.label,
    this.operator,
    this.latencyMs,
    this.uptime24h,
    this.protocolVersion,
  });

  final EpicboxRelay relay;

  /// The last probe completed the websocket handshake.
  final bool healthy;

  /// Listed as official by the monitor.
  final bool verified;
  final String? label;
  final String? operator;

  /// Measured from the monitor, not from this device.
  final int? latencyMs;
  final double? uptime24h;
  final String? protocolVersion;
}

/// Parses the monitor's `epicbox` list. Entries without a usable `wss://` endpoint are dropped.
List<RelayStatus> parseRelayStatus(String json) {
  final Object? decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('status: not an object');
  }
  final list = decoded['epicbox'];
  if (list is! List) throw const FormatException('status: no epicbox list');
  final relays = <RelayStatus>[];
  for (final item in list) {
    if (item is! Map<String, Object?>) continue;
    final endpoint = Uri.tryParse(item['endpoint'] as String? ?? '');
    if (endpoint == null || endpoint.scheme != 'wss' || endpoint.host.isEmpty) {
      continue;
    }
    final uptime = item['uptime'];
    relays.add(
      RelayStatus(
        relay: EpicboxRelay(
          host: endpoint.host,
          port: endpoint.hasPort ? endpoint.port : 443,
        ),
        healthy: item['state'] == 'healthy',
        verified: item['verified'] == true,
        label: item['label'] as String?,
        operator: cleanOperator(item['operator'] as String?),
        latencyMs: (item['latency_ms'] as num?)?.toInt(),
        uptime24h: uptime is Map ? (uptime['24h'] as num?)?.toDouble() : null,
        protocolVersion: item['protocol_version'] as String?,
      ),
    );
  }
  // Healthy first, then official, then fastest.
  relays.sort((a, b) {
    if (a.healthy != b.healthy) return a.healthy ? -1 : 1;
    if (a.verified != b.verified) return a.verified ? -1 : 1;
    return (a.latencyMs ?? 1 << 30).compareTo(b.latencyMs ?? 1 << 30);
  });
  return relays;
}

/// One public node as the monitor last saw it.
class NodeStatus {
  const NodeStatus({
    required this.url,
    required this.healthy,
    required this.verified,
    this.operator,
    this.height,
    this.latencyMs,
  });

  /// `scheme://host[:port]`, as the wallet stores a node address.
  final String url;

  /// The last probe got an answer at or near the tip.
  final bool healthy;

  /// Listed as official by the monitor.
  final bool verified;
  final String? operator;
  final int? height;

  /// Measured from the monitor, not from this device.
  final int? latencyMs;
}

/// Parses the monitor's `nodes` list, in its order. Entries without a plain http(s) endpoint
/// are dropped.
/// An operator name from the monitor, safe to show: control and bidi-override characters
/// removed, at most 64 characters; null when nothing is left.
String? cleanOperator(String? name) {
  final t = name?.replaceAll(RegExp(r'[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]'), '').trim();
  return t == null || t.isEmpty || t.length > 64 ? null : t;
}

List<NodeStatus> parseNodeStatus(String json) {
  final Object? decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('status: not an object');
  }
  final list = decoded['nodes'];
  if (list is! List) throw const FormatException('status: no nodes list');
  final nodes = <NodeStatus>[];
  for (final item in list) {
    if (item is! Map<String, Object?>) continue;
    if (item['kind'] != null && item['kind'] != 'node') continue;
    final endpoint = Uri.tryParse(item['endpoint'] as String? ?? '');
    if (endpoint == null ||
        // https only: every public node answers on it, and plain http would carry the
        // wallet's requests unencrypted.
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        (endpoint.path.isNotEmpty && endpoint.path != '/')) {
      continue;
    }
    final operator = cleanOperator(item['operator'] as String?);
    nodes.add(
      NodeStatus(
        url: endpoint.hasPort
            ? '${endpoint.scheme}://${endpoint.host}:${endpoint.port}'
            : '${endpoint.scheme}://${endpoint.host}',
        healthy: item['state'] == 'healthy',
        verified: item['verified'] == true,
        operator: operator,
        height: (item['height'] as num?)?.toInt(),
        latencyMs: (item['latency_ms'] as num?)?.toInt(),
      ),
    );
  }
  return nodes;
}

/// Fetches relay health for one chain.
abstract interface class RelayDirectory {
  Future<List<RelayStatus>> relays(String chain);
}

/// Fetches the public nodes of one chain.
abstract interface class NodeDirectory {
  Future<List<NodeStatus>> nodes(String chain);
}

/// Reads the monitor with a short [timeout] and keeps each answer, or failure, for [fresh], so
/// the lists do not ask again on every screen.
class HttpRelayDirectory implements RelayDirectory, NodeDirectory {
  HttpRelayDirectory({
    this.timeout = const Duration(seconds: 4),
    this.fresh = const Duration(minutes: 1),
    Future<HttpReply> Function(Uri url, {Duration timeout})? get,
    DateTime Function()? now,
  }) : _get = get ?? httpGet,
       _now = now ?? DateTime.now;

  final Duration timeout;
  final Duration fresh;
  final Future<HttpReply> Function(Uri url, {Duration timeout}) _get;
  final DateTime Function() _now;
  final Map<String, ({DateTime at, Future<String> body})> _cache = {};

  Future<String> _status(String chain) {
    final hit = _cache[chain];
    if (hit != null && _now().difference(hit.at) < fresh) return hit.body;
    final body = _fetch(chain);
    _cache[chain] = (at: _now(), body: body);
    return body;
  }

  Future<String> _fetch(String chain) async {
    final url = Uri.parse(relayStatusUrl)
        .replace(queryParameters: chain == 'mainnet' ? null : {'chain': chain});
    final reply = await _get(url, timeout: timeout).timeout(timeout);
    if (reply.status != 200) throw NetError('status ${reply.status}');
    return reply.body;
  }

  @override
  Future<List<RelayStatus>> relays(String chain) async =>
      parseRelayStatus(await _status(chain));

  @override
  Future<List<NodeStatus>> nodes(String chain) async =>
      parseNodeStatus(await _status(chain));
}

final relayDirectoryProvider = Provider<RelayDirectory>(
  (ref) => HttpRelayDirectory(),
);

/// Relay health for [NetworkPreset.statusChain]. Empty for usernet.
final relayStatusProvider = FutureProvider.autoDispose
    .family<List<RelayStatus>, NetworkPreset>((ref, preset) async {
      final chain = preset.statusChain;
      if (chain == null) return const [];
      return ref.watch(relayDirectoryProvider).relays(chain);
    });
