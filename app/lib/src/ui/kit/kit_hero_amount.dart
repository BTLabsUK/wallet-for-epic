// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_tokens.dart';

/// The amount a page is about (HANDOFF 7.9), centred: the figure in the data face at [size]
/// with the EPIC [unit] small and gold after it. An [incoming] amount is green and carries its
/// own "+" in [amount].
class KitHeroAmount extends StatelessWidget {
  const KitHeroAmount({super.key, required this.amount, required this.unit, this.incoming = false, this.size = 34});

  final String amount;
  final String unit;
  final bool incoming;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$amount $unit',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amount,
                style: KitType.amountOnPage.copyWith(
                  fontSize: size,
                  letterSpacing: -0.04 * size,
                  color: incoming ? t.ok : t.text,
                ),
                textScaler: TextScaler.noScaling,
              ),
              const SizedBox(width: 10),
              Text(unit, style: KitType.unit.copyWith(color: t.accentText), textScaler: TextScaler.noScaling),
            ],
          ),
        ),
      ),
    );
  }
}
