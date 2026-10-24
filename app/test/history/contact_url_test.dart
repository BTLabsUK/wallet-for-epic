// Phone contacts take an Epicbox address, an http(s) wallet address or an onion (the Direct
// methods), checked the way Send checks a recipient; an incomplete URL is refused with the
// example. The archive underneath stores an address as typed and leaves the rule to each screen.
import 'dart:io';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final String _bob = '${'b' * 52}@epicbox.epiccash.com';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

void main() {
  test('checkContactAddress takes complete URLs and onions, checks the rest', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final service = FakeWalletService();
    for (final address in [
      'http://203.0.113.5:3415',
      ' HTTPS://wallet.example ',
      _bob,
      '${'t' * 55}d.onion',
    ]) {
      expect(checkContactAddress(l, service, address), isNull, reason: address);
    }
    expect(checkContactAddress(l, service, 'http://'), contains('http://203.0.113.5:3415'));
    expect(checkContactAddress(l, service, ''), checkRecipient(l, service, ''));
    for (final junk in ['nonsense', 'tiger apple river house music light ocean stone']) {
      expect(checkContactAddress(l, service, junk), l.contactsAddressInvalidAny, reason: junk);
    }
    expect(l.contactsAddressInvalidAny, contains('Direct address (https://…)'));
    expect(l.contactsAddressInvalidAny, contains('onion address (….onion)'));
  });

  testWidgets('the contact form saves a wallet URL', (tester) async {
    final session = FakeWalletSession();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ContactEditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Shop');
    await tester.enterText(fields.at(1), 'https://203.0.113.5:3415');
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(session.contactsValue.single.address, 'https://203.0.113.5:3415');
  });

  test('the archive keeps a wallet URL; the screens decide', () async {
    final dir = await Directory.systemTemp.createTemp('wfe-contact-');
    addTearDown(() => dir.delete(recursive: true));
    final history = await WalletHistory.open(dir.path, Chain.mainnet);
    addTearDown(history.close);
    final shop = await history.saveContact(
      const Contact(id: '', name: 'Shop', address: ' HTTP://x:3415 '),
    );
    expect(shop.address, 'HTTP://x:3415');
    expect(history.contacts().single.name, 'Shop');
  });
}
