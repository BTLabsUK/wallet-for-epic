// SPDX-License-Identifier: Apache-2.0
// The epic1 service layer on the fakes: the switch kept per wallet across lock and unlock, the
// sealed-file naming and recognition of `BEGINEPICTX.` text, and the restore drain in epic1 mode.

import 'dart:convert';

import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart' show isSealedLepicText;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/restore_scan.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WalletConfig _config(String dir) => WalletConfig(
  dataDir: dir,
  chain: Chain.mainnet,
  nodeUrl: 'https://node.example.invalid',
  epicboxDomain: 'relay.example.invalid',
  epicboxPort: 443,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the switch per wallet', () {
    test('on, lock, unlock: stored and in use; off again likewise', () async {
      final service = FakeWalletService(existingWallets: {'w1'});
      final config = _config('w1');

      var session = await service.open(config: config, password: 'correct horse');
      expect(session.epic1!.storedOn, isFalse);
      expect(session.epic1!.inUse, isFalse);

      await session.epic1!.setStoredOn(true);
      // Applies at the next unlock.
      expect(session.epic1!.storedOn, isTrue);
      expect(session.epic1!.inUse, isFalse);
      expect(session.paymentMode, PaymentMode.classic);

      session.dispose();
      session = await service.open(config: config, password: 'correct horse');
      expect(session.epic1!.storedOn, isTrue);
      expect(session.epic1!.inUse, isTrue);
      expect(session.paymentMode, PaymentMode.epic1);

      await session.epic1!.setStoredOn(false);
      expect(session.epic1!.inUse, isTrue);
      session.dispose();
      session = await service.open(config: config, password: 'correct horse');
      expect(session.epic1!.storedOn, isFalse);
      expect(session.epic1!.inUse, isFalse);
      expect(session.paymentMode, PaymentMode.classic);
    });

    test('the PIN unlock keeps it too', () async {
      final service = FakeWalletService(existingWallets: {'w1'});
      final config = _config('w1');
      var session = await service.open(config: config, password: 'correct horse');
      await session.epic1!.setStoredOn(true);
      session.dispose();

      final sealed = fakeSealedPassword('123456');
      session = await service.openWithPin(config: config, pin: '123456', sealedPassword: sealed);
      expect(session.epic1!.inUse, isTrue);
    });

    test('each wallet keeps its own setting', () async {
      final service = FakeWalletService(existingWallets: {'w1', 'w2'});
      var session = await service.open(config: _config('w1'), password: 'correct horse');
      await session.epic1!.setStoredOn(true);
      session.dispose();

      session = await service.open(config: _config('w2'), password: 'correct horse');
      expect(session.epic1!.storedOn, isFalse);
      expect(session.epic1!.inUse, isFalse);
      session.dispose();

      session = await service.open(config: _config('w1'), password: 'correct horse');
      expect(session.epic1!.inUse, isTrue);
    });

    test('a new wallet starts with it off', () async {
      final service = FakeWalletService();
      final session = await service.create(config: _config('fresh'), password: 'correct horse');
      expect(session.epic1!.storedOn, isFalse);
      expect(session.epic1!.inUse, isFalse);
    });
  });

  group('sealed files', () {
    const uuid = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';

    tearDown(() => sealedExtensionHook = null);

    test('isSealedText and isSealedLepicText accept both armor lines', () {
      for (final check in [isSealedText, isSealedLepicText]) {
        expect(check('BEGINEPICSEALED. abc'), isTrue);
        expect(check('  \nBEGINEPICTX. abc'), isTrue);
        expect(check('{"version_info":{}}'), isFalse);
        expect(check('BEGINEPICTXT abc'), isFalse);
      }
    });

    test('a native slate is saved as .epictx, any other as .epicsealed', () {
      expect(sealedFileName(uuid, text: 'BEGINEPICTX. abc. ENDEPICTX.'), '0a1b2c3d.epictx');
      expect(sealedFileName(uuid, text: 'BEGINEPICSEALED. abc. ENDEPICSEALED.'), '0a1b2c3d.epicsealed');
      expect(sealedFileName(uuid), '0a1b2c3d.epicsealed');
    });

    test('LEPIC answers for the extension when it is wired', () {
      sealedExtensionHook = (_) => 'epictx';
      expect(sealedFileName(uuid, text: 'anything'), '0a1b2c3d.epictx');
      // A text the core refuses falls back to the armor line.
      sealedExtensionHook = (_) => throw StateError('too large');
      expect(sealedFileName(uuid, text: 'BEGINEPICTX. x'), '0a1b2c3d.epictx');
    });

    test('a file of either armor is read as sealed', () {
      for (final head in ['BEGINEPICSEALED.', 'BEGINEPICTX.']) {
        expect(decodeSlateFile(utf8.encode('$head abc. END')), startsWith(head));
      }
    });
  });

  group('restore in epic1 mode', () {
    ProviderContainer container() {
      final c = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(MemorySecretStore())]);
      c.listen(restoreScanProvider, (_, _) {});
      return c;
    }

    test('drains the link mailboxes once after the restore scan', () async {
      final c = container();
      addTearDown(c.dispose);
      final session = FakeWalletSession()
        ..restoreScanPending = true
        ..epic1Fake = FakeEpic1(on: true);
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(session.restoreScanPending, isFalse);
      expect(session.epic1Fake.calls.where((n) => n == 'restore'), hasLength(1));

      // Later checks of the flag drain nothing more.
      await c.read(restoreScanProvider.notifier).check();
      expect(session.epic1Fake.calls.where((n) => n == 'restore'), hasLength(1));
    });

    test('classic mode drains nothing', () async {
      final c = container();
      addTearDown(c.dispose);
      final session = FakeWalletSession()..restoreScanPending = true;
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(session.restoreScanPending, isFalse);
      expect(session.epic1Fake.calls, isNot(contains('restore')));
    });

    test('a failed drain does not fail the unlock', () async {
      final c = container();
      addTearDown(c.dispose);
      final session = FakeWalletSession()
        ..restoreScanPending = true
        ..epic1Fake = (FakeEpic1(on: true)..failNext = const WalletError(kind: WalletErrorKind.transportFailed, message: 'down'));
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(c.read(restoreScanProvider).required, isFalse);
    });
  });
}
