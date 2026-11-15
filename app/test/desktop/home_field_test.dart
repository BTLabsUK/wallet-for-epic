// SPDX-License-Identifier: Apache-2.0
// Home's field: what Enter opens, and the contacts a typed name brings up under it.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart' show RequestArgs;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/home_field.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;
const _e1Addr = 'epic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9';
const _e1Link = 'epic:epic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9?server=https://pay.example.net';
const _classicRequest = 'epic:esMASi45ub7Qe4ZE36UT5G6cU4ud8Fhhe4deS4F3cw9KTAb8dLcu@epicbox.example.org?amount=3&message=coffee';

/// Home with epic1 on, as it is by default, or switched off in the payment settings.
Future<ProviderContainer> _open(WidgetTester tester, {bool epic1 = true, Contact? extra}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = MockDeskWallet(delay: Duration.zero);
  if (extra != null) await wallet.saveContact(extra);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    final n = container.read(deskProvider.notifier);
    await n.refresh();
    if (!epic1) {
      final st = container.read(deskProvider).settings;
      await n.saveSettings(st.copyWith(payments: st.payments.copyWith(epic1: false)));
    }
  });
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

Finder get _input => find.descendant(of: find.byKey(const ValueKey('home-field')), matching: find.byType(EditableText));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.showKeyboard(_input);
  tester.testTextInput.enterText(text);
  await tester.pump();
  // The fee is asked once typing pauses.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump(const Duration(milliseconds: 300));
}

String _line(WidgetTester tester) => tester.widgetList<Text>(find.descendant(of: find.byKey(const ValueKey('home-field-preview')), matching: find.byType(Text))).map((t) => t.data ?? '').join(' | ');

