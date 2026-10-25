// A contact's Pairing block on the desktop (SPEC 2.4): Verified with its switches, Allow
// invoices off for a contact not verified, keys changed, Not paired with Pair, and deleting a
// paired contact removes this wallet's pairing too.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart' show FakePairing;
import 'package:epic_wallet/src/wallet_service.dart' show PairingApi;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';

// The mock pairs Anna (c1, verified), Tom (c4, paired, not verified) and Marta (c9, keys
// changed); Piotr (c6) is not paired.
late ProviderContainer _c;

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  // The mock's own delays run on the test clock.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, ContactsArgs arg) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet())]);
  addTearDown(_c.dispose);
  await tester.runAsync(() => _c.read(deskProvider.notifier).refresh());
  _c.read(deskInvoicesProvider);
  await _real(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: ContactsScreen(arg: arg)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

final _l = englishStrings;

PairingApi get _pairing => (_c.read(deskApiProvider) as MockDeskWallet).pairing;

ESwitch _switchOf(WidgetTester tester, String label) =>
    tester.widget<ESwitch>(find.byWidgetPredicate((w) => w is ESwitch && w.semanticLabel == label));

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('a verified contact: Verified, the date, both switches on', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    expect(find.text(_l.contactPairing), findsOneWidget);
    expect(find.text(_l.trustVerified), findsWidgets);
    expect(find.text(_l.contactCheckAgain), findsOneWidget);
    expect(_switchOf(tester, _l.contactSealPayments).value, isTrue);
    final allow = _switchOf(tester, _l.contactAllowInvoices);
    allow.onChanged!(!allow.value);
    await _real(tester);
    expect((await tester.runAsync(() => _pairing.pairing(mockAnnaPairing)))!.allowInvoices, !allow.value);
  });

  testWidgets('a contact not verified: Allow invoices waits for the words check', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c4'));
    expect(find.text(_l.trustPaired), findsWidgets);
    expect(find.text(_l.contactCheckWordsFirst), findsOneWidget);
    expect(_switchOf(tester, _l.contactAllowInvoices).onChanged, isNull);
  });

  testWidgets('keys changed: the notice with its three ways out, both switches paused', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c9'));
    expect(find.text(_l.contactKeysChangedTitle('Marta W.')), findsOneWidget);
    expect(find.text(_l.contactKeysChangedBody), findsOneWidget);
    for (final t in [_l.sasTitle, _l.contactKeepOldKeys, _l.contactUseNewKeys]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text(_l.contactPausedUntilChecked), findsNWidgets(2));
  });

  testWidgets('a contact not paired offers Pair', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c6'));
    expect(find.text(_l.pairNotPaired), findsOneWidget);
    expect(find.text(_l.pairNotPairedHint), findsOneWidget);
  });

  testWidgets('deleting a paired contact says the pairing goes, and removes it', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining(_l.contactDeletePaired('Anna Kowalska')), findsOneWidget);
    await tester.tap(find.text('Delete contact'));
    await _real(tester, 800);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c1'), isFalse);
    expect(await tester.runAsync(() => _pairing.pairing(mockAnnaPairing)), isNull);
  });

  testWidgets('a contact not paired is deleted without the pairing line', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c6'));
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining(_l.contactDeletePaired('Piotr Nowak')), findsNothing);
    await tester.tap(find.text('Delete contact'));
    await _real(tester, 800);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c6'), isFalse);
  });

  testWidgets('keys back: the contact page docks the notice until OK (PAIR-LNX-15)', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsNothing);
    (_pairing as FakePairing).restoreKeys(mockAnnaPairing);
    await _real(tester);
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsOneWidget);
    expect(find.text(_l.contactKeysBackBody), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.commonOk));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsNothing);
  });
}
