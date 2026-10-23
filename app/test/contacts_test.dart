// The phone's Contacts screen and contact sheet (spec §3), against FakeWalletSession.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_sheet.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final String _alice = 'es${'a' * 50}@epicbox.epiccash.com';
final String _bob = 'es${'b' * 50}@epicbox.epicnet.us';
final String _onion = '${'t' * 55}d.onion';
const String _http = 'http://10.100.10.20:3415';

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

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => false;

  @override
  Future<bool> configured() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

/// Opens [ContactsScreen] in picker mode and keeps what it returns.
class _Picker extends StatefulWidget {
  const _Picker();

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
              builder: (_) => const ContactsScreen(pick: true),
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
          pushPlatformProvider.overrideWithValue(_NoPush()),
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
    expect(contactTag(_alice), 'Epicbox');
    expect(contactTag(_onion), 'Direct');
    expect(contactTag('http://${'t' * 55}d.onion'), 'Direct');
    expect(contactTag(_http), 'Direct');
  });

  group('list', () {
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
      expect(find.text('Epicbox'), findsNWidgets(2));
      expect(find.text('Direct'), findsOneWidget);
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

  group('sheet', () {
    Future<_Harness> open(WidgetTester tester) async {
      final h = _Harness();
      await h.add('Alice Smith', _alice, note: 'Coffee club');
      await h.pump(tester, const ContactsScreen());
      await tester.tap(find.text('Alice Smith'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      return h;
    }

    testWidgets('shows the full address and the note, the code on request', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('a' * 50, findRichText: true),
        ),
        findsOneWidget,
      );
      expect(find.text('Coffee club'), findsNWidgets(2));
      expect(find.byType(MarkedQr), findsNothing);
      await tester.tap(find.text(_l.contactsShowCode));
      await tester.pumpAndSettle();
      expect(find.byType(MarkedQr), findsOneWidget);
      await tester.tap(find.text(_l.contactsHideCode));
      await tester.pumpAndSettle();
      expect(find.byType(MarkedQr), findsNothing);
    });

    testWidgets('Send hands the address to the Send tab', (tester) async {
      final h = await open(tester);
      await tester.tap(find.byKey(contactSheetSendKey));
      await tester.pumpAndSettle();
      final c = h.container(tester);
      expect(c.read(shellTabProvider), ShellTab.send);
      expect(c.read(sendRecipientProvider)?.text, _alice);
      expect(find.byType(BottomSheet), findsNothing);
    });

    for (final (name, address) in [('http', _http), ('onion', _onion)]) {
      testWidgets('the edit screen saves a Direct $name address', (tester) async {
        final h = _Harness();
        await h.pump(tester, const ContactEditScreen());
        await tester.enterText(find.widgetWithText(TextField, _l.contactsNameLabel), 'Dan');
        await tester.enterText(find.widgetWithText(TextField, _l.contactsAddressLabel), address);
        await tester.tap(find.text(_l.contactsSave));
        await tester.pumpAndSettle();
        expect(find.textContaining('not a valid'), findsNothing);
        expect((await h.session.contacts()).map((c) => c.name), contains('Dan'));
      });
    }

    testWidgets('Edit opens the edit screen', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(contactSheetEditKey));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(_l.contactsEditTitle), findsOneWidget);
    });

    testWidgets('Delete asks first; Cancel keeps it', (tester) async {
      final h = await open(tester);
      await tester.tap(find.byKey(contactSheetDeleteKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactsDeleteTitle('Alice Smith')), findsOneWidget);
      expect(find.text(_l.contactsDeleteConfirmBody), findsOneWidget);
      await tester.tap(find.text(_l.commonCancel));
      await tester.pumpAndSettle();
      expect(h.session.contactsValue, hasLength(1));
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.byKey(contactSheetDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_l.commonDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(h.session.contactsValue, isEmpty);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(_l.contactsEmptyTitle), findsOneWidget);
    });
  });
}
