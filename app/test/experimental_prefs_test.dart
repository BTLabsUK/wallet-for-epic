// SPDX-License-Identifier: Apache-2.0
// Retired Advanced values. Pairing, Invoices and Linked devices are on for everyone: a value an
// older build stored is read, kept as stored and ignored, so an update changes nothing on disk
// and a downgrade finds its old switch as it left it.
import 'dart:convert';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/backup_settings.dart';
import 'package:epic_wallet/src/levels/level_features.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shapes 26.11.3 saved: the phone's `app.advanced_prefs`.
const _phoneShapes = [
  'invoices|standard',
  'outputs,invoices|standard',
  'invoices,logs,outputs|torOnly|noFailover',
  'invoices,pairing|standard',
  'outputs|standard',
  '|standard',
];

/// The desktop's `advanced` block (settings file, written with toJson(mode: false)).
const _deskShapes = <Map<String, Object?>>[
  {'features': ['invoices'], 'nodeFailover': true, 'linkedDevices': true},
  {'features': ['invoices', 'outputs'], 'nodeFailover': false, 'linkedDevices': true},
  {'features': ['outputs'], 'nodeFailover': true, 'linkedDevices': true},
];

void main() {
  test('Pairing and Linked devices are always on, for a new wallet and an old one', () {
    expect(AdvancedPrefs.none.pairingOn, isTrue);
    expect(AdvancedPrefs.decode('outputs,technicalDetails|standard').pairingOn, isTrue);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard'}).pairingOn, isTrue);
    expect(retiredFeatures, containsAll([AdvancedFeature.pairing, AdvancedFeature.invoices, AdvancedFeature.linkedDevices]));
  });

  test('a saved invoices value is kept byte for byte on the phone, so an older build reads it back', () {
    for (final stored in _phoneShapes) {
      expect(AdvancedPrefs.decode(stored).encode(), _sorted(stored), reason: stored);
    }
  });

  test('a saved invoices value is kept on the desktop, and an unknown key does no harm', () {
    for (final stored in _deskShapes) {
      expect(AdvancedPrefs.fromJson(stored).toJson(mode: false), {
        ...stored,
        'features': [...stored['features']! as List]..sort(),
      });
    }
    expect(AdvancedPrefs.fromJson(jsonDecode('{"features":["invoices","later"],"nodeFailover":true,"later":1}')).shownFeatures, isEmpty);
  });

  test('the saved value changes nothing: the same Advanced state, views and gates with or without it', () {
    final withValue = AdvancedPrefs.decode('outputs,invoices|standard');
    final without = AdvancedPrefs.decode('outputs|standard');
    expect(withValue.shownFeatures, without.shownFeatures);
    expect(withValue.any, without.any);
    expect(AdvancedPrefs.decode('invoices|standard').any, isFalse);
    for (final level in WalletLevel.values) {
      expect(LevelFeatures.of(level, withValue, torBuilt: false).invoices, LevelFeatures.of(level, without, torBuilt: false).invoices, reason: '$level');
    }
  });

  test('a later save keeps the value, and Hide all leaves it', () {
    final p = AdvancedPrefs.decode('invoices|standard').withFeature(AdvancedFeature.outputs, true);
    expect(p.encode(), 'invoices,outputs|standard');
    expect(p.shownFeatures, {AdvancedFeature.outputs});
    expect(p.withoutShown().encode(), 'invoices|standard');
    expect(p.withMode(NetworkMode.torOnly).encode(), 'invoices,outputs|torOnly');
  });

  test('an old backup with the value restores cleanly: no question, and nothing about invoices changes', () {
    Map<String, Object?> advanced(List<String> features) => {'features': features, 'networkMode': 'standard', 'nodeFailover': true};
    BackupSettingsPlan plan({required List<String> file, required List<String> mine}) => planBackupSettings(
      here: BackupPlatform.mobile,
      mine: {BackupKey.advanced: advanced(mine)},
      defaults: {BackupKey.advanced: advanced(const [])},
      file: {BackupKey.v: backupSettingsVersion, BackupKey.from: BackupPlatform.mobile.name, BackupKey.advanced: advanced(file)},
    );

    final same = plan(file: const ['invoices', 'outputs'], mine: const ['outputs']);
    expect(same.isEmpty, isTrue);

    final onlyValue = plan(file: const ['invoices'], mine: const ['invoices']);
    expect(onlyValue.isEmpty, isTrue);

    // The file's value is not taken, and the install's stays.
    final over = plan(file: const ['invoices', 'logs'], mine: const []);
    expect(advancedFromBackup(AdvancedPrefs.none, over.values(takeConflicts: true)).encode(), 'logs|standard');
    final kept = plan(file: const ['logs'], mine: const ['invoices']);
    expect(advancedFromBackup(AdvancedPrefs.decode('invoices|standard'), kept.values(takeConflicts: true)).encode(), 'invoices,logs|standard');
  });

  test('Linked devices: a stored off from an older build is ignored (item 10)', () {
    expect(AdvancedPrefs.none.linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.any, isFalse);
    expect(AdvancedPrefs.decode('outputs|standard').linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.decode('outputs|standard|noLinkedDevices').linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.fromJson({'features': ['logs'], 'networkMode': 'standard', 'linkedDevices': false}).linkedDevicesOn, isTrue);
    final off = AdvancedPrefs.none.withFeature(AdvancedFeature.linkedDevices, false);
    expect(off.linkedDevicesOn, isTrue);
    expect(off.has(AdvancedFeature.linkedDevices), isTrue);
    expect(off.any, isFalse);
    expect(off.encode(), isNot(contains('noLinkedDevices')));
    expect(AdvancedPrefs.fromJson(off.toJson()).linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.decode(AdvancedPrefs.none.encode()), AdvancedPrefs.none);
    expect(AdvancedPrefs.none.withoutShown().linkedDevicesOn, isTrue);
    expect(AdvancedPrefs.none.pairingEngineOn, isTrue);
    expect(NetGate.pairing, isTrue);
  });
}

/// [stored] with its feature list in the order every build writes it.
String _sorted(String stored) {
  final parts = stored.split('|');
  return [(parts.first.split(',')..sort()).join(','), ...parts.skip(1)].join('|');
}
