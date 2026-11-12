// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import 'kit/kit_button.dart';
import 'kit/kit_group.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'theme/tokens.dart';

/// The sheet behind Send's "?" (Gap-2-Help): "How sending works", the three steps of a payment
/// with gold dots, two rows (what if it never finishes, more in Help) and Done.
Future<void> showSendHelpSheet(
  BuildContext context, {
  required VoidCallback onNeverFinishes,
  required VoidCallback onMore,
}) {
  return showKitSheet<void>(
    context: context,
    builder: (sheet) {
      final l = context.l10n;
      return KitSheet(
        title: l.phoneSendHelpTitle,
        titleGap: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitGroup(
              onSheet: true,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HelpStep(title: l.phoneSendHelpStep1, sub: l.phoneSendHelpStep1Sub),
                      _HelpStep(title: l.phoneSendHelpStep2, sub: l.phoneSendHelpStep2Sub, joined: true),
                      _HelpStep(title: l.phoneSendHelpStep3, sub: l.phoneSendHelpStep3Sub, joined: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            KitGroup(
              onSheet: true,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              dividerInset: 14,
              children: [
                _HelpRow(
                  label: l.sendTrackIfNot,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    onNeverFinishes();
                  },
                ),
                _HelpRow(
                  label: l.deskKitMoreInHelp,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    onMore();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
              child: KitButton(label: l.commonDone, kind: KitButtonKind.quiet, onPressed: () => Navigator.of(sheet).pop()),
            ),
          ],
        ),
      );
    },
  );
}

/// `.step.done` with a gold dot: 15 px title, a 13 px dim line under it, a connector to the
/// step above.
class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.title, required this.sub, this.joined = false});

  final String title;
  final String sub;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (joined)
          Positioned(
            left: 18.5,
            top: -14,
            height: 24,
            width: 1.5,
            child: ColoredBox(color: t.hair2),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ExcludeSemantics(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.accent,
                      border: Border.all(color: t.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KitType.body.copyWith(color: t.text, height: 1.3)),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(sub, style: KitType.body.copyWith(fontSize: 13, height: 1.45, color: t.dim)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A plain-group row at the frame's 52.5: a 15/500 title and a chevron.
class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      container: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 53),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: KitType.rowTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
                Icon(KitIcons.chevron, size: 18, color: t.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
