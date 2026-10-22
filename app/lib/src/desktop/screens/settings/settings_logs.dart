import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_log_io.dart' show LogFileInfo, maxLogFileBytes;
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
    final ok = dir != null && await ref.read(deskOpenFolderProvider)(dir);
    if (!ok && mounted) showEToast(context, 'Folder not opened', text: dir ?? 'The log is kept in memory only.', tone: ETone.warn);
  }

  Future<void> _clear() async {
    final ok = await showEDialog<bool>(
      context,
      builder: (context) => EDialog(
        title: 'Clear logs?',
        icon: EIcons.trash,
        tone: ETone.warn,
        description: 'Deletes the log files. A report sent later has only what is logged from now on.',
        actions: [
          EButton(label: 'Keep logs', size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
          EButton(label: 'Clear logs', icon: EIcons.trash, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(logFilesProvider).clear();
    await _read();
    if (mounted) showEToast(context, 'Logs cleared');
  }

  String _until(DateTime at) {
    final now = ref.read(logsClockProvider)();
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(at.hour)}:${two(at.minute)}';
    final today = at.year == now.year && at.month == now.month && at.day == now.day;
    return today ? 'today $time' : 'tomorrow $time';
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final total = _files?.fold<int>(0, (sum, f) => sum + f.bytes);
    final level = logs.until;
    return ESetGroup(
      title: 'Logs',
      rows: [
        ESetRow(
          title: 'Log level',
          text: level == null
              ? 'Normal. Detailed keeps more lines on disk for 24 hours; addresses may appear in the file, reports leave them out.'
              : 'Detailed until ${_until(level)}, then Normal. Addresses may appear in the file; reports leave them out.'
                    '${logs.coreDetailed ? '' : ' Wallet core lines get detailed from the next app start.'}',
          control: ERowControl(
            wide: true,
            child: ESegmented<bool>(
              stretch: true,
              value: logs.detailed,
              onChanged: (v) => ref.read(logsProvider.notifier).setDetailed(v),
              segments: const [ESegment(false, 'Normal'), ESegment(true, 'Detailed')],
            ),
          ),
        ),
        // Two row buttons: under the text when the card leaves the words too little room.
        LayoutBuilder(
          builder: (context, box) => ESetRow(
          title: 'Log files',
          stacked: box.maxWidth < 720.u,
          text: total == null
              ? 'Reading…'
              : 'Current size ${logSize(total)} of ${logSize(2 * maxLogFileBytes)}. Keeps one older file.',
          control: Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              ERowControl(child: EButton(label: 'Open log folder', icon: EIcons.folder, size: EBtnSize.sm, onPressed: _open)),
              ERowControl(child: EButton(label: 'Clear logs', icon: EIcons.trash, size: EBtnSize.sm, onPressed: total == 0 ? null : _clear)),
            ],
          ),
        ),
        ),
      ],
    );
  }
}
