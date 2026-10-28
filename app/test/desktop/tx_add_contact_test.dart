// SPDX-License-Identifier: Apache-2.0
// The other side of a payment, on the desktop detail as on the phone: "Sent to" / "Received
// from" with Add to contacts while no contact holds the address. It opens the contact form
// with the address in; Save goes back to the payment, which then shows the name. Not for a
// file, a mining reward or an address a contact already has.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late ProviderContainer _container;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Activity on the mock with [txId] open; the contact [forget] deleted first.
Future<MockDeskWallet> _open(WidgetTester tester, int txId, {String? forget}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    if (forget != null) await api.deleteContact(forget);
    await _container.read(deskProvider.notifier).refresh();
  });
  _container.read(deskNavProvider.notifier).reset(DeskRoute.activity, txId);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
  return api;
}

final _add = find.byKey(const ValueKey('tx-add-contact'));

void main() {
  testWidgets('a send to an address no contact has: Sent to, Add to contacts, saved, named', (tester) async {
    await _open(tester, 28, forget: 'c1');
    final tx = _container.read(deskProvider).txs!.firstWhere((t) => t.id == 28);
    expect(tx.contactName, isNull);
    expect(find.text('Sent to'), findsOneWidget);
    expect(_add, findsOneWidget);

    await tester.ensureVisible(_add);
    await tester.tap(_add);
    await _settle(tester);
    expect(_container.read(deskNavProvider).route, DeskRoute.contacts);
    expect(find.text('New contact'), findsWidgets);
    // The address is in; the name field has the focus.
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == tx.counterparty), findsOneWidget);
    await tester.enterText(find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus), 'Anna again');
    await tester.tap(find.widgetWithText(EButton, 'Save contact'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);

    // Back on the payment, which now names her, here and in its row.
    final nav = _container.read(deskNavProvider);
    expect((nav.route, nav.arg), (DeskRoute.activity, 28));
    expect(_container.read(deskProvider).txs!.firstWhere((t) => t.id == 28).contactName, 'Anna again');
    expect(find.textContaining('to Anna again', findRichText: true), findsWidgets);
    expect(_add, findsNothing);
  });

  testWidgets('a receive from an unsaved address says Received from and offers it too', (tester) async {
    await _open(tester, 27, forget: 'c2');
    expect(find.text('Received from'), findsOneWidget);
    expect(_add, findsOneWidget);
  });

  testWidgets('Cancel in the form goes back to the payment, nothing saved', (tester) async {
    await _open(tester, 28, forget: 'c1');
    final before = _container.read(deskProvider).contacts!.length;
    await tester.ensureVisible(_add);
    await tester.tap(_add);
    await _settle(tester);
    await tester.tap(find.widgetWithText(EButton, 'Cancel'));
    await _settle(tester);
    expect(_container.read(deskNavProvider).route, DeskRoute.activity);
    expect(_container.read(deskProvider).contacts!.length, before);
    expect(_add, findsOneWidget);
  });

  for (final (id, what) in [(28, 'a saved contact'), (38, 'a file'), (101, 'a mining reward')]) {
    testWidgets('no offer for $what', (tester) async {
      await _open(tester, id);
      expect(_add, findsNothing);
    });
  }

  test('ContactsArgs keeps the address and the payment to go back to', () {
    const a = ContactsArgs(adding: true, address: 'x', fromTx: 3);
    expect((a.address, a.fromTx), ('x', 3));
  });
}
