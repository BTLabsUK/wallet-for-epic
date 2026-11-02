// SPDX-License-Identifier: Apache-2.0
/// Settings › This computer › Files & logs: Folders (this wallet's folder, the app's files, the
/// network of a development build) and Logs (the level, the files; Advanced › Logs).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_log.dart' show LogFileInfo, maxLogFileBytes;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/logs.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'setting_ids.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;
import 'settings_frame.dart';

/// Where the app keeps its own files (mock).
const appFilesDir = '~/.config/epic-wallet';

class SettingsFilesScreen extends ConsumerWidget {
  const SettingsFilesScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = ref.watch(deskProvider.select((s) => s.account));
    if (a == null) return const SettingsFrame(route: DeskRoute.settingsFiles, child: SettingsLoading());
    return SettingsFrame(
      route: DeskRoute.settingsFiles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: l.deskSetFilesFolders,
            rows: [
              _FolderRow(anchor: SetId.walletFolder, title: l.deskSetAcctWalletFolder, path: a.folder),
              _FolderRow(anchor: SetId.appFiles, title: l.deskSetAcctAppFiles, hint: l.deskSetAcctAppFilesHint, path: a.appFolder ?? appFilesDir),
              // A development build on another network says so here (review 6).
              if (a.network != 'mainnet' && DeskFeatures.testNetworks)
                ESetRow(title: l.deskSetAcctNetwork, hint: l.deskSetAcctNetworkHint, control: EBadge(a.network, tone: ETone.warn)),
            ],
          ),
          LogsGroup(shown: advancedHas(ref, AdvancedFeature.logs)),
        ],
      ),
    );
  }
}

/// A folder: its path in mono with a copy button, and Open folder.
class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.anchor, required this.title, required this.path, this.hint});

  final String anchor;
  final String title;
  final String? hint;
  final String path;

  /// Opens [path] in the system's file manager; a path that is not on disk (the mock) toasts.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    if (!Directory(path).existsSync()) {
      showEToast(context, l.deskSetAcctFolderNotFound, text: path, tone: ETone.warn);
      return;
    }
    if (!await ref.read(deskOpenFolderProvider)(path) && context.mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: path, tone: ETone.warn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return ESetRow(
      anchor: anchor,
      title: title,
      hint: hint,
      control: ERowControl(child: EButton(label: l.deskSetBackupOpenFolder, icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: () => _open(context, ref))),
      below: Row(
        children: [
          Flexible(
            child: ETip.value(path, mono: true, child: Text(path, style: ts.mono(size: Fs.sm, color: c.dim), overflow: TextOverflow.ellipsis)),
          ),
          SizedBox(width: Sp.x1),
          ECopyButton(text: path, label: l.deskSetAcctCopyPath(title)),
        ],
      ),
    );
  }
}

/// Files & logs › Logs: the level, the folder, the size and Clear logs. The log is the app's
/// (every wallet's) and is read for support.
class LogsGroup extends ConsumerStatefulWidget {
  const LogsGroup({super.key, this.shown = true});

  /// Advanced › Logs is on: the rows show; off, they wait behind the group's ⇕.
  final bool shown;

  @override
  ConsumerState<LogsGroup> createState() => _LogsGroupState();
}

class _LogsGroupState extends ConsumerState<LogsGroup> {
  List<LogFileInfo>? _files;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final files = await ref.read(logFilesProvider).files();
    if (mounted) setState(() => _files = files);
  }

  Future<void> _open() async {
    final dir = ref.read(logFilesProvider).folder;
    final l = context.l10n;
    final ok = dir != null && await ref.read(deskOpenFolderProvider)(dir);
    if (!ok && mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: dir ?? l.deskSetLogsMemoryOnly, tone: ETone.warn);
  }

  Future<void> _clear() async {
    final ok = await showEDialog<bool>(
      context,
      builder: (context) => EDialog(
        title: context.l10n.deskSetLogsClearTitle,
        icon: EIcons.trash,
        tone: ETone.warn,
        description: context.l10n.deskSetLogsClearDesc,
        actions: [
          EButton(label: context.l10n.deskSetLogsKeep, onPressed: () => Navigator.pop(context, false)),
          EButton(label: context.l10n.deskSetLogsClear, icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(logFilesProvider).clear();
    await _read();
    if (mounted) showEToast(context, context.l10n.deskSetLogsCleared, tone: ETone.ok);
  }

  String _until(AppLocalizations l, DateTime at) {
    final now = ref.read(logsClockProvider)();
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(at.hour)}:${two(at.minute)}';
    final today = at.year == now.year && at.month == now.month && at.day == now.day;
    return today ? l.deskSetLogsToday(time) : l.deskSetLogsTomorrow(time);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final logs = ref.watch(logsProvider);
    final total = _files?.fold<int>(0, (sum, f) => sum + f.bytes);
    final level = logs.until;
    final rows = [
        ESetRow(
          anchor: SetId.logLevel,
          advancedBy: widget.shown ? null : advancedByFeature(l, AdvancedFeature.logs),
          title: l.deskSetLogsLevel,
          text: level == null
              ? l.deskSetLogsLevelNormal
              : (logs.coreDetailed ? l.deskSetLogsLevelDetailed(_until(l, level)) : l.deskSetLogsLevelDetailedCore(_until(l, level))),
          control: ERowControl(
            wide: true,
            child: ESegmented<bool>(
              stretch: true,
              value: logs.detailed,
              onChanged: (v) => ref.read(logsProvider.notifier).setDetailed(v),
              segments: [ESegment(false, l.deskSetLogsNormal), ESegment(true, l.deskSetLogsDetailed)],
            ),
          ),
        ),
        // Two row buttons: under the text when the card leaves the words too little room.
        ESetRow(
          anchor: SetId.logFiles,
          advancedBy: widget.shown ? null : advancedByFeature(l, AdvancedFeature.logs),
          title: l.deskSetLogsFiles,
          text: total == null ? l.deskSetLndReading : l.deskSetLogsSize(logSize(total, l), logSize(2 * maxLogFileBytes, l)),
          control: Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              ERowControl(child: EButton(label: l.deskSetLogsOpenFolder, icon: EIcons.folder, size: EBtnSize.sm, onPressed: _open)),
              ERowControl(child: EButton(label: l.deskSetLogsClear, icon: EIcons.trash, size: EBtnSize.sm, onPressed: total == 0 ? null : _clear)),
            ],
        ),
        ),
      ];
    return ESetGroup(
      title: l.deskSetLogsTitle,
      rows: widget.shown ? rows : const [],
      hidden: widget.shown ? const [] : rows,
      revealKey: 'files-logs',
    );
  }
}
