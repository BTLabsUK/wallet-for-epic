// SPDX-License-Identifier: Apache-2.0
/// Epicbox relays and public nodes with their health, from the public monitor, the status site
/// (`[status] directory` of the settings file).
///
/// The monitor probes every known relay and node every few seconds (its status file, open
/// CORS, `no-store`). The lists are advice for the network
/// settings screens. Nothing switches relay or node on its own: the relay is part of the
/// wallet's address, and the node is the user's pick.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log.dart';
import 'models.dart' show Chain;
import 'net/http.dart';
import 'net/tor_switch.dart';
import 'network.dart';
import 'settings_file/host_settings.dart';
import 'settings_file/settings_notice.dart' show SettingsChange;
import 'settings_file/settings_providers.dart' show hostSettingsChanges;

/// `--dart-define=WFE_STATUS_URL=...` replaces the settings' status file (a test monitor).
const String _statusUrlOverride = String.fromEnvironment('WFE_STATUS_URL');

/// The monitor's status file: `[status] directory` of the settings file.
String get relayStatusUrl => _statusUrlOverride.isNotEmpty ? _statusUrlOverride : hostSettings.statusDirectory;

/// Settings › Privacy › Use the status site: `[status] enabled` of the settings file, on by
/// default. Off, [HttpRelayDirectory] fails at once without a request, so every screen takes
/// its site-down path: built-in lists, the servers' own answers ("limited info"), no error.
/// Read on every request, so a change applies at once. It follows the settings file
/// ([followSettings]) from before the app asks anything.
class StatusSiteSwitch extends ChangeNotifier {
  bool _on = true;
  int _changes = 0;
  Future<bool>? _loading;

  /// The site may be asked.
  bool get on => _on;
  set on(bool value) {
    _loading = null;
    if (value == _on) return;
    _on = value;
    _changes++;
    notifyListeners();
  }

  /// Counts the changes, so a cache can tell it is from before one.
  int get changes => _changes;

  /// Takes the saved choice; until it is read, [allowed] waits for it. A failed read keeps the
  /// default (on).
  void loadFrom(Future<bool> saved) {
    final loading = saved.catchError((Object _) => true);
    _loading = loading;
    unawaited(
      loading.then((value) {
        if (identical(_loading, loading)) on = value;
      }),
    );
  }

  StreamSubscription<SettingsChange>? _follow;

  /// Takes `status.enabled` from the settings in use now and after every change (an app
  /// change or a hand edit of the file).
  void followSettings() {
    _loading = null;
    if (hostSettingsLoaded) on = hostSettings.statusEnabled;
    unawaited(_follow?.cancel());
    _follow = hostSettingsChanges.listen((c) => on = c.after.statusEnabled);
  }

  /// Whether a request to the site may go out now.
  Future<bool> allowed() async {
    final loading = _loading;
    if (loading != null) await loading;
    return _on;
  }
}

/// The app's one [StatusSiteSwitch].
final StatusSiteSwitch statusSite = StatusSiteSwitch();

/// [statusSite] for providers: those that watch it fetch again when it changes.
final useStatusSiteProvider = Provider<bool>((ref) {
  final s = statusSite;
  void changed() => ref.invalidateSelf();
  s.addListener(changed);
  ref.onDispose(() => s.removeListener(changed));
  return s.on;
});

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
    this.icon,
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

  /// The operator's icon the monitor holds, or null: the tile shows initials.
  final ServerIcon? icon;
}

/// An operator's icon on the monitor: square PNGs by pixel size, named by their content hash,
/// so a URL never changes what it serves.
@immutable
class ServerIcon {
  const ServerIcon({required this.hash, required this.urls});

  final String hash;

  /// Pixel size to URL, smallest first.
  final Map<int, Uri> urls;

  /// The smallest size of at least [pixels], else the largest.
  Uri forPixels(double pixels) {
    for (final MapEntry(:key, :value) in urls.entries) {
      if (key >= pixels) return value;
    }
    return urls.values.last;
  }

