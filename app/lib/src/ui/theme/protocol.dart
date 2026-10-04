/// The devices that make the Protocol look recognisable: corner ticks and the measurement grid
/// on the balance panel, the gold-rule section head, accent-edged notices and
/// the payment timeline. The full panel (grid, ticks) is Home's balance only; the
/// screens that open the app or end a task reuse the grid and ticks through `brand.dart`
/// (the Epic mark, glyph tiles, the lit backdrop), and lists and forms stay hairlines.
/// Spec: `docs/themes/protocol/FLUTTER.md`.
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

/// The balance header as the one framed object: grid behind, ticks in front.
class ProtocolBalancePanel extends StatelessWidget {
  const ProtocolBalancePanel({super.key, required this.child, this.padding});

  /// The figure, its fiat value and the status rows.
  final Widget child;

  /// Inside the frame; the header passes less while it shrinks on Send and Receive.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: CustomPaint(
        painter: GridFieldPainter(
          t.text.withValues(alpha: dark ? 0.035 : 0.05),
        ),
        foregroundPainter: CornerTicksPainter(t.tick),
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(18, 14, 12, 14),
          child: child,
        ),
      ),
    );
  }
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

/// A notice on a panel: hairline enclosure with a 2 px accent edge on the left. Waiting notices
/// take [WalletTokens.accent], reminders [WalletTokens.warn].
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

/// One step of [StatusTimeline]. The current step says what is being waited for, never what
/// already happened.
class TimelineStep {
  const TimelineStep(this.label, this.state, {this.detail});

  final String label;
  final TimelineState state;
  final String? detail;
}

/// A payment's progress as square-marked steps joined by a rail.
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
                                ? t.ok
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
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: t.bg,
        border: Border.all(
          width: 2,
          color: switch (state) {
            TimelineState.done => t.ok,
            TimelineState.current => t.accent,
            TimelineState.todo => t.lineStrong,
          },
        ),
        boxShadow: state == TimelineState.current
            ? [BoxShadow(color: t.accentSoft, spreadRadius: 4)]
            : null,
      ),
      child: state == TimelineState.done
          ? Icon(Icons.check, size: 14, color: t.ok)
          : null,
    );
  }
}
