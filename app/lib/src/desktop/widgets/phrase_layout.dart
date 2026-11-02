// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A recovery phrase on screen, laid out the same wherever it is shown (new wallet, Settings ›
/// Recovery phrase): [header] (a warning), then the [actions] (Hide, Copy, Show QR) on one row
/// whose right edge is the grid's, then the [grid] and whatever goes with it ([below]: the QR),
/// then the [footer] (the "written down" checkbox). [cover] sits in the middle of the part of the
/// grid in view (Reveal over hidden words), never scrolled away with it. With a bounded height only the grid part
/// scrolls: the header, the actions and the footer stay in view (a frame too short for that
/// scrolls the whole page instead: `EOnbFrame.fill`, `SettingsFrame.fill`). Unbounded (inside a page that
/// scrolls), it is one column. Focus follows the same order: actions, grid, footer.
class EPhraseLayout extends StatelessWidget {
  const EPhraseLayout({
    super.key,
    required this.grid,
    this.header = const [],
    this.actions = const [],
    this.below = const [],
    this.footer,
    this.cover,
    this.edgeInset = 0,
  });

  final List<Widget> header;
  final List<Widget> actions;
  final Widget grid;
  final List<Widget> below;
  final Widget? footer;
  final Widget? cover;

  /// How far the last action's label sits inside its box (a bare ghost button's padding): the
  /// row moves out by it, so the label, not the box, ends at the grid's edge.
  final double edgeInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final words = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [grid, ...below],
        );
        final footer = this.footer;
        final cover = this.cover;
        Widget covered(Widget w) => cover == null ? w : Stack(alignment: Alignment.center, children: [w, cover]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            if (actions.isNotEmpty) ...[
              Transform.translate(
                offset: Offset(Directionality.of(context) == TextDirection.rtl ? -edgeInset : edgeInset, 0),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Sp.x2,
                  runSpacing: Sp.x2,
                  children: actions,
                ),
              ),
              SizedBox(height: Sp.x3),
            ],
            // Loose: the footer sits right under the words while they fit, at the bottom once
            // they scroll.
            if (box.hasBoundedHeight) Flexible(child: covered(SingleChildScrollView(child: words))) else covered(words),
            if (footer != null) ...[
              SizedBox(height: Sp.x4),
              footer,
            ],
          ],
        );
      },
    );
  }
}
