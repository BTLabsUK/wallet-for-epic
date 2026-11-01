// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../state_language.dart';
import '../../ui/state_mark.dart' show StateMarkDot;
import '../../ui/status.dart' show OffSlash, StatusGlyph;

import '../desk_l10n.dart';
import '../data/models.dart';
import '../data/tor_view.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'surfaces.dart' show ETone;
import '../../text_join.dart';

export '../../state_language.dart' show ShownState, StateMark, StateTone;

/// One state mapping for the rail, the Receive header, panel dots and Settings heads:
/// [active] is in progress (starting, connecting, syncing, waiting for Tor), drawn blue;
/// [warn] amber is for real warnings only (behind, slow). The desktop's name for the shared
/// [StateTone] (state_language.dart): a [ShownState] gives its word and its [EState].
enum EState {
  ok,
  active,
  warn,
  risk,
  off;

  /// The shared tone of this state.
  StateTone get tone => switch (this) {
    EState.ok => StateTone.ok,
    EState.active => StateTone.info,
    EState.warn => StateTone.warn,
    EState.risk => StateTone.risk,
    EState.off => StateTone.faint,
  };

  /// The dot's shape.
  StateMark get mark => tone.mark;

  /// The desktop state of a shared [StateTone].
  static EState ofTone(StateTone t) => switch (t) {
    StateTone.ok => EState.ok,
    StateTone.info => EState.active,
    StateTone.warn => EState.warn,
    StateTone.risk => EState.risk,
    StateTone.faint => EState.off,
  };

  /// The desktop state of a [ShownState]: its word is [ShownState.word].
  static EState of(ShownState s) => ofTone(s.tone);
}

EState stateOf(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => EState.ok,
  ServiceHealth.checking => EState.active,
  ServiceHealth.slow => EState.warn,
  ServiceHealth.down => EState.risk,
  ServiceHealth.off => EState.off,
};

Color stateColor(DeskColors c, EState s) => switch (s) {
  EState.ok => c.ok,
  EState.active => c.info,
  EState.warn => c.warn,
  EState.risk => c.risk,
  EState.off => c.faint,
};

/// The badge and notice tone of a state.
ETone stateTone(EState s) => switch (s) {
  EState.ok => ETone.ok,
  EState.active => ETone.info,
  EState.warn => ETone.warn,
  EState.risk => ETone.risk,
  EState.off => ETone.neutral,
};

/// Lit bars of [ESignalBars] for a state.
int stateBars(EState s) => switch (s) {
  EState.ok => 3,
  EState.active || EState.warn => 2,
  EState.risk => 1,
  EState.off => 0,
};

/// The one glyph per method, shared with the phone.
IconData methodIcon(TxMethod m) => MethodIcons.of(switch (m) {
  TxMethod.epicbox => MethodKind.epicbox,
  TxMethod.http => MethodKind.linkHttp,
  TxMethod.tor => MethodKind.linkTor,
  TxMethod.file => MethodKind.directFile,
});

/// Three rising bars, 16 × 14 u, lit by [state]. Bars light upwards and dim downwards,
/// 120 ms each, 40 ms apart; with reduced motion they swap. The row supplies the semantics.
class ESignalBars extends StatefulWidget {
  const ESignalBars(this.state, {super.key});

  final EState state;

  @override
  State<ESignalBars> createState() => _ESignalBarsState();
}

