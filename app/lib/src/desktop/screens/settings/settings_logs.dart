// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../app_log.dart' show LogFileInfo, maxLogFileBytes;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/logs.dart';
import '../../widgets/kit.dart';

/// Settings › Help › Logs: the level, the folder, the size and Clear logs. In Help beside
/// Report a problem, because the log is the app's (every wallet's) and is read for support.
class LogsGroup extends ConsumerStatefulWidget {
  const LogsGroup({super.key});

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
          EButton(label: context.l10n.deskSetLogsKeep, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
          EButton(label: context.l10n.deskSetLogsClear, icon: EIcons.trash, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
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
    return ESetGroup(
      title: l.deskSetLogsTitle,
      rows: [
        ESetRow(
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
      ],
    );
  }
}
