// SPDX-License-Identifier: Apache-2.0
// One primary per screen: every desktop screen in the shots catalogue (dialog shots aside,
// EDialog has its own rule) shows at most one enabled filled primary button on its top route
// (a dialog over the page counts alone). A second thing to do is a secondary or ghost button; a
// disabled primary is the next step, waiting (Continue under Reveal phrase).
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The primaries a screen offers: filled, enabled, on stage (a closed panel's button is
/// offstage) and on the top route.
List<String> primariesOf(WidgetTester tester) => [
  for (final e in find.byType(EButton).evaluate())
    if (e.widget case EButton(kind: EBtnKind.primary, :final label, onPressed: _?) when ModalRoute.of(e)?.isCurrent ?? true) label,
];

void main() {
  // The levels shots keep their choice in the secret store.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  // A shot's network mode or switches stay with the process: the next shot starts clean.
  tearDown(() {
    NetGate.set(NetworkMode.standard);
    NetGate.setPayments(PaymentPrefs.defaults);
    NetGate.setExperimental(AdvancedPrefs.none);
    NetGate.releaseFirstStart();
  });
  final shots = [...onboardingShots, ...walletShots, ...transferShots, ...settingsShots].where((s) => s.dialog == null && s.prepare == null).toList();

  for (final shot in shots) {
    testWidgets('${shot.id}: at most one primary', (tester) async {
      tester.view.physicalSize = Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))],
        retry: (_, _) => null,
      );
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      if (shot.before != null) await tester.runAsync(() => shot.before!(container));
      container.read(deskNavProvider.notifier).reset(shot.route, shot.arg);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      }
      final primaries = primariesOf(tester);
      expect(primaries.length, lessThanOrEqualTo(1), reason: '${shot.id} shows ${primaries.join(', ')}');
      await tester.pumpWidget(const SizedBox.shrink());
      // Disposed inside the test: the price poll's timer must not outlive it.
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
