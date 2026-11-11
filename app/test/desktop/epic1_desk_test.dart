// SPDX-License-Identifier: Apache-2.0
// epic1 payments on the desktop (spec D1): the switch in Settings › Transactions, applied at
// the next unlock; Receive's link card; Send's one field with the unknown-server question,
// review, waiting and Sent; the classic lines in each mode; contacts that are Classic only.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart' show ContactsArgs;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/ui/epic1/epic1_sealed.dart' show epic1SealedKey;
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart' show Epic1Text;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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

Future<void> _open(WidgetTester tester, DeskRoute route, {Object? arg, bool epic1 = false}) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = _Wallet();
  if (epic1) {
    await _wallet.epic1Fake.setStoredOn(true);
    _wallet.epic1Fake.reopen();
  }
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
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

/// Lock, unlock (the fake applies the stored setting) and back on [route].
Future<void> _relock(WidgetTester tester, DeskRoute route) async {
  await tester.runAsync(() async {
    await _container.read(deskProvider.notifier).lock();
    expect(await _wallet.unlock('right password'), isTrue);
    await _container.read(deskProvider.notifier).refresh();
  });
  _container.read(deskNavProvider.notifier).reset(route);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await _settle(tester);
}

Finder _field(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.enterText(_field(key), text);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await _settle(tester);
}

bool _switchOn(WidgetTester tester) => tester.widget<ESwitch>(find.byKey(const ValueKey('e1-switch'))).value;