  @override
  bool operator ==(Object other) => other is ServerIcon && other.hash == hash;

  @override
  int get hashCode => hash.hashCode;
}

/// The `icon` field of a monitor entry. Only https URLs on the monitor's own host are taken,
/// so a listed operator cannot make the app fetch from anywhere else.
ServerIcon? parseServerIcon(Object? v) {
  if (v is! Map) return null;
  final hash = v['hash'];
  final urls = v['urls'];
  if (hash is! String || hash.isEmpty || urls is! Map) return null;
  final site = Uri.parse(relayStatusUrl).host;
  final out = <int, Uri>{};
  for (final MapEntry(:key, :value) in urls.entries) {
    final size = int.tryParse('$key');
    final u = value is String ? Uri.tryParse(value) : null;
    if (size == null || size <= 0 || u == null) continue;
    if (u.scheme != 'https' || u.host != site || u.userInfo.isNotEmpty) continue;
    out[size] = u;
  }
  if (out.isEmpty) return null;
  final sizes = out.keys.toList()..sort();
  return ServerIcon(hash: hash, urls: {for (final s in sizes) s: out[s]!});
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
        icon: parseServerIcon(item['icon']),
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
    this.state = NodeHealthState.unknown,
    this.reason,
    this.nodeVersion,
    this.tipLag,
    this.peers,
    this.uptime1h,
    this.uptime24h,
    this.uptime30d,
    this.listing,
    this.country,
    this.syncStatus,
    this.tipAgrees,
    this.lastCheckedAt,
    this.icon,
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

  /// The monitor's verdict; [healthy] is `state == healthy`.
  final NodeHealthState state;

  /// Why the monitor gave that state ("ok", ...).
  final String? reason;
  final String? nodeVersion;

  /// Blocks behind the highest tip the monitor has seen.
  final int? tipLag;
  final int? peers;

  /// Fractions 0..1, null where the monitor has no history.
  final double? uptime1h;
  final double? uptime24h;
  final double? uptime30d;

  /// "official" or "community".
  final String? listing;

  /// ISO country code; a registry guess.
  final String? country;

  /// The node's own `sync_status`, when the monitor could read it.
  final String? syncStatus;

  /// The node's tip matches the network's.
  final bool? tipAgrees;
  final DateTime? lastCheckedAt;

  /// The operator's icon the monitor holds, or null: the tile shows initials.
  final ServerIcon? icon;
}

/// The monitor's state of a node.
enum NodeHealthState { healthy, degraded, down, unknown }

NodeHealthState _healthState(Object? v) => switch (v) {
  'healthy' => NodeHealthState.healthy,
  'degraded' => NodeHealthState.degraded,
  'down' => NodeHealthState.down,
  _ => NodeHealthState.unknown,
};

/// The monitor's view of the chain as a whole.
class NetworkStatus {
  const NetworkStatus({
    this.tipHeight,
    this.tipHash,
    this.tipMinedAt,
    this.tipAgeSeconds,
    this.releasedNodeVersion,
    this.releasedWalletVersion,
    this.nodesHealthy,
    this.nodesTotal,
    this.epicboxHealthy,
    this.epicboxTotal,
    this.medianNodeLatencyMs,
    this.forked,
    this.healthScore,
  });

  final int? tipHeight;
  final String? tipHash;
  final DateTime? tipMinedAt;
  final int? tipAgeSeconds;
  final String? releasedNodeVersion;
  final String? releasedWalletVersion;
  final int? nodesHealthy;
  final int? nodesTotal;
  final int? epicboxHealthy;
  final int? epicboxTotal;
  final int? medianNodeLatencyMs;
  final bool? forked;

  /// 0..100.
  final int? healthScore;
}

