/// The step strip of Invite by message (Pairing UX plan 3): Invite, Reply, Finish link,
/// Words, so both sides see where they are. Each step is a bar with its name under it; where a
/// name does not fit its bar at full size (Russian at 360 dp), the bars carry one line under
/// them instead, "Step 3 of 4: Finish link", never a name shrunk past reading.
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';

/// Keys for tests.
const Key pairStepsKey = ValueKey('pair-steps');

class PairSteps extends StatelessWidget {
  const PairSteps({super.key = pairStepsKey, required this.current}) : assert(current >= 1 && current <= 4);

  /// The step shown now, 1 to 4.
  final int current;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final names = [l.pairStepInvite, l.pairStepReply, l.pairStepFinish, l.pairStepWords];
    TextStyle style(int i) => theme.textTheme.labelSmall!.copyWith(
      color: i + 1 == current ? t.text : t.dim,
      fontWeight: i + 1 == current ? FontWeight.w600 : FontWeight.w400,
    );
    Widget bar(int i) => Container(
      height: 3,
      decoration: BoxDecoration(
        color: i + 1 == current ? t.accent : (i + 1 < current ? t.accent.withValues(alpha: 0.55) : t.line),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Semantics(
      container: true,
      label: l.pairStepOf(current, names[current - 1]),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final slot = (box.maxWidth - _gap * (names.length - 1)) / names.length;
            final scaler = MediaQuery.textScalerOf(context);
            final fits = [
              for (var i = 0; i < names.length; i++)
                (TextPainter(text: TextSpan(text: names[i], style: style(i)), textDirection: Directionality.of(context), textScaler: scaler, maxLines: 1)
                      ..layout())
                    .width <=
                    slot,
            ].every((f) => f);
            if (!fits) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < names.length; i++) ...[if (i > 0) const SizedBox(width: _gap), Expanded(child: bar(i))],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l.pairStepOf(current, names[current - 1]), style: style(current - 1)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < names.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        bar(i),
                        const SizedBox(height: 6),
                        Text(names[i], maxLines: 1, textAlign: TextAlign.center, style: style(i)),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
