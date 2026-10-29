// SPDX-License-Identifier: Apache-2.0
// Settings › Privacy & network's Node and Epicbox rows and their picker sheets say what the Tor
// switch does to the node and Epicbox: nothing with Tor off, "Over Tor", or "Waiting for Tor" while Tor starts or is
// not connected.
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/network_menu.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/ui/server_picker.dart';
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
  PhoneTorState tor, {
  MemorySecretStore? store,
  bool dev = false,
  bool advanced = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(store ?? MemorySecretStore()),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        sessionProvider.overrideWith(_OpenSession.new),
        phoneTorProvider.overrideWith(() => _Tor(tor)),
        devNetworksProvider.overrideWithValue(dev),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AdvancedOptions(prefs: advanced ? AdvancedPrefs.all : AdvancedPrefs.none, child: child!),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _row(TorRoute route) =>
    find.byKey(route == TorRoute.node ? settingsNodeKey : settingsEpicboxKey);

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
  group('the Node and Epicbox rows are the pickers (one place to change servers)', () {
    final store = MemorySecretStore({
      'app.network': 'mainnet',
    });
    const off = PhoneTorState(phase: PhoneTorPhase.off);

    // The servers in use are the settings' (`node.use`, `epicbox.use`).
    setUp(() => hostSettings = hostSettings.withValues({'node.use': 'https://node.net.invalid:3413', 'epicbox.use': 'box.stack.invalid'}));

    Future<void> openPage(WidgetTester tester) async {
      await _pump(tester, const SettingsScreen(section: SettingsSection.privacyNetwork), off, store: store);
      await tester.scrollUntilVisible(
        find.byKey(settingsNodeKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('they show the server in use', (tester) async {
      await openPage(tester);
      expect(
        find.descendant(of: find.byKey(settingsNodeKey), matching: find.text('Node')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(settingsNodeKey), matching: find.text('node.net.invalid:3413')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(settingsEpicboxKey), matching: find.text('Epicbox')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(settingsEpicboxKey), matching: find.text('box.stack.invalid')),
        findsOneWidget,
      );
    });

    for (final (key, kind) in [
      (settingsNodeKey, ServerKind.node),
      (settingsEpicboxKey, ServerKind.relay),
    ]) {
      testWidgets('${kind.name}: a tap opens its picker sheet, not a page', (tester) async {
        await openPage(tester);
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        final sheet = find.byType(ServerListSheet);
        expect(sheet, findsOneWidget);
        expect(tester.widget<ServerListSheet>(sheet).kind, kind);
        // The sheet is a modal route over the page: closing it lands on the same page.
        // The header's close comes before the field's clear button, which is a close icon too.
    await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(find.byKey(key), findsOneWidget);
      });
    }

    for (final (dev, advanced) in [(false, true), (true, false), (true, true)]) {
      testWidgets('the Network row: development builds ($dev) with Advanced ($advanced)', (tester) async {
        await _pump(
          tester,
          const SettingsScreen(section: SettingsSection.privacyNetwork),
          off,
          store: store,
          dev: dev,
          advanced: advanced,
        );
        await tester.scrollUntilVisible(
          find.byKey(settingsEpicboxKey),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final row = find.widgetWithText(ListTile, 'Network');
        expect(row, dev && advanced ? findsOneWidget : findsNothing);
        if (dev && advanced) {
          await tester.tap(row);
          await tester.pumpAndSettle();
          expect(find.byKey(networkChoiceKey(floonetPreset)), findsOneWidget);
        }
      });
    }

    test('the old Node and Epicbox page is gone', () {
      expect(File('lib/src/ui/setup_screen.dart').existsSync(), isFalse);
    });
  });

  for (final (tor, word, colour) in _states) {
    for (final route in [TorRoute.node, TorRoute.epicbox]) {
      testWidgets(
        'Privacy & network › ${route.name} row, Tor ${tor.phase.name}: ${word ?? 'no Tor line'}',
        (tester) async {
          await _pump(tester, const SettingsScreen(section: SettingsSection.privacyNetwork), tor);
          await tester.scrollUntilVisible(
            _row(route),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final row = _row(route);
          expect(row, findsOneWidget);
          // One row per server on the page: the status card's, nothing repeated below it.
          expect(find.text(route == TorRoute.node ? 'Node' : 'Epicbox'), findsOneWidget);
          if (word == null) {
            for (final w in ['Over Tor', 'Waiting for Tor']) {
              expect(find.descendant(of: row, matching: find.text(w)), findsNothing);
            }
            expect(
              find.descendant(of: row, matching: find.byIcon(torIcon)),
              findsNothing,
            );
            return;
          }
          final text = find.descendant(of: row, matching: find.text(word));
          expect(text, findsOneWidget);
          final t = tester.element(row).tokens;
          expect(tester.widget<Text>(text).style?.color, _colour(t, colour!));
        },
      );
    }

    for (final (route, title) in [
      (TorRoute.node, 'Node'),
      (TorRoute.epicbox, 'Epicbox'),
    ]) {
      testWidgets(
        '$title picker sheet, Tor ${tor.phase.name}: ${word ?? 'no Tor line'}',
        (tester) async {
          await _pump(tester, const SettingsScreen(section: SettingsSection.privacyNetwork), tor);
          await tester.scrollUntilVisible(
            _row(route),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(_row(route));
          await tester.pumpAndSettle();
          expect(find.byType(ServerListSheet), findsOneWidget);
          final lines = find.descendant(
            of: find.byType(ServerListSheet),
            matching: find.byWidgetPredicate(
              (w) => w is TorWayLine && w.route == route,
            ),
          );
          // The line is there to be filled: with Tor off it says nothing.
          expect(
            find.descendant(of: lines, matching: find.byType(Text)),
            word == null ? findsNothing : findsOneWidget,
          );
        },
      );
    }
  }
}
