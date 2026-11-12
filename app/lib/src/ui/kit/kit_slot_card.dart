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
  const KitPageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (count < 2) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 2),
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
          Expanded(child: _SlotText(title: title, subtitle: subtitle, maxSubtitleLines: 2)),
          ?trailing,
          if (onTap != null && trailing == null) Icon(KitIcons.chevron, size: 22, color: t.faint),
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

/// A 40 px icon well, optionally in the gold tint of the needs-you card.
class KitWell extends StatelessWidget {
  const KitWell({super.key, required this.icon, this.gold = false});

  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: Kit.avatar,
      height: Kit.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gold ? t.accent.withValues(alpha: 0.14) : t.raised,
        borderRadius: BorderRadius.circular(Kit.rAvatar),
      ),
      child: ExcludeSemantics(child: Icon(icon, size: 22, color: gold ? t.accentText : t.dim)),
    );
  }
}

class _SlotText extends StatelessWidget {
  const _SlotText({required this.title, this.subtitle, this.maxSubtitleLines = 1});

  final String title;
  final String? subtitle;
  final int maxSubtitleLines;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: KitType.rowTitle.copyWith(color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle!, style: KitType.rowSub.copyWith(color: t.dim), maxLines: maxSubtitleLines, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// The needs-you card (HANDOFF 7.1): a gold-soft ground, a gold-line edge, deep-gold corner
/// marks, a [title] and a [subtitle] of up to two lines, then a gold Review button and a ghost Later. At
/// most one gold button on the screen: this card's, which is why the screen's own primary
/// leaves the gold to it. Its height follows its content (at least [Kit.slotCard]).
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: KitCornerMarks(
              child: Container(
                constraints: const BoxConstraints(minHeight: Kit.slotCard),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.goldSoft,
                  borderRadius: BorderRadius.circular(Kit.rGroup),
                  border: Border.all(color: t.goldLine),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        KitWell(icon: icon, gold: true),
                        const SizedBox(width: 12),
                        Expanded(child: _SlotText(title: title, subtitle: subtitle, maxSubtitleLines: 2)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 52),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            KitButton(label: reviewLabel, onPressed: onReview, small: true, expand: false, semanticsId: reviewId),
                            if (onLater != null)
                              KitButton(label: laterLabel, onPressed: onLater, kind: KitButtonKind.ghost, small: true, expand: false, semanticsId: laterId),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          KitPageDots(count: pages, index: page),
        ],
      ),
    );
  }
}
