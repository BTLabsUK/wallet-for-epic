/// Payment history backup: the encrypted `.wfeh` export, the CSV export and the import.
///
/// Files leave the app like transaction files do, through the shared helpers in
/// `slate_files.dart`: "Share" first, because a backup matters only once this phone is gone,
/// then "Save to device" (the system save dialog; the Storage Access Framework
/// on Android) first, and "Share" as a second choice where the platform has a share sheet.
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';

/// History backups are small; a file far larger is not one.
const int maxHistoryFileBytes = 32 << 20;

/// Moves history files in and out of the app. [dialogTitle] is the title of the system file
/// dialog, where the platform shows one.
abstract interface class HistoryFiles {
  /// Saves [bytes] as [name] where the user chooses. Returns false if they cancelled.
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String dialogTitle,
  });

  /// Whether [share] works on this platform.
  bool get canShare;

  /// Hands [bytes] to another app as a file called [name]. Returns false if dismissed.
  Future<bool> share({required String name, required Uint8List bytes});

  /// Lets the user pick a file and returns its bytes, or null if they cancelled.
  Future<Uint8List?> pick({required String dialogTitle});
}

class PlatformHistoryFiles implements HistoryFiles {
  const PlatformHistoryFiles();

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String dialogTitle,
  }) => saveBytesToDevice(name: name, bytes: bytes, dialogTitle: dialogTitle);

  @override
  bool get canShare => canShareFiles;

  @override
  Future<bool> share({required String name, required Uint8List bytes}) =>
      shareBytes(name: name, bytes: bytes);

  @override
  Future<Uint8List?> pick({required String dialogTitle}) async {
    final file = await FilePicker.pickFile(dialogTitle: dialogTitle);
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxHistoryFileBytes) {
      throw LocalizedFormatException((l) => l.historyBackupFileTooLarge);
    }
    return file.readAsBytes();
  }
}

/// Records saves and shares and hands out queued picks, for widget tests.
class FakeHistoryFiles implements HistoryFiles {
  final List<({String name, Uint8List bytes})> saved = [];
  final List<({String name, Uint8List bytes})> shared = [];
  final List<Uint8List?> picks = [];

  @override
  bool canShare = true;

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String dialogTitle,
  }) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<bool> share({required String name, required Uint8List bytes}) async {
    shared.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<Uint8List?> pick({required String dialogTitle}) async =>
      picks.isEmpty ? null : picks.removeAt(0);
}

final historyFilesProvider = Provider<HistoryFiles>(
  (ref) => const PlatformHistoryFiles(),
);

/// `epic-history-<chain>-<yyyyMMdd>.<extension>`, dated [day] in local time.
String historyFileName(Chain chain, DateTime day, String extension) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'epic-history-${chain.name}-${day.year}${two(day.month)}'
      '${two(day.day)}.$extension';
}

/// The import counts in plain words, naming only the counts above zero.
String describeImport(AppLocalizations l, ImportReport report) {
  final (m, a, s, c) = (
    report.merged,
    report.added,
    report.skipped,
    report.contactsAdded,
  );
  return switch ((m > 0, a > 0, s > 0, c > 0)) {
    (false, false, false, false) => l.historyBackupImportNothingNew,
    (true, false, false, false) => l.historyBackupImportMerged(m),
    (false, true, false, false) => l.historyBackupImportAdded(a),
    (true, true, false, false) => l.historyBackupImportMergedAdded(m, a),
    (false, false, true, false) => l.historyBackupImportSkipped(s),
    (true, false, true, false) => l.historyBackupImportMergedSkipped(m, s),
    (false, true, true, false) => l.historyBackupImportAddedSkipped(a, s),
    (true, true, true, false) => l.historyBackupImportMergedAddedSkipped(
      m,
      a,
      s,
    ),
    (false, false, false, true) => l.historyBackupImportContacts(c),
    (true, false, false, true) => l.historyBackupImportMergedContacts(m, c),
    (false, true, false, true) => l.historyBackupImportAddedContacts(a, c),
    (true, true, false, true) => l.historyBackupImportMergedAddedContacts(
      m,
      a,
      c,
    ),
    (false, false, true, true) => l.historyBackupImportSkippedContacts(s, c),
    (true, false, true, true) => l.historyBackupImportMergedSkippedContacts(
      m,
      s,
      c,
    ),
    (false, true, true, true) => l.historyBackupImportAddedSkippedContacts(
      a,
      s,
      c,
    ),
    (true, true, true, true) => l.historyBackupImportMergedAddedSkippedContacts(
      m,
      a,
      s,
      c,
    ),
  };
}

