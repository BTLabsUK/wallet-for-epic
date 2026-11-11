// SPDX-License-Identifier: Apache-2.0
// The contact label mark on the phone: the list draws it for a label and nothing for the
// default, and the contact page's mark opens the picker. Against FakeWalletSession.
import 'package:epic_wallet/src/contact_label.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/contact_label_mark.dart';
import 'package:epic_wallet/src/ui/contact_label_picker.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final String _alice = 'es${'a' * 50}@epicbox.epiccash.com';
final String _bob = 'es${'b' * 50}@epicbox.epicnet.us';

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

final _session = FakeWalletSession();

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService(session: _session)),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        updatePlatformProvider.overrideWithValue(null),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
        sessionProvider.overrideWith(() => _OpenSession(_session)),
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

Future<ContactLabel> _stored(String name) async => (await _session.contacts()).firstWhere((c) => c.name == name).label;

void main() {
  setUp(() async {
    for (final c in await _session.contacts()) {
      await _session.deleteContact(id: c.id);
    }
    await _session.saveContact(contact: Contact(id: '', name: 'Alice', address: _alice));
    await _session.saveContact(contact: Contact(id: '', name: 'Bob', address: _bob, label: ContactLabel.exchange));
  });

  testWidgets('the list marks every contact, the default faint, as large as the label mark size', (tester) async {
    await _pump(tester, const ContactsScreen());
    final marks = find.byType(ContactLabelMark);
    expect(marks, findsNWidgets(2));
    expect(marks.evaluate().map((e) => (e.widget as ContactLabelMark).label).toSet(), {ContactLabel.wallet, ContactLabel.exchange});
    // The 48 px row avatar: a 21 px mark (it was 19 px) with a 17 px glyph (it was 14 px).
    final exchange = find.byWidgetPredicate((w) => w is ContactLabelMark && w.label == ContactLabel.exchange);
    expect(tester.getSize(exchange).width, closeTo(contactLabelMarkSize(48), 0.01));
    expect(contactLabelMarkSize(48), greaterThanOrEqualTo(21));
    expect(tester.getSize(find.descendant(of: exchange, matching: find.byType(ContactLabelGlyph))).width, greaterThanOrEqualTo(16.8));
  });

  testWidgets('the contact page mark opens the picker; setting and clearing a label updates it and the stored contact', (tester) async {
    await _pump(tester, const ContactsScreen());
    await tester.tap(find.text('Alice').first);
    await tester.pumpAndSettle();
    expect(find.byType(ContactPage), findsOneWidget);
    // The default shows a faint mark that can be tapped.
    expect(find.byType(ContactLabelMark), findsOneWidget);
    await tester.tap(find.byType(ContactLabelMark));
    await tester.pumpAndSettle();
    expect(find.byKey(contactLabelSheetKey), findsOneWidget);
    await tester.tap(find.byKey(contactLabelRowKey(ContactLabel.vendor)));
    await tester.pumpAndSettle();
    expect(find.byKey(contactLabelSheetKey), findsNothing);
    expect(await _stored('Alice'), ContactLabel.vendor);
    expect(tester.widget<ContactLabelMark>(find.byType(ContactLabelMark)).label, ContactLabel.vendor);

    await tester.tap(find.byType(ContactLabelMark));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(contactLabelRowKey(ContactLabel.wallet)));
    await tester.pumpAndSettle();
    expect(await _stored('Alice'), ContactLabel.wallet);
    expect(tester.widget<ContactLabelMark>(find.byType(ContactLabelMark)).label, ContactLabel.wallet);
  });
}
