// SPDX-License-Identifier: Apache-2.0
/// Picking a transaction file from disk through the system's file dialog, and opening folders and
/// links in the system's file manager and browser.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network_gate.dart' show NetDial, NetGate;
import '../../slate_files.dart' show maxSlateFileBytes;

/// A transaction file chosen with [DeskFiles.pickSlates]: its [name], its [path] (the name
/// alone in a browser, which has no paths) and its [bytes], null when it is larger than any
/// transaction file ([maxSlateFileBytes]) or could not be read.
typedef PickedSlate = ({String name, String path, Uint8List? bytes});

abstract interface class DeskFiles {
  /// The path of the file chosen, or null when the dialog was closed.
  Future<String?> pickSlate({required String title});

  /// The files chosen, one or several; empty when the dialog was closed.
  Future<List<PickedSlate>> pickSlates({required String title});
}

class SystemDeskFiles implements DeskFiles {
  const SystemDeskFiles();

  @override
  Future<String?> pickSlate({required String title}) async => (await FilePicker.pickFile(dialogTitle: title))?.path;

  @override
  Future<List<PickedSlate>> pickSlates({required String title}) async {
    final picked = await FilePicker.pickFiles(dialogTitle: title);
    return [
      for (final f in picked) (name: f.name, path: f.path ?? f.name, bytes: await _read(f)),
    ];
  }

  static Future<Uint8List?> _read(PlatformFile f) async {
    try {
      final size = f.lengthSync() ?? await f.length();
      if (size == null || size > maxSlateFileBytes) return null;
      return await f.readAsBytes();
    } on Object {
      return null;
    }
  }
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

/// Opens the https address [url] in the default browser. False when it is not https, the
/// network mode refuses it (Node only, Kill switch: `NetGate.dial`) or the browser could not
/// be started.
Future<bool> openInBrowser(String url) async {
  final u = Uri.tryParse(url);
  if (u?.scheme != 'https') return false;
  if (!NetGate.allows(NetDial.browser, u!.host)) return false;
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
