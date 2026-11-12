// SPDX-License-Identifier: Apache-2.0
// The phone's upgrade path from the levels: whatever level an install had stored (1, 2, 3,
// none, or a store that cannot be read), the phone runs the Advanced switches it has stored,
// Advanced shows the same ones, nothing is written at launch, and the level and Default method
// values stay on disk as they were. The reasoning is in levels/level_providers.dart.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/levels/level_providers.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store whose reads fail, as a locked or broken keystore does.
class _Unreadable extends MemorySecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('keystore unavailable');
}

const _stored = 'outputs,technicalDetails|standard';
const _payments = 'app.payment_prefs';

Future<(ProviderContainer, MemorySecretStore)> _open(String? level, {MemorySecretStore? store}) async {
  final s = store ?? MemorySecretStore({'app.advanced_prefs': _stored, _payments: 'link'});
  if (level != null) s.values[levelKey] = level;
  final container = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(s)]);
  addTearDown(container.dispose);
  await container.read(appSettingsProvider.future);
  return (container, s);
}

void main() {
  final want = AdvancedPrefs.decode(_stored);

  for (final level in ['1', '2', '3']) {
    test('an install stored at level $level runs and shows its stored Advanced switches', () async {
      final (c, s) = await _open(level);
      final prefs = c.read(effectiveAdvancedProvider);
      expect(prefs.encode(), want.encode());
      expect(prefs.pairingOn, isTrue);
      expect(prefs.linkedDevicesOn, isTrue);
      // Nothing written by the phone: the level and the Default method stay as stored.
      expect(s.values[levelKey], level);
      expect(s.values['app.advanced_prefs'], _stored);
      expect(s.values[_payments], 'link');
    });
  }

  test('an install with no level stored settles as before and runs its stored switches', () async {
    final (c, s) = await _open(null);
    expect(c.read(effectiveAdvancedProvider).encode(), want.encode());
    // The one launch write is the settling of the level key (existing install, never asked).
    await c.read(walletLevelProvider.future);
    expect(s.values[levelKey], '${existingInstallLevel.number}');
    expect(s.values['app.advanced_prefs'], _stored);
  });

  test('a store that cannot be read gives the defaults: switches off, pairing on, nothing written', () async {
    final store = _Unreadable();
    final container = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    final prefs = container.read(effectiveAdvancedProvider);
    expect(prefs.encode(), AdvancedPrefs.none.encode());
    expect(prefs.pairingOn, isTrue);
    expect(store.values, isEmpty);
  });
}
