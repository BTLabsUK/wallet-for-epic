// SPDX-License-Identifier: Apache-2.0
// Home's field: what Enter opens, and the contacts a typed name brings up under it.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/home_field.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  return container;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  test('an amount opens Send with it; anything else lands in To', () {
    expect(homeFieldSend('  '), isNull);
    expect(homeFieldSend('12.5')!.amount, '12.5');
    expect(homeFieldSend('12.')!.amount, '12.', reason: 'an amount still being typed, as the matches count it');
    expect(homeFieldSend('anna')!.recipient, 'anna');
  });

  test('matches: by name in any case, favourites first, four at most, none for an amount', () {
    Contact c(String id, String name, {bool fav = false}) => Contact(id: id, name: name, address: '', favourite: fav);
    final all = [c('1', 'Anna Kowalska'), c('2', 'Hannah', fav: true), c('3', 'Tom'), c('4', 'Joanna'), c('5', 'Annette'), c('6', 'Danny')];
    expect(homeFieldMatches(all, 'ANN').map((x) => x.name), ['Hannah', 'Anna Kowalska', 'Annette', 'Danny']);
    expect(homeFieldMatches(all, '12'), isEmpty);
    expect(homeFieldMatches(all, ''), isEmpty);
  });

  testWidgets('typing a name shows the contact under the field; a click opens Send to it', (tester) async {
    final container = await _open(tester);
    final field = find.descendant(of: find.byKey(const ValueKey('home-field')), matching: find.byType(EditableText));
    final first = container.read(deskProvider).contacts!.first;
    await tester.enterText(field, first.name.substring(0, 3));
    await tester.pump();
    expect(find.byKey(const ValueKey('home-field-matches')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('home-field-match-${first.id}')));
    await tester.pump(const Duration(milliseconds: 300));
    final at = container.read(deskNavProvider);
    expect(at.route, DeskRoute.send);
    expect((at.arg as SendArgs).contact?.id, first.id);
    await _end(tester);
  });

  testWidgets('the field keeps the focus while typing brings matches up and takes them away', (tester) async {
    await _open(tester);
    final field = find.descendant(of: find.byKey(const ValueKey('home-field')), matching: find.byType(EditableText));
    bool focused() => tester.widget<EditableText>(field).focusNode.hasFocus;
    await tester.showKeyboard(field);
    await tester.pump();
    expect(focused(), isTrue);
    final state0 = tester.state(field);
    // Typed key by key, as the keyboard does: no match, a match (Tom), none again, and spaces.
    for (final typed in ['x', 'T', 'To', 'Tom', 'Tom ', 'Tom x', 'Tom', 'p', 'pay', 'pay ', 'pay bt labs 1', '']) {
      tester.testTextInput.enterText(typed);
      await tester.pump();
      expect(focused(), isTrue, reason: 'focus lost after typing "$typed"');
      expect(tester.testTextInput.hasAnyClients, isTrue, reason: 'keyboard input cut after typing "$typed"');
      expect(tester.state(field), same(state0), reason: 'field rebuilt after typing "$typed"');
    }
    await _end(tester);
  });

  testWidgets('Ctrl+K focuses the field once: opening Home again later does not', (tester) async {
    final container = await _open(tester);
    final nav = container.read(deskNavProvider.notifier);
    bool focused() => tester.widget<EditableText>(find.descendant(of: find.byKey(const ValueKey('home-field')), matching: find.byType(EditableText))).focusNode.hasFocus;
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    expect(focused(), isFalse);
    container.read(homeFieldFocusProvider.notifier).request();
    await settle();
    expect(focused(), isTrue);
    // Away and back: a new field, and no press since.
    nav.go(DeskRoute.activity);
    await settle();
    nav.go(DeskRoute.overview);
    await settle();
    expect(focused(), isFalse);
    // Pressed on another page: the field takes the focus when Home opens.
    nav.go(DeskRoute.activity);
    await settle();
    container.read(homeFieldFocusProvider.notifier).request();
    nav.go(DeskRoute.overview);
    await settle();
    expect(focused(), isTrue);
    await _end(tester);
  });
}
