import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (mode, c, b) in [
    ('dark', deskDark, Brightness.dark),
    ('light', deskLight, Brightness.light),
  ]) {
    group('Desktop $mode', () {
      test('every text colour passes AA (4.5:1) where it is used', () {
        final pairs = <String, (Color, Color)>{
          'accentInk on accent': (c.accentInk, c.accent),
          'bg on warn': (c.bg, c.warn),
          'bg on risk': (c.bg, c.risk),
          for (final (sname, surface) in [
            ('bg', c.bg),
            ('s1', c.s1),
            ('s2', c.s2),
            ('s3', c.s3),
            ('s4', c.s4),
          ]) ...{
            'text on $sname': (c.text, surface),
            'dim on $sname': (c.dim, surface),
            'accentText on $sname': (c.accentText, surface),
            'ok on $sname': (c.ok, surface),
            'warn on $sname': (c.warn, surface),
            'risk on $sname': (c.risk, surface),
            'info on $sname': (c.info, surface),
            // Direction colours on amounts and icons in Activity, details and Outputs.
            'txSent on $sname': (c.txSent, surface),
            'txReceived on $sname': (c.txReceived, surface),
            'txCancelled on $sname': (c.txCancelled, surface),
          },
          // Status text on its own soft fill (tags, notices, result glyphs).
          'ok on okSoft': (c.ok, Color.alphaBlend(c.okSoft, c.s1)),
          'warn on warnSoft': (c.warn, Color.alphaBlend(c.warnSoft, c.s1)),
          'risk on riskSoft': (c.risk, Color.alphaBlend(c.riskSoft, c.s1)),
          'info on infoSoft': (c.info, Color.alphaBlend(c.infoSoft, c.s1)),
          'accentText on accentSoft': (
            c.accentText,
            Color.alphaBlend(c.accentSoft, c.s1),
          ),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$mode $name',
          );
        }
      });

      test('the status colours are not the brand gold', () {
        expect(c.warn, isNot(c.accent));
        expect(c.warn, isNot(c.accentText));
        // Orange has more red over green than yellow or brown: at least a tenth more.
        expect(
          (c.warn.r - c.warn.g) - (c.accent.r - c.accent.g),
          greaterThanOrEqualTo(0.1),
          reason: '$mode warn ${c.warn} must be orange next to accent ${c.accent}',
        );
        expect(c.ok, isNot(c.accent));
        expect(c.info, isNot(c.accent));
        // Direction: sent gold (the one gold state), received green, cancelled a neutral grey.
        expect(c.txSent, c.accentText);
        expect(c.txReceived, c.ok);
        expect(c.txCancelled, isNot(c.warn));
        expect((c.txCancelled.r - c.txCancelled.b).abs(), lessThan(0.06), reason: 'cancelled is grey');
      });

      test('the theme carries the colours', () {
        final theme = buildDeskTheme(b);
        expect(theme.extension<DeskColors>(), same(c));
        expect(theme.colorScheme.primary, c.accent);
        expect(theme.colorScheme.error, c.risk);
        expect(theme.colorScheme.brightness, b);
      });
    });
  }
}
