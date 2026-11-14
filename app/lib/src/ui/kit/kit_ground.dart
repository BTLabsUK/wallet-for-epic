// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/widgets.dart';

import '../theme/brand.dart' show ProtocolBackdrop, topGlow;

/// The ground every phone screen stands on (HANDOFF 5.2, `.w::before` in wallet.css): the gold
/// glow at the top over the 28 px grid, both fading out by 62 % of the height, on the `bg`
/// token. Home, the tabs, pushed pages and flows all use it, so a sheet's scrim lies over the
/// same ground as in the frames. Under a [KitGround] another one paints nothing: a page inside
/// the home shell keeps the shell's light (and its breathing) instead of drawing a second one.
class KitGround extends StatelessWidget {
  const KitGround({super.key, required this.child, this.breathing = false});

  final Widget child;

  /// The light swells and fades slowly ([ProtocolBackdrop.breathing]).
  final bool breathing;

  /// Whether a [KitGround] above [context] already paints the ground.
  static bool paintedAbove(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GroundScope>() != null;

  @override
  Widget build(BuildContext context) {
    if (paintedAbove(context)) return child;
    return ProtocolBackdrop(
      focus: topGlow,
      breathing: breathing,
      child: _GroundScope(child: child),
    );
  }
}

class _GroundScope extends InheritedWidget {
  const _GroundScope({required super.child});

  @override
  bool updateShouldNotify(_GroundScope old) => false;
}
