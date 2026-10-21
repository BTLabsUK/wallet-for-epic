/// The desktop UI's saved state: settings, the settings screens' choices, own nodes and the
/// wallet's name. Not secret, but kept in the app's [SecretStore], as the phone keeps its
/// preferences (`settings.dart`), so the app needs no preferences dependency.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../secret_store_api.dart';
import 'models.dart';

class DeskStore {
  const DeskStore(this._secrets);

  final SecretStore _secrets;

  static const settingsKey = 'desk.settings';
  static const prefsKey = 'desk.prefs';
  static const nodesKey = 'desk.nodes';
  static const favouritesKey = 'desk.favourites';

  /// The wallet of [chain]: name, creation time, whether a scan is due.
  static String walletKey(String chain) => 'desk.wallet.$chain';

  Future<Object?> readJson(String key) async {
    final text = await _secrets.read(key);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      logWarn('desk', 'saved $key is not JSON; using defaults');
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) => _secrets.write(key, jsonEncode(value));

  Future<void> delete(String key) => _secrets.delete(key);

  Future<DeskSettings> settings() async {
    final json = await readJson(settingsKey);
    return json is Map<String, dynamic> ? deskSettingsFromJson(json) : const DeskSettings();
  }

  Future<void> saveSettings(DeskSettings s) => writeJson(settingsKey, deskSettingsToJson(s));
}

Map<String, Object?> deskSettingsToJson(DeskSettings s) => {
  'theme': s.theme.name,
  'scale': s.scale,
  'hideAmounts': s.hideAmounts,
  'newLookSeen': s.newLookSeen,
  'autoLockMinutes': s.autoLockMinutes,
};

DeskSettings deskSettingsFromJson(Map<String, dynamic> j) {
  const d = DeskSettings();
  final scale = j['scale'];
  return DeskSettings(
    theme: ThemeChoice.values.where((t) => t.name == j['theme']).firstOrNull ?? d.theme,
    scale: scale is int && deskScales.contains(scale) ? scale : d.scale,
    hideAmounts: j['hideAmounts'] is bool ? j['hideAmounts'] as bool : d.hideAmounts,
    newLookSeen: j['newLookSeen'] is bool ? j['newLookSeen'] as bool : d.newLookSeen,
    autoLockMinutes: j.containsKey('autoLockMinutes') ? j['autoLockMinutes'] as int? : d.autoLockMinutes,
  );
}

/// What the app read before its first frame, so theme and scale apply on the first screen.
@immutable
class DeskBoot {
  const DeskBoot({this.settings = const DeskSettings(), this.prefs});

  final DeskSettings settings;

  /// The settings screens' saved choices (`prefs.dart`), as JSON.
  final Map<String, dynamic>? prefs;

  static Future<DeskBoot> load(DeskStore store) async {
    final prefs = await store.readJson(DeskStore.prefsKey);
    return DeskBoot(settings: await store.settings(), prefs: prefs is Map<String, dynamic> ? prefs : null);
  }
}

/// Where the desktop UI saves; null (the mock, the tests) saves nothing.
final deskStoreProvider = Provider<DeskStore?>((ref) => null);

final deskBootProvider = Provider<DeskBoot>((ref) => const DeskBoot());
