// SPDX-License-Identifier: Apache-2.0
/// The settings file for the app: [openAppSettings] at start, and the Riverpod side
/// ([hostSettingsProvider], the change streams, [settingsNoticesProvider]).
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../secret_store_api.dart';
import 'host_settings.dart';
import 'settings_controller.dart';
import 'settings_layout.dart' show settingsKeys;
import 'settings_notice.dart';
import 'settings_platform.dart';

/// The shipped default, an asset of every build.
const String shippedSettingsAsset = 'assets/settings/settings.toml';

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

/// A hidden dev chain has no settings file: its servers are nowhere, so it does not start.
class DevSettingsMissing implements Exception {
  const DevSettingsMissing(this.chain, this.where);
  final String chain;

  /// Where the file was looked for.
  final String where;

  @override
  String toString() =>
      'No settings for the dev chain $chain at $where: copy one there with app/tool/dev_settings.sh $chain';
}

/// Opens the settings for this run and makes them the process-wide [hostSettings]: on the
/// desktop the data folder's `settings.toml`, watched for edits; on the phone the same file,
/// not watched; on the web the text in [store] (`app.settingsToml`).
///
/// [devChain] picks a hidden dev chain's own file (`<data>/dev/<chain>/settings.toml`, which
/// `app/tool/dev_settings.sh` copies there): it is its own default, so it must exist, else
/// this throws [DevSettingsMissing]. [shippedText] replaces the shipped asset (the web demo's
/// file from its server).
Future<SettingsFileController> openAppSettings({
  required SecretStore store,
  String? devChain,
  String? shippedText,
  AssetBundle? bundle,
}) async {
  final backend = await platformSettingsBackend(store: store, devChain: devChain);
  var shipped = shippedText;
  if (devChain != null) {
    shipped ??= await backend.read();
    if (shipped == null) throw DevSettingsMissing(devChain, settingsWhere(backend));
  }
  shipped ??= await (bundle ?? rootBundle).loadString(shippedSettingsAsset, cache: false);
  final c = await SettingsFileController.open(
    backend: backend,
    shippedText: shipped,
    watch: settingsWatchSupported,
    publishGlobal: true,
  );
  final before = _installed;
  _installed = c;
  _installedChain = devChain;
  unawaited(_changesSub?.cancel());
  unawaited(_useSub?.cancel());
  _changesSub = c.changes.listen(_allChanges.add);
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

/// Every change of the settings in use.
final settingsChangesProvider = StreamProvider<SettingsChange>(
  (ref) => ref.watch(settingsFileProvider)?.changes ?? const Stream.empty(),
);

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
