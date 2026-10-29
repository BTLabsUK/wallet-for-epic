// SPDX-License-Identifier: Apache-2.0
// Wave 2 keyboard rules (widgets/keyboard.dart): Tab visits a form's fields in visual order,
// then its main button, then wraps, never an icon; Enter moves to the next field and runs the
// main action from the last one; Esc closes the top-most thing; Back/Forward by mouse buttons,
// Alt+arrows and Backspace outside a text field, wizard steps first.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_wallets_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/data/server_lists.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_label.dart' show TxPen;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

/// A test network's wallet layer: one Epicbox server of its own.
class _Floonet extends MockDeskWallet {
  _Floonet() : super(delay: Duration.zero);

  @override
  Future<List<EpicboxServer>> epicboxes() async => [EpicboxServer(domain: 'epicbox.btlabs.uk', port: 443, health: ServiceHealth.ok)];
}

Future<ProviderContainer> _open(WidgetTester tester, DeskRoute route, {Object? arg, MockDeskWallet? api}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api ?? MockDeskWallet(delay: Duration.zero))], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.runAsync(() => advancedOn(container));
  container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

/// What has the keyboard focus, by the control's kind and label.
String _focused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return 'none';
  String? name;
  ctx.visitAncestorElements((e) {
    final w = e.widget;
    name = switch (w) {
      EInput() => 'field:${w.semanticLabel ?? w.hint}',
      EButton() => 'button:${w.label}',
      EIconButton() => 'icon:${w.label}',
      ELink() => 'link:${w.label}',
      ESelect() => 'select:${w.semanticLabel}',
      ECheckbox() => 'check:${w.label}',
      EChoiceCard() => 'card:${w.title}',
      ESwitch() => 'switch:${w.label ?? w.semanticLabel}',
      ESegmented() => 'segment',
      ServerListPanel() => 'combo:${w.label}',
      EDetails() => 'details',
      ENavItem() => 'nav:${w.label}',
      TxPen() => 'pen:${w.label}',
      _ => null,
    };
    return name == null;
  });
  return name ?? 'other:${ctx.widget.runtimeType}';
}

Finder _input(String label) => find.byWidgetPredicate((w) => w is EInput && (w.semanticLabel ?? w.hint ?? '').startsWith(label));

Finder _edit(String label) => find.descendant(of: _input(label), matching: find.byType(EditableText));

Future<void> _focus(WidgetTester tester, Finder edit) async {
  tester.widget<EditableText>(edit).focusNode.requestFocus();
  await tester.pump();
}

/// Focuses the closed button of the server list.
Future<void> _focusPanel(WidgetTester tester) async {
  tester.widget<FocusableActionDetector>(find.descendant(of: find.byType(ServerListPanel), matching: find.byType(FocusableActionDetector)).first).focusNode!.requestFocus();
  await tester.pump();
}

/// [n] presses of Tab (Shift+Tab with [back]) from [edit]; the focus after each.
Future<List<String>> _tabs(WidgetTester tester, Finder edit, int n, {bool back = false}) async {
  await _focus(tester, edit);
  final out = <String>[];
  for (var i = 0; i < n; i++) {
    if (back) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (back) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    out.add(_focused());
  }
  return out;
}

/// No secondary control in a Tab sequence.
Matcher get _noSecondary => everyElement(isNot(anyOf(startsWith('icon:'), startsWith('link:'), equals('button:Back'), equals('button:Cancel'))));

Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.enterText(_edit(label), text);
  await tester.pump();
}

/// Enter in the focused text field (the platform's text action).
Future<void> _enter(WidgetTester tester, [TextInputAction action = TextInputAction.done]) async {
  await tester.testTextInput.receiveAction(action);
  await _settle(tester, 4);
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key, {bool alt = false}) async {
  if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await _settle(tester, 4);
}

