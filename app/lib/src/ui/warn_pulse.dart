/// A status dot that has been amber for a while sends out one short echo, so a node that is
/// behind is not mistaken for a stuck payment: two soft rings grow out of the dot and fade,
/// like a sonar ping, then the dot stays as it is. Shared by the phone's [StatusGlyph] and the
/// desktop's [EStatusGlyph].
///
/// The echo is bounded on purpose. Flutter's desktop embedders present the whole window on
/// every frame, so anything that animates for as long as a state lasts keeps the window busy:
/// the breathing pulse this replaced cost most of a core on software OpenGL (BUGS B2). The
/// echo runs for [warnEchoLength], then nothing: no ticker, timer or frame is scheduled until
/// the next amber stretch, and a stretch that starts within [warnEchoCooldown] of the last
/// echo gets none.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How long a dot is continuously amber before its echo. A warning that clears sooner (one
/// slow node check) never echoes.
const Duration warnPulseDelay = Duration(seconds: 15);

/// A dot echoes at most once in this long. A status that flaps (the node keeper's can change
/// every few minutes) stays steady in between, and several amber dots cannot keep the window
/// busy between them.
const Duration warnEchoCooldown = Duration(minutes: 5);

/// Rings in one echo; each starts [warnEchoGap] after the one before and lives [warnEchoRing].
const int warnEchoRings = 2;
const Duration warnEchoRing = Duration(milliseconds: 1000);
const Duration warnEchoGap = Duration(milliseconds: 360);

/// The whole echo: 1360 ms, about 82 frames at 60 Hz, once per amber stretch.
final Duration warnEchoLength = warnEchoRing + warnEchoGap * (warnEchoRings - 1);

/// How far a ring travels, in widths of the dot: from the dot's edge to this far beyond it.
/// 0.75 keeps the rings inside a status glyph's 44 px target and the title bar's height.
const double warnEchoReach = 0.75;

/// A ring's opacity when it leaves the dot; each later ring starts fainter.
const double warnEchoPeak = 0.55;
const double warnEchoFalloff = 0.7;

/// The clock the cooldown reads. Tests replace it.
@visibleForTesting
DateTime Function() warnEchoNow = DateTime.now;

/// [child] echoes once in [color] after [active] (amber) has held for [warnPulseDelay], then
/// stays plain. A fresh [active] stretch waits the delay again, and echoes only if the last
/// echo is more than [warnEchoCooldown] ago. Never echoes with reduced motion.
///
/// The rings are drawn around [child], outside its box, without changing its layout; the
/// parent must not clip (the glyphs' stacks use `Clip.none`).
class WarnPulse extends StatefulWidget {
  const WarnPulse({
    super.key,
    required this.active,
    required this.color,
    required this.child,
    this.delay = warnPulseDelay,
    this.cooldown = warnEchoCooldown,
  });

  final bool active;

  /// How long [active] holds before the echo, and the least time between two echoes. The
  /// app keeps the defaults; a showcase shortens them.
  final Duration delay, cooldown;

  /// The ring colour: the dot's amber, dimmed as the dot is.
  final Color color;

  final Widget child;

  @override
  State<WarnPulse> createState() => _WarnPulseState();
}

class _WarnPulseState extends State<WarnPulse> with SingleTickerProviderStateMixin {
  /// Runs only for one echo: [AnimationController.forward] once, then it stops itself and
  /// [_echoing] drops the layer. [dispose] disposes it with the state.
  late final AnimationController _c = AnimationController(vsync: this, duration: warnEchoLength)..addStatusListener(_onStatus);

  /// Pending only during the delay; null before and after.
  Timer? _timer;

  /// When the last echo started, for the cooldown.
  DateTime? _lastEcho;

  bool _reduced = false;

  /// The echo is drawing; until then and after, the child is built bare, with no layer around it.
  bool _echoing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(WarnPulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync(restart: true);
  }

  void _sync({required bool restart}) {
    if (!widget.active || _reduced) {
      _timer?.cancel();
      _timer = null;
      if (_c.isAnimating) _c.stop();
      _echoing = false;
      return;
    }
    if (!restart && (_timer != null || _echoing)) return;
    _timer?.cancel();
    final last = _lastEcho;
    if (last != null && warnEchoNow().difference(last) < widget.cooldown) return;
    _timer = Timer(widget.delay, () {
      _timer = null;
      if (!mounted || !widget.active || _reduced) return;
      _lastEcho = warnEchoNow();
      setState(() => _echoing = true);
      _c.forward(from: 0);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _echoing = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_echoing) return widget.child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Under the dot: the rings come out from beneath it. Its own boundary, so the frames of
        // the echo rasterise a few dozen pixels, not the bar or rail around it.
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: WarnEchoPainter(progress: _c, color: widget.color)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// The rings of one echo at [progress] 0..1 over [warnEchoLength]: each grows from the dot's
/// edge outward with an ease-out, thinning and fading as it goes, so the motion is quick to
/// leave and slow to settle, like a ripple.
class WarnEchoPainter extends CustomPainter {
  WarnEchoPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    final r0 = size.shortestSide / 2;
    final reach = size.shortestSide * warnEchoReach;
    final total = warnEchoLength.inMilliseconds;
    final now = progress.value * total;
    for (var i = 0; i < warnEchoRings; i++) {
      final t = (now - i * warnEchoGap.inMilliseconds) / warnEchoRing.inMilliseconds;
      if (t <= 0 || t >= 1) continue;
      final grow = Curves.easeOutCubic.transform(t);
      final fade = Curves.easeInQuad.transform(t);
      final r = r0 + reach * grow;
      final alpha = warnEchoPeak * math.pow(warnEchoFalloff, i) * (1 - fade);
      final paint = Paint()
        ..color = color.withValues(alpha: color.a * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 - 0.5 * grow;
      canvas.drawCircle(o, r, paint);
    }
  }


  @override
  bool shouldRepaint(WarnEchoPainter old) => old.progress != progress || old.color != color;
}
