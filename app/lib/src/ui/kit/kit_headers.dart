// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import '../tip.dart';
import 'kit_icons.dart';
import 'kit_settings.dart' show KitTag;
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The round-cornered icon button of the headers (`.ib`): a 40 px square on the quiet fill, 48 px to touch.
class KitIconButton extends StatelessWidget {
  const KitIconButton({super.key, required this.icon, required this.label, required this.onPressed, this.color, this.semanticsId, this.filled = false, this.bare = false, this.glyphSize});

  final IconData icon;

  /// Spoken name, and the tooltip.
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final String? semanticsId;

  /// A [Kit.scanButton] sized button with the quiet fill (the scan button next to a field).
  final bool filled;

  /// No fill under the glyph (the scan mark inside the address field); the target stays 48.
  final bool bare;

  /// The glyph's size where the frame draws it other than 20.
  final double? glyphSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // `.ib`: 40 x 40 on the quiet fill, radius 14, the glyph 20 (the back chevron 21). The
    // touch target is [Kit.hitTarget]; the filled one is the scan button's 50.
    final size = filled ? Kit.scanButton : Kit.hitTarget;
    final glyph = glyphSize ?? (icon == KitIcons.back ? 21.0 : 20.0);
    return kitId(
      semanticsId,
      Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        child: Tip(
          label,
          excludeFromSemantics: true,
          child: Material(
            color: filled ? t.fill : Colors.transparent,
            borderRadius: BorderRadius.circular(Kit.rIconButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(Kit.rIconButton),
              onTap: onPressed,
              child: SizedBox(
                width: size,
                height: size,
                child: filled
                    ? Icon(icon, size: 22, color: color ?? t.text)
                    : Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: bare ? null : BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rIconButton)),
                          child: Icon(icon, size: glyph, color: color ?? t.text),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header of a flow (Send, Receive, a contact's payment; HANDOFF 7.7): 44 tall, a close
/// mark on the first step or a back arrow on a later one, the 17 [title] centred (with an
/// optional [avatar] before it), and a "?" for help on the right.
class KitFlowHeader extends StatelessWidget {
  const KitFlowHeader({super.key, required this.title, required this.onLeading, this.back = false, this.onHelp, this.avatar, this.leadingId, this.helpId, this.showLeading = true});

  final String title;

  /// False leaves the leading button out (a step that cannot be left, such as a search under way).
  final bool showLeading;

  /// Closes the flow on the first step, goes back on a later one ([back]).
  final VoidCallback? onLeading;
  final bool back;
  final VoidCallback? onHelp;
  final Widget? avatar;
  final String? leadingId;
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return SizedBox(
      height: Kit.flowHeader,
      // `.hdr` pads 12; the 48 targets hold the 40 `.ib` squares 4 in, so 8 here puts them at 12.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showLeading)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _reach(
                  KitIconButton(
                    icon: back ? KitIcons.back : KitIcons.close,
                    label: back ? l.phoneKitBack : l.commonClose,
                    onPressed: onLeading,
                    semanticsId: leadingId,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (avatar != null) ...[avatar!, const SizedBox(width: 8)],
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: KitType.flowTitle.copyWith(color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
            if (onHelp != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _reach(KitIconButton(icon: KitIcons.help, label: l.sendHelp, onPressed: onHelp, color: t.dim, semanticsId: helpId)),
              ),
          ],
        ),
      ),
    );
  }

  /// The 48 target of a button in the 44 bar: it reaches 2 past the bar on each side.
  static Widget _reach(Widget button) => SizedBox(
    width: Kit.hitTarget,
    height: Kit.flowHeader,
    child: OverflowBox(minHeight: Kit.hitTarget, maxHeight: Kit.hitTarget, child: button),
  );
}

/// The header of a page inside a tab (HANDOFF 7.4): a gold back link named after the page it
/// returns to ("‹ Settings"), a "?" on the right, then the 28 [title].
class KitPageHeader extends StatelessWidget {
  const KitPageHeader({super.key, required this.backLabel, required this.onBack, this.title, this.onHelp, this.backId, this.helpId, this.tag, this.bottomGap = 20});

  final String backLabel;
  final VoidCallback? onBack;

  /// The 28 title under the back link; null for a page that opens with its own content.
  final String? title;
  final VoidCallback? onHelp;
  final String? backId;
  final String? helpId;

  /// The space under the title; a page that opens with a group label asks for less.
  final double bottomGap;

  /// A small tag beside the title (the Experiment tag of Linked devices).
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The frame's nav row sits 4 px above the safe area and its title starts 6 px higher: a
        // 42 px row, drawn 0.5 px up (measured against the frames), keeps the content below where
        // it was.
        SizedBox(
          height: Kit.pageTitleHeader - 6,
          child: Transform.translate(
            offset: const Offset(0, -0.5),
            child: Padding(
            // `.nav` pads 6 on the left and 12 on the right: the help square's 48 target holds it 4
            // in, so 8 here puts its edge at 12.
            padding: const EdgeInsetsDirectional.only(start: 6, end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                  alignment: Alignment.centerLeft,
                  child: kitId(
                  backId,
                  Semantics(
                    button: true,
                    label: backLabel,
                    excludeSemantics: true,
                    onTap: onBack,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Kit.rIconButton),
                      onTap: onBack,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: Kit.hitTarget, minWidth: Kit.hitMin),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(KitIcons.backLink, size: 26, color: t.accentText),
                              Flexible(
                                child: Text(
                                  backLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: KitType.navLink.copyWith(color: t.accentText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ),
                ),
                if (onHelp != null)
                  KitIconButton(icon: KitIcons.help, label: context.l10n.sendHelp, onPressed: onHelp, color: t.dim, semanticsId: helpId),
              ],
            ),
          ),
          ),
        ),
        if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(Kit.gutter, 4, Kit.gutter, bottomGap - 1),
            child: tag == null
                ? Semantics(header: true, child: Text(title!, style: KitType.pageTitle.copyWith(color: t.text)))
                : Row(
                    children: [
                      Flexible(child: Semantics(header: true, child: Text(title!, style: KitType.pageTitle.copyWith(color: t.text)))),
                      const SizedBox(width: 12),
                      KitTag(tag!),
                    ],
                  ),
          )
        else
          const SizedBox(height: 6),
      ],
    );
  }
}