/// Parses the monitor's `network` object; throws [FormatException] when there is none.
NetworkStatus parseNetworkStatus(String json) {
  final Object? decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('status: not an object');
  }
  final n = decoded['network'];
  if (n is! Map<String, Object?>) {
    throw const FormatException('status: no network object');
  }
  int? i(String k) => (n[k] as num?)?.toInt();
  return NetworkStatus(
    tipHeight: i('tip_height'),
    tipHash: n['tip_hash'] as String?,
    tipMinedAt: _time(n['tip_mined_at']),
    tipAgeSeconds: i('tip_age_s'),
    releasedNodeVersion: n['released_node_version'] as String?,
    releasedWalletVersion: n['released_wallet_version'] as String?,
    nodesHealthy: i('nodes_healthy'),
    nodesTotal: i('nodes_total'),
    epicboxHealthy: i('epicbox_healthy'),
    epicboxTotal: i('epicbox_total'),
    medianNodeLatencyMs: i('median_node_latency_ms'),
    forked: n['forked'] as bool?,
    healthScore: i('health_score'),
  );
}

DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

/// The entry of [nodes] for a stored node address [url]: same scheme, host and port, where a
/// missing port means the scheme's default (https 443, http 80). Null when none matches.
NodeStatus? nodeStatusFor(List<NodeStatus> nodes, String url) {
  final key = _originKey(url);
  if (key == null) return null;
  for (final n in nodes) {
    if (_originKey(n.url) == key) return n;
  }
  return null;
}

String? _originKey(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty || (u.scheme != 'https' && u.scheme != 'http')) {
    return null;
  }
  final port = u.hasPort ? u.port : (u.scheme == 'https' ? 443 : 80);
  return '${u.scheme}://${u.host.toLowerCase()}:$port';
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
    final uptime = item['uptime'];
    final location = item['location'];
    final nodeStatus = item['node_status'];
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
        state: _healthState(item['state']),
        reason: item['reason'] as String?,
        nodeVersion: item['node_version'] as String?,
        tipLag: (item['tip_lag'] as num?)?.toInt(),
        peers: (item['peers'] as num?)?.toInt(),
        uptime1h: uptime is Map ? (uptime['1h'] as num?)?.toDouble() : null,
        uptime24h: uptime is Map ? (uptime['24h'] as num?)?.toDouble() : null,
        uptime30d: uptime is Map ? (uptime['30d'] as num?)?.toDouble() : null,
        listing: item['listing'] as String?,
        country: location is Map ? location['country'] as String? : null,
        syncStatus: nodeStatus is Map ? nodeStatus['sync_status'] as String? : null,
        tipAgrees: nodeStatus is Map ? nodeStatus['tip_agrees'] as bool? : null,
        lastCheckedAt: _time(item['last_checked_at']),
        icon: parseServerIcon(item['icon']),
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

/// Fetches the monitor's view of the chain as a whole.
abstract interface class NetworkDirectory {
  Future<NetworkStatus> network(String chain);
}

/// Reads the monitor with a short [timeout] ([torTimeout] with the Tor switch on) and keeps each
/// answer, or failure, for [fresh], so the lists do not ask again on every screen. The only way
/// to the site: with [site] off it throws [NetError] without a request.
class HttpRelayDirectory implements RelayDirectory, NodeDirectory, NetworkDirectory {
  HttpRelayDirectory({
    this.timeout = const Duration(seconds: 4),
    this.torTimeout = const Duration(seconds: 30),
    this.torRetryPause = const Duration(seconds: 1),
    this.fresh = const Duration(minutes: 1),
    Future<HttpReply> Function(Uri url, {Duration timeout})? get,
    DateTime Function()? now,
    StatusSiteSwitch? site,
  }) : _get = get ?? httpGet,
       _now = now ?? DateTime.now,
       _site = site ?? statusSite;

  final Duration timeout;

