// SPDX-License-Identifier: Apache-2.0
// The Ready pill carries a Tor badge on its top-left corner while Tor is on, and is unchanged
// otherwise.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/kit/kit_status_pill.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool tor, {bool dark = false, bool ready = true}) => MaterialApp(
  theme: buildWalletTheme(dark ? protocolDark : protocolLight, dark ? Brightness.dark : Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(24), child: KitStatusPill(ready: ready, tor: tor)))),
);

void main() {
  testWidgets('no Tor badge while Tor is off', (tester) async {
    await tester.pumpWidget(_app(false));
    expect(find.byIcon(EpicGlyphs.tor), findsNothing);
    expect(find.bySemanticsLabel('Ready'), findsOneWidget);
  });

  for (final ready in [true, false]) {
    testWidgets('Tor badge on the top-left corner, ready=$ready', (tester) async {
      await tester.pumpWidget(_app(true, ready: ready));
      expect(find.byIcon(EpicGlyphs.tor), findsOneWidget);
      final badge = tester.getTopLeft(find.byIcon(EpicGlyphs.tor));
      final pill = tester.getTopLeft(find.byType(KitStatusPill));
      expect((badge - pill).dx.abs() < 12 && (badge - pill).dy.abs() < 12, isTrue);
    });
  }
}
