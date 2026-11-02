// SPDX-License-Identifier: Apache-2.0
/// The shell's notice on Overview's dock (wallet levels): the one notice an install that
/// updated into levels sees ("New: wallet depth", Have a look / OK, never again). The Epicbox
/// server offer is a toast ([DeskRelayNotice], relay_offer.dart), not a card here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/desk_levels.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// Whether [DeskShellNotices] has anything to show (Overview leaves out its slot otherwise).
final deskShellNoticesShownProvider = Provider<bool>(
  (ref) => ref.watch(deskLevelNewsProvider).value ?? false,
);

class DeskShellNotices extends ConsumerWidget {
  const DeskShellNotices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final news = ref.watch(deskLevelNewsProvider).value ?? false;
    void dismiss() => ref.read(deskLevelNewsProvider.notifier).dismiss();
    if (!news) return const SizedBox.shrink();
    return ENotice(
      key: const ValueKey('level-news'),
      icon: EIcons.info,
      title: l.deskLvShellNewsTitle,
      text: l.deskLvShellNewsText,
      actionsBelow: true,
      actions: [
        EButton(
          key: const ValueKey('level-news-look'),
          label: l.deskLvShellNewsLook,
          size: EBtnSize.inline,
          onPressed: () {
            dismiss();
            ref.read(deskNavProvider.notifier).go(DeskRoute.settingsLevel);
          },
        ),
        EButton(key: const ValueKey('level-news-ok'), label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: dismiss),
      ],
    );
  }
}
