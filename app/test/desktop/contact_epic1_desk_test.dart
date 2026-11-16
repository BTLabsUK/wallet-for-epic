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
import 'package:epic_wallet/src/recipient.dart' show RecipientKind;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart' show WalletError, WalletErrorKind;
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart' show Epic1Text;
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

Future<_Wallet> _editor(WidgetTester tester, {ContactsArgs arg = const ContactsArgs(adding: true), List<Contact> seed = const []}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = _Wallet();
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    for (final c in seed) {
      await api.saveContact(c);
    }
    await container.read(deskProvider.notifier).refresh();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: ContactsScreen(arg: arg)),
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

    testWidgets('the list row of a contact with only a link tags it epic1, never Unknown', (tester) async {
      await _editor(tester);
      await _fill(tester, _link);
      await _save(tester);
      expect(find.byWidgetPredicate((w) => w is EBadge && w.icon == MethodIcons.ofRecipient(RecipientKind.epic1)), findsWidgets);
      expect(find.text(_l.deskKitUnknown), findsNothing);
    });

    testWidgets('editing a contact with a saved link shows its kind on opening', (tester) async {
      await _editor(tester, arg: const ContactsArgs(selectedId: 'eve', editing: true), seed: [Contact(id: 'eve', name: 'Eve', epic1: _link)]);
      expect(find.text(_link), findsOneWidget);
      // In the field, not only the list row.
      expect(find.descendant(of: find.byType(EField), matching: find.byWidgetPredicate((w) => w is EBadge && w.icon == MethodIcons.ofRecipient(RecipientKind.epic1))), findsOneWidget);
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

  group('Send with epic1 on', () {
    Future<_Wallet> open(WidgetTester tester, Object arg) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _Wallet();
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

    testWidgets('a contact with only an epic1 link opens the epic1 page with its link, ready to review', (tester) async {
      await open(tester, SendArgs(contact: Contact(id: 'eve', name: 'Eve', epic1: _link)));
      // The link is read: its address stands in To's place as the recipient's row.
      expect(tester.widget<Epic1ShortAddress>(find.byType(Epic1ShortAddress)).address, _bare);
      expect(find.byKey(const ValueKey('e1-review')), findsOneWidget);
      expect(find.text(_l.deskE1ErrNotLink), findsNothing);
    });

    testWidgets('a pasted bare epic1 address gets its line', (tester) async {
      await open(tester, SendArgs(contact: Contact(id: 'eve', name: 'Eve', epic1: _link)));
      // Clear goes back to the classic form; the address pasted there opens the epic1 page again.
      await tester.tap(find.byKey(const ValueKey('e1-clear')));
      await _settle(tester);
      await tester.enterText(find.byType(EditableText).first, _bare);
      await _settle(tester);
      expect(find.byWidgetPredicate((w) => (w is Text && w.data == _l.epic1AddressAlone) || (w is Epic1Text && w.text == _l.epic1AddressAlone)), findsOneWidget);
    });
  });
}
