// SPDX-License-Identifier: Apache-2.0
// Desktop accessibility fixes, read as a screen reader or a UI-automation driver reads them:
// the semantics tree, not the pixels. Each case names the node a driver looks for and the
// action it runs.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/shots.dart' show DeskShot;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/trust_ids.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

Future<ProviderContainer> _open(WidgetTester tester, DeskRoute route, {Object? arg, Size size = const Size(1280, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

bool _button(SemanticsNode n) => n.flagsCollection.isButton;
bool _textField(SemanticsNode n) => n.flagsCollection.isTextField;
bool _selected(SemanticsNode n) => n.flagsCollection.isSelected == Tristate.isTrue;
bool _hasSelectedState(SemanticsNode n) => n.flagsCollection.isSelected != Tristate.none;

/// The nodes with this label that are buttons (a page can name the same word elsewhere).
List<SemanticsNode> _buttons(String label) => [
  for (final n in find.semantics.byLabel(label).evaluate())
    if (_button(n)) n,
];

/// How many nodes at or under [n] carry a label.
int _labelled(SemanticsNode n) {
  var count = n.label.isNotEmpty ? 1 : 0;
  n.visitChildren((c) {
    count += _labelled(c);
    return true;
  });
  return count;
}

void main() {
  testWidgets('a) "Add a wallet" in the wallet menu is a button with a tap, and it runs', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await _open(tester, DeskRoute.overview);
    await tester.tap(find.byKey(const ValueKey('bar-wallet')));
    await _settle(tester);
    final add = _buttons(_l.deskBarAddWallet);
    expect(add, hasLength(1), reason: 'one button named "${_l.deskBarAddWallet}"');
    expect(add.single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    // A driver's press (Invoke on Windows, AXPress on macOS) is the semantics tap.
    tester.semantics.tap(find.semantics.byLabel(_l.deskBarAddWallet));
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.settingsWallets);
    expect(find.semantics.byLabel(_l.deskBarAddWallet).evaluate().where((n) => _button(n)), isEmpty, reason: 'the menu closed');
    handle.dispose();
    await _close(tester);
  });

  testWidgets('b) the Back button is one labelled button, not a button around a second label', (tester) async {
    final handle = tester.ensureSemantics();
    // One column (the page under 880 wide): the detail replaces the list and has a Back.
    await _open(tester, DeskRoute.activity, size: const Size(800, 700));
    await tester.tap(find.textContaining('a1f9e8d7.tx').first);
    await _settle(tester);
    final back = _buttons(_l.deskKitBackAlt);
    expect(back, hasLength(1));
    expect(back.single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    // Nothing under the button names it again: UI automation would read an empty Button
    // inside a named Custom otherwise.
    expect(_labelled(back.single), 1);
    handle.dispose();
    await _close(tester);
  });

  testWidgets('c) a checkbox takes the semantics tap, not only a pointer', (tester) async {
    final handle = tester.ensureSemantics();
    var value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, set) => ProviderScope(
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(body: Center(child: ECheckbox(value: value, onChanged: (v) => set(() => value = v), label: _l.deskOnbCreateWritten(24)))),
          ),
        ),
      ),
    );
    final box = find.semantics.byLabel(_l.deskOnbCreateWritten(24));
    expect(box.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(box);
    await tester.pump();
    expect(value, isTrue);
    tester.semantics.tap(box);
    await tester.pump();
    expect(value, isFalse);
    handle.dispose();
    await _close(tester);
  });

  testWidgets('d) each Settings section is its own button with a name and a selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, DeskRoute.settingsAppearance);
    final column = find.semantics.byLabel(_l.deskSetFrameSections).evaluate().single;
    expect(_textField(column), isFalse, reason: 'the list is not a text field');
    expect(_button(column), isFalse);
    // The search, the sections and the way back are the container's children, each its own node.
    final search = find.semantics.byFlag(SemanticsFlag.isTextField).evaluate().where((n) => n.label.contains(_l.deskSetSearchHint)).toList();
    expect(search, hasLength(1));
    expect(search.single.label, isNot(contains(_l.deskSetFrameBack)), reason: 'the search does not carry the way back');
    final back = find.bySemanticsIdentifier(TrustIds.settingsBack).evaluate();
    expect(back, hasLength(1));
    expect(_textField(tester.getSemantics(find.bySemanticsIdentifier(TrustIds.settingsBack))), isFalse);
    var sections = 0;
    for (final route in DeskRoute.values.where((r) => r.section == DeskSection.settings)) {
      final id = find.bySemanticsIdentifier(TrustIds.settingsSection(route.name));
      if (id.evaluate().isEmpty) continue;
      sections++;
      final n = tester.getSemantics(id);
      expect(_button(n), isTrue, reason: route.name);
      expect(_hasSelectedState(n), isTrue, reason: route.name);
      expect(_textField(n), isFalse, reason: route.name);
      expect(n.label, isNotEmpty, reason: route.name);
      expect(n.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: route.name);
      expect(_selected(n), route == DeskRoute.settingsAppearance, reason: route.name);
    }
    expect(sections, greaterThan(5));
    handle.dispose();
    await _close(tester);
  });

  testWidgets('e) the Theme options are buttons with a real frame, one selected, and a tap picks', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await _open(tester, DeskRoute.settingsAppearance);
    await tester.tap(find.byKey(const ValueKey('appearance-theme')));
    await tester.pump();
    // The first frame after opening, and once settled: the frame never starts flat.
    for (final settled in [false, true]) {
      if (settled) await _settle(tester);
      for (final name in [_l.deskSetAppearSystem, _l.deskSetAppearDark, _l.deskSetAppearLight]) {
        final option = _buttons(name).where((n) => n.rect.height > 0).toList();
        expect(option, isNotEmpty, reason: name);
        final n = option.last;
        expect(n.rect.height, greaterThanOrEqualTo(36), reason: '$name frame ${n.rect}');
        expect(n.rect.width, greaterThanOrEqualTo(100), reason: '$name frame ${n.rect}');
        expect(n.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: name);
      }
    }
    expect(_selected(_buttons(_l.deskSetAppearDark).last), isTrue);
    expect(_selected(_buttons(_l.deskSetAppearLight).last), isFalse);
    tester.semantics.tap(find.semantics.byLabel(_l.deskSetAppearLight).last);
    await _settle(tester);
    expect(container.read(deskProvider).settings.theme, ThemeChoice.light);
    handle.dispose();
    await _close(tester);
  });

  group('f) the create-wallet password fields', () {
    Future<(ProviderContainer, Finder, Finder)> openCreate(WidgetTester tester) async {
      final shot = <String, DeskShot>{for (final s in onboardingShots) s.id: s}['02a-create']!;
      tester.view.physicalSize = Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      container.read(deskNavProvider.notifier)
        ..reset(DeskRoute.overview)
        ..go(shot.route, shot.arg);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
      await _settle(tester);
      final fields = find.descendant(of: find.byType(AccountForm), matching: find.byType(TextField));
      return (container, fields.at(0), fields.at(1));
    }

    testWidgets('typing one character at a time into both keeps every character', (tester) async {
      final (_, password, confirm) = await openCreate(tester);
      const pw = 'correct horse 9!';
      for (final f in [password, confirm]) {
        await tester.tap(f);
        await tester.pump();
        for (var i = 1; i <= pw.length; i++) {
          await tester.enterText(f, pw.substring(0, i));
          await tester.pump();
          // Whatever was typed so far is what the field holds: a rebuild does not eat it.
          expect(tester.widget<TextField>(f).controller!.text, pw.substring(0, i));
        }
      }
      expect(tester.widget<TextField>(confirm).controller!.text, pw);
      expect(find.text(_l.deskSetupPasswordsDiffer), findsNothing);
      await _close(tester);
    });

    testWidgets('select all selects the whole confirm field', (tester) async {
      final (_, _, confirm) = await openCreate(tester);
      await tester.tap(confirm);
      await tester.pump();
      await tester.enterText(confirm, 'hunter2hunter2');
      await tester.pump();
      final context = tester.element(find.descendant(of: find.descendant(of: confirm, matching: find.byType(EditableText)), matching: find.byType(Scrollable)));
      Actions.invoke(context, const SelectAllTextIntent(SelectionChangedCause.keyboard));
      await tester.pump();
      final c = tester.widget<TextField>(confirm).controller!;
      expect((c.selection.start, c.selection.end), (0, 14));
      // The shortcut is bound to the field: no app-level key handler takes it.
      c.selection = const TextSelection.collapsed(offset: 3);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect((c.selection.start, c.selection.end), (0, 14));
      await _close(tester);
    });
  });
}
