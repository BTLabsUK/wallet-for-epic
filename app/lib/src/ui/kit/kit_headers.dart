// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import '../tip.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A round-cornered icon button of the headers: 44 px target, 14 radius when pressed.
class KitIconButton extends StatelessWidget {
  const KitIconButton({super.key, required this.icon, required this.label, required this.onPressed, this.color, this.semanticsId, this.filled = false});

  final IconData icon;

  /// Spoken name, and the tooltip.
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final String? semanticsId;

  /// A [Kit.scanButton] sized button with the quiet fill (the scan button next to a field).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = filled ? Kit.scanButton : Kit.hitMin;
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
              child: SizedBox(width: size, height: size, child: Icon(icon, size: 22, color: color ?? t.text)),
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
  const KitFlowHeader({super.key, required this.title, required this.onLeading, this.back = false, this.onHelp, this.avatar, this.leadingId, this.helpId});

  final String title;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KitIconButton(
                icon: back ? KitIcons.back : KitIcons.close,
                label: back ? l.phoneKitBack : l.commonClose,
                onPressed: onLeading,
                semanticsId: leadingId,
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
                child: KitIconButton(icon: KitIcons.help, label: l.sendHelp, onPressed: onHelp, color: t.dim, semanticsId: helpId),
              ),
          ],
        ),
      ),
    );
  }
}

/// The header of a page inside a tab (HANDOFF 7.4): a gold back link named after the page it
/// returns to ("‹ Settings"), a "?" on the right, then the 28 [title].
class KitPageHeader extends StatelessWidget {
  const KitPageHeader({super.key, required this.backLabel, required this.onBack, required this.title, this.onHelp, this.backId, this.helpId});

  final String backLabel;
  final VoidCallback? onBack;
  final String title;
  final VoidCallback? onHelp;
  final String? backId;
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: Kit.pageTitleHeader,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                kitId(
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
                        constraints: const BoxConstraints(minHeight: Kit.hitMin, minWidth: Kit.hitMin),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(KitIcons.backLink, size: 28, color: t.accentText),
                              Text(backLabel, style: KitType.navLink.copyWith(color: t.accentText)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (onHelp != null)
                  KitIconButton(icon: KitIcons.help, label: context.l10n.sendHelp, onPressed: onHelp, color: t.dim, semanticsId: helpId),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 2, Kit.gutter + 4, 14),
          child: Semantics(header: true, child: Text(title, style: KitType.pageTitle.copyWith(color: t.text))),
        ),
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

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Kit.flowHeader + 12,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 0, 10, 0),
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
class KitSectionHead extends StatelessWidget {
  const KitSectionHead(this.title, {super.key, this.trailing});

  final String title;

  /// A quiet text action at the end ("See all").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 22, Kit.gutter + 4, 10),
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
