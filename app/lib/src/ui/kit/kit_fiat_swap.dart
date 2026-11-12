// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The other currency under an amount ("≈ $25.82 ⇅", `.lbl`, Receive-2 and Send-2): 15 dim text
/// and the 15 swap glyph, one tap target 44 tall. Without [onSwap] it is the text alone.
class KitFiatSwap extends StatelessWidget {
  const KitFiatSwap({super.key, required this.text, this.onSwap, this.semanticsId});

  final String text;
  final VoidCallback? onSwap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, style: KitType.body.copyWith(color: t.dim, height: 1.2)),
          ),
        ),
        if (onSwap != null) ...[
          const SizedBox(width: 6),
          Icon(KitIcons.swap, size: 15, color: t.dim),
        ],
      ],
    );
    final child = SizedBox(
      height: Kit.hitMin,
      child: Center(widthFactor: 1, child: row),
    );
    if (onSwap == null) return Center(child: child);
    return kitId(
      semanticsId,
      Center(
        child: KitPress(
          onTap: onSwap,
          radius: Kit.rButtonSmall,
          semanticsLabel: '$text. ${context.l10n.phoneKitSwapCurrency}',
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: child),
        ),
      ),
    );
  }
}
