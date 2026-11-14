// SPDX-License-Identifier: Apache-2.0
/// Home's last [homeChartDays] days: what came in and went out, and the balance as a step line, drawn from
/// the confirmed payments the wallet holds (nothing is fetched for it).
library;

import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The days the chart covers.
const homeChartDays = 30;

/// The confirmed payments of the last [homeChartDays] before [now]: money in, money out (with
/// fees), and the balance after each, oldest first, starting from what it was before them
/// ([total] is the balance now).
({int inSum, int outSum, List<(DateTime, int)> steps}) homeChartData(List<Tx> txs, int total, DateTime now) {
  final from = now.subtract(const Duration(days: homeChartDays));
  final recent = [for (final t in txs) if (t.state == TxState.confirmed && t.created.isAfter(from)) t]..sort((a, b) => a.created.compareTo(b.created));
  int net(Tx t) => t.incoming ? t.amount : -(t.amount + t.fee);
  var inSum = 0;
  var outSum = 0;
  for (final t in recent) {
    if (t.incoming) {
      inSum += t.amount;
    } else {
      outSum += t.amount + t.fee;
    }
  }
  var balance = total - recent.fold<int>(0, (a, t) => a + net(t));
  final steps = <(DateTime, int)>[(from, balance)];
  for (final t in recent) {
    balance += net(t);
    steps.add((t.created, balance));
  }
  steps.add((now, balance));
  return (inSum: inSum, outSum: outSum, steps: steps);
}

/// The chart beside Home's balance: its caption, in and out, and the step line.
class HomeChart extends StatelessWidget {
  const HomeChart({super.key, required this.txs, required this.total, this.now});

  final List<Tx> txs;
  final int total;

  /// The chart's end; the clock when null (tests set it).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final d = homeChartData(txs, total, now ?? DateTime.now());
    return Column(
      key: const ValueKey('home-chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Sp.x3,
          runSpacing: Sp.x1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.deskOvLast30, style: ts.small.copyWith(color: c.dim)),
            Text('+${formatEpicL(l, d.inSum)} ${l.deskOvIn}', style: ts.mono(size: Fs.xs, color: c.ok)),
            Text('−${formatEpicL(l, d.outSum)} ${l.deskOvOut}', style: ts.mono(size: Fs.xs, color: c.txSent)), // l10n-ok: the minus sign
          ],
        ),
        SizedBox(height: Sp.x3),
        ExcludeSemantics(
          child: SizedBox(
            height: 44.u,
            child: CustomPaint(painter: _StepPainter(d.steps, line: c.accent, fill: c.accentFaint)),
          ),
        ),
      ],
    );
  }
}

class _StepPainter extends CustomPainter {
  _StepPainter(this.steps, {required this.line, required this.fill});

  final List<(DateTime, int)> steps;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.length < 2) return;
    final t0 = steps.first.$1.millisecondsSinceEpoch.toDouble();
    final t1 = steps.last.$1.millisecondsSinceEpoch.toDouble();
    final values = [for (final s in steps) s.$2];
    final lo = values.reduce((a, b) => a < b ? a : b).toDouble();
    final hi = values.reduce((a, b) => a > b ? a : b).toDouble();
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    double x(DateTime t) => t1 == t0 ? 0 : (t.millisecondsSinceEpoch - t0) / (t1 - t0) * size.width;
    // A flat line sits mid-height; otherwise the lowest balance leaves a tenth of the room.
    double y(int v) => hi == lo ? size.height / 2 : size.height - ((v - lo) / span * 0.8 + 0.1) * size.height;
    final path = Path()..moveTo(0, y(steps.first.$2));
    for (var i = 1; i < steps.length; i++) {
      path.lineTo(x(steps[i].$1), y(steps[i - 1].$2));
      path.lineTo(x(steps[i].$1), y(steps[i].$2));
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_StepPainter old) => old.steps != steps || old.line != line || old.fill != fill;
}
