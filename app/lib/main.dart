import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/app_log.dart';
import 'src/data_folder.dart';
import 'src/demo_web_platform.dart';
import 'src/password_lists.dart';
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
    registerFontLicences();
    registerPasswordListLicences();
    const build = String.fromEnvironment('FLUTTER_BUILD_NAME');
    logInfo('app', 'start ${build.isEmpty ? 'dev' : build}, $platformLabel');
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    // On the web demo, its server: the reconnecting wallet socket and the demo API.
    runApp(
      ProviderScope(
        retry: (_, _) => null,
        overrides: webDemoOverrides(),
        child: const WalletApp(),
      ),
    );
    // The web page's splash (web/index.html) stays until Flutter has drawn over it.
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
  }, (error, stack) => logError('zone', error, stack));
}
