// SPDX-License-Identifier: Apache-2.0
// The desktop's network mode is settings.toml's `[network] mode` (network_mode_file.dart): the
// Advanced page's choice is written there, and a change of the file (a hand edit, a restored
// backup) reaches the desktop's settings and the wallet at once. Over the mock wallet.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer c;

  setUp(() {
    c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    c.listen(deskProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() {
    c.dispose();
    NetGate.set(NetworkMode.standard);
  });

  test('the Advanced page\'s choice is written to the file; Normal takes it out', () async {
    final n = c.read(deskProvider.notifier);
    final s = c.read(deskProvider).settings;
    await n.saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.killSwitch)));
    expect(c.read(hostSettingsProvider).networkModeText, 'kill_switch');
    expect(NetGate.killSwitch, isTrue);
    await n.saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.standard)));
    expect(c.read(hostSettingsProvider).networkModeText, '');
    expect(NetGate.mode, NetworkMode.standard);
  });

  test('a change of the file applies to the desktop at once', () async {
    await c.read(hostSettingsProvider.notifier).set(networkModeKey, 'node_only');
    await pumpEventQueue();
    expect(c.read(deskProvider).settings.advanced.networkMode, NetworkMode.nodeOnly);
    expect(NetGate.nodeOnly, isTrue);
    await c.read(hostSettingsProvider.notifier).set(networkModeKey, '');
    await pumpEventQueue();
    expect(c.read(deskProvider).settings.advanced.networkMode, NetworkMode.standard);
    expect(NetGate.mode, NetworkMode.standard);
  });
}
