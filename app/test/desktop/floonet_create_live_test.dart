// Live: LNX-6 on the real LEPIC core through LepicDeskWallet. Welcome's Floonet choice makes a
// floonet wallet: its folder, its Epicbox address (floonet key, flooepicbox) and, after a fresh
// start over the same store, the floonet list again. Temp folders, unreachable node. Needs the
// Linux library:
//
//   WFE_DEMO_LEPIC_LIB=<path to liblepic_ffi.so> flutter test test/desktop/floonet_create_live_test.dart
//
// Without it it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

const _password = 'floonet-live-pass-1';

void main() {
  late Directory tmp;
  late MemorySecretStore secrets;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-floonet-live-');
    secrets = MemorySecretStore({'app.node.floonet': 'http://127.0.0.1:9', 'app.node.mainnet': 'http://127.0.0.1:9'});
  });

  tearDown(() => tmp.delete(recursive: true));

  LepicDeskWallet app(NetworkPreset preset) => LepicDeskWallet(
    preset: preset,
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

  test('Floonet on Welcome makes a floonet wallet with a floonet Epicbox address', () async {
    final wallet = app(mainnetPreset);
    await wallet.useNetwork('floonet');
    await wallet.createWallet(name: 'Test', password: _password);
    expect((await wallet.wallets()).single.network, 'floonet');
    expect(Directory('${tmp.path}/support/wallets/floonet').listSync(), isNotEmpty);
    expect(await wallet.unlock(_password), isTrue);
    final address = await wallet.epicboxAddress();
    expect(address, endsWith('@${floonetPreset.epicboxDomain}'));
    expect(wallet.isEpicboxAddress(address), isTrue);
    await wallet.dispose();

    // A fresh start on the saved choice lists it again; mainnet has none.
    final again = app(await LepicDeskWallet.savedPreset(secrets));
    expect(again.network, 'floonet');
    expect((await again.wallets()).single.name, 'Test');
    await again.useNetwork('mainnet');
    expect(await again.wallets(), isEmpty);
    await again.dispose();
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false, timeout: const Timeout(Duration(minutes: 3)));
}
