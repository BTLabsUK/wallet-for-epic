// SPDX-License-Identifier: Apache-2.0
// The recovery phrase layout (EPhraseLayout) on the new-wallet step and in Settings › Recovery
// phrase: the actions above the words, their right edge the grid's; the checkbox (or the
// warning) under the words; in a short window only the words scroll.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_phrase.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';

Future<void> _pump(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

Finder _button(String label) => find.ancestor(of: find.text(label), matching: find.byType(EButton)).first;

/// The actions sit above the grid, the last one ([edge]: its label for a bare button, its box
/// for a bordered one) ending at the grid's right edge.
void _actionsAbove(WidgetTester tester, String first, Finder edge) {
  final grid = tester.getRect(find.byType(ESeedGrid));
  expect(tester.getRect(_button(first)).bottom, lessThan(grid.top));
  expect(tester.getRect(edge).right, moreOrLessEquals(grid.right, epsilon: 1));
}

/// Dragging the words scrolls them and leaves [pinned] where it was.
Future<void> _onlyWordsScroll(WidgetTester tester, Finder pinned, Finder action) async {
  final word = tester.getTopLeft(find.byType(ESeedGrid));
  final at = tester.getTopLeft(pinned);
  final top = tester.getTopLeft(action);
  final view = tester.view.physicalSize.height;
  expect(tester.getRect(pinned).bottom, lessThanOrEqualTo(view), reason: 'in view before scrolling');
  await tester.dragFrom(word + const Offset(40, 20), const Offset(0, -200));
  await tester.pump();
  expect(tester.getTopLeft(find.byType(ESeedGrid)).dy, lessThan(word.dy), reason: 'the words scrolled');
  expect(tester.getTopLeft(pinned), at, reason: 'pinned under the words');
  expect(tester.getTopLeft(action), top, reason: 'the actions stay at the top');
}

void main() {
  testWidgets('new wallet: Hide, Copy, Show QR above the words; in a short window the checkbox stays in view', (tester) async {
    await _pump(tester, const CreateScreen(arg: CreateStep.phrase), const Size(1000, 640));
    final grid = tester.getTopLeft(find.byType(ESeedGrid));
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(ESeedGrid)), grid, reason: 'Reveal moves nothing');
    _actionsAbove(tester, 'Hide', find.text('Show QR'));
    final checkbox = find.byType(ECheckbox);
    expect(tester.getRect(checkbox).bottom, lessThan(tester.getRect(_button('Continue')).top));
    await _onlyWordsScroll(tester, checkbox, _button('Copy'));
    await tester.tap(find.textContaining('I have written down'));
    await tester.pump();
    expect(tester.widget<ECheckbox>(checkbox).value, isTrue);
    expect(tester.takeException(), isNull);
    await _end(tester);
  });

  testWidgets('new wallet: a tall window shows the checkbox right under the words', (tester) async {
    await _pump(tester, const CreateScreen(arg: CreateStep.phrase), const Size(1280, 1000));
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    _actionsAbove(tester, 'Hide', find.text('Show QR'));
    final gap = tester.getRect(find.byType(ECheckbox)).top - tester.getRect(find.byType(ESeedGrid)).bottom;
    expect(gap, lessThan(40));
    await _end(tester);
  });

  testWidgets('Settings › Recovery phrase: the actions above the words; in a short window the warning stays in view', (tester) async {
    await _pump(tester, const SettingsPhraseScreen(arg: PhraseDemo.shown), const Size(1000, 580));
    _actionsAbove(tester, 'Copy', _button('Hide recovery phrase'));
    await _onlyWordsScroll(tester, find.byType(ENotice), _button('Copy'));
    expect(tester.takeException(), isNull);
    await _end(tester);
  });
}
