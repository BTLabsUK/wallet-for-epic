/// How far a syncing node is: its stage, the stage's own progress, a rough overall progress, and
/// an ETA from the recent rate. Pure: the node's status in, values out.
library;

import 'dart:math';

import 'node_api_types.dart';

/// The sync stages of an Epic node, in the order a fresh node goes through them (header sync,
/// chain state download and validation, then blocks).
enum SyncStage {
  /// `awaiting_peers`.
  waitingForPeers,

  /// `header_sync`.
  headers,

  /// `txhashset_download`: the chain state, in bytes.
  chainStateDownload,

  /// `txhashset_kernels_validation`.
  chainStateKernels,

  /// `txhashset_rangeproofs_validation`.
  chainStateRangeProofs,

  /// `syncing`: the node's catch-all (chain state setup and save, the first moments).
  chainStateProcessing,

  /// `body_sync`.
  blocks,

  /// `no_sync`.
  synced,
  compacting,
  shuttingDown,

  /// Anything this app does not know.
  unknown,
}

/// The stage of a `sync_status` string.
SyncStage stageOf(String syncStatus) => switch (syncStatus) {
  'awaiting_peers' => SyncStage.waitingForPeers,
  'header_sync' => SyncStage.headers,
  'txhashset_download' => SyncStage.chainStateDownload,
  'txhashset_kernels_validation' => SyncStage.chainStateKernels,
  'txhashset_rangeproofs_validation' => SyncStage.chainStateRangeProofs,
  'syncing' => SyncStage.chainStateProcessing,
  'body_sync' => SyncStage.blocks,
  'no_sync' => SyncStage.synced,
  'compacting' => SyncStage.compacting,
  'shutdown' => SyncStage.shuttingDown,
  _ => SyncStage.unknown,
};

/// Share of the whole sync per stage, for [SyncProgress.overall]. ROUGH: guessed from a mainnet
/// sync (headers and the chain state download take most of the time, blocks after a fast sync a
/// fifth), not measured per machine. They add up to 1, in stage order.
const Map<SyncStage, double> syncStageWeights = {
  SyncStage.headers: 0.30,
  SyncStage.chainStateDownload: 0.30,
  SyncStage.chainStateKernels: 0.05,
  SyncStage.chainStateRangeProofs: 0.10,
  SyncStage.chainStateProcessing: 0.05,
  SyncStage.blocks: 0.20,
};

/// Where the stage starts in the overall progress (the weights of the stages before it).
double? _stageStart(SyncStage stage) {
  if (!syncStageWeights.containsKey(stage)) return null;
  var sum = 0.0;
  for (final e in syncStageWeights.entries) {
    if (e.key == stage) return sum;
    sum += e.value;
  }
  return sum;
}

class SyncProgress {
  const SyncProgress(
    this.stage, {
    this.stageFraction,
    this.overall,
    this.done,
    this.total,
  });

  final SyncStage stage;

  /// 0..1 within the stage, or null when the stage has no measure.
  final double? stageFraction;

  /// 0..1 over the whole sync, weighted by [syncStageWeights] (rough). Null when the stage does
  /// not tell where the node is (waiting for peers, chain state processing, unknown, compacting,
  /// shutting down).
  final double? overall;

  /// In the stage's own units: heights (headers, blocks), bytes (chain state download) or items
  /// (kernels, range proofs).
  final int? done;
  final int? total;

  @override
  bool operator ==(Object other) =>
      other is SyncProgress &&
      other.stage == stage &&
      other.stageFraction == stageFraction &&
      other.overall == overall &&
      other.done == done &&
      other.total == total;

  @override
  int get hashCode => Object.hash(stage, stageFraction, overall, done, total);

  @override
  String toString() =>
      'SyncProgress(${stage.name}, stage: $stageFraction, overall: $overall, $done/$total)';
}

