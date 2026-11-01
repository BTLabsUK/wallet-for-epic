// SPDX-License-Identifier: Apache-2.0
// The one dialog footer (polish P1): EDialog lays its buttons out itself.
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, EDialog dialog) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: Center(child: dialog))));
    await tester.pump();
    // The dialog takes the focus a frame later (Esc closes it).
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('orders the footer, keeps one filled primary and one height', (tester) async {
    await pump(
      tester,
      EDialog(
        title: 'T',
        actions: [
          EButton.primary(label: 'First', onPressed: () {}),
          EButton.ghost(label: 'Back', onPressed: () {}),
          EButton(label: 'Delete', kind: EBtnKind.danger, size: EBtnSize.inline, onPressed: () {}),
          EButton.primary(label: 'Go', size: EBtnSize.sm, onPressed: () {}),
        ],
      ),
    );
    final xs = {for (final l in ['Back', 'First', 'Delete', 'Go']) l: tester.getCenter(find.text(l)).dx};
    // Secondaries, the destructive action, then the primaries (the last one filled).
    expect(xs['Back']! < xs['Delete']! && xs['Delete']! < xs['First']! && xs['First']! < xs['Go']!, isTrue, reason: '$xs');
    final heights = {
      for (final l in ['Back', 'First', 'Delete', 'Go'])
        tester.getSize(find.ancestor(of: find.text(l), matching: find.byType(AnimatedContainer)).first).height,
    };
    expect(heights, {Ctl.md}, reason: 'every footer button is one height');
    final ys = {for (final l in ['Back', 'First', 'Delete', 'Go']) tester.getCenter(find.text(l)).dy};
    expect(ys.length, 1, reason: 'one baseline');
    Color fill(String l) => (tester.widget<AnimatedContainer>(find.ancestor(of: find.text(l), matching: find.byType(AnimatedContainer)).first).decoration! as BoxDecoration).color!;
    final c = deskDark;
    expect(fill('Go'), c.accent, reason: 'the last primary is filled');
    expect(fill('First'), isNot(c.accent), reason: 'an earlier primary shows as a secondary');
  });

  testWidgets('a disabled primary does not look like an enabled secondary', (tester) async {
    await pump(
      tester,
      EDialog(
        title: 'T',
        actions: [
          EButton(label: 'Cancel', onPressed: () {}),
          const EButton.primary(label: 'Save'),
        ],
      ),
    );
    BoxDecoration face(String l) => tester.widget<AnimatedContainer>(find.ancestor(of: find.text(l), matching: find.byType(AnimatedContainer)).first).decoration! as BoxDecoration;
    expect(face('Save').border, Border.all(color: Colors.transparent), reason: 'no edge');
    expect(face('Save').color, isNot(face('Cancel').color));
  });

  test('old widths snap to the two sizes', () {
    expect(EDialog(title: 'T', width: 420.u).width, DialogMetrics.standardWidth.u);
    expect(EDialog(title: 'T', width: 680.u).width, DialogMetrics.wideWidth.u);
    expect(const EDialog(title: 'T', width: double.infinity).width, DialogMetrics.wideWidth.u);
    expect(const EDialog(title: 'T').width, DialogMetrics.standardWidth.u);
  });
}
