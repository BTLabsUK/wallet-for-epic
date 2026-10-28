// The Settings hub's second lines name the main things on each page, never live values
// (the owner, 26.10.11): Security "Backup · PIN · Biometrics" (the backup warning instead while
// the phrase is not backed up), Privacy & network "Node · Epicbox · Tor", Wallet "Contacts ·
// Outputs · Payment history", Display "Theme · Language · Currency", About none. Every item
// named is on its page.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/settings_sections.dart' show advancedFeatureName;
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart' show TorSwitchTile;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
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

Finder _line(SettingsSection section, String text) => find.descendant(
  of: find.byKey(settingsGroupKey(section)),
  matching: find.text(text),
);

String _join(List<String> items) => items.reduce(_l.settingsStateJoin);

void main() {
  // What each line names, and the row on the page each item stands for.
  final pages = <SettingsSection, List<(String, Finder Function())>>{
    SettingsSection.security: [
      (_l.settingsHubBackup, () => find.text(_l.settingsBackupPhrase)),
      (_l.pinLabel, () => find.text(_l.settingsChangePin)),
      (_l.pinBiometricsIconLabel, () => find.text(_l.settingsBiometrics)),
    ],
    SettingsSection.privacyNetwork: [
      (_l.serverNodeTitle, () => find.text(_l.serverNodeTitle)),
      (_l.serverEpicboxTitle, () => find.text(_l.serverEpicboxTitle)),
      // No Tor switch, nor its name, in the build without Tor.
      if (torBuilt) (_l.netStatusTor, () => find.byType(TorSwitchTile)),
    ],
    // Outputs is named (and shown) only with Advanced > Outputs: see the test below.
    SettingsSection.wallet: [
      (_l.settingsContacts, () => find.text(_l.settingsContacts)),
      (_l.settingsSectionHistory, () => find.text(_l.settingsSectionHistory)),
    ],
    // Send defaults are named (and shown) only with Advanced > Send options: see below.
    SettingsSection.transactions: [
      (_l.settingsHubMethods, () => find.text(_l.txMethodsHeader)),
      (_l.settingsHubDefault, () => find.text(_l.txStartHeader)),
    ],
    SettingsSection.display: [
      (_l.settingsTheme, () => find.text(_l.settingsTheme)),
      (_l.languageSetting, () => find.text(_l.languageSetting)),
      (_l.settingsCurrency, () => find.text(_l.settingsCurrency)),
    ],
  };

  for (final MapEntry(key: section, value: items) in pages.entries) {
    testWidgets('${section.name}: the line names its things, each on its page', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        items,
        hasLength(
          section == SettingsSection.wallet ||
                  section == SettingsSection.transactions ||
                  (section == SettingsSection.privacyNetwork && !torBuilt)
              ? 2
              : 3,
        ),
      );
      expect(_line(section, _join([for (final (name, _) in items) name])), findsOneWidget);
      await tester.tap(find.byKey(settingsGroupKey(section)));
      await tester.pumpAndSettle();
      for (final (name, row) in items) {
        expect(row(), findsWidgets, reason: '"$name" is on the ${section.name} page');
      }
    });
  }

  testWidgets('wallet: Outputs joins the line and the page when Advanced shows it', (
    tester,
  ) async {
    await _pump(
      tester,
      advanced: const AdvancedPrefs(features: {AdvancedFeature.outputs}),
    );
    expect(
      _line(
        SettingsSection.wallet,
        _join([
          _l.settingsContacts,
          _l.outputsTitle,
          _l.settingsSectionHistory,
        ]),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(settingsGroupKey(SettingsSection.wallet)));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsTitle), findsWidgets);
  });

  testWidgets('transactions: Send defaults join the line and the page with Send options', (
    tester,
  ) async {
    await _pump(
      tester,
      advanced: const AdvancedPrefs(features: {AdvancedFeature.sendOptions}),
    );
    expect(
      _line(
        SettingsSection.transactions,
        _join([_l.settingsHubMethods, _l.settingsHubDefault, _l.settingsHubSendDefaults]),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(settingsGroupKey(SettingsSection.transactions)));
    await tester.pumpAndSettle();
    expect(find.text(_l.txDefaultsHeader), findsOneWidget);
  });

  testWidgets('the Transactions row comes right after Wallet', (tester) async {
    await _pump(tester);
    final wallet = find.byKey(settingsGroupKey(SettingsSection.wallet));
    final tx = find.byKey(settingsGroupKey(SettingsSection.transactions));
    expect(tx, findsOneWidget);
    expect(
      tester.getTopLeft(tx).dy - tester.getTopLeft(wallet).dy,
      moreOrLessEquals(tester.getSize(wallet).height, epsilon: 1),
    );
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
    // Its state line names what is on: Linked devices, on by default, until turned off.
    expect(
      _line(SettingsSection.advanced, advancedFeatureName(_l, AdvancedFeature.linkedDevices)),
      findsOneWidget,
    );
  });

  testWidgets('no live values: no host, no version, and About has no line', (tester) async {
    await _pump(tester);
    expect(find.textContaining('epicnet.us'), findsNothing);
    expect(find.textContaining('stackwallet.com'), findsNothing);
    expect(find.textContaining('Tor off'), findsNothing);
    final about = find.descendant(
      of: find.byKey(settingsGroupKey(SettingsSection.about)),
      matching: find.byType(Text),
    );
    expect(about, findsOneWidget, reason: 'the title only');
  });

  testWidgets('not backed up: Security warns instead', (tester) async {
    await _pump(tester, backedUp: false);
    expect(_line(SettingsSection.security, _l.settingsStateBackUp), findsOneWidget);
    expect(find.textContaining(_l.settingsHubBackup), findsNothing);
  });
}
