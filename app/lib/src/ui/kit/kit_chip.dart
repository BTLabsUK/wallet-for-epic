// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A 28 px pill that names a state or a count ("+37.0 arriving", "Epicbox"). [info] is the blue
/// tint, quiet the neutral fill.
class KitChip extends StatelessWidget {
  const KitChip(this.label, {super.key, this.icon, this.leading, this.iconSize = 15, this.info = false, this.large = false, this.bright = false, this.onTap, this.semanticsId, this.semanticsLabel});

  final String label;
  final IconData? icon;
  final double iconSize;

  /// A drawn mark in place of [icon] (a route icon); the caller sizes it.
  final Widget? leading;
  final bool info;

  /// The note chip of the amount page: 34 high, its text in the text colour, a 14 icon.
  final bool large;

  /// The label in the text colour on the neutral fill (`chip q` with `color: var(--text)`).
  final bool bright;
  final VoidCallback? onTap;
  final String? semanticsId;

  /// What a screen reader says when the text leaves something out (the unit).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = info ? t.info : (large || bright ? t.text : t.dim);
    final chip = Container(
      height: large ? 34 : Kit.chip,
      padding: large ? const EdgeInsetsDirectional.only(start: 12, end: 14) : const EdgeInsetsDirectional.only(start: 9, end: 11),
      decoration: BoxDecoration(color: info ? t.infoSoft : t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)] else if (icon != null) ...[Icon(icon, size: large ? 14 : iconSize, color: color), const SizedBox(width: 6)],
          Flexible(child: Text(label, style: KitType.chip.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    if (onTap == null) return kitId(semanticsId, chip);
    // The pill stays 28 tall; the tap target around it is 44.
    return kitId(
      semanticsId,
      Semantics(
        button: true,
        label: semanticsLabel,
        excludeSemantics: semanticsLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: large
              ? chip
              : ConstrainedBox(constraints: const BoxConstraints(minHeight: Kit.touchMin), child: Center(widthFactor: 1, child: chip)),
        ),
      ),
    );
  }
}
