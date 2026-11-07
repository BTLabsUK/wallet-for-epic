// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address_format.dart' show hostPort;
import '../dev_networks.dart' show devNetworksOf;

import '../connection_state.dart';
import '../state_language.dart';
import '../l10n.dart';
import '../network.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'state_mark.dart' show StateMarkDot;
import 'tip.dart';
import 'warn_pulse.dart';
import 'common.dart' show groupDigits;
import 'theme/tokens.dart';

/// Where the node stands for the open wallet.
enum NodeState { online, syncing, connecting, offline }

/// Where the epicbox listener stands. [blocked]: not connected because this network blocks the
/// relay (relay_block.dart); it shows at once and stays, without flipping to connecting.
enum EpicboxState { online, connecting, offline, blocked }

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
/// Node: a failed tip request not answered since is offline, even while a refresh runs; else a
/// running refresh is syncing; balances the refresh could not check are offline; a tip is
/// online; no answer yet is connecting. Epicbox: connected is
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
  // A node whose tip request failed, and that has not answered since, is offline even while a
  // refresh runs against it: that refresh only retries a node it can't reach, and as "syncing
  // 0 %" it hid the outage from node failover for good (26.10.26, a network filtering the node).
  final unreachable = tip.hasError && (!tip.isLoading || answer == null);
  final NodeStatus node;
  if (unreachable) {
    node = NodeStatus(NodeState.offline, height: checked);
  } else if (syncing && !(atTip && (percent ?? 0) == 0)) {
    node = NodeStatus(
      NodeState.syncing,
      percent: percent,
      tip: answer,
      height: checked,
    );
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
      : listener.blocked
      ? EpicboxState.blocked
      : (listener.lost || listener.retrying) && !waitingForTor
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
      : serverHost(config.nodeUrl);
  final height = node.height;
  final version = node.tip?.nodeVersion ?? '';
  final chain = config?.chain;
  final detail = [
    // A development build on a test network says so first: the app bar names no network.
    if (chain != null && chain != Chain.mainnet && devNetworksOf(context))
      '${chainName(l, chain)}, test coins',
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
      EpicGlyphs.epicbox,
      l.statusEpicboxOnline,
      t.ok,
      config == null ? l.statusEpicboxOnline : l.receiveEpicboxConnected(relayLabel(config)),
    ),
    EpicboxState.connecting => (
      EpicGlyphs.epicbox,
      l.statusEpicboxConnecting,
      t.info,
      l.homeEpicboxConnecting,
    ),
    EpicboxState.offline => (
      EpicGlyphs.epicbox,
      l.statusEpicboxOffline,
      t.risk,
      l.homeEpicboxOffline,
    ),
    EpicboxState.blocked => (
      EpicGlyphs.epicbox,
      l.statusEpicboxBlocked,
      t.risk,
      l.epicboxBlockedBody(config == null ? 'Epicbox' : relayLabel(config)),
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

/// [child] fading between 45 % and full opacity every 1.6 s for a few breaths once [active]
/// begins, as the mockup's pulse, then still at full opacity: the blue dot keeps saying "in
/// progress". A pulse that never ends redraws the screen for as long as Tor starts or the node
/// syncs (the desktop's dot stops the same way). Still at full opacity with reduced motion, or
/// when not [active]; a new [active] stretch plays its breaths again.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

/// Breaths a pulse plays before it holds still: five, about 8 s, as the desktop's dot.
@visibleForTesting
const int pulseBreaths = 5;

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )
    // The breaths end at full opacity: a frame that lands past the last one could leave the
    // value part way down.
    ..addStatusListener((status) {
      if (!_controller.isAnimating &&
          (status == AnimationStatus.completed || status == AnimationStatus.dismissed)) {
        _controller.value = 0;
      }
    });
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.45)
      .chain(CurveTween(curve: const Cubic(0.22, 0.61, 0.36, 1)))
      .animate(_controller);

  /// The breaths ran for this active stretch.
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    if (!widget.active) _played = false;
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_played) {
      _played = true;
      // Down and up is one breath: an even count ends where it began, at full opacity.
      _controller
        ..value = 0
        ..repeat(reverse: true, count: pulseBreaths * 2);
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
/// or waiting, or nothing is known yet (blue, in progress), does not work (red), works but is
/// degraded or needs the user's answer (amber: behind, the level-1 relay offer), or is off
/// (faint, slashed). Never the accent. The phone's name for the shared [StateTone]
/// (state_language.dart): a [ShownState] gives its word and its dot.
enum StatusDot {
  ok,
  busy,
  bad,
  warn,
  off;

  Color color(WalletTokens t) => toneColor(t, tone);

  /// The shared tone of this dot.
  StateTone get tone => switch (this) {
    StatusDot.ok => StateTone.ok,
    StatusDot.busy => StateTone.info,
    StatusDot.bad => StateTone.risk,
    StatusDot.warn => StateTone.warn,
    StatusDot.off => StateTone.faint,
  };

  /// The dot's shape.
  StateMark get mark => tone.mark;

  /// The phone's dot of a shared [StateTone].
  static StatusDot ofTone(StateTone t) => switch (t) {
    StateTone.ok => StatusDot.ok,
    StateTone.info => StatusDot.busy,
    StateTone.warn => StatusDot.warn,
    StateTone.risk => StatusDot.bad,
    StateTone.faint => StatusDot.off,
  };

  /// The phone's dot of a [ShownState]: its word is [ShownState.word].
  static StatusDot of(ShownState s) => ofTone(s.tone);
}

/// A [StateTone]'s colour in the phone's tokens: ok green, info blue, warn amber, risk red,
/// faint grey. Never the accent.
Color toneColor(WalletTokens t, StateTone tone) => switch (tone) {
  StateTone.ok => t.ok,
  StateTone.info => t.info,
  StateTone.warn => t.warn,
  StateTone.risk => t.risk,
  StateTone.faint => t.faint,
};

/// A result's tile, as the desktop's result cards (`ResultGlyph`): one 52 dp rounded square
/// per outcome, [icon] in its state [tone] on that tone's soft ground: done a green check,
/// waiting a blue hourglass, a problem red. Never a bare glyph, never the accent.
class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.icon, required this.tone});

  /// The tile of an outcome still under way: the hourglass in blue.
  const ResultTile.waiting({super.key}) : icon = Icons.hourglass_empty, tone = StateTone.info;

  final IconData icon;
  final StateTone tone;

  /// The tile's side.
  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ground = switch (tone) {
      StateTone.ok => t.okSoft,
      StateTone.info => t.infoSoft,
      StateTone.warn => t.warnSoft,
      StateTone.risk => t.riskSoft,
      StateTone.faint => t.surfaceHi,
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: ground, borderRadius: BorderRadius.circular(t.radiusSmall)),
        child: Icon(icon, size: 28, color: tone == StateTone.faint ? t.dim : toneColor(t, tone)),
      ),
    );
  }
}

