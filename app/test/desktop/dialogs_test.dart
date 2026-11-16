// SPDX-License-Identifier: Apache-2.0
// The one dialog footer (polish P1): EDialog lays its buttons out itself.
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
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

  testWidgets('a footer whose label does not fit its slot stacks, no label cut', (tester) async {
    Future<void> check(String back, String no, String yes, {required bool stacked}) async {
      await pump(
        tester,
        EDialog(
          title: 'T',
          size: DialogWidth.wide,
          actions: [
            EButton(label: back, onPressed: () {}),
            EButton(label: no, onPressed: () {}),
            EButton.primary(label: yes, onPressed: () {}),
          ],
        ),
      );
      for (final l in [back, no, yes]) {
        final p = tester.renderObject<RenderParagraph>(find.text(l));
        expect(p.didExceedMaxLines, isFalse, reason: l);
      }
      final ys = {for (final l in [back, no, yes]) tester.getCenter(find.text(l)).dy};
      if (stacked) expect(ys.length, 3, reason: no);
    }

    await check('Back', 'They do not match', 'They match', stacked: true);
    await check('Zurück', 'Sie stimmen nicht überein', 'Sie stimmen überein', stacked: true);
    await check('Wstecz', 'Nie zgadzają się', 'Zgadzają się', stacked: false);
    await check('返回', '不一致', '一致', stacked: false);
  });

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
    final xs = {for (final l in ['First', 'Delete', 'Go']) l: tester.getCenter(find.text(l)).dx};
    // Secondaries, the destructive action, then the primaries (the last one filled). Past three
    // buttons the first ones sit in a row above the last three.
    expect(xs['Delete']! < xs['First']! && xs['First']! < xs['Go']!, isTrue, reason: '$xs');
    expect(tester.getCenter(find.text('Back')).dy, lessThan(tester.getCenter(find.text('Go')).dy));
    final heights = {
      for (final l in ['Back', 'First', 'Delete', 'Go'])
        tester.getSize(find.ancestor(of: find.text(l), matching: find.byType(AnimatedContainer)).first).height,
    };
    expect(heights, {Ctl.md}, reason: 'every footer button is one height');
    final ys = {for (final l in ['First', 'Delete', 'Go']) tester.getCenter(find.text(l)).dy};
    expect(ys.length, 1, reason: 'one baseline');
    // The main button is 1.35 times as wide as each of the others in its row.
    double w(String l) => tester.getSize(find.ancestor(of: find.text(l), matching: find.byType(AnimatedContainer)).first).width;
    expect(w('Go') / w('Delete'), moreOrLessEquals(1.35, epsilon: 0.02));
    expect(w('First'), moreOrLessEquals(w('Delete'), epsilon: 1));
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

  test('the two widths', () {
    expect(const EDialog(title: 'T').width, 480.u);
    expect(const EDialog(title: 'T', size: DialogWidth.wide).width, 600.u);
  });
}
