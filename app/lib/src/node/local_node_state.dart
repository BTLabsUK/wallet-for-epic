/// The local (built-in) node as the app shows it: one phase, the sync progress, the network
/// height it is measured against, and the node's folder and disk. Pure: [deriveLocalNodeState]
/// maps a [BuiltInNodeState] plus what else is known onto it.
library;

import 'dart:math';

import '../builtin_node.dart';
import 'node_settings.dart' show ChainDataOrigin;
import 'sync_progress.dart';

enum LocalNodePhase { stopped, starting, syncing, synced, error }

/// A node at most this many blocks under the network's tip counts as synced.
const int syncedWithinBlocks = 10;

class LocalNodeState {
  const LocalNodeState({
    required this.phase,
    required this.dataFolder,
    required this.chainDataPath,
    required this.at,
    this.progress,
    this.eta,
    this.stageRate,
    this.height,
    this.networkHeight,
    this.blocksBehind,
    this.readyForTxs,
    this.version,
    this.startedAt,
    this.uptime,
    this.chainDataBytes,
    this.chainDataBytesAtStart,
    this.freeBytes,
    this.peers,
    this.failure,
    this.reason,
    this.stalled = false,
    this.restartNeeded = false,
    this.userToml = false,
    this.chainDataOrigin = ChainDataOrigin.own,
  });

  final LocalNodePhase phase;

  /// The sync stage and progress, when the node gave its status.
  final SyncProgress? progress;

  /// Time left in the current stage at the recent rate.
  final Duration? eta;

  /// The recent rate in the stage's own units per second: bytes/s while the chain state
  /// downloads ("download rate"), headers/s, blocks/s, items/s.
  final double? stageRate;

  /// The node's own tip.
  final int? height;

  /// The network's tip as best known (the node's highest height, its peers', the directory's).
  final int? networkHeight;

  /// [networkHeight] - [height], never below 0; null when either is unknown.
  final int? blocksBehind;

  /// The node's `ready_for_txs`; null on a node before 4.1.0 or when it did not answer.
  final bool? readyForTxs;
  final String? version;

  /// When the running process was spawned, and how long ago.
  final DateTime? startedAt;
  final Duration? uptime;

  /// The node's folder (toml, secret, log) and its chain data folder.
  final String dataFolder;
  final String chainDataPath;

  /// Size of [chainDataPath], measured every few minutes.
  final int? chainDataBytes;

  /// The first [chainDataBytes] measured in this session, for "grew by ... this session".
  final int? chainDataBytesAtStart;

  /// Free space on the volume of [chainDataPath].
  final int? freeBytes;

  /// Connected peers.
  final int? peers;

  final NodeFailure? failure;
  final String? reason;

  /// The node stopped making progress and the watchdog's one restart did not help.
  final bool stalled;

  /// Node settings changed that apply after a restart.
  final bool restartNeeded;

  /// The toml is the user's own; the app's node settings do not apply.
  final bool userToml;

  /// When this state was derived.
  final DateTime at;

  /// The node can be used for the wallet: synced to the network and ready for transactions.
  bool get online => phase == LocalNodePhase.synced;

  /// Whose chain data the node runs on.
  final ChainDataOrigin chainDataOrigin;

  /// The node runs on another node's folder in place: "Delete chain data" is off for it (and
  /// refused by [NodeMaintenance.deleteChainData]).
  bool get chainDataReused => chainDataOrigin == ChainDataOrigin.pointed;

  @override
  bool operator ==(Object other) =>
      other is LocalNodeState &&
      other.phase == phase &&
      other.progress == progress &&
      other.eta == eta &&
      other.stageRate == stageRate &&
      other.height == height &&
      other.networkHeight == networkHeight &&
      other.blocksBehind == blocksBehind &&
      other.readyForTxs == readyForTxs &&
      other.version == version &&
      other.startedAt == startedAt &&
      other.uptime == uptime &&
      other.dataFolder == dataFolder &&
      other.chainDataPath == chainDataPath &&
      other.chainDataBytes == chainDataBytes &&
      other.chainDataBytesAtStart == chainDataBytesAtStart &&
      other.freeBytes == freeBytes &&
      other.peers == peers &&
      other.failure == failure &&
      other.reason == reason &&
      other.stalled == stalled &&
      other.restartNeeded == restartNeeded &&
      other.userToml == userToml &&
      other.chainDataOrigin == chainDataOrigin &&
      other.at == at;

