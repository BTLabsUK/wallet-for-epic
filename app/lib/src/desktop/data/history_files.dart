/// The system Save and Open dialogs for history backups and the CSV (F34), behind a seam so
/// the mock and the tests answer without a dialog.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lepic_desk_wallet.dart' show maxDeskHistoryBytes;
import 'models.dart';

abstract interface class DeskHistoryFiles {
  /// Saves [bytes] as [name] where the user chooses; the path written, or null when the dialog
  /// was closed. A write that fails throws.
  Future<String?> save({required String name, required Uint8List bytes, required String title});

  /// The file the user picks, or null when the dialog was closed. A file too large to be a
  /// history backup (or larger than [maxBytes]) throws a [HistoryFileError] before it is read.
  /// [extensions] are the kinds offered: history backups by default, `json` for contacts.
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes});
}

class SystemDeskHistoryFiles implements DeskHistoryFiles {
  const SystemDeskHistoryFiles();

  @override
  Future<String?> save({required String name, required Uint8List bytes, required String title}) async {
    final uri = await FilePicker.saveFile(fileName: name, bytes: bytes, dialogTitle: title);
    if (uri == null) return null;
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  }

  @override
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes}) async {
    final file = await FilePicker.pickFile(dialogTitle: title, type: FileType.custom, allowedExtensions: extensions);
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > (maxBytes ?? maxDeskHistoryBytes)) throw tooLargeHistoryFile;
    return (name: file.name, bytes: await file.readAsBytes());
  }
}

final tooLargeHistoryFile = HistoryFileError.l10n(HistoryFileProblem.tooLarge, (l) => l.deskErrHistTooLarge);

/// The mock's dialogs: a save lands in ~/Documents, a pick gives a fixed file; tests queue
/// their own answers.
class MockDeskHistoryFiles implements DeskHistoryFiles {
  MockDeskHistoryFiles();

  /// Saved files, by name.
  final List<String> saved = [];

  /// What the next saves answer, in turn: a path, null (closed), or an error to throw.
  final List<Object?> saves = [];

  /// What the next picks answer, in turn: a file, null (closed), or an error to throw.
  final List<Object?> picks = [];

  @override
  Future<String?> save({required String name, required Uint8List bytes, required String title}) async {
    final next = saves.isEmpty ? '~/Documents/$name' : saves.removeAt(0);
    if (next is Exception || next is Error) throw next!;
    if (next != null) saved.add(name);
    return next as String?;
  }

  @override
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes}) async {
    final next = picks.isEmpty ? (name: 'epic-wallet-data-savings-mainnet-20261003.wfeh', bytes: Uint8List(8)) : picks.removeAt(0);
    if (next is Exception || next is Error) throw next!;
    return next as ({String name, Uint8List bytes})?;
  }
}

final deskHistoryFilesProvider = Provider<DeskHistoryFiles>((ref) => MockDeskHistoryFiles());
