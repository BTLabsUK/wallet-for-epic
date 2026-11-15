// SPDX-License-Identifier: Apache-2.0
// The recovery phrase line reads the open wallet's own flag: a wallet deleted and made again on
// the same chain is "not backed up", even while Home's reminder keeps the provider alive.
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = WalletConfig(dataDir: '/w', chain: Chain.mainnet, nodeUrl: 'https://node.lab.invalid', epicboxDomain: 'box.epic.invalid', epicboxPort: 443);

void main() {
  test('a wallet made again after a delete reads its own backed-up flag', () async {
    final store = MemorySecretStore();
    final container = ProviderContainer(
      overrides: [walletServiceProvider.overrideWithValue(FakeWalletService()), secretStoreProvider.overrideWithValue(store)],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    // Held the whole time, as Home's reminder holds it.
    final held = container.listen(backedUpProvider, (_, _) {});
    addTearDown(held.close);
    container.read(walletConfigProvider.notifier).select(_config);
    final vault = container.read(vaultProvider);

    await vault.markBackedUp(Chain.mainnet);
    container.read(sessionProvider.notifier).unlocked(FakeWalletSession());
    expect(await container.read(backedUpProvider.future), isTrue);

    // Delete: the session closes and the flags go; then a new wallet on the same config.
    container.read(sessionProvider.notifier).lock();
    await vault.forget(Chain.mainnet);
    container.read(walletConfigProvider.notifier).select(_config);
    container.read(sessionProvider.notifier).unlocked(FakeWalletSession());
    expect(await container.read(backedUpProvider.future), isFalse);
  });
}
