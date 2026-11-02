// SPDX-License-Identifier: Apache-2.0
/// Flow D, every level ([LevelFeatures.relaySwitchPrompt]): the Epicbox relay in use is down
/// and another is ready ([relaySwitchProvider]). A compact docked warning offers the move;
/// Switch moves the wallet ([RelaySwitchNotifier.accept]), its close button waits
/// ([RelaySwitchNotifier.keepWaiting]). Item 11: nothing during the connection grace after
/// start and resume ([connectionGraceProvider]; the status icon alone shows the state), and
/// only while the shell is the screen on top: a transaction's details or Settings never get it.
/// After the move a success notice offers the new address on Receive, where
/// [relaySwitchResultProvider] marks it new. Nothing moves by itself: the address changes.
///
/// The pinned core cannot read the old relay yet, so no text promises that payments to the old
/// address arrive: anyone with the old address needs the new one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connection_grace.dart';
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

/// Moves the wallet to the offered relay, or to [to] when the user picked one
/// ([RelaySwitchNotifier.moveTo]). A refused move is an error notice; the move done is a success
/// notice with Show new address. Returns whether the wallet moved.
Future<bool> acceptRelaySwitch(BuildContext context, WidgetRef ref, {RelayCandidate? to}) async {
  final l = context.l10n;
  final notices = ref.read(noticeProvider.notifier);
  notices.dismissTag(relayOfferNoticeTag);
  try {
    final relays = ref.read(relaySwitchProvider.notifier);
    final result = await (to == null ? relays.accept(ref) : relays.moveTo(ref, to));
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
  /// The shell's route is the one on top (no screen pushed over it).
  bool _onTop = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuilt when a screen is pushed over the shell or popped off it.
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    if (onTop == _onTop) return;
    _onTop = onTop;
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(ref.read(relaySwitchProvider)));
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual<RelaySwitchOffer?>(relaySwitchProvider, (_, offer) => _follow(offer));
    // The grace over: an offer still standing shows now.
    ref.listenManual<bool>(connectionGraceProvider, (_, _) => _follow(ref.read(relaySwitchProvider)));
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
    if (offer == null ||
        !ref.read(levelFeaturesProvider).relaySwitchPrompt ||
        ref.read(connectionGraceProvider) ||
        !_onTop) {
      notices.dismissTag(relayOfferNoticeTag);
      return;
    }
    final l = context.l10n;
    // Compact: a title, one line and Switch; the close button is Not now.
    notices.show(
      l.lvShellRelayDownShort(offer.name),
      title: l.lvShellRelayDownTitle,
      level: NoticeLevel.warning,
      persistent: true,
      tag: relayOfferNoticeTag,
      action: NoticeAction(l.lvShellSwitch, () {
        if (mounted) acceptRelaySwitch(context, ref);
      }),
      onClose: () => ref.read(relaySwitchProvider.notifier).keepWaiting(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
