// SPDX-License-Identifier: Apache-2.0
/// What an Epic node's JSON-RPC API answers, as typed values, and the parsers that read them.
///
/// Shapes are those of epic-server 4.1.0 (`api/src/types.rs`, `p2p/src/types.rs`,
/// `p2p/src/store.rs`), checked against a running node; the fixtures are in
/// `test/fixtures/node/`. Each parser takes the `Ok` payload of a reply and throws
/// [NodeRpcException] with [NodeRpcError.badResponse] when the shape is wrong.
library;

/// Why a node call failed.
enum NodeRpcError {
  /// No connection: refused, DNS, TLS, reset.
  unreachable,
  timeout,

  /// HTTP 401: no secret, or the wrong one.
  unauthorized,

  /// The node does not know the method (an older node), or the path (HTTP 404).
  methodNotFound,

  /// A bad argument, found here before sending or by the node (JSON-RPC -32602).
  invalidArgument,

  /// The node answered `Err` (e.g. ban of an unknown peer).
  nodeError,

  /// Not the JSON the node should answer.
  badResponse,
}

class NodeRpcException implements Exception {
  const NodeRpcException(this.kind, this.message);

  final NodeRpcError kind;

  /// For the log. Never holds the secret.
  final String message;

  @override
  String toString() => 'NodeRpcException(${kind.name}: $message)';
}

Never _bad(String what) =>
    throw NodeRpcException(NodeRpcError.badResponse, what);

Map<String, Object?> _map(Object? v, String what) =>
    v is Map ? v.cast<String, Object?>() : _bad('$what: not an object');

int _int(Object? v, String what) => v is num ? v.toInt() : _bad('$what: not a number');

int? _intOrNull(Object? v) => v is num ? v.toInt() : null;

String _str(Object? v, String what) => v is String ? v : _bad('$what: not a string');

/// Seconds since the epoch, 0 meaning never.
DateTime? _unixOrNull(Object? v) =>
    v is num && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000, isUtc: true) : null;

/// `{cuckaroo: 4, cuckatoo: 16384, progpow: ..., randomx: ...}`; entries that are not whole numbers
/// are left out (the values pass 2^53, which is fine for the VM's 64-bit ints).
Map<String, int> _difficulty(Object? v) {
  if (v is! Map) return const {};
  // Some versions wrap it as {"num": {...}}.
  final m = v['num'] is Map ? v['num'] as Map : v;
  return {
    for (final e in m.entries)
      if (e.key is String && e.value is int) e.key as String: e.value as int,
  };
}

/// `get_version` (foreign) and `GET /v1/version`.
class NodeVersionInfo {
  const NodeVersionInfo(this.nodeVersion, {this.blockHeaderVersion});

  /// "4.1.0".
  final String nodeVersion;
  final int? blockHeaderVersion;
}

NodeVersionInfo parseVersion(Object? ok) {
  final m = _map(ok, 'version');
  return NodeVersionInfo(
    _str(m['node_version'], 'version.node_version'),
    blockHeaderVersion: _intOrNull(m['block_header_version']),
  );
}

/// `get_tip` (foreign), and the `tip` of a status.
class NodeTipInfo {
  const NodeTipInfo(this.height, {this.lastBlockHash, this.totalDifficulty = const {}});

  final int height;
  final String? lastBlockHash;

  /// Per proof-of-work algorithm.
  final Map<String, int> totalDifficulty;
}

NodeTipInfo parseTip(Object? ok) {
  final m = _map(ok, 'tip');
  return NodeTipInfo(
    _int(m['height'], 'tip.height'),
    lastBlockHash: m['last_block_pushed'] as String?,
    totalDifficulty: _difficulty(m['total_difficulty']),
  );
}

/// `ready_for_txs` (foreign, node 4.1.0 and later): true only when the node is fully synced.
bool parseReadyForTxs(Object? ok) {
  final v = _map(ok, 'ready_for_txs')['ready_for_txs'];
  return v is bool ? v : _bad('ready_for_txs: not a bool');
}

/// `get_header` (foreign): the block time of the header, or null when it has none.
DateTime? parseHeaderTime(Object? ok) {
  final t = _map(ok, 'header')['timestamp'];
  return t is String ? DateTime.tryParse(t)?.toUtc() : null;
}

/// The `sync_info` of a status; which fields are set depends on the sync status.
class NodeSyncInfo {
  const NodeSyncInfo({
    this.currentHeight,
    this.highestHeight,
    this.downloadedBytes,
    this.totalBytes,
    this.kernels,
    this.kernelsTotal,
    this.rangeProofs,
    this.rangeProofsTotal,
  });

  /// `header_sync`, `body_sync`.
  final int? currentHeight;
  final int? highestHeight;

  /// `txhashset_download`.
  final int? downloadedBytes;
  final int? totalBytes;

  /// `txhashset_kernels_validation`.
  final int? kernels;
  final int? kernelsTotal;

  /// `txhashset_rangeproofs_validation`.
  final int? rangeProofs;
  final int? rangeProofsTotal;
}

NodeSyncInfo? _syncInfo(Object? v) {
  if (v is! Map) return null;
  return NodeSyncInfo(
    currentHeight: _intOrNull(v['current_height']),
    highestHeight: _intOrNull(v['highest_height']),
    downloadedBytes: _intOrNull(v['downloaded_size']),
    totalBytes: _intOrNull(v['total_size']),
    kernels: _intOrNull(v['kernels']),
    kernelsTotal: _intOrNull(v['kernels_total']),
    rangeProofs: _intOrNull(v['rproofs']),
    rangeProofsTotal: _intOrNull(v['rproofs_total']),
  );
}

