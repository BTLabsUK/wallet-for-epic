// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';

/// The mark at the head of a result page (HANDOFF 9, Send-4): a tick in a soft disc inside a
/// fainter ring, in the ok colour; [ok] false is the warn colour with a cross, for a payment
/// that did not go.
class KitResultMark extends StatelessWidget {
  const KitResultMark({super.key, this.ok = true});

  final bool ok;

  static const double _outer = 96;
  static const double _inner = 76;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = ok ? t.ok : t.warn;
    return ExcludeSemantics(
      child: Container(
        width: _outer,
        height: _outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.08)),
        child: Container(
          width: _inner,
          height: _inner,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
          child: Icon(ok ? KitIcons.check : KitIcons.close, size: 40, color: color),
        ),
      ),
    );
  }
}
