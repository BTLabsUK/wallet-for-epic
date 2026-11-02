// SPDX-License-Identifier: Apache-2.0
/// The Epicbox server offer on the desktop (wallet levels, Shallow): the rules are the phone's
/// (`levels/relay_switch.dart`), the wiring `data/desk_relay_switch.dart`. The server in use has
/// not answered for a while and another of the list is seen healthy: a toast on Overview names it
/// (Switch), the Epicbox popover carries the same offer, nothing moves until the user confirms
/// in a dialog. After the move a toast "Now on" with the domain offers Show new address, and
/// Receive shows the new address for the open wallet.
///
/// No text promises that payments to the old address arrive: the pinned core cannot read the old
/// server yet (LEPIC E-15), so anyone with the old address needs the new one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../levels/relay_switch.dart' show RelaySwitchOffer;
import '../data/desk_errors.dart' show deskErrorText;
import '../data/desk_levels.dart';
import '../data/desk_relay_switch.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;

export '../data/desk_relay_switch.dart'
    show deskRelayOfferProvider, deskRelayMovedProvider, deskRelayMovedNoticeProvider, deskRelayNoticeShownProvider;

/// Asks once, then moves the wallet to the offered server. A refused move is a toast and nothing
/// changes; Keep waiting is Not now. Returns whether the wallet moved.
Future<bool> confirmDeskRelaySwitch(BuildContext context, WidgetRef ref) async {
  // Read up front: the popover that asked may be gone by the answer.
  final switcher = ref.read(deskRelayOfferProvider.notifier);
  final offer = ref.read(deskRelayOfferProvider);
  final shown = deskNavigatorKey.currentContext ?? context;
  if (offer == null || !shown.mounted) return false;
  final l = shown.l10n;
  final go = await showEDialog<bool>(
    shown,
    builder: (context) => EDialog(
      key: const ValueKey('relay-dialog'),
      title: l.deskSendEpicboxSwitchTo(offer.name),
      icon: EIcons.epicbox,
      body: Text(l.lvShellOfferBody(offer.name), style: context.ts.body),
      actions: [
        EButton(key: const ValueKey('relay-dialog-wait'), label: l.lvShellKeepWaiting, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(
          key: const ValueKey('relay-dialog-switch'),
          label: l.lvShellSwitchTo(offer.name),
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (go == false) switcher.keepWaiting();
  if (go != true) return false;
  try {
    return await switcher.accept() != null;
  } on Object catch (e) {
    final at = deskNavigatorKey.currentContext ?? (context.mounted ? context : null);
    if (at != null && at.mounted) showEToast(at, at.l10n.deskSendEpicboxNotSwitched, text: deskErrorText(e, at.l10n), tone: ETone.risk);
    return false;
  }
}

/// The offer the toast already showed for, across visits to Overview: one toast per offer.
final _deskRelayToastedProvider = NotifierProvider<_DeskRelayToasted, RelaySwitchOffer?>(_DeskRelayToasted.new);

class _DeskRelayToasted extends Notifier<RelaySwitchOffer?> {
  @override
  RelaySwitchOffer? build() => null;

  void set(RelaySwitchOffer? offer) => state = offer;
}

/// The offer's and the move's toast on Overview (item 16): a short line and one action, hiding
/// by itself, never a card in the layout. The offer's toast shows once per offer; the Epicbox
/// status popover keeps the offer ([DeskRelayOfferPanel]). Draws [child].
class DeskRelayNotice extends ConsumerStatefulWidget {
  const DeskRelayNotice({super.key, this.child = const SizedBox.shrink()});

  final Widget child;

  @override
  ConsumerState<DeskRelayNotice> createState() => _DeskRelayNoticeState();
}

class _DeskRelayNoticeState extends ConsumerState<DeskRelayNotice> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(deskRelayNoticeShownProvider, (_, _) => _follow());
    ref.listenManual<RelaySwitchOffer?>(deskRelayOfferProvider, (_, _) => _follow());
    ref.listenManual<bool>(deskRelayMovedNoticeProvider, (_, _) => _follow());
    // An offer or a move already standing: after the first frame, as the toast needs the context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
  }

  void _follow() {
    if (!mounted) return;
    final offer = ref.read(deskRelayOfferProvider);
    final toasted = ref.read(_deskRelayToastedProvider.notifier);
    if (offer == null) toasted.set(null);
    if (!ref.read(deskRelayNoticeShownProvider)) return;
    final l = context.l10n;
    if (offer != null) {
      if (offer == ref.read(_deskRelayToastedProvider)) return;
      toasted.set(offer);
      showEToast(
        context,
        l.deskErrEpicboxUnreachable,
        text: l.lvShellRelayDownShort(offer.name),
        tone: ETone.warn,
        action: (label: l.lvShellSwitch, run: () {
          if (mounted) confirmDeskRelaySwitch(context, ref);
        }),
      );
      return;
    }
    final moved = ref.read(deskRelayMovedProvider);
    if (moved != null && ref.read(deskRelayMovedNoticeProvider)) {
      ref.read(deskRelayMovedNoticeProvider.notifier).close();
      showEToast(
        context,
        l.lvShellSwitchedNotice(moved.name),
        tone: ETone.ok,
        action: (label: l.lvShellShowNewAddress, run: () {
          if (mounted) ref.read(deskNavProvider.notifier).go(DeskRoute.receive);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The offer inside the Epicbox status popover: an amber notice with Switch, which asks in the
/// same dialog as the notice. [close] closes the popover before the dialog opens.
class DeskRelayOfferPanel extends ConsumerWidget {
  const DeskRelayOfferPanel({super.key, this.close});

  final VoidCallback? close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(deskLevelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    final offer = ref.watch(deskRelayOfferProvider);
    if (!prompt || offer == null) return const SizedBox.shrink();
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(top: Sp.x3),
      child: ENotice(
        key: const ValueKey('relay-pop-offer'),
        tone: ETone.warn,
        icon: EIcons.epicbox,
        title: l.lvShellOfferReady(offer.name),
        text: l.lvShellOfferBody(offer.name),
        actionsBelow: true,
        actions: [
          EButton.primary(
            key: const ValueKey('relay-pop-switch'),
            label: l.lvShellSwitchTo(offer.name),
            size: EBtnSize.sm,
            onPressed: () {
              close?.call();
              confirmDeskRelaySwitch(context, ref);
            },
          ),
        ],
      ),
    );
  }
}
