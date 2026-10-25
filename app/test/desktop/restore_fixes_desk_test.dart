// The desktop's restore and unlock fixes (restore map R4 R5 R6 R11 R13 R19 R23 R26 R37) over
// FakeWalletService, whose core here refuses what the real one refuses: a delete or a password
// reset of a wallet still open, and calls on a closed session.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/reset_password_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _other = 'legal winner thank year wave sausage worth useful legal winner thank yellow';

/// Two phrases are valid; a delete of an open wallet is refused, as LEPIC does.
class _Core extends core.FakeWalletService {
  _Core() : super(password: _password);

  /// When set, [create] writes the vault, then fails (R37).
  bool failCreate = false;

  /// When set, [resetPassword] fails with it and changes nothing.
  core.WalletError? resetError;

  @override
  Future<void> resetPassword({required core.WalletConfig config, required String mnemonic, required String newPassword}) async {
    final e = resetError;
    if (e != null) throw e;
    return super.resetPassword(config: config, mnemonic: mnemonic, newPassword: newPassword);
  }

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase || phrase == _other;

  @override
  Future<core.WalletSession> create({required core.WalletConfig config, String? mnemonic, required String password}) async {
    if (failCreate) {
      existingWallets.add(config.dataDir);
      throw const core.WalletError(kind: core.WalletErrorKind.io, message: 'database not written');
    }
    return super.create(config: config, mnemonic: mnemonic, password: password);
  }

  @override
  Future<void> deleteWallet({required core.WalletConfig config}) async {
    if (openWallets.contains(config.dataDir)) throw const core.WalletError(kind: core.WalletErrorKind.walletBusy, message: 'open');
    return super.deleteWallet(config: config);
  }
}

/// The mock, whose core cannot confirm any phrase for the wallet (no database it used).
class _Unverifiable extends MockDeskWallet {
  _Unverifiable() : super(delay: Duration.zero);

  final List<String> taken = [];

  @override
  Future<void> resetPassword(String id, {required List<String> phrase, required String newPassword}) async =>
      throw const DeskError('Nothing can confirm the phrase.', resetUnverifiable: true);

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    taken.add('$id:${mode.name}');
    return super.removeWallet(id, mode, password: password);
  }
}

/// A store whose writes of the wallet meta fail once [failMeta] is set (R11).
class _Store extends MemorySecretStore {
  bool failMeta = false;

  @override
  Future<void> write(String key, String value) async {
    if (failMeta && key.startsWith('desk.wallet.')) throw const FileSystemException('store refused');
    return super.write(key, value);
  }
}

