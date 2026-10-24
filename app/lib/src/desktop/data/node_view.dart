/// What the node screens say about a node: one word, a state, the rail's second line and the
/// tooltip's lines (spec §16), the local node's stage line and time left (§15.2). Pure, so the
/// rail, the node card and the local node panel say the same thing.
library;

import '../../address_format.dart' show railHost;
import '../../builtin_node.dart' show NodeStartException;
import '../../l10n.dart' show AppLocalizations, localDigits, localInt;
import '../widgets/status.dart' show EState;
import 'desk_node.dart';
import 'models.dart' show ServiceHealth;

/// One node as the rail and the panels show it.
class NodeView {
  const NodeView({
    required this.word,
    required this.state,
    required this.host,
    this.marker,
    this.lines = const [],
  });

  /// Synced, Behind, Not answering, Checking, Starting, Syncing, Stalled, Failed, Stopped.
  final String word;
  final EState state;

  /// The rail's host part ([railHost] applied), or "Local node".
  final String host;

  /// After the host, never cut: "12 behind", "no answer", "12 %", "stalled".
  final String? marker;

  /// The tooltip's lines, only the known ones.
  final List<String> lines;

  String get second => marker == null ? host : '$host · $marker';
}

/// 2914414 → "2,914,414" (`2.914.414` in German), for text shown.
String digits(AppLocalizations l, int n) => localInt(l, n);

String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// "12 %" of an overall progress 0–1 (floored: never 100 % before Synced).
String percent(double overall) => '${(overall * 100).floor().clamp(0, 99)} %';

/// [i]'s latency as shown, or null: while Tor is on ([torOn]) a figure this computer measured
/// directly is never shown, only one over Tor or the monitor's.
int? shownLatency(NodeInfo i, {bool torOn = false}) =>
    torOn && !i.latencyOverTor && !i.latencyFromMonitor && !isLocalNodeUrl(i.url) ? null : i.latencyMs;

/// A remote node from its [NodeInfo] (null: nothing known yet). [health] is the wallet's own
/// view when the info has not come in. A node the wallet itself reaches ([health] ok: its tip
/// check or a sync answered) is never "Not answering" because the info probe failed, as one
/// over Tor can while the wallet syncs through it.
NodeView remoteNodeView(AppLocalizations l, String url, NodeInfo? info, {ServiceHealth? health, DateTime? downSince, bool torOn = false}) {
  final full = nodeHost(url);
  final host = railHost('Node', full); // l10n-ok: railHost's kind key
  final probeFailed = info?.state == NodeHealthState.down || info?.source == NodeInfoSource.none;
  if (probeFailed && health == ServiceHealth.ok) return NodeView(word: l.deskNodeSynced, state: EState.ok, host: host, lines: [full]);
  final down = health == ServiceHealth.down || probeFailed;
  if (down) {
    return NodeView(
      word: l.deskNodeNotAnswering,
      state: EState.risk,
      host: host,
      marker: l.deskNodeMarkerNoAnswer,
      lines: [downSince == null ? full : l.deskNodeHostSince(full, hhmm(downSince)), l.deskNodeNotAnsweringLine],
    );
  }
  if (info == null) return NodeView(word: l.deskNodeChecking, state: EState.off, host: host, lines: [full]);
  final behind = info.blocksBehind;
  final h = info.height;
  final old = info.updateAvailable == true;
  final latency = shownLatency(info, torOn: torOn);
  final second = [
    if (latency != null) info.latencyOverTor ? l.deskNodeLatencyOverTor(digits(l, latency)) : l.deskNodeLatency(digits(l, latency)),
    if (info.version != null) 'v${info.version}',
    if (old && info.releasedVersion != null) l.deskNodeNewerOut(info.releasedVersion!),
  ].join(' · ');
  if (behind != null && behind > syncedWithinBlocks) {
    return NodeView(
      word: l.deskNodeBehind,
      state: EState.warn,
      host: host,
      marker: l.deskNodeMarkerBehind(digits(l, behind)),
      lines: [
        [full, if (h != null && info.networkHeight != null) l.deskNodeHeightOf(digits(l, h), digits(l, info.networkHeight!))].join(' · '),
        l.deskNodeBehindLine,
      ],
    );
  }
  return NodeView(
    word: l.deskNodeSynced,
    state: old ? EState.warn : EState.ok,
    host: host,
    lines: [
      [full, if (h != null) digits(l, h), if (behind != null) l.deskNodeAtTip].join(' · '),
      if (second.isNotEmpty) second,
    ],
  );
}

