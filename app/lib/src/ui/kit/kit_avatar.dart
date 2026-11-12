// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_tokens.dart';

/// Which way money went, shown as the small badge on an avatar: out is dim, in is ok, and a
/// payment still in progress is info (HANDOFF 7.3).
enum KitDirection { out, incoming, pending }

/// A contact or a thing in a list: 40 px (radius 13) or, in the contact strip, 54 px (radius
/// 18). Shows [initials] in gold, or [icon]. [neutral] makes the figure dim, for a thing that
/// is not a person. A [direction] adds the 19 px badge at the bottom-right corner.
class KitAvatar extends StatelessWidget {
  const KitAvatar({super.key, this.initials, this.icon, this.large = false, this.neutral = false, this.direction, this.semanticsLabel})
    : assert(initials != null || icon != null);

  final String? initials;
  final IconData? icon;

  /// The 54 px strip size.
  final bool large;
  final bool neutral;
  final KitDirection? direction;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = large ? Kit.avatarStrip : Kit.avatar;
    final radius = large ? Kit.rAvatarStrip : Kit.rAvatar;
    final ink = neutral ? t.dim : t.accentText;
    final face = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(radius)),
      child: initials != null
          ? Text(
              initials!,
              style: KitType.initials.copyWith(color: ink, fontSize: large ? 18 : 13),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
            )
          : Icon(icon, size: large ? 26 : 22, color: ink),
    );
    final d = direction;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            face,
            if (d != null) Positioned(right: -5, bottom: -5, child: _Badge(d)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.direction);

  final KitDirection direction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (Color color, IconData icon) = switch (direction) {
      KitDirection.out => (t.dim, KitIcons.send),
      KitDirection.incoming => (t.ok, KitIcons.receive),
      KitDirection.pending => (t.info, KitIcons.send),
    };
    return Container(
      width: Kit.avatarBadge,
      height: Kit.avatarBadge,
      alignment: Alignment.center,
      // `.dir`: 19 round on #111115 (the group's ground), the arrow small inside.
      decoration: BoxDecoration(color: t.group.withValues(alpha: 1), shape: BoxShape.circle),
      child: Icon(direction == KitDirection.pending ? KitIcons.more : icon, size: 11, color: color),
    );
  }
}
