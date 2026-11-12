// SPDX-License-Identifier: Apache-2.0
// The desktop checks an Epicbox address a chat app made into a link as the address itself.

import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

final String _address = 'es${'b' * 50}@epicbox.epiccash.com';

void main() {
  test('isEpicboxAddress reads http(s):// links of an address, and nothing else', () async {
    final support = await Directory.systemTemp.createTemp('desk-epicbox-link-');
    addTearDown(() => support.delete(recursive: true));
    final w = LepicDeskWallet(
      service: core.FakeWalletService(password: 'pw'),
      walletDir: (chain) async => WalletRegistry.firstWalletDir(support.path, chain),
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      rememberDir: () async => Directory('${support.path}/remember'),
    );
    expect(w.isEpicboxAddress(_address), isTrue);
    for (final form in ['http://$_address', 'https://$_address/', 'HTTPS://$_address']) {
      expect(w.isEpicboxAddress(form), isTrue, reason: form);
    }
    for (final form in ['https://$_address/path', 'https://$_address:443', 'http://192.168.1.5:3415']) {
      expect(w.isEpicboxAddress(form), isFalse, reason: form);
    }
  });
}
