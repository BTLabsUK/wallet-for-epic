// SPDX-License-Identifier: Apache-2.0
/// The desktop's help popover: what an info or help icon ([EInfoHint]) opens on a click, Enter
/// or Space. The hover tooltip it replaces (26.10.24 and before) came after a pause, ran as wide
/// as its sentence and went away on the smallest mouse move (two testers on Windows). The
/// popover opens at once, stays until a click outside, Esc or its ✕, wraps at a reading width,
/// scrolls when it is long and stays inside the window. The phone's twin is the info sheet
/// (`ui/info_hint.dart`).
///
/// It is a route over a clear barrier (`showGeneralDialog`): the barrier takes the outside
/// click, Esc pops it, the focus moves into it and comes back to what had it when it closes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;

import '../desk_l10n.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'selectable.dart';

/// The popover's reading width: a sentence wraps at about 70 characters.
double get infoPopoverMaxWidth => 400.u;

/// The popover's tallest, before its body scrolls: 60 % of the window, at most this.
double get infoPopoverMaxHeight => 420.u;

/// Opens the popover for [text] (with [title] and [icon] on its first line) next to [anchor],
/// the icon's rectangle in the root navigator's coordinates. Returns when it closes.
Future<void> showEInfoPopover(BuildContext context, {required Rect anchor, required String text, String? title, IconData? icon}) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.commonClose,
      barrierColor: Colors.transparent,
      transitionDuration: Dur.fast,
      pageBuilder: (context, _, _) => CustomSingleChildLayout(
        delegate: InfoPopoverLayout(anchor: anchor, margin: Sp.x2, gap: Sp.x1, maxWidth: infoPopoverMaxWidth, maxHeight: infoPopoverMaxHeight),
        child: EInfoPopover(title: title, text: text, icon: icon),
      ),
      transitionBuilder: (context, anim, _, child) =>
          MediaQuery.disableAnimationsOf(context) ? child : FadeTransition(opacity: anim, child: child),
    );

/// Where the popover goes: under the icon with its left edge on the icon's, reading to the
/// right. With no room under it, above; with no room to the right, its right edge on the
/// icon's. Never outside the window less [margin], never wider than [maxWidth] or taller than
/// 60 % of the window or [maxHeight].
class InfoPopoverLayout extends SingleChildLayoutDelegate {
  const InfoPopoverLayout({required this.anchor, required this.margin, required this.gap, required this.maxWidth, required this.maxHeight});

  final Rect anchor;
  final double margin, gap, maxWidth, maxHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.max(0, math.min(maxWidth, constraints.maxWidth - 2 * margin)),
    maxHeight: math.max(0, math.min(math.min(maxHeight, constraints.maxHeight * 0.6), constraints.maxHeight - 2 * margin)),
  );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.left;
    if (x + childSize.width > size.width - margin) x = anchor.right - childSize.width;
    x = x.clamp(margin, math.max(margin, size.width - margin - childSize.width));
    var y = anchor.bottom + gap;
    if (y + childSize.height > size.height - margin) {
      final above = anchor.top - gap - childSize.height;
      y = above >= margin ? above : size.height - margin - childSize.height;
    }
    y = y.clamp(margin, math.max(margin, size.height - margin - childSize.height));
    return Offset(x.roundToDouble(), y.roundToDouble());
  }

  @override
  bool shouldRelayout(InfoPopoverLayout old) =>
      anchor != old.anchor || margin != old.margin || gap != old.gap || maxWidth != old.maxWidth || maxHeight != old.maxHeight;
}

/// The popover itself: the s4 card with its ✕; [icon] and [title] on the first line and
/// [text] under it, or [text] alone beside the ✕. The text scrolls when the card is at its
/// tallest and is selectable. Esc closes it from anywhere inside.
class EInfoPopover extends StatefulWidget {
  const EInfoPopover({super.key, required this.text, this.title, this.icon});

  final String text;
  final String? title;
  final IconData? icon;

  @override
  State<EInfoPopover> createState() => _EInfoPopoverState();
}

class _EInfoPopoverState extends State<EInfoPopover> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final title = widget.title;
    final close = EIconButton(
      key: const ValueKey('info-popover-close'),
      icon: EIcons.close,
      label: l.commonClose,
      size: EBtnSize.inline,
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget body(EdgeInsets padding) => Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: padding,
        child: Text(widget.text, key: const ValueKey('info-popover-text'), style: ts.body),
      ),
    );
    final Widget content;
    if (title == null) {
      // The sentence starts level with the ✕ and runs under it when it is longer.
      content = Padding(
        padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x2, Sp.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: body(EdgeInsets.only(top: Sp.x1, bottom: Sp.x1, right: Sp.x2))),
            close,
          ],
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x2, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: Sp.x1, right: Sp.x2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.icon != null) ...[
                          Padding(padding: EdgeInsets.only(top: 2.u), child: Icon(widget.icon, size: Ctl.iconSm, color: c.accentText)),
                          SizedBox(width: Sp.x2),
                        ],
                        Flexible(child: Semantics(header: true, child: Text(title, style: ts.label))),
                      ],
                    ),
                  ),
                ),
                close,
              ],
            ),
          ),
          Flexible(child: body(EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x4, Sp.x4))),
        ],
      );
    }
    return Semantics(
      container: true,
      role: SemanticsRole.dialog,
      label: title,
      child: Actions(
        actions: {DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => Navigator.of(context).maybePop())},
        // The popover takes the focus when it opens, so Esc reaches it at once and Tab finds
        // its ✕; the icon that opened it gets the focus back when it closes.
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          debugLabel: 'info popover',
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.s4,
                border: Border.all(color: c.lineStrong),
                borderRadius: BorderRadius.circular(Rad.sm),
                boxShadow: [BoxShadow(color: c.scrim, blurRadius: 16.u, offset: Offset(0, 4.u))],
              ),
              child: DeskSelectable(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
