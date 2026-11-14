// SPDX-License-Identifier: Apache-2.0
/// The shell's notice on Home's dock: the one a wallet from before the onion's own key sees
/// about its changed Tor address (OK, never again for that wallet). The Epicbox server offer is
/// a toast ([DeskRelayNotice], relay_offer.dart), not a card here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/desk_onion_notice.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// Whether [DeskShellNotices] has anything to show (Home leaves out its slot otherwise).
final deskShellNoticesShownProvider = Provider<bool>((ref) => ref.watch(deskOnionNoticeProvider).value ?? false);

class DeskShellNotices extends ConsumerWidget {
  const DeskShellNotices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(deskShellNoticesShownProvider)) return const SizedBox.shrink();
    return ENotice(
      key: const ValueKey('onion-notice'),
      icon: EIcons.info,
      title: context.l10n.deskTorAddressChangedTitle,
      actions: [
        EButton(
          key: const ValueKey('onion-notice-ok'),
          label: context.l10n.commonOk,
          kind: EBtnKind.ghost,
          size: EBtnSize.inline,
          onPressed: () => ref.read(deskOnionNoticeProvider.notifier).dismiss(),
        ),
      ],
    );
  }
}
