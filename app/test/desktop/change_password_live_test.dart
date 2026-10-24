// Live: F32 on the real LEPIC core through LepicDeskWallet. A new wallet in a temp dir (temp
// key store, unreachable node) changes its password; then only the new one opens it, also from
// a fresh app over the same folders, and its remembered password is forgotten. A PIN wallet
// refuses a password change. Needs the Linux library:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   flutter test test/desktop/change_password_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

const _old = 'old-live-pass-1';
const _new = 'new-live-pass-2';

void main() {
  late Directory tmp;
  late MemorySecretStore secrets;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-change-password-live-');
    secrets = MemorySecretStore({'app.node.mainnet': 'http://127.0.0.1:9'});
  });

  tearDown(() => tmp.delete(recursive: true));

  LepicDeskWallet app() => LepicDeskWallet(
    service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
    walletDir: (chain) async {
      final d = Directory('${tmp.path}/support/wallets/${chain.name}');
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

  /// Unlock, again while the core still closes the last handle (its first sync runs on after
  /// a lock and holds the wallet for a moment: "Wallet busy").
  Future<bool> unlock(LepicDeskWallet w, String password) async {
    for (var i = 0; ; i++) {
      try {
        return await w.unlock(password);
      } on DeskError catch (e) {
        if (!e.message.startsWith('Wallet busy') || i == 30) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  test('after a change only the new password opens the wallet, also after a restart', () async {
    final wallet = app();
    await wallet.createWallet(name: 'Main', password: _old);
    final id = (await wallet.wallets()).single.id;
    expect(await wallet.unlock(_old, remember: true), isTrue);
    final phrase = await wallet.revealPhrase(_old);

    await expectLater(
      wallet.changePassword('not-the-password', _new),
      throwsA(isA<DeskError>().having((e) => e.wrongPassword, 'wrongPassword', isTrue)),
    );
    await wallet.changePassword(_old, _new);
    expect(await wallet.isRemembered(id), isFalse);
    expect(await wallet.revealPhrase(_new), phrase, reason: 'the open handle takes the new password');
    await wallet.lock();
    expect(await unlock(wallet, _old), isFalse);
    expect(await unlock(wallet, _new), isTrue);
    await wallet.lock();
    wallet.dispose();

    final again = app();
    addTearDown(again.dispose);
    expect(await unlock(again, _old), isFalse);
    expect(await unlock(again, _new), isTrue);
    expect(await again.revealPhrase(_new), phrase);
    expect(secrets.values.keys.where((k) => k.endsWith('vault-next')), isEmpty, reason: 'the change settled');
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false, timeout: const Timeout(Duration(minutes: 4)));

  test('a PIN wallet has no password to change', () async {
    final service = LepicWalletService(secrets: secrets, oneWalletPerChain: true);
    final created = await service.createWithPin(
      config: core.WalletConfig(dataDir: '${tmp.path}/pin/mainnet', chain: core.Chain.mainnet, nodeUrl: 'http://127.0.0.1:9', epicboxDomain: 'example.invalid', epicboxPort: 443),
      pin: '135790',
    );
    addTearDown(created.session.dispose);
    await expectLater(
      created.session.changePassword(currentPassword: 'anything-1', newPassword: _new),
      throwsA(isA<core.WalletError>().having((e) => e.kind, 'kind', core.WalletErrorKind.other)),
    );
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false, timeout: const Timeout(Duration(minutes: 2)));
}
