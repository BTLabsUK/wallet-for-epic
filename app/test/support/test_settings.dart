// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// `test/settings/test.toml`: the shipped file's layout with example hosts only.
const String testSettingsPath = 'test/settings/test.toml';

String? _text;

/// The test settings file's text (read once; tests run from the package folder).
String testSettingsText() => _text ??= File(testSettingsPath).readAsStringSync();

/// The test settings as the model, their own fallback.
HostSettings testSettings() => HostSettings.fromText(testSettingsText());

/// The shipped default file (`assets/settings/settings.toml`) as the model: for the tests that
/// check the real defaults or read a recorded answer of the real status site.
HostSettings shippedSettings() => HostSettings.fromText(File('assets/settings/settings.toml').readAsStringSync());

/// Makes the shipped defaults the settings in use for the tests of the calling group or file,
/// and puts the test settings back after each test.
void useShippedSettings() {
  setUp(() {
    hostSettings = shippedSettings();
    shippedHostSettings = hostSettings;
  });
  tearDown(() {
    hostSettings = testSettings();
    shippedHostSettings = hostSettings;
  });
}