/// The diameter of the state mark at a status glyph's bottom right, ring included.
const double statusDotSize = 8;


/// One status as its glyph on a [statusTarget] square ([StatusGlyph]). A tap runs [onTap]
/// (the service's screen); a long press runs [onLongPress] (the connections sheet) or, without
/// one, shows the tooltip with [detail]; a screen reader hears [label] (the service and its
/// state word), then [detail] and [actionHint]. A [StatusDot.busy] status pulses.
class StatusIcon extends StatelessWidget {
  const StatusIcon({
    super.key,
    required this.icon,
    required this.dot,
    required this.label,
    required this.detail,
    required this.onTap,
    this.onLongPress,
    this.actionHint,
    this.pulse = false,
    this.enabled = true,
  });

  /// Whether the service is on: the glyph is neutral then and the mark shows its connection;
  /// off, the glyph is faint with a slash and has no mark, and a tap opens the switch.
  final bool enabled;

  final IconData icon;
  final StatusDot dot;
  final String label;
  final String detail;
  final String? actionHint;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).scaffoldBackgroundColor;
    final target = SizedBox.square(
      dimension: statusTarget,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: statusTarget / 2,
        child: Center(
          child: Pulse(
            active: pulse,
            child: StatusGlyph(icon: icon, enabled: enabled, dot: dot, ring: ring),
          ),
        ),
      ),
    );
    // The semantics node is the widget's root, so tests and screen readers find it by key;
    // the tooltip inside it is excluded (its text is the hint).
    return Semantics(
      container: true,
      button: true,
      label: label,
      // A detail that only repeats the state in the label is said once.
      hint: [if (!label.toLowerCase().contains(detail.trim().toLowerCase())) detail, ?actionHint].join('\n'),
      liveRegion: true,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: onLongPress != null
          ? target
          : Tip(detail, child: target),
    );
  }
}

/// A status's glyph, [statusGlyph] across, with its state at the bottom right. One signal per
/// state: the glyph itself stays neutral ([WalletTokens.dim]) and only the small mark carries
/// colour, each state with its own shape beside the colour: a solid green dot = ready, a blue
/// ring (pulsing) = in progress, a red dot with "!" = a problem. Off by choice is calm, not an
/// error: the glyph faint with a thin slash and no mark. The Settings › Network rows, the
/// connections sheet and the desktop's clusters use the same language.
class StatusGlyph extends StatelessWidget {
  const StatusGlyph({
    super.key,
    required this.icon,
    required this.enabled,
    required this.dot,
    required this.ring,
  });

  final IconData icon;
  final bool enabled;
  final StatusDot dot;

  /// The page colour the dot is ringed in, so it stands off the glyph.
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final off = !enabled || dot == StatusDot.off;
    return SizedBox.square(
      dimension: statusGlyph,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: statusGlyph, color: off ? offGlyphColor(t) : t.dim),
          if (off)
            Positioned.fill(child: OffSlash(color: offGlyphColor(t), halo: ring))
          else
            Positioned(
              right: -2,
              bottom: -2,
              child: WarnPulse(
                active: dot == StatusDot.warn,
                color: StatusDot.warn.color(t),
                child: StateDot(dot: dot, size: statusDotSize, ring: ring),
              ),
            ),
        ],
      ),
    );
  }
}

