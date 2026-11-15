// SPDX-License-Identifier: Apache-2.0
/// Helpers the kit parts share: the stable test id and the one press feedback.
library;

import 'package:flutter/material.dart';

import '../../trust_ids.dart';

/// [child] given its stable test id when [id] is set (`TrustIds.*`, given by the screen).
Widget kitId(String? id, Widget child) => id == null ? child : TrustId(id, child: child);

/// A tap target that keeps the part's own look: no Material ripple box, a soft press tint.
class KitPress extends StatelessWidget {
  const KitPress({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 0,
    this.semanticsLabel,
    this.button = true,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double radius;
  final String? semanticsLabel;
  final bool button;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Semantics(
      button: button && onTap != null,
      enabled: onTap != null,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        child: InkWell(borderRadius: r, onTap: onTap, onLongPress: onLongPress, child: child),
      ),
    );
  }
}
