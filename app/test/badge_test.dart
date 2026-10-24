// The shared badge: one widget for the phone and the desktop, styled from each theme's
// tokens, drawn in the look [badgeLook] picks.
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart' show deskScale;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/badge.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

Color _words(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style!.color!;
Color _glyph(WidgetTester tester, IconData icon) => tester.widget<Icon>(find.byIcon(icon)).color!;
BadgeStyle _style(WidgetTester tester) => BadgeStyle.of(tester.element(find.byType(EBadge)));

/// The dot's fill, from the one circular box inside the badge.
Color? _dot(WidgetTester tester) {
  final boxes = tester.widgetList<Container>(find.descendant(of: find.byType(EBadge), matching: find.byType(Container)));
  final dot = boxes.map((c) => c.decoration).whereType<BoxDecoration>().firstWhere((d) => d.shape == BoxShape.circle);
  return dot.color;
}

void main() {
  testWidgets('the style comes from the theme in force: wallet tokens on the phone, desk tokens on the desktop', (tester) async {
    await tester.pumpWidget(_phone(const EBadge('Default', icon: Icons.star)));
    final phone = _style(tester);
    expect(phone.scale, 1);
    expect(_glyph(tester, Icons.star), phone.neutral);

    await tester.pumpWidget(_desk(const EBadge('Ok', icon: Icons.star, tone: BadgeTone.ok)));
    await tester.pumpAndSettle(); // the theme change animates
    final desk = _style(tester);
    expect(desk.scale, deskScale);
    expect(_glyph(tester, Icons.star), desk.ok);
    expect(desk.ok, isNot(phone.neutral));
  });

  testWidgets('the glyph carries the tone; the words stay muted', (tester) async {
    await tester.pumpWidget(_phone(const EBadge('Limited info', icon: Icons.info_outline, tone: BadgeTone.warn)));
    final s = _style(tester);
    expect(_glyph(tester, Icons.info_outline), s.warn);
    expect(_words(tester, 'Limited info'), anyOf(s.dim, s.text));
    expect(_words(tester, 'Limited info'), isNot(s.warn));
  });

  testWidgets('a badge is small, one line, and reads as its label', (tester) async {
    await tester.pumpWidget(_phone(const EBadge('Experimental')));
    expect(tester.getSize(find.byType(EBadge)).height, lessThanOrEqualTo(18));
    expect(tester.widget<Text>(find.text('Experimental')).maxLines, 1);
    expect(find.bySemanticsLabel('Experimental'), findsOneWidget);
  });

  testWidgets('kind: the method glyph and its name; compact keeps the name for the tooltip and the reader', (tester) async {
    await tester.pumpWidget(
      _phone(Builder(builder: (context) => EBadge.kind(RecipientKind.tor, l: AppLocalizations.of(context)))),
    );
    expect(find.byIcon(EpicGlyphs.tor), findsOneWidget);
    expect(find.text('Tor'), findsOneWidget); // the short name; the full one only in a tooltip

    await tester.pumpWidget(
      _desk(Builder(builder: (context) => EBadge.kind(RecipientKind.epicbox, l: AppLocalizations.of(context), compact: true))),
    );
    expect(find.byIcon(EpicGlyphs.epicbox), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Epicbox'), findsOneWidget);
    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Epicbox');
  });

  testWidgets('state: On is a filled ok dot, Off a ring', (tester) async {
    await tester.pumpWidget(_phone(const EBadge.state('On', on: true)));
    final s = _style(tester);
    expect(_dot(tester), s.ok);
    await tester.pumpWidget(_phone(const EBadge.state('Off', on: false)));
    expect(_dot(tester), Colors.transparent);
  });

  testWidgets('tor: ok over Tor, a spinner while it starts, risk when blocked', (tester) async {
    await tester.pumpWidget(_phone(EBadge.tor('Over Tor', way: TorWay.overTor)));
    final s = _style(tester);
    expect(_glyph(tester, EpicGlyphs.tor), s.ok);

    await tester.pumpWidget(_phone(EBadge.tor('Tor starting', way: TorWay.wait)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(EpicGlyphs.tor), findsNothing);
    expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).color, s.info);

    await tester.pumpWidget(_phone(EBadge.tor('Tor not connected', way: TorWay.blocked)));
    expect(_glyph(tester, EpicGlyphs.tor), s.risk);
  });

  testWidgets('a glyph-only badge keeps its words for a screen reader', (tester) async {
    await tester.pumpWidget(_phone(const EBadge(null, icon: Icons.edit_outlined, semanticsLabel: 'Added by you')));
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Added by you'), findsOneWidget);
    expect(tester.getSize(find.byType(EBadge)).width, lessThanOrEqualTo(18));
  });

  testWidgets('a long label is cut, never wrapped', (tester) async {
    await tester.pumpWidget(
      _phone(const SizedBox(width: 60, child: EBadge('A label far too long for this row'))),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(EBadge)).width, lessThanOrEqualTo(60));
    expect(tester.getSize(find.byType(EBadge)).height, lessThanOrEqualTo(18));
  });

  testWidgets('every look draws every form without an exception', (tester) async {
    final before = badgeLook;
    try {
      for (final look in BadgeLook.values) {
        badgeLook = look;
        await tester.pumpWidget(
          _phone(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EBadge('Plain'),
                const EBadge('Glyph', icon: Icons.star, tone: BadgeTone.gold),
                const EBadge.state('On', on: true),
                const EBadge(null, icon: Icons.star, semanticsLabel: 'Star'),
                EBadge.tor('Starting', way: TorWay.wait),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: look.name);
        expect(find.byType(EBadge), findsNWidgets(5), reason: look.name);
      }
    } finally {
      badgeLook = before;
    }
  });
}
