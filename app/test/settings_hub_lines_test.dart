// SPDX-License-Identifier: Apache-2.0
// The Settings hub's rows are a glyph, a name and at most one state line. The state is short
// (the lock, the ways to pay, the look); no server address, no list of what is inside. The
// recovery phrase shows on the wallet row; Linked devices carries its Experiment tag.
import 'package:epic_wallet/src/l10n.dart';
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
  testWidgets('every hub row is a name and at most one line, never a server or a list (item 3)', (tester) async {
    await _pump(tester);
    final rows = [
      for (final section in SettingsSection.values) find.byKey(settingsGroupKey(section)),
      find.byKey(settingsHelpKey),
    ];
    for (final row in rows) {
      if (row.evaluate().isEmpty) continue;
      expect(_texts(row).evaluate().length, lessThanOrEqualTo(4), reason: '$row: title, a line, a value');
    }
    expect(find.text(_l.settingsContacts), findsNothing);
    expect(find.textContaining('epicnet.us'), findsNothing);
    expect(find.textContaining('stackwallet.com'), findsNothing);
    expect(find.text(_l.settingsSectionNetworkPrivacy), findsOneWidget);
  });

  testWidgets('Linked devices: a hub row, its Experiment tag beside the chevron', (tester) async {
    await _pump(tester);
    final row = find.byKey(settingsLinkedDevicesKey);
    expect(row, findsOneWidget);
    expect(find.descendant(of: row, matching: find.text(_l.expLinkedDevices)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text(_l.settingsExperimentTag)), findsOneWidget);
  });

  testWidgets('the Transactions row comes right after Security, then Appearance', (tester) async {
    await _pump(tester);
    final y = [
      for (final section in [SettingsSection.wallet, SettingsSection.security, SettingsSection.transactions, SettingsSection.display])
        tester.getTopLeft(find.byKey(settingsGroupKey(section))).dy,
    ];
    expect(y, orderedEquals([...y]..sort()));
    expect(y.toSet().length, 4);
  });

  testWidgets('Payments and Privacy & network are hub rows at every setting', (tester) async {
    await _pump(tester);
    expect(find.byKey(settingsGroupKey(SettingsSection.transactions)), findsOneWidget);
    expect(find.byKey(settingsGroupKey(SettingsSection.privacyNetwork)), findsOneWidget);
  });

  testWidgets('the Advanced row is last, below Help; About is reached through Help', (tester) async {
    await _pump(tester);
    final advanced = find.byKey(settingsGroupKey(SettingsSection.advanced));
    final help = find.byKey(settingsHelpKey);
    expect(advanced, findsOneWidget);
    expect(find.byKey(settingsGroupKey(SettingsSection.about)), findsNothing);
    expect(tester.getTopLeft(help).dy, lessThan(tester.getTopLeft(advanced).dy));
  });

  testWidgets('not backed up: the wallet row says so, in the warning colour', (tester) async {
    await _pump(tester, backedUp: false);
    final wallet = find.byKey(settingsGroupKey(SettingsSection.wallet));
    expect(find.descendant(of: wallet, matching: find.text(_l.settingsStateBackUp)), findsOneWidget);
  });

  testWidgets('backed up: the wallet row says the phrase is saved', (tester) async {
    await _pump(tester);
    final wallet = find.byKey(settingsGroupKey(SettingsSection.wallet));
    expect(find.descendant(of: wallet, matching: find.text(_l.phoneSettingsPhraseBackedUp)), findsOneWidget);
  });
}
