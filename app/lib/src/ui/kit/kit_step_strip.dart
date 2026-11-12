// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The three-step strip under the header of a two-phone or file flow (HANDOFF 4, 7.9):
/// "1 · Show your code  2 · Scan their answer  3 · Done". Each step is a 3 px bar over its
/// label: done in deep gold, the [current] one in gold with a bright label, the rest faint.
/// [labels] are the steps' words without the number; the strip adds "1 · ". A screen reader
/// hears "Step 2 of 3: Scan their answer".
class KitStepStrip extends StatelessWidget {
  const KitStepStrip({super.key, required this.labels, required this.current, this.semanticsId});

  final List<String> labels;

  /// The step in progress, from 0. A value past the last step marks them all done.
  final int current;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final n = labels.length;
    final shown = current.clamp(0, n - 1);
    final cells = <Widget>[];
    for (var i = 0; i < n; i++) {
      final done = i < current;
      final now = i == shown && current < n;
      final bar = now ? t.accent : (done ? t.goldDeep : t.hair);
      final color = now ? t.text : (done ? t.dim : t.faint);
      if (i > 0) cells.add(const SizedBox(width: 6));
      cells.add(
        Flexible(
          flex: labels[i].length + 4,
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: l.phoneStepOf(i + 1, n, labels[i]),
            value: now ? l.phoneKitStepNow : (done ? l.phoneKitStepDone : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${i + 1} · ${labels[i]}',
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: KitType.tag.copyWith(fontSize: 12, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return kitId(
      semanticsId,
      Padding(
        padding: const EdgeInsets.fromLTRB(Kit.gutter, 10, Kit.gutter, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells),
      ),
    );
  }
}
