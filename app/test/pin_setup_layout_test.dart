// SPDX-License-Identifier: Apache-2.0
// The PIN keypad stays in one place between "choose" and "repeat", in the first-run layout
// (button at the foot) and the inline one (Settings › Change PIN, Restore).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/centered_body.dart';
import 'package:epic_wallet/src/ui/pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pin_pad.dart';

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
    testWidgets('the keypad does not move from choose to repeat (atFoot: $atFoot)', (tester) async {
      await _pump(tester, atFoot: atFoot);
      final choose = tester.getRect(pinPad);
      expect(find.text('Choose a different PIN').hitTestable(), findsNothing);
      await typePin(tester, '123456');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text(AppLocalizations.of(tester.element(pinPad)).pinConfirmTitle), findsOneWidget);
      expect(tester.getRect(pinPad), choose);
    });
  }
}
