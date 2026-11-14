// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_button.dart';
import 'kit_corner_marks.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The page dots under Home's slot card: 4 px dots, the current one 14 × 4 in gold.
class KitPageDots extends StatelessWidget {
  const KitPageDots({super.key, required this.count, required this.index, this.top = 12});

  final int count;
  final int index;

  /// Space above: 12 under a card, less where the card's own corner-mark margin adds to it.
  final double top;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (count < 2) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == index ? 14 : 4,
                height: 4,
                decoration: BoxDecoration(color: i == index ? t.accent : t.hair2, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The card in Home's slot (HANDOFF 7.1): 90 tall, 16 from the sides, radius 20. An [icon] or
/// [leading] well, a [title], one [subtitle] line, an optional trailing widget, a chevron when
/// it opens something. Page dots sit under it when [pages] is more than one.
class KitSlotCard extends StatelessWidget {
  const KitSlotCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.action,
    this.onTap,
    this.pages = 1,
    this.page = 0,
    this.semanticsId,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  /// The gold link under the text (`.lk b`: "Back up now"); it takes the place of the chevron and
  /// the subtitle keeps to one line so the card stays [Kit.slotCard] tall.
  final String? action;
  final VoidCallback? onTap;
  final int pages;
  final int page;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Container(
      height: Kit.slotCard,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: t.group, borderRadius: BorderRadius.circular(Kit.rGroup), border: Border.all(color: t.hair)),
      child: Row(
        children: [
          ?leading,
          if (leading == null && icon != null) KitWell(icon: icon!),
          const SizedBox(width: 12),
          Expanded(child: _SlotText(title: title, subtitle: subtitle, maxSubtitleLines: action == null ? 2 : 1, action: action)),
          ?trailing,
          if (onTap != null && trailing == null && action == null) Icon(KitIcons.chevron, size: 22, color: t.faint),
        ],
      ),
    );
    final tappable = onTap == null
        ? card
        : Material(
            type: MaterialType.transparency,
            child: InkWell(borderRadius: BorderRadius.circular(Kit.rGroup), onTap: onTap, child: card),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          kitId(semanticsId, Semantics(container: true, button: onTap != null, child: tappable)),
          KitPageDots(count: pages, index: page),
        ],
      ),
    );
  }
}

/// A 40 px icon well, optionally in the gold tint of the needs-you card, or the quiet blue of
/// an info card ([info]).
class KitWell extends StatelessWidget {
  const KitWell({super.key, required this.icon, this.gold = false, this.info = false});

  final IconData icon;
  final bool gold;
  final bool info;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: Kit.avatar,
      height: Kit.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gold ? t.accent.withValues(alpha: 0.14) : (info ? t.infoSoft : t.raised),
        borderRadius: BorderRadius.circular(Kit.rAvatar),
      ),
      child: ExcludeSemantics(child: Icon(icon, size: 22, color: gold ? t.accentText : (info ? t.info : t.dim))),
    );
  }
}

class _SlotText extends StatelessWidget {
  const _SlotText({required this.title, this.subtitle, this.maxSubtitleLines = 1, this.needs = false, this.action});

  final String title;
  final String? subtitle;
  final int maxSubtitleLines;
  final String? action;

