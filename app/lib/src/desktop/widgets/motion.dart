import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Shows [child] when [open]; animates height and opacity together, symmetrically (P2).
///
/// Opening and closing each take [Motion.expand], measured from the state change: ease-out
/// opening, ease-in closing. The fade starts [Motion.fadeLag] ms after the height on the way
/// in and ends that much before it on the way out, so the content never pops. With
/// `MediaQuery.disableAnimations` the widget swaps in one frame, both ways. The child stays
/// mounted while closing (the size transition needs it) and is [Offstage] once fully closed,
/// so it takes no focus and no semantics, and its own animations stop ([TickerMode]).
class ExpandFade extends StatefulWidget {
  const ExpandFade({super.key, required this.open, required this.child, this.axisAlignment = -1.0});

  final bool open;
  final Widget child;

  /// Where the child is pinned while the height changes: -1 top (default), 0 centre, 1 bottom.
  final double axisAlignment;

  @override
  State<ExpandFade> createState() => _ExpandFadeState();
}

class _ExpandFadeState extends State<ExpandFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.expand,
    reverseDuration: Motion.expand,
    value: widget.open ? 1 : 0,
  );
  // A reverse curve is applied to the controller's value (1 → 0), not to elapsed time, so
  // the time-domain "ease-in while closing" is the flipped curve. The fade's interval is in
  // value space too: on the way out it must reach 0 at value fadeLag/240, i.e. 40 ms before
  // the height does.
  late final Animation<double> _size = CurvedAnimation(
    parent: _c,
    curve: Motion.easeOut,
    reverseCurve: Motion.easeIn.flipped,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Interval(_lag, 1, curve: Motion.easeOut),
    reverseCurve: Interval(_lag, 1, curve: Motion.easeIn.flipped),
  );
  static final double _lag = Motion.fadeLag / Motion.expand.inMilliseconds;

  @override
  void didUpdateWidget(ExpandFade old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Offstage(
        offstage: _c.isDismissed,
        // Offstage alone keeps the folded controls in the Tab order; a closing panel leaves
        // the Tab order and the semantics tree at once.
        child: ExcludeFocus(
          excluding: !widget.open,
          child: ExcludeSemantics(
            excluding: !widget.open,
            child: TickerMode(enabled: !_c.isDismissed, child: child!),
          ),
        ),
      ),
      child: SizeTransition(
        sizeFactor: _size,
        alignment: AlignmentDirectional(-1, widget.axisAlignment),
        child: FadeTransition(opacity: _fade, child: widget.child),
      ),
    );
  }
}
