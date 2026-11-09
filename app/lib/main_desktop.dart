// SPDX-License-Identifier: Apache-2.0
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

import 'src/network.dart' show devChainOf, mainnetPreset;
import 'src/network_gate.dart';
import 'src/app_log.dart';
import 'src/btlabs_onions.dart';
import 'src/builtin_node.dart';
import 'src/builtin_node_provider.dart';
import 'src/data_folder.dart';
import 'src/desktop/app/close_guard.dart' show deskHoldExit;
import 'src/desktop/app/desk_app.dart';
import 'src/desktop/app/desk_window.dart';
import 'src/desktop/app/window_placement.dart';
import 'src/desktop/app/tray/tray_host.dart';
import 'src/desktop/app/tray/tray_linux.dart';
import 'src/desktop/app/tray/tray_windows.dart';
import 'src/desktop/app/shell.dart' show deskVersion;
import 'src/desktop/data/close_down.dart';
import 'src/desktop/data/desk_link_handler.dart';
import 'src/desktop/data/desk_node.dart';
import 'src/desktop/data/desk_update.dart' show deskUpdateAutoProvider;
import 'src/desktop/keyring_check.dart';
import 'src/desktop/screens/settings/local_node_dialogs.dart' show deskPickFolder;
import 'src/desktop/data/desk_levels.dart';
import 'src/desktop/data/name_service_state.dart' show deskNameServices, deskLinkPayments;
import 'src/desktop/data/pairing_state.dart' show deskPairingRefusalsProvider;
import 'src/name_service/membership.dart' show nameServiceMembershipProvider;
import 'src/name_service/payment_refusals.dart' show paymentRefusalsProvider;
import 'src/name_service/receipts.dart' show nameServiceReceiptsProvider, linkPaymentRecordsProvider;
import 'src/desktop/data/desk_store.dart';
import 'src/desktop/data/file_dialogs.dart';
import 'src/desktop/data/files.dart';
import 'src/desktop/data/history_files.dart';
import 'src/desktop/data/lepic_desk_wallet.dart';
import 'src/desktop/data/logs.dart';
import 'src/desktop/widgets/kit.dart';
import 'src/invite_links.dart' show launchArgumentsProvider;
import 'src/password_lists.dart';
import 'src/price.dart' show fiatChoiceProvider;
import 'src/tor_licence.dart';
import 'src/ui/theme/fonts.dart' show registerFontLicences;
import 'src/providers.dart';
import 'src/relay_directory.dart';
import 'src/services/service_loader.dart' show startServices;
import 'src/settings_file/host_settings.dart' show hostSettings;
import 'src/settings_file/network_mode_file.dart' show networkModeIn;
import 'src/settings_file/settings_providers.dart';
import 'src/tor_location.dart';
import 'src/wallet_backend.dart';
import 'src/web/splash.dart';

const bool _mock = bool.fromEnvironment('WFE_DESK_MOCK');

/// Kept for the app's lifetime; stops the built-in node when the window closes.
// ignore: unused_element
AppLifecycleListener? _exitListener;

/// Keeps the window's size and place (Linux, macOS); saved once more on the way out.
DeskWindowKeeper? _windowKeeper;

/// The tray, for Sync in background (tray/desk_tray.dart); none on macOS for now.
TrayHost _tray = NoTray();

Future<void>? _closing;

/// Every way out (Quit, the window's close, a signal, Windows' end of session) closes down once:
/// the tray's icon goes, the window's place is kept, the wallet locks and the node stops.
/// [hurry]: the system is ending the session and waits only so long.
Future<void> _closeDown(LepicDeskWallet wallet, {bool hurry = false}) => _closing ??= () async {
  try {
    await _tray.remove().timeout(const Duration(seconds: 2));
  } on Object catch (e) {
    logWarn('tray', 'icon not removed (${e.runtimeType})');
  }
  await _windowKeeper?.save();
  await deskCloseDown(
    disposeWallet: wallet.dispose,
    stopNodes: stopAllBuiltInNodes,
    walletLimit: hurry ? const Duration(seconds: 6) : const Duration(seconds: 40),
    nodeLimit: hurry ? const Duration(seconds: 12) : const Duration(seconds: 25),
  );
}();

