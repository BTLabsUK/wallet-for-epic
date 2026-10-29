// SPDX-License-Identifier: Apache-2.0
// A restored (or new) wallet's first-run Setup saves while the wallet is still locked: the
// node and Epicbox choices are only stored, and Save goes on to Unlock. Through the real
// adapter (LepicDeskWallet over the fake core), whose locked wallet has no address to read.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

void main() {
  late Directory support;
  late MemorySecretStore secrets;
  late core.FakeWalletService service;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-restore-setup-');
    secrets = MemorySecretStore();
    service = core.FakeWalletService(password: _password);
  });

  tearDown(() => support.delete(recursive: true));

  LepicDeskWallet wallet() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final d = Directory(WalletRegistry.firstWalletDir(support.path, chain));
      await d.create(recursive: true);
      return d.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    rememberDir: () async => Directory('${support.path}/remember'),
  );

  test('a locked wallet takes a node and an Epicbox change: stored, no error', () async {
    final w = wallet();
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(w), deskStoreProvider.overrideWithValue(DeskStore(secrets))]);
    addTearDown(c.dispose);
    await w.restoreWallet(password: _password, phrase: service.phrase.split(' '));
    final ctl = c.read(deskProvider.notifier);
    expect(c.read(deskProvider).account, isNull);
    await ctl.useNode('https://node.example:3413');
    await ctl.useEpicbox('epicbox.example.com');
    final s = await w.status();
    expect(s.node.url, 'https://node.example:3413');
    expect(s.epicbox.domain, 'epicbox.example.com');
    await w.dispose();
  });
}
