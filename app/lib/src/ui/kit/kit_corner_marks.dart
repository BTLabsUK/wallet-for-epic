// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Four L-shaped marks in deep gold around [child], drawn [inset] outside its edge (HANDOFF
/// 5.5): the brand's frame on a QR code and on the needs-you card. They are painted outside
/// the child's box, so leave [inset] of room around it.
class KitCornerMarks extends StatelessWidget {
  const KitCornerMarks({super.key, required this.child, this.inset = 6, this.arm = 11, this.thickness = 1.5, this.color});

  final Widget child;
  final double inset;
  final double arm;
  final double thickness;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.tokens.goldDeep;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -inset,
          top: -inset,
          right: -inset,
          bottom: -inset,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: CustomPaint(painter: _MarksPainter(c, arm, thickness)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.color, this.arm, this.thickness);

  final Color color;
  final double arm;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;
    final h = thickness / 2;
    final w = size.width - h, b = size.height - h;
    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x + dx * arm, y)
      ..lineTo(x, y)
      ..lineTo(x, y + dy * arm);
    canvas.drawPath(corner(h, h, 1, 1), paint);
    canvas.drawPath(corner(w, h, -1, 1), paint);
    canvas.drawPath(corner(h, b, 1, -1), paint);
    canvas.drawPath(corner(w, b, -1, -1), paint);
  }

  @override
  bool shouldRepaint(_MarksPainter old) => old.color != color || old.arm != arm || old.thickness != thickness;
}
