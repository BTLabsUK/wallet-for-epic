// Phone contacts hold epicbox addresses only: the contact form refuses a wallet URL on save, in
// the words Send uses (OD-2). The archive underneath is shared with the desktop, which pays
// http(s) addresses, so it stores one as typed and leaves the rule to each screen.
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
const _refusal =
    'Payments to a wallet URL are not supported. Ask the recipient for their epicbox address.';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

void main() {
  test('checkContactAddress refuses wallet URLs and checks the rest', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final service = FakeWalletService();
    for (final url in [
      'http://203.0.113.5:3415',
      ' HTTPS://wallet.example ',
      'http://',
    ]) {
      expect(checkContactAddress(l, service, url), _refusal, reason: url);
    }
    expect(checkContactAddress(l, service, _bob), isNull);
    expect(checkContactAddress(l, service, ''), checkRecipient(l, service, ''));
    expect(
      checkContactAddress(l, service, 'nonsense'),
      contains('not a valid address'),
    );
    for (final locale in AppLocalizations.supportedLocales) {
      final t = await AppLocalizations.delegate.load(locale);
      expect(t.sendUrlUnsupported, isNotEmpty, reason: '$locale');
    }
  });

  testWidgets('the contact form refuses a wallet URL and saves nothing', (
    tester,
  ) async {
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
    expect(find.text(_refusal), findsOneWidget);
    expect(session.contactsValue, isEmpty);
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
