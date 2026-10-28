// Settings › This wallet › Change password. The adapter over the fake core (the new
// password opens, the old one not; Remember forgotten; each core error worded), and the dialog
// (validation, Enter rules, a wrong current password on its field, the toast).
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/password_estimate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _next = 'new-pass-5678';

/// A session whose password change fails with [error].
class _Failing extends core.FakeWalletSession {
  core.WalletError? error;

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final e = error;
    if (e != null) throw e;
    return super.changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}

/// The mock, counting the password changes.
class _Mock extends MockDeskWallet {
  _Mock() : super(delay: Duration.zero);

  final List<(String, String)> passwordChanges = [];

  @override
  Future<void> changePassword(String current, String next) {
    passwordChanges.add((current, next));
    return super.changePassword(current, next);
  }
}

void main() {
  group('LepicDeskWallet', () {
    late Directory support;
    late _Failing session;
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;
    late String id;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-change-password-test-');
      session = _Failing();
      service = core.FakeWalletService(password: _password, session: session);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final d = Directory('${support.path}/wallets/${chain.name}');
          await d.create(recursive: true);
          return d.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        rememberDir: () async => Directory('${support.path}/remember'),
      );
      await wallet.createWallet(name: 'Main', password: _password);
      id = (await wallet.wallets()).single.id;
      expect(await wallet.unlock(_password, remember: true), isTrue);
    });

    tearDown(() async {
      wallet.dispose();
      await support.delete(recursive: true);
    });

    test('the new password opens the wallet, the old one not; Remember is forgotten', () async {
      expect(await wallet.isRemembered(id), isTrue);
      await wallet.changePassword(_password, _next);
      expect(session.passwordChanges.single, (current: _password, next: _next));
      expect(await wallet.isRemembered(id), isFalse);
      await wallet.lock();
      expect(await wallet.unlockRemembered(), isFalse);
      expect(await wallet.unlock(_password), isFalse);
      expect(await wallet.unlock(_next), isTrue);
    });

    test('a wrong current password: wrongPassword, nothing changed, still remembered', () async {
      await expectLater(
        wallet.changePassword('not-the-password', _next),
        throwsA(isA<DeskError>().having((e) => e.wrongPassword, 'wrongPassword', isTrue)),
      );
      expect(session.passwordChanges, isEmpty);
      expect(await wallet.isRemembered(id), isTrue);
    });

    test('a short new password is refused before the core', () async {
      await expectLater(
        wallet.changePassword(_password, 'short'),
        throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Use at least 8 characters')),
      );
      expect(session.passwordChanges, isEmpty);
    });

    test('each core error, worded; Remember kept', () async {
      const kept = 'Password not changed. The current password still opens the wallet.';
      final cases = {
        core.WalletErrorKind.wrongPassword: 'Wrong password',
        core.WalletErrorKind.invalidArgument: 'Use at least 8 characters',
        core.WalletErrorKind.walletBusy: 'Wallet busy. Try again in a moment.',
        core.WalletErrorKind.chainBusy: 'Wallet busy. Try again in a moment.',
        // LEPIC's secretStore (the key store failed) arrives as io; locked and unsupported as other.
        core.WalletErrorKind.io: kept,
        core.WalletErrorKind.other: kept,
      };
      for (final MapEntry(key: kind, value: text) in cases.entries) {
        session.error = core.WalletError(kind: kind, message: 'detail');
        await expectLater(
          wallet.changePassword(_password, _next),
          throwsA(
            isA<DeskError>()
                .having((e) => e.message, 'message', text)
                .having((e) => e.wrongPassword, 'wrongPassword', kind == core.WalletErrorKind.wrongPassword),
          ),
          reason: kind.name,
        );
      }
      expect(await wallet.isRemembered(id), isTrue);
    });

    test('a locked wallet: refused', () async {
      await wallet.lock();
      await expectLater(wallet.changePassword(_password, _next), throwsA(isA<DeskError>()));
    });
  });

  group('dialog', () {
    late _Mock mock;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mock = _Mock();
      final container = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(mock),
          passwordEstimatorProvider.overrideWith((ref) async => PasswordEstimator(const {})),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.runAsync(() => mock.unlock('right password', remember: true));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(
              body: Builder(builder: (c) => TextButton(onPressed: () => showChangePasswordDialog(c), child: const Text('open'))),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    Future<void> end(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }

    Finder field(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText)).first;

    bool focused(WidgetTester tester, String label) => tester.widget<EditableText>(field(label)).focusNode.hasFocus;

    Future<void> type(WidgetTester tester, String label, String text) async {
      await tester.enterText(field(label), text);
      await tester.pump();
    }

    Future<void> enter(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
    }

    EButton mainButton(WidgetTester tester) => tester.widget<EButton>(find.widgetWithText(EButton, 'Change password').last);

    testWidgets('Enter moves Current → New → Repeat; from Repeat it changes only when valid', (tester) async {
      await open(tester);
      expect(focused(tester, 'Current password'), isTrue);
      expect(mainButton(tester).onPressed, isNull);
      await type(tester, 'Current password', 'right password');
      await enter(tester);
      expect(focused(tester, 'New password'), isTrue);
      await type(tester, 'New password', _next);
      await enter(tester);
      expect(focused(tester, 'Repeat new password'), isTrue);
      await type(tester, 'Repeat new password', '${_next}x');
      expect(find.text('Passwords differ'), findsOneWidget);
      await enter(tester);
      expect(mock.passwordChanges, isEmpty, reason: 'not valid: Enter does nothing');
      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      await type(tester, 'Repeat new password', _next);
      expect(mainButton(tester).onPressed, isNotNull);
      await enter(tester);
      expect(mock.passwordChanges, [('right password', _next)]);
      expect(find.byType(ChangePasswordDialog), findsNothing);
      expect(find.text('Password changed.'), findsOneWidget);
      expect(await tester.runAsync(() => mock.isRemembered('')), isFalse, reason: 'forgotten on a change');
      await end(tester);
    });

    testWidgets('a short new password says so and blocks the change', (tester) async {
      await open(tester);
      await type(tester, 'Current password', 'right password');
      await type(tester, 'New password', 'short');
      await type(tester, 'Repeat new password', 'short');
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(mainButton(tester).onPressed, isNull);
      await enter(tester);
      expect(mock.passwordChanges, isEmpty);
      await end(tester);
    });

    testWidgets('a wrong current password: an error on its field, no toast, the dialog stays', (tester) async {
      await open(tester);
      await type(tester, 'Current password', 'wrong');
      await type(tester, 'New password', _next);
      await type(tester, 'Repeat new password', _next);
      await tester.tap(find.widgetWithText(EButton, 'Change password').last);
      await settle(tester);
      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.descendant(of: find.widgetWithText(EField, 'Current password'), matching: find.text('Wrong password')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(await tester.runAsync(() => mock.isRemembered('')), isTrue);
      // Typing again clears it.
      await type(tester, 'Current password', 'right password');
      expect(find.text('Wrong password'), findsNothing);
      await end(tester);
    });
  });
}
