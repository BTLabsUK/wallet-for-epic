// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The look of a [KitButton] (HANDOFF 7.2). One [gold] button a screen, the primary action;
/// [quiet] is the second action, [ghost] a tertiary one with no ground, [danger] an action that
/// cannot be taken back (red text on the quiet ground), [off] a button that is not ready.
enum KitButtonKind { gold, quiet, ghost, danger, off }

/// The redesign's button: 52 tall (a ghost one 44, as the frames draw it), radius 16 (the small one 36 and 12). It fills the width of
/// its parent unless [expand] is false. Without [onPressed], or as [KitButtonKind.off], it is
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
  });

  final String label;
  final VoidCallback? onPressed;
  final KitButtonKind kind;

  /// 36 tall, radius 12, 14 px text: a button inside a card or a row.
  final bool small;
  final IconData? icon;
  final bool expand;

  /// The test drivers' name (`TrustIds.*`).
  final String? semanticsId;

  /// A ghost at the 48 touch size instead of the frames' 44: a ghost alone at a page's foot
  /// (the unlock page's Forgot PIN), where the extra height moves nothing.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final off = onPressed == null || kind == KitButtonKind.off;
    final (Color bg, Color fg) = switch (kind) {
      _ when off => (t.fill, t.faint),
      KitButtonKind.gold => (t.accent, t.accentInk),
      KitButtonKind.quiet => (t.fill, t.text),
      KitButtonKind.ghost => (Colors.transparent, t.dim),
      KitButtonKind.danger => (t.fill, t.risk),
      KitButtonKind.off => (t.fill, t.faint),
    };
    final radius = small ? Kit.rButtonSmall : Kit.rButton;
    final style = (small ? KitType.buttonSmall : KitType.button).copyWith(
      color: fg,
      fontWeight: kind == KitButtonKind.ghost && !off ? FontWeight.w500 : FontWeight.w600,
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: small ? 18 : 20, color: fg), SizedBox(width: small ? 6 : 8)],
        Flexible(
          child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
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
              padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
    return kitId(semanticsId, expand ? SizedBox(width: double.infinity, child: button) : button);
  }
}
