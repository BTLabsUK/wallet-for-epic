import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/app_log.dart';
import 'src/rust/frb_generated.dart';
import 'src/ui/theme/fonts.dart';

Future<void> main() async {
  // Errors that escape every other handler land here, in the zone the app runs in.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
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
    await RustLib.init();
    await startLogging();
    registerFontLicences();
    const build = String.fromEnvironment('FLUTTER_BUILD_NAME');
    logInfo(
      'app',
      'start ${build.isEmpty ? 'dev' : build}, ${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}',
    );
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    runApp(ProviderScope(retry: (_, _) => null, child: const WalletApp()));
  }, (error, stack) => logError('zone', error, stack));
}