class _ESignalBarsState extends State<ESignalBars> with SingleTickerProviderStateMixin {
  static const _bar = 120, _stagger = 40, _total = _bar + 2 * _stagger;

  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: _total), value: 1);
  // Bar colours before and after the current change; the painter interpolates between them.
  List<Color>? _from, _to;
  bool _upwards = true;

  @override
  void didUpdateWidget(ESignalBars old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state) return;
    final c = context.dc;
    _from = _current(c, old.state);
    _to = _colors(c, widget.state);
    _upwards = stateBars(widget.state) >= stateBars(old.state);
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<Color> _colors(DeskColors c, EState s) {
    final lit = stateBars(s);
    return [for (var i = 0; i < 3; i++) i < lit ? stateColor(c, s) : c.lineStrong];
  }

  /// Bar [i]'s progress: bottom bar first when lighting, top bar first when dimming.
  double _t(int i) {
    final slot = _upwards ? i : 2 - i;
    final start = slot * _stagger / _total, end = (slot * _stagger + _bar) / _total;
    return ((_c.value - start) / (end - start)).clamp(0.0, 1.0);
  }

  List<Color> _current(DeskColors c, [EState? idle]) {
    final from = _from, to = _to;
    if (from == null || to == null) return _colors(c, idle ?? widget.state);
    return [for (var i = 0; i < 3; i++) Color.lerp(from[i], to[i], _t(i))!];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    // A theme change while idle repaints with the new colours.
    if (!_c.isAnimating) _from = _to = null;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size(16.u, 14.u),
        painter: _BarsPainter(_current(c)),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.colors);

  final List<Color> colors;

  // In the 16 × 14 design box (assets/signal-*.svg).
  static const _x = [0.5, 6.25, 12.0], _h = [5.0, 9.0, 13.0];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 16;
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(_x[i] * k, (13.5 - _h[i]) * k, 3.5 * k, _h[i] * k);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(1.2 * k)), Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.colors.length != colors.length || [for (var i = 0; i < colors.length; i++) old.colors[i] != colors[i]].any((x) => x);
}

/// A method's glyph in its state colour, fixed size whatever the state; the colour moves over
/// [Dur.base]. [color] overrides the state colour (the Send segments: selected or dim).
class EMethodIcon extends StatelessWidget {
  const EMethodIcon(this.method, this.state, {super.key, this.size, this.color});

  final TxMethod method;
  final EState state;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final target = color ?? stateColor(context.dc, state);
    final px = size ?? Ctl.icon;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: target),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base,
      builder: (context, c, _) => Icon(methodIcon(method), size: px, color: c),
    );
  }
}

/// One receiving method's state line: [word] bold in the state colour, then
/// [detail]. [retry]: the line offers Try again (HTTP) or Retry (Tor).
@immutable
class MethodLine {
  const MethodLine(this.word, this.state, {this.detail, this.retry = false});

  /// The line of a [ShownState]: its one word and its state.
  MethodLine.of(AppLocalizations l, ShownState s, {this.detail, this.retry = false}) : word = s.word(l), state = EState.of(s);

  final String word;
  final String? detail;
  final EState state;
  final bool retry;

  /// "Word · detail", for tooltips and screen readers.
  String get text => detail == null ? word : metaLine([word, detail]);
}

