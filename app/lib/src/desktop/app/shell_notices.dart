// SPDX-License-Identifier: Apache-2.0
/// The shell's notices on Overview's dock: the one notice an install that updated into wallet
/// levels sees ("New: wallet depth", Have a look / OK, never again), and the one a wallet from
/// before the onion's own key sees about its changed Tor address (What changed / OK, never
/// again for that wallet). The Epicbox server offer is a toast ([DeskRelayNotice],
/// relay_offer.dart), not a card here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings_file/host_settings.dart' show appConfig;
import '../data/desk_levels.dart';
import '../data/files.dart' show deskOpenUrlProvider;
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// Whether [DeskShellNotices] has anything to show (Overview leaves out its slot otherwise).
final deskShellNoticesShownProvider = Provider<bool>(
  (ref) => (ref.watch(deskLevelNewsProvider).value ?? false) || (ref.watch(deskOnionNoticeProvider).value ?? false),
);

class DeskShellNotices extends ConsumerWidget {
  const DeskShellNotices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final news = ref.watch(deskLevelNewsProvider).value ?? false;
    final onion = ref.watch(deskOnionNoticeProvider).value ?? false;
    void dismiss() => ref.read(deskLevelNewsProvider.notifier).dismiss();
    // One card at a time: the levels notice first, the Tor address one once it is gone.
    if (!news && onion) {
      void seen() => ref.read(deskOnionNoticeProvider.notifier).dismiss();
      final page = appConfig.linkTorAddressChanged;
      return ENotice(
        key: const ValueKey('onion-notice'),
        icon: EIcons.info,
        title: l.deskTorAddressChangedTitle,
        text: l.deskTorAddressChangedText,
        actionsBelow: true,
        actions: [
          if (page != null)
            EButton(
              key: const ValueKey('onion-notice-link'),
              label: l.deskTorAddressChangedLink,
              size: EBtnSize.inline,
              onPressed: () async {
                seen();
                if (!await ref.read(deskOpenUrlProvider)(page) && context.mounted) {
                  showEToast(context, l.deskSetAboutBrowserNotOpened, text: page, tone: ETone.warn);
                }
              },
            ),
          EButton(key: const ValueKey('onion-notice-ok'), label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: seen),
        ],
      );
    }
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
