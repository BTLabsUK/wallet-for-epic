// SPDX-License-Identifier: Apache-2.0
// A contact's claimed domain on the contact page: under the name only once proven (quietly,
// with a language icon); the Domain row in the details whenever a domain is claimed, with one
// word for where it stands. Nothing for a contact that claims none.

import 'package:epic_wallet/src/history/domain_check_book.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart' show clockProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/pairing/contact_pairing_block.dart' show contactPageDomainKey, contactPageDomainRowKey;
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/experimental.dart';

final AppLocalizations _l = englishStrings;
final DateTime _now = DateTime(2026, 11, 1, 12);
final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

WalletSummary get _summary => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: _epic(10),
  spendable: _epic(7),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(3),
  validatedWithNode: true,
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);

  FakePairing get api => session.pairing;

  /// Anna in the address book, with her Epicbox address.
  Contact anna() {
    final c = Contact(id: 'c1', name: 'Anna', epicbox: _anna);
    session.contactsValue.add(c);
    return c;
  }

  /// Anna paired (verified unless [state]), her card naming her payments address.
  PairingRecord pair({String? domain, DomainStatus? status}) {
    api.clock = () => _now;
    return api.seedPaired(id: 'p-anna', name: 'Anna', contactId: 'c1', paymentsAddress: _anna, peerDomain: domain, domainStatus: status);
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    session.owner = service;
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          invoicesOnProvider.overrideWithValue(true),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          slateFilesProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => _now),
          pairNetProvider.overrideWithValue(PairNet.online),
          sessionProvider.overrideWith(() => _Open(session)),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Text _row(WidgetTester tester) => tester.widget<Text>(find.descendant(of: find.byKey(contactPageDomainRowKey), matching: find.byType(Text)));

void main() {
  testWidgets('proven: the domain under the name and its row, "verified"', (tester) async {
    final h = _Harness()
      ..anna()
      ..pair(domain: 'anna.example', status: DomainStatus.proven);
    await h.pump(tester, const ContactPage(contactId: 'c1'));

    expect(find.byKey(contactPageDomainKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(contactPageDomainKey), matching: find.text('anna.example')), findsOneWidget);
    expect(find.descendant(of: find.byKey(contactPageDomainKey), matching: find.byIcon(Icons.language)), findsOneWidget);
    expect(_row(tester).textSpan!.toPlainText(), contains(_l.contactDomainVerified));
  });

  for (final (status, word) in [(DomainStatus.claimed, _l.contactDomainNotVerified), (DomainStatus.refused, _l.contactDomainRefused)]) {
    testWidgets('${status.name}: nothing under the name; the row says "$word"', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair(domain: 'anna.example', status: status);
      await h.pump(tester, const ContactPage(contactId: 'c1'));

      expect(find.byKey(contactPageDomainKey), findsNothing);
      expect(_row(tester).textSpan!.toPlainText(), allOf(contains('anna.example'), contains(word)));
    });
  }

  testWidgets('no claimed domain: no line, no row', (tester) async {
    final h = _Harness()
      ..anna()
      ..pair();
    await h.pump(tester, const ContactPage(contactId: 'c1'));

    expect(find.byKey(contactPageDomainKey), findsNothing);
    expect(find.byKey(contactPageDomainRowKey), findsNothing);
  });
}