  @override
  int get hashCode => Object.hashAll([
    phase,
    progress,
    eta,
    stageRate,
    height,
    networkHeight,
    blocksBehind,
    readyForTxs,
    version,
    startedAt,
    uptime,
    dataFolder,
    chainDataPath,
    chainDataBytes,
    chainDataBytesAtStart,
    freeBytes,
    peers,
    failure,
    reason,
    stalled,
    restartNeeded,
    userToml,
    chainDataOrigin,
    at,
  ]);

  @override
  String toString() =>
      'LocalNodeState(${phase.name}, height: $height/$networkHeight, behind: $blocksBehind, '
      'ready: $readyForTxs, progress: $progress, eta: $eta, peers: $peers, '
      'failure: $failure, reason: $reason, stalled: $stalled, restartNeeded: $restartNeeded)';
}

/// The app's view of the node. The rules (never "Online" at height 0):
///
/// | node state        | condition                                                  | phase    |
/// |-------------------|------------------------------------------------------------|----------|
/// | off, stopped      |                                                            | stopped  |
/// | starting          |                                                            | starting |
/// | syncing           |                                                            | syncing  |
/// | running           | ready (true, or null with sync status no_sync), height > 0 | synced   |
/// |                   | peers > 0 (when known), and network height unknown or at   |          |
/// |                   | most 10 blocks behind                                      |          |
/// | running           | otherwise                                                  | syncing  |
/// | stalled           | stalled = true, reason kept                                | error    |
/// | failed            | failure and reason                                         | error    |
LocalNodeState deriveLocalNodeState(
  BuiltInNodeState s, {
  required DateTime now,
  required String dataFolder,
  required String chainDataPath,
  int? directoryTip,
  int? peersHeight,
  Duration? eta,
  double? stageRate,
  int? chainDataBytes,
  int? chainDataBytesAtStart,
  int? freeBytes,
  DateTime? startedAt,
  bool restartNeeded = false,
  bool userToml = false,
  ChainDataOrigin chainDataOrigin = ChainDataOrigin.own,
}) {
  final status = s.status;
  final height = s.height ?? status?.tip.height;
  final networkHeight = networkTipOf(
    highestHeight: s.highest ?? status?.syncInfo?.highestHeight,
    peersHeight: peersHeight,
    directoryTip: directoryTip,
  );
  final behind = height != null && networkHeight != null
      ? max(0, networkHeight - height)
      : null;
  final connections = s.connections ?? status?.connections;
  final ready =
      s.readyForTxs == true ||
      (s.readyForTxs == null && status?.syncStatus == 'no_sync');
  final phase = switch (s.kind) {
    NodeStatusKind.off || NodeStatusKind.stopped => LocalNodePhase.stopped,
    NodeStatusKind.starting => LocalNodePhase.starting,
    NodeStatusKind.syncing => LocalNodePhase.syncing,
    // A node without peers says no_sync (and ready) at whatever height it had: not synced.
    NodeStatusKind.running =>
      ready &&
              (height ?? 0) > 0 &&
              (connections == null || connections > 0) &&
              (behind == null || behind <= syncedWithinBlocks)
          ? LocalNodePhase.synced
          : LocalNodePhase.syncing,
    NodeStatusKind.stalled || NodeStatusKind.failed => LocalNodePhase.error,
  };
  final live = phase != LocalNodePhase.stopped && phase != LocalNodePhase.error;
  final since = live || s.kind == NodeStatusKind.stalled ? startedAt : null;
  return LocalNodeState(
    phase: phase,
    progress: status == null
        ? null
        : progressOf(
            status,
            networkHeight: networkTipOf(peersHeight: peersHeight, directoryTip: directoryTip),
          ),
    eta: phase == LocalNodePhase.syncing ? eta : null,
    stageRate: phase == LocalNodePhase.syncing ? stageRate : null,
    height: height,
    networkHeight: networkHeight,
    blocksBehind: behind,
    readyForTxs: s.readyForTxs,
    version: s.version,
    startedAt: since,
    uptime: since == null ? null : now.difference(since),
    dataFolder: dataFolder,
    chainDataPath: chainDataPath,
    chainDataBytes: chainDataBytes,
    chainDataBytesAtStart: chainDataBytesAtStart,
    freeBytes: freeBytes,
    peers: s.connections ?? status?.connections,
    failure: s.failure,
    reason: s.reason,
    stalled: s.kind == NodeStatusKind.stalled,
    restartNeeded: restartNeeded,
    userToml: userToml,
    chainDataOrigin: chainDataOrigin,
    at: now,
  );
}
