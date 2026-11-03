// SPDX-License-Identifier: Apache-2.0
// The optional passphrase in place of the PIN (WAL-03): the screens of a wallet that uses one,
// and the proof that a PIN wallet's screens still read as before.
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_pin.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _mainnetDir = '/fake/wallets/mainnet';
const _pin = '123456';
const _passphrase = 'correct horse battery';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  _Harness({bool passphrase = false, bool everUsed = false}) {
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(passphrase ? _passphrase : _pin);
    store.values['wallet.mainnet.backedUp'] = '1';
    if (passphrase) store.values['wallet.mainnet.pinPassphrase'] = '1';
    if (passphrase || everUsed) store.values['wallet.mainnet.pinPassphraseEver'] = '1';
    service = FakeWalletService(existingWallets: {_mainnetDir}, session: session);
  }

  final store = MemorySecretStore();
  final bio = MemoryBiometricStore(available: false);
  final session = FakeWalletSession();
  late final FakeWalletService service;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          walletDirProvider.overrideWithValue((chain) async => '/fake/wallets/${chain.name}'),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(bio),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> openSecurity(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(section: SettingsSection.security),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String label, String text) async {
  await _enter(tester, label, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  group('a PIN wallet', () {
    testWidgets('sees the PIN screens as before, with no passphrase switch', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text(_l.unlockTitle), findsOneWidget);
      expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
      expect(find.text(_l.pinForgot), findsOneWidget);
      expect(find.text('Use passphrase instead'), findsNothing);
      expect(find.byIcon(Icons.visibility), findsNothing);
      await _enter(tester, 'PIN', _pin);
      expect(h.container.read(sessionProvider), isNotNull);

      await h.openSecurity(tester);
      expect(find.text(_l.settingsUsePassphrase), findsOneWidget);
      await _tapText(tester, 'Change PIN');
      expect(find.text('Enter your current PIN'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Current PIN'), findsOneWidget);
    });

    testWidgets('sets a passphrase: rules, crack-time hint, mismatch, then the notice', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'PIN', _pin);
      await h.openSecurity(tester);
      await _tapText(tester, _l.settingsUsePassphrase);
      await _enter(tester, _l.settingsPinCurrentLabel, _pin);

      expect(find.text(_l.passphraseChooseTitle), findsOneWidget);
      expect(find.textContaining('At least 10 characters and not only digits'), findsOneWidget);
      // Two fields, each with its show/hide eye.
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));

      // Too short: said under the first field, nothing saved.
      await _enter(tester, 'Passphrase', 'short');
      // The hint informs: the count, the estimated time to crack, and an info icon that opens
      // the explanation. No meter, no verdict.
      expect(find.textContaining('5 characters'), findsOneWidget);
      // The word lists load and rank off the UI thread (real async) before the time shows.
      for (var i = 0; i < 40 && find.textContaining('to crack').evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.textContaining('to crack'), findsOneWidget);
      for (final verdict in ['Weak', 'Fair', 'Strong']) {
        expect(find.text(verdict), findsNothing);
      }
      await tester.tap(find.byKey(const ValueKey('passphrase-hint-info')));
      await tester.pumpAndSettle();
      expect(find.textContaining('A guide, not a guarantee.'), findsOneWidget);
      await _tapText(tester, 'Close');
      expect(find.textContaining('A guide, not a guarantee.'), findsNothing);
      await _tapText(tester, 'Save');
      expect(find.textContaining('at least 10 characters'), findsOneWidget);
      expect(find.byType(ChangePinScreen), findsOneWidget);

      // Only digits is refused too, however long.
      await _enter(tester, 'Passphrase', '12345678901234');
      await _tapText(tester, 'Save');
      expect(find.textContaining('at least 10 characters'), findsOneWidget);

      // A mismatch is said under the second field.
      await _enter(tester, 'Passphrase', _passphrase);
      await _enter(tester, 'Repeat the passphrase', 'correct horse');
      await _tapText(tester, 'Save');
      expect(find.text('The two passphrases differ'), findsOneWidget);
      expect(find.textContaining('at least 10 characters'), findsNothing);

      await _submit(tester, 'Repeat the passphrase', _passphrase);
      expect(find.byType(ChangePinScreen), findsNothing);
      expect(
        find.descendant(of: find.byKey(noticeKey), matching: find.text('Passphrase set')),
        findsOneWidget,
      );
      expect(h.store.values['wallet.mainnet.pinSealed'], fakeSealedPassword(_passphrase));
      expect(h.store.values['wallet.mainnet.pinPassphrase'], '1');
      expect(h.store.values['wallet.mainnet.pinPassphraseEver'], '1');
      expect(find.text('Change passphrase'), findsOneWidget);
    });
  });

  group('a passphrase wallet', () {
    testWidgets('unlocks with a text field, Forgot passphrase and the eye', (tester) async {
      final h = _Harness(passphrase: true);
      await h.pump(tester);
      expect(find.text(_l.unlockTitle), findsOneWidget);
      expect(find.widgetWithText(TextField, _l.passphraseLabel), findsOneWidget);
      expect(find.widgetWithText(TextField, 'PIN'), findsNothing);
      expect(find.text(_l.passphraseForgot), findsOneWidget);
      expect(find.text('Forgot PIN?'), findsNothing);
      expect(find.text('Use PIN instead'), findsOneWidget);

      // The eye shows the text; the arrow submits it.
      await _enter(tester, 'Passphrase', 'wrong one here');
      expect(tester.widget<EditableText>(find.byType(EditableText).first).obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(find.byType(EditableText).first).obscureText, isFalse);
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.textContaining('Wrong PIN'), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);

      await _submit(tester, 'Passphrase', _passphrase);
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('the PIN dialog and the change screen ask for the passphrase', (tester) async {
      final h = _Harness(passphrase: true);
      await h.pump(tester);
      await _submit(tester, _l.passphraseLabel, _passphrase);
      await h.openSecurity(tester);

      await _tapText(tester, _l.settingsBackupPhrase);
      await _tapText(tester, _l.backupCopyAgree);
      await tester.tap(find.text('Show recovery phrase'));
      // The PIN dialog never settles (wallet_flow_test pumps frames too).
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Enter your passphrase'), findsOneWidget);
      expect(find.text('Enter your PIN'), findsNothing);
      expect(find.widgetWithText(TextField, 'Passphrase'), findsOneWidget);
      expect(find.text('Enter your passphrase to show the recovery phrase.'), findsOneWidget);
      // Cancel stays one tap.
      await _tapText(tester, 'Cancel');
      expect(find.text('Enter your passphrase'), findsNothing);
      // Cancelled, the backup screen leaves by itself.

      await _tapText(tester, 'Change passphrase');
      expect(find.text('Enter your current passphrase'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Current passphrase'), findsOneWidget);
    });
  });

  group('when the stored mode and the secret disagree', () {
    testWidgets('a wallet that ever had a passphrase can switch to it', (tester) async {
      // The app stopped between the new sealed text (a passphrase) and the recorded mode.
      final h = _Harness(everUsed: true);
      h.store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_passphrase);
      await h.pump(tester);
      expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
      await _tapText(tester, _l.passphraseUsePassphraseInstead);
      expect(find.widgetWithText(TextField, _l.passphraseLabel), findsOneWidget);
      expect(find.text(_l.passphraseForgot), findsOneWidget);
      expect(find.text('Use PIN instead'), findsOneWidget);
      await _submit(tester, 'Passphrase', _passphrase);
      expect(h.container.read(sessionProvider), isNotNull);
    });
  });
}
