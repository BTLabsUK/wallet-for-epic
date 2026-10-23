import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../l10n.dart';
import 'theme/tokens.dart';

/// The ways a payment travels, on Send and Receive: Epicbox (held by the Epicbox server until
/// the recipient's wallet is back), Direct (straight to their wallet at an http(s) or onion
/// address, which must be open), and a transaction file handed over by hand. Tor is not a
/// method: the one Tor switch changes how Epicbox and Direct connect.
enum TransferMethod { epicbox, direct, file }

/// The strip's picture of [method] (the desktop's `HeroArt`, ported): the two people dim, the
/// way the payment goes in the accent, a short caption in Montserrat under it. Drawn on a
/// 160 × 96 grid and scaled to [width] × [height]; one label for screen readers.
class MethodArt extends StatelessWidget {
  const MethodArt(this.method, {super.key, this.width = 88, this.height = 52});

  final TransferMethod method;
  final double width;
  final double height;

  static String caption(AppLocalizations l, TransferMethod m) => switch (m) {
    TransferMethod.epicbox => l.methodArtCaptionEpicbox,
    TransferMethod.direct => l.methodArtCaptionHttp,
    TransferMethod.file => l.methodArtCaptionFile,
  };

  static String label(AppLocalizations l, TransferMethod m) => switch (m) {
    TransferMethod.epicbox => l.methodArtLabelEpicbox,
    TransferMethod.direct => l.methodArtLabelDirect,
    TransferMethod.file => l.methodArtLabelFile,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Semantics(
      image: true,
      label: label(l, method),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(width, height),
        painter: _MethodPainter(
          method,
          caption: caption(l, method).toUpperCase(),
          accent: t.accent,
          people: t.dim,
          fill: t.surface,
          captionStyle: TextStyle(
            fontFamily: t.headFamily,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 8 * 0.04,
            height: 1,
            color: t.dim,
          ),
        ),
      ),
    );
  }
}

class _MethodPainter extends CustomPainter {
  _MethodPainter(
    this.method, {
    required this.caption,
    required this.accent,
    required this.people,
    required this.fill,
    required this.captionStyle,
  });

  final TransferMethod method;
  final String caption;
  final Color accent, people, fill;
  final TextStyle captionStyle;

  Paint _stroke(Color c, [double w = 1.6]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  /// [path] cut into dashes of [on], gaps of [off].
  static Path _dashed(Path path, double on, double off) {
    final out = Path();
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, (d + on).clamp(0, m.length)), Offset.zero);
        d += on + off;
      }
    }
    return out;
  }

  static Path _line(double x1, double y1, double x2, double y2) => Path()
    ..moveTo(x1, y1)
    ..lineTo(x2, y2);

  static Path _poly(List<Offset> pts, {bool close = false}) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    if (close) p.close();
    return p;
  }

  void _person(Canvas canvas, double dx, Paint p) {
    canvas.drawCircle(Offset(26 + dx, 36), 7, p);
    canvas.drawPath(
      Path()
        ..moveTo(12 + dx, 62)
        ..cubicTo(12 + dx, 53.5, 18.3 + dx, 48, 26 + dx, 48)
        ..cubicTo(33.7 + dx, 48, 40 + dx, 53.5, 40 + dx, 62),
      p,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // The grid's drawing sits between y 26 and 86 of 96; the strip shows that band.
    final k = size.width / 160;
    final top = (size.height - 60 * k) / 2;
    canvas.save();
    canvas.translate(0, top - 26 * k);
    canvas.scale(k);
    // Strokes keep their weight however small the picture is drawn.
    final w = 1.6 / k.clamp(0.5, 1.0) * 0.85;
    final dim = _stroke(people, w);
    final a = _stroke(accent, w);
    _person(canvas, 0, dim);
    _person(canvas, 108, dim);
    switch (method) {
      case TransferMethod.epicbox:
        canvas.drawPath(_dashed(_line(44, 50, 62, 50), 3, 4), a);
        canvas.drawPath(_dashed(_line(98, 50, 116, 50), 3, 4), a);
        canvas.drawPath(
          _poly(const [Offset(60, 46), Offset(64, 50), Offset(60, 54)]),
          a,
        );
        canvas.drawPath(
          _poly(const [Offset(112, 46), Offset(116, 50), Offset(112, 54)]),
          a,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(66, 36, 28, 28),
            const Radius.circular(5),
          ),
          a,
        );
        canvas.drawPath(
          _poly(const [
            Offset(66, 52),
            Offset(74, 52),
            Offset(77, 56),
            Offset(83, 56),
            Offset(86, 52),
            Offset(94, 52),
          ]),
          a,
        );
        canvas.drawCircle(const Offset(92, 36), 7, Paint()..color = fill);
        final clock = _stroke(accent, w * 0.9);
        canvas.drawCircle(const Offset(92, 36), 7, clock);
        canvas.drawPath(
          _poly(const [Offset(92, 32.5), Offset(92, 36), Offset(94.4, 37.8)]),
          clock,
        );
      case TransferMethod.direct:
        canvas.drawPath(_line(44, 50, 116, 50), a);
        canvas.drawPath(
          _poly(const [Offset(110, 45), Offset(116, 50), Offset(110, 55)]),
          a,
        );
        canvas.drawPath(
          Path()
            ..moveTo(72, 44.5)
            ..lineTo(68, 44.5)
            ..arcToPoint(
              const Offset(68, 55.5),
              radius: const Radius.circular(5.5),
              clockwise: false,
            )
            ..lineTo(72, 55.5)
            ..moveTo(88, 44.5)
            ..lineTo(92, 44.5)
            ..arcToPoint(
              const Offset(92, 55.5),
              radius: const Radius.circular(5.5),
            )
            ..lineTo(88, 55.5),
          a,
        );
        canvas.drawPath(_line(72, 50, 88, 50), a);
      case TransferMethod.file:
        canvas.drawPath(
          _poly(const [
            Offset(70, 36),
            Offset(83, 36),
            Offset(90, 43),
            Offset(90, 64),
            Offset(70, 64),
          ], close: true),
          a,
        );
        canvas.drawPath(
          _poly(const [Offset(83, 36), Offset(83, 43), Offset(90, 43)]),
          a,
        );
        canvas.drawPath(_line(75, 52, 85, 52), a);
        canvas.drawPath(_line(75, 58, 85, 58), a);
        canvas.drawPath(_line(44, 42, 64, 42), a);
        canvas.drawPath(
          _poly(const [Offset(58, 38), Offset(64, 42), Offset(58, 46)]),
          a,
        );
        canvas.drawPath(_line(116, 58, 96, 58), a);
        canvas.drawPath(
          _poly(const [Offset(102, 54), Offset(96, 58), Offset(102, 62)]),
          a,
        );
    }
    canvas.restore();
    // The caption on the grid's baseline at y 84, narrowed to fit a longer translation.
    final tp = TextPainter(
      text: TextSpan(text: caption, style: captionStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final fit = tp.width > size.width ? size.width / tp.width : 1.0;
    final baseline = top + (84 - 26) * k;
    canvas.save();
    canvas.translate(
      (size.width - tp.width * fit) / 2,
      baseline -
          tp.computeDistanceToActualBaseline(TextBaseline.alphabetic) * fit,
    );
    canvas.scale(fit);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
    tp.dispose();
  }

  @override
  bool shouldRepaint(_MethodPainter old) =>
      old.method != method ||
      old.caption != caption ||
      old.accent != accent ||
      old.people != people ||
      old.fill != fill ||
      old.captionStyle != captionStyle;
}
