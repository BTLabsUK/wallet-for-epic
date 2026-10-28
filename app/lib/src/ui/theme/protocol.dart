// SPDX-License-Identifier: Apache-2.0
/// The devices that make the Protocol look recognisable: corner ticks and the measurement grid
/// (on the screens that open the app or end a task, through `brand.dart`: the Epic mark, glyph
/// tiles, the lit backdrop), the sweep along the app bar when a payment lands, the gold-rule
/// section head, accent-edged notices and the payment timeline. Lists and forms stay
/// hairlines.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// L marks on the four corners of an enclosure.
class CornerTicksPainter extends CustomPainter {
  const CornerTicksPainter(this.color, {this.length = 10, this.width = 2});

  final Color color;
  final double length;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final w = size.width, h = size.height, l = length;
    final path = Path()
      ..moveTo(0, l)
      ..lineTo(0, 0)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w, 0)
      ..lineTo(w, l)
      ..moveTo(w, h - l)
      ..lineTo(w, h)
      ..lineTo(w - l, h)
      ..moveTo(l, h)
      ..lineTo(0, h)
      ..lineTo(0, h - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(CornerTicksPainter old) =>
      old.color != color || old.length != length || old.width != width;
}

/// A fine grid that fades out from the top left.
class GridFieldPainter extends CustomPainter {
  const GridFieldPainter(this.color, {this.step = 24});

  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, size.longestSide * 0.9, [
        color,
        color.withValues(alpha: 0),
      ])
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GridFieldPainter old) =>
      old.color != color || old.step != step;
}

/// The accent line that runs along the app bar's foot once when a payment lands: from the
/// centre out to both ends as [progress] goes from 0 to 1, fading from 70 % on, its ends
/// fading into the bar. Nothing at 0 or 1.
class SweepLinePainter extends CustomPainter {
  const SweepLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// The line's height.
  static const double thickness = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOut.transform(progress);
    final opacity = progress < 0.7 ? 1.0 : (1 - progress) / 0.3;
    final half = size.width / 2 * eased;
    final rect = Rect.fromLTRB(
      size.width / 2 - half,
      0,
      size.width / 2 + half,
      thickness,
    );
    final c = color.withValues(alpha: color.a * opacity);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          [c.withValues(alpha: 0), c, c.withValues(alpha: 0)],
          const [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(SweepLinePainter old) =>
      old.progress != progress || old.color != color;
}

/// A section heading: a short gold rule, then the title in sentence case.
class ProtocolSectionHead extends StatelessWidget {
  const ProtocolSectionHead(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(width: 14, height: 2, color: t.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A notice on a panel: hairline enclosure with a 2 px coloured edge on the left. A brand
/// highlight takes [WalletTokens.accent]; a state takes its status colour: in progress
/// [WalletTokens.info], reminders [WalletTokens.warn], done [WalletTokens.ok].
class EdgeCard extends StatelessWidget {
  const EdgeCard({super.key, required this.edge, required this.child});

  final Color edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusSmall),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 2, color: edge),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

enum TimelineState { done, current, todo }

/// The edge of the step being waited for: [StatusTimeline]'s current mark and the payment
/// tile's loader (`TxIcon`) both draw it, so the two read as one thing. A
/// [currentMarkStroke] line in [currentMarkEdge] with a [currentMarkHalo] halo, on a square
/// with rounded corners.
const double currentMarkStroke = 2;

/// The current mark's line: the in-progress blue, never the gold (gold is brand, not state).
Color currentMarkEdge(WalletTokens t) => t.info;

/// The current mark's halo.
Color currentMarkHalo(WalletTokens t) => t.infoSoft;

/// A done mark's line and rail, which a payment's tile closes in when it lands.
Color doneMarkEdge(WalletTokens t) => t.ok;

/// One step of [StatusTimeline]. The current step says what is being waited for, never what
/// already happened.
class TimelineStep {
  const TimelineStep(this.label, this.state, {this.detail});

  final String label;
  final TimelineState state;
  final String? detail;
}

/// A payment's progress as round-marked steps joined by a rail.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _Mark(state: steps[i].state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i].state == TimelineState.done
                                ? doneMarkEdge(t)
                                : t.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: steps[i].state == TimelineState.todo
                                ? t.dim
                                : t.text,
                            fontWeight: steps[i].state == TimelineState.current
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (steps[i].detail case final detail?)
                          Text(
                            detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.dim,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.state});

  final TimelineState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Round, as the send tracker's nodes: squares read as checkboxes.
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.bg,
        border: Border.all(
          width: currentMarkStroke,
          color: switch (state) {
            TimelineState.done => doneMarkEdge(t),
            TimelineState.current => currentMarkEdge(t),
            TimelineState.todo => t.lineStrong,
          },
        ),
        boxShadow: state == TimelineState.current
            ? [BoxShadow(color: currentMarkHalo(t), spreadRadius: 4)]
            : null,
      ),
      child: state == TimelineState.done
          ? Icon(Icons.check, size: 14, color: doneMarkEdge(t))
          : null,
    );
  }
}
