// SPDX-License-Identifier: Apache-2.0
// The Settings hub's second lines name the main things on each page, never live values
// (26.10.11): Security "Backup · PIN · Biometrics" (the backup warning instead while
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
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/text_join.dart' show metaLine;
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

void main() {
  testWidgets('section rows show the title only, no list of what is inside', (tester) async {
    await _pump(tester);
    for (final section in [
      SettingsSection.wallet,
      SettingsSection.transactions,
      SettingsSection.display,
    ]) {
      expect(
        find.descendant(of: find.byKey(settingsGroupKey(section)), matching: find.byType(Text)),
        findsOneWidget,
        reason: '${section.name}: the title only',
      );
    }
    expect(find.text(_l.settingsContacts), findsNothing);
  });

  testWidgets('Network & privacy says the mode and the Tor switch on its line (B-03)', (tester) async {
    await _pump(tester);
    expect(_line(SettingsSection.privacyNetwork, torBuilt ? metaLine([_l.advModeStandard, _l.netSummaryTorOff]) : _l.advModeStandard), findsOneWidget);
    expect(find.text(_l.settingsSectionNetworkPrivacy), findsOneWidget);
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
    // Its line is the current level, one choice.
    expect(
      find.descendant(
        of: find.byKey(settingsGroupKey(SettingsSection.advanced)),
        matching: find.byType(Text),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('no live values: no host, no version, and About has no line', (tester) async {
    await _pump(tester);
    expect(find.textContaining('epicnet.us'), findsNothing);
    expect(find.textContaining('stackwallet.com'), findsNothing);
    // Network & privacy's line is the choice (mode and Tor switch), not a live state.
    expect(find.textContaining('Tor off'), torBuilt ? findsOneWidget : findsNothing);
    final about = find.descendant(
      of: find.byKey(settingsGroupKey(SettingsSection.about)),
      matching: find.byType(Text),
    );
    expect(about, findsOneWidget, reason: 'the title only');
  });

  testWidgets('not backed up: Security warns instead', (tester) async {
    await _pump(tester, backedUp: false);
    expect(_line(SettingsSection.security, _l.settingsStateBackUp), findsOneWidget);
  });
}
