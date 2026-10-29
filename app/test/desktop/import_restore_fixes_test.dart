// SPDX-License-Identifier: Apache-2.0
// The import wizard's restore-review fixes on the mock wallet: the Epicbox server choice at
// Done, the password line, the Windows close-first line and the line for
// Stack Wallet and Epic Pay users.
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_wallets_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/welcome_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The in-use check gives no answer, as on Windows.
class _NoAnswer extends MockDeskWallet {
  _NoAnswer() : super(delay: const Duration(milliseconds: 10));

  @override
  Future<OldWalletUse> checkOldWallet(String id) async => OldWalletUse.unknown;
}

Future<MockDeskWallet> _pump(WidgetTester tester, Widget child, [MockDeskWallet? api]) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final mock = api ?? MockDeskWallet(delay: const Duration(milliseconds: 10));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deskApiProvider.overrideWithValue(mock)],
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await _wait(tester);
  return mock;
}

/// Spinners never settle: steps time instead.
Future<void> _wait(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('Done: the older Epicbox server is kept by default; Use the app\'s says the address changes', (tester) async {
    final api = await _pump(tester, const ImportWalletsScreen(arg: ImportStep.done));
    expect(find.text('Wallets imported'), findsOneWidget);
    expect(find.textContaining('Epicbox server for '), findsOneWidget, reason: 'only the wallet that used another server');
    expect(find.textContaining('The older app received through epicbox.example.org.'), findsOneWidget);
    expect(find.text('Unlock with the old password.'), findsWidgets);
    // Keep is chosen already: tapping it changes nothing.
    await tester.tap(find.text('Keep epicbox.example.org'));
    await _wait(tester);
    expect(api.relayChoices, isEmpty);
    expect(find.textContaining('payments to the old one do not arrive'), findsOneWidget);
    await tester.tap(find.text('Use ${hostSettings.epicboxUse}'));
    await _wait(tester);
    expect(api.relayChoices.single, endsWith(':false'));
    await tester.tap(find.text('Keep epicbox.example.org'));
    await _wait(tester);
    expect(api.relayChoices.last, endsWith(':true'));
    await _end(tester);
  });

  testWidgets('Check on Windows: no answer, so it asks to close the older app and waits for Continue', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await _pump(tester, const ImportWalletsScreen(), _NoAnswer());
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester);
    expect(find.text('Close the older Epic Wallet before importing. Whether it is still running cannot be checked on Windows.'), findsOneWidget);
    expect(find.text('Each wallet asks for its old password once.'), findsNothing, reason: 'stays on Check');
    await tester.tap(find.text('Continue'));
    await _wait(tester);
    expect(find.text('Each wallet asks for its old password once.'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    await _end(tester);
  });

  testWidgets('Check elsewhere: nothing in use goes straight on, no Windows line', (tester) async {
    await _pump(tester, const ImportWalletsScreen(), _NoAnswer());
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester);
    expect(find.textContaining('cannot be checked on Windows'), findsNothing);
    expect(find.text('Each wallet asks for its old password once.'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('Stack Wallet and Epic Pay: a line on Welcome and on No wallets found', (tester) async {
    const line = 'From Stack Wallet or Epic Pay: restore with the recovery phrase.';
    await _pump(tester, const WelcomeScreen());
    expect(find.text(line), findsOneWidget);
    await _pump(tester, const ImportWalletsScreen(arg: ImportStep.none));
    expect(find.text(line), findsOneWidget);
    await _end(tester);
  });
}
