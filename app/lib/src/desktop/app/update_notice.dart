/// What the desktop says and does about a newer Epic Cash Desktop (`data/desk_update.dart`), in
/// the sidebar's slot (`now_slot.dart`) and in Settings › About › Updates, the same steps in
/// both: Update available → Downloading 42 % → Restart to update, with a dialog that offers the
/// restart once the download is checked. A step that fails says so and offers the next way: try
/// the download again, or the download page. An update that did not finish (Windows) says
/// "Update didn't finish. Try again." and runs the steps again. A copy that cannot install
/// updates by itself opens the download page at every step, and says why.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart' show localInt;
import '../data/desk_update.dart';
import '../data/files.dart' show deskOpenUrlProvider;
import '../desk_l10n.dart';
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;

/// What the slot's line says in state [u]: two lines, the hover text, and whether it is a warning.
/// [act] is false while the download runs (nothing to click).
({String title, String second, String? tip, bool warn, bool act}) deskUpdateWords(AppLocalizations l, DeskUpdateState u) {
  final v = u.version ?? '';
  return switch (u.phase) {
    DeskUpdatePhase.downloading => (
      title: l.deskUpdDownloading(localInt(l, ((u.progress ?? 0) * 100).floor())),
      second: v,
      tip: null,
      warn: false,
      act: false,
    ),
    DeskUpdatePhase.ready when u.problem == null => (
      title: l.deskUpdReady(v),
      second: l.deskUpdRestartNow,
      tip: l.deskUpdRestartHint,
      warn: false,
      act: true,
    ),
    DeskUpdatePhase.ready => (title: l.deskUpdInstallFailed, second: l.deskUpdOpenPage, tip: u.problem, warn: true, act: true),
    DeskUpdatePhase.unfinished => (title: l.deskUpdUnfinished, second: v, tip: u.problem ?? l.deskUpdRestartHint, warn: true, act: true),
    _ when u.problem != null => (
      title: l.deskUpdFailed,
      second: u.file != null ? l.deskUpdTryAgain : l.deskUpdOpenPage,
      tip: u.file != null ? u.problem : '${u.problem}\n${l.deskUpdManual}',
      warn: true,
      act: true,
    ),
    _ => (
      title: l.deskUpdAvailable,
      second: v,
      tip: u.file != null ? l.deskUpdDownload(v) : '${l.deskUpdOpensPage}\n${l.deskUpdManual}',
      warn: false,
      act: true,
    ),
  };
}

/// The button for the step [deskUpdateAct] takes in state [u] (Settings › About); null while
/// there is none (nothing offered, or the download runs).
String? deskUpdateActLabel(AppLocalizations l, DeskUpdateState u) => switch (u.phase) {
  DeskUpdatePhase.unfinished => l.deskUpdTryAgain,
  DeskUpdatePhase.available when u.file != null => u.problem == null ? l.deskUpdDownloadInstall : l.deskUpdTryAgain,
  DeskUpdatePhase.ready when u.problem == null => l.deskUpdRestart,
  DeskUpdatePhase.available || DeskUpdatePhase.ready => l.deskUpdOpenPage,
  _ => null,
};

/// The click on an update (the slot's line, About's button): download, restart, try again, or
/// open the page. A download that arrives checked offers the restart ([showUpdateReadyDialog]).
Future<void> deskUpdateAct(BuildContext context, WidgetRef ref) async {
  final u = ref.read(deskUpdateProvider);
  switch (u.phase) {
    case DeskUpdatePhase.unfinished:
      await retryUpdate(context, ref);
    case DeskUpdatePhase.available when u.file != null:
      // The line or the page that started it may be gone when the download ends.
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(deskUpdateProvider.notifier).download();
      await showUpdateReadyDialog(container, context.mounted ? context : null);
    case DeskUpdatePhase.ready when u.problem == null:
      await restartToUpdate(context, ref);
    case DeskUpdatePhase.available || DeskUpdatePhase.ready:
      await openUpdatePage(context, ref, u.page ?? deskReleasesUrl);
    default:
      return;
  }
}

/// Opens the download page; a toast when the browser does not open.
Future<void> openUpdatePage(BuildContext context, WidgetRef ref, String page) async {
  if (!await ref.read(deskOpenUrlProvider)(page) && context.mounted) {
    showEToast(context, context.l10n.deskSetAboutBrowserNotOpened, text: page, tone: ETone.warn);
  }
}

/// "Epic Cash 26.10.19 is ready": Restart now or Later, once the download the user started is
/// checked. Later leaves "Restart to update" in the slot. Not while a payment is being sent (the
/// slot's line waits for a click), nor when the download did not end ready. [fallback] shows it
/// where the app's navigator is not there (tests).
Future<void> showUpdateReadyDialog(ProviderContainer container, BuildContext? fallback) async {
  final u = container.read(deskUpdateProvider);
  if (u.phase != DeskUpdatePhase.ready || u.problem != null) return;
  if (container.read(deskProvider.notifier).sending > 0) return;
  final shown = deskNavigatorKey.currentContext ?? (fallback != null && fallback.mounted ? fallback : null);
  if (shown == null) return;
  final now = await showEDialog<bool>(
    shown,
    builder: (context) {
      final l = context.l10n;
      return EDialog(
        key: const ValueKey('update-ready'),
        title: l.deskUpdReadyTitle(u.version ?? ''),
        description: l.deskUpdReadyBody,
        icon: EIcons.restart,
        tone: ETone.gold,
        actions: [
          EButton(label: l.deskUpdLater, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
          EButton(label: l.deskUpdRestartNow, kind: EBtnKind.primary, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
        ],
      );
    },
  );
  if (now == true && shown.mounted) await _restart(shown, container);
}

/// Restart to update: never in the middle of a send (as Quit); the update is put in place and
/// started, then the app quits. A failure stays in the slot and in About.
Future<void> restartToUpdate(BuildContext context, WidgetRef ref) => _restart(context, ProviderScope.containerOf(context, listen: false));

Future<void> _restart(BuildContext context, ProviderContainer container) async {
  final l = context.l10n;
  if (container.read(deskProvider.notifier).sending > 0) {
    showEToast(context, l.deskShellNotQuitTitle, text: l.deskShellNotQuitBody, tone: ETone.warn);
    return;
  }
  // The update is already running once restart() returns true, so the quit does not wait on this
  // widget (the sidebar may switch to its rail, About may close, during the re-check).
  if (!await container.read(deskUpdateProvider.notifier).restart()) return;
  await _quitForUpdate(container);
}

/// "Update didn't finish. Try again.": the update once more, as Restart to update does it (never
/// in the middle of a send); the app quits once Setup runs. What stops it stays in the slot.
Future<void> retryUpdate(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  if (ref.read(deskProvider.notifier).sending > 0) {
    showEToast(context, l.deskShellNotQuitTitle, text: l.deskShellNotQuitBody, tone: ETone.warn);
    return;
  }
  // The line changes (download, restart) while this runs: the quit goes through the container.
  final container = ProviderScope.containerOf(context, listen: false);
  if (!await ref.read(deskUpdateProvider.notifier).retry()) return;
  await _quitForUpdate(container);
}

/// The quit after an update was put in place: lock the wallet and close the app, through the
/// provider container (as [quitWallet] does through the widget's ref).
Future<void> _quitForUpdate(ProviderContainer container) async {
  try {
    await container.read(deskProvider.notifier).lock();
  } finally {
    await container.read(deskQuitProvider)?.call();
  }
}
