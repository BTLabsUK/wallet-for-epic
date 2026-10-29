// SPDX-License-Identifier: Apache-2.0
// The link code's wallet fingerprint over the real LEPIC library: two installs of one phrase
// on different Epicbox servers, one opened by password and one by PIN (desktop and phone), give
// the same fingerprint for a code; a wallet of another phrase gives another. Tester report
// (2026-10-28, "This code is from a different wallet."): the phone held a new wallet, not the
// phrase restored on the desktop. Skipped unless WFE_LEPIC_LIB (the Linux library built at the
// pins) is set; nothing goes to a node or a server.
import 'dart:io';

import 'package:epic_wallet/src/devices/device_link_code.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final String? _lib = Platform.environment['WFE_LEPIC_LIB'];

const _phrase = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _invite = 'epiccash://pair/1/AQABAQIAAQADAAEBBAAHRGVza3RvcA';

class _MemoryStore implements lepic.SecretStore, app.SecretStore {
  final _all = <String, String>{};

  @override
  Future<String?> read(String key) async => _all[key];

  @override
  Future<void> write(String key, String value) async => _all[key] = value;

  @override
  Future<void> delete(String key) async => _all.remove(key);
}

void main() {
  final skip = _lib == null ? 'needs WFE_LEPIC_LIB' : null;
  late lepic.LepicRuntime runtime;
  late Directory dir;

  setUpAll(() async {
    if (skip != null) return;
    await initLepic(libraryPath: _lib);
    runtime = lepic.LepicRuntime(logLevel: lepic.LogLevel.warn);
    dir = Directory.systemTemp.createTempSync('wfe-link-fp');
  });

  tearDownAll(() {
    if (skip == null) dir.deleteSync(recursive: true);
  });

  /// A mainnet wallet [name] on the Epicbox server [relay], from [mnemonic] (a new one when null).
  Future<LepicWalletSession> install(String name, String relay, {String? mnemonic, bool pin = false}) async {
    final config = lepic.WalletConfig(
      dataDir: (Directory('${dir.path}/$name')..createSync()).path,
      chain: lepic.Chain.mainnet,
      nodeUrl: 'https://node.btlabs.uk',
      epicboxDomain: relay,
      epicboxPort: 443,
      onionRoutes: const [],
    );
    final store = lepic.lepicSecretStore(_MemoryStore());
    final wallet = pin
        ? (await lepic.EpicWallet.createWithPin(runtime: runtime, config: config, store: store, mnemonic: mnemonic, pin: '482913')).wallet
        : await lepic.EpicWallet.create(runtime: runtime, config: config, store: store, mnemonic: mnemonic, password: 'link-fingerprint-2610');
    return LepicWalletSession(wallet);
  }

  Future<String> fingerprint(LepicWalletSession s) async =>
      deviceLinkFingerprint(await SessionDeviceHost(s).signProof(deviceLinkFingerprintMessage(_invite)));

  test('one phrase gives one fingerprint on any Epicbox server; another wallet another', skip: skip, () async {
    final desktop = await install('desktop', 'epicbox.epicnet.us', mnemonic: _phrase);
    final phone = await install('phone', 'epicbox.stackwallet.com', mnemonic: _phrase, pin: true);
    final other = await install('other', 'epicbox.stackwallet.com', pin: true);
    expect(await desktop.epicboxAddress(), isNot(await phone.epicboxAddress()));
    expect(await fingerprint(phone), await fingerprint(desktop));
    expect(await fingerprint(other), isNot(await fingerprint(desktop)));
    for (final s in [desktop, phone, other]) {
      s.dispose();
    }
  });
}
