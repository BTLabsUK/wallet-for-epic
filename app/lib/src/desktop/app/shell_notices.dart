// SPDX-License-Identifier: Apache-2.0
/// The shell's notices on Overview's dock (wallet levels): the one notice an install that
/// updated into levels sees ("New: wallet depth", Have a look / OK, never again) and the
/// Epicbox server offer's notice ([DeskRelayNotice], relay_offer.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/desk_levels.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';
import 'relay_offer.dart';

/// Whether [DeskShellNotices] has anything to show (Overview leaves out its slot otherwise).
final deskShellNoticesShownProvider = Provider<bool>(
  (ref) =>
      (ref.watch(deskLevelNewsProvider).value ?? false) ||
      ref.watch(deskRelayNoticeShownProvider),
);

class DeskShellNotices extends ConsumerWidget {
  const DeskShellNotices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final news = ref.watch(deskLevelNewsProvider).value ?? false;
    final relay = ref.watch(deskRelayNoticeShownProvider);
    void dismiss() => ref.read(deskLevelNewsProvider.notifier).dismiss();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (news)
          ENotice(
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
          ),
        if (news && relay) SizedBox(height: Sp.x4),
        if (relay) const DeskRelayNotice(),
      ],
    );
  }
}
