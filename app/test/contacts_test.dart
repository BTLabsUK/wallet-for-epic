// SPDX-License-Identifier: Apache-2.0
// The phone's Contacts screen and contact page, against
// FakeWalletSession.

import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final String _alice = 'es${'a' * 50}@epicbox.epiccash.com';
final String _bob = 'es${'b' * 50}@epicbox.epicnet.us';
final String _onion = '${'t' * 55}d.onion';
const String _http = 'http://192.168.1.20:3415';

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

/// Opens [ContactsScreen] in picker mode and keeps what it returns.
class _Picker extends StatefulWidget {
  const _Picker({this.forPayment = false});

  final bool forPayment;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  Contact? picked;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final contact = await Navigator.of(context).push<Contact>(
            MaterialPageRoute<Contact>(
              builder: (_) => ContactsScreen(pick: true, forPayment: widget.forPayment),
            ),
          );
          setState(() => picked = contact);
        },
        child: Text(picked?.name ?? 'pick'),
      ),
    ),
  );
}

class _Harness {
  _Harness({this.refusals});

  final PaymentRefusals? refusals;
  final session = FakeWalletSession();
  late final service = FakeWalletService(session: session);

  Future<void> add(String name, String address, {String? note}) =>
      session.saveContact(
        contact: Contact(id: '', name: name, address: address, note: note),
      );

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
          if (refusals != null) paymentRefusalsProvider.overrideWithValue(refusals!),
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

class _RefusesAlice implements PaymentRefusals {
  @override
  bool refusesPayments({String? pairingId, String? address}) =>
      address != null && epicboxKey(address) == epicboxKey(_alice);