void main() {
  group('Settings › Transactions', () {
    testWidgets('classic: Experimental last; turning on asks first, then applies at the next unlock', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(find.byKey(const ValueKey('e1-experimental')), findsOneWidget);
      expect(find.text(_l.deskSetTxMethods), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-group')), findsNothing);
      expect(_switchOn(tester), isFalse);
      expect(find.byKey(const ValueKey('e1-applies')), findsNothing);

      // Cancel in the confirm keeps it off.
      await _tap(tester, 'e1-switch');
      expect(find.byKey(const ValueKey('e1-turn-on-dialog')), findsOneWidget);
      expect(find.text(_l.deskE1TurnOnBody), findsOneWidget);
      await tester.tap(find.text(_l.commonCancel));
      await _settle(tester);
      expect(_wallet.epic1Fake.storedOn, isFalse);

      await _tap(tester, 'e1-switch');
      await _tap(tester, 'e1-turn-on');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(_wallet.epic1Fake.storedOn, isTrue);
      expect(_switchOn(tester), isTrue);
      expect(find.text(_l.deskE1AppliesNext), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-lock-now')), findsOneWidget);
      // Still classic until the unlock.
      expect(find.text(_l.deskSetTxMethods), findsOneWidget);

      // Lock now locks.
      await _tap(tester, 'e1-lock-now');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.unlock);

      await _relock(tester, DeskRoute.settingsReceiving);
      expect(_container.read(deskPaymentModeProvider), PaymentMode.epic1);
      expect(find.byKey(const ValueKey('e1-group')), findsOneWidget);
      expect(find.text(_l.deskSetTxMethods), findsNothing);
      expect(find.text(_l.deskE1PrintedCount(0)), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-applies')), findsNothing);
    });

    testWidgets('epic1: turning off has no confirm and applies at the next unlock', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, epic1: true);
      expect(_switchOn(tester), isTrue);
      await _tap(tester, 'e1-switch');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-turn-on-dialog')), findsNothing);
      expect(_wallet.epic1Fake.storedOn, isFalse);
      expect(find.text(_l.deskE1AppliesNext), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-group')), findsOneWidget);

      await _relock(tester, DeskRoute.settingsReceiving);
      expect(_container.read(deskPaymentModeProvider), PaymentMode.classic);
      expect(find.byKey(const ValueKey('e1-group')), findsNothing);
      expect(find.text(_l.deskSetTxMethods), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-applies')), findsNothing);
    });

    testWidgets('epic1: Printed links opens the panel', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, epic1: true);
      await _tap(tester, 'e1-printed-open');
      expect(find.byKey(const ValueKey('e1-printed-panel')), findsOneWidget);
      expect(find.text(_l.deskE1PrintedNone), findsOneWidget);
    });
  });

  group('Receive', () {
    testWidgets('epic1: the link card with its QR shown, Copy link, Ask an amount, In person', (tester) async {
      await _open(tester, DeskRoute.receive, epic1: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-link-card')), findsOneWidget);
      expect(_wallet.epic1Fake.calls, contains('makeLink'));
      expect(find.byKey(const ValueKey('e1-copy-link')), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-qr-image-epic1')), findsOneWidget, reason: 'shown from the start');
      expect(find.text('Show QR'), findsNothing, reason: 'no cover, no Show QR step');
      expect(find.byKey(const ValueKey('e1-ask-amount')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-request-in-person')), findsOneWidget);
      // No classic receiving rows.
      expect(find.byKey(const ValueKey('rx-files-drop')), findsNothing);
      expect(find.text(_l.deskTfPickTitle), findsNothing);
    });
  });

  group('Send', () {
    testWidgets('epic1: a link through an unknown server asks first, then review, waiting, Sent', (tester) async {
      await _open(tester, DeskRoute.send, epic1: true);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      expect(find.byKey(const ValueKey('e1-send-to')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Epic1Text && w.text == _l.deskE1SendField), findsWidgets);

      await _enter(tester, 'e1-send-to', _link);
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

    testWidgets('epic1: a link on a listed server reviews with no question and pays', (tester) async {
      await _open(tester, DeskRoute.send, epic1: true);
      await _enter(tester, 'e1-send-to', _link);
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

    testWidgets('epic1: Cancel in the server question leaves the form', (tester) async {
      await _open(tester, DeskRoute.send, epic1: true);
      _wallet.epic1Fake.linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443)];
      await _enter(tester, 'e1-send-to', _link);
      await tester.tap(find.text(_l.commonCancel));
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-review')), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsNothing);
    });

    testWidgets('epic1: Send opened with a link shows it in the field, ready to review', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: _link), epic1: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _settle(tester);
      expect(tester.widget<EditableText>(_field('e1-send-to')).controller.text, _link);
      expect(find.byKey(const ValueKey('e1-amount-fixed')), findsOneWidget);
      await _tap(tester, 'e1-review');
      expect(find.byKey(const ValueKey('e1-review-panel')), findsOneWidget);
    });

    testWidgets('epic1: a classic address gets the mode line with Settings', (tester) async {
      await _open(tester, DeskRoute.send, epic1: true);
      final anna = _container.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c1');
      await _enter(tester, 'e1-send-to', anna.address);
      expect(find.text(_l.deskE1ModeClassicAddress), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-send-settings')), findsOneWidget);
    });

    testWidgets('classic: an epic1 link gets the mode line with Settings', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(find.byKey(const ValueKey('e1-send-to')), findsNothing);
      await tester.enterText(find.byType(EditableText).first, _link);
      await _settle(tester);
      expect(find.text(_l.deskE1ModeEpic1Link), findsOneWidget);
      expect(find.byKey(const ValueKey('e1-classic-settings')), findsOneWidget);
    });
  });

  group('Contacts', () {
    testWidgets('epic1: the picker shows Classic only and does not pick it', (tester) async {
      await _open(tester, DeskRoute.send, epic1: true);
      await _tap(tester, 'e1-contacts');
      expect(find.byKey(const ValueKey('e1-classic-only')), findsWidgets);
      await tester.tap(find.text('Anna Kowalska').last, warnIfMissed: false);
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-classic-only')), findsWidgets, reason: 'the picker stays open');
      expect(find.byType(ETip), findsWidgets);
    });

    testWidgets('epic1: the contact page says Classic only and Send is off', (tester) async {
      await _open(tester, DeskRoute.contacts, arg: const ContactsArgs(selectedId: 'c1'), epic1: true);
      expect(find.byKey(const ValueKey('e1-contact-classic-only')), findsOneWidget);
      final send = tester.widget<EButton>(find.byKey(const ValueKey('contact-send')));
      expect(send.onPressed, isNull);
      expect(find.ancestor(of: find.byKey(const ValueKey('contact-send')), matching: find.byType(ETip)), findsOneWidget);
    });

    testWidgets('classic: no Classic only and Send works', (tester) async {
      await _open(tester, DeskRoute.contacts, arg: const ContactsArgs(selectedId: 'c1'));
      expect(find.byKey(const ValueKey('e1-contact-classic-only')), findsNothing);
      expect(tester.widget<EButton>(find.byKey(const ValueKey('contact-send'))).onPressed, isNotNull);
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
      if (epic1) {
        await _wallet.epic1Fake.setStoredOn(true);
        _wallet.epic1Fake.reopen();
      }
      _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_wallet)], retry: (_, _) => null);
      addTearDown(_container.dispose);
      await tester.runAsync(() async {
        final n = _container.read(deskProvider.notifier);
        await n.refresh();
        await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
      });
      _container.read(deskNavProvider.notifier).reset(DeskRoute.activity);
      await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
      await _settle(tester);
    }

    testWidgets('epic1: a sealed payment shows the lock on its row', (tester) async {
      await activity(tester, epic1: true, sealed: true);
      expect(find.byKey(epic1SealedKey), findsWidgets);
    });

    testWidgets('epic1: an unsealed payment shows none', (tester) async {
      await activity(tester, epic1: true, sealed: false);
      expect(find.byKey(epic1SealedKey), findsNothing);
    });

    testWidgets('classic: a sealed payment shows none', (tester) async {
      await activity(tester, epic1: false, sealed: true);
      expect(find.byKey(epic1SealedKey), findsNothing);
    });
  });
}
