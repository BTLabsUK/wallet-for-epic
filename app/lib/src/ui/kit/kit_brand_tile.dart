// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/brand.dart';
import 'kit_corner_marks.dart';
import 'kit_tokens.dart';

/// The brand tile (HANDOFF 7.7): the Epic mark on a [size] square tile with the four gold corner
/// marks outside it ([KitCornerMarks]). Welcome uses it at [Kit.brandTile], the unlock screen
/// at 64. The marks take [inset] of room on every side, which the widget adds to its own box.
class KitBrandTile extends StatelessWidget {
  const KitBrandTile({super.key, this.size = Kit.brandTile, this.inset = 9});

  final double size;
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(inset),
    child: KitCornerMarks(
      inset: inset,
      arm: size * 0.2 + 4,
      child: GlyphTile(size: size, child: EpicMark(size: size * 0.52)),
    ),
  );
}
