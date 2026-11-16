// SPDX-License-Identifier: Apache-2.0
// epic1 as a payment method on the desktop: its row in Settings › Payments (on by default, applied
// at once); Receive's epic1 panel beside the classic address; Send and Home taking an epic1 link
// and a classic address in one session; the off stop; contacts paid by an epic1 link.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart' show settingsPrefsProvider;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart' show ContactsArgs;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/epic1_hosts.dart' show acceptedRelaysIn;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/payment_prefs.dart' show PaymentPrefs;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show HostSettings, hostSettings;
import 'package:epic_wallet/src/ui/epic1/epic1_sealed.dart' show epic1SealedKey;
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart' show Epic1Text;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

/// The text [s] on stage: plain, or drawn with the epic1 wordmark in place of the word.
Finder _say(String s) => find.byWidgetPredicate((w) => (w is Text && w.data == s) || (w is Epic1Text && w.text == s));

const _link = 'epic:epic1qtestlink0000000000000000000000000000?amount=150000000';

/// The mock wallet with one epic1 payment in the list once [e1State] is set (the fake's first
/// payment is tx 1).
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  TxState? e1State;

  /// That payment was sealed ([Tx.sealed]).
  bool e1Sealed = false;

  @override
  Future<List<Tx>> transactions() async {
    final all = await super.transactions();
    final s = e1State;
    return [
      if (s != null)
        Tx(id: 1, slateId: '00000000-0000-4000-8000-000000000002', direction: TxDirection.sent, state: s, method: TxMethod.epicbox, amount: 150000000, fee: 7000000, cancellable: s == TxState.waitingRecipient, created: DateTime(2026, 11, 9), sealed: e1Sealed),
      ...all,
    ];
  }
}

late ProviderContainer _container;
late _Wallet _wallet;

/// Opens [route]; epic1 is on as it is by default, unless [epic1] is false (switched off in the
/// payment settings).
Future<void> _open(WidgetTester tester, DeskRoute route, {Object? arg, bool epic1 = true, Contact? select}) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = _Wallet();
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    final st = _container.read(deskProvider).settings;
    await n.saveSettings(st.copyWith(tourSeen: true, payments: st.payments.copyWith(epic1: epic1)));
    // A contact to open on its page.
    if (select != null) {
      await n.saveContact(select);
      await n.refresh();
      arg = ContactsArgs(selectedId: _container.read(deskProvider).contacts!.firstWhere((c) => c.name == select.name).id);
    }
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await _settle(tester);
}

/// Pastes the epic1 link into the classic Send form's To field (one change of 8 or more
/// characters is a paste).
Future<void> _pasteLink(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, _link);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await _settle(tester);
}

Finder _field(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));

bool _switchOn(WidgetTester tester) => tester.widget<ESwitch>(find.byKey(const ValueKey('st-offer-epic1'))).value;

bool _saved(bool Function(PaymentPrefs p) read) => read(_container.read(deskProvider).settings.payments);

