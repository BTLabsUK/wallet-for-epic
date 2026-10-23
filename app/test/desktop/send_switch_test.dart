// Send's method follows the address (spec 8.4): a complete address of another kind, or a
// pasted one, switches; text still being typed never does, and nothing switches back.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd';
const _epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<List<Contact>> contacts() async => [
    ...await super.contacts(),
    const Contact(id: 'tor1', name: 'Onion Olga', address: '$_onion.onion'),
  ];
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]));
  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester, SendArgs args) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
      ),
    );
    await tester.pumpAndSettle();
  }

  TxMethod method(WidgetTester tester) => tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>)).value;
  Finder to() => find.byType(EditableText).first;
  Finder tag() => find.descendant(of: find.byKey(const ValueKey('send-switch-tag')), matching: find.text('Direct'));

  /// Types [text] one character at a time; the method after each.
  Future<List<TxMethod>> type(WidgetTester tester, String text) async {
    final seen = <TxMethod>[];
    for (var i = 1; i <= text.length; i++) {
      await tester.enterText(to(), text.substring(0, i));
      await tester.pump();
      seen.add(method(tester));
    }
    return seen;
  }

  testWidgets('typing "es" under Direct stays on Direct', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http));
    await type(tester, 'es');
    expect(method(tester), TxMethod.http);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a pasted Epicbox address under Direct switches to Epicbox and says so', (tester) async {
    await show(tester, const SendArgs(method: TxMethod.http));
    await tester.enterText(to(), _epicbox);
    await tester.pump();
    expect(method(tester), TxMethod.epicbox);
    expect(find.text('Via Epicbox'), findsOneWidget);
    expect(find.text(_epicbox), findsOneWidget, reason: 'the field keeps its text');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('send-switch-tag'))).opacity, 0, reason: 'the tag goes after 3 s');
  });

  testWidgets('an onion typed char by char switches to Direct once, at the last char, never back', (tester) async {
    await show(tester, const SendArgs());
    final seen = await type(tester, _onion);
    final first = seen.indexOf(TxMethod.http);
    expect(first, _onion.length - 1, reason: 'only when the address is complete');
    expect(seen.skip(first), everyElement(TxMethod.http));
    expect(tag(), findsOneWidget);
    // Deleting a character makes it incomplete: the method stays.
    await tester.enterText(to(), _onion.substring(0, 50));
    await tester.pump();
    expect(method(tester), TxMethod.http);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('http://10.0.1.24 typed switches to HTTP once the host is complete', (tester) async {
    await show(tester, const SendArgs());
    final seen = await type(tester, 'http://10.0.1.24');
    expect(seen.first, TxMethod.epicbox);
    expect(seen.last, TxMethod.http);
    final first = seen.indexOf(TxMethod.http);
    expect(seen.skip(first), everyElement(TxMethod.http));
    expect(first, greaterThanOrEqualTo('http://1'.length), reason: 'not while only the scheme is there');
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('picking an onion contact switches to Direct', (tester) async {
    await show(tester, const SendArgs());
    await tester.enterText(to(), 'Olga');
    await tester.pump();
    await tester.tap(find.text('Onion Olga'));
    await tester.pump();
    expect(method(tester), TxMethod.http);
    expect(tag(), findsOneWidget);
    expect(find.byKey(const ValueKey('send-picked')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