void _say(BuildContext context, String message) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(message);
}

Future<void> _tell(BuildContext context, String title, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );

enum _Destination { device, share }

/// Offers "Save to device", and "Share" where the platform can, then hands the file over.
/// Returns true once it was saved or shared.
Future<bool> _handOver(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required Uint8List bytes,
  required String title,
  String? note,
}) async {
  final l = context.l10n;
  final files = ref.read(historyFilesProvider);
  var destination = _Destination.device;
  if (files.canShare) {
    final chosen = await showModalBottomSheet<_Destination>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(note),
              ),
            // Share first: the copy that matters is the one off this phone.
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l.historyBackupShare),
              subtitle: Text(l.historyBackupShareSubtitle),
              onTap: () => Navigator.pop(context, _Destination.share),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(l.historyBackupSaveToDevice),
              subtitle: Text(l.historyBackupSaveToDeviceSubtitle),
              onTap: () => Navigator.pop(context, _Destination.device),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null) return false;
    destination = chosen;
  }
  final done = await ref
      .read(autoLockHoldProvider.notifier)
      .during(
        () => switch (destination) {
          _Destination.device => files.save(
            name: name,
            bytes: bytes,
            dialogTitle: l.historyBackupSaveDialogTitle,
          ),
          _Destination.share => files.share(name: name, bytes: bytes),
        },
      );
  // The share sheet is its own confirmation; a save into a folder is silent otherwise.
  if (done && destination == _Destination.device && context.mounted) {
    _say(context, l.historyBackupSaved(name));
  }
  return done;
}

/// Exports the encrypted history backup. Returns true once the file was handed over.
Future<bool> exportHistoryBackup(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final l = context.l10n;
  try {
    // uihome: what the file holds, for the home reminder (read just before the export).
    final snapshot = HistoryExportSnapshot.of(
      await session.transactions(refresh: false),
    );
    final bytes = await session.exportHistory();
    if (!context.mounted) return false;
    final name = historyFileName(
      config.chain,
      ref.read(clockProvider)(),
      'wfeh',
    );
    final saved = await _handOver(
      context,
      ref,
      name: name,
      bytes: bytes,
      title: l.historyBackupExportTitle,
      note: l.historyBackupExportNote,
    );
    // uihome: the home reminder counts what changed since this export.
    if (saved) {
      await ref
          .read(appSettingsProvider.notifier)
          .setHistoryExported(
            config.chain,
            ref.read(clockProvider)(),
            snapshot: snapshot,
          );
    }
    return saved;
  } catch (error) {
    if (context.mounted) _say(context, describeError(l, error));
    return false;
  }
}

/// Warns that the CSV is readable by anyone, then exports it. Returns true once handed over.
Future<bool> exportHistoryCsv(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final l = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.historyBackupCsvTitle),
        content: Text(l.historyBackupCsvWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.historyBackupCsvConfirm),
          ),
        ],
      );
    },
  );
  if (go != true || !context.mounted) return false;
  try {
    final csv = await session.exportHistoryCsv();
    if (!context.mounted) return false;
    final name = historyFileName(
      config.chain,
      ref.read(clockProvider)(),
      'csv',
    );
    final saved = await _handOver(
      context,
      ref,
      name: name,
      bytes: Uint8List.fromList(utf8.encode(csv)),
      title: l.historyBackupCsvTitle,
    );
    return saved;
  } catch (error) {
    if (context.mounted) _say(context, describeError(l, error));
    return false;
  }
}

/// Picks a history backup and imports it into the open wallet. Returns true when imported.
Future<bool> importHistoryBackup(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session == null) return false;
  final l = context.l10n;
  try {
    final bytes = await ref
        .read(autoLockHoldProvider.notifier)
        .during(
          () => ref
              .read(historyFilesProvider)
              .pick(dialogTitle: l.historyBackupOpenDialogTitle),
        );
    if (bytes == null) return false;
    final report = await session.importHistory(data: bytes);
    ref.invalidate(homeProvider);
    if (context.mounted) {
      await _tell(
        context,
        l.historyBackupImportedTitle,
        describeImport(l, report),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      await _tell(
        context,
        l.historyBackupImportFailedTitle,
        describeError(l, error),
      );
    }
    return false;
  }
}