/// [args]: the runner's command line; a browser passes an `epic:` or `epiccash:` link there.
Future<void> main(List<String> args) async {
  final launch = launchArgumentsProvider.overrideWithValue(List<String>.unmodifiable(args));
  if (_mock) {
    WidgetsFlutterBinding.ensureInitialized();
    // The mock wallet shows the shipped servers; it reads and writes no file.
    await loadShippedSettings();
    await startServices();
    final window = await SystemDeskWindow.init();
    await placeDeskWindow(null);
    runApp(ProviderScope(overrides: [launch, nameServiceMembershipProvider.overrideWith((ref) => ref.watch(deskNameServices.membership)), paymentRefusalsProvider.overrideWith((ref) => ref.watch(deskPairingRefusalsProvider)), nameServiceReceiptsProvider.overrideWith((ref) => ref.watch(deskNameServices.receipts)), linkPaymentRecordsProvider.overrideWith((ref) => ref.watch(deskLinkPayments)), if (window != null) deskWindowProvider.overrideWithValue(window)], child: const DeskApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
    return;
  }
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await setUpDeskFileDialogs();
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
    registerFontLicences();
    registerPasswordListLicences();
    registerTorLicence();
    logInfo('app', 'desktop start $deskVersion, $platformLabel');
    if (Platform.isLinux) unawaited(registerAppImageLinks());
    // Linux without a keyring to use: say so on the first screen, before libsecret is asked
    // anything (it would hold the window's thread, so no window showed).
    final keyring = await checkLinuxKeyring();
    if (keyring != null) {
      // The first-start size: the settings with the saved one are behind the keyring.
      await placeDeskWindow(null);
      final ready = Completer<void>();
      runApp(KeyringApp(problem: keyring, check: checkLinuxKeyring, onReady: () => ready.isCompleted ? null : ready.complete()));
      await ready.future;
    }
    final overrides = await deskOverrides();
    // The app's own title bar from here on (the keyring screen above keeps the system's).
    final window = await SystemDeskWindow.init();
    if (window != null) overrides.add(deskWindowProvider.overrideWithValue(window));
    overrides.add(launch);
    // Size and place before the first frame, which shows the window (window_placement.dart).
    _windowKeeper = await placeDeskWindow(DeskStore(createSecretStore()));
    // Wallet errors are final answers (wrong password, node down); do not retry them silently.
    runApp(ProviderScope(retry: (_, _) => null, overrides: overrides, child: const DeskApp()));
  }, (error, stack) {
    logError('zone', error, stack);
    // macOS keeps the window hidden until it is placed: never leave it so after a failed start.
    unawaited(showDeskWindow());
  });
}

Future<bool> _walletsOnDisk() async => deskWalletsOnDisk(await appDataDirectory());

/// Whether `<data>/wallets` holds any file: a wallet was created or restored here (the first
/// wallet's folder alone may exist empty).
Future<bool> deskWalletsOnDisk(Directory data) async {
  final dir = Directory('${data.path}${Platform.pathSeparator}wallets');
  if (!await dir.exists()) return false;
  return dir.list(recursive: true).any((e) => e is File);
}

