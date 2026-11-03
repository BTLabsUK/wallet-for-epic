// SPDX-License-Identifier: Apache-2.0
// Password fields with a test-driver id (TrustIds) keep their semantics: the node that carries the id
// is an obscured text field, beside its show/hide button, not inside it. In 26.10.26 b1e4540 the id
// made the field's row take the eye's button and label, with the field inside it; on Windows the
// field then read as a plain text field after a "Show" button.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/app/shots.dart' show DeskShot;
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final shots = <String, DeskShot>{for (final s in [...onboardingShots, ...transferShots]) s.id: s};

  final screens = <String, List<String>>{
    '02a-create': ['g4.account.password', 'g4.account.confirm'],
    '05-unlock': ['g4.unlock.password'],
    '16-send-review': ['g4.send.password'],
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key}: ${entry.value.join(', ')} are obscured text fields', (tester) async {
      final handle = tester.ensureSemantics();
      final shot = shots[entry.key]!;
      tester.view.physicalSize = Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      if (shot.before != null) await tester.runAsync(() => shot.before!(container));
      container.read(deskNavProvider.notifier)
        ..reset(DeskRoute.overview)
        ..go(shot.route, shot.arg);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
      }
      if (shot.prepare != null) {
        await tester.runAsync(() => shot.prepare!(container, tester.element(find.byType(DeskRoot))));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
      }
      for (final id in entry.value) {
        final found = find.bySemanticsIdentifier(id);
        expect(found, findsOneWidget, reason: id);
        final flags = tester.getSemantics(found).getSemanticsData().flagsCollection;
        expect(flags.isTextField, isTrue, reason: '$id: not a text field');
        expect(flags.isObscured, isTrue, reason: '$id: not obscured');
        final field = tester.getSemantics(found);
        final siblings = <SemanticsNode>[];
        field.parent!.visitChildren((n) {
          siblings.add(n);
          return true;
        });
        final next = siblings.indexOf(field) + 1;
        expect(next < siblings.length && siblings[next].getSemanticsData().flagsCollection.isButton, isTrue,
            reason: '$id: its show/hide button is not the node after it');
        expect(siblings[next].getSemanticsData().label, startsWith('Show'), reason: '$id: the node after it is not show/hide');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      handle.dispose();
    });
  }
}
