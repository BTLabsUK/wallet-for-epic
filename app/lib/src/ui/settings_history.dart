/// Transaction history backup: the encrypted `.wfeh` export, the CSV export and the import.
///
/// Files leave the app the way transaction files do (`slate_files.dart`): a save dialog on
/// desktop, the share sheet on phones. Binary content needs its own path, because slate files
/// are text.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';

/// History backups are small; a file far larger is not one.
const int maxHistoryFileBytes = 32 << 20;

/// Moves history files in and out of the app.
abstract interface class HistoryFiles {
  /// Hands [bytes] over as a file called [name]. Returns false if the user cancelled.
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  });

  /// Lets the user pick a file and returns its bytes, or null if they cancelled.
  Future<Uint8List?> pick();
}

class PlatformHistoryFiles implements HistoryFiles {
  const PlatformHistoryFiles();

  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!_mobile) {
      final saved = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        dialogTitle: 'Save history file',
      );
      return saved != null;
    }
    // The share sheet needs a real file; it lives in the cache and is replaced next time.
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}history',
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: [name],
        subject: name,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

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

/// Records saves and hands out queued picks, for widget tests.
class FakeHistoryFiles implements HistoryFiles {
  final List<({String name, Uint8List bytes, String mimeType})> saved = [];
  final List<Uint8List?> picks = [];

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    saved.add((name: name, bytes: bytes, mimeType: mimeType));
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
      '${count(report.merged, 'transaction', 'transactions')} got '
          'their details back',
    if (report.added > 0)
      '${count(report.added, 'older transaction', 'older transactions')} '
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

Future<bool> _save(
  WidgetRef ref, {
  required String name,
  required Uint8List bytes,
  required String mimeType,
}) => ref
    .read(autoLockHoldProvider.notifier)
    .during(
      () => ref
          .read(historyFilesProvider)
          .save(name: name, bytes: bytes, mimeType: mimeType),
    );

/// Exports the encrypted history backup. Returns true once the file was handed over.
Future<bool> exportHistoryBackup(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  try {
    final bytes = await session.exportHistory();
    final saved = await _save(
      ref,
      name: historyFileName(config.chain, ref.read(clockProvider)(), 'wfeh'),
      bytes: bytes,
      mimeType: 'application/octet-stream',
    );
    if (saved && context.mounted) _say(context, 'History backup exported');
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
        'Export backup for that.',
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
    final saved = await _save(
      ref,
      name: historyFileName(config.chain, ref.read(clockProvider)(), 'csv'),
      bytes: Uint8List.fromList(utf8.encode(csv)),
      mimeType: 'text/csv',
    );
    if (saved && context.mounted) _say(context, 'CSV exported');
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
