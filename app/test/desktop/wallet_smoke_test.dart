import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart' show DeskTextScaler;
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart';

Widget _screen(DeskRoute r, Object? a) => switch (r) {
  DeskRoute.overview => OverviewScreen(arg: a),
  DeskRoute.activity => ActivityScreen(arg: a),
  _ => ContactsScreen(arg: a),
};

void main() {
  // The contact detail dates its pairing with the app's formatter; the app loads the data through its localizations.
  setUpAll(initializeDateFormatting);

  // Every state at desktop, narrow and phone width; narrow and phone again at 125 % and 150 %.
  const runs = [
    (Size(1280, 800), 1.0),
    (Size(1000, 700), 1.0),
    (Size(560, 800), 1.0),
    (Size(1000, 700), 1.25),
    (Size(560, 800), 1.25),
    (Size(1000, 700), 1.5),
    (Size(560, 800), 1.5),
  ];
  for (final (size, scale) in runs) {
    for (final shot in walletShots) {
      testWidgets('${shot.id} at ${size.width.toInt()} ${(scale * 100).round()}%', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        deskScale = scale * deskBase;
        addTearDown(() {
          tester.view.reset();
          deskScale = deskBase;
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        await tester.runAsync(() => container.read(deskOutputsProvider.future));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildDeskTheme(Brightness.dark),
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(data: mq.copyWith(textScaler: DeskTextScaler(mq.textScaler, deskScale)), child: child!);
              },
              home: Scaffold(body: _screen(shot.route, shot.arg)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        // What the shot adds to the mock first (a payment in its Cancel hold, …), as the tour does.
        if (shot.prepare != null) {
          await tester.runAsync(() => shot.prepare!(container, tester.element(find.byType(Scaffold))));
          await tester.pump(const Duration(milliseconds: 600));
        }
        if (shot.dialog != null) {
          final ctx = tester.element(find.byType(Scaffold));
          shot.dialog!(ctx);
          await tester.pump(const Duration(milliseconds: 600));
        }
        final error = tester.takeException();
        if (error is FlutterError) debugPrint(error.toStringDeep());
        expect(error, isNull);
        // Let mock timers (restart, toasts) finish before the test ends.
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}
