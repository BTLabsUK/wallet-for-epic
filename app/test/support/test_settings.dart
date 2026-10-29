// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';

/// `test/settings/test.toml`: the shipped file's layout with example hosts only.
const String testSettingsPath = 'test/settings/test.toml';

String? _text;

/// The test settings file's text (read once; tests run from the package folder).
String testSettingsText() => _text ??= File(testSettingsPath).readAsStringSync();

/// The test settings as the model, their own fallback.
HostSettings testSettings() => HostSettings.fromText(testSettingsText());