  @override
  String? refusedName({String? pairingId, String? address}) => refusesPayments(pairingId: pairingId, address: address) ? 'Alice' : null;
}

void main() {
  group('initials', () {
    test('take the first letters of the first two words', () {
      expect(contactInitials('Alice Smith'), 'AS');
      expect(contactInitials('  bob   van  dyke '), 'BV');
      expect(contactInitials('Łukasz Żak'), 'ŁŻ');
    });

    test('else the first two letters, or ? for nothing', () {
      expect(contactInitials('alice'), 'AL');
      expect(contactInitials('Q'), 'Q');
      expect(contactInitials('   '), '?');
    });
  });

  test('the tag says how the address is reached', () {
    expect(contactTag(_l, _alice), _l.methodEpicbox);
    expect(contactTag(_l, _onion), _l.methodDirectTor);
    expect(contactTag(_l, 'http://${'t' * 55}d.onion'), _l.methodDirectTor);
    expect(contactTag(_l, _http), 'Link · HTTP');
  });

  group('list', () {
    testWidgets('a book this wallet has no key to is shown closed, not empty', (tester) async {
      final h = _Harness();
      h.session.contactsAvailableValue = false;
      await h.pump(tester, const ContactsScreen());
      expect(find.byKey(const ValueKey('contacts-closed')), findsOneWidget);
      expect(find.text(_l.contactsClosedTitle), findsOneWidget);
      expect(find.text(_l.contactsClosedText), findsOneWidget);
      expect(find.text(_l.contactsEmptyTitle), findsNothing);
    });

    testWidgets('empty: the next step, no search field', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactsScreen());
      expect(find.text(_l.contactsEmptyTitle), findsOneWidget);
      expect(find.text(_l.contactsEmptyCaption), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, _l.contactsAdd));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsNewTitle), findsOneWidget);
    });

    testWidgets('rows: initials, name, tag, short address, note', (
      tester,
    ) async {
      final h = _Harness();
      await h.add('Bob Builder', _bob, note: 'Rent, every month');
      await h.add('alice', _alice);
      await h.add('Tor friend', _onion);
      await h.pump(tester, const ContactsScreen());
      expect(find.byTooltip(_l.contactsAdd), findsOneWidget);
      expect(find.text('BB'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);
      // Not paired: the method badge after the name.
      expect(find.byIcon(EpicGlyphs.epicbox), findsNWidgets(2));
      expect(find.byIcon(EpicGlyphs.tor), findsOneWidget);
      expect(find.text(_l.methodEpicbox), findsNWidgets(2));
      expect(find.text(_l.methodShortTor), findsOneWidget);
      expect(
        find.textContaining(
          shortAddress(_bob).split('@').first,
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Rent, every month'), findsOneWidget);
      // Sorted by name, whatever the case.
      final names = [
        for (final name in ['alice', 'Bob Builder', 'Tor friend'])
          tester.getTopLeft(find.text(name)).dy,
      ];
      expect(names, [...names]..sort());
      // Eight or fewer: no letter headers.
      expect(find.text('A'), findsNothing);
    });

    testWidgets('more than eight contacts get letter headers', (tester) async {
      final h = _Harness();
      for (final name in [
        'Ann',
        'Amy',
        'Ben',
        'Bea',
        'Cal',
        'Cy',
        'Dan',
        'Di',
      ]) {
        await h.add(name, 'es${name.toLowerCase() * 20}@epicbox.epiccash.com');
      }
      await h.add('9 lives', _alice);
      await h.pump(tester, const ContactsScreen());
      for (final letter in ['#', 'A', 'B']) {
        expect(find.text(letter), findsOneWidget, reason: letter);
      }
    });

    testWidgets('search narrows by name or address, and says when nothing '
        'matches', (tester) async {
      final h = _Harness();
      await h.add('Alice', _alice);
      await h.add('Bob', _bob);
      await h.pump(tester, const ContactsScreen());
      await tester.enterText(find.byType(TextField), 'epicnet');
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();
      expect(find.text(_l.contactsNoMatchQuery('xyz')), findsOneWidget);
      await tester.tap(find.byTooltip(_l.commonClose));
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('picker mode returns the tapped contact', (tester) async {
      final h = _Harness();
      await h.add('Alice', _alice);
      await h.pump(tester, const _Picker());
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsPickTitle), findsOneWidget);
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text(_l.contactsPickTitle), findsNothing);
    });
  });

  group('contacts that take no payments', () {
    testWidgets('the list row carries the bare mark and no words', (tester) async {
      final h = _Harness(refusals: _RefusesAlice());
      await h.add('Alice', _alice);
      await h.add('Bob', _bob);
      await h.pump(tester, const ContactsScreen());
      expect(find.byIcon(EpicGlyphs.noPayments), findsOneWidget);
      expect(find.text(_l.contactNoPayments), findsNothing);
      expect(find.text(_l.contactTakesNoPayments), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == _l.contactNoPayments), findsOneWidget);
    });

    testWidgets('the picker for a payment shows the row disabled with why; Bob can be picked', (tester) async {
      final h = _Harness(refusals: _RefusesAlice());
      await h.add('Alice', _alice);
      await h.add('Bob', _bob);
      await h.pump(tester, const _Picker(forPayment: true));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactTakesNoPayments), findsOneWidget);
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsPickTitle), findsOneWidget, reason: 'the disabled row does not pick');
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsPickTitle), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('page', () {
    Future<_Harness> open(WidgetTester tester, {PaymentRefusals? refusals}) async {
      final h = _Harness(refusals: refusals);
      await h.add('Alice Smith', _alice, note: 'Coffee club');
      await h.pump(tester, const ContactsScreen());
      await tester.tap(find.text('Alice Smith'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactPage), findsOneWidget);
      return h;
    }

    testWidgets('a contact that takes no payments has no Send, one line says why', (tester) async {
      await open(tester, refusals: _RefusesAlice());
      expect(find.byKey(contactPageSendKey), findsNothing);
      expect(find.byKey(contactPageNoPaymentsKey), findsOneWidget);
      expect(find.text(_l.contactNoPayments), findsOneWidget);
      expect(find.byIcon(EpicGlyphs.noPayments), findsOneWidget);
    });

    testWidgets('shows the full address and the note, the code on request', (
      tester,
    ) async {
      await open(tester);
      // In full on the page, and again under Show code.
      expect(
        find.descendant(
          of: find.byType(ContactPage),
          matching: find.textContaining('a' * 50, findRichText: true),
        ),
        findsWidgets,
      );
      expect(find.text('Coffee club'), findsOneWidget);
      expect(find.text(_l.contactAddresses), findsOneWidget);
      expect(find.byType(MarkedQr), findsNothing);
      await tester.tap(find.text(_l.contactsShowCode));
      await tester.pumpAndSettle();
      expect(find.byType(MarkedQr), findsOneWidget);
      expect(find.textContaining('a' * 50, findRichText: true), findsWidgets);
    });

    testWidgets('on a phone Send sits above the navigation bar, 48 dp tall', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
      await open(tester);
      final limit = tester.view.physicalSize.height / tester.view.devicePixelRatio - 48;
      final rect = tester.getRect(find.byKey(contactPageSendKey));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(limit));
      expect(tester.getRect(find.byKey(contactPageEditKey)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('Send hands the address to the Send tab', (tester) async {
      final h = await open(tester);
      await tester.tap(find.byKey(contactPageSendKey));
      await tester.pumpAndSettle();
      final c = h.container(tester);
      expect(c.read(shellTabProvider), ShellTab.send);
      expect(c.read(sendRecipientProvider)?.text, _alice);
      expect(find.byType(ContactPage), findsNothing);
    });

    for (final (name, address) in [('http', _http), ('onion', _onion)]) {
      testWidgets('the edit screen saves a Link $name address', (tester) async {
        final h = _Harness();
        await h.pump(tester, const ContactEditScreen());
        await tester.enterText(find.widgetWithText(TextField, _l.contactsNameLabel), 'Dan');
        await tester.enterText(find.widgetWithText(TextField, _l.addrField), address);
        await tester.tap(find.text(_l.contactsSave));
        await tester.pumpAndSettle();
        if (!torBuilt && name == 'onion') {
          // The build without Tor refuses a new onion, in one short line.
          expect(find.text(_l.sendTorNotInVersion), findsOneWidget);
          expect((await h.session.contacts()).map((c) => c.name), isNot(contains('Dan')));
          return;
        }
        expect(find.textContaining('not a valid'), findsNothing);
        expect((await h.session.contacts()).map((c) => c.name), contains('Dan'));
      });
    }

    testWidgets('without Tor, a contact keeps the onion it has', (tester) async {
      final h = _Harness();
      final saved = await h.session.saveContact(contact: Contact(id: '', name: 'Tor friend', address: _onion));
      await h.pump(tester, ContactEditScreen(contact: saved));
      expect(find.text(_onion), findsOneWidget);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      expect(find.text(_l.sendTorNotInVersion), findsNothing);
      expect((await h.session.contacts()).single.tor, _onion);
    }, skip: torBuilt);

    testWidgets('Edit opens the edit screen', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(contactPageEditKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsEditTitle), findsOneWidget);
    });

    Future<void> delete(WidgetTester tester) async {
      await tester.tap(find.byKey(contactPageMoreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(contactPageDeleteKey));
      await tester.pumpAndSettle();
    }

    testWidgets('Delete asks first; Cancel keeps it', (tester) async {
      final h = await open(tester);
      await delete(tester);
      expect(find.text(_l.contactsDeleteTitle('Alice Smith')), findsOneWidget);
      expect(find.text(_l.contactsDeleteConfirmBody), findsOneWidget);
      await tester.tap(find.text(_l.commonCancel));
      await tester.pumpAndSettle();
      expect(h.session.contactsValue, hasLength(1));
      expect(find.byType(ContactPage), findsOneWidget);

      await delete(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_l.commonDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(h.session.contactsValue, isEmpty);
      expect(find.byType(ContactPage), findsNothing);
      expect(find.text(_l.contactsEmptyTitle), findsOneWidget);
    });
  });
}
