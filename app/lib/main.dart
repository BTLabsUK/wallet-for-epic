// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/app_log.dart';
import 'src/data_folder.dart';
import 'src/password_lists.dart';
import 'src/phone_tor.dart';
import 'src/relay_directory.dart' show statusSite;
import 'src/network.dart' show devChainOf;
import 'src/providers.dart' show NetworkChoiceNotifier;
import 'src/btlabs_public_phone.dart' show refreshBtlabsPublicAtStart;
import 'src/secret_store_api.dart' show SecretStore;
import 'src/settings_file/settings_providers.dart';
import 'src/wallet_service.dart' show Chain;
import 'src/levels/first_start.dart';
import 'src/net/tor_net.dart';
import 'src/tor_build.dart';
import 'src/tor_licence.dart';
import 'src/tor_phone.dart';
import 'src/ui/theme/fonts.dart';
import 'src/wallet_backend.dart';
import 'src/web/splash.dart';
import 'src/settings_file/host_settings.dart' show appConfig;

Future<void> main() async {
  // Errors that escape every other handler land here, in the zone the app runs in.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Before the logs and wallets ask for the support folder: Linux's own, never a stray one.
    await settleDataFolder();
    // First, so a failure to load either core is in the file.
    await startLogging();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      logError('flutter', details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logError('platform', error, stack);
      // Not handled: the engine still reports it as before.
      return false;
    };
    await initWalletBackend();
    final store = createSecretStore();
    // Before the settings open and before any request: a fresh install opens no connection
    // until its first-start step (the level, Undercover) is answered (levels/first_start.dart).
    // The web builds have no first-start step.
    if (!kIsWeb) await holdUntilFirstStart(store);
    // Before anything reads an address: the settings file (docs/settings-file.md). A dev build
    // on a test network reads that network's own file.
    await _openSettings(store);
    // Before any request: with the Tor switch saved on, the app's own requests (update check,
    // price, status) wait for tor from launch, also before the PIN, and never go direct.
    bool torSavedOn;
    try {
      torSavedOn = await PhoneTor.savedOn(store).timeout(const Duration(seconds: 5));
    } on Object catch (e) {
      logWarn('tor', 'tor switch not read: ${e.runtimeType}');
      // Unknown: wait until the wallet's own switch is read at unlock rather than risk direct.
      torSavedOn = true;
    }
    // iOS has no tor: nothing waits for one.
    phoneTorAtLaunch(savedOn: torSavedOn && defaultTargetPlatform != TargetPlatform.iOS);
    // A wallet whose switch is on opens waiting for tor, so a missing tor bundle blocks.
    wantTorAtOpen((config) => PhoneTor.wantedAtOpen(store, config));
    // The update check, price and status asked before tor connects wait for it, then go
    // through it.
    if (torBuilt) TorNet.hold = appConfig.torSendWait;
    // BT Labs' signed btlabs.json, in the background after the network mode and Tor are set:
    // the donation address from the kept copy at once, then from a fresh read if one verifies.
    // Held for the first-start step: once it is answered.
    afterFirstStart(() => unawaited(refreshBtlabsPublicAtStart(store)));
    // Before anything asks the status site: off (`status.enabled`), nothing is asked.
    statusSite.followSettings();
    registerFontLicences();
    registerPasswordListLicences();
    registerTorLicence();
    const build = String.fromEnvironment('FLUTTER_BUILD_NAME');
    logInfo('app', 'start ${build.isEmpty ? 'dev' : build}, $platformLabel');
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    // The web preview plays Tor and the levels back (web/preview.dart).
    runApp(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          ...backendOverrides(),
          // The phone's Tor controller restarts tor when the network returns.
          networkChangesProvider.overrideWithValue(androidNetworkChanges()),
        ],
        child: const WalletApp(),
      ),
    );
    // The web page's splash (web/index.html) stays until Flutter has drawn over it.
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
  }, (error, stack) => logError('zone', error, stack));
}

/// Opens this run's settings. A dev chain without its file (`app/tool/dev_settings.sh`) falls
/// back to mainnet's, saved as the network, with the reason in the log.
Future<void> _openSettings(SecretStore store) async {
  final chain = await NetworkChoiceNotifier.savedChain(store);
  try {
    await openAppSettings(store: store, devChain: devChainOf(chain));
  } on DevSettingsMissing catch (e) {
    logError('settings', e, StackTrace.current);
    await store.write(NetworkChoiceNotifier.networkKey, Chain.mainnet.name);
    await openAppSettings(store: store);
  }
}
