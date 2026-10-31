// SPDX-License-Identifier: Apache-2.0
/// The wallet level as Riverpod state: the stored choice, the level in force and what it shows.
/// Platform-neutral; the first-start step and the Change level row call [WalletLevelNotifier.setLevel].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../network_gate.dart';
import '../providers.dart' show secretStoreProvider;
import '../settings.dart';
import '../tor_build.dart';
import 'level_features.dart';
import 'wallet_level.dart';

/// The stored level choice, settled once at launch ([settleLevelChoice]).
/// Never retried: a store that can't be read shows Deep end ([currentLevelProvider]) rather than
/// asking again on a timer.
final walletLevelProvider = AsyncNotifierProvider<WalletLevelNotifier, LevelChoice>(
  WalletLevelNotifier.new,
  retry: (_, _) => null,
);

class WalletLevelNotifier extends AsyncNotifier<LevelChoice> {
  @override
  Future<LevelChoice> build() async {
    final store = ref.read(secretStoreProvider);
    final choice = await settleLevelChoice(read: store.read, write: store.write);
    // The settings may have built before the level was known: bring the gate in line.
    // Only when built: the desktop keeps its settings elsewhere and never builds the phone's.
    final settings = ref.exists(appSettingsProvider) ? ref.read(appSettingsProvider).value : null;
    if (settings != null) NetGate.setExperimental(effectiveAdvanced(_levelOf(choice), settings.advanced));
    return choice;
  }

  /// The user picked [level]: stored, then its preset applied to the Advanced prefs when it
  /// changes them (level 3 turns the shown features on).
  Future<void> setLevel(WalletLevel level) async {
    await store(level);
    final notifier = ref.read(appSettingsProvider.notifier);
    final settings = await ref.read(appSettingsProvider.future);
    final preset = levelPreset(level, settings.advanced);
    if (preset != settings.advanced) await notifier.setAdvanced(preset);
    NetGate.setExperimental(effectiveAdvanced(level, preset));
  }

  /// Stores [level] and nothing else: the desktop applies the preset to its own settings.
  Future<void> store(WalletLevel level) async {
    await ref.read(secretStoreProvider).write(levelKey, LevelChosen(level).encode());
    state = AsyncData(LevelChosen(level));
  }
}

WalletLevel _levelOf(LevelChoice? c) => c is LevelChosen ? c.level : WalletLevel.everything;

/// The level in force: the chosen one, [WalletLevel.everything] while loading or pending so
/// nothing hides by accident.
final currentLevelProvider = Provider<WalletLevel>((ref) => _levelOf(ref.watch(walletLevelProvider).value));

/// The Advanced prefs the level shows ([effectiveAdvanced]); the stored ones at levels 2 and 3.
final effectiveAdvancedProvider = Provider<AdvancedPrefs>((ref) {
  final level = ref.watch(currentLevelProvider);
  final stored = ref.watch(appSettingsProvider.select((s) => s.value?.advanced)) ?? AdvancedPrefs.none;
  return effectiveAdvanced(level, stored);
});

/// What the level in force shows.
final levelFeaturesProvider = Provider<LevelFeatures>((ref) {
  final level = ref.watch(currentLevelProvider);
  final stored = ref.watch(appSettingsProvider.select((s) => s.value?.advanced)) ?? AdvancedPrefs.none;
  return LevelFeatures.of(level, stored, torBuilt: torBuilt);
});
