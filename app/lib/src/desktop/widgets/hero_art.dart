// SPDX-License-Identifier: Apache-2.0
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../data/models.dart';
import '../theme/tokens.dart';

/// The Send strip's picture of a method (`assets/hero-*.svg`): the two people dim,
/// the way the payment goes in the accent, a caption under it. 160 × 96 u.
class HeroArt extends StatelessWidget {
  const HeroArt(this.method, {super.key});

  final TxMethod method;

  static String caption(AppLocalizations l, TxMethod m) => switch (m) {
    TxMethod.epicbox => l.deskKitHeroCaptionEpicbox,
    TxMethod.http => l.deskKitHeroCaptionHttp,
    TxMethod.tor => l.deskKitHeroCaptionTor,
    TxMethod.file => l.deskKitHeroCaptionFile,
  };

  static String label(AppLocalizations l, TxMethod m) => switch (m) {
    TxMethod.epicbox => l.deskKitHeroLabelEpicbox,
    TxMethod.http => l.deskKitHeroLabelHttp,
    TxMethod.tor => l.deskKitHeroLabelTor,
    TxMethod.file => l.deskKitHeroLabelFile,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      image: true,
      label: label(context.l10n, method),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(160.u, 96.u),
        painter: _HeroPainter(
          method,
          captionText: caption(context.l10n, method),
          accent: c.accent,
          people: c.dim,
          fill: c.s1,
          caption: ts.h3.copyWith(fontSize: 9.u, fontWeight: FontWeight.w600, color: c.dim, letterSpacing: 9.u * 0.04, height: 1),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.method, {required this.captionText, required this.accent, required this.people, required this.fill, required this.caption});

  final TxMethod method;
  final String captionText;
  final Color accent, people, fill;
  final TextStyle caption;

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
    canvas.save();
    canvas.scale(size.width / 160, size.height / 96);
    final dim = _stroke(people);
    final a = _stroke(accent);
    _person(canvas, 0, dim);
    _person(canvas, 108, dim);
    switch (method) {
      case TxMethod.epicbox:
        canvas.drawPath(_dashed(_line(44, 50, 62, 50), 3, 4), a);
        canvas.drawPath(_dashed(_line(98, 50, 116, 50), 3, 4), a);
        canvas.drawPath(_poly(const [Offset(60, 46), Offset(64, 50), Offset(60, 54)]), a);
        canvas.drawPath(_poly(const [Offset(112, 46), Offset(116, 50), Offset(112, 54)]), a);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 36, 28, 28), const Radius.circular(5)), a);
        canvas.drawPath(_poly(const [Offset(66, 52), Offset(74, 52), Offset(77, 56), Offset(83, 56), Offset(86, 52), Offset(94, 52)]), a);
        canvas.drawCircle(const Offset(92, 36), 7, Paint()..color = fill);
        final clock = _stroke(accent, 1.4);
        canvas.drawCircle(const Offset(92, 36), 7, clock);
        canvas.drawPath(_poly(const [Offset(92, 32.5), Offset(92, 36), Offset(94.4, 37.8)]), clock);
      case TxMethod.http:
        canvas.drawPath(_line(44, 50, 116, 50), a);
        canvas.drawPath(_poly(const [Offset(110, 45), Offset(116, 50), Offset(110, 55)]), a);
        canvas.drawPath(
          Path()
            ..moveTo(72, 44.5)
            ..lineTo(68, 44.5)
            ..arcToPoint(const Offset(68, 55.5), radius: const Radius.circular(5.5), clockwise: false)
            ..lineTo(72, 55.5)
            ..moveTo(88, 44.5)
            ..lineTo(92, 44.5)
            ..arcToPoint(const Offset(92, 55.5), radius: const Radius.circular(5.5))
            ..lineTo(88, 55.5),
          a,
        );
        canvas.drawPath(_line(72, 50, 88, 50), a);
      case TxMethod.tor:
        canvas.drawPath(_dashed(_line(44, 50, 60, 50), 3, 4), a);
        canvas.drawPath(_dashed(_line(100, 50, 116, 50), 3, 4), a);
        canvas.drawPath(_poly(const [Offset(110, 45), Offset(116, 50), Offset(110, 55)]), a);
        for (final r in const [16.0, 10.5, 5.0]) {
          canvas.drawCircle(const Offset(80, 50), r, a);
        }
        final route = Path()
          ..moveTo(60, 50)
          ..cubicTo(66, 38, 94, 38, 100, 50)
          ..moveTo(60, 50)
          ..cubicTo(66, 62, 94, 62, 100, 50);
        canvas.drawPath(_dashed(route, 2, 3), _stroke(people, 1.4));
      case TxMethod.file:
        canvas.drawPath(_poly(const [Offset(70, 36), Offset(83, 36), Offset(90, 43), Offset(90, 64), Offset(70, 64)], close: true), a);
        canvas.drawPath(_poly(const [Offset(83, 36), Offset(83, 43), Offset(90, 43)]), a);
        canvas.drawPath(_line(75, 52, 85, 52), a);
        canvas.drawPath(_line(75, 58, 85, 58), a);
        canvas.drawPath(_line(44, 42, 64, 42), a);
        canvas.drawPath(_poly(const [Offset(58, 38), Offset(64, 42), Offset(58, 46)]), a);
        canvas.drawPath(_line(116, 58, 96, 58), a);
        canvas.drawPath(_poly(const [Offset(102, 54), Offset(96, 58), Offset(102, 62)]), a);
    }
    canvas.restore();
    final tp = TextPainter(
      text: TextSpan(text: captionText, style: caption),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // The SVG's baseline is at y 84; the text's box sits 9 u above it.
    final k = size.height / 96;
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 84 * k - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.method != method || old.captionText != captionText || old.accent != accent || old.people != people || old.fill != fill || old.caption != caption;
}
