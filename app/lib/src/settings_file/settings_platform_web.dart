// SPDX-License-Identifier: Apache-2.0
/// `settings_platform.dart` in the browser: no file. The text is a key in the app's store
/// (`app.settingsToml`), written on the first change; until then the shipped file is used.
library;

import '../secret_store_api.dart';
import 'settings_backend.dart';

Future<SettingsBackend> platformSettingsBackend({required SecretStore store, String? devChain}) async =>
    StoreSettingsBackend(store, key: devChain == null ? 'app.settingsToml' : 'app.settingsToml.$devChain');

bool get settingsWatchSupported => false;

/// Where [backend]'s text is, for a message.
String settingsWhere(SettingsBackend backend) =>
    backend is StoreSettingsBackend ? 'the app store key ${backend.key}' : backend.fileName;

/// No dev chain folder in a browser: the web demo is given its files by its server.
Future<String?> readDevChainFile(String devChain, String name) async => null;

/// Where a dev chain's files are, for a message.
Future<String> devChainWhere(String devChain) async => 'its server (demo/)';
