import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_state.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart' show groupDigits;
import 'theme/tokens.dart';

/// Where the node stands for the open wallet.
enum NodeState { online, syncing, connecting, offline }

/// Where the epicbox listener stands.
enum EpicboxState { online, connecting, offline }

/// The node row of the header: its state, and what its tooltip tells.
class NodeStatus {
  const NodeStatus(
    this.state, {
    this.percent,
    this.tip,
    this.height,
    this.validated = true,
  });

  final NodeState state;

  /// Percent done while [NodeState.syncing], when the refresh reports it.
  final int? percent;

  /// The node's answer, when it gave one.
  final NodeTip? tip;

  /// The block the balances were checked at, else the node's tip.
  final BigInt? height;

  /// False when the balances on screen were read from the wallet's files only, because the
  /// refresh against the node failed. Only [NodeState.offline] has it false.
  final bool validated;
}

/// The header's two statuses. [epicbox] is null when the listener does not run.
typedef WalletStatus = ({NodeStatus node, EpicboxState? epicbox});

/// The node and epicbox statuses from what the app knows: the node's tip, whether a refresh
/// runs ([syncing]) and its [percent], the balances shown ([summary]) and the listener.
///
/// Node: a running refresh is syncing; a failed tip request, or balances the refresh could not
/// check, is offline; a tip is online; no answer yet is connecting. Epicbox: connected is
/// online, a lost connection is offline, anything else connecting; a stopped listener has no
/// status. While the relay's connection [waitingForTor] (the user turned Tor on and it is still
/// starting) a lost connection is connecting: the user closed it on purpose (android-09).
/// Blocks the wallet may be behind the node's tip while a refresh runs and still read as up to
/// date: a routine refresh at the tip is not syncing, however long it takes over Tor (android-04,
/// "Syncing 0 %" at the tip after a network change).
const int syncLagBlocks = 3;

WalletStatus walletStatus({
  required AsyncValue<NodeTip> tip,
  required bool syncing,
  int? percent,
  WalletSummary? summary,
  required ListenerState listener,
  bool waitingForTor = false,
}) {
  final answer = tip.value;
  final checked = summary != null && summary.lastConfirmedHeight > BigInt.zero
      ? summary.lastConfirmedHeight
      : answer?.height;
  // A refresh that has scanned nothing yet, with the wallet at the tip, is a routine check.
  final atTip =
      answer != null &&
      summary != null &&
      summary.lastConfirmedHeight > BigInt.zero &&
      answer.height - summary.lastConfirmedHeight <= BigInt.from(syncLagBlocks);
  final NodeStatus node;
  if (syncing && !(atTip && (percent ?? 0) == 0)) {
    node = NodeStatus(
      NodeState.syncing,
      percent: percent,
      tip: answer,
      height: checked,
    );
  } else if (tip.hasError && !tip.isLoading) {
    node = NodeStatus(NodeState.offline, height: checked);
  } else if (summary != null && !summary.validatedWithNode) {
    node = NodeStatus(
      NodeState.offline,
      tip: answer,
      height: checked,
      validated: false,
    );
  } else if (answer != null) {
    node = NodeStatus(NodeState.online, tip: answer, height: checked);
  } else {
    node = NodeStatus(NodeState.connecting, height: checked);
  }
  final EpicboxState? epicbox = listener.stopped
      ? null
      : listener.connected
      ? EpicboxState.online
      : listener.lost && !waitingForTor
      ? EpicboxState.offline
      : EpicboxState.connecting;
  return (node: node, epicbox: epicbox);
}

/// The [WalletStatus] of the open wallet as shown: offline and syncing only once they last
/// ([walletStatusProvider]).
WalletStatus watchWalletStatus(WidgetRef ref) => ref.watch(walletStatusProvider);

/// Icon, words (the service and its state, also what a screen reader says), colour, spoken
/// label and tooltip of one status.
class _Face {
  const _Face(this.icon, this.word, this.color, this.label, this.detail);

  final IconData icon;
  final String word;
  final Color color;
  final String label;
  final String detail;
}

