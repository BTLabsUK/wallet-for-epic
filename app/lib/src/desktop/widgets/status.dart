import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';

/// One state mapping for the rail, the Receive header, panel dots and Settings heads.
enum EState { ok, warn, risk, off }

EState stateOf(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => EState.ok,
  ServiceHealth.slow || ServiceHealth.checking => EState.warn,
  ServiceHealth.down => EState.risk,
  ServiceHealth.off => EState.off,
};

Color stateColor(DeskColors c, EState s) => switch (s) {
  EState.ok => c.ok,
  EState.warn => c.warn,
  EState.risk => c.risk,
  EState.off => c.faint,
};

/// Lit bars of [ESignalBars] for a state.
int stateBars(EState s) => switch (s) {
  EState.ok => 3,
  EState.warn => 2,
  EState.risk => 1,
  EState.off => 0,
};

/// The one glyph per method, shared with the phone.
IconData methodIcon(TxMethod m) => switch (m) {
  TxMethod.epicbox => EIcons.epicbox,
  TxMethod.http => EIcons.http,
  TxMethod.tor => EIcons.tor,
  TxMethod.file => EIcons.file,
};

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
