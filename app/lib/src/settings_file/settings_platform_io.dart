// SPDX-License-Identifier: Apache-2.0
/// `settings_platform.dart` off the web.
library;

import 'dart:convert';
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

/// The registry ids of the added wallets in the data folder's `wallets.json`, for the one-time
/// import of their records (`legacy_import.dart`); none when it cannot be read.
Future<List<String>> dataFolderWalletIds() async {
  try {
    final f = File('${(await appDataDirectory()).path}${Platform.pathSeparator}wallets.json');
    if (!await f.exists()) return const [];
    final j = jsonDecode(await f.readAsString());
    final wallets = j is Map ? j['wallets'] : null;
    return [
      if (wallets is List)
        for (final w in wallets)
          if (w is Map && w['id'] is String && !(w['id'] as String).startsWith('legacy-')) w['id'] as String,
    ];
  } on Object {
    return const [];
  }
}

/// Where a dev chain's files are, for a message.
Future<String> devChainWhere(String devChain) async => (await settingsFolder(devChain: devChain)).path;
