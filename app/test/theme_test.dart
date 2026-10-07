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
          'risk on surface': (t.risk, t.surface),
          'ok on surface': (t.ok, t.surface),
          'warn on surface': (t.warn, t.surface),
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
            home: AdvancedOptions(
              enabled: true,
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
                        TimelineStep('Sent to the network', TimelineState.todo),
                      ],
                    ),
                    Advanced(child: Text('technical')),
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

  testWidgets('Advanced hides its child unless the option is on', (
    tester,
  ) async {
    Widget app(bool on) => MaterialApp(
      home: AdvancedOptions(
        enabled: on,
        child: const Scaffold(body: Advanced(child: Text('technical'))),
      ),
    );
    await tester.pumpWidget(app(false));
    expect(find.text('technical'), findsNothing);
    await tester.pumpWidget(app(true));
    expect(find.text('technical'), findsOneWidget);
    // Outside any AdvancedOptions it counts as off.
    await tester.pumpWidget(
      const MaterialApp(home: Advanced(child: Text('technical'))),
    );
    expect(find.text('technical'), findsNothing);
  });
}
