// SPDX-License-Identifier: Apache-2.0
// Settings › Advanced › Confirmations on the desktop: the wallet's minimum confirmations at the
// default 6, each step applied at once and the balance split again, the note below the default,
// the bounds, Reset, and a refused count going back.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late MockDeskWallet _wallet;
late ProviderContainer _container;

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAdvanced);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Finder get _row => find.byKey(const ValueKey('adv-minConfirmations'));
Finder _button(String label) => find.descendant(of: _row, matching: find.byWidgetPredicate((w) => w is EIconButton && w.label == label));
EIconButton _iconButton(WidgetTester tester, String label) => tester.widget<EIconButton>(_button(label));
String _shown(WidgetTester tester) => tester.widget<EditableText>(find.descendant(of: _row, matching: find.byType(EditableText))).controller.text;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _settle(tester);
}

void main() {
  testWidgets('starts at the default 6: Default tag, no Reset, no note', (tester) async {
    await _open(tester);
    expect(_row, findsOneWidget);
    expect(_shown(tester), '6');
    expect(find.descendant(of: _row, matching: find.text('Default')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-minConfirmations-reset')), findsNothing);
    expect(find.byKey(const ValueKey('adv-minConfirmations-note')), findsNothing);
    expect(_container.read(deskProvider).balance!.minConfirmations, 6);
  });

  testWidgets('+ stores 7 at once and the balance counts with it; Reset brings back 6', (tester) async {
    await _open(tester);
    await _tap(tester, _button('More confirmations'));
    expect(_shown(tester), '7');
    expect(await tester.runAsync(_wallet.minimumConfirmations), 7);
    expect(_container.read(deskProvider).balance!.minConfirmations, 7);
    expect(find.byKey(const ValueKey('adv-minConfirmations-note')), findsNothing, reason: 'above the default: no note');
    expect(find.text('Reset to 6'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('adv-minConfirmations-reset')));
    expect(_shown(tester), '6');
    expect(await tester.runAsync(_wallet.minimumConfirmations), 6);
    expect(find.text('Reset to 6'), findsNothing);
  });

  testWidgets('below 6 the note shows and the Overview split moves: the 4-block payment is spendable at 3', (tester) async {
    await _open(tester);
    final before = _container.read(deskProvider).balance!;
    for (var i = 0; i < 3; i++) {
      await _tap(tester, _button('Fewer confirmations'));
    }
    expect(_shown(tester), '3');
    expect(find.byKey(const ValueKey('adv-minConfirmations-note')), findsOneWidget);
    expect(find.text('Fewer confirmations are faster but less safe.'), findsOneWidget);
    final after = _container.read(deskProvider).balance!;
    expect(after.minConfirmations, 3);
    expect(before.awaitingConfirmation, greaterThan(0));
    expect(after.awaitingConfirmation, 0, reason: 'the 4-block payment no longer confirming');
    expect(after.spendable - before.spendable, before.awaitingConfirmation, reason: 'it moved to spendable');
    expect(after.total, before.total);
    final lunch = _container.read(deskProvider).txs!.firstWhere((t) => t.id == 39);
    expect(lunch.state, TxState.confirmed);
    expect(lunch.confirmationsNeeded, 3);
  });

  testWidgets('bounds: − stops at 1, + stops at 30', (tester) async {
    await _open(tester);
    await tester.runAsync(() => _container.read(deskMinConfirmationsSettingProvider.notifier).set(1));
    await _settle(tester);
    expect(_shown(tester), '1');
    expect(_iconButton(tester, 'Fewer confirmations').onPressed, isNull);
    expect(_iconButton(tester, 'More confirmations').onPressed, isNotNull);
    await tester.runAsync(() => _container.read(deskMinConfirmationsSettingProvider.notifier).set(30));
    await _settle(tester);
    expect(_shown(tester), '30');
    expect(_iconButton(tester, 'More confirmations').onPressed, isNull);
    final refused = await tester.runAsync(() async {
      try {
        await _wallet.setMinimumConfirmations(31);
        return null;
      } on DeskError catch (e) {
        return e;
      }
    });
    expect(refused, isA<DeskError>());
    expect(await tester.runAsync(_wallet.minimumConfirmations), 30);
  });

  testWidgets('a refused count goes back and says so', (tester) async {
    await _open(tester);
    _wallet.refuseMinConfirmations = true;
    await _tap(tester, _button('More confirmations'));
    expect(_shown(tester), '6');
    expect(_container.read(deskMinConfirmationsSettingProvider).value, 6);
    expect(find.text('Confirmations not changed'), findsOneWidget);
    expect(find.descendant(of: _row, matching: find.text('Default')), findsOneWidget);
  });
}