/// The large title of a tab (Home's neighbours: Activity, Contacts, Settings): 30, 44 tall,
/// with an optional trailing icon button.
class KitTabTitle extends StatelessWidget {
  const KitTabTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  // `.ttl`: 44 tall at 58 from the top (the view's top padding is 54), 16 in. The box is 51 tall
  // so the centre sits on the frame's line and the search field below keeps its 14.
  @override
  Widget build(BuildContext context) => SizedBox(
    height: Kit.flowHeader + 7,
    child: Padding(
      // The trailing button's 40 square sits 4 inside its 48 target, so 12 puts it 16 in.
      padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: KitType.tabTitle.copyWith(color: context.tokens.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// A section head (HANDOFF 7.4): 18/600 Montserrat with a 12 × 2 deep-gold tick before it.
/// `.sec`: 16 in at the start, 18 at the end, a 32 tall line and 10 to what follows. A
/// [trailing] action is 48 tall to reach (the line is 32 in the frames), so the space around
/// the line gives back the 8 above and below. [top] is the space above the line.
class KitSectionHead extends StatelessWidget {
  const KitSectionHead(this.title, {super.key, this.trailing, this.top = 22, this.inset = Kit.gutter});

  final String title;
  final double top;

  /// The space before the tick: the gutter, or 0 inside a body that is padded already.
  final double inset;

  /// A quiet text action at the end ("See all").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final give = trailing == null ? 0.0 : 8.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, top - give, inset + 2, 10 - give),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(color: t.goldDeep, borderRadius: BorderRadius.circular(1)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(child: Text(title, style: KitType.sectionHead.copyWith(color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
