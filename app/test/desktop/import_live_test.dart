// Live: a wallet.seed made by the real epic-wallet 4.1 imported through the real LEPIC
// service and LepicDeskWallet, then opened. Everything lives in a temp dir: the program runs
// with HOME there, the app's folder and key store are temp, the node is unreachable. The
// phrase is compared in memory and never printed. Needs the Linux library and the program:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   WFE_IMPORT_LIVE_BIN=/path/to/a/copy/of/epic-wallet \
//   flutter test test/desktop/import_live_test.dart
//
// Without them it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _bin = Platform.environment['WFE_IMPORT_LIVE_BIN'];

void main() {
  test('an epic-wallet 4.1 wallet.seed imports into LEPIC and opens with the same phrase', () async {
    await initLepic(libraryPath: _lib);
    final tmp = await Directory.systemTemp.createTemp('desk-import-live-');
    addTearDown(() => tmp.delete(recursive: true));
    final home = '${tmp.path}/home';
    final made = '${tmp.path}/made';
    await Directory(home).create();
    const oldPassword = 'old-live-pass-1';
    final init = await Process.run(
      _bin!,
      ['--floonet', '-t', made, '-p', oldPassword, 'init'],
      environment: {'HOME': home, 'PATH': '/usr/bin:/bin'},
      includeParentEnvironment: false,
    ).timeout(const Duration(minutes: 2));
    expect(init.exitCode, 0, reason: 'epic-wallet init failed');
    final lines = (init.stdout as String).split('\n').map((l) => l.trim()).toList();
    final at = lines.indexWhere((l) => l.startsWith('Your recovery phrase is'));
    final phrase = lines.skip(at + 1).firstWhere((l) => l.isNotEmpty);
    expect(phrase.split(' '), hasLength(24));

    // The seed as an old program leaves it: <home>/.epic/main/wallet_data/wallet.seed.
    final seed = File('$made/wallet_data/wallet.seed');
    final old = '$home/.epic/main';
    await File('$old/wallet_data/wallet.seed').create(recursive: true);
    await seed.copy('$old/wallet_data/wallet.seed');
    final before = await folderHash(home);

    final support = await Directory('${tmp.path}/support').create();
    final secrets = MemorySecretStore({'app.node.mainnet': 'http://127.0.0.1:9'});
    final wallet = LepicDeskWallet(
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async {
        final d = Directory('${support.path}/wallets/${chain.name}');
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => tmp,
      nodePoll: const Duration(hours: 1),
      nodeTimeout: const Duration(seconds: 2),
      legacyRoots: () => LegacyRoots(home: home, appData: '${tmp.path}/appdata'),
      listProcesses: () async => const [],
    );
    addTearDown(wallet.dispose);

    final found = await wallet.findOldWallets();
    final cli = found.singleWhere((w) => w.folder == old);
    await expectLater(
      wallet.importOldWallet(cli.id, oldPassword: 'not-the-password'),
      throwsA(isA<DeskError>().having((e) => e.wrongPassword, 'wrongPassword', isTrue)),
    );
    expect(await wallet.wallets(), isEmpty);
    final r = await wallet.importOldWallet(cli.id, oldPassword: oldPassword);
    expect(r.proof.every((p) => p.ok), isTrue);
    expect(await folderHash(home), before);
    expect(await wallet.unlock(oldPassword), isTrue);
    expect((await wallet.revealPhrase(oldPassword)).join(' '), phrase, reason: 'same wallet as epic-wallet made');
    await wallet.lock();
    // R15: the core's fingerprint of the imported wallet is the phrase's, so a restore of the
    // phrase finds this wallet instead of making a second one.
    final fp = LepicWalletService(secrets: secrets, oneWalletPerChain: true).walletFingerprint(mnemonic: phrase, chain: core.Chain.mainnet);
    expect((await wallet.registry()).byId(r.id)!.walletFingerprint, fp);
    expect((await wallet.walletWithPhrase(phrase.split(' ')))?.id, r.id);
    // Wrong-password and short-password refusals of LEPIC itself.
    await expectLater(
      LepicWalletService(secrets: secrets, oneWalletPerChain: true).importWalletSeed(
        config: core.WalletConfig(dataDir: '${tmp.path}/x/mainnet', chain: core.Chain.mainnet, nodeUrl: 'http://127.0.0.1:9', epicboxDomain: 'example.invalid', epicboxPort: 443),
        seedFile: await seed.readAsString(),
        seedPassword: oldPassword,
        password: 'short',
      ),
      throwsA(isA<core.WalletError>().having((e) => e.kind, 'kind', core.WalletErrorKind.invalidArgument)),
    );
  }, skip: _lib == null || _bin == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_IMPORT_LIVE_BIN' : false, timeout: const Timeout(Duration(minutes: 4)));
}