/// A key the test key maps lack (the keyboard's Back / Forward), down and up straight to the handlers.
Future<void> _hwKey(WidgetTester tester, LogicalKeyboardKey logical, PhysicalKeyboardKey physical) async {
  final t = Duration.zero;
  HardwareKeyboard.instance.handleKeyEvent(KeyDownEvent(physicalKey: physical, logicalKey: logical, timeStamp: t));
  HardwareKeyboard.instance.handleKeyEvent(KeyUpEvent(physicalKey: physical, logicalKey: logical, timeStamp: t));
  await _settle(tester, 4);
}

Future<void> _mouse(WidgetTester tester, int buttons) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: buttons);
  await g.down(const Offset(640, 400));
  await g.up();
  await _settle(tester, 4);
}

void main() {
  group('Tab order', () {
    testWidgets('Create: Password, Confirm, Create wallet, the name pen; Shift+Tab reverses', (tester) async {
      await _open(tester, DeskRoute.create);
      await _type(tester, 'Password', 'longpassword');
      await _type(tester, 'Confirm password', 'longpassword');
      final fwd = await _tabs(tester, _edit('Password'), 3);
      // The wallet's name sits in the title, its pen the first stop (a Tab from the last wraps there).
      expect(fwd, ['field:Confirm password', 'button:Create wallet', 'pen:Edit wallet name']);
      final back = await _tabs(tester, _edit('Password'), 3, back: true);
      expect(back, ['pen:Edit wallet name', 'button:Create wallet', 'field:Confirm password']);
      await _end(tester);
    });

    testWidgets('Unlock: Wallet, Password, Remember, Unlock, Forgot password?, Add a wallet, wrap; never the eye', (tester) async {
      await _open(tester, DeskRoute.unlock);
      final tabs = await _tabs(tester, _edit('Password'), 6);
      // Forgot password? and Add a wallet stay reachable for keyboard-only users, after the main button.
      expect(tabs, ['check:Remember on this computer', 'button:Unlock', 'link:Forgot password?', 'link:Add a wallet', 'select:Wallet', 'field:Password']);
      await _end(tester);
    });

    testWidgets('Send: To, Amount, Message, then Review send before the sidebar', (tester) async {
      await _open(tester, DeskRoute.send);
      await _type(tester, 'Recipient', 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com');
      await _type(tester, 'Amount', '1');
      final tabs = await _tabs(tester, _edit('Recipient'), 8);
      // Contacts and All are the stops right after their fields; paste and clear are not. The
      // address is the BT Labs contact: its card's Clear comes next; the Advanced disclosure
      // follows Message.
      expect(tabs.take(7), ['button:Contacts', 'button:Clear', 'field:Amount in EPIC', 'button:Max', 'field:Message', 'details', 'button:Review']);
      expect(tabs.last, startsWith('nav:'), reason: 'the sidebar comes after the form');
      expect(tabs, _noSecondary);
      await _end(tester);
    });

    testWidgets('Contact form: Name, Address, Note, Save contact; never the picture or Cancel buttons', (tester) async {
      await _open(tester, DeskRoute.contacts, arg: const ContactsArgs(adding: true));
      final tabs = await _tabs(tester, find.descendant(of: find.byType(EInput).at(1), matching: find.byType(EditableText)), 4);
      expect(tabs.take(3).toList(), [isNot(startsWith('nav:')), anything, anything]);
      final name = _focusOrder(tabs);
      expect(name, containsAllInOrder(['field:null', 'button:Save contact']));
      expect(tabs, _noSecondary);
      await _end(tester);
    });

    testWidgets('Setup › Epicbox on a test network starts on its own server (LNX-6)', (tester) async {
      await _open(tester, DeskRoute.setup, arg: SetupStep.epicbox, api: _Floonet());
      expect(find.text('epicbox.btlabs.uk'), findsWidgets);
      expect(find.text('epicbox.epiccash.com'), findsNothing);
      await _end(tester);
    });

    testWidgets('Setup › Epicbox: the server, then Continue, then the switch', (tester) async {
      await _open(tester, DeskRoute.setup, arg: SetupStep.epicbox);
      await _focusPanel(tester);
      expect(_focused(), 'combo:Epicbox server');
      final tabs = <String>[];
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        tabs.add(_focused());
      }
      expect(tabs, ['button:Continue', 'switch:Receive through Epicbox']);
      await _end(tester);
    });

    testWidgets('Import › old password: the field, Import, then Skip; never Back', (tester) async {
      await _open(tester, DeskRoute.importWallets, arg: ImportStep.import);
      final tabs = await _tabs(tester, _edit('Old password'), 2);
      // Skip comes after the main button.
      expect(tabs.take(2), ['button:Import', 'button:Skip']);
      expect(tabs, _noSecondary);
      await _end(tester);
    });

    for (final (route, label) in [
      (DeskRoute.settingsAccount, 'Label'),
      (DeskRoute.settingsReceiving, 'HTTP port'),
    ]) {
      testWidgets('Settings ${route.name}: no icon is a Tab stop', (tester) async {
        await _open(tester, route);
        final tabs = await _tabs(tester, _edit(label), 12);
        // The page's stops, up to the sidebar (its lock and switch icons are not a form's).
        expect(tabs.takeWhile((t) => !t.startsWith('nav:')), _noSecondary);
        await _end(tester);
      });
    }

    testWidgets('Settings › Node: from the node field no icon is a Tab stop', (tester) async {
      await _open(tester, DeskRoute.settingsNode);
      // The closed combo is a button: no text field to focus.
      expect(find.descendant(of: find.byType(ServerListPanel), matching: find.byType(EditableText)), findsNothing);
      tester.widget<FocusableActionDetector>(find.descendant(of: find.byType(ServerListPanel), matching: find.byType(FocusableActionDetector)).first).focusNode!.requestFocus();
      await tester.pump();
      expect(_focused(), 'combo:Node server');
      final tabs = <String>[];
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        tabs.add(_focused());
      }
      expect(tabs.takeWhile((t) => !t.startsWith('nav:')), _noSecondary);
      await _end(tester);
    });
  });

  group('Enter', () {
    testWidgets('Create: Enter in Password goes to Confirm; in Confirm it creates only when valid', (tester) async {
      await _open(tester, DeskRoute.create);
      await _type(tester, 'Password', 'longpassword');
      await _focus(tester, _edit('Password'));
      await _enter(tester, TextInputAction.next);
      expect(_focused(), 'field:Confirm password');

      await _type(tester, 'Confirm password', 'different1');
      await _enter(tester);
      expect(find.text('Create wallet'), findsWidgets, reason: 'invalid: nothing happens');
      expect(_focused(), 'field:Confirm password', reason: 'the focus stays to fix it');

      await _type(tester, 'Confirm password', 'longpassword');
      await _enter(tester);
      await _settle(tester, 30);
      expect(find.text('Recovery phrase'), findsWidgets);
      await _end(tester);
    });

    testWidgets('Contact form: Enter in Name goes to Address; in Address it saves, showing errors when invalid', (tester) async {
      await _open(tester, DeskRoute.contacts, arg: const ContactsArgs(adding: true));
      final name = find.descendant(of: find.byType(EInput).at(1), matching: find.byType(EditableText));
      await tester.enterText(name, 'Alice');
      await _focus(tester, name);
      await _enter(tester, TextInputAction.next);
      final address = find.descendant(of: find.byType(EInput).at(2), matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(address).focusNode.hasFocus, isTrue);
      await tester.enterText(address, 'not an address');
      await _enter(tester);
      expect(find.text('Contact not saved'), findsNothing);
      expect(find.text('New contact'), findsWidgets, reason: 'still on the form, the error shown');
      await _end(tester);
    });

    testWidgets('Setup › Epicbox: Enter on the server opens its list', (tester) async {
      await _open(tester, DeskRoute.setup, arg: SetupStep.epicbox);
      await _focusPanel(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const ValueKey('server-list-field')), findsOneWidget, reason: 'the list is open');
      expect(find.text('Review settings'), findsNothing);
      await _key(tester, LogicalKeyboardKey.escape);
      await _end(tester);
    });

    testWidgets('Send: Enter in Amount opens the review dialog, never the send itself', (tester) async {
      final container = await _open(tester, DeskRoute.send);
      await _type(tester, 'Recipient', 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com');
      await _type(tester, 'Amount', '1');
      await _focus(tester, _edit('Amount'));
      await _enter(tester);
      await _settle(tester, 20);
      expect(find.byType(Dialog), findsOneWidget, reason: 'the confirmation is open');
      expect(container.read(deskProvider.notifier).sending, 0, reason: 'nothing sent yet');
      await _end(tester);
    });

    testWidgets('Delete wallet: Enter in the password does nothing until the box is ticked', (tester) async {
      final container = await _open(tester, DeskRoute.settingsAccount);
      showDeleteWalletDialog(tester.element(find.byType(EPage)));
      await _settle(tester);
      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(EditableText)), 'password');
      await _enter(tester);
      expect(find.text('Delete this wallet?'), findsOneWidget);
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAccount, reason: 'nothing was deleted, no place changed');
      expect(container.read(deskProvider).account, isNotNull, reason: 'the wallet is still open');
      await _end(tester);
    });
  });

  group('Esc', () {
    testWidgets('closes a tooltip first, then the dialog under it; with nothing open it does nothing', (tester) async {
      final container = await _open(tester, DeskRoute.settingsAccount);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAccount);

      showEDialog(
        tester.element(find.byType(EPage)),
        dismissible: false,
        builder: (_) => const EDialog(title: 'Test', body: Tooltip(message: 'Tip', child: Text('Hover'))),
      );
      await _settle(tester);
      final tip = tester.state<TooltipState>(find.byType(Tooltip).last);
      tip.ensureTooltipVisible();
      await _settle(tester);
      expect(find.text('Tip'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.text('Tip'), findsNothing);
      expect(find.text('Test'), findsOneWidget, reason: 'one Esc closes one thing');

      await _key(tester, LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.text('Test'), findsNothing, reason: 'a dialog showing Close closes on Esc even without a dismissing barrier');
      await _end(tester);
    });

    testWidgets('folds an open panel on the page; in a dialog it closes the dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: const Scaffold(body: EDetails(title: 'More', initiallyOpen: true, child: Text('Inside'))),
        ),
      );
      // The focus in the panel's head (Tab), then Esc.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'details');
      expect(find.text('Inside'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle(); // the fold-out closes over Motion.expand (ExpandFade)
      expect(find.text('Inside'), findsNothing);

      showEDialog(
        tester.element(find.byType(EDetails)),
        builder: (_) => const EDialog(title: 'Dlg', body: EDetails(title: 'Inner', initiallyOpen: true, child: Text('Deep'))),
      );
      await _settle(tester);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'details');
      await _key(tester, LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.text('Dlg'), findsNothing);
    });
  });

  group('Back and Forward', () {
    test('history: de-dup, back, forward, a new place drops forward', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final nav = c.read(deskNavProvider.notifier);
      nav.reset(DeskRoute.overview);
      nav.go(DeskRoute.activity);
      nav.go(DeskRoute.activity);
      nav.go(DeskRoute.send);
      nav.back();
      expect(c.read(deskNavProvider).route, DeskRoute.activity);
      nav.back();
      expect(c.read(deskNavProvider).route, DeskRoute.overview, reason: 'the same place twice is one step');
      expect(nav.canBack, isFalse);
      nav.forward();
      nav.forward();
      expect(c.read(deskNavProvider).route, DeskRoute.send);
      nav.back();
      nav.go(DeskRoute.contacts);
      expect(nav.canForward, isFalse);
      nav.reset(DeskRoute.settingsNode);
      nav.back();
      expect(c.read(deskNavProvider).route, DeskRoute.overview, reason: 'Back ends on Overview');
    });

    testWidgets('mouse buttons 8/16, Alt+Left/Right and Backspace move through the history', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      DeskRoute at() => container.read(deskNavProvider).route;
      container.read(deskNavProvider.notifier).go(DeskRoute.activity);
      await _settle(tester);
      await _mouse(tester, kBackMouseButton);
      expect(at(), DeskRoute.overview);
      await _mouse(tester, kForwardMouseButton);
      expect(at(), DeskRoute.activity);
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(at(), DeskRoute.overview);
      await _key(tester, LogicalKeyboardKey.arrowRight, alt: true);
      expect(at(), DeskRoute.activity);
      FocusManager.instance.primaryFocus?.unfocus();
      await _key(tester, LogicalKeyboardKey.backspace);
      expect(at(), DeskRoute.overview);
      await _end(tester);
    });

    testWidgets('Backspace in a text field deletes and stays', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.send);
      await _settle(tester);
      await _type(tester, 'Amount', '12');
      await _focus(tester, _edit('Amount'));
      await _key(tester, LogicalKeyboardKey.backspace);
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      expect(tester.widget<EditableText>(_edit('Amount')).controller.text, '1', reason: 'Backspace edited the text');
      await _end(tester);
    });

    testWidgets('with a dialog open Back does nothing', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.settingsAccount);
      await _settle(tester);
      showDeleteWalletDialog(tester.element(find.byType(EPage)));
      await _settle(tester);
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAccount);
      expect(find.text('Delete this wallet?'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('a wizard goes one step back first; the phrase step holds Back', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.setup, SetupStep.epicbox);
      await _settle(tester);
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(find.text('Choose a node'), findsOneWidget);
      expect(container.read(deskNavProvider).route, DeskRoute.setup);
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(find.text('Preferences'), findsWidgets, reason: 'the language step comes first');
      expect(container.read(deskNavProvider).route, DeskRoute.setup);
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(container.read(deskNavProvider).route, DeskRoute.overview);

      container.read(deskNavProvider.notifier).go(DeskRoute.create, CreateStep.phrase);
      await _settle(tester);
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.create);
      expect(find.text('Recovery phrase'), findsWidgets);
      await _end(tester);
    });

    testWidgets('Restore: typed words hold Back', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.restore, RestoreStep.wordsFilled);
      await _settle(tester);
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.restore, reason: 'typed words are not thrown away');
      await _end(tester);
    });

    testWidgets('Restore: Back on the password step goes back to the phrase', (tester) async {
      final container = await _open(tester, DeskRoute.restore, arg: RestoreStep.account);
      expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.restore);
      expect(find.byKey(const ValueKey('wallet-name-title')), findsNothing, reason: 'back on the phrase step');
      await _end(tester);
    });
  });

  group('Settings combo', () {
    Future<void> pumpCombo(WidgetTester tester, {bool busy = false, ValueChanged<String>? onPicked}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 500,
                  child: _panel(busy: busy, onPicked: onPicked),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Finder closedField() => find.descendant(of: find.byType(ServerListPanel), matching: find.byType(EditableText));

    testWidgets('the closed combo is a button with no text field; Esc and a pick leave nothing selected', (tester) async {
      String? picked;
      await pumpCombo(tester, onPicked: (v) => picked = v);
      expect(closedField(), findsNothing, reason: 'no TextField in the closed state');
      await tester.tap(find.text('a.example'));
      await tester.pump();
      expect(find.text('b.example', findRichText: true), findsOneWidget, reason: 'the list is open');
      expect(find.byType(EditableText), findsOneWidget, reason: 'the search field at the top of the list');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.text('b.example', findRichText: true), findsNothing, reason: 'Esc closed it');
      expect(closedField(), findsNothing);

      await tester.pump(const Duration(milliseconds: 500)); // not a double tap
      await tester.tap(find.text('a.example'));
      await tester.pump();
      await tester.tap(find.text('b.example', findRichText: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Switch to b.example?'), findsOneWidget, reason: 'an Epicbox pick asks first');
      await tester.tap(find.byKey(const ValueKey('server-list-switch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(picked, 'b.example');
      expect(closedField(), findsNothing);
    });

    testWidgets('Space, Enter and ↓ on the focused button open the list', (tester) async {
      for (final k in [LogicalKeyboardKey.space, LogicalKeyboardKey.enter, LogicalKeyboardKey.arrowDown]) {
        await pumpCombo(tester);
        tester.widget<FocusableActionDetector>(find.descendant(of: find.byType(ServerListPanel), matching: find.byType(FocusableActionDetector)).first).focusNode!.requestFocus();
        await tester.pump();
        await _key(tester, k);
        await tester.pump();
        expect(find.text('b.example', findRichText: true), findsOneWidget, reason: k.keyLabel);
        await _key(tester, LogicalKeyboardKey.escape);
      }
    });

    testWidgets('while busy the chevron stays and Checking… shows; after the timeout No answer yet', (tester) async {
      await pumpCombo(tester, busy: true);
      expect(find.byIcon(EIcons.chevronDown), findsOneWidget);
      expect(find.text('Checking…'), findsOneWidget);
      expect(find.byType(ESpinner), findsNothing, reason: 'no spinner in the field');
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('No answer yet'), findsOneWidget);
      expect(find.byIcon(EIcons.chevronDown), findsOneWidget);
    });
  });

  for (final (platform, key, shift, ctrl, alt, hint) in [
    (TargetPlatform.windows, LogicalKeyboardKey.f8, false, false, true, 'Alt+F8'),
    (TargetPlatform.linux, LogicalKeyboardKey.keyP, true, true, false, 'Ctrl+Shift+P'),
  ]) {
    testWidgets('${platform.name}: $hint in a password field shows and hides it; the eye tooltip names it', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: EPasswordInput(semanticLabel: 'P'))));
        await tester.tap(find.byType(EditableText));
        await tester.pump();
        bool obscured() => tester.widget<EditableText>(find.byType(EditableText)).obscureText;
        expect(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Show ($hint)'), findsOneWidget);
        expect(obscured(), isTrue);
        Future<void> press() async {
          if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
          await tester.sendKeyEvent(key);
          if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
          if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
        }

        await press();
        expect(obscured(), isFalse);
        await press();
        expect(obscured(), isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  group('Copy buttons, trailing buttons', () {
    testWidgets('a labelled copy button is a Tab stop; an icon-only one is not', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: FocusTraversalGroup(
              child: Column(
                children: [
                  const EInput(semanticLabel: 'First'),
                  const ECopyButton(text: 'x', label: 'Copy address', withLabel: true),
                  const ECopyButton(text: 'y', label: 'Copy icon'),
                  const ECopyButton(text: 'z', label: 'Copy forced', tabStop: true),
                ],
              ),
            ),
          ),
        ),
      );
      await _focus(tester, find.byType(EditableText));
      final seen = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        seen.add(_focused());
      }
      expect(seen, ['button:Copy address', 'icon:Copy forced', 'field:First']);
      await _end(tester);
    });
  });

  group('Back details', () {
    testWidgets('Alt+Left in a text field does not go back; Backspace edits', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.send);
      await _settle(tester);
      await _focus(tester, _edit('Amount'));
      await _key(tester, LogicalKeyboardKey.arrowLeft, alt: true);
      expect(container.read(deskNavProvider).route, DeskRoute.send);
      await _end(tester);
    });

    testWidgets('a half-filled Send form holds mouse Back; an empty one lets it go', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.send);
      await _settle(tester);
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.overview, reason: 'empty form: Back goes');
      container.read(deskNavProvider.notifier).go(DeskRoute.send);
      await _settle(tester);
      await _type(tester, 'Amount', '3');
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.send, reason: 'typed amount: Back stays');
      expect(tester.widget<EditableText>(_edit('Amount')).controller.text, '3');
      await _end(tester);
    });

    testWidgets('a typed Contact form holds Back', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.contacts, const ContactsArgs(adding: true));
      await _settle(tester);
      final name = find.descendant(of: find.byType(EInput).at(1), matching: find.byType(EditableText));
      await tester.enterText(name, 'Al');
      await tester.pump();
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.contacts);
      await _end(tester);
    });

    testWidgets('typed passwords hold Back on Create', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.create);
      await _settle(tester);
      await _type(tester, 'Password', 'abc');
      await _mouse(tester, kBackMouseButton);
      expect(container.read(deskNavProvider).route, DeskRoute.create);
      await _end(tester);
    });

    testWidgets('the keyboard Back and Forward keys go through the history', (tester) async {
      final container = await _open(tester, DeskRoute.overview);
      container.read(deskNavProvider.notifier).go(DeskRoute.activity);
      await _settle(tester);
      await _hwKey(tester, LogicalKeyboardKey.browserBack, PhysicalKeyboardKey.browserBack);
      await _settle(tester, 4);
      expect(container.read(deskNavProvider).route, DeskRoute.overview);
      await _hwKey(tester, LogicalKeyboardKey.browserForward, PhysicalKeyboardKey.browserForward);
      await _settle(tester, 4);
      expect(container.read(deskNavProvider).route, DeskRoute.activity);
      await _end(tester);
    });

    testWidgets('the screen that holds the focus answers Back; a screen with tickers off never does', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DeskStepBack(onBack: () => log.add('first'), child: const TextField(key: Key('a'))),
                TickerMode(
                  enabled: false,
                  child: DeskStepBack(onBack: () => log.add('leaving'), child: const SizedBox()),
                ),
                DeskStepBack(onBack: () => log.add('last'), child: const TextField(key: Key('b'))),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('a')));
      await tester.pump();
      expect(DeskStepBack.tryStepBack(), isTrue);
      expect(log, ['first'], reason: 'the focused screen, not the most recent one');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(DeskStepBack.tryStepBack(), isTrue);
      expect(log, ['first', 'last'], reason: 'no focus: the most recent running one');
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(enabled: false, child: DeskStepBack(onBack: () => log.add('leaving'), child: const SizedBox())),
        ),
      );
      expect(DeskStepBack.tryStepBack(), isFalse, reason: 'a leaving screen catches nothing');
      expect(log, ['first', 'last']);
    });
  });

  group('Hardware Enter, Esc in combo', () {
    // A plain Enter reaches a single-line field as the platform's text action (the tests above);
    // Ctrl+Enter is a key event the form handles itself.
    testWidgets('Setup › Epicbox: the Ctrl+Enter key event continues', (tester) async {
      await _open(tester, DeskRoute.setup, arg: SetupStep.epicbox);
      await _focusPanel(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester, 6);
      expect(find.text('Review settings'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('Esc on an open combo in a dialog closes the combo first, then the dialog', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SizedBox()))));
      final ctx = tester.element(find.byType(Scaffold));
      showDialog<void>(
        context: ctx,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 500,
            height: 300,
            child: _panel(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('a.example'));
      await tester.pump();
      expect(find.text('b.example', findRichText: true), findsOneWidget, reason: 'the list is open');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.text('b.example', findRichText: true), findsNothing, reason: 'the first Esc closed the list');
      expect(find.byType(Dialog), findsOneWidget, reason: 'the dialog is still there');
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing, reason: 'the second Esc closed the dialog');
    });
  });
}

/// The sequence with repeats after the first wrap dropped.
List<String> _focusOrder(List<String> tabs) => [...{...tabs}];

/// A two-row Epicbox list, a.example in use.
Widget _panel({bool busy = false, ValueChanged<String>? onPicked}) => ServerListPanel(
  kind: ServerKind.relay,
  label: 'Node server',
  value: 'a.example',
  fieldText: 'a.example',
  servers: const [PanelServer(value: 'a.example', host: 'a.example'), PanelServer(value: 'b.example', host: 'b.example')],
  source: const DeskServerSource(public: ['a.example', 'b.example']),
  busy: busy,
  busyTimeout: const Duration(seconds: 2),
  onChoose: (v) async => onPicked?.call(v),
  onTest: (_) async => null,
);
