// SPDX-License-Identifier: Apache-2.0
/// The key picture (docs/design/key-picture.md) as a widget: [KeyPictureView] draws it, and
/// [BtLabsBadge] marks a key on the BT Labs list. The tile is the same in light and dark.
library;

import 'package:flutter/material.dart';

import '../key_picture.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// The picture of a pairing key on its 7x7-unit tile, [size] logical pixels square. Decorative
/// to screen readers: the words around it carry the meaning. A hairline in the theme's line
/// colour outlines the tile, which on a dark surface would otherwise not show its edge.
class KeyPictureView extends StatelessWidget {
  const KeyPictureView({super.key, required this.picture, this.size = 72});

  final KeyPicture picture;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: KeyPicturePainter(picture),
      foregroundPainter: _TileEdge(context.tokens.lineStrong),
    ),
  );
}

class _TileEdge extends CustomPainter {
  const _TileEdge(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final r = KeyPicturePainter.tileRadius * size.width / KeyPicturePainter.units;
    canvas.drawRRect(
      RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(r)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colour,
    );
  }

  @override
  bool shouldRepaint(_TileEdge old) => old.colour != colour;
}

/// Draws a [KeyPicture] to fill the canvas' width: tile, then cells at (1 + x, 1 + y) units,
/// square corners, no gap.
class KeyPicturePainter extends CustomPainter {
  const KeyPicturePainter(this.picture);

  final KeyPicture picture;

  /// The tile is 7 units wide: the 5 cells and one unit around them.
  static const double units = 7;
  static const double tileRadius = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / units;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(tileRadius * u)),
      Paint()..color = const Color(keyPictureTile),
    );
    final paint = Paint()
      ..color = Color(picture.colourValue)
      ..isAntiAlias = false;
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        if (picture.filled(x, y)) canvas.drawRect(Rect.fromLTWH((1 + x) * u, (1 + y) * u, u, u), paint);
      }
    }
  }

  @override
  bool shouldRepaint(KeyPicturePainter old) => old.picture.cells != picture.cells || old.picture.colour != picture.colour;
}

/// The BT Labs mark beside [label] ("BT Labs service"): a key on the BT Labs list.
class BtLabsBadge extends StatelessWidget {
  const BtLabsBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EpicMark(size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.accentText)),
        ),
      ],
    );
  }
}
