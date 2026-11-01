// SPDX-License-Identifier: Apache-2.0
// The To field draws a link's scheme and host in lower case over what was typed; the text,
// which is what is parsed and sent, stays as typed.

import 'package:epic_wallet/src/address_field.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _typed = 'HTTP://WFE7Q3K2MZ5XR4TBV6LD5YHNPJC7SGO2A3UE6IWQ4FK7TR3MXZABCDID.ONION/';
const _onion = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
const _epicbox = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';

Widget _app(Widget child) => MaterialApp(
  theme: buildWalletTheme(protocolDark, Brightness.dark),
  home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
);

void main() {
  testWidgets('the To field shows a typed onion link in lower case, its text as typed', (tester) async {
    final c = AddressFieldController();
    await tester.pumpWidget(_app(TextField(controller: c)));
    await tester.enterText(find.byType(TextField), _typed);
    await tester.pump();
    expect(c.text, _typed);
    final shown = c.buildTextSpan(context: tester.element(find.byType(TextField)), withComposing: false).toPlainText();
    expect(shown, 'http://$_onion/');
    // What is parsed (and sent) is the same as without the field's display.
    expect(parseRecipient(c.text).address, _onion);
    expect(parseRecipient(c.text).address, parseRecipient(_typed).address);
    expect(parseRecipient(c.text).kind, RecipientKind.tor);
    c.dispose();
  });

  testWidgets('an Epicbox key is drawn as typed: its case is part of it', (tester) async {
    final c = AddressFieldController(text: _epicbox);
    await tester.pumpWidget(_app(TextField(controller: c)));
    final shown = c.buildTextSpan(context: tester.element(find.byType(TextField)), withComposing: false).toPlainText();
    expect(shown, _epicbox);
    c.dispose();
  });
}
