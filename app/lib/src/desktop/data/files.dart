// SPDX-License-Identifier: Apache-2.0
/// Picking a transaction file from disk through the system's file dialog, and opening folders and
/// links in the system's file manager and browser.
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

/// Open folder buttons: [openInFileManager]; tests record the folder instead.
final deskOpenFolderProvider = Provider<Future<bool> Function(String dir)>((ref) => openInFileManager);

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

/// Link buttons: [openInBrowser]; tests record the address instead.
final deskOpenUrlProvider = Provider<Future<bool> Function(String url)>((ref) => openInBrowser);

/// Opens the https address [url] in the default browser. False when it is not https or the
/// browser could not be started.
Future<bool> openInBrowser(String url) async {
  if (Uri.tryParse(url)?.scheme != 'https') return false;
  // Windows: the URL handler, which needs no shell, so nothing in the address is interpreted.
  final (cmd, args) = Platform.isWindows
      ? ('rundll32', ['url.dll,FileProtocolHandler', url])
      : (Platform.isMacOS ? 'open' : 'xdg-open', [url]);
  try {
    await Process.start(cmd, args, mode: ProcessStartMode.detached);
    return true;
  } on ProcessException {
    return false;
  }
}
