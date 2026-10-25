/// The update notice at the foot of the sidebar, above the statuses, while a newer Epic Cash
/// Desktop is out (`data/desk_update.dart`): Update available → Downloading 42 % → Restart to
/// update. A step that fails says so and offers the next way: try the download again, or the
/// download page. An update that did not finish (Windows) says "Update didn't finish. Try
/// again." and runs the steps again. Nothing shows otherwise. This is the one place in the app
/// that offers an update: Settings › About › Updates only checks and says what it found.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart' show localInt;
import '../data/desk_update.dart';
import '../data/files.dart' show deskOpenUrlProvider;
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// What the notice says in state [u]: two lines, the hover text, and whether it is a warning.
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
      title: l.deskUpdRestart,
      second: l.deskUpdReady(v),
      tip: l.deskUpdRestartHint,
      warn: false,
      act: true,
    ),
    DeskUpdatePhase.ready => (title: l.deskUpdInstallFailed, second: l.deskUpdOpenPage, tip: u.problem, warn: true, act: true),
    DeskUpdatePhase.unfinished => (title: l.deskUpdUnfinished, second: v, tip: u.problem ?? l.deskUpdRestartHint, warn: true, act: true),
    _ when u.problem != null => (
      title: l.deskUpdFailed,
      second: u.file != null ? l.deskUpdTryAgain : l.deskUpdOpenPage,
      tip: u.problem,
      warn: true,
      act: true,
    ),
    _ => (
      title: l.deskUpdAvailable,
      second: v,
      tip: u.file != null ? l.deskUpdDownload(v) : l.deskUpdOpensPage,
      warn: false,
      act: true,
    ),
  };
}

/// The notice's click: download, restart, try again, or open the page.
Future<void> deskUpdateAct(BuildContext context, WidgetRef ref) async {
  final u = ref.read(deskUpdateProvider);
  switch (u.phase) {
    case DeskUpdatePhase.unfinished:
      await retryUpdate(context, ref);
    case DeskUpdatePhase.available when u.file != null:
      await ref.read(deskUpdateProvider.notifier).download();
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

/// Restart to update: never in the middle of a send (as Quit); the update is put in place and
/// started, then the app quits. A failure stays in the notice.
Future<void> restartToUpdate(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  if (ref.read(deskProvider.notifier).sending > 0) {
    showEToast(context, l.deskShellNotQuitTitle, text: l.deskShellNotQuitBody, tone: ETone.warn);
    return;
  }
  // The update is already running once restart() returns true, so the quit does not wait on this
  // widget (the sidebar may switch to its rail, About may close, during the re-check).
  final container = ProviderScope.containerOf(context, listen: false);
  if (!await ref.read(deskUpdateProvider.notifier).restart()) return;
  await _quitForUpdate(container);
}

/// "Update didn't finish. Try again.": the update once more, as Restart to update does it (never
/// in the middle of a send); the app quits once Setup runs. What stops it stays in the notice.
Future<void> retryUpdate(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  if (ref.read(deskProvider.notifier).sending > 0) {
    showEToast(context, l.deskShellNotQuitTitle, text: l.deskShellNotQuitBody, tone: ETone.warn);
    return;
  }
  // The notice changes (download, restart) while this runs: the quit goes through the container.
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

class DeskUpdateNotice extends ConsumerWidget {
  const DeskUpdateNotice({super.key, this.compact = false});

  /// The narrow rail: an icon with the words in its tooltip.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(deskUpdateProvider);
    return ExpandFade(
      open: u.offered,
      child: u.offered ? Padding(padding: EdgeInsets.only(bottom: Sp.x2), child: _Notice(u: u, compact: compact)) : const SizedBox.shrink(),
    );
  }
}

class _Notice extends ConsumerWidget {
  const _Notice({required this.u, required this.compact});

  final DeskUpdateState u;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final w = deskUpdateWords(context.l10n, u);
    final ink = w.warn ? c.warn : c.accentText;
    final icon = switch (u.phase) {
      _ when w.warn => EIcons.alert,
      DeskUpdatePhase.ready => EIcons.restart,
      _ => EIcons.download,
    };
    final downloading = u.phase == DeskUpdatePhase.downloading;
    void onTap() => unawaited(deskUpdateAct(context, ref));
    if (compact) {
      final label = u.phase == DeskUpdatePhase.available && u.problem == null ? context.l10n.deskUpdNotice(u.version ?? '') : '${w.title} · ${w.second}';
      return Center(
        child: downloading
            ? Tooltip(
                message: label,
                child: Semantics(
                  label: label,
                  child: SizedBox.square(
                    dimension: Ctl.inline,
                    child: Padding(padding: EdgeInsets.all(4.u), child: CircularProgressIndicator(value: u.progress, strokeWidth: 2, color: c.accent)),
                  ),
                ),
              )
            : EIconButton(icon: icon, label: [label, ?w.tip].join('\n'), color: ink, onPressed: onTap),
      );
    }
    final body = Container(
      key: const ValueKey('update-notice'),
      padding: EdgeInsets.symmetric(horizontal: 8.u, vertical: 6.u),
      decoration: BoxDecoration(color: w.warn ? c.warnSoft : c.accentSoft, borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.u, color: ink),
              SizedBox(width: 10.u),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600, height: 17 / Fs.sm)),
                    Text(w.second, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.caption.copyWith(color: w.act ? ink : c.dim, height: 15 / Fs.xs)),
                  ],
                ),
              ),
            ],
          ),
          if (downloading) ...[SizedBox(height: 6.u), EProgress(value: u.progress)],
        ],
      ),
    );
    final notice = Semantics(
      button: w.act,
      label: '${w.title}: ${w.second}',
      hint: w.tip,
      excludeSemantics: true,
      child: w.act ? Material(type: MaterialType.transparency, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(Rad.sm), child: body)) : body,
    );
    return w.tip == null ? notice : Tooltip(message: w.tip, preferBelow: false, child: notice);
  }
}