/// `get_status` (owner) and `GET /v1/status`. A failover for readiness, tip and version (nodes
/// will drop it), but the only source of the sync stage.
class NodeStatusInfo {
  const NodeStatusInfo({
    required this.protocolVersion,
    required this.userAgent,
    required this.connections,
    required this.tip,
    required this.syncStatus,
    this.syncInfo,
  });

  final int protocolVersion;

  /// "MW/Epic 4.1.0".
  final String userAgent;
  final int connections;
  final NodeTipInfo tip;

  /// `no_sync`, `awaiting_peers`, `header_sync`, `txhashset_download`,
  /// `txhashset_rangeproofs_validation`, `txhashset_kernels_validation`, `body_sync`,
  /// `shutdown`, `compacting`, or `syncing` (any other step).
  final String syncStatus;
  final NodeSyncInfo? syncInfo;

  /// The version in [userAgent] ("4.1.0" of "MW/Epic 4.1.0"), or null.
  String? get version => RegExp(r'(\d+\.\d+\.\d+(?:[-.][0-9A-Za-z]+)*)\s*$').firstMatch(userAgent)?[1];
}

NodeStatusInfo parseStatus(Object? ok) {
  final m = _map(ok, 'status');
  return NodeStatusInfo(
    protocolVersion: _int(m['protocol_version'], 'status.protocol_version'),
    userAgent: _str(m['user_agent'], 'status.user_agent'),
    connections: _int(m['connections'], 'status.connections'),
    tip: parseTip(m['tip']),
    syncStatus: _str(m['sync_status'], 'status.sync_status'),
    syncInfo: _syncInfo(m['sync_info']),
  );
}

enum PeerDirection { inbound, outbound, unknown }

/// One entry of `get_connected_peers` (owner). The node gives no ping, connected-since or byte
/// counts.
class ConnectedPeer {
  const ConnectedPeer({
    required this.addr,
    required this.direction,
    required this.userAgent,
    required this.protocolVersion,
    required this.height,
    this.totalDifficulty = const {},
    this.onionAddr,
    this.capabilities = '',
  });

  /// "ip:port" ("[v6]:port").
  final String addr;
  final PeerDirection direction;

  /// "MW/Epic 4.1.0".
  final String userAgent;
  final int protocolVersion;

  /// As the peer advertises it, unverified.
  final int height;
  final Map<String, int> totalDifficulty;
  final String? onionAddr;

  /// "HEADER_HIST | TXHASHSET_HIST | ...".
  final String capabilities;
}

List<ConnectedPeer> parseConnectedPeers(Object? ok) {
  if (ok is! List) _bad('connected peers: not a list');
  return [
    for (final (i, item) in ok.indexed)
      () {
        final m = _map(item, 'peer $i');
        return ConnectedPeer(
          addr: _str(m['addr'], 'peer $i addr'),
          direction: switch (m['direction']) {
            'Inbound' => PeerDirection.inbound,
            'Outbound' => PeerDirection.outbound,
            _ => PeerDirection.unknown,
          },
          userAgent: m['user_agent'] as String? ?? '',
          protocolVersion: _intOrNull(m['version']) ?? 0,
          height: _intOrNull(m['height']) ?? 0,
          totalDifficulty: _difficulty(m['total_difficulty']),
          onionAddr: m['onion_addr'] as String?,
          capabilities: m['capabilities'] as String? ?? '',
        );
      }(),
  ];
}

enum PeerFlag { healthy, banned, defunct, unknown }

/// One entry of `get_peers` (owner): a peer the node knows of, connected or not.
class StoredPeer {
  const StoredPeer({
    required this.addr,
    required this.flag,
    this.banReason = 'None',
    this.userAgent = '',
    this.lastBanned,
    this.lastConnected,
    this.capabilities = '',
  });

  final String addr;
  final PeerFlag flag;

  /// "None", "ManualBan", "BadBlock", "BadCompactBlock", "BadBlockHeader", "BadTxHashSet",
  /// "FraudHeight", "BadHandshake".
  final String banReason;
  final String userAgent;
  final DateTime? lastBanned;
  final DateTime? lastConnected;
  final String capabilities;

  bool get banned => flag == PeerFlag.banned;
}

List<StoredPeer> parseStoredPeers(Object? ok) {
  if (ok is! List) _bad('peers: not a list');
  return [
    for (final (i, item) in ok.indexed)
      () {
        final m = _map(item, 'peer $i');
        return StoredPeer(
          addr: _str(m['addr'], 'peer $i addr'),
          flag: switch (m['flags']) {
            'Healthy' => PeerFlag.healthy,
            'Banned' => PeerFlag.banned,
            'Defunct' => PeerFlag.defunct,
            _ => PeerFlag.unknown,
          },
          banReason: m['ban_reason'] as String? ?? 'None',
          userAgent: m['user_agent'] as String? ?? '',
          lastBanned: _unixOrNull(m['last_banned']),
          lastConnected: _unixOrNull(m['last_connected']),
          capabilities: m['capabilities'] as String? ?? '',
        );
      }(),
  ];
}