_Face _nodeFace(BuildContext context, NodeStatus node, WalletConfig? config) {
  final l = context.l10n;
  final t = context.tokens;
  final (
    IconData icon,
    String word,
    Color color,
    String sentence,
  ) = switch (node.state) {
    NodeState.online => (
      EpicGlyphs.node,
      l.statusNodeOnline,
      t.ok,
      l.homeSyncUpToDate,
    ),
    NodeState.syncing => (
      Icons.sync,
      node.percent == null
          ? l.statusNodeSyncing
          : l.statusNodeSyncingPercent(node.percent!),
      t.info,
      node.percent == null
          ? l.homeSyncSyncing
          : l.homeSyncSyncingPercent(node.percent!),
    ),
    NodeState.connecting => (
      Icons.cloud_queue,
      l.statusNodeConnecting,
      t.info,
      l.homeSyncContactingNode,
    ),
    NodeState.offline => (
      Icons.cloud_off,
      l.statusNodeOffline,
      t.risk,
      node.validated ? l.homeSyncNodeUnreachable : l.homeSyncNotValidated,
    ),
  };
  final host = config == null
      ? null
      : Uri.tryParse(config.nodeUrl)?.host ?? config.nodeUrl;
  final height = node.height;
  final version = node.tip?.nodeVersion ?? '';
  final chain = config?.chain;
  final detail = [
    // A test network says so first: the app bar names no network.
    if (chain != null && chain != Chain.mainnet)
      l.statusNodeTestNetwork(chainName(l, chain)),
    sentence,
    if (host != null && host.isNotEmpty) l.statusNodeHost(host),
    if (height != null && height > BigInt.zero)
      l.homeSyncedAtBlock(groupDigits(l, height)),
    if (version.isNotEmpty) l.statusNodeVersion(version),
  ].join('\n');
  return _Face(icon, word, color, word, detail);
}

_Face _epicboxFace(
  BuildContext context,
  EpicboxState state,
  WalletConfig? config,
) {
  final l = context.l10n;
  final t = context.tokens;
  final (
    IconData icon,
    String word,
    Color color,
    String sentence,
  ) = switch (state) {
    EpicboxState.online => (
      Icons.mark_email_read_outlined,
      l.statusEpicboxOnline,
      t.ok,
      l.receiveEpicboxConnected,
    ),
    EpicboxState.connecting => (
      EpicGlyphs.epicbox,
      l.statusEpicboxConnecting,
      t.info,
      l.homeEpicboxConnecting,
    ),
    EpicboxState.offline => (
      Icons.unsubscribe_outlined,
      l.statusEpicboxOffline,
      t.risk,
      l.homeEpicboxOffline,
    ),
  };
  final detail = [
    sentence,
    if (config != null)
      l.statusRelay('${config.epicboxDomain}:${config.epicboxPort}'),
  ].join('\n');
  return _Face(icon, word, color, word, detail);
}

/// The side of a status's tap target.
const double statusTarget = 48;

/// The side of a status's icon, centred in its target.
const double statusGlyph = 18;

/// From a status target's leading edge to its icon's: what a row of statuses is moved back by
/// so its first icon lines up with the text above or beside it.
const double statusInset = (statusTarget - statusGlyph) / 2;

/// The key of the node status, for tests.
const Key nodeStatusKey = ValueKey('status-node');

/// The key of the epicbox status, for tests.
const Key epicboxStatusKey = ValueKey('status-epicbox');

/// [child] fading between 45 % and full opacity every 1.6 s while [active], as the mockup's
/// pulse. Still at full opacity with reduced motion, or when not [active].
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.45)
      .chain(CurveTween(curve: const Cubic(0.22, 0.61, 0.36, 1)))
      .animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!run && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// The colour of a status's state dot: the service works (green), is busy connecting, syncing
/// or waiting (blue, in progress), does not work (red), or is off (faint). Never the accent.
enum StatusDot {
  ok,
  busy,
  bad,
  off;

