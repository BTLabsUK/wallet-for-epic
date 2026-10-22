/// The desktop interface on the wallet core (LEPIC), as `main.dart` starts the phone app.
/// `flutter run -d linux -t lib/main_desktop.dart`.
///
/// `--dart-define=WFE_DESK_MOCK=true` runs every screen on canned data instead (screenshots,
/// the tour); start on any page with `--dart-define=WFE_DESK_START=<route>` (names in
/// `src/desktop/app/routes.dart`).
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';

import 'src/app_log.dart';
import 'src/data_folder.dart';
import 'src/desktop/app/desk_app.dart';
import 'src/desktop/data/desk_store.dart';
import 'src/desktop/data/files.dart';
import 'src/desktop/data/lepic_desk_wallet.dart';
import 'src/desktop/widgets/kit.dart';
import 'src/providers.dart';
import 'src/relay_directory.dart';
import 'src/wallet_backend.dart';
import 'src/web/splash.dart';

const bool _mock = bool.fromEnvironment('WFE_DESK_MOCK');

Future<void> main() async {
  if (_mock) {
    runApp(const ProviderScope(child: DeskApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
    return;
  }
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Before the logs and wallets ask for the support folder: Linux's own, never a stray one.
    await settleDataFolder();
    await startLogging();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      logError('flutter', details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logError('platform', error, stack);
      return false;
    };
    await initWalletBackend();
    const build = String.fromEnvironment('FLUTTER_BUILD_NAME');
    logInfo('app', 'desktop start ${build.isEmpty ? 'dev' : build}, $platformLabel');
    final overrides = await deskOverrides();
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    runApp(ProviderScope(retry: (_, _) => null, overrides: overrides, child: const DeskApp()));
  }, (error, stack) => logError('zone', error, stack));
}

/// The real wallet behind the desktop UI, its saved settings read before the first frame, and
/// the first screen: Welcome without a wallet, Unlock with one.
Future<List<Override>> deskOverrides() async {
  final container = ProviderContainer();
  final secrets = container.read(secretStoreProvider);
  final store = DeskStore(secrets);
  final boot = await DeskBoot.load(store);
  final wallet = LepicDeskWallet(
    service: container.read(walletServiceProvider),
    walletDir: container.read(walletDirProvider),
    secrets: secrets,
    filesDir: () async => await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory(),
    settings: boot.settings,
    relayDirectory: container.read(relayDirectoryProvider),
    pickDirectory: () => FilePicker.getDirectoryPath(dialogTitle: 'Choose the wallet folder'),
  );
  final hasWallet = (await wallet.wallets()).isNotEmpty;
  return [
    deskApiProvider.overrideWithValue(wallet),
    deskStoreProvider.overrideWithValue(store),
    deskBootProvider.overrideWithValue(boot),
    deskFilesProvider.overrideWithValue(const SystemDeskFiles()),
    deskQuitProvider.overrideWithValue(() async {
      await wallet.dispose();
      exit(0);
    }),
    if (!deskStartGiven) deskStartProvider.overrideWithValue(hasWallet ? DeskRoute.unlock : DeskRoute.welcome),
  ];
}
