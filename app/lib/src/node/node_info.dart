// SPDX-License-Identifier: Apache-2.0
/// What the app can tell about any node, remote or local: from the public monitor at
/// status.btlabs.uk when it lists the node, else "limited info" from the node's own foreign API.
/// One service shared by the picker, the node card and the status rail.
library;

import 'dart:async';

import '../net/local_address.dart';
import '../net/tor_net.dart' show isLoopbackUrl;
import '../net/tor_switch.dart';
import '../relay_directory.dart';
import 'node_api.dart';
import 'node_api_types.dart';
import 'node_info_types.dart';

export 'node_info_types.dart';

/// How long a node may take over Tor.
const Duration torNodeTimeout = Duration(seconds: 30);

/// Reads [NodeInfo] for a node URL. The monitor answer is cached by the directory (a minute);
/// the limited-info probe is three foreign calls plus one header.
class NodeInfoService {
  NodeInfoService({
    required this.nodes,
    this.network,
    NodeApiClient Function(String url)? clientFor,
    DateTime Function()? clock,
    bool Function()? overTor,
    this.publicTip,
    this.timeout = const Duration(seconds: 6),
  }) : _clientFor = clientFor ?? NodeApiClient.new,
       _overTor = overTor ?? (() => TorSwitch.on),
       _clock = clock ?? DateTime.now;

  final NodeDirectory nodes;

  /// The monitor's network block; null skips the network context.
  final NetworkDirectory? network;
  final NodeApiClient Function(String url) _clientFor;
  final DateTime Function() _clock;
  final Duration timeout;

  /// The public nodes' median tip of a chain, when status.btlabs.uk gives none (own nodes).
  final Future<PublicTip?> Function(String? chain)? publicTip;

  /// Each own node's height at its last answer: a height that moves is a node syncing.
  final Map<String, int> _lastHeight = {};

  /// Whether a request to a node goes through tor now; a node on this computer never does.
  final bool Function() _overTor;

  /// Kept apart by route: a direct figure from before Tor came on is never shown as Tor's.
  final Map<(String, bool), List<int>> _latencies = {};

  /// A node on this computer, the local network or a tailnet is never asked over Tor.
  bool _torFor(String url) => _overTor() && !isLoopbackUrl(Uri.tryParse(url) ?? Uri()) && !isLocalNodeUrl(url);

  /// Over Tor a circuit takes seconds to build: a slow answer is not a node that is down.
  Duration get _wait => _overTor() && timeout < torNodeTimeout ? torNodeTimeout : timeout;
  DateTime? _reachedAt;

  /// When the monitor last answered.
  DateTime? get directoryReachedAt => _reachedAt;

  /// The median of the last three latencies this computer measured for [url], or null.
  int? measuredLatency(String url) {
    final l = _latencies[(url, _torFor(url))];
    if (l == null || l.isEmpty) return null;
    final sorted = [...l]..sort();
    return sorted[sorted.length ~/ 2];
  }

  void _noteLatency(String url, int ms) {
    final l = _latencies.putIfAbsent((url, _torFor(url)), () => []);
    l.add(ms);
    if (l.length > 3) l.removeAt(0);
  }

  /// [chain] is the monitor's chain name ("mainnet", "floonet"); null skips the monitor
  /// (usernet has none). A node on this computer, the local network or a VPN, or one the user
  /// marked as theirs ([mine]), is asked directly: the monitor gives only the network's tip.
  Future<NodeInfo> info(String url, {required String? chain, bool mine = false}) async {
    final cls = nodeClassOf(url, mine: mine);
    NodeStatus? listed;
    NetworkStatus? net;
    var answered = false;
    if (chain != null) {
      if (!cls.own) {
        try {
          listed = nodeStatusFor(await nodes.nodes(chain).timeout(_wait), url);
          _reachedAt = _clock();
          answered = true;
        } on Object {
          // the monitor is down: limited info
        }
      }
      try {
        net = await network?.network(chain).timeout(_wait);
      } on Object {
        // no network context
      }
    }
    if (listed != null) return _fromMonitor(url, listed, net, await _measure(url));
    final https = Uri.tryParse(url.trim())?.scheme == 'https';
    return _limited(url, net, cls: cls.own ? cls : (answered && https ? NodeClass.ownServer : NodeClass.public), chain: chain);
  }

