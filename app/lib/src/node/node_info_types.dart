/// What [NodeInfoService] reports about a node, without the service: the web build shows these
/// and never reaches the node clients behind them.
library;

import '../net/local_address.dart' show NodeClass;
import '../relay_directory.dart';

enum NodeInfoSource {
  /// The monitor lists the node: its view (state, lag, uptime, peers, operator).
  directory,

  /// The monitor is unreachable or does not list the node: what the node itself answers.
  limited,

  /// Neither answered.
  none,
}

/// An own node's head word: Synced, Syncing, Behind, Not answering.
enum NodeHead { synced, syncing, behind, down }

/// Where an own node's reference tip came from: never the node itself.
enum TipReference {
  /// status.btlabs.uk's network tip.
  statusSite,

  /// The median tip of the public nodes the app could reach.
  publicNodes,
}

/// The network tip from the public nodes and how many gave it, for an own node's "behind"
/// when status.btlabs.uk does not answer.
typedef PublicTip = ({int tip, int nodes});

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
    this.latencyOverTor = false,
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
    this.nodeClass = NodeClass.public,
    this.poolSize,
    this.head,
    this.tipFrom,
    this.tipNodes,
  });

  final String url;
  final NodeInfoSource source;
  final DateTime at;

  /// The monitor's verdict; for limited info: healthy when the node answers, is ready and at the
  /// tip (10 blocks of the monitor's tip, or a last block under 30 min old), degraded when it
  /// answers otherwise, down when it does not answer.
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

  /// [latencyMs] was measured through tor (the Tor switch is on): never a direct figure then.
  final bool latencyOverTor;

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

  /// What the node is to the user; an own class is asked directly, never the monitor.
  final NodeClass nodeClass;

  /// Own nodes: the transactions waiting in its mempool (`get_pool_size`).
  final int? poolSize;

  /// Own nodes: the head word.
  final NodeHead? head;

  /// Own nodes: where [networkHeight] came from, and how many public nodes gave it.
  final TipReference? tipFrom;
  final int? tipNodes;

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
