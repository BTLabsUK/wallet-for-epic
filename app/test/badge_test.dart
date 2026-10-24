// The shared badge: one widget for the phone and the desktop, styled by each theme.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart' show deskScale;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/badge.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';

Widget _phone(Widget child) => MaterialApp(
  theme: buildWalletTheme(protocolDark, Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [child]))),
);

Widget _desk(Widget child) => MaterialApp(
  theme: buildDeskTheme(Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [child]))),
);

Color _ink(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('both themes carry a BadgeStyle and the badge takes its tone from it', (tester) async {
    await tester.pumpWidget(_phone(const EBadge('Default')));
    final phone = BadgeStyle.of(tester.element(find.byType(EBadge)));
    expect(_ink(tester, 'Default'), phone.neutral);
    expect(phone.scale, 1);

    await tester.pumpWidget(_desk(const EBadge('Ok', tone: BadgeTone.ok)));
    await tester.pumpAndSettle(); // the theme change animates
    final desk = BadgeStyle.of(tester.element(find.byType(EBadge)));
    expect(_ink(tester, 'Ok'), desk.ok);
    expect(desk.scale, deskScale);
    expect(desk.ok, isNot(phone.neutral));
  });

  testWidgets('a badge is 20 dp tall, one line, and reads as its label', (tester) async {
    await tester.pumpWidget(_phone(const EBadge('Experimental')));
    expect(tester.getSize(find.byType(EBadge)).height, 20);
    expect(tester.widget<Text>(find.text('Experimental')).maxLines, 1);
    expect(find.bySemanticsLabel('Experimental'), findsOneWidget);
  });

  testWidgets('kind: the method glyph and its name', (tester) async {
    await tester.pumpWidget(
      _phone(
        Builder(builder: (context) => EBadge.kind(RecipientKind.tor, l: AppLocalizations.of(context)!)),
      ),
    );
    expect(find.byIcon(EpicGlyphs.tor), findsOneWidget);
    expect(find.text('Link Payment · Tor'), findsOneWidget);

    await tester.pumpWidget(
      _desk(
        Builder(builder: (context) => EBadge.kind(RecipientKind.epicbox, l: AppLocalizations.of(context)!)),
      ),
    );
    expect(find.byIcon(EpicGlyphs.epicbox), findsOneWidget);
    expect(find.text('Epicbox'), findsOneWidget);
  });

  testWidgets('state: On is ok with a dot, Off neutral', (tester) async {
    await tester.pumpWidget(_phone(const EBadge.state('On', on: true)));
    final s = BadgeStyle.of(tester.element(find.byType(EBadge)));
    expect(_ink(tester, 'On'), s.ok);
    await tester.pumpWidget(_phone(const EBadge.state('Off', on: false)));
    expect(_ink(tester, 'Off'), s.neutral);
  });

  testWidgets('tor: ok over Tor, a spinner while it starts, risk when blocked', (tester) async {
    await tester.pumpWidget(_phone(EBadge.tor('Over Tor', way: TorWay.overTor)));
    final s = BadgeStyle.of(tester.element(find.byType(EBadge)));
    expect(_ink(tester, 'Over Tor'), s.ok);
    expect(find.byIcon(EpicGlyphs.tor), findsOneWidget);

    await tester.pumpWidget(_phone(EBadge.tor('Tor starting', way: TorWay.wait)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(EpicGlyphs.tor), findsNothing);
    expect(_ink(tester, 'Tor starting'), s.info);

    await tester.pumpWidget(_phone(EBadge.tor('Tor not connected', way: TorWay.blocked)));
    expect(_ink(tester, 'Tor not connected'), s.risk);
  });

  testWidgets('a glyph-only badge keeps its words for a screen reader', (tester) async {
    await tester.pumpWidget(_phone(const EBadge(null, icon: Icons.edit_outlined, semanticsLabel: 'Added by you')));
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Added by you'), findsOneWidget);
    expect(tester.getSize(find.byType(EBadge)).width, 20);
  });

  testWidgets('a long label is cut, never wrapped', (tester) async {
    await tester.pumpWidget(
      _phone(const SizedBox(width: 60, child: EBadge('A label far too long for this row'))),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(EBadge)).width, lessThanOrEqualTo(60));
    expect(tester.getSize(find.byType(EBadge)).height, 20);
  });
}