/// A node URL on this computer (the local node's own address).
bool isLocalNodeUrl(String url) {
  final h = nodeHost(url).toLowerCase();
  return h == '127.0.0.1' || h == 'localhost' || h == '::1' || h == '[::1]' || h == '0.0.0.0';
}

/// The local node (§16). [fallbackUrl] is the public node the wallet actually reads through
/// meanwhile (the wallet's own node URL when it is not the local one): the second line then
/// names that node, whatever the local node's phase, and the tooltip says which is which.
NodeView localNodeView(AppLocalizations l, LocalNodeState? s, {String? fallbackUrl}) {
  final name = l.deskNodeLocal;
  final fallback = fallbackUrl == null || isLocalNodeUrl(fallbackUrl) ? null : nodeHost(fallbackUrl);
  final host = fallback != null ? railHost('Node', fallback) : name; // l10n-ok: railHost's row key
  if (s == null) return NodeView(word: l.deskNodeChecking, state: EState.off, host: host, lines: [name]);
  final p = s.progress;
  switch (s.phase) {
    case LocalNodePhase.starting:
      return NodeView(
        word: l.deskNodeStarting,
        state: EState.warn,
        host: host,
        marker: l.deskNodeMarkerStarting,
        lines: [name, l.deskNodeConnectingPeers, if (fallback != null) l.deskNodeUsingUntilSynced(fallback)],
      );
    case LocalNodePhase.syncing:
      final pct = p?.overall == null ? null : percent(p!.overall!);
      final left = p == null ? null : timeLeft(l, p.stage, s.eta);
      return NodeView(
        word: l.deskNodeSyncing,
        state: EState.warn,
        host: host,
        marker: pct,
        lines: [
          [name, ?pct, ?left].join(' · '),
          [if (p != null) stageLine(l, p), if (s.peers != null) l.deskNodePeers(s.peers!)].join(' · '),
          fallback != null ? l.deskNodeUsingUntilSynced(fallback) : l.deskNodeNothingUntilSynced,
        ].where((line) => line.isNotEmpty).toList(),
      );
    case LocalNodePhase.synced:
      return NodeView(
        word: l.deskNodeSynced,
        state: EState.ok,
        host: host,
        lines: [
          [name, if (s.height != null) digits(l, s.height!), l.deskNodeAtTip].join(' · '),
          [if (s.peers != null) l.deskNodePeers(s.peers!), if (s.version != null) 'v${s.version}', if (s.uptime != null) l.deskNodeRunning(duration(l, s.uptime!))].join(' · '),
          if (fallback != null) l.deskNodeStillUsing(fallback),
        ],
      );
    case LocalNodePhase.error:
      if (s.stalled) {
        return NodeView(
          word: l.deskNodeStalled,
          state: EState.risk,
          host: host,
          marker: l.deskNodeMarkerStalled,
          lines: [
            [name, if (s.height != null) digits(l, s.height!)].join(' · '),
            l.deskNodeNoProgress,
            if (fallback != null) l.deskNodeUsingMeanwhile(fallback),
          ],
        );
      }
      return NodeView(word: l.deskNodeFailed, state: EState.risk, host: host, marker: l.deskNodeMarkerFailed, lines: [name, failureLine(l, s), if (fallback != null) l.deskNodeUsingMeanwhile(fallback)]);
    case LocalNodePhase.stopped:
      return NodeView(
        word: l.deskNodeStopped,
        state: EState.off,
        host: host,
        marker: l.deskNodeMarkerStopped,
        lines: [name, l.deskNodeStartIt, if (fallback != null) l.deskNodeUsingMeanwhile(fallback)],
      );
  }
}

/// Why the local node failed, as a detail after the word (§19).
String failureLine(AppLocalizations l, LocalNodeState s) => switch (s.failure) {
  NodeFailure.portInUse => l.deskNodeFailPort,
  NodeFailure.diskLow => l.deskNodeFailDisk,
  NodeFailure.binaryMissing => l.deskNodeFailMissing,
  NodeFailure.exited => switch (_exitCode(s.reason)) { final code? => l.deskNodeFailExitedCode(code), _ => l.deskNodeFailExited },
  _ => s.reason ?? l.deskNodeFailDefault,
};

/// Why a start of the local node failed, as a detail ([failureLine]'s words; the exception's
/// message is English, for logs).
String startFailureLine(AppLocalizations l, NodeStartException e) => switch (e.failure) {
  NodeFailure.portInUse => l.deskNodeFailPort,
  NodeFailure.diskLow => l.deskNodeFailDisk,
  NodeFailure.binaryMissing => l.deskNodeFailMissing,
  NodeFailure.exited => switch (_exitCode(e.message)) { final code? => l.deskNodeFailExitedCode(code), _ => l.deskNodeFailExited },
  _ => l.deskNodeFailDefault,
};

