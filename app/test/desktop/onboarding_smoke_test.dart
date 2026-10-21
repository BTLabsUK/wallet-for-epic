import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/found_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_wallets_screen.dart';
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

void main() {
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
