// SPDX-License-Identifier: Apache-2.0
// The desktop contact editor with an epic1 link, and Send paying a contact through it in
// epic1 mode. The mock's FakeEpic1 reads links as LEPIC does: only an `epic:` link with a
// server is payable; a bare address gets its own line.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart' show WalletError, WalletErrorKind;
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _bare = 'epic1qcontact000000000000000000000000000000';
const _link = 'epic:$_bare?epicbox=mailbox%40relay.example.invalid';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final saved = <Contact>[];

  @override
  Future<String> saveContact(Contact contact) async {
    saved.add(contact);
    return super.saveContact(contact);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<_Wallet> _editor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = _Wallet();
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: const Scaffold(body: ContactsScreen(arg: ContactsArgs(adding: true))),
      ),
    ),
  );
  await _settle(tester);
  return api;
}

Finder _input(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText));

Future<void> _fill(WidgetTester tester, String address) async {
  await tester.enterText(_input(_l.deskConFieldName), 'Eve');
  await tester.enterText(_input(_l.addrField).first, address);
  await _settle(tester);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text(_l.deskConSave));
  await _settle(tester);
}

void main() {
  group('the desktop editor', () {
    testWidgets('the field is labelled Address; an epic1 link is saved with its badge', (tester) async {
      final api = await _editor(tester);
      expect(find.byWidgetPredicate((w) => w is EField && w.label == 'Epicbox address'), findsNothing);
      await _fill(tester, _link);
      expect(find.text(_l.epic1AddressAlone), findsNothing);
      await _save(tester);
      expect(api.saved.single.epic1, _link);
      expect(api.saved.single.epicbox, isNull);
      expect(api.saved.single.address, isEmpty, reason: 'an epic1 link is never the classic address');
    });

    testWidgets('a bare epic1 address gets its line at once and is not saved', (tester) async {
      final api = await _editor(tester);
      await _fill(tester, _bare);
      expect(find.text(_l.epic1AddressAlone), findsOneWidget);
      await _save(tester);
      expect(api.saved, isEmpty);
    });

    testWidgets('a link LEPIC refuses, and garbage, get the invalid-address line', (tester) async {
      final api = await _editor(tester);
      api.epic1Fake.failNext = const WalletError(kind: WalletErrorKind.notAnEpic1Link, message: 'bad checksum');
      await _fill(tester, _link);
      await _save(tester);
      expect(api.saved, isEmpty);
      expect(find.text(torBuilt ? _l.deskConErrAddressInvalid : _l.contactsAddressInvalidAnyNoTor), findsOneWidget);
    });
  });

  group('Send in epic1 mode', () {
    Future<_Wallet> open(WidgetTester tester, Object arg) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _Wallet();
      await api.epic1Fake.setStoredOn(true);
      api.epic1Fake.reopen();
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        final n = container.read(deskProvider.notifier);
        await n.refresh();
        await n.saveSettings(container.read(deskProvider).settings.copyWith(tourSeen: true));
      });
      container.read(deskNavProvider.notifier).reset(DeskRoute.send, arg);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
      await _settle(tester);
      return api;
    }

    Finder to() => find.descendant(of: find.byKey(const ValueKey('e1-send-to')), matching: find.byType(EditableText));

    testWidgets('a contact with only an epic1 link opens the epic1 page with its link, ready to review', (tester) async {
      await open(tester, SendArgs(contact: Contact(id: 'eve', name: 'Eve', epic1: _link)));
      expect(tester.widget<EditableText>(to()).controller.text, _link);
      expect(find.byKey(const ValueKey('e1-review')), findsOneWidget);
      expect(find.text(_l.deskE1ErrNotLink), findsNothing);
    });

    testWidgets('a pasted bare epic1 address gets its line', (tester) async {
      await open(tester, const SendArgs());
      await tester.enterText(to(), _bare);
      await _settle(tester);
      expect(find.text(_l.epic1AddressAlone), findsOneWidget);
    });
  });
}
