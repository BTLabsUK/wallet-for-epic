// SPDX-License-Identifier: Apache-2.0
/// The desktop's one tooltip (the phone's twin is `Tip`). A tooltip names, it never explains:
///  - [ETip]: the 1–3-word name of an icon-only control or glyph, with its state when it has one
///    ("Epicbox: connected"), or a disabled control's short reason ("Off in Settings").
///  - [ETip.value]: the whole of a shortened value (an address, a path, a host, a title, an
///    exact time); [ETip.value] with `mono` for addresses and keys.
///  - [ETip.card]: a status item's hover card (the rail): its name and state lines, no prose.
/// All show on hover after the theme's wait, and at once on a click; they go when the pointer
/// leaves. Never a sentence of explanation, never something the user must read to go on, never
/// the same words as a label already on screen: an explanation is an ⓘ ([EInfoHint], which
/// shows its text on hover and opens the info popover on a click). The look, width and wait
/// come from the theme's `tooltipTheme` only.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind, PointerEnterEvent, PointerExitEvent;
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ETip extends StatefulWidget {
  /// The name of [child] (or why it is off). A null [message] shows [child] alone.
  const ETip(this.message, {super.key, required this.child, this.above = false, this.excludeFromSemantics = false, this.onClick = true})
    : mono = false,
      _card = null;

  /// The whole of a shortened value; [mono] sets it in the monospace face.
  const ETip.value(this.message, {super.key, required this.child, this.mono = false, this.above = false, this.excludeFromSemantics = false, this.onClick = true})
    : _card = null;

  /// A hover card for a status item: [card] holds its name and state lines.
  const ETip.card(Widget card, {super.key, required this.child, this.excludeFromSemantics = false, this.onClick = true})
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

  /// False where a click on [child] opens something that says the same (the ⓘ's popover).
  final bool onClick;

  @override
  State<ETip> createState() => _ETipState();
}

/// Drives the tip itself from the pointer: Flutter's [Tooltip] shows on hover only for a
/// mouse it tracks as hovering, never on a mouse click, and a click clears its hover so the
/// tip does not come back until the pointer leaves and returns. Here a mouse entering starts
/// the theme's wait, a click shows it at once, and leaving hides it.
class _ETipState extends State<ETip> {
  final _tip = GlobalKey<TooltipState>();
  Timer? _wait;

  /// The tip is up because of this state (not Flutter's own hover), so leaving must hide it.
  bool _held = false;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  void _show() {
    _wait?.cancel();
    if (mounted && (_tip.currentState?.ensureTooltipVisible() ?? false)) _held = true;
  }

  void _enter(PointerEnterEvent e) {
    if (e.kind != PointerDeviceKind.mouse) return;
    _wait?.cancel();
    _wait = Timer(TooltipTheme.of(context).waitDuration ?? const Duration(milliseconds: 400), _show);
  }

  void _exit(PointerExitEvent e) {
    _wait?.cancel();
    if (!_held) return;
    _held = false;
    Tooltip.dismissAllToolTips();
  }

  // A press before the wait is over: the click decides, not the hover.
  void _down(PointerDownEvent e) => _wait?.cancel();

  void _up(PointerUpEvent e) {
    // After the press, which hid every tip (Flutter's global pointer route).
    if (widget.onClick) _show();
  }

  Widget _driven(Widget tooltip) => MouseRegion(
    onEnter: _enter,
    onExit: _exit,
    child: Listener(onPointerDown: _down, onPointerUp: _up, child: tooltip),
  );

  @override
  Widget build(BuildContext context) {
    final card = widget._card;
    final excludeFromSemantics = widget.excludeFromSemantics;
    final child = widget.child;
    if (card != null) {
      return _driven(Tooltip(
        key: _tip,
        richMessage: WidgetSpan(child: card),
        // A rich tip takes clicks unless told not to: over the control under it, the first
        // click would only close it.
        ignorePointer: true,
        preferBelow: false,
        verticalOffset: 18.u,
        excludeFromSemantics: excludeFromSemantics,
        child: child,
      ));
    }
    final message = widget.message;
    final mono = widget.mono;
    if (message == null || message.isEmpty) return child;
    return _driven(Tooltip(
      key: _tip,
      message: mono ? null : message,
      richMessage: mono ? TextSpan(text: message, style: context.ts.mono(size: Fs.xs, color: context.dc.text)) : null,
      // Never in the way of a click (a mono tip is a rich one, which takes clicks by default).
      ignorePointer: true,
      preferBelow: !widget.above,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    ));
  }
}
