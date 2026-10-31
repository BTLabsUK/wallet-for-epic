// SPDX-License-Identifier: Apache-2.0
// The PIN field stays in one place between "choose" and "repeat", in the first-run layout
// (button at the foot) and the inline one (Settings › Change PIN, Restore).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/centered_body.dart';
import 'package:epic_wallet/src/ui/pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool atFoot}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final view = PinSetupView(onDone: (_, _) {}, askBiometrics: false, actionsAtFoot: atFoot);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: atFoot
              ? Padding(padding: const EdgeInsets.all(16), child: view)
              : CenteredBody(children: [view]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final atFoot in [true, false]) {
    testWidgets('the PIN field does not move from choose to repeat (atFoot: $atFoot)', (tester) async {
      await _pump(tester, atFoot: atFoot);
      final choose = tester.getRect(find.byKey(const ValueKey('pin-choose')));
      expect(find.text('Choose a different PIN').hitTestable(), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('pin-choose')), '123456');
      await tester.pumpAndSettle();
      final confirm = tester.getRect(find.byKey(const ValueKey('pin-confirm')));
      expect(confirm, choose);
      if (atFoot) {
        // Centred in the room, not pinned to the top.
        expect(choose.top, greaterThan(200));
      }
    });
  }
}
