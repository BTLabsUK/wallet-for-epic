// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_tokens.dart';

/// A progress ring with the figure inside (HANDOFF 7.8, the restore search): a 122 px gold arc (a 116 px circle, 6 px stroke) in a 132 px box on
/// the quiet track, [label] in the page-title type at its centre. [value] 0 to 1; null draws the
/// empty track. [semanticsLabel] and [semanticsValue] (a number) are what a screen reader says.
class KitProgressRing extends StatelessWidget {
  const KitProgressRing({super.key, required this.value, required this.label, required this.semanticsLabel, this.semanticsValue});

  final double? value;
  final String label;
  final String semanticsLabel;
  final String? semanticsValue;

  static const double size = 132;
  static const double stroke = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              // The stroke is centred on the circle's edge: a 116 px circle draws 122 px across, as the frame's r=58.
              dimension: size - 16,
              child: CircularProgressIndicator(
                value: value ?? 0,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: t.fill,
                color: t.accent,
              ),
            ),
            Text(label, style: KitType.pageTitle.copyWith(color: t.text, fontSize: 30, letterSpacing: -0.6)),
          ],
        ),
      ),
    );
  }
}
