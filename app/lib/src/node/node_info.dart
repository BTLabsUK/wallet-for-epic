/// What the app can tell about any node, remote or local (F27): from the public monitor at
/// status.btlabs.uk when it lists the node, else "limited info" from the node's own foreign API.
/// One service shared by the picker, the node card and the status rail.
library;

import 'dart:async';

import '../relay_directory.dart';
import 'node_api.dart';
import 'node_api_types.dart';

enum NodeInfoSource {
  /// The monitor lists the node: its view (state, lag, uptime, peers, operator).
  directory,

  /// The monitor is unreachable or does not list the node: what the node itself answers.
  limited,

  /// Neither answered.
  none,
}

/// One node as the app sees it now. Fields a source does not give are null.
class NodeInfo {
  const NodeInfo({
    required this.url,
    required this.source,
    required this.at,
    this.state,
    this.reason,
    this.height,
    this.networkHeight,
    this.blocksBehind,
    this.version,
    this.releasedVersion,
    this.latencyMs,
    this.latencyFromMonitor = false,
    this.monitorLatencyMs,
    this.directoryReachedAt,
    this.uptime24h,
    this.peers,
    this.operator,
    this.listing,
    this.country,
    this.readyForTxs,
    this.tipTime,
    this.network,
    this.error,
  });

  final String url;
  final NodeInfoSource source;
  final DateTime at;

  /// The monitor's verdict; for limited info: healthy when the node answers and is ready,
  /// degraded when it answers but syncs, down when it does not answer.
  final NodeHealthState? state;

  /// The monitor's reason ("ok", "behind", ...).
  final String? reason;
  final int? height;

  /// The network's tip, from the monitor.
  final int? networkHeight;

  /// From the monitor's `tip_lag`, or height against [networkHeight].
  final int? blocksBehind;
  final String? version;

  /// The released node version, from the monitor.
  final String? releasedVersion;

  /// This computer's measurement: the median of its last three checks of the node; the
  /// monitor's number only when this computer could not reach the node ([latencyFromMonitor]).
  final int? latencyMs;

  /// [latencyMs] was measured by the monitor, not by this device.
  final bool latencyFromMonitor;

  /// The monitor's own measurement (from its location), for picker rows of nodes this computer
  /// has not checked yet.
  final int? monitorLatencyMs;

  /// When the monitor last answered this session ("Status site last reached HH:MM").
  final DateTime? directoryReachedAt;

  /// 0..1.
  final double? uptime24h;
  final int? peers;
  final String? operator;

  /// "official" or "community".
  final String? listing;
  final String? country;

  /// Limited info only: the node's own `ready_for_txs` (null for nodes before 4.1.0).
  final bool? readyForTxs;

  /// Limited info only: the time of the node's tip block.
  final DateTime? tipTime;

  /// The network context (all nodes, relays, tip age), when the monitor answered.
  final NetworkStatus? network;

  /// Why nothing is known, for [NodeInfoSource.none]; for the log.
  final String? error;

  bool get atTip => blocksBehind != null && blocksBehind! <= 0;

  /// The node runs an older version than the released one.
  bool? get updateAvailable {
    final v = version, r = releasedVersion;
    if (v == null || r == null) return null;
    final c = compareVersions(v, r);
    return c == null ? null : c < 0;
  }
}

