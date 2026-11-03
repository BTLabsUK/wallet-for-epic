// SPDX-License-Identifier: Apache-2.0
// Saving a contact never hangs: the address is checked as text only, a refused save ends the
// spinner with a notice, and an http(s) address is stored without reaching the host.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;

final _l = englishStrings;

/// The mock, with saves that fail or never return.
class _Wallet extends MockDeskWallet {
  _Wallet({this.fail = false});

  final bool fail;
  final saved = <Contact>[];

  @override
  Future<String> saveContact(Contact contact) async {
    if (fail) throw const DeskError('Disk full');
    saved.add(contact);
    return super.saveContact(contact);
  }
}

Future<void> _open(WidgetTester tester, DeskWalletApi api) async {
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
        theme: buildDeskTheme(Brightness.dark),
        home: const Scaffold(body: ContactsScreen(arg: ContactsArgs(adding: true))),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _fill(WidgetTester tester, String name, String address) async {
  Finder input(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText));
  await tester.enterText(input('Name'), name);
  // The empty address field is labelled by the kind it takes first ("Epicbox address").
  await tester.enterText(find.descendant(of: find.byWidgetPredicate((w) => w is EField && w.label.toLowerCase().endsWith('address')), matching: find.byType(EditableText)).first, address);
  await tester.pump();
  await tester.tap(find.text(_l.deskConSave));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('an http address is saved at once, as typed (a host with a dot or an IP: spec 7)', (tester) async {
    final api = _Wallet();
    await _open(tester, api);
    await _fill(tester, 'lol', 'http://10.0.1.24:3415');
    expect(api.saved.single.address, 'http://10.0.1.24:3415');
    expect(api.saved.single.id, isEmpty, reason: 'a new contact gets its id from the store');
    expect(find.byType(ESpinner), findsNothing);
  });

  testWidgets('a refused save ends the spinner and says why', (tester) async {
    await _open(tester, _Wallet(fail: true));
    await _fill(tester, 'lol', 'http://10.0.1.24:3415');
    expect(find.text(_l.deskConSaveFailed), findsOneWidget);
    expect(find.textContaining('Disk full'), findsOneWidget);
    expect(find.byType(ESpinner), findsNothing);
    expect(find.text(_l.deskConSave), findsOneWidget);
  });

  testWidgets('a malformed address is refused inline, nothing is stored', (tester) async {
    final api = _Wallet();
    await _open(tester, api);
    await _fill(tester, 'lol', 'http://');
    expect(api.saved, isEmpty);
    expect(find.text(_l.deskConErrAddressInvalid), findsOneWidget);
    expect(find.byType(ESpinner), findsNothing);
  }, skip: !torBuilt);
}
