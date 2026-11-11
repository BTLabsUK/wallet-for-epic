// SPDX-License-Identifier: Apache-2.0
// A contact's epic1 link (lib/src/contact_epic1.dart): read by shape, checked by LEPIC's
// readLink (FakeEpic1 here, which refuses as LEPIC does), stored under its own key, and paid
// through the epic1 flow in epic1 mode. A bare epic1 address is not payable: a line says so.
// Synthetic data.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/contact_epic1.dart';
import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/contacts.dart' show checkRecipient, contactSendAddress;
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_common.dart' show classicOnlyProvider;
import 'package:epic_wallet/src/ui/epic1/epic1_send.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _bare = 'epic1qcontact000000000000000000000000000000';
const _link = 'epic:$_bare?epicbox=mailbox%40relay.example.invalid';
const _box = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.com';

String get _invalid => torBuilt ? _l.contactsAddressInvalidAny : _l.contactsAddressInvalidAnyNoTor;

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  _Harness({bool epic1 = false}) {
    if (epic1) session.epic1Fake = FakeEpic1(on: true);
  }

  final session = FakeWalletSession();
  late final service = FakeWalletService(session: session);

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// A page under [screen], so Save can pop it.
class _Under extends StatefulWidget {
  const _Under(this.screen, {super.key});

  final Widget screen;

  @override
  State<_Under> createState() => _UnderState();
}

