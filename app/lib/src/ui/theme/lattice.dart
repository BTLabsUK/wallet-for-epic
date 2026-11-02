// SPDX-License-Identifier: Apache-2.0
/// The BT Labs lattice: the pointy-top hex lattice of the btlabs.uk hero (lines and nodes,
/// brightest at the centre, fading to the edges), drawn still in the app's text colour at low
/// strength. A quiet graphic for the empty room under a short Recent activity list, on the
/// phone's Home and the desktop's Overview. Decorative: no text, no focus, no semantics.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../recent_activity.dart';

/// Below this much room the lattice draws nothing.
const double latticeMinHeight = 90;

/// The gap between the list above and the top of the lattice.
const double latticeInset = 8;

/// The cell size (hex circumradius) on the phone; the desktop's is [latticeCellDesktop].
const double latticeCellPhone = 24;
const double latticeCellDesktop = 30;

/// How strongly the lattice shows under a short list of [rows] payments: full on an empty
/// list, 75 % at one row, 40 % at three, off from [recentActivityCount] on (where the list
/// is full and "View all" shows). Null rows (still loading): off.
double latticeStrength(int? rows) {
  if (rows == null || showViewAll(rows)) return 0;
  // The approved steps (0, 1 and 3 rows, off at the full list), straight lines between them.
  const knots = <(int, double)>[(0, 1), (1, .75), (3, .4), (recentActivityCount, 0)];
  if (rows <= 0) return 1;
  for (var i = 1; i < knots.length; i++) {
    final (r1, s1) = knots[i];
    if (rows <= r1) {
      final (r0, s0) = knots[i - 1];
      return s0 + (s1 - s0) * (rows - r0) / (r1 - r0);
    }
  }
  return 0;
}

/// The lattice, filling the space it is given. [color] is the text colour of the theme
/// (`context.tokens.text`, `context.dc.text`); [strength] scales it (see [latticeStrength]).
/// [vignette] fades it out towards an ellipse touching the four sides (the desktop's wide
/// area).
class BrandLattice extends StatelessWidget {
  const BrandLattice({
    super.key,
    required this.color,
    required this.strength,
    this.cell = latticeCellPhone,
    this.vignette = false,
  });

  final Color color;
  final double strength;
  final double cell;
  final bool vignette;

  @override
  Widget build(BuildContext context) => strength <= 0
      // Off: nothing drawn, nothing kept.
      ? const SizedBox()
      : ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: LatticePainter(color: color, strength: strength, cell: cell, vignette: vignette),
        ),
      ),
    ),
  );
}

/// Paints [BrandLattice]; once per size, colour and strength.
class LatticePainter extends CustomPainter {
  const LatticePainter({
    required this.color,
    required this.strength,
    required this.cell,
    this.vignette = false,
  });

  final Color color;
  final double strength;
  final double cell;
  final bool vignette;

  // The "Faint" strength: lines and nodes, a base plus a share of the vignette's weight.
  static const _line0 = .012, _line1 = .055, _node0 = .03, _node1 = .14;

  /// Whether a lattice of [size] draws anything at all.
  bool shows(Size size) => strength > 0 && size.width > 0 && size.height >= latticeMinHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (!shows(size)) return;
    final area = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(area)
      ..saveLayer(area, Paint()..color = color.withValues(alpha: strength.clamp(0, 1)))
      ..translate(0, latticeInset);
    final w = size.width, h = size.height - latticeInset;
    _lattice(canvas, w, h);
    if (vignette) {
      // An ellipse touching the four sides: opaque to half way, gone at its edge.
      final unit = Rect.fromLTRB(-1, -1, 1, 1);
      canvas
        ..save()
        ..translate(w / 2, h / 2)
        ..scale(w / 2, h / 2)
        ..drawRect(
          unit,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [.5, 1],
            ).createShader(unit),
        )
        ..restore();
    }
    canvas
      ..restore()
      ..restore();
  }

  void _lattice(Canvas canvas, double w, double h) {
    final r = cell;
    final hw = math.sqrt(3) * r, vs = 1.5 * r, cx0 = w / 2, cy0 = h * .45;
    // Vertices shared by neighbouring hexes are one node, each edge drawn once.
    final ids = <int, int>{};
    final xs = <double>[], ys = <double>[];
    final seen = <int>{};
    final from = <int>[], to = <int>[];
    int node(double x, double y) {
      final k = ((x * 4).round() + 100000) * 200000 + (y * 4).round() + 100000;
      return ids.putIfAbsent(k, () {
        xs.add(x);
        ys.add(y);
        return xs.length - 1;
      });
    }

    final jFrom = -(cy0 / vs).ceil() - 1, jTo = ((h - cy0) / vs).ceil() + 1;
    final iFrom = -(cx0 / hw).ceil() - 1, iTo = ((w - cx0) / hw).ceil() + 1;
    for (var j = jFrom; j <= jTo; j++) {
      for (var i = iFrom; i <= iTo; i++) {
        final cx = cx0 + i * hw + (j.isOdd ? hw / 2 : 0), cy = cy0 + j * vs;
        final v = [
          for (var k = 0; k < 6; k++)
            node(cx + r * math.cos((60 * k - 90) * math.pi / 180), cy + r * math.sin((60 * k - 90) * math.pi / 180)),
        ];
        for (var k = 0; k < 6; k++) {
          final p = v[k], q = v[(k + 1) % 6];
          if (seen.add(p < q ? p * 1000000 + q : q * 1000000 + p)) {
            from.add(p);
            to.add(q);
          }
        }
      }
    }

    // Brightest in the middle of the free space, gone at the sides and near the list above.
    double weight(double x, double y) {
      final dx = (x - w / 2) / (w * .6), dy = (y - cy0) / (h * .62);
      var v = 1 - math.sqrt(dx * dx + dy * dy);
      v = v < 0 ? 0 : v * v * (3 - 2 * v);
      return v * (y / 36).clamp(0, 1);
    }

    final nk = [for (var i = 0; i < xs.length; i++) weight(xs[i], ys[i])];

    // Lines in ten bands of weight, one path and one alpha each.
    final bands = List.generate(10, (_) => Path());
    for (var e = 0; e < from.length; e++) {
      final p = from[e], q = to[e];
      final band = math.min(9, ((nk[p] + nk[q]) / 2 * 10).floor());
      bands[band]
        ..moveTo(xs[p], ys[p])
        ..lineTo(xs[q], ys[q]);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0; k < bands.length; k++) {
      final wk = (k + .5) / 10;
      if (wk < .05) continue;
      canvas.drawPath(bands[k], line..color = color.withValues(alpha: color.a * (_line0 + _line1 * wk)));
    }

    // A 2 px node on each vertex.
    final dot = Paint();
    for (var i = 0; i < xs.length; i++) {
      if (nk[i] < .03) continue;
      canvas.drawRect(
        Rect.fromLTWH(xs[i] - 1, ys[i] - 1, 2, 2),
        dot..color = color.withValues(alpha: color.a * (_node0 + _node1 * nk[i])),
      );
    }
  }

  @override
  bool shouldRepaint(LatticePainter old) =>
      old.color != color || old.strength != strength || old.cell != cell || old.vignette != vignette;
}
