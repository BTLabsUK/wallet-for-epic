// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_wallets_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/welcome_screen.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';

Widget _screen(DeskRoute r, Object? a) => switch (r) {
  DeskRoute.welcome => WelcomeScreen(arg: a),
  DeskRoute.create => CreateScreen(arg: a),
  DeskRoute.restore => RestoreScreen(arg: a),
  DeskRoute.setup => SetupScreen(arg: a),
  DeskRoute.unlock => UnlockScreen(arg: a),
  DeskRoute.importWallets => ImportWalletsScreen(arg: a),
  _ => throw ArgumentError(r),
};

/// Pumps [child] at desktop size; returns the provider container.
Future<ProviderContainer> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return container;
}

Finder _field(int i) => find.byType(EditableText).at(i);

/// Spinners never settle: steps time instead.
Future<void> _wait(WidgetTester tester, [int ms = 3000]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void flows() {
  testWidgets('unlock: fail stops at the wallet service with Back and Try again', (tester) async {
    await _pump(tester, const UnlockScreen());
    await tester.enterText(_field(0), 'fail');
    await tester.tap(find.text('Unlock').last);
    await _wait(tester);
    expect(find.text('Unlock failed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Unlock wallet'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('unlock: wrong password returns to the form with the message', (tester) async {
    await _pump(tester, const UnlockScreen());
    await tester.enterText(_field(0), 'wrong');
    await tester.tap(find.text('Unlock').last);
    await _wait(tester, 4000);
    expect(find.textContaining('Wrong password'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('restore: a pasted 12-word phrase sets the count and allows Continue', (tester) async {
    await _pump(tester, const RestoreScreen());
    final words = [...List.filled(11, 'abandon'), 'about'].join(' ');
    await tester.enterText(_field(0), words);
    await _wait(tester, 500);
    expect(find.text('12 of 12 words'), findsOneWidget);
    expect(find.text('All 12 words check out.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    expect(find.text('Name'), findsNothing);
    expect(find.byType(EditableText), findsNWidgets(2), reason: 'password and repeat; the name is the title, its field opens from the pen');
    await _end(tester);
  });

  testWidgets('restore: the title is the next free Wallet N; the pen edits it in place and the restored wallet takes the name', (tester) async {
    final container = await _pump(tester, const RestoreScreen());
    final words = [...List.filled(11, 'abandon'), 'about'].join(' ');
    await tester.enterText(_field(0), words);
    await _wait(tester, 500);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Wallet 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wallet-name-pen')));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-field')), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byKey(const ValueKey('wallet-name-field')), matching: find.byType(EditableText)), 'Savings');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-field')), findsNothing, reason: 'Enter saves and closes the field');
    expect(find.text('Savings'), findsOneWidget);
    await tester.enterText(_field(0), 'longpassword');
    await tester.enterText(_field(1), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Restore wallet').last);
    await _wait(tester, 4000);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.setup);
    expect((nav.arg as SetupFirstRun).added.name, 'Savings');
    await _end(tester);
  });

  testWidgets('restore: no Length field; 24 boxes always, a paste sets 12, 15 or 21', (tester) async {
    await _pump(tester, const RestoreScreen());
    expect(find.text('Length'), findsNothing);
    expect(find.byType(EditableText), findsNWidgets(24));
    for (final (n, last) in [(15, 'address'), (12, 'about'), (21, 'admit')]) {
      await tester.enterText(_field(0), [...List.filled(n - 1, 'abandon'), last].join(' '));
      await _wait(tester, 500);
      expect(find.text('$n of $n words'), findsOneWidget);
      expect(find.text('All $n words check out.'), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(24), reason: 'the grid never changes size');
    }
    // Thirteen words are not a phrase: the line says so.
    await tester.enterText(_field(0), List.filled(13, 'abandon').join(' '));
    await _wait(tester, 500);
    expect(find.text('13 words pasted; a phrase has 12, 15, 18, 21 or 24'), findsOneWidget);
    expect(find.text('13 of 24 words'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('import: find, choose, check, one old password per wallet, done opens Unlock', (tester) async {
    final container = await _pump(tester, const ImportWalletsScreen());
    await _wait(tester, 1500);
    expect(find.text('3 wallets found'), findsOneWidget, reason: 'a test network wallet is not offered');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Choose wallets'), findsOneWidget);
    expect(find.textContaining('Test network wallet'), findsNothing);
    expect(find.text('Same wallet as Everyday. Tick for a second copy.'), findsOneWidget);
    expect(find.text('2 of 3 selected'), findsOneWidget, reason: 'the copy starts unticked');
    await tester.tap(find.text('Continue'));
    await _wait(tester, 1500);
    // Nothing in use: Check goes straight on to Import.
    expect(find.text('Each wallet asks for its old password once.'), findsOneWidget);
    expect(find.text('0 of 2 imported'), findsOneWidget);
    await tester.enterText(_field(0), 'wrong-password');
    await tester.tap(find.text('Import').last);
    await _wait(tester, 1500);
    expect(find.text('Wrong old password'), findsOneWidget);
    await tester.enterText(_field(0), 'old-password');
    await tester.tap(find.text('Import').last);
    await _wait(tester, 1500);
    expect(find.text('1 of 2 imported'), findsOneWidget);
    expect(find.text('Old folder unchanged'), findsOneWidget);
    // A short old password asks for a new one.
    await tester.enterText(_field(0), 'abc');
    await tester.pump();
    expect(find.text('New password'), findsOneWidget);
    await tester.enterText(_field(1), 'new-password');
    await tester.enterText(_field(2), 'new-password');
    await tester.tap(find.text('Import').last);
    await _wait(tester, 1500);
    expect(find.text('2 of 2 imported'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Wallets imported'), findsOneWidget);
    expect(find.text('Unlock with the old password.'), findsOneWidget);
    expect(find.text('Unlock with the new password chosen here.'), findsOneWidget);
    expect(find.text('Keep epicbox.example.org'), findsOneWidget);
    await tester.tap(find.text('Open wallet'));
    await tester.pump();
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    final added = container.read(deskNavProvider).arg as UnlockAdded;
    expect(added.name, '2 wallets');
    expect(added.id, isNotNull, reason: 'the last wallet added is the one Unlock selects');
    final api = container.read(deskApiProvider);
    expect((await tester.runAsync(api.wallets))!.firstWhere((w) => w.current).id, added.id);
    await _end(tester);
  });

  testWidgets('import: Cancel after an import asks, then removes it', (tester) async {
    final container = await _pump(tester, const ImportWalletsScreen());
    await _wait(tester, 1500);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester, 1500);
    await tester.enterText(_field(0), 'old-password');
    await tester.tap(find.text('Import').last);
    await _wait(tester, 1500);
    final api = container.read(deskApiProvider);
    expect((await tester.runAsync(api.wallets))!.map((w) => w.id), contains('imp-sav'));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Stop the import?'), findsOneWidget);
    await tester.tap(find.text('Stop import'));
    await _wait(tester, 1000);
    expect((await tester.runAsync(api.wallets))!.map((w) => w.id), isNot(contains('imp-sav')));
    await _end(tester);
  });

  testWidgets('create: the name is the title, no name step, no quiz; Continue on the phrase goes to the first-run setup with the new wallet', (tester) async {
    final container = await _pump(tester, const CreateScreen());
    expect(find.text('Name'), findsNothing);
    expect(find.text('Wallet 1'), findsOneWidget, reason: 'the next free default name as the title');
    expect(find.byKey(const ValueKey('wallet-name-pen')), findsOneWidget);
    expect(find.byType(EditableText), findsNWidgets(2), reason: 'password and repeat only');
    await tester.enterText(_field(0), 'longpassword');
    await tester.enterText(_field(1), 'longpassword');
    await tester.pump();
    expect(find.text('Check phrase'), findsNothing);
    await tester.tap(find.text('Create wallet').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Creating the wallet'), findsOneWidget);
    await _wait(tester, 4000);
    expect(find.text('Recovery phrase'), findsWidgets);
    expect(find.text('Check phrase'), findsNothing);
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    await tester.tap(find.textContaining('I have written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester, 500);
    expect(find.text('Check the phrase'), findsNothing);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.setup);
    final added = (nav.arg as SetupFirstRun).added;
    expect(added.name, 'Wallet 1');
    expect(added.id, isNotNull);
    await _end(tester);
    expect(container.read(onbFlowProvider).network, 'mainnet');
  });

  testWidgets('create: a name typed into the title lands on the new wallet; Esc keeps the title, an empty field goes back to the default', (tester) async {
    final container = await _pump(tester, const CreateScreen());
    final field = find.descendant(of: find.byKey(const ValueKey('wallet-name-field')), matching: find.byType(EditableText));
    await tester.tap(find.byKey(const ValueKey('wallet-name-pen')));
    await tester.pump();
    await tester.enterText(field, 'Savings');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Wallet 1'), findsOneWidget, reason: 'Esc keeps the title');
    await tester.tap(find.byKey(const ValueKey('wallet-name-pen')));
    await tester.pump();
    await tester.enterText(field, 'Savings');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Savings'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wallet-name-pen')));
    await tester.pump();
    await tester.enterText(field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Wallet 1'), findsOneWidget, reason: 'an empty name is the default again');
    await tester.tap(find.byKey(const ValueKey('wallet-name-pen')));
    await tester.pump();
    await tester.enterText(field, 'Savings');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(_field(0), 'longpassword');
    await tester.enterText(_field(1), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Create wallet').last);
    await _wait(tester, 4000);
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    await tester.tap(find.textContaining('I have written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester, 500);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.setup);
    expect((nav.arg as SetupFirstRun).added.name, 'Savings');
    await _end(tester);
  });

  testWidgets('unlock: the added wallet is the one selected, not the one that was current', (tester) async {
    final container = await _pump(tester, const SizedBox());
    final api = container.read(deskApiProvider);
    await tester.runAsync(() => api.createWallet(password: 'longpassword'));
    await tester.runAsync(() => api.createWallet(password: 'longpassword'));
    final all = (await tester.runAsync(api.wallets))!;
    expect(all.map((w) => w.name), containsAll(['Wallet 1', 'Wallet 2']));
    final added = all.firstWhere((w) => w.name == 'Wallet 2');
    await tester.runAsync(() => api.selectWallet('legacy-mainnet'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: UnlockScreen(arg: UnlockAdded('Wallet 2', id: added.id)))),
      ),
    );
    await _wait(tester, 1000);
    expect((await tester.runAsync(api.wallets))!.firstWhere((w) => w.current).id, added.id);
    expect(find.text('New wallet added.'), findsOneWidget);
    expect(find.text('Wallet 2 added.'), findsNothing, reason: 'the notice names no wallet');
    await _end(tester);
  });
}

void main() {
  flows();
  test('Welcome\'s network reaches the wallet layer, and Welcome opens on the one in use (LNX-6)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onbFlowProvider.notifier).setNetwork('floonet');
    await Future<void>.delayed(Duration.zero);
    final api = container.read(deskApiProvider);
    expect(api.network, 'floonet');
    final again = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(again.dispose);
    expect(again.read(onbFlowProvider).network, 'floonet');
  });
  for (final size in const [Size(1280, 800), Size(1000, 700), Size(600, 800)]) {
    for (final shot in onboardingShots) {
      testWidgets('${shot.id} at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildDeskTheme(Brightness.dark),
              home: Scaffold(
                body: Builder(
                  builder: (context) => _screen(shot.route, shot.arg),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        if (shot.dialog != null) {
          final ctx = tester.element(find.byType(Scaffold).first);
          shot.dialog!(ctx);
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
