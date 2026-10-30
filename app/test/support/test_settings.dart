// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart' show networkModeKey, networkModeText;
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

/// Makes [mode] the settings file's `[network] mode` for this test (the one place the mode is
/// kept, `network_mode_file.dart`); the next test starts from the test settings again.
void useNetworkModeFile(NetworkMode mode) {
  hostSettings = hostSettings.withValues({networkModeKey: networkModeText(mode)});
}

/// Makes a dev [chain]'s own `app-config.toml` (`tool/config/<chain>/`, its node ports among
/// it) the configuration in use for this test, over the test default copy; mainnet keeps the
/// test configuration.
void useChainConfig(Chain chain) {
  if (chain == Chain.mainnet) return;
  hostSettings = HostSettings.fromText(
    testSettingsText(),
    config: AppConfig.fromText(File('tool/config/${chain.name}/app-config.toml').readAsStringSync()),
  );
}
