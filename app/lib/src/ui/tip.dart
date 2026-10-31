// SPDX-License-Identifier: Apache-2.0
/// The phone's one tooltip (the desktop's twin is `ETip`). A tooltip names, it never explains:
///  - [Tip]: the 1–3-word name of an icon-only control or glyph, with its state when it has one
///    ("Epicbox: connected"), or a disabled control's short reason ("Off in Settings"). Shown on
///    a long press, so a tap still does what the control does.
///  - [Tip.value]: the whole of a shortened value (an exact amount, an address, a path). Shown on
///    a tap, because the value itself does nothing on a tap.
/// Never a sentence of explanation, never something the user must read to go on, never the same
/// words as a label already on screen: an explanation is an ⓘ ([InfoHint], which opens the info
/// sheet). An `IconButton`'s own `tooltip:` is the same thing as [Tip] and stays. The look,
/// width, wait and show time come from the theme's `tooltipTheme` only.
library;

import 'package:flutter/material.dart';

class Tip extends StatelessWidget {
  /// The name of [child] (or why it is off), on a long press. A null [message] shows [child]
  /// alone.
  const Tip(this.message, {super.key, required this.child, this.above = false, this.excludeFromSemantics = false})
    : _tap = false;

  /// The whole of a shortened value, on a tap.
  const Tip.value(this.message, {super.key, required this.child, this.above = false, this.excludeFromSemantics = false})
    : _tap = true;

  final String? message;
  final Widget child;

  /// Above [child] rather than under it: where the tip would cover what it is about.
  final bool above;

  /// True where [child] carries its own semantics label with the same words.
  final bool excludeFromSemantics;

  final bool _tap;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null || message.isEmpty) return child;
    return Tooltip(
      message: message,
      triggerMode: _tap ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
      preferBelow: !above,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}
