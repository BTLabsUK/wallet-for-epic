// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A 28 px pill that names a state or a count ("+37.0 arriving", "Epicbox"). [info] is the blue
/// tint, quiet the neutral fill.
class KitChip extends StatelessWidget {
  const KitChip(this.label, {super.key, this.icon, this.info = false, this.onTap, this.semanticsId});

  final String label;
  final IconData? icon;
  final bool info;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = info ? t.info : t.dim;
    final chip = Container(
      height: Kit.chip,
      padding: const EdgeInsetsDirectional.only(start: 9, end: 11),
      decoration: BoxDecoration(color: info ? t.infoSoft : t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 6)],
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: Kit.hitMin), child: Center(widthFactor: 1, child: chip)),
        ),
      ),
    );
  }
}