String? _exitCode(String? reason) => RegExp(r'(?:exit code|code)\s*(-?\d+)').firstMatch(reason ?? '')?[1];

/// The stage's name for the panel's detail.
String stageName(AppLocalizations l, SyncStage s) => switch (s) {
  SyncStage.waitingForPeers => l.deskNodeStageWaiting,
  SyncStage.headers => l.deskNodeStageHeaders,
  SyncStage.chainStateDownload => l.deskNodeStageChainDownload,
  SyncStage.chainStateKernels => l.deskNodeStageKernels,
  SyncStage.chainStateRangeProofs => l.deskNodeStageRangeProofs,
  SyncStage.chainStateProcessing => l.deskNodeStageProcessing,
  SyncStage.blocks => l.deskNodeStageBlocks,
  SyncStage.compacting => l.deskNodeStageCompacting,
  SyncStage.shuttingDown => l.deskNodeStageStopping,
  SyncStage.synced || SyncStage.unknown => l.deskNodeStageSyncing,
};

String _gb(int bytes) => (bytes / 1e9).toStringAsFixed(1);

String _millions(int n) => (n / 1e6).toStringAsFixed(1);

/// The stage line: the stage in its own units, never a second percentage (§15.2).
String stageLine(AppLocalizations l, SyncProgress p) {
  final d = p.done, t = p.total;
  final known = d != null && t != null && t > 0;
  return switch (p.stage) {
    SyncStage.waitingForPeers => l.deskNodeLineWaiting,
    SyncStage.headers => known ? l.deskNodeLineHeaders(digits(l, d), digits(l, t)) : l.deskNodeLineHeadersBare,
    SyncStage.chainStateDownload => known ? l.deskNodeLineChain(localDigits(l, _gb(d)), localDigits(l, _gb(t))) : l.deskNodeLineChainBare,
    SyncStage.chainStateKernels => known ? l.deskNodeLineKernels(_millions(d), _millions(t)) : l.deskNodeLineKernelsBare,
    SyncStage.chainStateRangeProofs => known ? l.deskNodeLineRangeProofs(_millions(d), _millions(t)) : l.deskNodeLineRangeProofsBare,
    SyncStage.chainStateProcessing => l.deskNodeLineProcessing,
    SyncStage.blocks => known ? l.deskNodeLineBlocks(digits(l, d), digits(l, t)) : l.deskNodeLineBlocksBare,
    SyncStage.compacting => l.deskNodeLineCompacting,
    SyncStage.shuttingDown => l.deskNodeLineStopping,
    SyncStage.synced || SyncStage.unknown => l.deskNodeLineSyncing,
  };
}

/// "about 3 h left", "about 12 min left", "estimating…", or the fixed text of the checks.
String? timeLeft(AppLocalizations l, SyncStage stage, Duration? eta) {
  switch (stage) {
    case SyncStage.chainStateKernels || SyncStage.chainStateRangeProofs || SyncStage.chainStateProcessing:
      return l.deskNodeNoEstimate;
    case SyncStage.headers || SyncStage.chainStateDownload || SyncStage.blocks:
      if (eta == null) return l.deskNodeEstimating;
      final min = (eta.inSeconds / 60).ceil();
      return min > 90 ? l.deskNodeAboutHours((min / 60).round()) : l.deskNodeAboutMinutes(min < 1 ? 1 : min);
    default:
      return null;
  }
}

/// "9 h 40 min", "2 min".
String duration(AppLocalizations l, Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? l.deskNodeDurationHm(h, m) : l.deskNodeDurationM(d.inMinutes);
}

/// "5.2 GB", "820 MB".
/// `1.2 GB` or `640 MB`, in [l]'s decimal separator when given (`1,2 GB`).
String bytesText(int b, [AppLocalizations? l]) {
  final gb = _gb(b);
  return b >= 1e9 ? '${l == null ? gb : localDigits(l, gb)} GB' : '${(b / 1e6).round()} MB';
}

/// The step of the sync strip a stage belongs to: 0 headers, 1 chain state, 2 blocks, 3 synced;
/// null while waiting for peers.
int? stripStep(SyncStage s) => switch (s) {
  SyncStage.waitingForPeers => null,
  SyncStage.headers => 0,
  SyncStage.chainStateDownload || SyncStage.chainStateKernels || SyncStage.chainStateRangeProofs || SyncStage.chainStateProcessing => 1,
  SyncStage.blocks => 2,
  SyncStage.synced => 3,
  _ => null,
};
