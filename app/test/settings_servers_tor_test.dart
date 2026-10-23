// Settings › Servers and the node and relay screen say what the Tor switch does to the node
// and Epicbox: nothing with Tor off, "Over Tor", or "Waiting for Tor" while Tor starts or is
// not connected.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/setup_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/updater.dart';
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

class _OpenSession extends SessionNotifier {
  @override
  WalletSession? build() => FakeWalletSession();
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  PhoneTorState tor,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        sessionProvider.overrideWith(_OpenSession.new),
        phoneTorProvider.overrideWith(() => _Tor(tor)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AdvancedOptions(enabled: false, child: child!),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _serversRow() => find.ancestor(
  of: find.text('Node and Epicbox'),
  matching: find.byType(ListTile),
);

const _states = [
  (PhoneTorState(phase: PhoneTorPhase.off), null, null),
  (
    PhoneTorState(receiving: true, phase: PhoneTorPhase.starting),
    'Waiting for Tor',
    'warn',
  ),
  (
    PhoneTorState(receiving: true, phase: PhoneTorPhase.ready),
    'Over Tor',
    'ok',
  ),
  (
    PhoneTorState(
      receiving: true,
      phase: PhoneTorPhase.failed,
      failure: TorFailure.network,
    ),
    'Waiting for Tor',
    'risk',
  ),
];

Color _colour(WalletTokens t, String name) => switch (name) {
  'ok' => t.ok,
  'warn' => t.warn,
  _ => t.risk,
};

void main() {
  for (final (tor, word, colour) in _states) {
    testWidgets(
      'Privacy & network › Servers, Tor ${tor.phase.name}: ${word ?? 'no Tor line'}',
      (tester) async {
        await _pump(tester, const SettingsScreen(section: SettingsSection.privacyNetwork), tor);
        await tester.scrollUntilVisible(
          find.text('Node and Epicbox'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final row = _serversRow();
        expect(row, findsOneWidget);
        final line = find.descendant(
          of: row,
          matching: find.byType(TorWayLine),
        );
        if (word == null) {
          expect(line, findsNothing);
          expect(
            find.descendant(of: row, matching: find.byIcon(torIcon)),
            findsNothing,
          );
          return;
        }
        expect(line, findsOneWidget);
        final text = find.descendant(of: row, matching: find.text(word));
        final t = tester.element(row).tokens;
        expect(tester.widget<Text>(text).style?.color, _colour(t, colour!));
      },
    );

    testWidgets(
      'node and relay screen, Tor ${tor.phase.name}: ${word ?? 'no Tor line'}',
      (tester) async {
        await _pump(tester, const SetupScreen(), tor);
        final lines = find.byType(TorWayLine, skipOffstage: false);
        if (word == null) {
          expect(lines, findsNothing);
          return;
        }
        // One above the node list, one above the relay list.
        expect(lines, findsNWidgets(2));
        for (final route in [TorRoute.node, TorRoute.epicbox]) {
          expect(
            find.byWidgetPredicate(
              (w) => w is TorWayLine && w.route == route,
              skipOffstage: false,
            ),
            findsOneWidget,
          );
        }
        final first = find.text(word, skipOffstage: false).first;
        final t = tester.element(first).tokens;
        expect(tester.widget<Text>(first).style?.color, _colour(t, colour!));
      },
    );
  }
}
