// SPDX-License-Identifier: Apache-2.0
// Linux's file dialogs carry the app's window as their parent, so the portal's chooser opens
// above the app (before, GNOME opened it behind); without a handle they open as before.
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/file_dialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder extends FilePickerPlatform {
  final seen = <LinuxOptions>[];

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    seen.add(linuxOptions);
    return null;
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    seen.add(linuxOptions);
    return null;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    seen.add(linuxOptions);
    return null;
  }
}

void main() {
  test('every dialog gets the window as its parent, modal to it', () async {
    final inner = _Recorder();
    final picker = ParentedLinuxFilePicker(inner, parentHandle: () async => 'wayland:abc');
    await picker.pickFile(dialogTitle: 'Import', linuxOptions: const LinuxOptions(acceptLabel: 'Open'));
    await picker.getDirectoryPath(dialogTitle: 'Folder');
    await picker.saveFile(fileName: 'h.wfeh', bytes: Uint8List(1), mimeType: 'application/octet-stream');
    expect(inner.seen, hasLength(3));
    for (final o in inner.seen) {
      expect(o, isA<FilePickerLinuxOptions>());
      expect((o as FilePickerLinuxOptions).parentWindow, 'wayland:abc');
      expect(o.lockParentWindow, isTrue);
    }
    expect(inner.seen.first.acceptLabel, 'Open');
  });

  test('without a handle the dialogs open as before', () async {
    final inner = _Recorder();
    final picker = ParentedLinuxFilePicker(inner, parentHandle: () async => null);
    const given = LinuxOptions(acceptLabel: 'Open');
    await picker.pickFile(linuxOptions: given);
    expect(inner.seen.single, same(given));
  });
}