  Color color(WalletTokens t) => switch (this) {
    StatusDot.ok => t.ok,
    StatusDot.busy => t.info,
    StatusDot.bad => t.risk,
    StatusDot.off => t.faint,
  };
}

/// The diameter of the state dot at a status glyph's bottom right, ring included.
const double statusDotSize = 10;

/// One status as its glyph on a [statusTarget] square, in the dim colour, with the state's
/// [dot] at its bottom right (ringed in the page colour so it stands off the glyph). A tap
/// runs [onTap] (the service's screen); a long press or hover shows the tooltip with
/// [detail]; a screen reader hears [label] (the service and its state word), then [detail]
/// and [actionHint]. A [StatusDot.busy] status pulses.
class StatusIcon extends StatelessWidget {
  const StatusIcon({
    super.key,
    required this.icon,
    required this.dot,
    required this.label,
    required this.detail,
    required this.onTap,
    this.actionHint,
    this.pulse = false,
  });

  final IconData icon;
  final StatusDot dot;
  final String label;
  final String detail;
  final String? actionHint;
  final VoidCallback onTap;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ring = Theme.of(context).scaffoldBackgroundColor;
    // The semantics node is the widget's root, so tests and screen readers find it by key;
    // the tooltip inside it is excluded (its text is the hint).
    return Semantics(
      container: true,
      button: true,
      label: label,
      hint: [detail, ?actionHint].join('\n'),
      liveRegion: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: detail,
        triggerMode: TooltipTriggerMode.longPress,
        showDuration: const Duration(seconds: 6),
        child: SizedBox.square(
          dimension: statusTarget,
          child: InkResponse(
            onTap: onTap,
            radius: statusTarget / 2,
            child: Center(
              child: Pulse(
                active: pulse,
                child: SizedBox.square(
                  dimension: statusGlyph,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: statusGlyph, color: t.dim),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: statusDotSize,
                          height: statusDotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot.color(t),
                            border: Border.all(color: ring, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The node's glyph, label word and tooltip for the status icons ([StatusIcon]): the state's
/// cloud glyph as the header's icons had it (a shape cue beside the dot's colour), the word
/// the status card uses ("Synced", "Behind 12"), and the dot: green synced, blue syncing or
/// connecting, red offline or far behind.
({IconData icon, StatusDot dot, String word, String detail}) nodeIconFace(
  BuildContext context,
  NodeStatus node,
  WalletConfig? config, {
  int? behind,
}) {
  final f = _nodeFace(context, node, config);
  final net = nodeNetFace(context, node, behind: behind);
  final dot = switch (node.state) {
    NodeState.online when behind != null && behind >= behindAfter =>
      StatusDot.bad,
    NodeState.online => StatusDot.ok,
    NodeState.syncing || NodeState.connecting => StatusDot.busy,
    NodeState.offline => StatusDot.bad,
  };
  return (icon: f.icon, dot: dot, word: net.word, detail: f.detail);
}

/// The same for the epicbox listener; a stopped listener is "Off" with a faint dot.
({IconData icon, StatusDot dot, String word, String detail}) epicboxIconFace(
  BuildContext context,
  EpicboxState? state,
  WalletConfig? config,
) {
  final l = context.l10n;
  final net = epicboxNetFace(context, state);
  if (state == null) {
    final detail = [
      l.netStatusOff,
      if (config != null)
        l.statusRelay('${config.epicboxDomain}:${config.epicboxPort}'),
    ].join('\n');
    return (
      icon: EpicGlyphs.epicbox,
      dot: StatusDot.off,
      word: net.word,
      detail: detail,
    );
  }
  final f = _epicboxFace(context, state, config);
  final dot = switch (state) {
    EpicboxState.online => StatusDot.ok,
    EpicboxState.connecting => StatusDot.busy,
    EpicboxState.offline => StatusDot.bad,
  };
  return (icon: f.icon, dot: dot, word: net.word, detail: f.detail);
}

/// How many of [SignalBars]' three bars are lit: none for a service that is off.
enum SignalLevel { none, one, two, three }

/// The desktop's three-bar signal glyph, drawn: three bars of rising height in an
/// [statusGlyph] box with 2 dp gaps, the lit ones in [color], the others in the hairline
/// colour. [pulse] fades it while a node syncs (still with reduced motion).
class SignalBars extends StatelessWidget {
  const SignalBars({
    super.key,
    required this.level,
    required this.color,
    this.pulse = false,
  });

  final SignalLevel level;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Pulse(
        active: pulse,
        child: CustomPaint(
          size: const Size.square(statusGlyph),
          painter: _BarsPainter(level.index, color, context.tokens.line),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.lit, this.color, this.unlit);

  final int lit;
  final Color color;
  final Color unlit;

  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width - 2 * _gap) / 3;
    for (var i = 0; i < 3; i++) {
      final h = size.height * (i + 1) / 3;
      final left = i * (w + _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - h, w, h),
          const Radius.circular(1),
        ),
        Paint()..color = i < lit ? color : unlit,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.lit != lit || old.color != color || old.unlit != unlit;
}

/// A service's state on the status card and in the pickers: its bars, their colour and the
/// word that always goes with them.
typedef NetFace = ({SignalLevel level, Color color, String word});

/// From this many blocks behind the network's tip a node that answers reads "Behind N".
const int behindAfter = 3;

/// The node's face on the status card. [behind] is the node's lag behind the network tip
/// when the monitor told it, for a node that answers.
NetFace nodeNetFace(BuildContext context, NodeStatus node, {int? behind}) {
  final l = context.l10n;
  final t = context.tokens;
  return switch (node.state) {
    NodeState.online when behind != null && behind >= behindAfter => (
      level: SignalLevel.two,
      color: t.risk,
      word: l.netStatusBehind(behind),
    ),
    NodeState.online => (
      level: SignalLevel.three,
      color: t.ok,
      word: l.netStatusSynced,
    ),
    NodeState.syncing => (
      level: SignalLevel.two,
      color: t.info,
      word: node.percent == null
          ? l.netStatusSyncing
          : l.netStatusSyncingPercent(node.percent!),
    ),
    NodeState.connecting => (
      level: SignalLevel.one,
      color: t.info,
      word: l.netStatusConnecting,
    ),
    NodeState.offline => (
      level: SignalLevel.one,
      color: t.risk,
      word: l.netStatusOffline,
    ),
  };
}

/// The epicbox listener's face; null [state] is a stopped listener ("Off").
NetFace epicboxNetFace(BuildContext context, EpicboxState? state) {
  final l = context.l10n;
  final t = context.tokens;
  return switch (state) {
    // This wallet's connection, not the server's health (the picker shows that).
    EpicboxState.online => (
      level: SignalLevel.three,
      color: t.ok,
      word: l.netStatusConnected,
    ),
    EpicboxState.connecting => (
      level: SignalLevel.one,
      color: t.info,
      word: l.netStatusConnecting,
    ),
    EpicboxState.offline => (
      level: SignalLevel.one,
      color: t.risk,
      word: l.netStatusNotConnected,
    ),
    null => (level: SignalLevel.none, color: t.dim, word: l.netStatusOff),
  };
}

/// A server address as the screen shows it: the host only, with the port only when it is not
/// the scheme's default. Text that is no address comes back as it is.
String serverHost(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return url.trim();
  final port = u.hasPort && u.port != (u.scheme == 'http' ? 80 : 443);
  return port ? '${u.host}:${u.port}' : u.host;
}

/// What the node's status icon says to a screen reader ("Node online") and its tooltip
/// detail, for the status card's row.
({String label, String detail}) nodeStatusWords(
  BuildContext context,
  NodeStatus node,
  WalletConfig? config,
) {
  final f = _nodeFace(context, node, config);
  return (label: f.label, detail: f.detail);
}

/// The same for the epicbox listener; null while it does not run.
({String label, String detail})? epicboxStatusWords(
  BuildContext context,
  EpicboxState? state,
  WalletConfig? config,
) {
  if (state == null) return null;
  final f = _epicboxFace(context, state, config);
  return (label: f.label, detail: f.detail);
}
