// SPDX-License-Identifier: Apache-2.0
// Opening a flow from Home closes the screens over the shell, but not a Send that has sent or is
// sending: it stays, and a request for Send brings it forward.
import 'package:epic_wallet/src/ui/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<NavigatorState> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('shell')));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(settings: const RouteSettings(name: sendFlowRouteName), builder: (_) => const Text('send')));
    await tester.pumpAndSettle();
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('other')));
    await tester.pumpAndSettle();
    return navigator;
  }

  testWidgets('a Send that holds a payment stays when the screens over the shell close', (tester) async {
    final navigator = await open(tester);
    final owner = Object();
    sendHoldsPayment(owner, true);
    addTearDown(() => sendHoldsPayment(owner, false));
    expect(popToShell(navigator), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('send'), findsOneWidget);
    expect(find.text('other'), findsNothing);
  });

  testWidgets('a Send with nothing sent closes with the rest', (tester) async {
    final navigator = await open(tester);
    final owner = Object();
    sendHoldsPayment(owner, true);
    sendHoldsPayment(owner, false);
    expect(popToShell(navigator), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('shell'), findsOneWidget);
    expect(find.text('send'), findsNothing);
  });
}