  /// One timed `get_tip` for this computer's latency; the median so far, or null.
  Future<int?> _measure(String url) async {
    try {
      final api = _clientFor(url);
      final watch = Stopwatch()..start();
      await api.tip().timeout(_wait);
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
      latencyOverTor: measured != null && _torFor(url),
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

  Future<NodeInfo> _limited(String url, NetworkStatus? net, {NodeClass cls = NodeClass.public, String? chain}) async {
    final own = cls.own;
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
        nodeClass: cls,
        head: own ? NodeHead.down : null,
      );
    }
    final watch = Stopwatch()..start();
    final NodeTipInfo tip;
    try {
      tip = await api.tip().timeout(_wait);
    } on Object catch (e) {
      return NodeInfo(
        url: url,
        source: NodeInfoSource.none,
        at: _clock(),
        state: NodeHealthState.down,
        network: net,
        directoryReachedAt: _reachedAt,
        error: e is NodeRpcException ? e.kind.name : e.runtimeType.toString(),
        nodeClass: cls,
        head: own ? NodeHead.down : null,
      );
    }
    _noteLatency(url, watch.elapsedMilliseconds);
    Future<T?> quiet<T>(Future<T?> Function() call) async {
      try {
        return await call().timeout(_wait);
      } on Object {
        return null;
      }
    }

    final (ready, version, time, pool) = await (
      quiet(api.readyForTxs),
      quiet(() async => (await api.version()).nodeVersion),
      quiet(() => api.headerTime(tip.height)),
      own ? quiet(api.poolSize) : Future<int?>.value(),
    ).wait;
    // An own node's reference tip never comes from the node itself: the monitor's, else the
    // public nodes' median.
    var netTip = net?.tipHeight;
    TipReference? tipFrom = netTip == null ? null : TipReference.statusSite;
    int? tipNodes;
    if (own && netTip == null && publicTip != null) {
      final p = await quiet(() => publicTip!(chain));
      if (p != null) {
        netTip = p.tip;
        tipFrom = TipReference.publicNodes;
        tipNodes = p.nodes;
      }
    }
    final behind = netTip != null ? netTip - tip.height : null;
    // Healthy: ready, past 0, and at the tip as far as it can be told: within 10 blocks of the
    // monitor's tip, else (no tip known) a last block under 30 minutes old. A node before 4.1.0
    // says nothing about readiness, so the age is all there is.
    final stale = behind != null
        ? behind > 10
        : (time != null && _clock().toUtc().difference(time) > const Duration(minutes: 30));
    final previous = _lastHeight[url];
    if (own) _lastHeight[url] = tip.height;
    final moved = previous != null && tip.height > previous;
    final NodeHead? head = !own
        ? null
        : ready == false || tip.height == 0
        ? NodeHead.syncing
        : stale
        ? (moved ? NodeHead.syncing : NodeHead.behind)
        : NodeHead.synced;
    return NodeInfo(
      url: url,
      source: NodeInfoSource.limited,
      at: _clock(),
      nodeClass: cls,
      head: head,
      poolSize: pool,
      tipFrom: own ? tipFrom : null,
      tipNodes: tipNodes,
      state: ready == false || tip.height == 0 || stale ? NodeHealthState.degraded : NodeHealthState.healthy,
      height: tip.height,
      networkHeight: netTip,
      blocksBehind: behind,
      version: version,
      releasedVersion: net?.releasedNodeVersion,
      latencyMs: measuredLatency(url),
      latencyOverTor: _torFor(url),
      directoryReachedAt: _reachedAt,
      readyForTxs: ready,
      tipTime: time,
      network: net,
    );
  }
}
