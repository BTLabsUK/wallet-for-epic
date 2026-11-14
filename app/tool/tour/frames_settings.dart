// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Settings and Gap-* settings pages. Add `('fr-<Frame>', _Start.home, visit)`
// entries to the list and, when a frame needs its own data, a seed to `_settingsSeeds`. See
// tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

Future<void> _openTab(_Tour t, String label) async {
  // Face unlock is set up on the wallet the frames show; the start-up clears it, so it is set here.
  t.store.values['wallet.mainnet.pinBiometrics'] = '1';
  await t.tap(find.descendant(of: find.byType(KitTabBar), matching: find.text(label)));
  await t.frames();
}

Future<void> _openSection(_Tour t, SettingsSection section) async {
  await _openTab(t, t.l.settingsTitle);
  await t.tap(find.byKey(settingsGroupKey(section)));
  await t.frames();
}

(String, _Start, _Visit) _sectionVisit(String frame, SettingsSection section) => (
  frame,
  _Start.home,
  (t) async {
    await _openSection(t, section);
    await t.shot(frame);
  },
);

/// The frames drawn in classic payments mode (epic1 off).
const Set<String> _epic1ClassicFrames = {'fr-Gap-11-Payments', 'fr-Gap-13-Wallet', 'fr-Settings-Advanced'};

final List<(String, _Start, _Visit)> _framesSettings = [
  (
    'fr-Settings',
    _Start.home,
    (t) async {
      await _openTab(t, t.l.settingsTitle);
      await t.shot('fr-Settings');
    },
  ),
  _sectionVisit('fr-Settings-Security', SettingsSection.security),
  (
    'fr-Settings-Picker',
    _Start.home,
    (t) async {
      await _openSection(t, SettingsSection.security);
      await t.tapText(t.l.settingsAutoLock);
      await t.frames();
      await t.shot('fr-Settings-Picker');
    },
  ),
  _sectionVisit('fr-Settings-Network', SettingsSection.privacyNetwork),
  _sectionVisit('fr-Settings-Advanced', SettingsSection.advanced),
  _sectionVisit('fr-Gap-11-Payments', SettingsSection.transactions),
  _sectionVisit('fr-Gap-12-Appearance', SettingsSection.display),
  _sectionVisit('fr-Gap-13-Wallet', SettingsSection.wallet),
  (
    'fr-Gap-14-Devices',
    _Start.home,
    (t) async {
      await _openTab(t, t.l.settingsTitle);
      await t.tap(find.byKey(settingsLinkedDevicesKey));
      await t.frames();
      await t.shot('fr-Gap-14-Devices');
    },
  ),
  (
    'fr-Gap-15-Help',
    _Start.home,
    (t) async {
      await _openTab(t, t.l.settingsTitle);
      await t.tap(find.byKey(settingsHelpKey));
      await t.frames();
      await t.shot('fr-Gap-15-Help');
    },
  ),
  (
    'fr-Gap-16-About',
    _Start.home,
    (t) async {
      await _openTab(t, t.l.settingsTitle);
      await t.tap(find.byKey(settingsHelpKey));
      await t.frames();
      await t.tapText(t.l.phoneSettingsAboutRow);
      await t.frames();
      await t.shot('fr-Gap-16-About');
    },
  ),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _settingsSeeds = {};

/// What the Settings frames start with in the store: English, and the Advanced options the
/// frames show on.
final Map<String, void Function(MemorySecretStore)> _settingsStore = {
  for (final name in [
    'fr-Settings',
    'fr-Settings-Security',
    'fr-Settings-Picker',
    'fr-Settings-Network',
    'fr-Settings-Advanced',
    'fr-Gap-11-Payments',
    'fr-Gap-12-Appearance',
    'fr-Gap-13-Wallet',
    'fr-Gap-14-Devices',
    'fr-Gap-15-Help',
    'fr-Gap-16-About',
  ])
    name: (s) {
      s.values['app.language'] = 'en';
      s.values['app.advanced_prefs'] = 'outputs,technicalDetails|standard';
    },
};
