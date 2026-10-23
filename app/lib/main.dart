import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/app_log.dart';
import 'src/data_folder.dart';
import 'src/demo_web_platform.dart';
import 'src/password_lists.dart';
import 'src/phone_tor.dart';
import 'src/relay_directory.dart' show statusSite;
import 'src/settings.dart' show readUseStatusSite;
import 'src/tor_licence.dart';
import 'src/tor_phone.dart';
import 'src/ui/theme/fonts.dart';
import 'src/wallet_backend.dart';
import 'src/web/splash.dart';

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
    phoneTorAtLaunch(savedOn: torSavedOn);
    // Before anything asks status.btlabs.uk: opted out, nothing is asked.
    statusSite.loadFrom(readUseStatusSite(store));
    registerFontLicences();
    registerPasswordListLicences();
    registerTorLicence();
    const build = String.fromEnvironment('FLUTTER_BUILD_NAME');
    logInfo('app', 'start ${build.isEmpty ? 'dev' : build}, $platformLabel');
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    // On the web demo, its server: the reconnecting wallet socket and the demo API.
    runApp(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          ...webDemoOverrides(),
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
