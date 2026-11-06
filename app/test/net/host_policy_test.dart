// SPDX-License-Identifier: Apache-2.0
// The host policy LEPIC is given: the contact hold bounds come from `[contacts]` of
// app-config.toml, and every config the app builds carries them.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

void main() {
  test('hostPolicyOf reads the hold attempts and patience from the config', () {
    final p = LepicWalletService.hostPolicyOf(testConfig());
    expect(p.contactHoldAttempts, 10);
    expect(p.contactHoldPatienceS, BigInt.from(86400));
    final other = LepicWalletService.hostPolicyOf(
      testConfig().withValues({'contacts.hold_attempts': 4, 'contacts.hold_patience_s': 600}),
    );
    expect(other.contactHoldAttempts, 4);
    expect(other.contactHoldPatienceS, BigInt.from(600));
  });

  test('the config the app gives LEPIC carries the policy', () async {
    final c = await LepicWalletService.lepicConfigOf(
      const WalletConfig(dataDir: '/wallets/main', chain: Chain.mainnet, nodeUrl: '', epicboxDomain: '', epicboxPort: 443),
    );
    expect(c.policy.contactHoldAttempts, isNotNull);
    expect(c.policy.contactHoldPatienceS, isNotNull);
  });
}
