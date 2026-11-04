// SPDX-License-Identifier: Apache-2.0
/// The key picture (docs/design/key-picture.md) as a widget: [KeyPictureView] draws it, and
/// [VerifiedCheck] marks a key on the BT Labs list. The tile is the same in light and dark.
library;

import 'package:flutter/material.dart';

import '../key_picture.dart';
import 'theme/palette.dart';
import 'theme/tokens.dart';

/// The picture of a pairing key on its 7x7-unit tile, [size] logical pixels square. Decorative
/// to screen readers: the words around it carry the meaning. A hairline in the theme's line
/// colour outlines the tile, which on a dark surface would otherwise not show its edge.
class KeyPictureView extends StatelessWidget {
  const KeyPictureView({super.key, required this.picture, this.size = 72, this.framed = false});

  final KeyPicture picture;
  final double size;

  /// Four gold corner brackets just outside the tile; the widget grows by [frameOffset] on
  /// every side.
  final bool framed;

  /// How far outside the tile the brackets sit, at [size].
  static double frameOffsetOf(double size) => size * 0.07;

  @override
  Widget build(BuildContext context) {
    final tile = ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: KeyPicturePainter(picture),
        foregroundPainter: _TileEdge(context.tokens.lineStrong),
      ),
    );
    if (!framed) return tile;
    final o = frameOffsetOf(size);
    return ExcludeSemantics(
      child: CustomPaint(
        foregroundPainter: _Brackets(size, PaletteDark.accentDeep),
        child: Padding(padding: EdgeInsets.all(o), child: tile),
      ),
    );
  }
}

/// Four L-shaped marks around the tile: arm 0.11 of its size, 1.5 px stroke, 0.07 outside.
class _Brackets extends CustomPainter {
  const _Brackets(this.tile, this.colour);

  final double tile;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final arm = tile * 0.11;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt
      ..color = colour;
    // The stroke's centre line, half a stroke in from the widget's edge.
    const h = 0.75;
    final w = size.width - h, b = size.height - h;
    for (final (x, y, dx, dy) in [(h, h, 1.0, 1.0), (w, h, -1.0, 1.0), (h, b, 1.0, -1.0), (w, b, -1.0, -1.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x + dx * arm, y)
          ..lineTo(x, y)
          ..lineTo(x, y + dy * arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Brackets old) => old.tile != tile || old.colour != colour;
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

/// The green check after the name of a key on the BT Labs list: a filled [colour] circle with
/// a dark (or, on a dark green, light) tick. Labelled and tipped with [label].
class VerifiedCheck extends StatelessWidget {
  const VerifiedCheck({super.key, required this.label, required this.colour, this.size = 18});

  final String label;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = colour.computeLuminance() > 0.3 ? const Color(0xFF08080A) : Colors.white;
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: size * 0.72, color: ink),
          ),
        ),
      ),
    );
  }
}
