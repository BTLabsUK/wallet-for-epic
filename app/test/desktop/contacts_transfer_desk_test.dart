// Desktop Contacts header: More › Export contacts saves the book and toasts the count; Import
// contacts shows what it does, then adds and merges without touching what is saved (the star
// stays).
import 'dart:convert';
import 'dart:typed_data';

import 'package:epic_wallet/src/contact_store.dart' show ContactFields;
import 'package:epic_wallet/src/contacts_file.dart';
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_transfer.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

Future<(MockDeskWallet, MockDeskHistoryFiles, ProviderContainer)> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = MockDeskWallet(delay: Duration.zero);
  final files = MockDeskHistoryFiles();
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(api), deskHistoryFilesProvider.overrideWithValue(files)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ContactsScreen()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  return (api, files, container);
}

Future<void> _menu(WidgetTester tester, Key item) async {
  await tester.tap(find.byKey(deskContactsMoreKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(item));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Export contacts saves the book and says how many', (tester) async {
    final (_, files, container) = await _open(tester);
    final withAddress = container.read(deskProvider).contacts!.where((c) => c.addresses.isNotEmpty).length;
    await _menu(tester, deskContactsExportKey);
    expect(files.saved.single, startsWith('epic-cash-contacts-'));
    expect(find.text(_l.contactsExported(withAddress)), findsOneWidget);
    expect(find.text(_l.deskFinOpenFolder), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Import contacts: the dialog says what it does; a saved contact keeps its name and star', (tester) async {
    final (api, files, container) = await _open(tester);
    final anna = container.read(deskProvider).contacts!.firstWhere((c) => c.name == 'Anna Kowalska');
    expect(anna.favourite, isTrue);
    final onion = '${'q' * 55}d.onion';
    final file = encodeContactsFile(
      [
        ContactFields(name: 'Anna K.', epicbox: anna.epicbox, tor: onion, note: 'their note'),
        const ContactFields(name: 'New friend', epicbox: 'esNw4Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK9z@epicbox.epiccash.com'),
      ],
      network: 'mainnet',
      now: DateTime(2026, 10, 25),
    );
    files.picks.add((name: 'epic-cash-contacts-2026-10-25.json', bytes: Uint8List.fromList(utf8.encode(file))));
    await _menu(tester, deskContactsImportKey);
    expect(find.text(_l.contactsImportTitle), findsOneWidget);
    expect(find.text(_l.contactsImportNew(1)), findsOneWidget);
    expect(find.text(_l.contactsImportMerged(1)), findsOneWidget);
    await tester.tap(find.byKey(deskContactsImportDoKey));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    final after = await api.contacts();
    final merged = after.firstWhere((c) => c.id == anna.id);
    // Anna had no note, so she gains the file's; her name and star stay.
    expect(anna.note, isNull);
    expect((merged.name, merged.note, merged.favourite, merged.tor), (anna.name, 'their note', true, onion));
    expect(after.where((c) => c.name == 'New friend'), hasLength(1));
    expect(find.text(_l.contactsImportedAdded(2)), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a file of another network is refused with the reason', (tester) async {
    final (api, files, _) = await _open(tester);
    final before = (await api.contacts()).length;
    final file = encodeContactsFile(
      [const ContactFields(name: 'F', epicbox: 'zz1234@flooepicbox.btlabs.uk')],
      network: 'floonet',
      now: DateTime(2026, 10, 25),
    );
    files.picks.add((name: 'f.json', bytes: Uint8List.fromList(utf8.encode(file))));
    await _menu(tester, deskContactsImportKey);
    expect(find.text(_l.contactsImportAllOtherNet), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.commonClose));
    await tester.pumpAndSettle();
    expect((await api.contacts()).length, before);
  });
}
