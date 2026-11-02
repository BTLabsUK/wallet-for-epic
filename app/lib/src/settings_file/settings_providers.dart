// SPDX-License-Identifier: Apache-2.0
/// The settings file for the app: [openAppSettings] at start, and the Riverpod side
/// ([hostSettingsProvider], the change streams, [settingsNoticesProvider]).
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network_gate.dart' show NetGate;
import '../secret_store_api.dart';
import 'host_settings.dart';
import 'legacy_import.dart';
import 'network_mode_file.dart';
import 'plain_http_nodes.dart' show importLanNodesFile, writePlainHttpNodes;
import 'settings_backend.dart' show SettingsBackend;
import 'settings_controller.dart';
import 'settings_layout.dart' show settingsKeys;
import 'settings_notice.dart';
import 'settings_platform.dart';

/// The default copy of `settings.toml`, an asset of every build: written to the data folder on
/// the first start.
const String defaultSettingsAsset = 'assets/config/settings.default.toml';

/// `app-config.toml`, an asset of every build, read from there only.
const String appConfigAsset = 'assets/config/app-config.toml';

/// The default copy's name in a dev chain's folder.
const String defaultSettingsFileName = 'settings.default.toml';

SettingsFileController? _installed;
String? _installedChain;
final _installedChanges = StreamController<SettingsFileController>.broadcast(sync: true);
final _allChanges = StreamController<SettingsChange>.broadcast(sync: true);
final _allUseChanges = StreamController<UseChange>.broadcast(sync: true);
StreamSubscription<SettingsChange>? _changesSub;
StreamSubscription<UseChange>? _useSub;

/// Every change of the settings in use, from whichever file is open (a chain switch opens
/// another): for code without a `ref` that follows a value, such as the status-site switch.
Stream<SettingsChange> get hostSettingsChanges => _allChanges.stream;

/// [SettingsFileController.useChanges] of whichever file is open.
Stream<UseChange> get hostUseChanges => _allUseChanges.stream;

/// The controller [openAppSettings] opened, or null before (and in tests that open none).
SettingsFileController? get installedSettingsFile => _installed;

/// The hidden dev chain whose file is open, or null for the data folder's own.
String? get installedSettingsChain => _installedChain;

/// A hidden dev chain lacks its files (`settings.default.toml`, `app-config.toml`): its servers
/// are nowhere, so it does not start.
class DevSettingsMissing implements Exception {
  const DevSettingsMissing(this.chain, this.where);
  final String chain;

  /// Where the files were looked for.
  final String where;

  @override
  String toString() =>
      'No settings for the dev chain $chain in $where: copy them there with app/tool/dev_settings.sh $chain';
}

