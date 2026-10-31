// SPDX-License-Identifier: Apache-2.0
/// Payment history backup: the encrypted `.wfeh` export, the CSV export and the import.
///
/// Files leave the app like transaction files do, through the shared helpers in
/// `slate_files.dart`: "Share" first, because a backup matters only once this phone is gone,
/// then "Save to device" (the system save dialog; the Storage Access Framework
/// on Android) first, and "Share" as a second choice where the platform has a share sheet.
library;

import 'phone_sheet.dart';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactsProvider, favouriteContactsProvider;
import '../errors.dart';
import '../l10n.dart';
import '../pairing_providers.dart' show pairingsProvider;
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import '../history/backup_summary.dart';
import 'backup_settings_phone.dart';
import 'common.dart';
import 'history_conflicts.dart';

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

/// `epic-wallet-data-<yyyyMMdd>.<extension>`, dated [day] in local time; a dev chain's file
/// names its chain after `data-`. Older `epic-history-*` files still import: the import goes by
/// the extension and the content.
String historyFileName(Chain chain, DateTime day, String extension) {
  String two(int v) => v.toString().padLeft(2, '0');
  final tag = chain == Chain.mainnet ? '' : '${chain.name}-';
  return 'epic-wallet-data-$tag${day.year}${two(day.month)}'
      '${two(day.day)}.$extension';
}

/// `epic-payments-<yyyyMMdd>.csv`, the name offered for a new payments export.
String paymentsFileName(Chain chain, DateTime day) {
  String two(int v) => v.toString().padLeft(2, '0');
  final tag = chain == Chain.mainnet ? '' : '${chain.name}-';
  return 'epic-payments-$tag${day.year}${two(day.month)}${two(day.day)}.csv';
}

void _say(BuildContext context, String message, {required NoticeLevel level}) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(message, level: level);
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
            child: Text(context.l10n.commonDone),
          ),
        ],
      ),
    );

enum _Destination { device, share }

/// Offers "Save to device", and "Share" where the platform can, then hands the file over.
/// Returns true once it was saved or shared. [saveDialogTitle] titles the system save dialog
/// (the history backup's by default); [doneNotice], when given, is the success notice after a
/// save or a share instead of the file name saved after a save only. Also used for contacts files.
Future<bool> handOverFile(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required Uint8List bytes,
  required String title,
  String? note,
  String? saveDialogTitle,
  String? doneNotice,
}) async {
  final l = context.l10n;
  final files = ref.read(historyFilesProvider);
  var destination = _Destination.device;
  if (files.canShare) {
    final chosen = await showPhoneSheet<_Destination>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        // Scrolls on a short screen or with large text: the sheet stops at part of the height.
        child: SingleChildScrollView(
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
            dialogTitle: saveDialogTitle ?? l.historyBackupSaveDialogTitle,
          ),
          _Destination.share => files.share(name: name, bytes: bytes),
        },
      );
  if (done && doneNotice != null && context.mounted) {
    _say(context, doneNotice, level: NoticeLevel.success);
  } else if (done && destination == _Destination.device && context.mounted) {
    // The share sheet is its own confirmation; a save into a folder is silent otherwise.
    _say(context, l.historyBackupSaved(name), level: NoticeLevel.success);
  }
  return done;
}

/// What a history backup holds, told where the user exports it, and that a restore takes
/// the recovery phrase first, then this file.
String backupFileNote(AppLocalizations l) =>
    '${l.backupFileHolds} ${l.backupFileRestoreOrder}';

/// "Use the settings from this backup?" for [n] settings the user changed here that the file
/// has otherwise. True takes the backup's.
Future<bool> _askSettings(BuildContext context, int n) async {
  final use = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.backupSettingsTitle),
        content: Text(l.backupSettingsBody(n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.backupSettingsKeepMine),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.backupSettingsUseBackup),
          ),
        ],
      );
    },
  );
  return use == true;
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
    final bytes = await session.exportHistory(settings: await collectPhoneBackupSettings(ref));
    if (!context.mounted) return false;
    final name = historyFileName(
      config.chain,
      ref.read(clockProvider)(),
      'wfeh',
    );
    final saved = await handOverFile(
      context,
      ref,
      name: name,
      bytes: bytes,
      title: l.historyBackupExportTitle,
      // What the file holds, that it is not the recovery phrase, and the order of a restore.
      note: backupFileNote(l),
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
    if (context.mounted) {
      _say(context, describeError(l, error), level: NoticeLevel.error);
    }
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
    final name = paymentsFileName(config.chain, ref.read(clockProvider)());
    final saved = await handOverFile(
      context,
      ref,
      name: name,
      bytes: Uint8List.fromList(utf8.encode(csv)),
      title: l.historyBackupCsvTitle,
    );
    return saved;
  } catch (error) {
    if (context.mounted) {
      _say(context, describeError(l, error), level: NoticeLevel.error);
    }
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
    var report = await session.importHistory(data: bytes);
    if (!report.applied) {
      // The file disagrees with what the user entered: nothing is written until they choose.
      if (!context.mounted) return false;
      final choices = await showImportConflicts(context, report.conflicts);
      if (choices == null) return false;
      report = await session.importHistory(data: bytes, useBackup: choices);
    }
    // Everything an import can bring back, shown fresh.
    ref
      ..invalidate(homeProvider)
      ..invalidate(contactsProvider)
      ..invalidate(favouriteContactsProvider)
      ..invalidate(issuedInvoicesProvider)
      ..invalidate(pendingInvoicesProvider)
      ..invalidate(pairingsProvider);
    // The settings: those still as the app came are taken; one the user changed here that
    // differs from the file asks once for all.
    var settingsChanged = 0;
    final fileSettings = report.settings;
    if (fileSettings != null && context.mounted) {
      final plan = await planPhoneBackupSettings(ref, fileSettings);
      if (!context.mounted) return true;
      var takeConflicts = false;
      if (plan.conflicts.isNotEmpty) {
        takeConflicts = await _askSettings(context, plan.conflicts.length);
        if (!context.mounted) return true;
      }
      settingsChanged = await applyPhoneBackupSettings(ref, plan, takeConflicts: takeConflicts);
    }
    if (context.mounted) {
      // One summary of what came back.
      await _tell(
        context,
        l.historyBackupImportedTitle,
        [
          backupRestoredText(
            l,
            payments: report.merged + report.added,
            notes: report.notesAdded,
            labels: report.labelsAdded,
            contacts: report.contactsAdded,
            stars: report.starsAdded,
            pairings: report.pairingsAdded,
            invoices: report.invoicesAdded,
            settings: settingsChanged > 0,
            alreadyHere: report.skipped,
          ),
          if (report.replaced > 0) l.histImportedReplaced(report.replaced),
        ].join(' '),
      );
    }
    // Pairings used on another device wait until the user takes them over here (RFC 9.5).
    if (report.pairingsOtherDevice > 0 && context.mounted) {
      final use = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.restoreUseContactsTitle),
          content: Text(l.restoreUseContactsBody(report.pairingsOtherDevice)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.pairNotNow),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.restoreUseHere),
            ),
          ],
        ),
      );
      if (use == true) await session.pairing.useImportedPairings();
      ref.invalidate(pairingsProvider);
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      _say(
        context,
        l.historyBackupImportFailed(describeError(l, error)),
        level: NoticeLevel.error,
      );
    }
    return false;
  }
}
