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
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart' show Kit;
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

  testWidgets('the list marks only a contact whose kind is not the plain wallet, at the larger size', (tester) async {
    await _pump(tester, const ContactsScreen());
    // Bob only: once on the faces strip (54 px avatar) and once on his list row (40 px avatar).
    final marks = find.byType(ContactLabelMark);
    expect(marks, findsNWidgets(2));
    for (final m in tester.widgetList<ContactLabelMark>(marks)) {
      expect(m.label, ContactLabel.exchange);
    }
    final widths = [for (final e in marks.evaluate()) tester.getSize(find.byElementPredicate((x) => x == e)).width]..sort();
    expect(widths[0], closeTo(contactLabelMarkSize(Kit.avatar), 0.01));
    expect(widths[1], closeTo(contactLabelMarkSize(Kit.avatarStrip), 0.01));
    expect(contactLabelMarkSize(Kit.avatarStrip), greaterThanOrEqualTo(21));
    for (final m in marks.evaluate()) {
      final mark = find.byElementPredicate((x) => x == m);
      final glyph = tester.getSize(find.descendant(of: mark, matching: find.byType(ContactLabelGlyph))).width;
      expect(glyph, closeTo(contactLabelGlyphSize(tester.getSize(mark).width), 0.01));
    }
  });

  testWidgets('the contact page draws no mark for the plain wallet; Label in the menu opens the picker, and a set kind draws a mark that opens it too', (tester) async {
    await _pump(tester, const ContactsScreen());
    await tester.tap(find.text('Alice').first);
    await tester.pumpAndSettle();
    expect(find.byType(ContactPage), findsOneWidget);
    // The default is the frame's plain avatar: no mark.
    expect(find.byType(ContactLabelMark), findsNothing);
    await tester.tap(find.byKey(contactPageMoreKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(contactPageLabelKey));
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
    expect(find.byType(ContactLabelMark), findsNothing);
  });
}
