/// `slate_files.dart`'s file calls on the phone and desktop: the save dialog, the share sheet
/// and its temporary copies.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Lets the user choose where to save [bytes] as [name]: the system save dialog, which on
/// Android is the Storage Access Framework (Downloads, Drive, a USB stick). Returns false if the
/// user cancelled. Also used for history backups.
Future<bool> saveBytesToDevice({
  required String name,
  required Uint8List bytes,
  required String dialogTitle,
}) async {
  final saved = await FilePicker.saveFile(
    fileName: name,
    bytes: bytes,
    dialogTitle: dialogTitle,
  );
  return saved != null;
}

/// Hands [bytes] to another app through the share sheet, as a file called [name]. Returns
/// false if the user dismissed it. Only where `canShareFiles`.
///
/// The share sheet needs a real file. It is written to `<tmp>/shared` and deleted as soon as the
/// sheet returns: on Android share_plus has copied it into its own cache by then, and on iOS the
/// receiving app has read it. [mimeType] tells the receiving app what it is; [text] goes along
/// as the message, where the app takes one. [share] and [tempDir] are for tests.
Future<bool> shareBytes({
  required String name,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
  String? text,
  @visibleForTesting Future<ShareResult> Function(ShareParams params)? share,
  @visibleForTesting Directory? tempDir,
}) async {
  final tmp = tempDir ?? await getTemporaryDirectory();
  final dir = Directory('${tmp.path}${Platform.pathSeparator}$_sharedDir');
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  try {
    final result = await (share ?? SharePlus.instance.share)(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: [name],
        // A message app shows the subject as text too; with a message, that is enough.
        subject: text == null ? name : null,
        text: text,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  } finally {
    if (await file.exists()) await file.delete();
  }
}

const String _sharedDir = 'shared';

/// Cache folders that can hold copies of shared files: ours, share_plus's own copy on Android
/// (`<cache>/share_plus`, cleared by the plugin only at the next share), and the folder older
/// versions of this app used for transaction files.
const List<String> _shareCaches = [_sharedDir, 'share_plus', 'slates'];

/// Deletes every leftover copy of a shared file (transaction files, history backups, CSV). Call
/// it when the wallet is deleted. [tempDir] is for tests.
Future<void> clearSharedFiles({@visibleForTesting Directory? tempDir}) async {
  final tmp = tempDir ?? await getTemporaryDirectory();
  for (final name in _shareCaches) {
    final dir = Directory('${tmp.path}${Platform.pathSeparator}$name');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
