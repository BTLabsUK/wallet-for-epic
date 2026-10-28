// The phone's contact star (per wallet, as the desktop's) and the Contacts list's Export and
// Import contacts, against FakeWalletSession.

import 'dart:convert';
import 'dart:typed_data';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/contacts_file.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/contacts_transfer.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final String _alice = 'es${'a' * 50}@epicbox.epiccash.com';
final String _bob = 'es${'b' * 50}@epicbox.epicnet.us';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => const WalletConfig(
    dataDir: '/fake/wallets/mainnet',
    chain: Chain.mainnet,
    nodeUrl: 'https://node.btlabs.uk',
    epicboxDomain: 'epicbox.epiccash.com',
    epicboxPort: 443,
  );
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

/// Opens [ContactsScreen] in picker mode.
class _Picker extends StatelessWidget {
  const _Picker();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push<Contact>(MaterialPageRoute<Contact>(builder: (_) => const ContactsScreen(pick: true))),
        child: const Text('pick'),
      ),
    ),
  );
}

class _Harness {
  final session = FakeWalletSession();
  late final service = FakeWalletService(session: session);
  final files = FakeHistoryFiles()..canShare = false;

  Future<Contact> add(String name, String address, {String? note}) =>
      session.saveContact(contact: Contact(id: '', name: name, address: address, note: note));

  late ProviderContainer container;

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
          walletConfigProvider.overrideWith(_Config.new),
          historyFilesProvider.overrideWithValue(files),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.byType(Navigator).first));
  }

  String? get notice => container.read(noticeProvider)?.text;
}

Future<void> _menu(WidgetTester tester, Key item) async {
  await tester.tap(find.byKey(contactsMoreKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(item));
  await tester.pumpAndSettle();
}

void main() {
  group('star', () {
    testWidgets('Star on the contact page stars it in this wallet, shown in the list and the picker', (tester) async {
      final h = _Harness();
      final alice = await h.add('Alice', _alice);
      await h.add('Bob', _bob);
      await h.pump(tester, const ContactsScreen());
      expect(find.byType(ContactStar), findsNothing);

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(contactPageMoreKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactStar), findsOneWidget);
      await tester.tap(find.byKey(contactPageStarKey));
      await tester.pumpAndSettle();
      expect(h.session.favourites, {alice.id});
      // The header shows it, labelled for screen readers.
      expect(find.descendant(of: find.byType(ContactPage), matching: find.byType(ContactStar)), findsOneWidget);
      expect(tester.widget<Icon>(find.descendant(of: find.byType(ContactStar), matching: find.byType(Icon))).semanticLabel, _l.contactStarred);

      await tester.pageBack();
      await tester.pumpAndSettle();
      // The row of Alice has it; Bob's has not. The order stays by name.
      expect(find.byType(ContactStar), findsOneWidget);
      expect(tester.getTopLeft(find.byType(ContactStar)).dy, closeTo(tester.getTopLeft(find.text('Alice')).dy, 24));
      expect(tester.getTopLeft(find.text('Alice')).dy, lessThan(tester.getTopLeft(find.text('Bob')).dy));

      // Unstar from the menu again.
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(contactPageMoreKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactUnstar), findsOneWidget);
      await tester.tap(find.byKey(contactPageStarKey));
      await tester.pumpAndSettle();
      expect(h.session.favourites, isEmpty);
      expect(find.byType(ContactStar), findsNothing);
    });

    testWidgets('another wallet (session) has its own stars', (tester) async {
      final h = _Harness();
      final alice = await h.add('Alice', _alice);
      h.session.favourites.add(alice.id);
      await h.pump(tester, const _Picker());
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      // Pick mode shows the star too; no More menu there.
      expect(find.byType(ContactStar), findsOneWidget);
      expect(find.byKey(contactsMoreKey), findsNothing);

      // A fresh app over another wallet's session.
      await tester.pumpWidget(const SizedBox());
      final other = _Harness();
      await other.add('Alice', _alice);
      await other.pump(tester, const ContactsScreen());
      expect(find.byType(ContactStar), findsNothing);
    });
  });

  group('export and import', () {
    testWidgets('Export saves the book as a contacts file and says how many', (tester) async {
      final h = _Harness();
      await h.add('Alice', _alice, note: 'Coffee');
      await h.add('Bob', _bob);
      await h.pump(tester, const ContactsScreen());
      await _menu(tester, contactsExportKey);
      final saved = h.files.saved.single;
      expect(saved.name, startsWith('epic-cash-contacts-'));
      final j = jsonDecode(utf8.decode(saved.bytes)) as Map<String, dynamic>;
      expect(j['format'], 'epic-cash-contacts');
      expect(j['network'], 'mainnet');
      expect(j['contacts'], [
        {'name': 'Alice', 'epicbox': _alice, 'note': 'Coffee'},
        {'name': 'Bob', 'epicbox': _bob},
      ]);
      expect(h.notice, _l.contactsExported(2));
    });

    testWidgets('Export is off with nothing to export', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactsScreen());
      await tester.tap(find.byKey(contactsMoreKey));
      await tester.pumpAndSettle();
      expect(tester.widget<PopupMenuItem<String>>(find.byKey(contactsExportKey)).enabled, isFalse);
      expect(find.text(_l.contactsImport), findsOneWidget);
    });

    testWidgets('Import shows what it does, then adds and merges without changing what is saved', (tester) async {
      final h = _Harness();
      await h.add('Alice (mine)', _alice, note: 'Mine');
      final file = encodeContactsFile(
        [
          ContactFields(name: 'Alice', epicbox: _alice, http: 'https://pay.example.net:3415', note: 'Theirs'),
          ContactFields(name: 'Bob', epicbox: _bob),
        ],
        network: 'mainnet',
        now: DateTime(2026, 10, 25),
      );
      h.files.picks.add(Uint8List.fromList(utf8.encode(file)));
      await h.pump(tester, const ContactsScreen());
      await _menu(tester, contactsImportKey);
      expect(find.text(_l.contactsImportTitle), findsOneWidget);
      expect(find.text(_l.contactsImportNew(1)), findsOneWidget);
      expect(find.text(_l.contactsImportMerged(1)), findsOneWidget);
      expect(find.text(_l.contactsImportKeeps), findsOneWidget);
      await tester.tap(find.byKey(contactsImportDoKey));
      await tester.pumpAndSettle();
      final all = await h.session.contacts();
      expect(all.map((c) => (c.name, c.epicbox, c.http, c.note)), [
        ('Alice (mine)', _alice, 'https://pay.example.net:3415', 'Mine'),
        ('Bob', _bob, null, null),
      ]);
      expect(h.notice, _l.contactsImportedAdded(2));
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('a file of another kind is refused in the sheet; nothing is saved', (tester) async {
      final h = _Harness();
      h.files.picks.add(Uint8List.fromList(utf8.encode('{"format":"epic-cash-contacts","version":2,"contacts":[]}')));
      await h.pump(tester, const ContactsScreen());
      await _menu(tester, contactsImportKey);
      expect(find.text(_l.contactsImportNewer), findsOneWidget);
      await tester.tap(find.text(_l.commonClose));
      await tester.pumpAndSettle();
      expect(await h.session.contacts(), isEmpty);
    });
  });
}
