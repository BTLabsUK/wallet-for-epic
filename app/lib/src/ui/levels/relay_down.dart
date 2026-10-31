// SPDX-License-Identifier: Apache-2.0
/// Flow D, level 1 only ([LevelFeatures.relaySwitchPrompt]): the Epicbox relay in use is down
/// and another is ready ([relaySwitchProvider]). A docked warning offers the move; Switch moves
/// the wallet ([RelaySwitchNotifier.accept]), Not now waits ([RelaySwitchNotifier.keepWaiting]).
/// After the move a success notice offers the new address on Receive, where
/// [relaySwitchResultProvider] marks it new. Nothing moves by itself: the address changes.
///
/// The pinned core cannot read the old relay yet, so no text promises that payments to the old
/// address arrive: anyone with the old address needs the new one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../levels/level_providers.dart';
import '../../levels/relay_switch.dart';
import '../../levels/relay_switch_providers.dart';
import '../../models.dart' show WalletError;
import '../../providers.dart';
import '../notices.dart';
import '../receive_screen.dart' show ReceiveTab, receiveTabProvider;

/// The tag of the offer's notice, and of the move's, so each replaces itself.
const String relayOfferNoticeTag = 'relay-offer';
const String relayMovedNoticeTag = 'relay-moved';

/// Moves the wallet to the offered relay. A refused move is an error notice; the move done is
/// a success notice with Show new address. Returns whether the wallet moved.
Future<bool> acceptRelaySwitch(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final notices = ref.read(noticeProvider.notifier);
  notices.dismissTag(relayOfferNoticeTag);
  try {
    final result = await ref.read(relaySwitchProvider.notifier).accept(ref);
    if (result == null) return false;
    notices.show(
      l.lvShellSwitchedNotice(result.name),
      level: NoticeLevel.success,
      tag: relayMovedNoticeTag,
      action: NoticeAction(l.lvShellShowNewAddress, () => showNewAddress(ref)),
    );
    return true;
  } on WalletError catch (e) {
    notices.show(describeError(l, e), level: NoticeLevel.error);
    return false;
  }
}

/// Not now: the offer waits until the relay answers again or the wait runs out.
void keepWaitingForRelay(WidgetRef ref) {
  ref.read(noticeProvider.notifier).dismissTag(relayOfferNoticeTag);
  ref.read(relaySwitchProvider.notifier).keepWaiting();
}

/// Receive, at the Epicbox address the move gave.
void showNewAddress(WidgetRef ref) {
  ref.read(receiveTabProvider.notifier).choose(ReceiveTab.epicbox);
  ref.read(shellTabProvider.notifier).go(ShellTab.receive);
}

/// The offer's notice while one stands; draws nothing. Sits in the shell's app bar beside
/// the other notice sources.
class RelayDownNotices extends ConsumerStatefulWidget {
  const RelayDownNotices({super.key});

  @override
  ConsumerState<RelayDownNotices> createState() => _RelayDownNoticesState();
}

class _RelayDownNoticesState extends ConsumerState<RelayDownNotices> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<RelaySwitchOffer?>(relaySwitchProvider, (_, offer) => _follow(offer));
    // An offer already standing: after the first frame, as the notice's words need the context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(ref.read(relaySwitchProvider)));
    // The level loads after the first frame: an offer already there shows once it is level 1.
    ref.listenManual<bool>(
      levelFeaturesProvider.select((f) => f.relaySwitchPrompt),
      (_, _) => _follow(ref.read(relaySwitchProvider)),
    );
  }

  void _follow(RelaySwitchOffer? offer) {
    if (!mounted) return;
    final notices = ref.read(noticeProvider.notifier);
    if (offer == null || !ref.read(levelFeaturesProvider).relaySwitchPrompt) {
      notices.dismissTag(relayOfferNoticeTag);
      return;
    }
    final l = context.l10n;
    notices.show(
      l.lvShellRelayDownNotice(offer.name),
      level: NoticeLevel.warning,
      persistent: true,
      tag: relayOfferNoticeTag,
      action: NoticeAction(l.lvShellSwitchTo(offer.name), () {
        if (mounted) acceptRelaySwitch(context, ref);
      }),
      secondary: NoticeAction(l.pairNotNow, () => ref.read(relaySwitchProvider.notifier).keepWaiting()),
      onClose: () => ref.read(relaySwitchProvider.notifier).keepWaiting(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
