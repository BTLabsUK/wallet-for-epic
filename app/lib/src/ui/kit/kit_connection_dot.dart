// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The dot of the connection state (HANDOFF 7.1): 7 px, green when [ready], amber when not,
/// with a soft halo of its own colour. [KitStatusPill] uses it; Home and unlock can place it on
/// its own. Decorative: the state is named by the part that holds it.
class KitConnectionDot extends StatelessWidget {
  const KitConnectionDot({super.key, required this.ready, this.size = 7});

  final bool ready;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = ready ? t.ok : t.warn;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), spreadRadius: 3)],
        ),
      ),
    );
  }
}
