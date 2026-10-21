/// Proves the wallet core runs without Flutter, as the demo server runs it.
///
/// From `app/`, with Flutter's `dart`, after `tools/lepic.sh build linux`:
///
///     dart run bin/core_check.dart [path/to/liblepic_ffi.so]
///
/// It loads the Linux LEPIC library, creates a floonet wallet with a PIN in a temp directory
/// through [LepicWalletService], reads its epicbox address, deletes the wallet, checks that a
/// wallet still opens after its data directory moves, and prints `ok`.
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
    await check(library, '${dir.path}/plain');
    await checkMovedDirectory('${dir.path}/moved');
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

/// A wallet created before its store keys were pinned (keys named after the directory), then
/// pinned on first use, and one created pinned, both open after their directory moves. The
/// path-named entries are never removed.
Future<void> checkMovedDirectory(String root) async {
  WalletConfig at(String dir) => WalletConfig(
    dataDir: Directory(dir).absolute.path,
    chain: Chain.floonet,
    nodeUrl: floonetPreset.nodeUrl,
    epicboxDomain: floonetPreset.epicboxDomain,
    epicboxPort: floonetPreset.epicboxPort,
  );
  Future<void> openAt(
    LepicWalletService service,
    WalletConfig config,
    PinWallet created,
  ) async {
    if (!await service.walletExists(config: config)) {
      throw StateError('the wallet is not found at ${config.dataDir}');
    }
    final session = await service.openWithPin(
      config: config,
      pin: '123456',
      sealedPassword: created.sealedPassword,
    );
    session.dispose();
  }

  // Created by an app that keyed the store by the directory.
  final store = MemorySecretStore();
  final first = at('$root/a');
  Directory(first.dataDir).createSync(recursive: true);
  final created = await LepicWalletService(secrets: store)
      .createWithPin(config: first, pin: '123456');
  created.session.dispose();
  final pathKeys = Map.of(store.values);
  if (!pathKeys.keys.every(
    (k) => k.startsWith('lepic:floonet:${first.dataDir}:'),
  )) {
    throw StateError('unexpected store keys before pinning');
  }

  // The app now pins the keys on first use, then the directory moves.
  var app = LepicWalletService(secrets: store, oneWalletPerChain: true);
  await openAt(app, first, created);
  final moved = at('$root/b');
  Directory(first.dataDir).renameSync(moved.dataDir);
  app = LepicWalletService(secrets: store, oneWalletPerChain: true);
  await openAt(app, moved, created);
  for (final e in pathKeys.entries) {
    if (store.values[e.key] == null) {
      throw StateError('a store entry named after the old directory is gone');
    }
  }
  await app.deleteWallet(config: moved);

  // A wallet created pinned gets keys that name no directory.
  final fresh = MemorySecretStore();
  final c = at('$root/c');
  Directory(c.dataDir).createSync(recursive: true);
  app = LepicWalletService(secrets: fresh, oneWalletPerChain: true);
  final made = await app.createWithPin(config: c, pin: '123456');
  made.session.dispose();
  if (fresh.values.keys.any((k) => k.contains(root))) {
    throw StateError('a pinned wallet still names its directory in the store');
  }
  final d = at('$root/d');
  Directory(c.dataDir).renameSync(d.dataDir);
  app = LepicWalletService(secrets: fresh, oneWalletPerChain: true);
  await openAt(app, d, made);
  await app.deleteWallet(config: d);
}
