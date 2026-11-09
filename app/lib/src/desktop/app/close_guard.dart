// SPDX-License-Identifier: Apache-2.0
/// The one close rule. The title bar's ✕, Alt+F4, the taskbar's and the window menu's Close,
/// Ctrl+Q and the app menu's Quit all come here: with no send running the wallet locks, the
/// built-in node stops and the app ends; the window's own close first hides it to the tray
/// instead while the node syncs in the background (desk_tray.dart); while a send runs the app stays open and asks (Keep
/// open, or Close when it finishes). There is no "close now anyway": closing mid-send would
/// leave the payment's outcome unknown.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_window.dart';
import 'shell.dart' show lockWallet;

/// "Close when it finishes" was chosen: the app closes when the last send is done. The ✕ carries
/// a dot meanwhile.
class DeskCloseAfterSend extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final deskCloseAfterSendProvider = NotifierProvider<DeskCloseAfterSend, bool>(DeskCloseAfterSend.new);

/// True from the moment the app closes: the window shows Closing over everything while the
/// wallet locks and the local node stops (deskCloseDown, up to about a minute).
class DeskClosing extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final deskClosingProvider = NotifierProvider<DeskClosing, bool>(DeskClosing.new);

/// For main_desktop.dart's exit listener (the paths that do not pass the window): true while a
/// send runs, after asking. Set by [DeskCloseGuard].
bool Function() deskHoldExit = () => false;

/// For the window's close: true when the window went to the tray instead (desk_tray.dart's rule,
/// `hidesOnClose`). Set by DeskTray.
Future<bool> Function() deskHideToTray = () async => false;

bool _asking = false;

/// The window's close (the bar's ✕ and the system's: Alt+F4, the taskbar): to the tray when
/// Sync in background keeps the node running, else [deskClose]. Quit in a menu calls
/// [deskClose] itself.
Future<void> deskCloseWindow(WidgetRef ref) async {
  if (await deskHideToTray()) return;
  if (ref.context.mounted) await deskClose(ref);
}

/// Close the app, by the rule above.
Future<void> deskClose(WidgetRef ref) async {
  if (ref.read(deskSendingProvider) > 0) {
    await _askAboutSend(ref);
    return;
  }
  final quit = ref.read(deskQuitProvider);
  final window = ref.read(deskWindowProvider);
  final shown = deskNavigatorKey.currentContext;
  // The mock in a test or the web build: only locks.
  if (quit == null && !window.frameless && shown != null && shown.mounted) {
    showEToast(shown, shown.l10n.deskShellLockedTitle, text: shown.l10n.deskShellLockedBody, tone: ETone.neutral);
  }
  if (ref.read(deskClosingProvider)) return;
  if (quit != null || window.frameless) ref.read(deskClosingProvider.notifier).set(true);
  // On the unlock screen there is nothing to lock.
  if (!ref.read(deskNavProvider).route.bare) await lockWallet(ref);
  if (quit != null) {
    await quit();
  } else if (window.frameless) {
    await window.destroy();
  }
}

Future<void> _askAboutSend(WidgetRef ref) async {
  final context = deskNavigatorKey.currentContext;
  if (context == null || _asking) return;
  _asking = true;
  final bool? after;
  try {
    after = await showEDialog<bool>(context, builder: (_) => const _SendRunningDialog());
  } finally {
    _asking = false;
  }
  if (after == null) return;
  ref.read(deskCloseAfterSendProvider.notifier).set(after);
  final shown = deskNavigatorKey.currentContext;
  if (after && shown != null && shown.mounted) showEToast(shown, shown.l10n.deskBarClosesAfterSend, tone: ETone.neutral);
}

class _SendRunningDialog extends ConsumerWidget {
  const _SendRunningDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // The send ended while this was open: nothing to ask any more. Only this route goes, also
    // when another dialog is over it.
    ref.listen(deskSendingProvider, (_, now) {
      if (now > 0 || !context.mounted) return;
      final route = ModalRoute.of(context);
      if (route == null) return;
      final nav = Navigator.of(context);
      route.isCurrent ? nav.pop() : nav.removeRoute(route);
    });
    return EDialog(
      icon: EIcons.alert,
      tone: ETone.warn,
      title: l.deskBarSendRunningTitle,
      description: l.deskBarSendRunningBody,
      actions: [
        EButton(label: l.deskBarCloseAfterSend, onPressed: () => Navigator.of(context).pop(true)),
        EButton.primary(label: l.deskBarKeepOpen, autofocus: true, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
  }
}

/// Takes the system's close requests for the app ([DeskWindow.onCloseRequested]) and closes it
/// after the send when that was chosen.
class DeskCloseGuard extends ConsumerStatefulWidget {
  const DeskCloseGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeskCloseGuard> createState() => _DeskCloseGuardState();
}

class _DeskCloseGuardState extends ConsumerState<DeskCloseGuard> {
  late final DeskWindow _window = ref.read(deskWindowProvider);

  @override
  void initState() {
    super.initState();
    _window.onCloseRequested = () => deskCloseWindow(ref);
    deskHoldExit = () {
      if (!mounted || ref.read(deskSendingProvider) == 0) return false;
      unawaited(_askAboutSend(ref));
      return true;
    };
  }

  @override
  void dispose() {
    _window.onCloseRequested = null;
    deskHoldExit = () => false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deskSendingProvider, (before, now) {
      if (now == 0 && ref.read(deskCloseAfterSendProvider)) {
        ref.read(deskCloseAfterSendProvider.notifier).set(false);
        unawaited(deskClose(ref));
      }
    });
    return widget.child;
  }
}
