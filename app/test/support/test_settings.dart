// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// `test/settings/`: the shipped pair's layout with example hosts only.
const String testSettingsPath = 'test/settings/settings.default.toml';
const String testConfigPath = 'test/settings/app-config.toml';

String? _text;
String? _configText;

/// The test default copy's text (read once; tests run from the package folder).
String testSettingsText() => _text ??= File(testSettingsPath).readAsStringSync();

/// The test `app-config.toml`'s text.
String testConfigText() => _configText ??= File(testConfigPath).readAsStringSync();

/// The test configuration.
AppConfig testConfig() => AppConfig.fromText(testConfigText());

/// The test settings as the model, their own default copy, over [testConfig].
HostSettings testSettings() => HostSettings.fromText(testSettingsText(), config: testConfig());

/// The test `app-config.toml` with the lines that start with [keys] (`donation`, `[status]`, …)
/// commented out: an entry left out of the file. A table name comments out the whole table.
String testConfigWithout(List<String> keys) {
  final out = <String>[];
  var inTable = false;
  for (final line in testConfigText().split('\n')) {
    if (line.startsWith('[')) inTable = keys.contains(line.trim());
    final key = line.split('=').first.trim();
    out.add(inTable || keys.contains(key) ? '# $line' : line);
  }
  return out.join('\n');
}

/// The shipped pair (`assets/config/`) as the model: for the tests that check the real defaults
/// or read a recorded answer of the real status site.
HostSettings shippedSettings() => HostSettings.fromText(
  File('assets/config/settings.default.toml').readAsStringSync(),
  config: AppConfig.fromText(File('assets/config/app-config.toml').readAsStringSync()),
);

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
