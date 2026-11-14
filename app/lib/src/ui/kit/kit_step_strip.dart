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
    final style = KitType.tag.copyWith(fontSize: 12);
    final texts = [for (var i = 0; i < n; i++) '${i + 1} · ${labels[i]}'];
    return kitId(
      semanticsId,
      Padding(
        padding: const EdgeInsets.fromLTRB(Kit.gutter, 10, Kit.gutter, 0),
        child: LayoutBuilder(
          builder: (context, box) {
            final widths = _widths(texts, style, box.maxWidth - _gap * (n - 1));
            final cells = <Widget>[];
            for (var i = 0; i < n; i++) {
              final done = i < current;
              final now = i == shown && current < n;
              final bar = now ? t.accent : (done ? t.goldDeep : t.hair);
              final color = now ? t.text : (done ? t.dim : t.faint);
              if (i > 0) cells.add(const SizedBox(width: _gap));
              cells.add(
                SizedBox(
                  width: widths[i],
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
                            texts[i],
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                            style: style.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
          },
        ),
      ),
    );
  }

  /// The CSS `.steps3 span{flex:1;white-space:nowrap}` sizing: equal shares, but a step whose
  /// label is wider than its share keeps the label's width and the others split what is left.
  /// When the labels together do not fit, each takes its share of the room by label width.
  /// `.steps3` has a 6 gap, but its nowrap labels then nearly touch; 12 keeps them apart.
  static const double _gap = 12;

  static List<double> _widths(List<String> texts, TextStyle style, double room) {
    final n = texts.length;
    final need = [
      for (final s in texts)
        (TextPainter(
          text: TextSpan(text: s, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
        )..layout()).width.ceilToDouble(),
    ];
    final total = need.fold<double>(0, (a, b) => a + b);
    if (total >= room) return [for (final w in need) room * w / total];
    final widths = List<double?>.filled(n, null);
    var left = room;
    var free = n;
    var changed = true;
    while (changed) {
      changed = false;
      final share = left / free;
      for (var i = 0; i < n; i++) {
        if (widths[i] == null && need[i] > share) {
          widths[i] = need[i];
          left -= need[i];
          free--;
          changed = true;
        }
      }
    }
    final share = free > 0 ? left / free : 0.0;
    return [for (final w in widths) w ?? share];
  }
}
