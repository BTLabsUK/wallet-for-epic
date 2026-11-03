// SPDX-License-Identifier: Apache-2.0
// Send keeps its draft when the page is left and opened again (people check the balance and
// come back), and a filled recipient always has Clear: it empties To and puts the method back
// where Send starts (tester report 26.10.21).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';
const _epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
const _http = 'http://192.168.1.24:3415';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<List<Contact>> contacts() async => [
    ...await super.contacts(),
    Contact(id: 'ol', name: 'Olga Link', address: _http),
  ];
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]));
  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> show(WidgetTester tester, [Object? arg]) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await pump(tester, SendScreen(arg: arg));
  }

  /// Another page, then Send again as the sidebar opens it (no argument).
  Future<void> leaveAndBack(WidgetTester tester) async {
    await pump(tester, const Text('Overview'));
    expect(find.byType(SendScreen), findsNothing);
    await pump(tester, const SendScreen());
  }

  // There is no method selector: the method line under To names what the address chose, none while To is empty.
  String? method(WidgetTester tester) => const ['epicbox', 'onion', 'http', 'https']
      .where((k) => find.byKey(ValueKey('send-route-$k')).evaluate().isNotEmpty)
      .firstOrNull;
  String toText(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText).first).controller.text;
  Finder clear() => find.byKey(const ValueKey('send-to-clear'));

  testWidgets('a pasted address stays after leaving Send; × empties To and puts the method back', (tester) async {
    await show(tester);
    expect(method(tester), isNull);
    await tester.enterText(find.byType(EditableText).first, _onion);
    await tester.enterText(find.byType(EditableText).at(1), '2');
    await tester.pump(const Duration(seconds: 4));
    expect(method(tester), 'onion', reason: 'the onion is read as Link · Tor');

    await leaveAndBack(tester);
    expect(toText(tester), _onion);
    expect(method(tester), 'onion');
    expect(tester.widget<EditableText>(find.byType(EditableText).at(1)).controller.text, '2');

    expect(tester.widget<EIconButton>(clear()).tabStop, isTrue, reason: 'no card below: the × is the Tab stop');
    await tester.tap(clear());
    await tester.pumpAndSettle();
    expect(toText(tester), isEmpty);
    expect(method(tester), isNull, reason: 'back to Send as it starts: no address, no method line');
    expect(clear(), findsNothing);
    expect(tester.widget<EditableText>(find.byType(EditableText).at(1)).controller.text, '2', reason: 'a typed amount stays');
  }, skip: !torBuilt);

  testWidgets('a picked contact stays after leaving Send; its Clear resets the recipient', (tester) async {
    final olga = (await container.read(deskApiProvider).contacts()).firstWhere((c) => c.id == 'ol');
    await show(tester, olga);
    expect(method(tester), 'http');
    expect(find.byKey(const ValueKey('send-picked')), findsOneWidget);

    await leaveAndBack(tester);
    expect(method(tester), 'http');
    expect(find.byKey(const ValueKey('send-picked')), findsOneWidget, reason: 'the chip stands for the address');
    expect(tester.widget<EIconButton>(clear()).tabStop, isTrue, reason: "the chip's × is the Tab stop");

    await tester.tap(clear());
    await tester.pumpAndSettle();
    expect(toText(tester), isEmpty);
    expect(method(tester), isNull);
    expect(find.byKey(const ValueKey('send-picked')), findsNothing);

    // Cleared and left: Send opens empty.
    await leaveAndBack(tester);
    expect(toText(tester), isEmpty);
  });

  testWidgets('a pasted Epicbox address: × empties it, the draft is gone after leaving', (tester) async {
    await show(tester);
    await tester.enterText(find.byType(EditableText).first, _epicbox);
    await tester.pump(const Duration(seconds: 4));
    await leaveAndBack(tester);
    expect(toText(tester), _epicbox);
    expect(method(tester), 'epicbox');
    await tester.tap(clear());
    await tester.pumpAndSettle();
    expect(toText(tester), isEmpty);
    expect(method(tester), isNull);
    await leaveAndBack(tester);
    expect(toText(tester), isEmpty);
  });

  testWidgets('a lock drops the draft with the rest of the open wallet', (tester) async {
    await show(tester);
    await tester.enterText(find.byType(EditableText).first, _onion);
    await tester.pump(const Duration(seconds: 4));
    await pump(tester, const Text('Overview'));
    await tester.runAsync(() async {
      await container.read(deskProvider.notifier).lock();
      await container.read(deskProvider.notifier).refresh();
    });
    await pump(tester, const SendScreen());
    expect(toText(tester), isEmpty);
  });
}
