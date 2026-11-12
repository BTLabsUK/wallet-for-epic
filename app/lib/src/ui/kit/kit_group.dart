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
      // The line is drawn over the top edge of the row (the frame's `.row + .row` border sits
      // inside the row's height), so the rows keep their own heights.
      kids.add(
        i == 0
            ? children[i]
            : Stack(
                fit: StackFit.passthrough,
                children: [
                  children[i],
                  PositionedDirectional(
                    top: 0,
                    start: dividerInset,
                    end: 0,
                    height: 1,
                    child: IgnorePointer(child: ColoredBox(color: t.hair)),
                  ),
                ],
              ),
      );
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
  const KitGroupLabel(this.text, {super.key, this.inset = Kit.gutter + 4, this.top = 18});

  final String text;

  /// The side inset: 20 on a page, less where the page already pads.
  final double inset;

  /// The space above: 18, or 0 for the first label of a page, whose header leaves the gap.
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset, top, inset, 8),
    child: Semantics(
      header: true,
      child: Epic1Text(text, style: KitType.groupLabel.copyWith(color: context.tokens.dim)),
    ),
  );
}
