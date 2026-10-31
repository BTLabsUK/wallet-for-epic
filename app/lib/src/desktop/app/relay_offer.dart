// SPDX-License-Identifier: Apache-2.0
/// The Epicbox server offer on the desktop (wallet levels, Shallow): the rules are the phone's
/// (`levels/relay_switch.dart`), the wiring `data/desk_relay_switch.dart`. The server in use has
/// not answered for a while and another of the list is seen healthy: a notice names it by its
/// address ("Switch to" and the domain), the Epicbox popover carries the same offer, nothing
/// moves until the user confirms. After the move "Now on" with the domain offers Show new
/// address, and Receive shows the new address for the open wallet.
///
/// No text promises that payments to the old address arrive: the pinned core cannot read the old
/// server yet (LEPIC E-15), so anyone with the old address needs the new one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// The offer's and the move's notice, docked with the shell's notices; nothing otherwise.
class DeskRelayNotice extends ConsumerStatefulWidget {
  const DeskRelayNotice({super.key});

  @override
  ConsumerState<DeskRelayNotice> createState() => _DeskRelayNoticeState();
}

class _DeskRelayNoticeState extends ConsumerState<DeskRelayNotice> {
  bool _busy = false;

  Future<void> _switch() async {
    setState(() => _busy = true);
    await confirmDeskRelaySwitch(context, ref);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prompt = ref.watch(deskLevelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    final offer = ref.watch(deskRelayOfferProvider);
    final moved = ref.watch(deskRelayMovedProvider);
    final movedOpen = ref.watch(deskRelayMovedNoticeProvider);
    if (!prompt) return const SizedBox.shrink();
    if (offer != null) {
      return ENotice(
        key: const ValueKey('relay-offer'),
        tone: ETone.warn,
        icon: EIcons.epicbox,
        title: l.deskErrEpicboxUnreachable,
        text: l.lvShellOfferBody(offer.name),
        actionsBelow: true,
        actions: [
          EButton(
            key: const ValueKey('relay-offer-switch'),
            label: l.lvShellSwitchTo(offer.name),
            kind: EBtnKind.primary,
            size: EBtnSize.inline,
            busy: _busy,
            onPressed: _busy ? null : _switch,
          ),
          EButton(
            key: const ValueKey('relay-offer-later'),
            label: l.pairNotNow,
            kind: EBtnKind.ghost,
            size: EBtnSize.inline,
            onPressed: _busy ? null : () => ref.read(deskRelayOfferProvider.notifier).keepWaiting(),
          ),
        ],
      );
    }
    if (moved != null && movedOpen) {
      void close() => ref.read(deskRelayMovedNoticeProvider.notifier).close();
      return ENotice(
        key: const ValueKey('relay-switched'),
        tone: ETone.ok,
        title: l.lvShellNowOn(moved.name),
        text: l.lvShellSwitchedBody,
        actionsBelow: true,
        actions: [
          EButton(
            key: const ValueKey('relay-switched-show'),
            label: l.lvShellShowNewAddress,
            size: EBtnSize.inline,
            onPressed: () {
              close();
              ref.read(deskNavProvider.notifier).go(DeskRoute.receive);
            },
          ),
          EButton(key: const ValueKey('relay-switched-ok'), label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: close),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// The offer inside the Epicbox status popover: a short line and Switch, which asks in the same
/// dialog as the notice. [close] closes the popover before the dialog opens.
class DeskRelayOfferPanel extends ConsumerWidget {
  const DeskRelayOfferPanel({super.key, this.close});

  final VoidCallback? close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(deskLevelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    final offer = ref.watch(deskRelayOfferProvider);
    if (!prompt || offer == null) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    return Container(
      key: const ValueKey('relay-pop-offer'),
      margin: EdgeInsets.only(top: Sp.x3),
      padding: EdgeInsets.all(Sp.x3),
      decoration: BoxDecoration(
        color: c.s3,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.lvShellOfferReady(offer.name), style: ts.strong),
          SizedBox(height: Sp.x1),
          Text(l.lvShellOfferBody(offer.name), style: ts.small),
          SizedBox(height: Sp.x2),
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
