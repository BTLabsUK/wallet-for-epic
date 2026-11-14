// SPDX-License-Identifier: Apache-2.0
/// The Undercover illustration (hat and glasses), drawn as paths like [EpicMark] so it needs no
/// asset or SVG package: a line in the given colour and a soft fill in the same colour at 18 %.
library;

import 'package:flutter/material.dart';

import 'theme/tokens.dart';

/// The illustration, [size] square, in [color] (the accent by default). Decorative: the screen
/// around it carries the words.
class UndercoverArt extends StatelessWidget {
  const UndercoverArt({super.key, this.size = 30, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _UndercoverPainter(color ?? context.tokens.accentText)),
    ),
  );
}

class _UndercoverPainter extends CustomPainter {
  const _UndercoverPainter(this.color);

  final Color color;

  static const double _box = 48;

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _box, size.height / _box);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final soft = Paint()..color = color.withValues(alpha: 0.18);

    void rr(RRect r) => canvas
      ..drawPath(Path()..addRRect(r), soft)
      ..drawPath(Path()..addRRect(r), line);

    final crown = Path()
      ..moveTo(13, 21)
      ..cubicTo(13, 13, 17, 8, 24, 8)
      ..cubicTo(31, 8, 35, 13, 35, 21);
    canvas
      ..drawPath(crown, soft)
      ..drawPath(crown, line);
    rr(_rr(11, 25, 11, 7, 3));
    rr(_rr(26, 25, 11, 7, 3));
    canvas.drawPath(
      Path()
        ..moveTo(7, 21)
        ..lineTo(41, 21)
        ..moveTo(15, 16)
        ..lineTo(33, 16)
        ..moveTo(22, 28)
        ..lineTo(26, 28)
        ..moveTo(9, 44)
        ..cubicTo(11, 39, 16, 36, 24, 36)
        ..cubicTo(32, 36, 37, 39, 39, 44)
        ..moveTo(24, 36)
        ..lineTo(24, 44),
      line,
    );
  }

  @override
  bool shouldRepaint(_UndercoverPainter old) => old.color != color;
}
