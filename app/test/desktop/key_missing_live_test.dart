// SPDX-License-Identifier: Apache-2.0
// Live: Unlock when the secret store lost the wallet's vault (macOS: the login keychain's items
// removed, a new code signature), on the real LEPIC core through LepicDeskWallet. The files stay;
// LEPIC's open fails, Unlock says the key is gone (not "No wallet found") and the recovery phrase
// seals a new vault that opens the same wallet. restore_fixes_desk_test covers the screen over a
// fake core; this checks the fake's premise, that LEPIC answers walletNotFound. Temp folders,
// unreachable node. Needs the Linux library:
//
//   WFE_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   flutter test test/desktop/key_missing_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_LEPIC_LIB'];

const _pass = 'key-missing-pass-1';

void main() {
  late Directory tmp;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-key-missing-live-');
  });

  tearDown(() => tmp.delete(recursive: true));

  /// An app over `<tmp>/support` with the key store [secrets] and an unreachable node.
  LepicDeskWallet app(MemorySecretStore secrets) => LepicDeskWallet(
    service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
    walletDir: (chain) async {
      final d = Directory(WalletRegistry.firstWalletDir('${tmp.path}/support', chain));
      await d.create(recursive: true);
      return d.path;
    },
    secrets: secrets,
    filesDir: () async => tmp,
    nodePoll: const Duration(hours: 1),
    nodeTimeout: const Duration(seconds: 2),
    rememberDir: () async => Directory('${tmp.path}/support/remember'),
    listProcesses: () async => const [],
  );

  test('a wallet whose vault the store lost: Unlock says the key is gone, its phrase opens it again', () async {
    final first = app(MemorySecretStore({'app.node.mainnet': 'http://127.0.0.1:9'}));
    final phrase = await first.createWallet(name: 'Main', password: _pass);
    final id = (await first.wallets()).single.id;
    expect(await first.unlock(_pass), isTrue);
    final address = await first.epicboxAddress();
    await first.dispose();

    // A fresh start over the same folders with an empty store.
    final w = app(MemorySecretStore({'app.node.mainnet': 'http://127.0.0.1:9'}));
    expect((await w.wallets()).single.id, id, reason: 'the folder still lists it');
    await expectLater(
      w.unlock(_pass),
      throwsA(isA<DeskError>().having((e) => e.keyMissing, 'keyMissing', isTrue)),
    );
    await w.resetPassword(id, phrase: phrase, newPassword: 'key-missing-pass-2');
    expect(await w.unlock('key-missing-pass-2'), isTrue);
    expect(await w.epicboxAddress(), address, reason: 'the same wallet');
    await w.dispose();
  }, skip: _lib == null ? 'needs WFE_LEPIC_LIB' : false, timeout: const Timeout(Duration(minutes: 3)));
}
