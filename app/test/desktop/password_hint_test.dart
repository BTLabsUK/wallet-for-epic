// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_wallets_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/password_estimate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Patterns only, no word lists: quick to build, and estimates the same way.
final _estimator = PasswordEstimator(const {});

Future<ProviderContainer> _pump(WidgetTester tester, Widget child, {bool lists = true}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      if (lists) passwordEstimatorProvider.overrideWith((ref) async => _estimator),
      if (!lists) passwordEstimatorProvider.overrideWith((ref) => Future.error(StateError('no lists'))),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return container;
}

String? _line(WidgetTester tester) {
  final f = find.byKey(const ValueKey('password-hint'));
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

/// The live region's label: what a screen reader was last told.
String _announced(WidgetTester tester) {
  final node = tester.getSemantics(find.byKey(const ValueKey('password-hint')));
  SemanticsNode? n = node;
  while (n != null && !n.getSemanticsData().flagsCollection.isLiveRegion) {
    n = n.parent;
  }
  return n?.label ?? '';
}

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

Finder _field(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText)).first;

void main() {
  testWidgets('the count follows each keystroke, the time comes 150 ms after typing stops', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, Column(children: [TextField(controller: c), PasswordHint(controller: c)]));
    expect(_line(tester), '8 characters or more', reason: 'empty field: the least length, never a blank line');
    expect(find.byIcon(EIcons.info), findsNothing);

    await _type(tester, find.byType(TextField), 'a');
    expect(_line(tester), '1 character');
    await _type(tester, find.byType(TextField), 'ab');
    expect(_line(tester), '2 characters');
    await tester.pump(const Duration(milliseconds: 149));
    expect(_line(tester), '2 characters');
    await tester.pump(const Duration(milliseconds: 2));
    expect(_line(tester), '2 characters · under a minute to crack');
    expect(find.byIcon(EIcons.info), findsOneWidget);

    await _type(tester, find.byType(TextField), 'x8F!q2Lm#9Rt');
    expect(_line(tester), startsWith('12 characters · under a minute'), reason: 'the last time stays until the new one');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_line(tester), '12 characters · ${_estimator.crackTime('x8F!q2Lm#9Rt')}');
    expect(_line(tester), isNot(contains('under a minute')));

    await _type(tester, find.byType(TextField), '');
    expect(_line(tester), '8 characters or more');
    await tester.pump(const Duration(seconds: 2));
    expect(_line(tester), '8 characters or more');
    await _end(tester);
  });

  testWidgets('the live region speaks after a pause, and only when the time changes', (tester) async {
    final handle = tester.ensureSemantics();
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, Column(children: [TextField(controller: c), PasswordHint(controller: c)]));
    final field = find.byType(TextField);

    await _type(tester, field, 'aaaaaaaa');
    await tester.pump(const Duration(milliseconds: 200));
    expect(_line(tester), contains('under a minute'));
    expect(_announced(tester), '', reason: 'not yet: under a second of pause');
    await tester.pump(const Duration(seconds: 1));
    expect(_announced(tester), 'under a minute to crack');

    // Typing on with short pauses: the line updates, the live region waits.
    const strong = 'x8F!q2Lm#9Rt';
    for (var i = 1; i <= strong.length; i++) {
      await _type(tester, field, strong.substring(0, i));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_announced(tester), 'under a minute to crack');
    }
    final time = _estimator.crackTime(strong);
    expect(_line(tester), '12 characters · $time');
    await tester.pump(const Duration(seconds: 1));
    expect(_announced(tester), time);

    // Back to quick passwords: one change, then the same time again changes nothing.
    final labels = <String>[];
    for (final p in ['aaaaaaaa', 'aaaaaaaaa', 'aaaaaaaaaa']) {
      await _type(tester, field, p);
      await tester.pump(const Duration(seconds: 2));
      labels.add(_announced(tester));
    }
    expect(labels, everyElement('under a minute to crack'));
    handle.dispose();
    await _end(tester);
  });

  testWidgets('without word lists the count still shows and nothing fails', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, Column(children: [TextField(controller: c), PasswordHint(controller: c)]), lists: false);
    await _type(tester, find.byType(TextField), 'abcdefgh');
    await tester.pump(const Duration(seconds: 1));
    expect(_line(tester), '8 characters');
    expect(tester.takeException(), isNull);
    await _end(tester);
  });

  group('under each new password', () {
    Future<void> check(WidgetTester tester, Finder field) async {
      expect(find.byType(PasswordHint), findsOneWidget);
      expect(find.text('Weak'), findsNothing);
      expect(find.text('Strong'), findsNothing);
      expect(_line(tester), '8 characters or more', reason: 'the rule at rest');
      await _type(tester, field, 'Password1!');
      await tester.pump(const Duration(milliseconds: 200));
      expect(_line(tester), '10 characters · ${_estimator.crackTime('Password1!')}');
      // The hint sits under the field it rates.
      expect(tester.getTopLeft(find.byType(PasswordHint)).dy, greaterThan(tester.getBottomLeft(field).dy));
    }

    testWidgets('create', (tester) async {
      await _pump(tester, const CreateScreen(arg: CreateStep.account));
      await check(tester, _field('Password'));
      await _end(tester);
    });

    testWidgets('restore', (tester) async {
      await _pump(tester, const RestoreScreen(arg: RestoreStep.account));
      await check(tester, _field('Password'));
      await _end(tester);
    });

    testWidgets('import: a new password for a short old one', (tester) async {
      await _pump(tester, const ImportWalletsScreen(arg: ImportStep.import));
      expect(find.byType(PasswordHint), findsNothing);
      await _type(tester, _field('Old password'), 'short');
      await check(tester, _field('New password'));
      await _end(tester);
    });

    testWidgets('change password', (tester) async {
      await _pump(tester, Builder(builder: (c) => TextButton(onPressed: () => showChangePasswordDialog(c), child: const Text('open'))));
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 500));
      await check(tester, _field('New password'));
      await _end(tester);
    });

    testWidgets('not on unlock', (tester) async {
      await _pump(tester, const UnlockScreen());
      expect(find.byType(PasswordHint), findsNothing);
      await _end(tester);
    });
  });

  testWidgets('the info icon opens on click and closes on a second click, Esc or an outside click', (tester) async {
    final handle = tester.ensureSemantics();
    final c = TextEditingController(text: 'abc');
    addTearDown(c.dispose);
    await _pump(tester, Column(children: [TextField(controller: c), PasswordHint(controller: c)]));
    expect(find.bySemanticsLabel('How the time is estimated'), findsOneWidget);
    final note = find.byKey(const ValueKey('info-popover-text'));
    await tester.tap(find.byIcon(EIcons.info));
    await tester.pump();
    expect(note, findsOneWidget);
    // A second click closes.
    await tester.tap(find.byIcon(EIcons.info));
    await tester.pump();
    expect(note, findsNothing);
    // Esc closes.
    await tester.tap(find.byIcon(EIcons.info));
    await tester.pump();
    expect(note, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(note, findsNothing);
    // An outside click closes.
    await tester.tap(find.byIcon(EIcons.info));
    await tester.pump();
    expect(note, findsOneWidget);
    await tester.tapAt(const Offset(600, 700));
    await tester.pump();
    expect(note, findsNothing);
    handle.dispose();
    await _end(tester);
  });

  testWidgets('the Confirm field stays put while the hint and its error line change', (tester) async {
    await _pump(tester, const CreateScreen(arg: CreateStep.account));
    final confirm = find.byType(PasswordBox).at(1);
    final at = tester.getTopLeft(confirm);
    for (final t in ['a', 'abc', 'abcdefgh', 'abcdefghijkl', '']) {
      await _type(tester, _field('Password'), t);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(confirm), at, reason: 'after typing "$t"');
    }
    await _end(tester);
  });
}
