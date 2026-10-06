/// Epicbox relays and their health, from the public monitor at `status.btlabs.uk`.
///
/// The monitor probes every known relay every few seconds (endpoint `/api/v1/status.json`,
/// open CORS, `no-store`). The list is advice for the network settings screen. Nothing
/// switches relay on its own, because the relay is part of the wallet's address.
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
        operator: item['operator'] as String?,
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

/// Fetches relay health for one chain.
abstract interface class RelayDirectory {
  Future<List<RelayStatus>> relays(String chain);
}

class HttpRelayDirectory implements RelayDirectory {
  const HttpRelayDirectory();

  @override
  Future<List<RelayStatus>> relays(String chain) async {
    final url = Uri.parse(relayStatusUrl)
        .replace(queryParameters: chain == 'mainnet' ? null : {'chain': chain});
    final reply = await httpGet(url);
    if (reply.status != 200) throw NetError('status ${reply.status}');
    return parseRelayStatus(reply.body);
  }
}

final relayDirectoryProvider = Provider<RelayDirectory>(
  (ref) => const HttpRelayDirectory(),
);

/// Relay health for [NetworkPreset.statusChain]. Empty for usernet.
final relayStatusProvider = FutureProvider.autoDispose
    .family<List<RelayStatus>, NetworkPreset>((ref, preset) async {
      final chain = preset.statusChain;
      if (chain == null) return const [];
      return ref.watch(relayDirectoryProvider).relays(chain);
    });
