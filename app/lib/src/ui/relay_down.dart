// SPDX-License-Identifier: Apache-2.0
/// Flow D: the Epicbox relay in use is down
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart' show NetworkMode, NetworkModeRestricted;
import '../connection_grace.dart';
import '../settings.dart' show networkModeProvider;
import '../errors.dart';
import '../l10n.dart';
import '../relay_switch.dart';
import '../relay_switch_providers.dart';
import '../models.dart' show WalletError;
import '../providers.dart';
import 'notices.dart';
import 'receive_screen.dart' show ReceiveTab, receiveTabProvider;

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
      l.statusSwitchedNotice(result.name),
      level: NoticeLevel.success,
      tag: relayMovedNoticeTag,
      action: NoticeAction(l.statusShowNewAddress, () => showNewAddress(ref)),
    );
    return true;
  } on WalletError catch (e) {
    notices.show(describeError(l, e), level: NoticeLevel.error);
    return false;
  }
}

/// Receive, at the Epicbox address the move gave.
void showNewAddress(WidgetRef ref) {
  ref.read(receiveTabProvider.notifier).choose(ReceiveTab.epicbox);
  ref.read(shellFlowProvider.notifier).open(ShellFlow.receive);
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

  /// The offer whose notice ran its course: it shows once per offer and hides by itself; the
  /// Epicbox status sheet keeps the offer (item 16). One taken away early (a screen pushed over
  /// the shell, the grace) shows again.
  RelaySwitchOffer? _seen;
  Timer? _seenTimer;

  @override
  void dispose() {
    _seenTimer?.cancel();
    super.dispose();
  }

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
    // Node only or Kill switch turns Epicbox off: a "new address is ready" notice still up
    // would announce an address that nothing serves now.
    ref.listenManual<NetworkMode>(networkModeProvider, (_, mode) {
      if (mode.restricted) ref.read(noticeProvider.notifier).dismissTag(relayMovedNoticeTag);
    });
    // The grace over: an offer still standing shows now.
    ref.listenManual<bool>(connectionGraceProvider, (_, _) => _follow(ref.read(relaySwitchProvider)));
    // An offer already standing: after the first frame, as the notice's words need the context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(ref.read(relaySwitchProvider)));
  }

  void _follow(RelaySwitchOffer? offer) {
    if (!mounted) return;
    final notices = ref.read(noticeProvider.notifier);
    if (offer == null) _seen = null;
    if (offer == null ||
        ref.read(connectionGraceProvider) ||
        !_onTop) {
      _seenTimer?.cancel();
      _seenTimer = null;
      notices.dismissTag(relayOfferNoticeTag);
      return;
    }
    if (offer == _seen) return;
    _seenTimer ??= Timer(
      noticeDuration(NoticeLevel.warning, action: true, accessible: MediaQuery.accessibleNavigationOf(context)),
      () {
        _seenTimer = null;
        _seen = offer;
      },
    );
    final l = context.l10n;
    // Compact: a title, one line and Switch; it hides by itself, and swiping it away is Not now.
    notices.show(
      l.statusRelayDownShort(offer.name),
      title: l.statusRelayDownTitle,
      level: NoticeLevel.warning,
      tag: relayOfferNoticeTag,
      action: NoticeAction(l.statusSwitch, () {
        if (mounted) acceptRelaySwitch(context, ref);
      }),
      onClose: () => ref.read(relaySwitchProvider.notifier).keepWaiting(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
