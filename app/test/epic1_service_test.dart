// SPDX-License-Identifier: Apache-2.0
// The epic1 service layer on the fakes: the sealed-file naming and recognition of
// `BEGINEPICTX.` text, and the restore drain, which follows the epic1 switch of the payment
// settings.

import 'dart:convert';

import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart' show isSealedLepicText;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/restore_scan.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('restore with epic1 on', () {
    ProviderContainer container({PaymentPrefs? payments}) {
      final store = MemorySecretStore();
      if (payments != null) store.values['app.payment_prefs'] = payments.encode();
      final c = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(store)]);
      c.listen(restoreScanProvider, (_, _) {});
      return c;
    }

    test('drains the link mailboxes once after the restore scan', () async {
      final c = container();
      addTearDown(c.dispose);
      final session = FakeWalletSession()
        ..restoreScanPending = true
        ..epic1Fake = FakeEpic1();
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(session.restoreScanPending, isFalse);
      expect(session.epic1Fake.calls.where((n) => n == 'restore'), hasLength(1));

      // Later checks of the flag drain nothing more.
      await c.read(restoreScanProvider.notifier).check();
      expect(session.epic1Fake.calls.where((n) => n == 'restore'), hasLength(1));
    });

    test('epic1 off in the payment settings drains nothing', () async {
      final c = container(payments: const PaymentPrefs(epic1: false));
      addTearDown(c.dispose);
      await c.read(appSettingsProvider.future);
      final session = FakeWalletSession()..restoreScanPending = true;
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(c.read(epic1OnProvider), isFalse);
      expect(session.restoreScanPending, isFalse);
      expect(session.epic1Fake.calls, isNot(contains('restore')));
    });

    test('a wallet whose settings never held the switch drains: it reads as on', () async {
      final c = container(payments: PaymentPrefs.decode('v2,file,noqr|epicbox'));
      addTearDown(c.dispose);
      await c.read(appSettingsProvider.future);
      final session = FakeWalletSession()..restoreScanPending = true;
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(c.read(epic1OnProvider), isTrue);
      expect(session.epic1Fake.calls.where((n) => n == 'restore'), hasLength(1));
    });

    test('a failed drain does not fail the unlock', () async {
      final c = container();
      addTearDown(c.dispose);
      final session = FakeWalletSession()
        ..restoreScanPending = true
        ..epic1Fake = (FakeEpic1()..failNext = const WalletError(kind: WalletErrorKind.transportFailed, message: 'down'));
      c.read(sessionProvider.notifier).unlocked(session);
      await pumpEventQueue();

      expect(c.read(restoreScanProvider).required, isFalse);
    });
  });
}
