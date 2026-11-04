// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:flutter/services.dart';

import '../../log.dart';

/// Makes the system file dialogs (Wallet › Export and Import, slates, folders) work on the
/// desktop. Called once at start, before any dialog opens.
///
/// - macOS: the plugin refuses every dialog unless the app has the sandbox's user-selected
///   file entitlements ("file could not be written", "something went wrong"). The app runs
///   without the sandbox (macos/Runner/*.entitlements), so the check is skipped.
/// - Linux: the chooser comes from the desktop portal, which only keeps it above the app when
///   told the app's window; without it GNOME opened the chooser behind the app.
Future<void> setUpDeskFileDialogs() async {
  if (Platform.isMacOS) {
    await FilePicker.skipEntitlementsChecks();
  } else if (Platform.isLinux) {
    FilePickerPlatform.instance = ParentedLinuxFilePicker(FilePickerPlatform.instance);
  }
}

/// The Linux file picker with the app's window as the dialogs' parent (portal parent_window),
/// so the chooser opens above the app and stays there. Without a handle (an older runner, a
/// display without one) the dialogs open as before.
class ParentedLinuxFilePicker extends FilePickerPlatform {
  ParentedLinuxFilePicker(this._inner, {Future<String?> Function()? parentHandle})
      : _parentHandle = parentHandle ?? _windowHandle;

  final FilePickerPlatform _inner;
  final Future<String?> Function() _parentHandle;

  static const _channel = MethodChannel('epic_wallet/window');

  /// The runner's answer (linux/runner/my_application.cc): "x11:…", "wayland:…" or null.
  static Future<String?> _windowHandle() async {
    try {
      return await _channel.invokeMethod<String>('parentHandle');
    } catch (e) {
      logError('file dialogs', e);
      return null;
    }
  }

  Future<LinuxOptions> _options(LinuxOptions given) async {
    if (given is FilePickerLinuxOptions && given.parentWindow != null) return given;
    final handle = await _parentHandle();
    if (handle == null) return given;
    return FilePickerLinuxOptions(
      parentWindow: handle,
      acceptLabel: given.acceptLabel,
      lockParentWindow: true,
    );
  }

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
  }) async =>
      _inner.pickFile(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
        compressionQuality: compressionQuality,
        androidOptions: androidOptions,
        darwinOptions: darwinOptions,
        windowsOptions: windowsOptions,
        linuxOptions: await _options(linuxOptions),
        webOptions: webOptions,
      );

  @override
  Future<List<PlatformFile>> pickFiles({
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
  }) async =>
      _inner.pickFiles(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
        compressionQuality: compressionQuality,
        androidOptions: androidOptions,
        darwinOptions: darwinOptions,
        windowsOptions: windowsOptions,
        linuxOptions: await _options(linuxOptions),
        webOptions: webOptions,
      );

  @override
  Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) =>
      _inner.pickFileAndDirectoryPaths(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
      );

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      _inner.getDirectoryPath(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        androidOptions: androidOptions,
        windowsOptions: windowsOptions,
        linuxOptions: await _options(linuxOptions),
        webOptions: webOptions,
      );

  @override
  Future<void> clearTemporaryFiles() => _inner.clearTemporaryFiles();

  @override
  Future<void> skipEntitlementsChecks() => _inner.skipEntitlementsChecks();

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
  }) async =>
      _inner.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        onFileSaving: onFileSaving,
        windowsOptions: windowsOptions,
        linuxOptions: await _options(linuxOptions),
        webOptions: webOptions,
      );
}
