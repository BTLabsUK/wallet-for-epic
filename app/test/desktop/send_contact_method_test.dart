// SPDX-License-Identifier: Apache-2.0
// Send to a contact with only an Epicbox address (BT Labs' donation entry, 26.10.25): Send goes
// by Epicbox, and the method-off notice never says the contact has only a Link address.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _box = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.epic.invalid';
final _btlabs = Contact(id: 'c-btlabs', name: 'BT Labs', epicbox: _box);

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, {Object? arg, PaymentPrefs payments = PaymentPrefs.defaults}) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => NetGate.setPayments(PaymentPrefs.defaults));
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(payments: payments, tourSeen: true));
    await n.saveContact(Contact(id: '', name: 'BT Labs', epicbox: _box));
  });
  _container.read(deskNavProvider.notifier).reset(DeskRoute.send, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

TxMethod? _selected(WidgetTester tester) => tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>).first).value;

String _to(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText).first).controller.text;

void main() {
  testWidgets('a contact with only an Epicbox address opens Send on Epicbox, no notice', (tester) async {
    await _open(tester, arg: SendArgs(contact: _btlabs));
    expect(_to(tester), _box);
    expect(_selected(tester), TxMethod.epicbox);
    expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
  });

  testWidgets('Link picked, then the contact: Send moves to Epicbox, no Link notice', (tester) async {
    await _open(tester, arg: const SendArgs());
    await tester.tap(find.descendant(of: find.byType(ESegmented<TxMethod?>), matching: find.text('Link')));
    await _settle(tester);
    expect(_selected(tester), TxMethod.http);
    await tester.enterText(find.byType(EditableText).first, 'BT La');
    await _settle(tester);
    await tester.tap(find.text('BT Labs').last);
    await _settle(tester);
    expect(_to(tester), _box);
    expect(_selected(tester), TxMethod.epicbox);
    expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
  });

  testWidgets('Epicbox off moves Send to Link; Epicbox back on: the Epicbox address in To goes by Epicbox again', (tester) async {
    await _open(tester, arg: SendArgs(contact: _btlabs), payments: const PaymentPrefs(epicbox: false));
    expect(_to(tester), _box);
    final n = _container.read(deskProvider.notifier);
    await tester.runAsync(() => n.saveSettings(_container.read(deskProvider).settings.copyWith(payments: PaymentPrefs.defaults)));
    await _settle(tester);
    expect(_selected(tester), TxMethod.epicbox);
    expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    expect(find.textContaining('has only a Link'), findsNothing);
  });

  testWidgets('Link chosen by hand with an Epicbox address in To: the notice never says the contact has only a Link address', (tester) async {
    await _open(tester, arg: SendArgs(contact: _btlabs));
    await tester.tap(find.descendant(of: find.byType(ESegmented<TxMethod?>), matching: find.text('Link')));
    await _settle(tester);
    expect(find.textContaining('has only a Link'), findsNothing);
  });
}