/// The colour of a glyph whose service is off by choice: faint, well under the neutral glyph,
/// and the same for the slash over it.
Color offGlyphColor(WalletTokens t) => t.faint.withValues(alpha: 0.55);

/// The state mark at a status glyph's corner, [size] across with the page-colour [ring]: the
/// shared [StateMark] ([StateMarkDot]): a solid green dot for ok, a blue ring for work in
/// progress or a state not known yet, a dot with "!" for a problem (red, amber while it still
/// works), a slashed ring for off. Beside a glyph, [StatusGlyph] draws off as the faint glyph
/// with an [OffSlash] instead.
class StateDot extends StatelessWidget {
  const StateDot({super.key, required this.dot, required this.size, required this.ring});

  final StatusDot dot;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return StateMarkDot(
      mark: dot.mark,
      size: size,
      color: dot == StatusDot.off ? offGlyphColor(t) : dot.color(t),
      ink: ring,
      ring: ring,
      ringWidth: 1.5,
    );
  }
}

/// A thin diagonal slash over a status glyph that is off by choice, haloed in the page colour
/// [halo] so it reads over the glyph's strokes: the shape cue beside the faint colour.
class OffSlash extends StatelessWidget {
  const OffSlash({super.key, required this.color, required this.halo});

  final Color color;
  final Color halo;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _SlashPainter(color, halo)));
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter(this.color, this.halo);

  final Color color;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    // Bottom-left to top-right, a little past the box on both ends.
    final a = Offset(-1, size.height + 1);
    final b = Offset(size.width + 1, -1);
    canvas.drawLine(a, b, Paint()
      ..color = halo
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(a, b, Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SlashPainter old) => old.color != color || old.halo != halo;
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
      StatusDot.of(ShownState.behind),
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
    EpicboxState.offline || EpicboxState.blocked => StatusDot.bad,
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

/// The state dot for a [NetFace] (the faces use the tokens' colours, so the dot follows the
/// same meaning): off when nothing is lit, green ok, blue in progress, red a problem.
StatusDot netFaceDot(WalletTokens t, NetFace face) {
  if (face.level == SignalLevel.none) return StatusDot.off;
  if (face.color == t.ok) return StatusDot.ok;
  if (face.color == t.info) return StatusDot.busy;
  if (face.color == t.warn) return StatusDot.warn;
  return StatusDot.bad;
}

/// From this many blocks behind the network's tip a node that answers reads "Behind N".
const int behindAfter = 3;

/// The node's face on the status card. [behind] is the node's lag behind the network tip
/// when the monitor told it, for a node that answers.
NetFace nodeNetFace(BuildContext context, NodeStatus node, {int? behind}) {
  final l = context.l10n;
  final t = context.tokens;
  NetFace face(SignalLevel level, ShownState s, [String? word]) =>
      (level: level, color: toneColor(t, s.tone), word: word ?? s.word(l));
  return switch (node.state) {
    // Behind still answers: the amber "!" (state_language.dart), as on the desktop.
    NodeState.online when behind != null && behind >= behindAfter =>
      face(SignalLevel.two, ShownState.behind, l.netStatusBehind(behind)),
    NodeState.online => face(SignalLevel.three, ShownState.synced),
    NodeState.syncing => face(
      SignalLevel.two,
      ShownState.syncing,
      node.percent == null ? null : l.netStatusSyncingPercent(node.percent!),
    ),
    NodeState.connecting => face(SignalLevel.one, ShownState.connecting),
    NodeState.offline => face(SignalLevel.one, ShownState.notAnswering),
  };
}

/// The epicbox listener's face; null [state] is a stopped listener ("Off").
NetFace epicboxNetFace(BuildContext context, EpicboxState? state) {
  final l = context.l10n;
  final t = context.tokens;
  NetFace face(SignalLevel level, ShownState s) =>
      (level: level, color: toneColor(t, s.tone), word: s.word(l));
  return switch (state) {
    // This wallet's connection, not the server's health (the picker shows that).
    EpicboxState.online => face(SignalLevel.three, ShownState.connected),
    EpicboxState.connecting => face(SignalLevel.one, ShownState.connecting),
    EpicboxState.offline => face(SignalLevel.one, ShownState.notConnected),
    EpicboxState.blocked => face(SignalLevel.one, ShownState.blocked),
    null => (level: SignalLevel.none, color: t.dim, word: l.netStatusOff),
  };
}

/// The wallet's relay as addresses write it: the host, with the port only when it is not 443.
String relayLabel(WalletConfig config) =>
    EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort).label;

/// A server address as the screen shows it: host:port, the port only when it is not the
/// scheme's default ([hostPort]). Text that is no address comes back trimmed.
String serverHost(String url) => hostPort(url);

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
