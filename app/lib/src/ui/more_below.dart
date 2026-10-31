import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The app's scroll behaviour, for every MaterialApp: the stock one plus a soft fade on the edge a
/// vertical scroller still runs on past, gone again at the end. Done once here, so no screen,
/// dialog or panel has to ask for it. The fade is the content going transparent, so it takes
/// whatever lies behind it (page, card, dialog) as its colour and follows both themes.
class MoreBelowScrollBehavior extends MaterialScrollBehavior {
  const MoreBelowScrollBehavior();

  /// How far in from the edge the fade reaches.
  static const double fade = 40;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    final vertical = axisDirectionToAxis(details.direction) == Axis.vertical;
    return super.buildScrollbar(context, vertical ? _MoreBelow(details.direction, child) : child, details);
  }
}

class _MoreBelow extends StatefulWidget {
  const _MoreBelow(this.direction, this.child);
  final AxisDirection direction;
  final Widget child;

  @override
  State<_MoreBelow> createState() => _MoreBelowState();
}

class _MoreBelowState extends State<_MoreBelow> {
  bool _more = false;

  bool _onNotification(ScrollNotification n) {
    // Only this scroller's own (depth 0); a nested one has its own wrapper.
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      final more = n.metrics.extentAfter > 1;
      if (more != _more) _set(more);
    }
    return false;
  }

  // Metrics arrive during layout, where a rebuild may not be asked for: then after the frame.
  void _set(bool more) {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() => _more = more);
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && more != _more) setState(() => _more = more);
    });
  }

  bool _onMetrics(ScrollMetricsNotification n) => _onNotification(ScrollUpdateNotification(metrics: n.metrics, context: n.context, depth: n.depth));

  @override
  Widget build(BuildContext context) {
    // Expand = collapse: one short ease-out both ways, instant when the system asks for none.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final up = widget.direction == AxisDirection.up;
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _more ? 1 : 0),
          duration: still ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: widget.child,
          builder: (context, t, child) {
            if (t == 0) return child!;
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) {
                final f = (MoreBelowScrollBehavior.fade / (r.height == 0 ? 1 : r.height)).clamp(0.0, 0.5);
                final solid = Colors.white;
                final gone = Colors.white.withValues(alpha: 1 - t);
                return LinearGradient(
                  begin: up ? Alignment.bottomCenter : Alignment.topCenter,
                  end: up ? Alignment.topCenter : Alignment.bottomCenter,
                  colors: [solid, solid, gone],
                  stops: [0, 1 - f, 1],
                ).createShader(r);
              },
              child: child,
            );
          },
        ),
      ),
    );
  }
}
