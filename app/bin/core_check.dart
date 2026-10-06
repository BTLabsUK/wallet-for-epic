/// Proves the wallet core runs without Flutter, as the demo server runs it.
///
/// From `app/`, with Flutter's `dart`, after `tools/lepic.sh build linux`:
///
///     dart run bin/core_check.dart [path/to/liblepic_ffi.so]
///
/// It loads the Linux LEPIC library, creates a floonet wallet with a PIN in a temp directory
/// through [LepicWalletService], reads its epicbox address, deletes the wallet and prints `ok`.
/// Any failure prints `failed: <error>` and exits 1. A Flutter import anywhere on the path
/// fails the run before it starts, on `dart:ui`.
library;

import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/redact.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart';

const String defaultLibrary =
    'third_party/lepic/bindings/flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so';

Future<void> main(List<String> args) async {
  final library = args.isEmpty ? defaultLibrary : args.first;
  final dir = Directory.systemTemp.createTempSync('wfe-core-check-');
  try {
    await check(library, dir.path);
    stdout.writeln('ok');
  } catch (error) {
    stderr.writeln('failed: ${redact('$error')}');
    exitCode = 1;
  } finally {
    dir.deleteSync(recursive: true);
  }
  // LEPIC's runtime and log stream keep the isolate alive; the check is done.
  exit(exitCode);
}

Future<void> check(String library, String dataDir) async {
  if (!File(library).existsSync()) {
    throw StateError(
      'no LEPIC library at $library; run tools/lepic.sh build linux',
    );
  }
  await initLepic(libraryPath: library);
  final service = LepicWalletService(secrets: MemorySecretStore());
  final config = WalletConfig(
    dataDir: dataDir,
    chain: Chain.floonet,
    nodeUrl: floonetPreset.nodeUrl,
    epicboxDomain: floonetPreset.epicboxDomain,
    epicboxPort: floonetPreset.epicboxPort,
  );

  final created = await service.createWithPin(config: config, pin: '123456');
  final String address;
  try {
    address = await created.session.epicboxAddress();
  } finally {
    created.session.dispose();
  }
  if (!address.contains('@${floonetPreset.epicboxDomain}') ||
      !service.validateEpicboxAddress(address: address)) {
    throw StateError('the epicbox address is not a floonet address');
  }

  await service.deleteWallet(config: config);
  if (await service.walletExists(config: config)) {
    throw StateError('the wallet still exists after deleteWallet');
  }
}
