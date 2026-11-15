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
    expect(p.contactHoldAttempts, 3);
    expect(p.contactHoldPatienceS, BigInt.from(180));
    final other = LepicWalletService.hostPolicyOf(
      testConfig().withValues({'contacts.hold_attempts': 4, 'contacts.hold_patience_s': 600}),
    );
    expect(other.contactHoldAttempts, 4);
    expect(other.contactHoldPatienceS, BigInt.from(600));
  });

  test('hostPolicyOf reads the listener, quarantine and early notice bounds from the config', () {
    final p = LepicWalletService.hostPolicyOf(testConfig());
    expect(p.listenerHeldRounds, 8);
    expect(p.listenerChallengeRounds, 3);
    expect(p.quarantineMaxBytes, BigInt.from(16777216));
    expect(p.earlyNoticeMaxCount, 256);
    expect(p.earlyNoticeMaxAgeS, BigInt.from(604800));
    final other = LepicWalletService.hostPolicyOf(
      testConfig().withValues({
        'epicbox.listener_held_rounds': 3,
        'epicbox.listener_challenge_rounds': 5,
        'contacts.quarantine_max_bytes': 1024,
        'notices.early_notice_max_count': 5,
        'notices.early_notice_max_age_s': 60,
      }),
    );
    expect(other.listenerHeldRounds, 3);
    expect(other.listenerChallengeRounds, 5);
    expect(other.quarantineMaxBytes, BigInt.from(1024));
    expect(other.earlyNoticeMaxCount, 5);
    expect(other.earlyNoticeMaxAgeS, BigInt.from(60));
  });

  test('the config the app gives LEPIC carries the policy', () async {
    final c = await LepicWalletService.lepicConfigOf(
      const WalletConfig(dataDir: '/wallets/main', chain: Chain.mainnet, nodeUrl: '', epicboxDomain: '', epicboxPort: 443),
    );
    expect(c.policy.contactHoldAttempts, isNotNull);
    expect(c.policy.contactHoldPatienceS, isNotNull);
  });
}
