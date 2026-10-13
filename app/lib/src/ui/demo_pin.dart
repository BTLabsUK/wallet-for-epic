/// The web demo's PIN, filled in for the visitor: six dots that fill one after another, then
/// [DemoPinFill.onDone]. First run, unlock and the PIN prompt show it in demo mode only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../vault.dart' show pinLength;
import 'theme/tokens.dart';

class DemoPinFill extends StatefulWidget {
  const DemoPinFill({super.key, required this.onDone, this.compact = false});

  /// Called once, when the dots are filled or the visitor skipped.
  final VoidCallback onDone;

  /// For a dialog: one line of text under the dots.
  final bool compact;

  /// Dot i starts filling at i × [_step], for [_fill]; the row then holds for [_hold].
  static const Duration _step = Duration(milliseconds: 110);
  static const Duration _fill = Duration(milliseconds: 160);
  static const Duration _hold = Duration(milliseconds: 280);

  /// The whole animation, a little under 1.1 s.
  static final Duration total = _step * (pinLength - 1) + _fill + _hold;

  @override
  State<DemoPinFill> createState() => _DemoPinFillState();
}

class _DemoPinFillState extends State<DemoPinFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DemoPinFill.total,
  );
  late final List<Animation<double>> _dots = [
    for (var i = 0; i < pinLength; i++)
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _at(DemoPinFill._step * i),
          _at(DemoPinFill._step * i + DemoPinFill._fill),
        ),
      ),
  ];
  late final Animation<double> _hold = CurvedAnimation(
    parent: _controller,
    curve: Interval(_at(DemoPinFill.total - DemoPinFill._hold), 1),
  );
  bool _started = false;
  bool _done = false;

  double _at(Duration time) =>
      time.inMicroseconds / DemoPinFill.total.inMicroseconds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      // Completes only when the animation runs to its end, not when Skip stops it.
      _controller.forward().then((_) => _finish());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  void _skip() {
    if (_done) return;
    _controller.value = 1;
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final row = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // One gentle pulse of the whole row while it holds: 1.0, 1.08, 1.0.
        final pulse = 1 + 0.08 * math.sin(math.pi * _hold.value);
        return Transform.scale(
          scale: pulse,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pinLength; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                _Dot(
                  progress: _dots[i].value,
                  ring: tokens.faint,
                  fill: tokens.accent,
                ),
              ],
            ],
          ),
        );
      },
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Skip is the action for assistive tech; the tap area is a shortcut for pointers.
      excludeFromSemantics: true,
      onTap: _skip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: l.demoPinFilled,
            child: ExcludeSemantics(child: row),
          ),
          SizedBox(height: widget.compact ? 12 : 16),
          // The row's label already says it to a screen reader.
          ExcludeSemantics(
            child: Text(
              l.demoPinFilled,
              style: widget.compact ? text.bodyMedium : text.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 4),
            Text(
              l.demoPinOwnInApp,
              style: text.bodyMedium?.copyWith(color: tokens.dim),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _skip,
              child: Text(l.demoPinSkip),
            ),
          ),
        ],
      ),
    );
  }
}

/// One PIN digit: an empty ring, with the fill growing and fading in over it as [progress]
/// goes from 0 to 1.
class _Dot extends StatelessWidget {
  const _Dot({required this.progress, required this.ring, required this.fill});

  static const double _size = 14;

  final double progress;
  final Color ring;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final scale = 0.4 + 0.6 * Curves.easeOutBack.transform(progress);
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 1.5),
            ),
          ),
          if (progress > 0)
            Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill.withValues(alpha: fill.a * progress),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
