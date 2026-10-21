/// Picking a transaction file from disk through the system's file dialog.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class DeskFiles {
  /// The path of the file chosen, or null when the dialog was closed.
  Future<String?> pickSlate({required String title});
}

class SystemDeskFiles implements DeskFiles {
  const SystemDeskFiles();

  @override
  Future<String?> pickSlate({required String title}) async => (await FilePicker.pickFile(dialogTitle: title))?.path;
}

/// The file dialog; null in the mock, whose screens use a fixed file name.
final deskFilesProvider = Provider<DeskFiles?>((ref) => null);

/// Opens [dir] in the system's file manager. False when it could not be started.
Future<bool> openInFileManager(String dir) async {
  final cmd = Platform.isWindows ? 'explorer' : (Platform.isMacOS ? 'open' : 'xdg-open');
  try {
    await Process.start(cmd, [dir], mode: ProcessStartMode.detached);
    return true;
  } on ProcessException {
    return false;
  }
}
