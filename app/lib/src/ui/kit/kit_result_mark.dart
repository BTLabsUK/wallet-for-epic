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

  static const double _halo = 10;
  static const double _inner = 76;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = ok ? t.ok : t.warn;
    // `.okring`: 76 wide in the layout, a 10 px halo of the same colour drawn around it.
    return ExcludeSemantics(
      child: SizedBox(
        width: _inner,
        height: _inner,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -_halo,
              top: -_halo,
              right: -_halo,
              bottom: -_halo,
              child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.05))),
            ),
            Container(
              width: _inner,
              height: _inner,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
              child: Icon(ok ? KitIcons.check : KitIcons.close, size: 36, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
