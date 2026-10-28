// SPDX-License-Identifier: Apache-2.0
// Closing the app after a lock (LNX-4): the wallet's dispose never waits on its streams. The
// live test needs the Linux library and the network, and is skipped without them:
//
//   WFE_DEMO_LEPIC_LIB=.../liblepic_ffi.so flutter test test/desktop/lock_close_test.dart
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

void main() {
  late Directory tmp;
  late MemorySecretStore secrets;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-lock-close-live-');
    secrets = MemorySecretStore({'app.node.mainnet': 'https://node.btlabs.uk'});
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
    rememberDir: () async => Directory('${tmp.path}/support/remember'),
    listProcesses: () async => const [],
  );

  test('dispose ends while a listener is paused (Riverpod pauses an unwatched provider)', () async {
    final wallet = app();
    final notices = wallet.invoiceNotices().listen((_) {})..pause();
    final changes = wallet.changes().listen((_) {})..pause();
    addTearDown(notices.cancel);
    addTearDown(changes.cancel);
    await wallet.dispose().timeout(const Duration(seconds: 5));
  });

  test('live: lock, then close: dispose ends at once', () async {
    final wallet = app();
    await wallet.createWallet(name: 'Main', password: 'live-pass-123');
    expect(await wallet.unlock('live-pass-123'), isTrue);
    await Future<void>.delayed(const Duration(seconds: 4));
    final lockWatch = Stopwatch()..start();
    await wallet.lock();
    // ignore: avoid_print
    print('LOCK took ${lockWatch.elapsedMilliseconds} ms');
    await Future<void>.delayed(const Duration(seconds: 2));
    final watch = Stopwatch()..start();
    await wallet.dispose().timeout(const Duration(seconds: 60));
    // ignore: avoid_print
    print('DISPOSE took ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 3)));
}
