/// What the node screens say about a node: one word, a state, the rail's second line and the
/// tooltip's lines (spec §16), the local node's stage line and time left (§15.2). Pure, so the
/// rail, the node card and the local node panel say the same thing.
library;

import '../../address_format.dart' show railHost;
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

/// 2914414 → "2,914,414".
String digits(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// "12 %" of an overall progress 0–1 (floored: never 100 % before Synced).
String percent(double overall) => '${(overall * 100).floor().clamp(0, 99)} %';

/// A remote node from its [NodeInfo] (null: nothing known yet). [health] is the wallet's own
/// view when the info has not come in.
NodeView remoteNodeView(String url, NodeInfo? info, {ServiceHealth? health, DateTime? downSince}) {
  final full = nodeHost(url);
  final host = railHost('Node', full);
  final down = health == ServiceHealth.down || info?.state == NodeHealthState.down || info?.source == NodeInfoSource.none;
  if (down) {
    return NodeView(
      word: 'Not answering',
      state: EState.risk,
      host: host,
      marker: 'no answer',
      lines: [downSince == null ? full : '$full · since ${hhmm(downSince)}', 'The node is not answering.'],
    );
  }
  if (info == null) return NodeView(word: 'Checking', state: EState.off, host: host, lines: [full]);
  final behind = info.blocksBehind;
  final h = info.height;
  final old = info.updateAvailable == true;
  final second = [
    if (info.latencyMs != null) '${digits(info.latencyMs!)} ms${info.latencyOverTor ? ' over Tor' : ''}',
    if (info.version != null) 'v${info.version}',
    if (old && info.releasedVersion != null) '${info.releasedVersion} is out',
  ].join(' · ');
  if (behind != null && behind > syncedWithinBlocks) {
    return NodeView(
      word: 'Behind',
      state: EState.warn,
      host: host,
      marker: '${digits(behind)} behind',
      lines: [
        [full, if (h != null && info.networkHeight != null) '${digits(h)} of ${digits(info.networkHeight!)}'].join(' · '),
        'Behind the network; catching up.',
      ],
    );
  }
  return NodeView(
    word: 'Synced',
    state: old ? EState.warn : EState.ok,
    host: host,
    lines: [
      [full, if (h != null) digits(h), if (behind != null) 'at tip'].join(' · '),
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
NodeView localNodeView(LocalNodeState? s, {String? fallbackUrl}) {
  const name = 'Local node';
  final fallback = fallbackUrl == null || isLocalNodeUrl(fallbackUrl) ? null : nodeHost(fallbackUrl);
  final host = fallback != null ? railHost('Node', fallback) : name;
  if (s == null) return NodeView(word: 'Checking', state: EState.off, host: host, lines: const [name]);
  final p = s.progress;
  switch (s.phase) {
    case LocalNodePhase.starting:
      return NodeView(
        word: 'Starting',
        state: EState.warn,
        host: host,
        marker: 'starting',
        lines: [name, 'Connecting to peers', if (fallback != null) 'Using $fallback until it is synced.'],
      );
    case LocalNodePhase.syncing:
      final pct = p?.overall == null ? null : percent(p!.overall!);
      final left = p == null ? null : timeLeft(p.stage, s.eta);
      return NodeView(
        word: 'Syncing',
        state: EState.warn,
        host: host,
        marker: pct,
        lines: [
          [name, ?pct, ?left].join(' · '),
          [if (p != null) stageLine(p), if (s.peers != null) '${s.peers} peers'].join(' · '),
          fallback != null ? 'Using $fallback until it is synced.' : 'Nothing can be sent until it is synced.',
        ].where((l) => l.isNotEmpty).toList(),
      );
    case LocalNodePhase.synced:
      return NodeView(
        word: 'Synced',
        state: EState.ok,
        host: host,
        lines: [
          [name, if (s.height != null) digits(s.height!), 'at tip'].join(' · '),
          [if (s.peers != null) '${s.peers} peers', if (s.version != null) 'v${s.version}', if (s.uptime != null) 'running ${duration(s.uptime!)}'].join(' · '),
          if (fallback != null) 'Still using $fallback; the local node takes over shortly.',
        ],
      );
    case LocalNodePhase.error:
      if (s.stalled) {
        return NodeView(
          word: 'Stalled',
          state: EState.risk,
          host: host,
          marker: 'stalled',
          lines: [
            [name, if (s.height != null) digits(s.height!)].join(' · '),
            'No progress for 5 min. Restarted once already.',
            if (fallback != null) 'Using $fallback meanwhile.',
          ],
        );
      }
      return NodeView(word: 'Failed', state: EState.risk, host: host, marker: 'failed', lines: [name, failureLine(s), if (fallback != null) 'Using $fallback meanwhile.']);
    case LocalNodePhase.stopped:
      return NodeView(
        word: 'Stopped',
        state: EState.off,
        host: host,
        marker: 'stopped',
        lines: [name, 'Start it under Settings › Node.', if (fallback != null) 'Using $fallback meanwhile.'],
      );
  }
}

/// Why the local node failed, as a detail after the word (§19).
String failureLine(LocalNodeState s) => switch (s.failure) {
  NodeFailure.portInUse => 'port 3413 is used by another program',
  NodeFailure.diskLow => 'not enough disk space',
  NodeFailure.binaryMissing => 'the node program is missing',
  NodeFailure.exited => 'the node program stopped${_exitCode(s.reason)}',
  _ => s.reason ?? 'the node did not start',
};

String _exitCode(String? reason) {
  final m = RegExp(r'(?:exit code|code)\s*(-?\d+)').firstMatch(reason ?? '');
  return m == null ? '' : ' (exit code ${m[1]})';
}

/// The stage's name for the panel's detail.
String stageName(SyncStage s) => switch (s) {
  SyncStage.waitingForPeers => 'connecting to peers',
  SyncStage.headers => 'headers',
  SyncStage.chainStateDownload => 'chain state download',
  SyncStage.chainStateKernels => 'checking kernels',
  SyncStage.chainStateRangeProofs => 'checking range proofs',
  SyncStage.chainStateProcessing => 'processing the chain state',
  SyncStage.blocks => 'blocks',
  SyncStage.compacting => 'compacting',
  SyncStage.shuttingDown => 'stopping',
  SyncStage.synced || SyncStage.unknown => 'syncing',
};

String _gb(int bytes) => (bytes / 1e9).toStringAsFixed(1);

String _millions(int n) => (n / 1e6).toStringAsFixed(1);

/// The stage line: the stage in its own units, never a second percentage (§15.2).
String stageLine(SyncProgress p) {
  final d = p.done, t = p.total;
  final known = d != null && t != null && t > 0;
  return switch (p.stage) {
    SyncStage.waitingForPeers => 'Connecting to peers',
    SyncStage.headers => known ? 'Headers · ${digits(d)} of ${digits(t)}' : 'Headers',
    SyncStage.chainStateDownload => known ? 'Chain state · ${_gb(d)} of ${_gb(t)} GB' : 'Chain state',
    SyncStage.chainStateKernels => known ? 'Checking kernels · ${_millions(d)} of ${_millions(t)} million' : 'Checking kernels',
    SyncStage.chainStateRangeProofs => known ? 'Checking range proofs · ${_millions(d)} of ${_millions(t)} million' : 'Checking range proofs',
    SyncStage.chainStateProcessing => 'Processing the chain state',
    SyncStage.blocks => known ? 'Blocks · ${digits(d)} of ${digits(t)}' : 'Blocks',
    SyncStage.compacting => 'Compacting the chain data',
    SyncStage.shuttingDown => 'Stopping…',
    SyncStage.synced || SyncStage.unknown => 'Syncing',
  };
}

/// "about 3 h left", "about 12 min left", "estimating…", or the fixed text of the checks.
String? timeLeft(SyncStage stage, Duration? eta) {
  switch (stage) {
    case SyncStage.chainStateKernels || SyncStage.chainStateRangeProofs || SyncStage.chainStateProcessing:
      return 'no estimate; up to an hour';
    case SyncStage.headers || SyncStage.chainStateDownload || SyncStage.blocks:
      if (eta == null) return 'estimating…';
      final min = (eta.inSeconds / 60).ceil();
      return min > 90 ? 'about ${(min / 60).round()} h left' : 'about ${min < 1 ? 1 : min} min left';
    default:
      return null;
  }
}

/// "9 h 40 min", "2 min".
String duration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '$h h $m min' : '${d.inMinutes} min';
}

/// "5.2 GB", "820 MB".
String bytesText(int b) => b >= 1e9 ? '${_gb(b)} GB' : '${(b / 1e6).round()} MB';

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
