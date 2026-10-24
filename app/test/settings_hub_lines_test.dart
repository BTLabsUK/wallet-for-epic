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
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart' show TorSwitchTile;
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

Future<void> _pump(WidgetTester tester, {bool backedUp = true}) async {
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
            AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
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
      (_l.netStatusTor, () => find.byType(TorSwitchTile)),
    ],
    SettingsSection.wallet: [
      (_l.settingsContacts, () => find.text(_l.settingsContacts)),
      (_l.outputsTitle, () => find.text(_l.outputsTitle)),
      (_l.settingsSectionHistory, () => find.text(_l.settingsSectionHistory)),
    ],
    SettingsSection.display: [
      (_l.settingsTheme, () => find.text(_l.settingsTheme)),
      (_l.languageSetting, () => find.text(_l.languageSetting)),
      (_l.settingsCurrency, () => find.text(_l.settingsCurrency)),
    ],
  };

  for (final MapEntry(key: section, value: items) in pages.entries) {
    testWidgets('${section.name}: the line names three things, each on its page', (
      tester,
    ) async {
      await _pump(tester);
      expect(items, hasLength(3));
      expect(_line(section, _join([for (final (name, _) in items) name])), findsOneWidget);
      await tester.tap(find.byKey(settingsGroupKey(section)));
      await tester.pumpAndSettle();
      for (final (name, row) in items) {
        expect(row(), findsWidgets, reason: '"$name" is on the ${section.name} page');
      }
    });
  }

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
