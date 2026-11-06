// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/finalize_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/import_tx_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';

Widget _screen(DeskRoute r, Object? a) => switch (r) {
  DeskRoute.send => SendScreen(arg: a),
  DeskRoute.receive => ReceiveScreen(arg: a),
  DeskRoute.importTx => ImportTxScreen(arg: a),
  _ => FinalizeScreen(arg: a),
};

void main() {
  for (final size in const [Size(1280, 800), Size(1000, 700), Size(560, 800)]) {
    for (final shot in transferShots) {
      testWidgets('${shot.id} at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildDeskTheme(Brightness.dark),
              home: Scaffold(body: _screen(shot.route, shot.arg)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        if (shot.dialog != null) {
          final ctx = tester.element(find.byType(Scaffold));
          shot.dialog!(ctx);
          await tester.pump(const Duration(milliseconds: 600));
        }
        expect(tester.takeException(), isNull);
        // Let the mock's delayed answers (listener start/stop) finish before the test ends.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }
}
