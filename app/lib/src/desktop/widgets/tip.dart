// SPDX-License-Identifier: Apache-2.0
/// The desktop's one tooltip (the phone's twin is `Tip`). A tooltip names, it never explains:
///  - [ETip]: the 1–3-word name of an icon-only control or glyph, with its state when it has one
///    ("Epicbox: connected"), or a disabled control's short reason ("Off in Settings").
///  - [ETip.value]: the whole of a shortened value (an address, a path, a host, a title, an
///    exact time); [ETip.value] with `mono` for addresses and keys.
///  - [ETip.card]: a status item's hover card (the rail): its name and state lines, no prose.
/// All show on hover after the theme's wait. Never a sentence of explanation, never something
/// the user must read to go on, never the same words as a label already on screen: an
/// explanation is an ⓘ ([EInfoHint], which opens the info popover). The look, width and wait
/// come from the theme's `tooltipTheme` only.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ETip extends StatelessWidget {
  /// The name of [child] (or why it is off). A null [message] shows [child] alone.
  const ETip(this.message, {super.key, required this.child, this.above = false, this.excludeFromSemantics = false})
    : mono = false,
      _card = null;

  /// The whole of a shortened value; [mono] sets it in the monospace face.
  const ETip.value(this.message, {super.key, required this.child, this.mono = false, this.above = false, this.excludeFromSemantics = false})
    : _card = null;

  /// A hover card for a status item: [card] holds its name and state lines.
  const ETip.card(Widget card, {super.key, required this.child, this.excludeFromSemantics = false})
    : message = null,
      mono = false,
      above = true,
      _card = card;

  final String? message;
  final Widget child;
  final bool mono;

  /// Above [child] rather than under it: where the tip would cover what it is about.
  final bool above;

  /// True where [child] carries its own semantics label with the same words.
  final bool excludeFromSemantics;

  final Widget? _card;

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card != null) {
      return Tooltip(
        richMessage: WidgetSpan(child: card),
        // A rich tip takes clicks unless told not to: over the control under it, the first
        // click would only close it.
        ignorePointer: true,
        preferBelow: false,
        verticalOffset: 18.u,
        excludeFromSemantics: excludeFromSemantics,
        child: child,
      );
    }
    final message = this.message;
    if (message == null || message.isEmpty) return child;
    return Tooltip(
      message: mono ? null : message,
      richMessage: mono ? TextSpan(text: message, style: context.ts.mono(size: Fs.xs, color: context.dc.text)) : null,
      // Never in the way of a click (a mono tip is a rich one, which takes clicks by default).
      ignorePointer: true,
      preferBelow: !above,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}