void main() {
  group('classic', () {
    testWidgets('"4 anna" says what Enter does and opens Send to Anna with 4', (tester) async {
      final container = await _open(tester);
      await _type(tester, '4 anna');
      expect(_line(tester), contains('Send'));
      expect(_line(tester), contains('Anna Kowalska'));
      await _enter(tester);
      final at = container.read(deskNavProvider);
      expect(at.route, DeskRoute.send);
      final a = at.arg as SendArgs;
      expect(a.contact?.name, 'Anna Kowalska');
      expect(a.amount, '4');
      await _end(tester);
    });

    testWidgets('the words around a name and "for" a message', (tester) async {
      final container = await _open(tester);
      await _type(tester, 'send 5.5 epic to anna for lunch');
      await _enter(tester);
      final a = container.read(deskNavProvider).arg as SendArgs;
      expect(a.contact?.name, 'Anna Kowalska');
      expect(a.amount, '5.5');
      expect(a.message, 'lunch');
      await _end(tester);
    });

    testWidgets('an address opens Send with it; a half address says what is missing and Enter does nothing', (tester) async {
      final container = await _open(tester);
      await _type(tester, '3 esMASi45ub7Qe4ZE36UT5G6cU4ud8Fhhe4deS4F3cw9KTAb8dLcu@epicbox.example.org');
      expect(find.byKey(const ValueKey('home-field-detail')), findsOneWidget);
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      expect((container.read(deskNavProvider).arg as SendArgs).recipient, startsWith('esMASi'));
      container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
      await tester.pump(const Duration(milliseconds: 300));
      await _type(tester, 'esMASi45ub7Qe4ZE');
      expect(_line(tester), isNot(contains('Send |')));
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.overview);
      await _end(tester);
    });

    testWidgets('nothing matches: the line says so, Enter does nothing, To is untouched', (tester) async {
      final container = await _open(tester);
      await _type(tester, 'xyzzy');
      expect(_l.deskHomeNoMatch('xyzzy'), "No contact or address matches 'xyzzy'");
      expect(find.text(_l.deskHomeNoMatch('xyzzy')), findsWidgets);
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.overview);
      await _end(tester);
    });

    testWidgets('more than spendable: the line says so and Enter does nothing', (tester) async {
      final container = await _open(tester);
      await _type(tester, '9999999 anna');
      expect(find.textContaining('More than spendable'), findsWidgets);
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.overview);
      await _end(tester);
    });

    testWidgets('an amount within the balance shows the fee and the balance after', (tester) async {
      await _open(tester);
      await _type(tester, '5 anna');
      expect(find.byKey(const ValueKey('home-field-note')), findsOneWidget);
      final note = tester.widget<Text>(find.byKey(const ValueKey('home-field-note'))).data;
      expect(note, contains('Fee'));
      // The whole balance (1,224.4451) less 5 and the fee, as Send's summary shows it.
      expect(note, contains('Balance after 1,219.4'));
      await _end(tester);
    });

    testWidgets('"anna max" opens Send to Anna with the max flag', (tester) async {
      final container = await _open(tester);
      await _type(tester, 'anna max');
      await _enter(tester);
      final a = container.read(deskNavProvider).arg as SendArgs;
      expect(a.contact?.name, 'Anna Kowalska');
      expect(a.all, isTrue);
      await _end(tester);
    });

    testWidgets('"request 5 from anna" opens Request with 5', (tester) async {
      final container = await _open(tester);
      await _type(tester, 'request 5 from anna');
      await _enter(tester);
      final at = container.read(deskNavProvider);
      expect(at.route, DeskRoute.invoiceIssue);
      expect((at.arg as RequestArgs).amount, '5');
      await _end(tester);
    });

    testWidgets('a bare amount opens Send with it', (tester) async {
      final container = await _open(tester);
      await _type(tester, '12,5');
      await _enter(tester);
      expect((container.read(deskNavProvider).arg as SendArgs).amount, '12.5');
      await _end(tester);
    });

    testWidgets('Tab writes the name, ↑ ↓ choose, Esc clears', (tester) async {
      await _open(tester);
      await _type(tester, '4 ann');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.widget<EditableText>(_input).controller.text, '4 Anna Kowalska');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.widget<EditableText>(_input).controller.text, isEmpty);
      await _type(tester, 'm');
      final first = _line(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_line(tester), isNot(first));
      await _end(tester);
    });
  });

  group('epic1 off', () {
    testWidgets('an amount and an epic1 code: the line says epic1 is off; Enter opens Send, which stops', (tester) async {
      final container = await _open(tester, epic1: false);
      await _type(tester, '10 $_e1Link');
      expect(_line(tester), contains(_l.netBlockMethodOff(_l.deskE1SetSwitch)));
      await _enter(tester);
      final nav = container.read(deskNavProvider);
      expect(nav.route, DeskRoute.send);
      expect((nav.arg as SendArgs).code, _e1Link);
      await _end(tester);
    });

    testWidgets('a classic payment request code opens Send with the code', (tester) async {
      final container = await _open(tester, epic1: false);
      await _type(tester, _classicRequest);
      expect(_line(tester), contains(_l.deskHomeOpenCode));
      await _enter(tester);
      final nav = container.read(deskNavProvider);
      expect(nav.route, DeskRoute.send);
      expect((nav.arg as SendArgs).code, _classicRequest);
      await _end(tester);
    });

    testWidgets('a contact with only an epic1 link has no epic1 line', (tester) async {
      await _open(tester, epic1: false, extra: Contact(id: '', name: 'Epic One', epic1: _e1Link));
      await _type(tester, '4 epic one');
      expect(_line(tester), isNot(contains(_l.deskE1LinkTitle)));
      await _end(tester);
    });
  });

  group('epic1 on beside the classic methods', () {
    const link = 'epic:epic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9?server=https://pay.example.net';
    Future<ProviderContainer> openWithE1Contact(WidgetTester tester) => _open(tester, epic1: true, extra: Contact(id: '', name: 'Epic One', epic1: link));

    testWidgets('"4 epic one" opens Send with the contact and the amount; the line names the link', (tester) async {
      final container = await openWithE1Contact(tester);
      await _type(tester, '4 epic one');
      expect(_line(tester), contains('epic1 link'));
      await _enter(tester);
      final a = container.read(deskNavProvider).arg as SendArgs;
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      expect(a.contact?.name, 'Epic One');
      expect(a.amount, '4');
      await _end(tester);
    });

    testWidgets('"epic one max" hands over the figure, not the flag', (tester) async {
      final container = await openWithE1Contact(tester);
      await _type(tester, 'epic one max');
      await _enter(tester);
      final a = container.read(deskNavProvider).arg as SendArgs;
      expect(a.all, isFalse);
      expect(a.amount, isNotNull);
      await _end(tester);
    });

    testWidgets('a contact with a classic address is paid through it, epic1 on', (tester) async {
      final container = await _open(tester);
      await _type(tester, '4 anna');
      expect(_line(tester), isNot(contains(_l.deskE1LinkTitle)));
      await _enter(tester);
      final a = container.read(deskNavProvider).arg as SendArgs;
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      expect(a.contact?.name, startsWith('Anna'));
      await _end(tester);
    });

    testWidgets('a classic address and an epic1 link are both taken in one session', (tester) async {
      final container = await _open(tester);
      await _type(tester, '3 esMASi45ub7Qe4ZE36UT5G6cU4ud8Fhhe4deS4F3cw9KTAb8dLcu@epicbox.example.org');
      expect(_line(tester), isNot(contains(_l.netBlockMethodOff(_l.deskE1SetSwitch))));
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
      await tester.pump(const Duration(milliseconds: 100));
      await _type(tester, '10 $_e1Link');
      await _enter(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      expect((container.read(deskNavProvider).arg as SendArgs).recipient, _e1Link);
      await _end(tester);
    });

    for (final typed in ['10 $_e1Link', '$_e1Link 10', 'send 10 to $_e1Link']) {
      testWidgets('"$typed": an amount and an epic1 code open the epic1 page with both', (tester) async {
        final container = await _open(tester, epic1: true);
        await _type(tester, typed);
        expect(_line(tester), contains('10'));
        expect(find.byKey(const ValueKey('home-field-problem')), findsNothing);
        await _enter(tester);
        final nav = container.read(deskNavProvider);
        expect(nav.route, DeskRoute.send);
        final a = nav.arg as SendArgs;
        expect(a.recipient, _e1Link);
        expect(a.amount, isNotNull);
        await _end(tester);
      });
    }

    for (final typed in ['10 $_e1Addr', '$_e1Addr 10', _e1Addr]) {
      testWidgets('"$typed": a bare epic1 address is refused as Send refuses it, Enter does nothing', (tester) async {
        final container = await _open(tester, epic1: true);
        await _type(tester, typed);
        expect(_line(tester), contains(_l.epic1AddressAlone));
        await _enter(tester);
        expect(container.read(deskNavProvider).route, DeskRoute.overview);
        await _end(tester);
      });
    }

    testWidgets('a classic payment request code opens Send with the code, epic1 on', (tester) async {
      final container = await _open(tester);
      await _type(tester, _classicRequest);
      expect(_line(tester), contains(_l.deskHomeOpenCode));
      await _enter(tester);
      expect((container.read(deskNavProvider).arg as SendArgs).code, _classicRequest);
      await _end(tester);
    });
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