/// -1, 0 or 1 comparing dotted versions ("4.1.0" < "4.1.1"; "4.1.0-1" counts as 4.1.0.1), or null
/// when either is not a version.
int? compareVersions(String a, String b) {
  List<int>? parts(String v) {
    final m = RegExp(r'^\s*v?(\d+(?:[.-]\d+)*)').firstMatch(v);
    return m?[1]!.split(RegExp(r'[.-]')).map(int.parse).toList();
  }

  final x = parts(a), y = parts(b);
  if (x == null || y == null) return null;
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0).compareTo(i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

/// Reads [NodeInfo] for a node URL. The monitor answer is cached by the directory (a minute);
/// the limited-info probe is three foreign calls plus one header.
class NodeInfoService {
  NodeInfoService({
    required this.nodes,
    this.network,
    NodeApiClient Function(String url)? clientFor,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 6),
  }) : _clientFor = clientFor ?? NodeApiClient.new,
       _clock = clock ?? DateTime.now;

  final NodeDirectory nodes;

  /// The monitor's network block; null skips the network context.
  final NetworkDirectory? network;
  final NodeApiClient Function(String url) _clientFor;
  final DateTime Function() _clock;
  final Duration timeout;

  final Map<String, List<int>> _latencies = {};
  DateTime? _reachedAt;

  /// When the monitor last answered.
  DateTime? get directoryReachedAt => _reachedAt;

  /// The median of the last three latencies this computer measured for [url], or null.
  int? measuredLatency(String url) {
    final l = _latencies[url];
    if (l == null || l.isEmpty) return null;
    final sorted = [...l]..sort();
    return sorted[sorted.length ~/ 2];
  }

  void _noteLatency(String url, int ms) {
    final l = _latencies.putIfAbsent(url, () => []);
    l.add(ms);
    if (l.length > 3) l.removeAt(0);
  }

  /// [chain] is the monitor's chain name ("mainnet", "floonet"); null skips the monitor
  /// (usernet has none).
  Future<NodeInfo> info(String url, {required String? chain}) async {
    NodeStatus? listed;
    NetworkStatus? net;
    if (chain != null) {
      try {
        listed = nodeStatusFor(await nodes.nodes(chain).timeout(timeout), url);
        _reachedAt = _clock();
      } on Object {
        // the monitor is down: limited info
      }
      try {
        net = await network?.network(chain).timeout(timeout);
      } on Object {
        // no network context
      }
    }
    if (listed != null) return _fromMonitor(url, listed, net, await _measure(url));
    return _limited(url, net);
  }

  /// One timed `get_tip` for this computer's latency; the median so far, or null.
  Future<int?> _measure(String url) async {
    try {
      final api = _clientFor(url);
      final watch = Stopwatch()..start();
      await api.tip().timeout(timeout);
      _noteLatency(url, watch.elapsedMilliseconds);
    } on Object {
      // the monitor's number stands in
    }
    return measuredLatency(url);
  }

  NodeInfo _fromMonitor(String url, NodeStatus s, NetworkStatus? net, int? measured) {
    final tip = net?.tipHeight;
    return NodeInfo(
      url: url,
      source: NodeInfoSource.directory,
      at: _clock(),
      state: s.state,
      reason: s.reason,
      height: s.height,
      networkHeight: tip,
      blocksBehind: s.tipLag ?? (tip != null && s.height != null ? tip - s.height! : null),
      version: s.nodeVersion,
      releasedVersion: net?.releasedNodeVersion,
      latencyMs: measured ?? s.latencyMs,
      latencyFromMonitor: measured == null && s.latencyMs != null,
      monitorLatencyMs: s.latencyMs,
      directoryReachedAt: _reachedAt,
      uptime24h: s.uptime24h,
      peers: s.peers,
      operator: s.operator,
      listing: s.listing,
      country: s.country,
      network: net,
    );
  }

  Future<NodeInfo> _limited(String url, NetworkStatus? net) async {
    final NodeApiClient api;
    try {
      api = _clientFor(url);
    } on Object catch (e) {
      return NodeInfo(
        url: url,
        source: NodeInfoSource.none,
        at: _clock(),
        network: net,
        directoryReachedAt: _reachedAt,
        error: '$e',
      );
    }
    final watch = Stopwatch()..start();
    final NodeTipInfo tip;
    try {
      tip = await api.tip().timeout(timeout);
    } on Object catch (e) {
      return NodeInfo(
        url: url,
        source: NodeInfoSource.none,
        at: _clock(),
        state: NodeHealthState.down,
        network: net,
        directoryReachedAt: _reachedAt,
        error: e is NodeRpcException ? e.kind.name : e.runtimeType.toString(),
      );
    }
    _noteLatency(url, watch.elapsedMilliseconds);
    Future<T?> quiet<T>(Future<T?> Function() call) async {
      try {
        return await call().timeout(timeout);
      } on Object {
        return null;
      }
    }

    final (ready, version, time) = await (
      quiet(api.readyForTxs),
      quiet(() async => (await api.version()).nodeVersion),
      quiet(() => api.headerTime(tip.height)),
    ).wait;
    final netTip = net?.tipHeight;
    return NodeInfo(
      url: url,
      source: NodeInfoSource.limited,
      at: _clock(),
      state: ready == false || tip.height == 0 ? NodeHealthState.degraded : NodeHealthState.healthy,
      height: tip.height,
      networkHeight: netTip,
      blocksBehind: netTip != null ? netTip - tip.height : null,
      version: version,
      releasedVersion: net?.releasedNodeVersion,
      latencyMs: measuredLatency(url),
      directoryReachedAt: _reachedAt,
      readyForTxs: ready,
      tipTime: time,
      network: net,
    );
  }
}
