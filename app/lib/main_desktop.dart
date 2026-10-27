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

import 'src/network.dart' show mainnetPreset;
import 'src/network_gate.dart';
import 'src/app_log.dart';
import 'src/btlabs_onions.dart';
import 'src/builtin_node.dart';
import 'src/builtin_node_provider.dart';
import 'src/data_folder.dart';
import 'src/desktop/app/close_guard.dart' show deskHoldExit;
import 'src/desktop/app/desk_app.dart';
import 'src/desktop/app/desk_window.dart';
import 'src/desktop/app/shell.dart' show deskVersion;
import 'src/desktop/data/close_down.dart';
import 'src/desktop/data/desk_node.dart';
import 'src/desktop/data/desk_update.dart' show deskUpdateAutoProvider;
import 'src/desktop/keyring_check.dart';
import 'src/desktop/screens/settings/local_node_dialogs.dart' show deskPickFolder;
import 'src/desktop/data/desk_store.dart';
import 'src/desktop/data/files.dart';
import 'src/desktop/data/history_files.dart';
import 'src/desktop/data/lepic_desk_wallet.dart';
import 'src/desktop/data/logs.dart';
import 'src/desktop/widgets/kit.dart';
import 'src/password_lists.dart';
import 'src/tor_licence.dart';
import 'src/providers.dart';
import 'src/relay_directory.dart';
import 'src/tor_location.dart';
import 'src/wallet_backend.dart';
import 'src/web/splash.dart';

const bool _mock = bool.fromEnvironment('WFE_DESK_MOCK');

/// Kept for the app's lifetime; stops the built-in node when the window closes.
// ignore: unused_element
AppLifecycleListener? _exitListener;

Future<void> main() async {
  if (_mock) {
    WidgetsFlutterBinding.ensureInitialized();
    final window = await SystemDeskWindow.init();
    runApp(ProviderScope(overrides: [if (window != null) deskWindowProvider.overrideWithValue(window)], child: const DeskApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
    return;
  }
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    deskPickFolder = () => FilePicker.getDirectoryPath(dialogTitle: 'Choose the data folder');
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
    registerPasswordListLicences();
    registerTorLicence();
    logInfo('app', 'desktop start $deskVersion, $platformLabel');
    // Linux without a keyring to use: say so on the first screen, before libsecret is asked
    // anything (it would hold the window's thread, so no window showed).
    final keyring = await checkLinuxKeyring();
    if (keyring != null) {
      final ready = Completer<void>();
      runApp(KeyringApp(problem: keyring, check: checkLinuxKeyring, onReady: () => ready.isCompleted ? null : ready.complete()));
      await ready.future;
    }
    final overrides = await deskOverrides();
    // The app's own title bar from here on (the keyring screen above keeps the system's).
    final window = await SystemDeskWindow.init();
    if (window != null) overrides.add(deskWindowProvider.overrideWithValue(window));
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
  // Before the wallet core starts: its runtime takes the log level once.
  await applySavedLogLevel(store);
  // A store that cannot be read (damaged, held by another program) must not stop the app
  // before its first frame: start with default settings and let Unlock show the error. The
  // store itself never writes over what it could not read.
  DeskBoot boot;
  try {
    boot = await DeskBoot.load(store);
  } on Object catch (e, stack) {
    logError('desk', 'settings not read: ${e.runtimeType}', stack);
    boot = const DeskBoot();
  }
  // Before any request: Offline sends nothing, Tor only nothing direct (network_gate.dart).
  NetGate.set(boot.settings.advanced.networkMode);
  // Before anything asks status.btlabs.uk: off, nothing is asked.
  statusSite.on = boot.settings.useStatusSite;
  final directory = container.read(relayDirectoryProvider);
  // Saved on: the app's own requests wait for tor from the first one, also before unlock.
  bool torSwitch;
  try {
    torSwitch = DeskFeatures.tor && (await store.torSwitch() ?? false);
  } on Object catch (e) {
    logWarn('desk', 'tor switch not read: ${e.runtimeType}');
    torSwitch = false;
  }
  if (!DeskFeatures.tor) logInfo('desk', 'tor: not in this build');
  final wallet = LepicDeskWallet(
    // A dev build with test networks starts on the one chosen last on Welcome.
    preset: DeskFeatures.testNetworks ? await LepicDeskWallet.savedPreset(secrets) : mainnetPreset,
    service: container.read(walletServiceProvider),
    walletDir: container.read(walletDirProvider),
    secrets: secrets,
    filesDir: () async => await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory(),
    settings: boot.settings,
    relayDirectory: directory,
    nodeDirectory: directory is NodeDirectory ? directory as NodeDirectory : null,
    builtInNode: builtInNodeSupported
        ? (chain) async {
            // The one node object of the chain, shared with the node providers.
            final where = await container.read(builtInNodeLocationProvider.future);
            return builtInNodeFor(where, chain);
          }
        : null,
    pickDirectory: () => FilePicker.getDirectoryPath(dialogTitle: 'Choose the wallet folder'),
    // bin/tor-bundle beside the app (tools/fetch-tor.sh); without it Tor cannot be turned on.
    torBundle: findTorBundle,
    torSwitch: torSwitch,
    // The BT Labs contact's website copy (F31); the bundled one is used until it answers.
    seedFetch: LepicDeskWallet.fetchSeeds,
    onions: container.read(onionDirectoryProvider),
  );
  // Off by default (D10): this starts a node only when the user turned it on before.
  unawaited(wallet.resumeBuiltInNode());
  // Closing the window must not leave the node running, nor cut off a send: while one runs
  // the app stays open and asks (close_guard.dart, the rule of the title bar's close and Ctrl+Q).
  _exitListener = AppLifecycleListener(
    onExitRequested: () async {
      if (deskHoldExit()) return AppExitResponse.cancel;
      await deskCloseDown(disposeWallet: wallet.dispose, stopNodes: stopAllBuiltInNodes);
      return AppExitResponse.exit;
    },
  );
  // Unreadable wallet list: open Unlock, which reads it again and shows why; never Welcome,
  // which would offer to make a new wallet over an existing one.
  bool hasWallet;
  try {
    hasWallet = (await wallet.wallets()).isNotEmpty;
  } on Object catch (e, stack) {
    logError('desk', 'wallet list not read: ${e.runtimeType}', stack);
    hasWallet = true;
  }
  return [
    deskApiProvider.overrideWithValue(wallet),
    if (builtInNodeSupported)
      deskNodeProvider.overrideWith((ref) {
        final node = LepicDeskNode(
          ref,
          chain: wallet.preset.chain,
          onDecision: (d) => wallet.applyNodeFallback(usePublic: d.action == FallbackAction.usePublic, publicUrl: d.nodeUrl),
        );
        wallet.nodeWhileSyncing = node.nodeWhileSyncing;
        return node;
      }),
    deskStoreProvider.overrideWithValue(store),
    deskBootProvider.overrideWithValue(boot),
    deskFilesProvider.overrideWithValue(const SystemDeskFiles()),
    deskHistoryFilesProvider.overrideWithValue(const SystemDeskHistoryFiles()),
    deskUpdateAutoProvider.overrideWithValue(true),
    deskQuitProvider.overrideWithValue(() async {
      await deskCloseDown(disposeWallet: wallet.dispose, stopNodes: stopAllBuiltInNodes);
      exit(0);
    }),
    if (!deskStartGiven) deskStartProvider.overrideWithValue(hasWallet ? DeskRoute.unlock : DeskRoute.welcome),
  ];
}
