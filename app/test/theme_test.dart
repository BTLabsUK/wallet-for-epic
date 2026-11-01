// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/theme/tokens.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (mode, t, b) in [
    ('dark', protocolDark, Brightness.dark),
    ('light', protocolLight, Brightness.light),
  ]) {
    group('Protocol $mode', () {
      test('every text colour passes AA (4.5:1) where it is used', () {
        final scheme = buildWalletTheme(t, b).colorScheme;
        final pairs = <String, (Color, Color)>{
          'text on bg': (t.text, t.bg),
          'text on surface': (t.text, t.surface),
          'text on surfaceHi': (t.text, t.surfaceHi),
          'text on field': (t.text, t.field),
          'dim on bg': (t.dim, t.bg),
          'dim on surface': (t.dim, t.surface),
          'dim on field': (t.dim, t.field),
          'accentText on bg': (t.accentText, t.bg),
          'accentText on surface': (t.accentText, t.surface),
          'accentInk on accent': (t.accentInk, t.accent),
          // Status colours as text on every surface they appear on.
          for (final (sname, surface) in [
            ('bg', t.bg),
            ('surface', t.surface),
            ('surfaceHi', t.surfaceHi),
            ('field', t.field),
            ('raised', t.raised),
            ('selected', t.selected),
          ]) ...{
            // Hints, tags and metadata lines (the phone's faint once failed on surfaceHi).
            'faint on $sname': (t.faint, surface),
            'ok on $sname': (t.ok, surface),
            'warn on $sname': (t.warn, surface),
            'risk on $sname': (t.risk, surface),
            'info on $sname': (t.info, surface),
            'accentText on $sname': (t.accentText, surface),
            'dim on $sname': (t.dim, surface),
            'text on $sname': (t.text, surface),
            // Direction colours on amounts and icons in lists and details.
            'txSent on $sname': (t.txSent, surface),
            'txReceived on $sname': (t.txReceived, surface),
            'txCancelled on $sname': (t.txCancelled, surface),
          },
          // Status text on its own soft fill over a panel (notices, result glyphs).
          'ok on okSoft': (t.ok, Color.alphaBlend(t.okSoft, t.surface)),
          'warn on warnSoft': (t.warn, Color.alphaBlend(t.warnSoft, t.surface)),
          'risk on riskSoft': (t.risk, Color.alphaBlend(t.riskSoft, t.surface)),
          'info on infoSoft': (t.info, Color.alphaBlend(t.infoSoft, t.surface)),
          'text on infoSoft': (t.text, Color.alphaBlend(t.infoSoft, t.surface)),
          'bg on warn (onTertiary)': (t.bg, t.warn),
          'onTertiaryContainer': (
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
          ),
          'onSecondaryContainer': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'onErrorContainer': (scheme.onErrorContainer, scheme.errorContainer),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$mode $name',
          );
        }
      });

      test('a field and a well show their edge, a floating surface its soft shadow', () {
        // WCAG 1.4.11: a field's boundary at 3:1 against its fill and the page.
        expect(contrast(t.lineField, t.field), greaterThanOrEqualTo(3), reason: '$mode lineField on field');
        expect(contrast(t.lineField, t.bg), greaterThanOrEqualTo(3), reason: '$mode lineField on bg');
        final well = t.well;
        expect(well.color, t.field);
        expect((well.border! as Border).isUniform, isTrue, reason: 'a well has an edge on every side');
        expect((well.border! as Border).top.color, t.line);
        // The shadow is soft and low: never the dialog barrier, which drew a hard band.
        expect(t.shadow, isNot(t.scrim));
        expect(t.shadow.a, lessThanOrEqualTo(0.4));
        expect(t.popShadow.single.blurRadius, greaterThanOrEqualTo(16));
        final theme = buildWalletTheme(t, b);
        expect(theme.colorScheme.scrim, t.scrim);
        expect(theme.popupMenuTheme.color, t.raised);
      });

      test('a row subtitle is dim, set once in the theme', () {
        final theme = buildWalletTheme(t, b);
        expect(theme.listTileTheme.subtitleTextStyle?.color, t.dim);
        expect(theme.listTileTheme.textColor, isNull, reason: 'textColor would paint the subtitle too');
      });

      test('the status colours are not the brand gold', () {
        // Amber is apart from the gold: a clearly lower green channel, so a warning never
        // looks like the accent (which is what made a gold "current" row read as a warning).
        expect(t.warn, isNot(t.accent));
        expect(t.warn, isNot(t.accentText));
        // Orange has more red over green than yellow or brown: at least a tenth more.
        expect(
          (t.warn.r - t.warn.g) - (t.accent.r - t.accent.g),
          greaterThanOrEqualTo(0.1),
          reason: '$mode warn ${t.warn} must be orange next to accent ${t.accent}',
        );
        expect(t.ok, isNot(t.accent));
        expect(t.info, isNot(t.accent));
        // Direction: sent red (money out, never the gold and never the error tone), received
        // green, cancelled a neutral grey.
        expect(t.txSent, isNot(t.accentText));
        expect(t.txSent, isNot(t.risk));
        expect(t.txSent, isNot(t.warn));
        // Red: the red channel well over the others, and more so than the amber, so a sent
        // amount is never read as orange.
        expect(t.txSent.r - t.txSent.g, greaterThanOrEqualTo(0.4), reason: 'sent is red');
        expect(t.txSent.r - t.txSent.b, greaterThanOrEqualTo(0.4), reason: 'sent is red');
        expect((t.txSent.r - t.txSent.g) - (t.warn.r - t.warn.g), greaterThanOrEqualTo(0.1));
        // Apart from the error red side by side: at least a tenth away in RGB.
        final dr = t.txSent.r - t.risk.r, dg = t.txSent.g - t.risk.g, db = t.txSent.b - t.risk.b;
        expect(dr * dr + dg * dg + db * db, greaterThanOrEqualTo(0.01), reason: 'sent is not the risk red');
        expect(t.txReceived, t.ok);
        expect(t.txCancelled, isNot(t.warn));
        expect(t.txCancelled, isNot(t.risk));
        expect((t.txCancelled.r - t.txCancelled.b).abs(), lessThan(0.06), reason: 'cancelled is grey');
        // The selected treatment is neutral: a grey, not a tint of the accent.
        for (final c in [t.selected, t.selectedLine]) {
          expect((c.r - c.b).abs() * 255, lessThan(16), reason: '$mode $c');
        }
      });

      test('the theme carries the tokens and the display face', () {
        final theme = buildWalletTheme(t, b);
        expect(theme.extension<WalletTokens>(), same(t));
        expect(theme.textTheme.displaySmall?.fontFamily, montserrat);
        expect(theme.colorScheme.primary, t.accent);
        expect(theme.colorScheme.brightness, b);
      });

      testWidgets('the Protocol pieces render', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildWalletTheme(t, b),
            home: AdvancedOptions(prefs: AdvancedPrefs.all,
              child: Scaffold(
                body: ListView(
                  children: const [
                    Readout('Synced at block 2,500,000'),
                    ProtocolSectionHead('Recent activity'),
                    EdgeCard(edge: Colors.amber, child: Text('Waiting')),
                    StatusTimeline(
                      steps: [
                        TimelineStep('Payment started', TimelineState.done),
                        TimelineStep(
                          'Waiting for recipient',
                          TimelineState.current,
                        ),
                        TimelineStep('Posted to the network', TimelineState.todo),
                      ],
                    ),
                    Advanced(feature: AdvancedFeature.technicalDetails, child: Text('technical')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Synced at block 2,500,000'), findsOneWidget);
        expect(find.text('Waiting for recipient'), findsOneWidget);
        expect(find.text('technical'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Recent activity'),
          findsOneWidget,
          reason: 'the section head is announced as a heading',
        );
      });
    });
  }

  // One palette (ui/theme/palette.dart): every role both front ends have holds one value.
  for (final (mode, t, c) in [
    ('dark', protocolDark, deskDark),
    ('light', protocolLight, deskLight),
  ]) {
    test('phone and desktop $mode share every role', () {
      final pairs = <String, (Color, Color)>{
        'bg': (t.bg, c.bg),
        'surface/s1': (t.surface, c.s1),
        'field/s2': (t.field, c.s2),
        'surfaceHi/s3': (t.surfaceHi, c.s3),
        'raised/s4': (t.raised, c.s4),
        'line': (t.line, c.line),
        'lineStrong': (t.lineStrong, c.lineStrong),
        'lineField': (t.lineField, c.lineField),
        'text': (t.text, c.text),
        'dim': (t.dim, c.dim),
        'faint': (t.faint, c.faint),
        'accent': (t.accent, c.accent),
        'accentInk': (t.accentInk, c.accentInk),
        'accentText': (t.accentText, c.accentText),
        'accentSoft': (t.accentSoft, c.accentSoft),
        'tick': (t.tick, c.tick),
        'ok': (t.ok, c.ok),
        'okSoft': (t.okSoft, c.okSoft),
        'warn': (t.warn, c.warn),
        'warnSoft': (t.warnSoft, c.warnSoft),
        'risk': (t.risk, c.risk),
        'riskSoft': (t.riskSoft, c.riskSoft),
        'info': (t.info, c.info),
        'infoSoft': (t.infoSoft, c.infoSoft),
        'txSent': (t.txSent, c.txSent),
        'txReceived': (t.txReceived, c.txReceived),
        'txCancelled': (t.txCancelled, c.txCancelled),
        'scrim': (t.scrim, c.scrim),
        'shadow': (t.shadow, c.shadow),
      };
      for (final MapEntry(key: role, value: (phone, desk)) in pairs.entries) {
        expect(phone, desk, reason: '$mode $role');
      }
      // The light field is a white well, as on the desktop.
      if (mode == 'light') expect(t.field, t.surface);
    });
  }

  testWidgets('Advanced hides its child unless the option is on', (
    tester,
  ) async {
    Widget app(bool on) => MaterialApp(
      home: AdvancedOptions(prefs: on ? AdvancedPrefs.all : AdvancedPrefs.none,
        child: const Scaffold(body: Advanced(feature: AdvancedFeature.technicalDetails, child: Text('technical'))),
      ),
    );
    await tester.pumpWidget(app(false));
    expect(find.text('technical'), findsNothing);
    await tester.pumpWidget(app(true));
    expect(find.text('technical'), findsOneWidget);
    // Outside any AdvancedOptions it counts as off.
    await tester.pumpWidget(
      const MaterialApp(home: Advanced(feature: AdvancedFeature.technicalDetails, child: Text('technical'))),
    );
    expect(find.text('technical'), findsNothing);
  });
}
