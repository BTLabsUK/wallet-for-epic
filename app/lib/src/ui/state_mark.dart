// SPDX-License-Identifier: Apache-2.0
/// The one drawing of a state's dot, shared by the desktop's `EStateDot`, the phone's
/// `StateDot` and the server tiles' corner dot ([StateMark], state_language.dart): ok a solid
/// dot, in progress or not known yet a ring, a problem a solid dot with "!", off a ring with a
/// slash. Each app passes its own colours.
library;

import 'package:flutter/widgets.dart';

import '../state_language.dart' show StateMark;

export '../state_language.dart' show StateMark;

/// A [mark] [size] across in [color]; [ink] draws the "!" on a problem dot; [ring] (the page
/// colour behind it) is drawn [ringWidth] wide around it so it stands off a glyph or a tile.
class StateMarkDot extends StatelessWidget {
  const StateMarkDot({
    super.key,
    required this.mark,
    required this.size,
    required this.color,
    required this.ink,
    this.ring,
    this.ringWidth = 2,
  });

  final StateMark mark;

  /// The whole dot's side, ring included.
  final double size;
  final Color color, ink;
  final Color? ring;
  final double ringWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: StateMarkPainter(mark: mark, color: color, ink: ink, ring: ring, ringWidth: ringWidth),
    ),
  );
}

class StateMarkPainter extends CustomPainter {
  const StateMarkPainter({required this.mark, required this.color, required this.ink, this.ring, this.ringWidth = 2});

  final StateMark mark;
  final Color color, ink;
  final Color? ring;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    var r = size.shortestSide / 2;
    if (ring != null) {
      canvas.drawCircle(o, r, Paint()..color = ring!);
      r -= ringWidth;
    }
    if (r <= 0) return;
    final w = (r * 0.45).clamp(1.2, 2.0);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    switch (mark) {
      case StateMark.ok:
        canvas.drawCircle(o, r, Paint()..color = color);
      case StateMark.busy:
        canvas.drawCircle(o, r - w / 2, stroke);
      case StateMark.off:
        // Off by choice: the ring crossed out, calm rather than an error.
        canvas.drawCircle(o, r - w / 2, stroke);
        final d = (r - w / 2) * 0.7071;
        canvas.drawLine(o.translate(-d, d), o.translate(d, -d), stroke);
      case StateMark.problem:
        canvas.drawCircle(o, r, Paint()..color = color);
        final m = Paint()
          ..color = ink
          ..strokeWidth = (r * 0.36).clamp(1.0, 2.0)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(o.translate(0, -r * 0.5), o.translate(0, r * 0.12), m);
        canvas.drawCircle(o.translate(0, r * 0.52), m.strokeWidth * 0.55, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(StateMarkPainter old) =>
      old.mark != mark || old.color != color || old.ink != ink || old.ring != ring || old.ringWidth != ringWidth;
}
