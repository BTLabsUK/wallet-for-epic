import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/features.dart';
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

  testWidgets('unlock: busy opens the kill-process dialog, closing adds a stage', (tester) async {
    await _pump(tester, const UnlockScreen());
    await tester.enterText(_field(0), 'busy');
    await tester.tap(find.text('Unlock').last);
    await _wait(tester, 1000);
    expect(find.text('Epic is already running'), findsOneWidget);
    await tester.tap(find.text('Close and unlock'));
    await _wait(tester, 1200);
    expect(find.text('Epic is already running'), findsNothing);
    expect(find.textContaining('Closing the old wallet processes'), findsOneWidget);
    await _wait(tester, 5000);
    await _end(tester);
  }, skip: !DeskFeatures.walletProcesses);

  testWidgets('unlock: wrong password returns to the form with the message', (tester) async {
    await _pump(tester, const UnlockScreen());
    await tester.enterText(_field(0), 'wrong');
    await tester.tap(find.text('Unlock').last);
    await _wait(tester, 4000);
    expect(find.textContaining('Wrong password'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('restore: a pasted 12-word phrase sets the length and allows Continue', (tester) async {
    await _pump(tester, const RestoreScreen());
    final words = List.filled(12, 'abandon').join(' ');
    await tester.enterText(_field(0), words);
    await _wait(tester, 500);
    expect(find.text('12 of 12 words'), findsOneWidget);
    expect(find.text('All 12 words are in the word list'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Choose a password'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
    expect(find.byType(EditableText), findsNWidgets(2), reason: 'password and repeat only');
    await _end(tester);
  });

  testWidgets('import: find, choose, check, one old password per wallet, done opens Unlock', (tester) async {
    final container = await _pump(tester, const ImportWalletsScreen());
    await _wait(tester, 1500);
    expect(find.text('4 wallets found'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Choose wallets'), findsOneWidget);
    expect(find.textContaining('Only mainnet wallets can be imported'), findsOneWidget);
    expect(find.text('Same wallet as Everyday. Tick for a second copy.'), findsOneWidget);
    expect(find.text('2 of 4 selected'), findsOneWidget, reason: 'the floonet wallet and the copy start unticked');
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

  testWidgets('create: no name field, no quiz; Continue on the phrase goes to Unlock with the new wallet', (tester) async {
    final container = await _pump(tester, const CreateScreen());
    expect(find.text('Name'), findsNothing);
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
    await tester.tap(find.textContaining('Written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _wait(tester, 500);
    expect(find.text('Check the phrase'), findsNothing);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.unlock);
    final added = nav.arg as UnlockAdded;
    expect(added.name, 'Wallet 1');
    expect(added.id, isNotNull);
    await _end(tester);
    expect(container.read(onbFlowProvider).network, 'mainnet');
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
    expect(find.text('Wallet 2 added.'), findsOneWidget);
    await _end(tester);
  });
}

void main() {
  flows();
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
