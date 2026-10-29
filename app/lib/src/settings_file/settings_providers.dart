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
import 'settings_notice.dart';
import 'settings_platform.dart';

/// The shipped default, an asset of every build.
const String shippedSettingsAsset = 'assets/settings/settings.toml';

SettingsFileController? _installed;

/// The controller [openAppSettings] opened, or null before (and in tests that open none).
SettingsFileController? get installedSettingsFile => _installed;

/// Opens the settings for this run and makes them the process-wide [hostSettings]: on the
/// desktop the data folder's `settings.toml`, watched for edits; on the phone the same file,
/// not watched; on the web the text in [store] (`app.settingsToml`). [devChain] picks a hidden
/// dev chain's own file (`<data>/dev/<chain>/settings.toml`).
Future<SettingsFileController> openAppSettings({
  required SecretStore store,
  String? devChain,
  AssetBundle? bundle,
}) async {
  final shippedText = await (bundle ?? rootBundle).loadString(shippedSettingsAsset, cache: false);
  final backend = await platformSettingsBackend(store: store, devChain: devChain);
  final c = await SettingsFileController.open(
    backend: backend,
    shippedText: shippedText,
    watch: settingsWatchSupported,
    publishGlobal: true,
  );
  _installed = c;
  return c;
}

/// The settings controller; [installedSettingsFile] unless a test overrides it.
final settingsFileProvider = Provider<SettingsFileController?>((ref) => installedSettingsFile);

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
