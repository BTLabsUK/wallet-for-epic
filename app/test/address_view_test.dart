// SPDX-License-Identifier: Apache-2.0
// The phone's address widgets: an Epicbox server whole on its own line, a link's host:port
// never broken, the selectable text exactly what is shown.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/address_view.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _epicbox = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';

Widget _app(Widget child) => MaterialApp(
  theme: buildWalletTheme(protocolDark, Brightness.dark),
  home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
);

void main() {
  testWidgets('MarkedAddress: the key, then the server whole on its own line', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const MarkedAddress(_epicbox)));
    expect(find.text('@epicbox.epiccash.com'), findsOneWidget);
    expect(find.byType(FittedBox), findsOneWidget);
    expect(find.bySemanticsLabel(_epicbox), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('MarkedAddress, selectable: the selectable text is exactly the key', (tester) async {
    await tester.pumpWidget(_app(const MarkedAddress(_epicbox, selectable: true)));
    final key = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(key.textSpan!.toPlainText(), _epicbox.split('@').first);
  });

  testWidgets('a link that fits stays on one line with its host:port whole', (tester) async {
    await tester.pumpWidget(_app(const MarkedAddress('http://192.168.1.20:3415/')));
    expect(find.byType(Column), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap that copies is the address\'s one node, read as Copy', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildWalletTheme(protocolDark, Brightness.dark),
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: MarkedAddress(_epicbox, selectable: true, onTap: () => taps++)))),
      ),
    );
    final node = tester.getSemantics(find.byType(MarkedAddress));
    expect(node.label, _epicbox);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.hintOverrides?.onTapHint, _l.commonCopy);
    tester.semantics.tap(find.semantics.byLabel(_epicbox));
    expect(taps, 1);
    handle.dispose();
  });
}