/// The shipped default copy and configuration as the settings in use and the default copy's,
/// for runs that read and write no file (the mock wallet, the desktop web prototype, the
/// screenshot tours).
Future<HostSettings> loadShippedSettings({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  final config = AppConfig.fromText(await b.loadString(appConfigAsset));
  final shipped = HostSettings.fromText(await b.loadString(defaultSettingsAsset), config: config);
  hostSettings = shipped;
  shippedHostSettings = shipped;
  return shipped;
}

/// Opens the settings for this run and makes them the process-wide [hostSettings]: on the
/// desktop the data folder's `settings.toml`, watched for edits; on the phone the same file,
/// not watched; on the web the text in [store] (`app.settingsToml`). `app-config.toml` is the
/// shipped asset, read-only.
///
/// [devChain] picks a hidden dev chain (a `WFE_DEV_NETWORKS` build): its own folder
/// `<data>/dev/<chain>/` holds its `settings.default.toml`, `app-config.toml` and
/// `settings.toml` (`app/tool/dev_settings.sh` copies the first two there); without them this
/// throws [DevSettingsMissing]. [shippedText] and [configText] replace the two.
///
/// The network mode (`[network] mode`, `network_mode_file.dart`) reaches [NetGate] here, before
/// this returns and so before any connection of the app (Tor, the status site, the price, the
/// updater, the built-in node, a wallet), and again on every change of the file (the app's own
/// writes, a hand edit, a restored backup). The store's old mode moves into the file first, and
/// so do the plain-http agreements of `lan_nodes.json` (`plain_http_nodes.dart`).
Future<SettingsFileController> openAppSettings({
  required SecretStore store,
  String? devChain,
  String? shippedText,
  String? configText,
  AssetBundle? bundle,
}) async {
  final backend = await platformSettingsBackend(store: store, devChain: devChain);
  return openAppSettingsOn(
    backend: backend,
    store: store,
    devChain: devChain,
    shippedText: shippedText,
    configText: configText,
    bundle: bundle,
    walletIds: dataFolderWalletIds,
  );
}

/// [openAppSettings] on [backend] (tests give a folder of their own).
Future<SettingsFileController> openAppSettingsOn({
  required SettingsBackend backend,
  required SecretStore store,
  String? devChain,
  String? shippedText,
  String? configText,
  AssetBundle? bundle,
  Future<List<String>> Function()? walletIds,
}) async {
  var shipped = shippedText;
  var config = configText;
  if (devChain != null) {
    shipped ??= await readDevChainFile(devChain, defaultSettingsFileName);
    config ??= await readDevChainFile(devChain, AppConfig.fileName);
    if (shipped == null || config == null) throw DevSettingsMissing(devChain, await devChainWhere(devChain));
  }
  shipped ??= await (bundle ?? rootBundle).loadString(defaultSettingsAsset, cache: false);
  config ??= await (bundle ?? rootBundle).loadString(appConfigAsset, cache: false);
  final c = await SettingsFileController.open(
    backend: backend,
    shippedText: shipped,
    config: AppConfig.fromText(config),
    watch: settingsWatchSupported,
    publishGlobal: true,
  );
  // The data folder's own file: what 26.10.23 and older kept in the store joins it once.
  if (devChain == null && shippedText == null) {
    await importLegacySettings(store, c, walletIds: walletIds);
    await importNetworkMode(store, c);
    await foldTorSwitch(store, c);
    await importLanNodesFile(store, c);
  }
  NetGate.set(networkModeIn(c.settings));
  final before = _installed;
  _installed = c;
  _installedChain = devChain;
  writePlainHttpNodes = writeHostSettings;
  unawaited(_changesSub?.cancel());
  unawaited(_useSub?.cancel());
  _changesSub = c.changes.listen((e) {
    if (e.keys.contains(networkModeKey)) NetGate.set(networkModeIn(e.after));
    _allChanges.add(e);
  });
  _useSub = c.useChanges.listen(_allUseChanges.add);
  if (before != null) {
    unawaited(before.close());
    _installedChanges.add(c);
    // What follows the settings without a ref reads the new chain's values.
    _allChanges.add(SettingsChange(before.settings, c.settings, {for (final k in settingsKeys) k.path}));
  }
  return c;
}

/// Writes [values] to the settings in use (see [SettingsFileController.setAll]), for code
/// without a `ref`. Without an open file (tests) only the process-wide [hostSettings] change.
Future<void> writeHostSettings(Map<String, Object> values) async {
  final c = _installed;
  if (c == null) {
    hostSettings = hostSettings.withValues(values);
    return;
  }
  await c.setAll(values);
}

/// The settings controller; [installedSettingsFile] unless a test overrides it. A chain switch
/// that opens another file ([openAppSettings] again) replaces it.
final settingsFileProvider = Provider<SettingsFileController?>((ref) => ref.watch(_installedSettingsProvider));

final _installedSettingsProvider = NotifierProvider<_InstalledSettings, SettingsFileController?>(_InstalledSettings.new);

class _InstalledSettings extends Notifier<SettingsFileController?> {
  @override
  SettingsFileController? build() {
    final sub = _installedChanges.stream.listen((c) => state = c);
    ref.onDispose(sub.cancel);
    return installedSettingsFile;
  }
}

/// The settings in use; rebuilds its watchers on every change. Without a controller (most
/// tests) it starts from [hostSettings] and [HostSettingsNotifier.setAll] changes only this
/// container's state.
final hostSettingsProvider = NotifierProvider<HostSettingsNotifier, HostSettings>(HostSettingsNotifier.new);

class HostSettingsNotifier extends Notifier<HostSettings> {
  @override
  HostSettings build() {
    final c = ref.watch(settingsFileProvider);
    if (c == null) return hostSettings;
    final sub = c.changes.listen((e) => state = e.after);
    ref.onDispose(sub.cancel);
    return c.settings;
  }

  Future<void> set(String path, Object value) => setAll({path: value});

  /// Writes [values] to the file (see [SettingsFileController.setAll]).
  Future<void> setAll(Map<String, Object> values) async {
    final c = ref.read(settingsFileProvider);
    if (c == null) {
      state = state.withValues(values);
      return;
    }
    await c.setAll(values);
    state = c.settings;
  }
}

/// Changes of `node.use` and `epicbox.use`, from the app or a hand edit.
final settingsUseChangesProvider = StreamProvider<UseChange>(
  (ref) => ref.watch(settingsFileProvider)?.useChanges ?? const Stream.empty(),
);

/// The notices not yet dismissed, oldest first (those from before the first watch too).
final settingsNoticesProvider = NotifierProvider<SettingsNoticesNotifier, List<SettingsNotice>>(
  SettingsNoticesNotifier.new,
);

class SettingsNoticesNotifier extends Notifier<List<SettingsNotice>> {
  final Set<SettingsNotice> _dismissed = {};

  @override
  List<SettingsNotice> build() {
    final c = ref.watch(settingsFileProvider);
    if (c == null) return const [];
    final sub = c.noticeStream.listen((n) => state = [...state, n]);
    ref.onDispose(sub.cancel);
    return [
      for (final n in c.notices)
        if (!_dismissed.contains(n)) n,
    ];
  }

  void dismiss(SettingsNotice notice) {
    _dismissed.add(notice);
    state = [
      for (final n in state)
        if (n != notice) n,
    ];
  }
}
