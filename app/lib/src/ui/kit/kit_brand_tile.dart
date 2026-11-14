// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/brand.dart' show EpicMark;
import '../theme/tokens.dart';
import 'kit_corner_marks.dart';
import 'kit_tokens.dart';

/// The brand tile (HANDOFF 7.7, the frame's `.tile`): the Epic mark on a [size] square tile, with
/// one set of gold corner marks outside it ([KitCornerMarks], `.tile.brk::after`: 9 out, 16 long,
/// 2 thick). Welcome and About use it at [Kit.brandTile] (radius [Kit.rBrandTile]), the unlock
/// screen at [Kit.brandTileSmall] (`.tile.s`, radius [Kit.rBrandTileSmall]). The marks take
/// [inset] of room on every side, which the widget adds to its own box.
class KitBrandTile extends StatelessWidget {
  const KitBrandTile({super.key, this.size = Kit.brandTile, this.inset = 9});

  final double size;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final small = size < Kit.brandTile;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: KitCornerMarks(
          inset: inset,
          arm: 16,
          thickness: 2,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.hair2),
              borderRadius: BorderRadius.circular(small ? Kit.rBrandTileSmall : Kit.rBrandTile),
              boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.16 : 0.10), blurRadius: 80)],
            ),
            child: EpicMark(size: size * 0.49),
          ),
        ),
      ),
    );
  }
}
