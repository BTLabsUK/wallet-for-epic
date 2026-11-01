// SPDX-License-Identifier: Apache-2.0
/// The app root's half of invite links (`invite_links.dart`): while a wallet is open (the phone's
/// home, the desktop's shell), each invite the system opened goes to the handler registered for
/// its kind, which opens its confirm sheet. An invite that came before the unlock waits in the
/// inbox until this widget is built. Nothing here pairs or links.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../l10n.dart';
import '../invite_links.dart';
import '../scan/incoming_link.dart' show linkBusyProvider;

/// How long an invite waits for its kind's handler once a wallet is open (a feature registers
/// as its part of the shell starts) before [InviteLinkGate.onNoHandler] says it cannot open.
const Duration inviteHandlerWait = Duration(seconds: 3);

/// Routes the held invite, and each one after it, to its handler while it is built.
/// [onUnreadable] says briefly that a link was not an invite the app can read; [onNoHandler]
/// that no feature takes an invite of that kind now (off, or not available in this wallet),
/// and the invite is dropped.
class InviteLinkGate extends ConsumerStatefulWidget {
  const InviteLinkGate({super.key, required this.child, this.onUnreadable, this.onNoHandler});

  final Widget child;
  final void Function(BuildContext context)? onUnreadable;
  final void Function(BuildContext context, InviteKind kind)? onNoHandler;

  @override
  ConsumerState<InviteLinkGate> createState() => _InviteLinkGateState();
}

class _InviteLinkGateState extends ConsumerState<InviteLinkGate> {
  StreamSubscription<InviteLink>? _arrivals;
  StreamSubscription<void>? _unreadable;
  Timer? _wait;

  /// False while the tree takes this widget out (a handler unregistering in its own dispose
  /// notifies [inviteHandlersChanged] then): nothing may be read from the tree.
  bool _active = true;

  @override
  void initState() {
    super.initState();
    inviteHandlersChanged.addListener(_route);
    final inbox = ref.read(inviteInboxProvider);
    _arrivals = inbox.arrivals.listen((_) => _route());
    _unreadable = inbox.unreadable.listen((_) {
      if (mounted) widget.onUnreadable?.call(context);
    });
    // One that came before this wallet opened: after the first frame, so a sheet has a
    // navigator to open on.
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void dispose() {
    inviteHandlersChanged.removeListener(_route);
    _wait?.cancel();
    _arrivals?.cancel();
    _unreadable?.cancel();
    super.dispose();
  }

  /// Hands the held invite to its handler: none while a PIN prompt or a send is in progress
  /// (it waits for them). Without a handler for its kind it waits [inviteHandlerWait] for one,
  /// then says so and is dropped.
  void _route() {
    if (!mounted || !_active || ref.read(linkBusyProvider)) return;
    final inbox = ref.read(inviteInboxProvider);
    final held = inbox.held;
    if (held == null) return;
    final handler = inviteHandler(held.kind);
    if (handler == null) {
      _wait ??= Timer(inviteHandlerWait, _giveUp);
      return;
    }
    _wait?.cancel();
    _wait = null;
    inbox.take();
    unawaited(handler(context, held).catchError((Object e, StackTrace s) => logError('links', e, s)));
  }

  void _giveUp() {
    _wait = null;
    if (!mounted || !_active) return;
    final inbox = ref.read(inviteInboxProvider);
    final held = inbox.held;
    if (held == null || inviteHandler(held.kind) != null) return _route();
    inbox.take();
    widget.onNoHandler?.call(context, held.kind);
  }

  @override
  Widget build(BuildContext context) {
    // The busy step over: the waiting invite goes now (a late handler: inviteHandlersChanged).
    ref.listen(linkBusyProvider, (_, busy) {
      if (!busy) _route();
    });
    return widget.child;
  }
}

/// The notice for an invite of [kind] no feature takes now: its part is off, or not available
/// in this wallet.
String inviteNoHandlerText(AppLocalizations l, InviteKind kind) => l.inviteLinkNoHandler(switch (kind) {
  InviteKind.pair => l.expPairing,
  InviteKind.deviceLink => l.expLinkedDevices,
});
