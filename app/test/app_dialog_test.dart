// SPDX-License-Identifier: Apache-2.0
// The phone's one dialog (polish P1): footer order, one primary, stacking, the check row.
import 'package:epic_wallet/src/ui/app_dialog.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget dialog, {double width = 390}) async {
    await tester.binding.setSurfaceSize(Size(width, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: buildWalletTheme(protocolDark, Brightness.dark), home: Scaffold(body: dialog)));
    await tester.pump();
  }

  testWidgets('secondaries, then the risk action, then the one filled primary, on one line', (tester) async {
    await pump(
      tester,
      AppDialog(
        title: 'Title',
        icon: Icons.info_outline,
        actions: [
          DialogButton.primary(label: 'Go', onPressed: () {}),
          DialogButton.risk(label: 'Out', onPressed: () {}),
          DialogButton.secondary(label: 'No', onPressed: () {}),
        ],
      ),
    );
    final xs = [for (final l in ['No', 'Out', 'Go']) tester.getCenter(find.text(l)).dx];
    expect(xs[0] < xs[1] && xs[1] < xs[2], isTrue, reason: '$xs');
    expect({for (final l in ['No', 'Out', 'Go']) tester.getCenter(find.text(l)).dy}.length, 1);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('a second primary shows as a secondary', (tester) async {
    await pump(
      tester,
      AppDialog(
        title: 'Title',
        icon: Icons.info_outline,
        actions: [
          DialogButton.primary(label: 'A', onPressed: () {}),
          DialogButton.primary(label: 'B', onPressed: () {}),
        ],
      ),
    );
    expect(find.widgetWithText(FilledButton, 'B'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'A'), findsOneWidget);
  });

  testWidgets('long labels stack full width with the primary on top', (tester) async {
    await pump(
      tester,
      AppDialog(
        title: 'Title',
        icon: Icons.info_outline,
        actions: [
          DialogButton.secondary(label: 'A rather long secondary label', onPressed: () {}),
          DialogButton.primary(label: 'A rather long primary label', onPressed: () {}),
        ],
      ),
      width: 360,
    );
    final primary = tester.getRect(find.widgetWithText(FilledButton, 'A rather long primary label'));
    final secondary = tester.getRect(find.widgetWithText(OutlinedButton, 'A rather long secondary label'));
    expect(primary.bottom <= secondary.top, isTrue);
    expect(primary.width, secondary.width);
  });

  testWidgets('the check row toggles from its label, in body text', (tester) async {
    var value = false;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: 'Title',
          icon: Icons.delete_outline,
          body: DialogCheckRow(value: value, onChanged: (v) => setState(() => value = v), label: 'I have it'),
        ),
      ),
    );
    await tester.tap(find.text('I have it'));
    await tester.pump();
    expect(value, isTrue);
    final style = tester.widget<Text>(find.text('I have it')).style!;
    expect(style.fontSize, Theme.of(tester.element(find.text('I have it'))).textTheme.bodyMedium!.fontSize);
    expect(tester.getSize(find.byType(DialogCheckRow)).height, greaterThanOrEqualTo(44));
  });
}
