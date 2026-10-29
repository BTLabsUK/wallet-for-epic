// SPDX-License-Identifier: Apache-2.0
/// `settings_platform.dart` in the browser: no file. The text is a key in the app's store
/// (`app.settingsToml`), written on the first change; until then the shipped file is used.
library;

import '../secret_store_api.dart';
import 'settings_backend.dart';

Future<SettingsBackend> platformSettingsBackend({required SecretStore store, String? devChain}) async =>
    StoreSettingsBackend(store, key: devChain == null ? 'app.settingsToml' : 'app.settingsToml.$devChain');

bool get settingsWatchSupported => false;