  /// The needs-you card's words (`.need b`, `.need p`): the title 600 at 1.3, the sub at 1.4.
  final bool needs;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KitType.rowTitle.copyWith(color: t.text, fontWeight: needs ? FontWeight.w600 : null, height: needs ? 1.3 : null),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle!, style: KitType.rowSub.copyWith(color: t.dim, height: needs ? 1.4 : null), maxLines: maxSubtitleLines, overflow: TextOverflow.ellipsis),
          ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(action!, style: KitType.rowSub.copyWith(color: t.accentText, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// The needs-you card (HANDOFF 7.1): a gold-soft ground, a gold-line edge, deep-gold corner
/// marks, a [title] and a [subtitle] on one line (an ellipsis cuts it), then a gold Review button and a ghost Later. At
/// most one gold button on the screen: this card's, which is why the screen's own primary
/// leaves the gold to it. Its height follows its content (at least [Kit.slotCard]).
///
/// With [info] it is the quiet version for news that needs an answer but is not a warning (an
/// invoice to review): the card's own ground, a blue hairline and icon, no corner marks and a
/// quiet Review button, all from the info tokens.
class KitNeedsYouCard extends StatelessWidget {
  const KitNeedsYouCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.reviewLabel,
    required this.laterLabel,
    required this.onReview,
    this.onLater,
    this.icon = KitIcons.invoice,
    this.pages = 1,
    this.page = 0,
    this.reviewId,
    this.laterId,
    this.info = false,
  });

  final String title;
  final String? subtitle;
  final String reviewLabel;
  final String laterLabel;
  final VoidCallback onReview;
  final VoidCallback? onLater;
  final IconData icon;
  final int pages;
  final int page;
  final String? reviewId;
  final String? laterId;

  /// The quiet blue look instead of the gold one.
  final bool info;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Container(
      constraints: const BoxConstraints(minHeight: Kit.slotCard),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: info ? t.group : t.goldSoft,
        borderRadius: BorderRadius.circular(Kit.rGroup),
        border: Border.all(color: info ? t.info.withValues(alpha: 0.4) : t.goldLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KitWell(icon: icon, gold: !info, info: info),
              const SizedBox(width: 12),
              Expanded(child: _SlotText(title: title, subtitle: subtitle, needs: true)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 52),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KitButton(
                    label: reviewLabel,
                    onPressed: onReview,
                    kind: info ? KitButtonKind.quiet : KitButtonKind.gold,
                    small: true,
                    expand: false,
                    semanticsId: reviewId,
                  ),
                  if (onLater != null)
                    KitButton(label: laterLabel, onPressed: onLater, kind: KitButtonKind.ghost, small: true, expand: false, semanticsId: laterId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      // `.need` sits on the gutter with its marks 6 out; here the marks sit on the gutter and the
      // card 6 in, so nothing reaches the screen margin.
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Room for the corner marks (`.brk`, 6 out); 4 on top keeps the card 20 under the
          // buttons as `.need{margin-top:20px}`, the marks reaching 2 into that gap.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: info ? card : KitCornerMarks(child: card),
          ),
          KitPageDots(count: pages, index: page, top: 6),
        ],
      ),
    );
  }
}

/// The reminder card of Home's slot (frame "Wallet reminders", `.ann`): 90 tall, a 64 px well
/// with a [icon] in gold, up to two lines of [text], a gold [action] link at the foot and a × at
/// the top corner that puts it away ([onClose]). The card and its link open [onAction]; the × is
/// its own button. [actionId] and [closeId] are the test drivers' names.
class KitReminderCard extends StatelessWidget {
  const KitReminderCard({
    super.key,
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
    required this.closeLabel,
    required this.onClose,
    this.pages = 1,
    this.page = 0,
    this.actionId,
    this.closeId,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;
  final String closeLabel;
  final VoidCallback onClose;
  final int pages;
  final int page;
  final String? actionId;
  final String? closeId;

  /// The × target: the frame's 34 px square, 5 px in from the corner.
  static const double _closeBox = 34;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Container(
      height: Kit.slotCard,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: t.group, borderRadius: BorderRadius.circular(Kit.rGroup), border: Border.all(color: t.hair)),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(16)),
            child: ExcludeSemantics(child: Icon(icon, size: 28, color: t.accentText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              // Room for the ×.
              padding: const EdgeInsetsDirectional.only(end: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: KitType.rowSub.copyWith(fontSize: 13.5, height: 1.4, color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text(action, style: KitType.rowSub.copyWith(color: t.accentText, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              kitId(
                actionId,
                Semantics(
                  container: true,
                  button: true,
                  label: '$text $action',
                  excludeSemantics: true,
                  onTap: onAction,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(borderRadius: BorderRadius.circular(Kit.rGroup), onTap: onAction, child: card),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 5,
                end: 5,
                child: kitId(
                  closeId,
                  Semantics(
                    button: true,
                    label: closeLabel,
                    excludeSemantics: true,
                    onTap: onClose,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkResponse(
                        onTap: onClose,
                        radius: _closeBox / 2,
                        child: SizedBox(width: _closeBox, height: _closeBox, child: Center(child: Icon(KitIcons.close, size: 16, color: t.faint))),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          KitPageDots(count: pages, index: page),
        ],
      ),
    );
  }
}
