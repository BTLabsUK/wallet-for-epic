// SPDX-License-Identifier: Apache-2.0
// TorWayLine: what a connection does under the Tor switch, in the words the status card and
// the server lists share: nothing with Tor off, "Over Tor", or "Waiting for Tor" (in-progress blue while
// Tor starts, risk with "Tor is not connected" when it failed).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tor extends PhoneTor {
  _Tor(this.value);

  final PhoneTorState value;

  @override
  PhoneTorState build() => value;
}

Future<void> _pump(
  WidgetTester tester,
  PhoneTorState tor, {
  TorRoute route = TorRoute.epicbox,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [phoneTorProvider.overrideWith(() => _Tor(tor))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: TorWayLine(key: const Key('line'), route: route),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

WalletTokens _tokens(WidgetTester tester) =>
    tester.element(find.byType(Scaffold)).tokens;

void main() {
  testWidgets('Tor off: nothing', (tester) async {
    await _pump(tester, const PhoneTorState(phase: PhoneTorPhase.off));
    expect(find.byType(Text), findsNothing);
    expect(find.byIcon(torIcon), findsNothing);
    expect(tester.getSize(find.byKey(const Key('line'))), Size.zero);
  });

  testWidgets('a send started tor, the switch is off: nothing', (tester) async {
    await _pump(tester, const PhoneTorState(phase: PhoneTorPhase.ready));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the switch on without its tor files: blocked, as failed', (tester) async {
    await _pump(
      tester,
      const PhoneTorState(receiving: true, phase: PhoneTorPhase.unavailable),
    );
    if (torBuilt) {
      final text = tester.widget<Text>(find.text('Waiting for Tor'));
      expect(text.style?.color, _tokens(tester).risk);
    } else {
      expect(find.byType(Text), findsNothing);
    }
  });

  for (final (name, state, word, color, spoken) in [
    (
      'starting',
      const PhoneTorState(receiving: true, phase: PhoneTorPhase.starting),
      'Waiting for Tor',
      (WalletTokens t) => t.info,
      'Waiting for Tor',
    ),
    (
      'on',
      const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready),
      'Over Tor',
      (WalletTokens t) => t.ok,
      'Over Tor',
    ),
    (
      'failed',
      const PhoneTorState(
        receiving: true,
        phase: PhoneTorPhase.failed,
        failure: TorFailure.network,
      ),
      'Waiting for Tor',
      (WalletTokens t) => t.risk,
      'Waiting for Tor, Tor is not connected.',
    ),
  ]) {
    testWidgets('$name: $word, its colour, read out', (tester) async {
      final handle = tester.ensureSemantics();
      for (final route in [TorRoute.epicbox, TorRoute.node]) {
        await _pump(tester, state, route: route);
        final t = _tokens(tester);
        final text = tester.widget<Text>(find.text(word));
        expect(text.style?.color, color(t));
        expect(
          text.style?.fontSize,
          Theme.of(tester.element(find.text(word)))
              .textTheme
              .bodySmall
              ?.fontSize,
        );
        final icon = tester.widget<Icon>(find.byIcon(torIcon));
        expect(icon.size, 16);
        expect(icon.color, color(t));
        expect(find.bySemanticsLabel(spoken), findsOneWidget);
      }
      handle.dispose();
    });
  }

  testWidgets('a route Tor does not cover: nothing', (tester) async {
    await _pump(
      tester,
      const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready),
      route: TorRoute.httpListener,
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('torWayWords: null where nothing is said', (tester) async {
    await _pump(tester, const PhoneTorState(phase: PhoneTorPhase.off));
    final l = tester.element(find.byType(Scaffold)).l10n;
    final t = _tokens(tester);
    for (final way in [TorWay.clearnet, TorWay.needsTor, TorWay.off]) {
      expect(torWayWords(l, t, way), isNull);
    }
    expect(torWayWords(l, t, TorWay.overTor)?.detail, isNull);
    expect(torWayWords(l, t, TorWay.blocked)?.detail, 'Tor is not connected.');
  });
}
