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
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';

/// History backups are small; a file far larger is not one.
const int maxHistoryFileBytes = 32 << 20;

/// Moves history files in and out of the app.
abstract interface class HistoryFiles {
  /// Saves [bytes] as [name] where the user chooses. Returns false if they cancelled.
  Future<bool> save({required String name, required Uint8List bytes});

  /// Whether [share] works on this platform.
  bool get canShare;

  /// Hands [bytes] to another app as a file called [name]. Returns false if dismissed.
  Future<bool> share({required String name, required Uint8List bytes});

  /// Lets the user pick a file and returns its bytes, or null if they cancelled.
  Future<Uint8List?> pick();
}

class PlatformHistoryFiles implements HistoryFiles {
  const PlatformHistoryFiles();

  @override
  Future<bool> save({required String name, required Uint8List bytes}) =>
      saveBytesToDevice(
        name: name,
        bytes: bytes,
        dialogTitle: 'Save payment history',
      );

  @override
  bool get canShare => canShareFiles;

  @override
  Future<bool> share({required String name, required Uint8List bytes}) =>
      shareBytes(name: name, bytes: bytes);

  @override
  Future<Uint8List?> pick() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Open history backup');
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxHistoryFileBytes) {
      throw const FormatException('That file is too large to be a backup.');
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
  Future<bool> save({required String name, required Uint8List bytes}) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<bool> share({required String name, required Uint8List bytes}) async {
    shared.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<Uint8List?> pick() async => picks.isEmpty ? null : picks.removeAt(0);
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

/// The import counts in plain words.
String describeImport(ImportReport report) {
  String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  final parts = [
    if (report.merged > 0)
      '${count(report.merged, 'payment', 'payments')} got '
          'their details back',
    if (report.added > 0)
      '${count(report.added, 'older payment', 'older payments')} '
          'added',
    if (report.skipped > 0)
      '${count(report.skipped, 'record was', 'records were')} already here',
    if (report.contactsAdded > 0)
      '${count(report.contactsAdded, 'contact', 'contacts')} added',
  ];
  if (parts.isEmpty) return 'The backup held nothing new.';
  final text = parts.join(', ');
  return '${text[0].toUpperCase()}${text.substring(1)}.';
}

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
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
            child: const Text('OK'),
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
              title: const Text('Share'),
              subtitle: const Text(
                'Keep a copy off this phone, such as email or cloud storage',
              ),
              onTap: () => Navigator.pop(context, _Destination.share),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save to device'),
              subtitle: const Text(
                'Only useful if you also copy it off this phone.',
              ),
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
          _Destination.device => files.save(name: name, bytes: bytes),
          _Destination.share => files.share(name: name, bytes: bytes),
        },
      );
  // The share sheet is its own confirmation; a save into a folder is silent otherwise.
  if (done && destination == _Destination.device && context.mounted) {
    _say(context, 'Saved $name');
  }
  return done;
}

/// Exports the encrypted history backup. Returns true once the file was handed over.
Future<bool> exportHistoryBackup(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  try {
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
      title: 'Export history backup',
      note:
          'History backups hold payments up to now. Export again after new '
          'payments.',
    );
    // uihome: the home reminder counts payments since this export.
    if (saved) {
      await ref
          .read(appSettingsProvider.notifier)
          .setHistoryExported(config.chain, ref.read(clockProvider)());
    }
    return saved;
  } catch (error) {
    if (context.mounted) _say(context, describeError(error));
    return false;
  }
}

/// Warns that the CSV is readable by anyone, then exports it. Returns true once handed over.
Future<bool> exportHistoryCsv(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Export CSV'),
      content: const Text(
        'The CSV file is not encrypted. Anyone who gets it can read your '
        'amounts, dates, addresses and notes. It cannot be imported back; use '
        'Export history backup for that.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Export CSV'),
        ),
      ],
    ),
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
      title: 'Export CSV',
    );
    return saved;
  } catch (error) {
    if (context.mounted) _say(context, describeError(error));
    return false;
  }
}

/// Picks a history backup and imports it into the open wallet. Returns true when imported.
Future<bool> importHistoryBackup(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session == null) return false;
  try {
    final bytes = await ref
        .read(autoLockHoldProvider.notifier)
        .during(() => ref.read(historyFilesProvider).pick());
    if (bytes == null) return false;
    final report = await session.importHistory(data: bytes);
    ref.invalidate(homeProvider);
    if (context.mounted) {
      await _tell(context, 'History imported', describeImport(report));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      await _tell(context, 'Could not import', describeError(error));
    }
    return false;
  }
}
