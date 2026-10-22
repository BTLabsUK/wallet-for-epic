// EShortAddress (spec 7.1): the full short form when it fits, the compact form when it does not,
// never a tail ellipsis; the whole address in the tooltip and the screen-reader label.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';

const _epicbox = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
const _tor = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
const _http = 'https://pay.example.org/v2/foreign';

Future<void> _pump(WidgetTester tester, Widget child, double width) => tester.pumpWidget(
  MaterialApp(
    theme: buildDeskTheme(Brightness.dark),
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: child)),
    ),
  ),
);

String _shown(WidgetTester tester) => tester.widget<Text>(find.descendant(of: find.byType(EShortAddress), matching: find.byType(Text))).data!;

void main() {
  for (final (a, full, compact) in [
    (_epicbox, 'esWxbo…3jUcNK@epicbox.epiccash.com', 'esWxbo…3jUcNK'),
    (_tor, 'wfe7q3…abcdid.onion', 'wfe7q3…abcdid'),
    (_http, 'https://pay.example.org/…', 'pay.example.org/…'),
  ]) {
    testWidgets('$full in a wide cell and its compact form in a narrow one', (tester) async {
      await _pump(tester, EShortAddress(a), 700);
      expect(_shown(tester), full);
      await _pump(tester, EShortAddress(a), 200);
      expect(_shown(tester), compact);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the screen reader and the tooltip get the whole address', (tester) async {
    await _pump(tester, const EShortAddress(_epicbox), 420);
    expect(find.bySemanticsLabel(_epicbox), findsOneWidget);
    final tip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tip.richMessage!.toPlainText(), _epicbox);
  });

  testWidgets('a contact row keeps name, tag and address; the note gives way first', (tester) async {
    const lines = EAddressLines(name: 'BT Labs', address: _epicbox, note: 'Donations support development of this wallet.');
    await _pump(tester, lines, 1000);
    expect(find.text('Epicbox'), findsOneWidget);
    expect(_shown(tester), 'esWxbo…3jUcNK@epicbox.epiccash.com');
    expect(find.textContaining('Donations'), findsOneWidget);
    await _pump(tester, lines, 240);
    expect(_shown(tester), 'esWxbo…3jUcNK');
    expect(find.textContaining('Donations'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