/// The state line of [m] for Receive, Settings › Transactions and the rail tooltip. One word
/// per state ([ShownState]): a connection is Connected, a listener Receiving, a Tor address
/// Reachable; On and Off are only the switches' words (#29).
MethodLine methodStateLine(AppLocalizations l, TxMethod m, ServiceStatus s, DeskSettings settings) {
  switch (m) {
    case TxMethod.epicbox:
      final host = s.epicbox.domain;
      // The network ends the handshake with the relay (relay_block.dart): one steady state, not
      // Connecting and Not answering in turn; Retry would only fail again.
      if (s.epicboxBlocked && s.epicboxHealth == ServiceHealth.down) {
        return MethodLine(l.deskEpicboxBlockedWord, EState.risk, detail: l.deskEpicboxBlockedText(host));
      }
      // With the Tor switch on, Epicbox goes through Tor or waits for it (tor_routes.dart).
      final way = torWay(TorRoute.epicbox, torStateOf(settings, s));
      if (s.epicboxHealth != ServiceHealth.off) {
        if (way == TorWay.wait) return MethodLine.of(l, ShownState.waitingTor, detail: host);
        // Tor failed: Epicbox is not connected; why is Tor's to say (one message per page).
        if (way == TorWay.blocked) return MethodLine.of(l, ShownState.notConnected, detail: host);
        if (way == TorWay.overTor && s.epicboxHealth == ServiceHealth.ok) return MethodLine.of(l, ShownState.connected, detail: l.deskKitMethodOverTor(host));
      }
      return switch (s.epicboxHealth) {
        ServiceHealth.off => MethodLine.of(l, ShownState.off, detail: l.deskKitMethodEpicboxOffDetail),
        ServiceHealth.checking => MethodLine.of(l, ShownState.connecting, detail: host),
        ServiceHealth.ok => MethodLine.of(l, ShownState.connected, detail: host),
        ServiceHealth.slow => MethodLine.of(l, ShownState.slow, detail: host),
        ServiceHealth.down => MethodLine.of(l, ShownState.notAnswering, detail: l.deskKitMethodEpicboxDown(host)),
      };
    case TxMethod.http:
      final port = settings.httpPort;
      return switch (s.httpListener) {
        ServiceHealth.off => MethodLine.of(l, ShownState.off, detail: l.deskKitMethodHttpOffDetail),
        ServiceHealth.checking => MethodLine.of(l, ShownState.starting),
        ServiceHealth.ok || ServiceHealth.slow => MethodLine.of(
          l,
          ShownState.receiving,
          detail: settings.publicMode ? l.deskKitMethodHttpInternet('$port') : l.deskKitMethodHttpLocal,
        ),
        ServiceHealth.down => MethodLine.of(
          l,
          ShownState.notReceiving,
          retry: true,
          detail: s.httpProblem == null || s.httpProblem == HttpProblem.portInUse
              ? l.deskKitMethodPortInUse('$port')
              : '${httpProblemText(l, s.httpProblem!, s.httpProblemPort ?? port)}.',
        ),
      };
    case TxMethod.tor:
      if (!s.torIncluded) return MethodLine(l.deskKitMethodNotInBuild, EState.off);
      return switch (s.tor) {
        ServiceHealth.off => MethodLine.of(l, ShownState.off, detail: l.deskKitMethodTorOffDetail),
        ServiceHealth.checking => s.torCanSend
            ? MethodLine.of(l, ShownState.publishing)
            : MethodLine.of(l, ShownState.connecting, detail: '${s.torProgress ?? 0}%', retry: s.torSlowStart),
        ServiceHealth.ok => MethodLine.of(l, ShownState.reachable),
        ServiceHealth.slow => MethodLine.of(l, ShownState.notPublished, detail: l.deskKitMethodTorSendsWork(s.torProblem ?? l.deskKitMethodTorNotReachableYet), retry: true),
        ServiceHealth.down => MethodLine.of(l, ShownState.failed, detail: s.torProblem ?? l.deskKitMethodTorStoppedDetail, retry: true),
      };
    case TxMethod.file:
      return MethodLine(l.deskKitMethodFiles, EState.off);
  }
}

/// A [MethodLine] on one line: an 8 u dot, the word bold in the state colour, the detail.
class EStateLine extends StatelessWidget {
  const EStateLine(this.line, {super.key, this.trailing});

  final MethodLine line;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final color = stateColor(c, line.state);
    return Semantics(
      liveRegion: true,
      label: line.text,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8.u,
            height: 8.u,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: line.state == EState.off ? null : color,
              border: line.state == EState.off ? Border.all(color: color, width: 1.2) : null,
            ),
          ),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: line.word, style: ts.small.copyWith(color: line.state == EState.off ? c.text : color, fontWeight: FontWeight.w600)),
                  if (line.detail != null) TextSpan(text: ' · ${line.detail}'),
                ],
              ),
              style: ts.small,
            ),
          ),
          if (trailing != null) ...[SizedBox(width: Sp.x3), trailing!],
        ],
      ),
    );
  }
}

/// A state dot with a second cue besides its colour (WCAG 1.4.1), the shared [StateMark]:
/// ok a filled green dot, in progress or not known yet a blue ring, a problem a filled dot
/// with "!" (red, amber while it still works), off a faint ring with a slash. [ring] draws a
/// 2 u ring of the background around it, so it reads over a glyph.
class EStateDot extends StatelessWidget {
  const EStateDot(this.state, {super.key, this.size, this.ring = false, this.dim = false});

  /// The dot of a [ShownState].
  EStateDot.of(ShownState s, {Key? key, double? size, bool ring = false, bool dim = false}) : this(EState.of(s), key: key, size: size, ring: ring, dim: dim);

