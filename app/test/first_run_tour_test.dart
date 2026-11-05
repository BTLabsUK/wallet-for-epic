// SPDX-License-Identifier: Apache-2.0
// The first-run tour opens by itself only on a fresh install's first run: never after an
// update of an install that has data (wallets, settings, the level), whatever older version
// wrote it, and never on a second launch. Settling it changes nothing else in the store.
import 'package:epic_wallet/src/first_run_tour.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart' show levelKey, levelPendingValue, settleLevelChoice;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/tour/phone_tour.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _seenKey = AppSettingsNotifier.phoneTourSeenKey;

/// A launch as `main.dart` runs it: the tour settled first, then the level, then the settings;
/// returns whether Home's automatic start opened the tour.
Future<bool> _launch(MemorySecretStore store) async {
  await settlePhoneFirstRunTour(store);
  await settleLevelChoice(read: store.read, write: store.write);
  final c = ProviderContainer(
    overrides: [secretStoreProvider.overrideWithValue(store), phonePaymentsProvider.overrideWithValue(true)],
    retry: (_, _) => null,
  );
  addTearDown(c.dispose);
  final opened = await c.read(phoneTourProvider.notifier).openIfUnseen();
  await pumpEventQueue();
  return opened;
}

class _Broken implements SecretStore {
  @override
  Future<String?> read(String key) => throw StateError('keystore');

  @override
  Future<void> write(String key, String value) => throw StateError('keystore');

  @override
  Future<void> delete(String key) => throw StateError('keystore');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install: the tour opens on the first run, and never on the next', () async {
    final store = MemorySecretStore();
    expect(await _launch(store), isTrue);
    expect(store.values[_seenKey], 'true');
    expect(await _launch(store), isFalse);
  });

  test('a fresh install whose first run never opened it (left Home first): not on the second launch', () async {
    final store = MemorySecretStore();
    expect(await settlePhoneFirstRunTour(store), isTrue);
    await settleLevelChoice(read: store.read, write: store.write);
    store.values['wallet.mainnet.pinSealed'] = 'sealed';
    expect(await _launch(store), isFalse);
    expect(store.values[_seenKey], 'true');
  });

  group('an update of an install with data never opens it', () {
    // What each older version left without the tour's flag: a wallet from before the tour
    // (26.10.23), settings, the level (26.10.31+, Level 1 never opened it by itself).
    for (final (name, key, value) in [
      ('a sealed wallet PIN', 'wallet.mainnet.pinSealed', 'sealed'),
      ('settings only', 'app.advanced_prefs', ''),
      ('the settings marker', 'app.qr_method_seen', 'true'),
      ('the network', 'app.network', 'mainnet'),
      ('a level choice', levelKey, '1'),
      ('a pending level step', levelKey, levelPendingValue),
    ]) {
      test(name, () async {
        final store = MemorySecretStore()..values[key] = value;
        final before = Map.of(store.values);
        expect(await _launch(store), isFalse);
        expect(store.values[_seenKey], 'true');
        // Only the flag was added; what was there is as it was.
        for (final e in before.entries) {
          expect(store.values[e.key], e.value, reason: e.key);
        }
      });
    }

    test('a tour seen or skipped before stays seen, its flag untouched', () async {
      final store = MemorySecretStore()
        ..values[_seenKey] = 'true'
        ..values['wallet.mainnet.pinSealed'] = 'sealed';
      expect(await settlePhoneFirstRunTour(store), isFalse);
      expect(await _launch(store), isFalse);
      expect(store.values[_seenKey], 'true');
    });
  });

  test('a store that cannot be read is left alone and nothing throws', () async {
    expect(await settlePhoneFirstRunTour(_Broken()), isFalse);
  });

  test('Help › Show the tour again still opens it on an updated install', () async {
    final store = MemorySecretStore()..values['wallet.mainnet.pinSealed'] = 'sealed';
    await settlePhoneFirstRunTour(store);
    final c = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(store), phonePaymentsProvider.overrideWithValue(true)]);
    addTearDown(c.dispose);
    c.read(phoneTourProvider.notifier).open();
    expect(c.read(phoneTourProvider).open, isTrue);
  });
}
