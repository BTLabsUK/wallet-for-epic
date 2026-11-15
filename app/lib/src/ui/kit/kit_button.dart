// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The look of a [KitButton] (HANDOFF 7.2). One [gold] button a screen, the primary action;
/// [quiet] is the second action, [ghost] a tertiary one with no ground, [danger] an action that
/// cannot be taken back (red text on the quiet ground), [off] a button that is not ready.
enum KitButtonKind { gold, quiet, ghost, danger, off }

/// The redesign's button: 52 tall (a ghost one 44, as the frames draw it), radius 16 (the small one 36 and 12; its hit area
/// reaches 44 without taking the room). It fills the width of its parent unless [expand] is false. A label of several words takes a
/// second line and the button grows with it; a single word stays on one line (ellipsis), never broken inside. Without [onPressed], or as [KitButtonKind.off], it is
/// shown as off and does not react.
class KitButton extends StatelessWidget {
  const KitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = KitButtonKind.gold,
    this.small = false,
    this.icon,
    this.expand = true,
    this.semanticsId,
    this.tall = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KitButtonKind kind;

  /// 36 tall, radius 12, 14 px text: a button inside a card or a row. The look stays 36; the area
  /// that takes a tap is 44 (see [KitHitReach]), over the space around it.
  final bool small;
  final IconData? icon;
  final bool expand;

  /// The stable test id (`TrustIds.*`).
  final String? semanticsId;

  /// A ghost at the 48 touch size instead of the frames' 44: a ghost alone at a page's foot
  /// (the unlock page's Forgot PIN), where the extra height moves nothing.
  final bool tall;

  /// Work is under way: a small spinner before the label (a still arc under reduced motion),
  /// and the button does not react.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final off = busy || onPressed == null || kind == KitButtonKind.off;
    final (Color bg, Color fg) = switch (kind) {
      _ when off => (t.fill, t.faint),
      KitButtonKind.gold => (t.accent, t.accentInk),
      KitButtonKind.quiet => (t.fill, t.text),
      KitButtonKind.ghost => (Colors.transparent, t.dim),
      KitButtonKind.danger => (t.fill, t.risk),
      KitButtonKind.off => (t.fill, t.faint),
    };
    // At a large text size (1.5 and up) a label may wrap, so it gets room above and below; at the
    // sizes the frames are drawn at the button is exactly its minimum height.
    final roomy = MediaQuery.textScalerOf(context).scale(16) >= 24;
    final radius = small ? Kit.rButtonSmall : Kit.rButton;
    final style = (small ? KitType.buttonSmall : KitType.button).copyWith(
      color: fg,
      fontWeight: kind == KitButtonKind.ghost && !off ? FontWeight.w500 : FontWeight.w600,
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox.square(
            dimension: small ? 14 : 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg, value: MediaQuery.disableAnimationsOf(context) ? 0.3 : null),
          ),
          SizedBox(width: small ? 6 : 8),
        ] else if (icon != null) ...[Icon(icon, size: small ? 18 : 20, color: fg), SizedBox(width: small ? 6 : 8)],
        Flexible(
          child: Text(label, style: style, maxLines: label.trim().contains(' ') ? 2 : 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ],
    );
    final button = Semantics(
      button: true,
      enabled: !off,
      excludeSemantics: true,
      label: label,
      onTap: off ? null : onPressed,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: off ? null : onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: small ? Kit.buttonSmall : (kind == KitButtonKind.ghost ? (tall ? Kit.touchMin : Kit.hitMin) : Kit.button), minWidth: small ? 0 : 64),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20, vertical: roomy ? 6 : 0),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
    final sized = expand ? SizedBox(width: double.infinity, child: button) : button;
    return kitId(semanticsId, small ? KitHitReach(child: sized) : sized);
  }
}

/// Gives a child that is smaller than [min] on either side a tap area of [min] × [min], centred on
/// it, without changing its size or its place in the layout (the way `_reach` in the flow header
/// reaches 48 past a 44 bar, but with nothing around it moving). A tap in the added band goes to
/// the child as if it had landed on its edge. Where a neighbour is painted over the band, the
/// neighbour is tested first and wins.
class KitHitReach extends SingleChildRenderObjectWidget {
  const KitHitReach({super.key, super.child, this.min = Kit.hitMin});

  final double min;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitReach(min);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderHitReach).min = min;
}

class _RenderHitReach extends RenderProxyBox {
  _RenderHitReach(this._min);

  double _min;
  set min(double v) {
    if (v != _min) {
      _min = v;
      markNeedsLayout();
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final dx = (_min - size.width) / 2 > 0 ? (_min - size.width) / 2 : 0.0;
    final dy = (_min - size.height) / 2 > 0 ? (_min - size.height) / 2 : 0.0;
    if (position.dx < -dx || position.dx >= size.width + dx || position.dy < -dy || position.dy >= size.height + dy) return false;
    final inside = Offset(position.dx.clamp(0.0, size.width - 0.01), position.dy.clamp(0.0, size.height - 0.01));
    if (hitTestChildren(result, position: inside) || hitTestSelf(inside)) {
      result.add(BoxHitTestEntry(this, inside));
      return true;
    }
    return false;
  }
}
