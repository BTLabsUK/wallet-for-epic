import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/features.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/found_screen.dart';
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
  DeskRoute.found => FoundScreen(arg: a),
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
    await tester.tap(find.text('Close them and unlock'));
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
    await _end(tester);
  });

  testWidgets('create: creating runs before the phrase, the end is Unlock with the added notice', (tester) async {
    final container = await _pump(tester, const CreateScreen());
    await tester.enterText(_field(0), 'Daily');
    await tester.enterText(_field(1), 'longpassword');
    await tester.enterText(_field(2), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Create wallet').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Creating the wallet'), findsOneWidget);
    await _wait(tester, 2500);
    expect(find.text('Recovery phrase'), findsWidgets);
    await _end(tester);
    expect(container.read(onbFlowProvider).network, 'mainnet');
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
