// SPDX-License-Identifier: Apache-2.0
// Live: deleting the open wallet on the real LEPIC core through LepicDeskWallet (tester report
// 26.10.16: "Wallet busy", then a Settings page that never loads). Needs the Linux library:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   flutter test test/desktop/delete_open_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

const _pass = 'delete-live-pass-1';

void main() {
  late Directory tmp;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-delete-live-');
  });

  tearDown(() => tmp.delete(recursive: true));

  /// An app over `<tmp>/<root>` with its own key store and an unreachable node.
  LepicDeskWallet app([String root = 'support']) {
    final secrets = MemorySecretStore({'app.node.mainnet': 'http://127.0.0.1:9'});
    return LepicDeskWallet(
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async {
        final d = Directory('${tmp.path}/$root/wallets/${chain.name}');
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => tmp,
      nodePoll: const Duration(hours: 1),
      nodeTimeout: const Duration(seconds: 2),
      rememberDir: () async => Directory('${tmp.path}/$root/remember'),
      listProcesses: () async => const [],
    );
  }

  test('the open wallet deletes with its password', () async {
    final w = app();
    await w.createWallet(name: 'Main', password: _pass);
    await w.createWallet(name: 'Third', password: _pass);
    final third = (await w.wallets()).firstWhere((e) => e.name == 'Third');
    await w.selectWallet(third.id);
    expect(await w.unlock(_pass), isTrue);
    await w.removeWallet(third.id, WalletRemoval.delete, password: _pass);
    expect((await w.wallets()).map((e) => e.name), ['Main']);
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);

  test('a restored wallet deletes right after unlock, while its first scan is due', () async {
    // A throwaway seed from a wallet made elsewhere.
    final phrase = await app('other').createWallet(name: 'Elsewhere', password: _pass);
    final w = app();
    await w.createWallet(name: 'Main', password: _pass);
    await w.restoreWallet(name: 'Third', password: _pass, phrase: phrase);
    final third = (await w.wallets()).firstWhere((e) => e.name == 'Third');
    await w.selectWallet(third.id);
    expect(await w.unlock(_pass), isTrue);
    await w.removeWallet(third.id, WalletRemoval.delete, password: _pass);
    expect((await w.wallets()).map((e) => e.name), ['Main']);
    expect(Directory('${third.folder}/lepic').existsSync(), isFalse);
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false);
}
