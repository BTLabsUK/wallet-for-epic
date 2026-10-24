// The Settings hub's Privacy & network row says node · Epicbox · Tor on its second line, and
// never loses a part: at 360 dp, in every language, at text scale 1 and 2, the line wraps
// instead of cutting the Tor state off (a tester could not find "Tor" on 26.10.10).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(
    receiving: true,
    phase: PhoneTorPhase.failed,
    failure: TorFailure.network,
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

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${locale.languageCode} at 360 dp, text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
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
                  // The longest public node and relay names.
                  'app.node.mainnet': 'https://node.epicnet.us:3413',
                  'app.relay.mainnet': 'epicbox.stackwallet.com',
                }),
              ),
              updatePlatformProvider.overrideWithValue(null),
              relayDirectoryProvider.overrideWithValue(_NoRelays()),
              sessionProvider.overrideWith(_OpenSession.new),
              phoneTorProvider.overrideWith(_Tor.new),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: AdvancedOptions(enabled: false, child: child!),
              ),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(locale);
        final tor = l.settingsStateTor(l.torWordNotConnected.toLowerCase());
        final line = find.descendant(
          of: find.byKey(settingsGroupKey(SettingsSection.privacyNetwork)),
          matching: find.textContaining(tor),
        );
        expect(line, findsOneWidget);
        expect(tester.widget<Text>(line).data, startsWith('epicnet.us'));
        final paragraph = tester.renderObject<RenderParagraph>(line);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
