/// The step strip of Invite by message (Pairing UX plan 3): Invite, Reply, Finish link,
/// Words, so both sides see where they are. Each step is a bar with its name under it; the
/// names shrink rather than wrap or cut, as the long German and Russian ones need.
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final names = [l.pairStepInvite, l.pairStepReply, l.pairStepFinish, l.pairStepWords];
    return Semantics(
      container: true,
      label: l.pairStepOf(current, names[current - 1]),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < names.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: i + 1 == current
                            ? t.accent
                            : (i + 1 < current ? t.accent.withValues(alpha: 0.55) : t.line),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        names[i],
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: i + 1 == current ? t.text : t.dim,
                          fontWeight: i + 1 == current ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
