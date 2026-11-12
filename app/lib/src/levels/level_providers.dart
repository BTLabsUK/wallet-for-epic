// SPDX-License-Identifier: Apache-2.0
/// The wallet level as Riverpod state: the stored choice and the level in force. The desktop
/// reads it (its Welcome dial and Settings › Advanced); the phone has no levels since the
/// phone redesign and only keeps the launch settling ([settleLevelChoice]), which tells a fresh
/// install from an existing one for the first-start hold.
///
/// Phone upgrade path (no write at launch, the level key is never touched by the phone UI):
/// every starting level runs the same engines. Pairing, invoices and linked devices are always
/// on ([AdvancedPrefs.pairingOn], [AdvancedPrefs.linkedDevicesOn]), so level 1's forced
/// "pairing + linked devices" set was already the same as the stored prefs for those. Levels 2
/// and 3, an unreadable store and a missing key already ran the stored prefs. A level-1 install
/// now runs its stored switches too; they were all off unless the user had set them at level 2
/// or 3 before. Advanced shows the stored switches, so it matches what runs. The stored level
/// and "Default method" values stay where they are and are no longer read on the phone.
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
    if (settings != null) NetGate.setExperimental(settings.advanced);
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
    NetGate.setExperimental(preset);
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

/// The Advanced prefs the phone runs and shows: the stored ones, at every starting level
/// (see the library comment). The desktop keeps its levels in `desk_levels.dart`.
final effectiveAdvancedProvider = Provider<AdvancedPrefs>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.value?.advanced)) ?? AdvancedPrefs.none;
});

/// What the matrix shows for the stored prefs, with no level in force: Send reads it until its
/// rebuild stops reading the level. Nothing else on the phone reads it.
final levelFeaturesProvider = Provider<LevelFeatures>((ref) {
  final stored = ref.watch(appSettingsProvider.select((s) => s.value?.advanced)) ?? AdvancedPrefs.none;
  return LevelFeatures.of(WalletLevel.everything, stored, torBuilt: torBuilt);
});