class _UnderState extends State<_Under> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => widget.screen)));
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  group('reading', () {
    test('a link and a bare address are epic1; only a link with a server is more than an address', () {
      expect(parseRecipient(_link).kind, RecipientKind.epic1);
      expect(parseRecipient(_bare).kind, RecipientKind.epic1);
      expect(parseRecipient('t$_bare').kind, RecipientKind.epic1);
      expect(parseRecipient(' $_link\n').address, _link);
      expect(epic1AddressOnly(_bare), isTrue);
      expect(epic1AddressOnly('epic:$_bare'), isTrue, reason: 'a link that names no server');
      expect(epic1AddressOnly(_link), isFalse);
      expect(epic1Shaped(_box), isFalse);
      expect(parseRecipient(_box).kind, RecipientKind.epicbox);
    });

    test("LEPIC's verdict: link, address alone, other network, cannot pay, invalid", () async {
      final e1 = FakeEpic1(on: true);
      expect(await checkEpic1(e1, _link), Epic1Check.link);
      expect(await checkEpic1(e1, _bare), Epic1Check.addressOnly);
      expect(e1.calls.last, 'readLink', reason: 'a bare address is read as epic:<address>');
      expect(await checkEpic1(e1, 'epic1-not-an-address'), Epic1Check.invalid);
      e1.failNext = const WalletError(kind: WalletErrorKind.epic1WrongNetwork, message: 'floonet');
      expect(await checkEpic1(e1, 't$_bare'), Epic1Check.otherNetwork);
      e1.failNext = const WalletError(kind: WalletErrorKind.epic1CannotPay, message: 'no relay');
      expect(await checkEpic1(e1, _link), Epic1Check.cannotPay);
      e1.failNext = const WalletError(kind: WalletErrorKind.notAnEpic1Link, message: 'bad checksum');
      expect(await checkEpic1(e1, _bare), Epic1Check.invalid);
      // Locked: the shape alone.
      expect(await checkEpic1(null, _link), Epic1Check.link);
      expect(await checkEpic1(null, _bare), Epic1Check.addressOnly);
    });

    test('each verdict has its line; a payable link none', () {
      expect(epic1CheckText(_l, Epic1Check.link, invalid: 'x'), isNull);
      expect(epic1CheckText(_l, Epic1Check.addressOnly, invalid: 'x'), _l.epic1AddressAlone);
      expect(epic1CheckText(_l, Epic1Check.otherNetwork, invalid: 'x'), _l.deskE1ErrWrongNetwork);
      expect(epic1CheckText(_l, Epic1Check.cannotPay, invalid: 'x'), _l.deskE1ErrCannotPay);
      expect(epic1CheckText(_l, Epic1Check.invalid, invalid: 'x'), 'x');
    });

    test('the invalid-address line names epic1 links; checkRecipient says a bare address is not enough', () {
      expect(_l.contactsAddressInvalidAny, contains('epic1 link'));
      expect(_l.contactsAddressInvalidAnyNoTor, contains('epic1 link'));
      expect(_l.deskConErrAddressInvalid, contains('epic1 link'));
      final service = FakeWalletService(session: FakeWalletSession());
      expect(checkRecipient(_l, service, _bare), _l.epic1AddressAlone);
      expect(checkRecipient(_l, service, _link), isNull);
    });
  });

  group('storing', () {
    late Directory tmp;
    setUp(() async {
      ContactStore.forgetAll();
      tmp = await Directory.systemTemp.createTemp('contact_epic1_');
    });
    tearDown(() async {
      ContactStore.forgetAll();
      await tmp.delete(recursive: true);
    });

    test('the address book keeps the link under its own key and reads it back', () async {
      final s = await ContactStore.open(tmp.path);
      await s.save(const ContactFields(name: 'Eve', epicbox: _box, epic1: _link));
      final json = jsonDecode(await File('${tmp.path}/$contactsFileName').readAsString()) as Map<String, dynamic>;
      expect(json['version'], 1, reason: 'additive: no new file version');
      expect((json['contacts'] as List).single, containsPair('epic1', _link));
      ContactStore.forgetAll();
      final again = (await ContactStore.open(tmp.path)).list().single;
      expect([again.epicbox, again.epic1], [_box, _link]);
    });

    test('a file written before epic1 reads as it did', () async {
      await File('${tmp.path}/$contactsFileName').writeAsString(
        jsonEncode({
          'version': 1,
          'contacts': [
            {'id': '0123456789abcdef0123456789abcdef', 'name': 'Old', 'epicbox': _box},
          ],
        }),
      );
      final old = (await ContactStore.open(tmp.path)).list().single;
      expect([old.name, old.epicbox, old.epic1], ['Old', _box, null]);
    });

    test('a history record and a backup carry the link; an old record has none', () {
      final meta = Meta(contacts: [ContactRec(id: '1', name: 'Eve', epicbox: _box, epic1: _link)]);
      final back = Meta.fromJson(jsonDecode(encodeJson(meta.toJson()))).contacts.single;
      expect([back.epicbox, back.epic1], [_box, _link]);
      expect((meta.toJson()['contacts'] as List).single['address'], _box, reason: 'never the epic1 link');
      final old = Meta.fromJson(jsonDecode(encodeJson(Meta(contacts: [ContactRec(id: '1', name: 'B', address: _box)]).toJson())));
      expect(old.contacts.single.epic1, isNull);
    });
  });

  group('Send', () {
    test('classic Send of a contact with only a link gets the link (its line says to turn epic1 on)', () {
      final only = Contact(id: '1', name: 'E', epic1: _link);
      expect(only.address, isEmpty);
      expect(only.methodKinds, isEmpty);
      expect(contactSendAddress(only, (_) => true), _link);
      final both = Contact(id: '2', name: 'F', epicbox: _box, epic1: _link);
      expect(contactSendAddress(both, (_) => true), _box);
      expect(both.kinds, [RecipientKind.epicbox, RecipientKind.epic1]);
    });

    testWidgets('epic1 mode: a contact with a link is not Classic only; its page Send opens the epic1 link flow', (tester) async {
      final h = _Harness(epic1: true);
      final eve = await h.session.saveContact(contact: Contact(id: '', name: 'Eve', epic1: _link));
      final bob = await h.session.saveContact(contact: Contact(id: '', name: 'Bob', epicbox: _box));
      await h.pump(tester, ContactPage(contactId: eve.id));
      final c = h.container(tester);
      expect(c.read(classicOnlyProvider(eve.id)), isFalse);
      expect(c.read(classicOnlyProvider(bob.id)), isTrue, reason: 'no pairing, no link: as before');
      await tester.tap(find.byKey(contactPageSendKey));
      await tester.pumpAndSettle();
      expect(find.byType(Epic1LinkSendScreen), findsOneWidget);
      expect(find.byType(Epic1LinkSendScreen).evaluate().single.widget, isA<Epic1LinkSendScreen>().having((s) => s.link, 'link', _link));
    });

    testWidgets('epic1 Send: a bare address gets its line, a mistyped one "not an epic1 link"', (tester) async {
      final h = _Harness(epic1: true);
      await h.pump(tester, Scaffold(body: Epic1SendStart(classicCode: (_) => false, onContact: (_) {}, onDone: () {})));
      await tester.enterText(find.byKey(epic1SendFieldKey), _bare);
      await tester.pump();
      await tester.tap(find.byKey(epic1SendContinueKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.epic1AddressAlone), findsOneWidget);
      expect(find.byType(Epic1LinkSendScreen), findsNothing);
      h.session.epic1Fake.failNext = const WalletError(kind: WalletErrorKind.notAnEpic1Link, message: 'bad checksum');
      await tester.enterText(find.byKey(epic1SendFieldKey), 't$_bare');
      await tester.pump();
      await tester.tap(find.byKey(epic1SendContinueKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskE1ErrNotLink), findsOneWidget);
    });
  });

  group('the phone editor', () {
    Future<void> fill(WidgetTester tester, String address) async {
      await tester.enterText(find.widgetWithText(TextField, _l.contactsNameLabel), 'Eve');
      await tester.enterText(find.widgetWithText(TextField, _l.addrField), address);
      await tester.pumpAndSettle();
    }

    testWidgets('the field is labelled Address; an epic1 link is saved, shown and kept on edit', (tester) async {
      final h = _Harness();
      await h.pump(tester, _Under(key: UniqueKey(), const ContactEditScreen()));
      expect(find.text('Epicbox address'), findsNothing);
      await fill(tester, _link);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      final saved = (await h.session.contacts()).singleWhere((c) => c.name == 'Eve');
      expect([saved.epic1, saved.epicbox], [_link, null]);

      await h.pump(tester, _Under(key: UniqueKey(), ContactEditScreen(contact: saved)));
      expect(find.text(_link), findsOneWidget);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      expect((await h.session.contacts()).singleWhere((c) => c.name == 'Eve').epic1, _link);
    });

    testWidgets('a bare epic1 address gets its line and is not saved', (tester) async {
      final h = _Harness();
      await h.pump(tester, _Under(key: UniqueKey(), const ContactEditScreen()));
      await fill(tester, _bare);
      expect(find.text(_l.epic1AddressAlone), findsOneWidget);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      expect((await h.session.contacts()).where((c) => c.name == 'Eve'), isEmpty);
    });

    testWidgets('what LEPIC refuses, and garbage, get the invalid-address line', (tester) async {
      final h = _Harness();
      await h.pump(tester, _Under(key: UniqueKey(), const ContactEditScreen()));
      h.session.epic1Fake.failNext = const WalletError(kind: WalletErrorKind.notAnEpic1Link, message: 'bad checksum');
      await fill(tester, _link);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      expect(find.text(_invalid), findsOneWidget);
      expect((await h.session.contacts()).where((c) => c.name == 'Eve'), isEmpty);

      await tester.enterText(find.widgetWithText(TextField, _l.addrField), 'hello there');
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      expect(find.text(_invalid), findsOneWidget);
    });
  });
}