void main() {
  group('LepicDeskWallet', () {
    late Directory support;
    late _Store secrets;
    late _Core service;
    late LepicDeskWallet wallet;

    LepicDeskWallet make() => LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final dir = Directory('${support.path}/wallets/${chain.name}');
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: secrets,
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
    );

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-restore-fixes-');
      secrets = _Store();
      service = _Core();
      wallet = make();
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    Future<Map<String, dynamic>> meta(String key) async => jsonDecode(await secrets.read(key) ?? '{}') as Map<String, dynamic>;

    test('R6: the scan-due note is written before the core makes the wallet', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      service.createGate = Completer<void>();
      final restoring = wallet.restoreWallet(name: 'Old', password: _password, phrase: _other.split(' '));
      String? key;
      for (var i = 0; i < 100 && key == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        key = secrets.values.keys.where((k) => k.startsWith('desk.wallet.mainnet.')).firstOrNull;
      }
      expect(key, isNotNull);
      expect(service.createGate!.isCompleted, isFalse, reason: 'the core is still making it');
      expect(await meta(key!), containsPair('scanPending', true), reason: 'an app closed now still scans at the next unlock');
      service.createGate!.complete();
      await restoring;
      expect(await meta(key), containsPair('name', 'Old'));
    });

    test('R37: a failed restore of the first wallet takes back what the core wrote, and its note', () async {
      service.failCreate = true;
      await expectLater(wallet.restoreWallet(password: _password, phrase: _other.split(' ')), throwsA(isA<DeskError>()));
      expect(service.deletedWallets, ['${support.path}/wallets/mainnet']);
      expect(await secrets.read('desk.wallet.mainnet'), isNull);
      expect(await wallet.wallets(), isEmpty);
    });

    test('R23: a restore takes the typed name', () async {
      await wallet.restoreWallet(name: 'Savings', password: _password, phrase: _other.split(' '));
      expect((await wallet.wallets()).single.name, 'Savings');
    });

    test('R26: a password is counted in characters, as the core counts', () async {
      expect(passwordLongEnough('😀😀😀😀'), isFalse, reason: 'four emoji: eight UTF-16 units, four characters');
      expect(passwordLongEnough('😀😀😀😀😀😀😀😀'), isTrue);
      await expectLater(wallet.createWallet(password: '😀😀😀😀'), throwsA(isA<DeskError>()));
      expect(service.createdConfig, isNull);
    });

    test('R19: Delete also removes WALLET.txt, the folder and the autostart choice', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      await wallet.createWallet(name: 'Savings', password: _password);
      final id = service.createdConfig!.walletId!;
      final dir = service.createdConfig!.dataDir;
      expect(File('$dir/WALLET.txt').existsSync(), isTrue);
      await wallet.selectWallet(id);
      expect(await wallet.unlock(_password), isTrue);
      await secrets.write('desk.autostart.$id', '{"epicbox":false,"tor":false}');
      await wallet.removeWallet(id, WalletRemoval.delete, password: _password);
      expect(Directory(dir).existsSync(), isFalse);
      expect(Directory(Directory(dir).parent.path).existsSync(), isFalse);
      expect(await secrets.read('desk.autostart.$id'), isNull);
    });

    test('R11: a Setup mark the store cannot clear is noted in the wallet folder, so Setup does not come back', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      final id = (await wallet.wallets()).single.id;
      await wallet.setSetupPending(id, true);
      secrets.failMeta = true;
      await wallet.setSetupPending(id, false);
      expect(File('${support.path}/wallets/mainnet/${LepicDeskWallet.setupDoneFileName}').existsSync(), isTrue);
      final again = make();
      addTearDown(again.dispose);
      expect(await again.setupPending(id), isFalse, reason: 'the next start goes to Unlock');
      secrets.failMeta = false;
      await again.setSetupPending(id, true);
      expect(await again.setupPending(id), isTrue, reason: 'a new mark takes the note away');
    });

    test('R13: a restored wallet offers the history import until it is answered; a created one never', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      expect((await wallet.historyBackupState()).importOffer, isFalse);
      await wallet.restoreWallet(name: 'Old', password: _password, phrase: _other.split(' '));
      await wallet.selectWallet((await wallet.wallets()).last.id);
      expect(await wallet.unlock(_password), isTrue);
      expect((await wallet.historyBackupState()).importOffer, isTrue);
      await wallet.dismissHistoryImportOffer();
      expect((await wallet.historyBackupState()).importOffer, isFalse);
    });

    group('R4: Forgot password', () {
      test('the wallet\'s own phrase sets a new password; an open wallet locks first; the remembered one is forgotten', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        final id = (await wallet.wallets()).single.id;
        expect(await wallet.unlock(_password, remember: true), isTrue);
        await wallet.resetPassword(id, phrase: service.phrase.split(' '), newPassword: 'brand-new-pass');
        expect(service.passwordResets, ['${support.path}/wallets/mainnet']);
        expect(await wallet.isRemembered(id), isFalse);
        expect(await wallet.unlock(_password), isFalse);
        expect(await wallet.unlock('brand-new-pass'), isTrue);
      });

      test('another wallet\'s phrase changes nothing and says so', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        final id = (await wallet.wallets()).single.id;
        await expectLater(
          wallet.resetPassword(id, phrase: _other.split(' '), newPassword: 'brand-new-pass'),
          throwsA(isA<DeskError>().having((e) => e.wrongPhrase, 'wrongPhrase', isTrue)),
        );
        expect(service.passwordResets, isEmpty);
        expect(await wallet.unlock(_password), isTrue);
      });

      test('a wallet the core cannot check the phrase against: nothing changes, the way out is a restore', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        final id = (await wallet.wallets()).single.id;
        service.resetError = const core.WalletError(kind: core.WalletErrorKind.walletNotFound, message: 'nothing to check');
        await expectLater(
          wallet.resetPassword(id, phrase: service.phrase.split(' '), newPassword: 'brand-new-pass'),
          throwsA(isA<DeskError>().having((e) => e.resetUnverifiable, 'resetUnverifiable', isTrue)),
        );
        expect(await wallet.unlock(_password), isTrue, reason: 'the old password still opens it');
      });

      test('the list fingerprint answers before the password step', () async {
        await wallet.restoreWallet(name: 'Old', password: _password, phrase: _other.split(' '));
        final id = (await wallet.wallets()).single.id;
        expect(await wallet.phraseIsOf(id, _other.split(' ')), isTrue);
        expect(await wallet.phraseIsOf(id, service.phrase.split(' ')), isFalse);
      });

      test('a short new password is refused before the core', () async {
        await wallet.createWallet(name: 'Main', password: _password);
        final id = (await wallet.wallets()).single.id;
        await expectLater(wallet.resetPassword(id, phrase: service.phrase.split(' '), newPassword: 'short'), throwsA(isA<DeskError>()));
        expect(service.passwordResets, isEmpty);
      });
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(WidgetTester tester, MockDeskWallet api, DeskRoute route, [Object? arg]) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      container.read(deskNavProvider.notifier).reset(route, arg);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
      await settle(tester);
      return container;
    }

    testWidgets('R4: a wallet whose files cannot confirm the phrase offers Restore from the phrase, which takes it off the list only', (tester) async {
      final api = _Unverifiable();
      final id = (await tester.runAsync(api.wallets))!.first.id;
      final container = await pump(tester, api, DeskRoute.resetPassword, ResetPasswordArg(id, phrase: 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'.split(' ')));
      final pw = find.byType(EditableText);
      await tester.enterText(pw.at(0), 'brand-new-pass');
      await tester.enterText(pw.at(1), 'brand-new-pass');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('reset-password-save')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      expect(find.text('Password not changed. The current password still opens the wallet.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reset-restore-instead')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      expect(api.taken, ['$id:list']);
      expect(container.read(deskNavProvider).route, DeskRoute.restore);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('R5: a mistyped password in Delete stays in the dialog; the wallet stays open', (tester) async {
      final container = await pump(tester, MockDeskWallet(delay: Duration.zero), DeskRoute.settingsAccount);
      showDeleteWalletDialog(tester.element(find.byType(EPage)));
      await settle(tester);
      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(EditableText)), 'wrong');
      await tester.tap(find.byType(ECheckbox));
      await settle(tester);
      await tester.tap(find.widgetWithText(EButton, 'Delete wallet'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      expect(container.read(deskProvider).account, isNotNull, reason: 'not locked by a typo');
      expect(find.text('Delete this wallet?'), findsOneWidget, reason: 'the dialog stays');
      expect(find.text('Wrong password'), findsOneWidget, reason: 'the error is under the field');
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAccount);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('R4: Unlock › Forgot password? › phrase › new password › Unlock with the notice', (tester) async {
      final api = MockDeskWallet(delay: Duration.zero);
      final container = await pump(tester, api, DeskRoute.unlock);
      await tester.tap(find.byKey(const ValueKey('unlock-forgot')));
      await settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.resetPassword);
      // Typed (no clipboard in tests).
      final words = 'abandon ' * 11;
      final fields = find.byType(EditableText);
      for (final (i, w) in '${words}about'.split(' ').indexed) {
        await tester.enterText(fields.at(i), w);
      }
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('reset-password-words')));
      await settle(tester);
      final pw = find.byType(EditableText);
      await tester.enterText(pw.at(0), 'brand-new-pass');
      await tester.enterText(pw.at(1), 'brand-new-pass');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('reset-password-save')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.unlock);
      expect(find.text('Password changed.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('R4: a phrase of another wallet stays on the phrase step with the reason', (tester) async {
      final api = MockDeskWallet(delay: Duration.zero);
      final id = (await tester.runAsync(api.wallets))!.first.id;
      final container = await pump(tester, api, DeskRoute.resetPassword, ResetPasswordArg(id, phrase: _other.split(' ')));
      final pw = find.byType(EditableText);
      await tester.enterText(pw.at(0), 'brand-new-pass');
      await tester.enterText(pw.at(1), 'brand-new-pass');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('reset-password-save')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.resetPassword);
      expect(find.text('This phrase belongs to another wallet. Nothing was changed.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  });
}

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