/// The progress of a node by its status. [networkHeight] is the network's tip as known from
/// the peers or the monitor ([networkTipOf] without the node's own highest height): during
/// header sync the node's `highest_height` is only the target of the batch it asks for (a few
/// thousand ahead), so headers are measured against [networkHeight] and have no fraction until it
/// is known. Blocks use the higher of the two.
SyncProgress progressOf(NodeStatusInfo s, {int? networkHeight}) {
  final stage = stageOf(s.syncStatus);
  final i = s.syncInfo;
  int? atLeast(int? a, int? b) => a == null ? b : (b == null ? a : max(a, b));
  final (done, total) = switch (stage) {
    SyncStage.headers => (
      i?.currentHeight,
      networkHeight == null ? null : atLeast(networkHeight, i?.highestHeight),
    ),
    SyncStage.blocks => (
      i?.currentHeight,
      atLeast(i?.highestHeight, networkHeight),
    ),
    SyncStage.chainStateDownload => (i?.downloadedBytes, i?.totalBytes),
    SyncStage.chainStateKernels => (i?.kernels, i?.kernelsTotal),
    SyncStage.chainStateRangeProofs => (i?.rangeProofs, i?.rangeProofsTotal),
    _ => (null, null),
  };
  if (stage == SyncStage.synced) {
    return SyncProgress(
      stage,
      stageFraction: 1,
      overall: 1,
      done: s.tip.height,
      total: s.tip.height,
    );
  }
  final fraction = done != null && total != null && total > 0
      ? (done / total).clamp(0.0, 1.0)
      : null;
  final start = _stageStart(stage);
  final overall = start != null && fraction != null
      ? (start + syncStageWeights[stage]! * fraction).clamp(0.0, 1.0)
      : null;
  return SyncProgress(
    stage,
    stageFraction: fraction,
    overall: overall,
    done: done,
    total: total,
  );
}

/// The network's tip as best known while syncing: the highest of the node's own highest height,
/// its peers' and the directory's. Null when none is known.
int? networkTipOf({int? highestHeight, int? peersMaxHeight, int? directoryTip}) {
  final known = [
    highestHeight,
    peersMaxHeight,
    directoryTip,
  ].whereType<int>().where((h) => h > 0);
  return known.isEmpty ? null : known.reduce(max);
}

/// The time left in a stage, from the rate over a sliding window of samples.
class EtaEstimator {
  EtaEstimator({
    this.window = const Duration(minutes: 2),
    this.minSpan = const Duration(seconds: 20),
  });

  /// Samples older than this (before the newest) are dropped.
  final Duration window;

  /// The samples must span at least this before a rate is given.
  final Duration minSpan;

  final List<({DateTime at, int done})> _samples = [];
  SyncStage? _stage;
  int? _total;

  /// One reading of the stage; [total] may be unknown (no ETA then, the rate still counts) and
  /// may move (the network grows, the node learns the tip). A new stage or a count that went back
  /// starts over.
  void add(DateTime at, SyncStage stage, int done, int? total) {
    final last = _samples.isEmpty ? null : _samples.last;
    if (stage != _stage || (last != null && (done < last.done || at.isBefore(last.at)))) {
      _samples.clear();
      _stage = stage;
    }
    _total = total;
    _samples.add((at: at, done: done));
    final from = at.subtract(window);
    while (_samples.length > 2 && _samples.first.at.isBefore(from)) {
      _samples.removeAt(0);
    }
  }

  /// Forgets every sample.
  void reset() {
    _samples.clear();
    _stage = null;
    _total = null;
  }

  /// Units of the stage per second over the window, or null with fewer than 2 samples, a span
  /// under [minSpan] or no progress.
  double? ratePerSecond() {
    if (_samples.length < 2) return null;
    final first = _samples.first;
    final last = _samples.last;
    final span = last.at.difference(first.at);
    if (span < minSpan) return null;
    final rate = (last.done - first.done) / (span.inMilliseconds / 1000);
    return rate > 0 ? rate : null;
  }

  /// The time left at [ratePerSecond], or null when there is none.
  Duration? eta() {
    final rate = ratePerSecond();
    final total = _total;
    if (rate == null || total == null) return null;
    final left = max(0, total - _samples.last.done);
    return Duration(milliseconds: (left / rate * 1000).round());
  }
}
