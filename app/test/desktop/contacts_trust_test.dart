// A contact's Trusted switch reads LEPIC's list by key, a rename updates the trusted label, and
// deleting a trusted contact asks whether to stop trusting it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';

// Anna (c1) is on the mock's trusted list by her payments address; Piotr (c6) has an invoice
// address and is not trusted.
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

ESwitch _switch(WidgetTester tester) => tester.widget<ESwitch>(find.byType(ESwitch).first);

void main() {
  testWidgets('the switch is on for a contact on LEPIC\'s list and follows a change of it', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    expect(_switch(tester).value, isTrue);
    await tester.runAsync(() => _c.read(deskInvoicesProvider.notifier).untrust(_c.read(deskInvoicesProvider)!.trusted.firstWhere((t) => t.contactId == 'c1').address));
    await _real(tester);
    expect(_switch(tester).value, isFalse, reason: 'read from the list, not kept apart');
  });

  testWidgets('turning it on trusts the invoice address when the contact has one', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c6'));
    expect(_switch(tester).value, isFalse);
    final piotr = _c.read(deskProvider).contacts!.firstWhere((x) => x.id == 'c6');
    _switch(tester).onChanged!(true);
    await _real(tester);
    final entry = _c.read(deskInvoicesProvider)!.trusted.firstWhere((t) => t.contactId == 'c6');
    expect(entry.address, piotr.invoiceAddress);
    expect(_switch(tester).value, isTrue);
  });

  testWidgets('renaming a trusted contact updates the trusted label', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1', editing: true));
    final name = find.descendant(of: find.widgetWithText(EField, 'Name'), matching: find.byType(EditableText));
    await tester.enterText(name, 'Anna K.');
    await tester.pump();
    await tester.tap(find.text('Save contact'));
    await _real(tester, 800);
    expect(_c.read(deskInvoicesProvider)!.trusted.firstWhere((t) => t.contactId == 'c1').label, 'Anna K.');
  });

  testWidgets('deleting a trusted contact asks about trust; Remove stops it', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Delete contact'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stop trusting Anna Kowalska?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await _real(tester, 800);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c1'), isFalse);
    expect(_c.read(deskInvoicesProvider)!.trusted.any((t) => t.contactId == 'c1'), isFalse);
  });

  testWidgets('Keep deletes the contact and leaves the sender trusted', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c1'));
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Delete contact'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Keep'));
    await _real(tester, 800);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c1'), isFalse);
    expect(_c.read(deskInvoicesProvider)!.trusted.any((t) => t.label == 'Anna Kowalska'), isTrue);
  });

  testWidgets('an untrusted contact is deleted without the question', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c6'));
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Delete contact'));
    await _real(tester, 800);
    expect(find.textContaining('Stop trusting'), findsNothing);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c6'), isFalse);
  });
}
