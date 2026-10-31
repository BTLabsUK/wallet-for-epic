// SPDX-License-Identifier: Apache-2.0
/// The level illustrations, from the level design's icon kit (`docs/feedback/designs/levels/
/// kit/icons.js`: i-relaxed, i-curious, i-explorer, i-agent, 48 x 48 view boxes). Drawn as
/// paths like [EpicMark], so they need no asset or SVG package: a line in the given colour and
/// the kit's soft gold fill in the same colour at 18 %.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum LevelArtKind {
  /// Level 1, Shallow: closed eyes, at ease.
  relaxed,

  /// Level 2, Deeper: binoculars.
  curious,

  /// Level 3, Deep end: a compass.
  explorer,

  /// Undercover: hat and glasses.
  agent,
}

/// One illustration, [size] square, in [color] (the accent by default). Decorative: the row or
/// stop around it carries the words.
class LevelArt extends StatelessWidget {
  const LevelArt(this.kind, {super.key, this.size = 30, this.color});

  final LevelArtKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _LevelArtPainter(kind, color ?? t.accentText, t.bg)),
      ),
    );
  }
}

class _LevelArtPainter extends CustomPainter {
  const _LevelArtPainter(this.kind, this.color, this.hole);

  final LevelArtKind kind;
  final Color color;

  /// The compass needle's pivot, punched in the background colour.
  final Color hole;

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
    final solid = Paint()..color = color;

    void both(Path p) => canvas
      ..drawPath(p, soft)
      ..drawPath(p, line);
    void rr(RRect r) => both(Path()..addRRect(r));

    switch (kind) {
      case LevelArtKind.relaxed:
        rr(_rr(3, 18, 17, 13, 6.5));
        rr(_rr(28, 18, 17, 13, 6.5));
        canvas.drawPath(
          Path()
            ..moveTo(20, 23)
            ..relativeQuadraticBezierTo(4, -3, 8, 0)
            ..moveTo(3, 22)
            ..lineTo(1, 15)
            ..moveTo(45, 22)
            ..relativeLineTo(2, -7)
            ..moveTo(8, 22)
            ..relativeLineTo(3, -2)
            ..moveTo(33, 22)
            ..relativeLineTo(3, -2),
          line,
        );
      case LevelArtKind.curious:
        rr(_rr(6, 15, 14, 25, 5));
        rr(_rr(28, 15, 14, 25, 5));
        final p = Path();
        for (final x in [9.0, 31.0]) {
          p
            ..moveTo(x, 15)
            ..lineTo(x, 10)
            ..relativeArcToPoint(const Offset(3, -3), radius: const Radius.circular(3))
            ..relativeLineTo(2, 0)
            ..relativeArcToPoint(const Offset(3, 3), radius: const Radius.circular(3))
            ..relativeLineTo(0, 5);
        }
        p
          ..moveTo(20, 25)
          ..relativeLineTo(8, 0);
        canvas
          ..drawPath(p, line)
          ..drawCircle(const Offset(13, 32), 3.5, line)
          ..drawCircle(const Offset(35, 32), 3.5, line);
      case LevelArtKind.explorer:
        canvas
          ..drawCircle(const Offset(24, 24), 19, line)
          ..drawPath(
            Path()
              ..moveTo(24, 7)
              ..relativeLineTo(0, 3)
              ..moveTo(24, 38)
              ..relativeLineTo(0, 3)
              ..moveTo(7, 24)
              ..relativeLineTo(3, 0)
              ..moveTo(38, 24)
              ..relativeLineTo(3, 0),
            line,
          );
        both(
          Path()
            ..moveTo(24, 11)
            ..lineTo(29, 24)
            ..lineTo(24, 37)
            ..lineTo(19, 24)
            ..close(),
        );
        canvas
          ..drawPath(
            Path()
              ..moveTo(24, 11)
              ..lineTo(29, 24)
              ..lineTo(19, 24)
              ..close(),
            solid,
          )
          ..drawCircle(const Offset(24, 24), 1.6, Paint()..color = hole);
      case LevelArtKind.agent:
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
  }

  @override
  bool shouldRepaint(_LevelArtPainter old) => old.kind != kind || old.color != color || old.hole != hole;
}
