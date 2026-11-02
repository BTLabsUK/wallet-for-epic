// SPDX-License-Identifier: Apache-2.0
// Test settings for one network mode or one dev chain (test_settings.dart holds the default).
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart' show networkModeKey, networkModeText;

import 'test_settings.dart';

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
