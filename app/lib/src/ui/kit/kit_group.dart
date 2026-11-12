// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/epic1_mark.dart' show Epic1Text;
import '../theme/tokens.dart';
import 'kit_tokens.dart';

/// A grouped panel (HANDOFF 7.3): the group fill, a hairline edge, radius 20, and a 1 px hair
/// divider between its [children] that starts at [dividerInset] from the left edge, which is
/// after the icon in a list ([Kit.dividerInsetList]) and at the row's padding in a plain
/// settings group ([Kit.dividerInsetPlain]). Side margins are the gutter unless [margin] says
/// otherwise.
class KitGroup extends StatelessWidget {
  const KitGroup({
    super.key,
    required this.children,
    this.dividerInset = Kit.dividerInsetList,
    this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter),
    this.onSheet = false,
  });

  final List<Widget> children;
  final double dividerInset;
  final EdgeInsetsGeometry margin;

  /// A group inside a sheet takes a lighter ground (`fill`), since the sheet is already raised.
  final bool onSheet;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final kids = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) kids.add(Padding(padding: EdgeInsetsDirectional.only(start: dividerInset), child: KitHairline(color: t.hair)));
      kids.add(children[i]);
    }
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onSheet ? t.fill : t.group,
          borderRadius: BorderRadius.circular(Kit.rGroup),
          border: Border.all(color: t.hair),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Kit.rGroup - 1),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
        ),
      ),
    );
  }
}

/// A 1 px line in the hair colour.
class KitHairline extends StatelessWidget {
  const KitHairline({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, child: ColoredBox(color: color ?? context.tokens.hair));
}

/// The small dim label above a group: 13/500, 20 px in, 18 above and 8 below.
class KitGroupLabel extends StatelessWidget {
  const KitGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 18, Kit.gutter + 4, 8),
    child: Semantics(
      header: true,
      child: Epic1Text(text, style: KitType.groupLabel.copyWith(color: context.tokens.dim)),
    ),
  );
}