/// The real wallet behind the desktop UI, its saved settings read before the first frame, and
/// the first screen: Welcome without a wallet, Unlock with one.
Future<List<Override>> deskOverrides() async {
  final container = ProviderContainer();
  final secrets = container.read(secretStoreProvider);
  final store = DeskStore(secrets);
  // Before the settings open and before any request: a fresh install opens no connection until
  // Welcome's depth dial is answered (levels/first_start.dart, desk_levels.dart).
  // First, before this run writes a key: an install that ran before never gets the first-run
  // tour by itself (first_run_tour.dart).
  await deskSettleFirstRunTour(store, walletsOnDisk: _walletsOnDisk);
  await deskHoldUntilFirstStart(secrets, walletsOnDisk: _walletsOnDisk);
  // Before the wallet core starts: its runtime takes the log level once.
  await applySavedLogLevel(store);
  // Before anything reads an address: the settings file (docs/settings-file.md), watched for
  // hand edits. A dev build on a test network reads that network's own file.
  final preset = DeskFeatures.testNetworks ? await LepicDeskWallet.savedPreset(secrets) : mainnetPreset;
  try {
    await openAppSettings(store: secrets, devChain: devChainOf(preset.chain));
  } on DevSettingsMissing catch (e) {
    // A dev build only: it does not start on a network without its servers.
    logError('settings', e, StackTrace.current);
    stderr.writeln('$e');
    exit(2);
  }
  // Hints Send shows for a known kind of address (docs/services.md); none without files.
  await startServices();
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
  // The network mode is settings.toml's (`network_mode_file.dart`): openAppSettings above
  // applied it to NetGate before anything could connect; the desktop's settings take it too.
  boot = boot.withNetworkMode(networkModeIn(hostSettings));
  NetGate.set(boot.settings.advanced.networkMode);
  // Before anything asks the status site: off (`status.enabled`), nothing is asked.
  statusSite.followSettings();
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
  late final LepicDeskWallet wallet;
  // A wallet opened with the Tor switch on waits for tor, so a missing tor bundle blocks.
  wantTorAtOpen((config) => wallet.torWantedAt(config));
  wallet = LepicDeskWallet(
    // A dev build with test networks starts on the one chosen last on Welcome.
    preset: preset,
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
    // The BT Labs contact's website copy; the bundled one is used until it answers.
    seedFetch: LepicDeskWallet.fetchSeeds,
    onions: container.read(onionDirectoryProvider),
  );
  // Off by default: this starts a node only when the user turned it on before.
  unawaited(wallet.resumeBuiltInNode());
  // Closing the window must not leave the node running, nor cut off a send: while one runs
  // the app stays open and asks (close_guard.dart, the rule of the title bar's close and Ctrl+Q).
  _exitListener = AppLifecycleListener(
    onExitRequested: () async {
      if (deskHoldExit()) return AppExitResponse.cancel;
      await _closeDown(wallet);
      return AppExitResponse.exit;
    },
  );
  deskCloseOnSignals(() async {
    await _closeDown(wallet);
    exit(0);
  });
  // Sync in background's tray. Linux: a StatusNotifierItem host, when the desktop has one
  // (GNOME needs the AppIndicator extension); none answers, the setting says it is unavailable.
  if (Platform.isLinux) {
    _tray = await LinuxTray.start() ?? NoTray();
  } else if (Platform.isWindows) {
    // Windows sends no signal at shutdown or sign-out: the runner passes it on, and waits.
    _tray = WindowsTray()..onEndSession = () => _closeDown(wallet, hurry: true);
  }
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
    // What the rest of the app may ask of the name services the open wallet joined.
    nameServiceMembershipProvider.overrideWith((ref) => ref.watch(deskNameServices.membership)),
    paymentRefusalsProvider.overrideWith((ref) => ref.watch(deskPairingRefusalsProvider)),
    nameServiceReceiptsProvider.overrideWith((ref) => ref.watch(deskNameServices.receipts)),
    linkPaymentRecordsProvider.overrideWith((ref) => ref.watch(deskLinkPayments)),
    // The balance line's dollars (overview_screen.dart), not the phone's fiat settings; none on
    // a dev build's test network.
    fiatChoiceProvider.overrideWith((ref) async => (show: preset.chain == mainnetPreset.chain, currency: 'usd')),
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
      await _closeDown(wallet);
      exit(0);
    }),
    deskTrayHostProvider.overrideWithValue(_tray),
    if (!deskStartGiven) deskStartProvider.overrideWithValue(hasWallet ? DeskRoute.unlock : DeskRoute.welcome),
  ];
}