  /// Over Tor the site is its onion: a first rendezvous takes several seconds and a warm one
  /// about 3 s, so [timeout] would fail most fetches. Also covers the wait for tor to connect
  /// and one more try after [torRetryPause] when the first fails.
  final Duration torTimeout;
  final Duration torRetryPause;
  final Duration fresh;
  final Future<HttpReply> Function(Uri url, {Duration timeout}) _get;
  final DateTime Function() _now;
  final StatusSiteSwitch _site;
  final Map<String, ({DateTime at, Future<String> body})> _cache = {};
  int _cachedAt = 0;

  Future<String> _status(String chain) {
    // A change of the switch drops the cache: neither state is answered from the other's.
    if (_cachedAt != _site.changes) {
      _cache.clear();
      _cachedAt = _site.changes;
    }
    final hit = _cache[chain];
    if (hit != null && _now().difference(hit.at) < fresh) return hit.body;
    final body = _fetch(chain);
    _cache[chain] = (at: _now(), body: body);
    return body;
  }

  Future<String> _fetch(String chain) async {
    if (!await _site.allowed()) throw const NetError('status site off');
    final url = Uri.parse(relayStatusUrl)
        .replace(queryParameters: chain == 'mainnet' ? null : {'chain': chain});
    final tor = TorSwitch.on;
    final limit = tor ? torTimeout : timeout;
    final watch = Stopwatch()..start();
    try {
      HttpReply reply;
      try {
        reply = await _get(url, timeout: limit).timeout(limit);
      } on NetError {
        // A cold onion rendezvous often fails once (tor's SOCKS error after several seconds)
        // and the next works: over Tor, one more try in what is left of the limit.
        final left = limit - watch.elapsed - torRetryPause;
        if (!tor || left < torRetryPause) rethrow;
        await Future<void>.delayed(torRetryPause);
        reply = await _get(url, timeout: left).timeout(left);
      }
      if (reply.status != 200) throw NetError('status ${reply.status}');
      return reply.body;
    } catch (error) {
      // The health lines then read "not reachable": the reason belongs in a report.
      logInfo('status', 'site not read ($chain${TorSwitch.on ? ', over Tor' : ''}, ${watch.elapsedMilliseconds} ms): $error');
      rethrow;
    }
  }

  @override
  Future<List<RelayStatus>> relays(String chain) async =>
      parseRelayStatus(await _status(chain));

  @override
  Future<List<NodeStatus>> nodes(String chain) async =>
      parseNodeStatus(await _status(chain));

  @override
  Future<NetworkStatus> network(String chain) async =>
      parseNetworkStatus(await _status(chain));
}

final relayDirectoryProvider = Provider<RelayDirectory>(
  (ref) => HttpRelayDirectory(),
);

/// Relay health for [NetworkPreset.statusChain]. Empty for usernet. A relay the settings list
/// (Epicbox list, connection servers) may serve both chains, and the monitor may list it under
/// floonet only: on mainnet its floonet entry stands in when the mainnet list has none, so it
/// does not look dead beside the others. A failed floonet fetch leaves it unknown.
final relayStatusProvider = FutureProvider.autoDispose
    .family<List<RelayStatus>, NetworkPreset>((ref, preset) async {
      final chain = preset.statusChain;
      if (chain == null) return const [];
      ref.watch(useStatusSiteProvider);
      final directory = ref.watch(relayDirectoryProvider);
      final list = await directory.relays(chain);
      final settings = hostSettings;
      final ours = {
        for (final b in settings.epicboxServers) b.host.toLowerCase(),
        for (final p in settings.pairingServers) ?EpicboxRelay.parse(p)?.host,
      };
      final missing = ours.difference({for (final r in list) r.relay.host.toLowerCase()});
      if (preset.chain != Chain.mainnet || missing.isEmpty) {
        return list;
      }
      try {
        final floonet = await directory.relays('floonet');
        return [
          ...list,
          for (final r in floonet)
            if (missing.contains(r.relay.host.toLowerCase())) r,
        ];
      } catch (_) {
        return list;
      }
    });
