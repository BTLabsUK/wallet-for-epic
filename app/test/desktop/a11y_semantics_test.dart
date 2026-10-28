// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// What a screen reader (AT-SPI on Linux) sees and can do: buttons carry a tap, text fields a
// name, and Cancel on a pending send opens its dialog from the semantics tap.

Widget _kit(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildDeskTheme(Brightness.dark),
    home: Scaffold(body: Center(child: child)),
  ),
);

SemanticsNode _node(WidgetTester tester, String label) => find.semantics.byLabel(label).evaluate().single;

void main() {
  testWidgets('EButton and ENavItem expose a tap a screen reader can run', (tester) async {
    final handle = tester.ensureSemantics();
    var pressed = 0, nav = 0;
    await tester.pumpWidget(
      _kit(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EButton.primary(label: 'Create wallet', onPressed: () => pressed++),
            const EButton(label: 'Disabled'),
            SizedBox(width: 240, child: ENavItem(icon: EIcons.send, label: 'Send', selected: false, onTap: () => nav++)),
          ],
        ),
      ),
    );
    expect(_node(tester, 'Create wallet').getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(_node(tester, 'Disabled').getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(_node(tester, 'Send').getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Create wallet'));
    tester.semantics.tap(find.semantics.byLabel('Send'));
    expect((pressed, nav), (1, 1));
    handle.dispose();
  });

  testWidgets('text fields are named by their field label, else their hint', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _kit(
        SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EField(label: 'Password', child: EPasswordInput()),
              const EField(label: 'Amount', child: EInput(hint: '0.00')),
              const EInput(hint: 'Search'),
              const EInput(semanticLabel: 'Server'),
            ],
          ),
        ),
      ),
    );
    final names = [for (final n in find.semantics.byFlag(SemanticsFlag.isTextField).evaluate()) n.label];
    expect(names, hasLength(4));
    expect(names[0], contains('Password'));
    expect(names[1], contains('Amount'));
    expect(names[2], contains('Search'));
    expect(names[3], contains('Server'));
    handle.dispose();
  });

  Future<void> pumpPendingSend(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          // The mock wallet's tx 38: a send waiting for the recipient, cancellable.
          home: const Scaffold(body: ActivityScreen(arg: 38)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Cancel on a pending send opens its dialog from the semantics tap', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPendingSend(tester);
    await tester.ensureVisible(find.widgetWithText(EButton, 'Cancel payment'));
    await tester.pump();
    tester.semantics.tap(find.semantics.byLabel('Cancel payment'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Cancel this payment?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Keep'));
    await tester.pump(const Duration(seconds: 3));
    handle.dispose();
  });
}