  final EState state;
  final double? size;
  final bool ring;

  /// The surface around it is dimmed (a modal over the bar): the dot follows at 60 %.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final px = size ?? 8.u;
    final outer = ring ? px + 4 : px;
    final color = (state == EState.off ? c.lineField : stateColor(c, state)).withValues(alpha: dim ? 0.6 : 1);
    return StateMarkDot(mark: state.mark, size: outer, color: color, ink: c.bg, ring: ring ? c.bg : null);
  }
}

/// A service glyph in a status cluster (title bar, sidebar): the neutral glyph with its
/// [EStateDot] as the one coloured signal, each state with its own shape (solid, ring, "!");
/// off by choice draws the glyph faint with a thin slash and no dot, calm rather than an
/// error. The phone's [StatusGlyph] speaks the same language. [label] ("Node: Synced") is the
/// semantics; the cluster's own tooltip lists every glyph.
class EStatusGlyph extends StatelessWidget {
  const EStatusGlyph({super.key, required this.icon, required this.state, required this.label, this.size, this.dim = false});

  final IconData icon;
  final EState state;
  final String label;
  final double? size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final px = size ?? 17.u;
    final off = state == EState.off;
    final box = px + 9.u;
    // The glyph is neutral; only the dot, on an enabled service, carries colour: green
    // connected, blue (pulsing) in progress, red down, amber a warning. Off is faint with a
    // slash. The label says the state in words.
    // Off keeps the slash and stays readable (>= 3:1 on the bar, UD-012).
    final ink = off ? c.lineField : c.dim;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: box,
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: dim ? 0.6 : 1,
                child: SizedBox.square(
                  dimension: px,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: px, color: ink),
                      if (off) Positioned.fill(child: OffSlash(color: ink, halo: c.bg)),
                    ],
                  ),
                ),
              ),
            ),
            if (!off)
              PositionedDirectional(
                end: 1.u,
                bottom: 1.u,
                child: _DotSwitch(state: state, dim: dim),
              ),
          ],
        ),
      ),
    );
  }
}

/// The glyph's dot, cross-fading on a change of state. Each change gets its own key, so a
/// state that comes back while its old dot still fades out never meets itself.
class _DotSwitch extends StatefulWidget {
  const _DotSwitch({required this.state, required this.dim});

  final EState state;
  final bool dim;

  @override
  State<_DotSwitch> createState() => _DotSwitchState();
}

class _DotSwitchState extends State<_DotSwitch> {
  int _changes = 0;

  @override
  void didUpdateWidget(_DotSwitch old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _changes++;
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base,
    child: _MaybePulse(
      key: ValueKey((widget.state, _changes)),
      active: widget.state == EState.active,
      child: EStateDot(widget.state, ring: true, dim: widget.dim),
    ),
  );
}

/// [child] fading between 45 % and full opacity for a few beats once [active] begins, then
/// still at full opacity: the blue ring keeps saying "in progress". A pulse that never ends
/// redraws the window 60 times a second for as long as Epicbox or Tor keeps retrying, which on
/// software OpenGL filled every core. Still with reduced motion.
class _MaybePulse extends StatefulWidget {
  const _MaybePulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_MaybePulse> createState() => _MaybePulseState();
}

/// Half-breaths a pulse plays: five end at full opacity, about 8 s.
@visibleForTesting
const int statusPulseBeats = 5;

class _MaybePulseState extends State<_MaybePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600), value: 1)
    // The beats end at full opacity: a frame that lands past the last beat could leave the
    // value part way down.
    ..addStatusListener((status) {
      if (!_c.isAnimating && (status == AnimationStatus.completed || status == AnimationStatus.dismissed) && _played) _c.value = 1;
    });

  /// The beats ran for this active stretch (a new state gives a new pulse: the glyph keys it).
  bool _played = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !widget.active || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _c.stop();
      return widget.child;
    }
    if (!_played) {
      _played = true;
      _c
        ..value = 0
        ..repeat(reverse: true, count: statusPulseBeats);
    }
    return FadeTransition(opacity: Tween(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)), child: widget.child);
  }
}

