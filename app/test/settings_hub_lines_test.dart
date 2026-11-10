// SPDX-License-Identifier: Apache-2.0
// The Settings hub's rows are a glyph and a name, never a second line (item 3): no state, no
// list of what is inside. Security's backup warning is a mark beside the chevron; Linked
// devices carries its Experiment tag on the same line.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/level_providers.dart' show currentLevelProvider;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(
    phase: PhoneTorPhase.off,
    onion: 'abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx',
  );
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
  WidgetTester tester, {
  bool backedUp = true,
  AdvancedPrefs advanced = AdvancedPrefs.none,
  WalletLevel? level,
}) async {
  // Tall enough that every page builds all of its rows.
  tester.view.physicalSize = const Size(1080, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore({
            'app.network': 'mainnet',
            'app.node.mainnet': 'https://node.epicnet.us:3413',
            'app.relay.mainnet': 'epicbox.stackwallet.com',
            // The hub reads the stored choice; the pages read the tree's.
            if (advanced.any) 'app.advanced_prefs': advanced.encode(),
          }),
        ),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        sessionProvider.overrideWith(_OpenSession.new),
        if (level != null) currentLevelProvider.overrideWithValue(level),
        phoneTorProvider.overrideWith(_Tor.new),
        backedUpProvider.overrideWith((ref) async => backedUp),
        biometricsProvider.overrideWith(
          (ref) async => (available: true, enabled: false),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AdvancedOptions(prefs: advanced, child: child!),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every Text under a hub row.
Finder _texts(Finder row) => find.descendant(of: row, matching: find.byType(Text));

void main() {
  testWidgets('every hub row is its name alone: one line, no subtitle (item 3)', (tester) async {
    await _pump(tester);
    final rows = [
      for (final section in SettingsSection.values) find.byKey(settingsGroupKey(section)),
      find.byKey(settingsHelpKey),
    ];
    for (final row in rows) {
      if (row.evaluate().isEmpty) continue;
      expect(_texts(row), findsOneWidget, reason: '$row: the title only');
      expect(tester.widget<ListTile>(find.descendant(of: row, matching: find.byType(ListTile))).subtitle, isNull, reason: '$row');
    }
    expect(find.text(_l.settingsContacts), findsNothing);
    expect(find.textContaining('Tor off'), findsNothing);
    expect(find.textContaining('epicnet.us'), findsNothing);
    expect(find.textContaining('stackwallet.com'), findsNothing);
    expect(find.text(_l.settingsSectionNetworkPrivacy), findsOneWidget);
  });

  testWidgets('Linked devices: a hub row at every level, its Experiment tag on the title line', (tester) async {
    await _pump(tester);
    final row = find.byKey(settingsLinkedDevicesKey);
    expect(row, findsOneWidget);
    expect(tester.widget<ListTile>(find.descendant(of: row, matching: find.byType(ListTile))).subtitle, isNull);
    expect(find.descendant(of: row, matching: find.text(_l.expLinkedDevices)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text(_l.settingsExperimentTag)), findsOneWidget);
  });

  testWidgets('the Transactions row comes right after Security (the desktop\'s order)', (tester) async {
    await _pump(tester);
    final wallet = find.byKey(settingsGroupKey(SettingsSection.security));
    final tx = find.byKey(settingsGroupKey(SettingsSection.transactions));
    expect(tx, findsOneWidget);
    expect(
      tester.getTopLeft(tx).dy - tester.getTopLeft(wallet).dy,
      moreOrLessEquals(tester.getSize(wallet).height, epsilon: 1),
    );
  });

  testWidgets('Transactions is a hub row at Shallow too: it holds the epic1 switch', (tester) async {
    await _pump(tester, level: WalletLevel.justSendReceive);
    expect(find.byKey(settingsGroupKey(SettingsSection.transactions)), findsOneWidget);
    expect(find.byKey(settingsGroupKey(SettingsSection.privacyNetwork)), findsNothing, reason: 'Shallow still hides Privacy & network');
  });

  testWidgets('the Advanced row is last but one: below Help, directly above About', (
    tester,
  ) async {
    await _pump(tester);
    final advanced = find.byKey(settingsGroupKey(SettingsSection.advanced));
    final help = find.byKey(settingsHelpKey);
    final about = find.byKey(settingsGroupKey(SettingsSection.about));
    expect(advanced, findsOneWidget);
    final y = [for (final f in [help, advanced, about]) tester.getTopLeft(f).dy];
    expect(y, orderedEquals([...y]..sort()));
    // Nothing between the two: About starts one row below Advanced.
    expect(
      tester.getTopLeft(about).dy - tester.getTopLeft(advanced).dy,
      moreOrLessEquals(tester.getSize(advanced).height, epsilon: 1),
    );
  });

  testWidgets('not backed up: Security shows a warning mark, not a line', (tester) async {
    await _pump(tester, backedUp: false);
    final security = find.byKey(settingsGroupKey(SettingsSection.security));
    expect(_texts(security), findsOneWidget);
    expect(
      find.descendant(of: security, matching: find.byWidgetPredicate((w) => w is Tooltip && w.message == _l.settingsStateBackUp)),
      findsOneWidget,
    );
  });
}
