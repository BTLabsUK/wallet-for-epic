// SPDX-License-Identifier: Apache-2.0
/// `settings_platform.dart` off the web.
library;

import 'dart:io';

import '../data_folder_io.dart';
import '../secret_store_api.dart';
import 'settings_backend.dart';
import 'settings_backend_io.dart';

/// The folder whose `settings.toml` is read: the data folder, or `<data>/dev/<chain>` for a
/// hidden dev chain.
Future<Directory> settingsFolder({String? devChain}) async {
  final data = await appDataDirectory();
  if (devChain == null) return data;
  final sep = Platform.pathSeparator;
  return Directory('${data.path}${sep}dev$sep$devChain');
}

/// The data folder's `settings.toml`. [store] is the web's; unused here.
Future<SettingsBackend> platformSettingsBackend({required SecretStore store, String? devChain}) async =>
    FileSettingsBackend(await settingsFolder(devChain: devChain));

/// Only the desktop watches the file: on the phone only the app writes it.
bool get settingsWatchSupported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// Where [backend]'s text is, for a message.
String settingsWhere(SettingsBackend backend) =>
    backend is FileSettingsBackend ? backend.file.path : backend.fileName;

/// A dev chain's own file [name] (`settings.default.toml`, `app-config.toml`) in its folder,
/// which `app/tool/dev_settings.sh` fills; null when it is not there.
Future<String?> readDevChainFile(String devChain, String name) async {
  final f = File('${(await settingsFolder(devChain: devChain)).path}${Platform.pathSeparator}$name');
  return await f.exists() ? f.readAsString() : null;
}

/// Where a dev chain's files are, for a message.
Future<String> devChainWhere(String devChain) async => (await settingsFolder(devChain: devChain)).path;
