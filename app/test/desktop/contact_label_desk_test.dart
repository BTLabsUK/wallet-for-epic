// SPDX-License-Identifier: Apache-2.0
// The contact label on the desktop: the list marks a labelled contact, and the details' mark
// opens the menu; a choice is saved on the contact with every other field kept.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/contact_label.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show AppLocalizations, englishStrings;
import 'package:epic_wallet/src/ui/contact_label_mark.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  /// The mock's contacts carry no label; c3 is an exchange and the others a mix.
  Future<void> label() async {
    final all = await contacts();
    for (final (id, l) in [('c3', ContactLabel.exchange), ('c2', ContactLabel.service), ('c5', ContactLabel.vendor)]) {
      await super.saveContact(all.firstWhere((x) => x.id == id).copyWith(label: l));
    }
  }

  final saved = <Contact>[];

  @override
  Future<String> saveContact(Contact contact) async {
    saved.add(contact);
    return super.saveContact(contact);
  }
}

Future<void> _open(WidgetTester tester, DeskWalletApi api, ContactsArgs args) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: ContactsScreen(arg: args)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('a list row draws a mark for a non-default kind only, at a readable size', (tester) async {
    final api = _Wallet();
    await api.label();
    await _open(tester, api, const ContactsArgs());
    // The mock has an exchange, a service and a vendor; the others are plain wallets.
    final labels = find.byType(ContactLabelMark).evaluate().map((e) => (e.widget as ContactLabelMark).label).toSet();
    expect(labels, containsAll([ContactLabel.exchange, ContactLabel.service, ContactLabel.vendor]));
    expect(labels, isNot(contains(ContactLabel.wallet)));
    // A 40 u row avatar: the mark is at least 20 px with a 16 px glyph.
    final service = find.byWidgetPredicate((w) => w is ContactLabelMark && w.label == ContactLabel.service).first;
    expect(tester.getSize(service).width, greaterThanOrEqualTo(20));
    final glyph = find.descendant(of: service, matching: find.byType(ContactLabelGlyph));
    expect(tester.getSize(glyph).width, greaterThanOrEqualTo(16));
  });

  testWidgets('the details mark opens the menu; a choice is saved with the other fields kept; the default clears it', (tester) async {
    final api = _Wallet();
    await api.label();
    await _open(tester, api, const ContactsArgs(selectedId: 'c3'));
    final marks = find.byWidgetPredicate((w) => w is ContactLabelMark && w.avatar > 50);
    expect(marks, findsOneWidget);
    await tester.tap(marks);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.deskConLabelVendor).last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(api.saved.last.label, ContactLabel.vendor);
    expect(api.saved.last.name, 'Exchange deposit');
    expect(api.saved.last.id, 'c3');

    await tester.tap(find.byWidgetPredicate((w) => w is ContactLabelMark && w.avatar > 50));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.deskConLabelWallet).last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(api.saved.last.label, ContactLabel.wallet);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