void main() {
  // "Use server" writes the settings ([acceptedRelaysIn]): each test starts from the same ones.
  late HostSettings saved;
  setUp(() => saved = hostSettings);
  tearDown(() => hostSettings = saved);

  group('Settings › Payments', () {
    testWidgets('the epic1 row follows Epicbox, is on by default and shows the printed links row', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(find.byKey(const ValueKey('st-method-epic1')), findsOneWidget);
      expect(_say(_l.deskE1SetSwitch), findsWidgets);
      expect(_switchOn(tester), isTrue);
      expect(find.byKey(const ValueKey('e1-printed-open')), findsOneWidget);
      // The old exclusive mode is gone.
      expect(find.byKey(const ValueKey('e1-experimental')), findsNothing);
      expect(find.byKey(const ValueKey('e1-applies')), findsNothing);
      expect(find.byKey(const ValueKey('e1-lock-now')), findsNothing);
    });

    testWidgets('turning it off needs no confirm and no relock; the printed row goes', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await _tap(tester, 'st-offer-epic1');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-turn-on-dialog')), findsNothing);
      expect(_saved((p) => p.epic1), isFalse);
      expect(_container.read(deskEpic1OnProvider), isFalse);
      expect(_switchOn(tester), isFalse);
      expect(find.byKey(const ValueKey('e1-printed-open')), findsNothing);

      await _tap(tester, 'st-offer-epic1');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(_saved((p) => p.epic1), isTrue);
      expect(_container.read(deskEpic1OnProvider), isTrue);
      expect(find.byKey(const ValueKey('e1-printed-open')), findsOneWidget);
    });

    testWidgets('off: the row shows the switch off', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, epic1: false);
      expect(_switchOn(tester), isFalse);
      expect(find.byKey(const ValueKey('e1-printed-open')), findsNothing);
    });

    testWidgets('Printed links opens the panel', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await _tap(tester, 'e1-printed-open');
      expect(find.byKey(const ValueKey('e1-printed-panel')), findsOneWidget);
      expect(find.text(_l.deskE1PrintedNone), findsOneWidget);
    });
  });

  group('Receive', () {
    testWidgets('the classic address stays first; the epic1 panel is closed and makes no link', (tester) async {
      await _open(tester, DeskRoute.receive);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('rx-ask-open')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-receive-panel')), findsOneWidget);
      expect(find.text(_l.deskE1LinkTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-link-card')), findsNothing);
      expect(_wallet.epic1Fake.calls, isNot(contains('makeLink')), reason: 'no link before the press');
    });

    testWidgets('Make link shows the link card with Copy link, Ask an amount and In person', (tester) async {
      await _open(tester, DeskRoute.receive);
      await _tap(tester, 'e1-open-link');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-link-card')), findsOneWidget);
      expect(_wallet.epic1Fake.calls, contains('makeLink'));
      expect(find.byKey(const ValueKey('e1-copy-link')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-ask-amount')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-request-in-person')), findsOneWidget);
      // The classic address is still there.
      expect(find.byKey(const ValueKey('rx-ask-open')), findsOneWidget);
    });

    testWidgets('off: no epic1 panel, the classic page as it was', (tester) async {
      await _open(tester, DeskRoute.receive, epic1: false);
      expect(find.byKey(const ValueKey('e1-receive-panel')), findsNothing);
      expect(find.byKey(const ValueKey('e1-link-card')), findsNothing);
      expect(find.byKey(const ValueKey('rx-ask-open')), findsOneWidget);
    });

    testWidgets('switched off in Settings: the panel is gone at once', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await _tap(tester, 'st-offer-epic1');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      _container.read(deskNavProvider.notifier).reset(DeskRoute.receive);
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-receive-panel')), findsNothing);
      expect(find.byKey(const ValueKey('rx-ask-open')), findsOneWidget);
    });
  });

  group('Send', () {
    testWidgets('an epic1 link pasted into the classic form asks first, then review, waiting, Sent', (tester) async {
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      // The classic form is the start.
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsOneWidget);
      expect(find.text(_l.deskE1UnknownServerTitle), findsOneWidget);
      await _tap(tester, 'e1-use-server');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsOneWidget);

      await _tap(tester, 'e1-review');
      expect(find.byKey(const ValueKey('e1-review-panel')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('e1-review-server')), matching: find.textContaining('relay.example.invalid')), findsOneWidget);

      _wallet.e1State = TxState.waitingRecipient;
      await _tap(tester, 'e1-send');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(_wallet.epic1Fake.calls, contains('payLink'));
      expect(find.byKey(const ValueKey('e1-waiting')), findsOneWidget);
      expect(find.text(_l.deskE1Waiting), findsWidgets);
      expect(find.byKey(const ValueKey('e1-try-next')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-cancel-unlock')), findsOneWidget);

      _wallet.e1State = TxState.posted;
      await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-sent')), findsOneWidget);
    });

    testWidgets('a link on a listed server reviews with no question and pays', (tester) async {
      await _open(tester, DeskRoute.send);
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsNothing);
      await _tap(tester, 'e1-review');
      expect(find.byKey(const ValueKey('e1-review-server')), findsOneWidget);

      _wallet.e1State = TxState.waitingRecipient;
      await _tap(tester, 'e1-send');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(_wallet.epic1Fake.calls, contains('payLink'));
      expect(find.byKey(const ValueKey('e1-waiting')), findsOneWidget);
    });

    testWidgets('a link through a listed server the wallet is not on reviews with no question', (tester) async {
      // LEPIC knows only the relay in use; the link names another of the Epicbox list, port written.
      final listed = hostSettings.epicboxServers.last;
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = [Epic1Host(host: listed.host.toUpperCase(), port: listed.port)];
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsNothing);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsOneWidget);
      await _tap(tester, 'e1-review');
      _wallet.e1State = TxState.waitingRecipient;
      await _tap(tester, 'e1-send');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(_wallet.epic1Fake.calls, contains('payLink'));
    });

    testWidgets('"Use server" is kept, the next link through that server asks nothing', (tester) async {
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsOneWidget);
      await _tap(tester, 'e1-use-server');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(acceptedRelaysIn(hostSettings).map((r) => r.label), ['relay.example.invalid']);

      // The next payment, after a restart of the screen: no question.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsNothing);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsOneWidget);
      // Another server still asks.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'other.example.invalid', port: 443)];
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-unknown-server')), findsOneWidget);
    });

    testWidgets('Cancel in the server question leaves the form', (tester) async {
      await _open(tester, DeskRoute.send);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      await _pasteLink(tester);
      await tester.tap(find.text(_l.commonCancel));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-review')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsNothing);
    });

    testWidgets('Send opened with a link shows it in the field, ready to review', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: _link));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(tester.widget<EditableText>(_field('e1-send-to')).controller.text, _link);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsOneWidget);
      await _tap(tester, 'e1-review');
      expect(find.byKey(const ValueKey('e1-review-panel')), findsOneWidget);
    });

    testWidgets('a link behind https:// is the link', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'https://$_link'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(tester.widget<EditableText>(_field('e1-send-to')).controller.text, _link);
    });

    testWidgets('To cleared goes back to the classic form; typed empty, the amount stays', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: _link));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      await _tap(tester, 'e1-clear');
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byKey(const ValueKey('e1-review')), findsNothing);

      const open = 'epic:epic1qtestlink0000000000000000000000000000';
      _container.read(deskNavProvider.notifier).reset(DeskRoute.send, const SendArgs(code: open));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      await tester.enterText(_field('e1-amount'), '2,5');
      await tester.enterText(_field('e1-send-to'), '');
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '2,5'), findsOneWidget);
    });

    testWidgets('an amount from Home opens the classic Send with it', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(amount: '12,5'));
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '12,5'), findsOneWidget);
    });

    testWidgets('a classic address and an epic1 link in one session: each opens its own flow', (tester) async {
      await _open(tester, DeskRoute.send);
      final anna = _container.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c1');
      await tester.enterText(find.byType(EditableText).first, anna.address);
      await _settle(tester);
      // The classic address stays in the classic form, with no mode line.
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byKey(const ValueKey('e1-mode-dialog')), findsNothing);

      _container.read(deskNavProvider.notifier).reset(DeskRoute.send, const SendArgs(code: _link));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsOneWidget);
    });

    testWidgets('epic1 off: a link stops with the off line and its Settings action', (tester) async {
      await _open(tester, DeskRoute.send, epic1: false);
      await _pasteLink(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byKey(const ValueKey('e1-mode-dialog')), findsOneWidget);
      expect(_say(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('e1-mode-settings')));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.settingsReceiving);
      expect(_container.read(settingsPrefsProvider).jump, isNotNull);
    });

    /// Types the link into the classic form's To a few characters at a time, then leaves the field.
    Future<void> typeAndLeave(WidgetTester tester) async {
      final to = find.byType(EditableText).first;
      for (var n = 7; n < _link.length + 7; n += 7) {
        await tester.enterText(to, _link.substring(0, n > _link.length ? _link.length : n));
        await tester.pump();
      }
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
    }

    testWidgets('a link typed into the classic form is read once To is left', (tester) async {
      await _open(tester, DeskRoute.send);
      await typeAndLeave(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsOneWidget);
    });

    testWidgets('the typed link cleared on the epic1 form: the classic form is empty, To focused', (tester) async {
      await _open(tester, DeskRoute.send);
      await typeAndLeave(tester);
      await _tap(tester, 'e1-clear');
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      final to = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(to.controller.text, isEmpty);
      expect(to.focusNode.hasFocus, isTrue);
    });

    testWidgets('epic1 off: a typed link gets the off line under To', (tester) async {
      await _open(tester, DeskRoute.send, epic1: false);
      await typeAndLeave(tester);
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      expect(find.byKey(const ValueKey('e1-mode-dialog')), findsNothing);
      expect(_say(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
    });

    testWidgets('epic1 off: a classic address is not stopped by it', (tester) async {
      await _open(tester, DeskRoute.send, epic1: false);
      final anna = _container.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c1');
      await tester.enterText(find.byType(EditableText).first, anna.address);
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-mode-dialog')), findsNothing);
    });
  });

  group('Contacts', () {
    testWidgets('the picker and the contact page carry no Classic only mark; Send works', (tester) async {
      await _open(tester, DeskRoute.contacts, arg: const ContactsArgs(selectedId: 'c1'));
      expect(find.byKey(const ValueKey('e1-contact-classic-only')), findsNothing);
      expect(tester.widget<EButton>(find.byKey(const ValueKey('contact-send'))).onPressed, isNotNull);
    });

    testWidgets('a contact with only an epic1 link is paid through it; off, it has no way to pay', (tester) async {
      await _open(tester, DeskRoute.contacts, select: Contact(id: '', name: 'Link Only', epic1: _link));
      final id = (_container.read(deskNavProvider).arg as ContactsArgs).selectedId;
      expect(find.byKey(const ValueKey('contact-no-address')), findsNothing);
      expect(tester.widget<EButton>(find.byKey(const ValueKey('contact-send'))).onPressed, isNotNull);
      await _tap(tester, 'contact-send');
      expect(find.byKey(const ValueKey('e1-send-to')), findsOneWidget);
      expect(tester.widget<EditableText>(_field('e1-send-to')).controller.text, _link);

      await tester.runAsync(() async {
        final n = _container.read(deskProvider.notifier);
        final st = _container.read(deskProvider).settings;
        await n.saveSettings(st.copyWith(payments: st.payments.copyWith(epic1: false)));
      });
      _container.read(deskNavProvider.notifier).reset(DeskRoute.contacts, ContactsArgs(selectedId: id));
      await _settle(tester);
      expect(find.byKey(const ValueKey('contact-no-address')), findsOneWidget);
      expect(tester.widget<EButton>(find.byKey(const ValueKey('contact-send'))).onPressed, isNull);
    });
  });

  group('Sealed with epic1', () {
    Future<void> activity(WidgetTester tester, {required bool epic1, required bool sealed}) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _wallet = _Wallet()
        ..e1State = TxState.confirmed
        ..e1Sealed = sealed;
      _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_wallet)], retry: (_, _) => null);
      addTearDown(_container.dispose);
      await tester.runAsync(() async {
        final n = _container.read(deskProvider.notifier);
        await n.refresh();
        final st = _container.read(deskProvider).settings;
        await n.saveSettings(st.copyWith(tourSeen: true, payments: st.payments.copyWith(epic1: epic1)));
      });
      _container.read(deskNavProvider.notifier).reset(DeskRoute.activity);
      await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
      await _settle(tester);
    }

    testWidgets('a sealed payment shows the lock on its row', (tester) async {
      await activity(tester, epic1: true, sealed: true);
      expect(find.byKey(epic1SealedKey), findsWidgets);
    });

    testWidgets('an unsealed payment shows none', (tester) async {
      await activity(tester, epic1: true, sealed: false);
      expect(find.byKey(epic1SealedKey), findsNothing);
    });

    testWidgets('epic1 off: a sealed payment still shows the lock', (tester) async {
      await activity(tester, epic1: false, sealed: true);
      expect(find.byKey(epic1SealedKey), findsWidgets);
    });
  });
}
