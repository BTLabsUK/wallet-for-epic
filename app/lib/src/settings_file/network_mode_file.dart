// SPDX-License-Identifier: Apache-2.0
/// The network mode in `settings.toml` (docs/settings-file.md, docs/network-modes.md): the one
/// place both apps keep it. A `[network]` table with `mode = "tor_only" | "node_only" |
/// "kill_switch"`, written only while the mode is not Normal and taken out again for Normal.
///
/// [importNetworkMode] moves the mode builds before 26.10.25 kept in the app's store (the
/// phone's `app.advanced_prefs`, the desktop's `desk.settings`) into the file once: Offline
/// lands in Node only, Tor only stays Tor only, Normal writes nothing. It runs where the file
/// opens ([openAppSettings]), before the mode is applied.
library;

import 'dart:convert';

import '../advanced.dart';
import '../log.dart';
import '../secret_store_api.dart';
import '../tor_build.dart';
import 'host_settings.dart';
import 'settings_controller.dart';

/// The key of the mode in `settings.toml`.
const String networkModeKey = 'network.mode';

/// Set once the store's old mode was moved into the file (or there was none).
const String networkModeMovedKey = 'app.networkModeMoved';

/// The mode [s] holds: Normal without the key, and in the build without Tor ([torBuilt]) a Tor
/// only reads as Normal (nothing could carry it).
NetworkMode networkModeIn(HostSettings s) {
  final mode = networkModeNamed(s.networkModeText) ?? NetworkMode.standard;
  return !torBuilt && mode == NetworkMode.torOnly ? NetworkMode.standard : mode;
}

/// The file's value for [mode]: empty for Normal, which takes the key out of the file.
String networkModeText(NetworkMode mode) => switch (mode) {
  NetworkMode.standard => '',
  NetworkMode.torOnly => 'tor_only',
  NetworkMode.nodeOnly => 'node_only',
  NetworkMode.killSwitch => 'kill_switch',
};

/// Writes [mode] to the settings in use ([writeHostSettings]-style, through [write]).
Future<void> saveNetworkMode(NetworkMode mode, Future<void> Function(Map<String, Object> values) write) =>
    write({networkModeKey: networkModeText(mode)});

/// The mode the store kept before 26.10.25, read raw (an old `offline` is Node only); null
/// when neither app stored one or it was Normal. The phone's `app.advanced_prefs` is
/// `features|mode|…`, the desktop's `desk.settings` JSON has `advanced.networkMode`.
Future<NetworkMode?> readLegacyNetworkMode(SecretStore store) async {
  final found = <NetworkMode>{};
  final phone = await store.read('app.advanced_prefs');
  if (phone != null) {
    final parts = phone.split('|');
    if (parts.length > 1) found.add(networkModeNamed(parts[1]) ?? NetworkMode.standard);
  }
  final desk = await store.read('desk.settings');
  if (desk != null) {
    try {
      final j = jsonDecode(desk);
      final mode = j is Map && j['advanced'] is Map ? (j['advanced'] as Map)['networkMode'] : null;
      if (mode is String) found.add(networkModeNamed(mode) ?? NetworkMode.standard);
    } on FormatException {
      // Not JSON: nothing to take.
    }
  }
  // Both apps' records in one store (never in a real install): the stricter wins.
  for (final m in const [NetworkMode.killSwitch, NetworkMode.nodeOnly, NetworkMode.torOnly]) {
    if (found.contains(m)) return m;
  }
  return null;
}

/// Moves the store's old mode into [file] once (see the library comment). A file that already
/// names a mode keeps it. Never throws: a store that cannot be read, or a write that did not
/// take, is tried again at the next start; the marker is written only after the file holds the
/// mode, so a later choice of the user is never overridden by a second run.
Future<void> importNetworkMode(SecretStore store, SettingsFileController file) async {
  try {
    if (await store.read(networkModeMovedKey) != null) return;
    var old = await readLegacyNetworkMode(store);
    // Tor only in the build without Tor runs as Normal: nothing to write.
    if (old == NetworkMode.torOnly && !torBuilt) old = null;
    if (old != null && networkModeIn(file.settings) == NetworkMode.standard) {
      await saveNetworkMode(old, file.setAll);
      if (networkModeIn(file.settings) != old) {
        logWarn('settings', 'network mode not moved: not written');
        return;
      }
      logInfo('settings', 'network mode moved to the settings file: ${old.name}');
    }
    await store.write(networkModeMovedKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String()}));
  } on Object catch (e) {
    logWarn('settings', 'network mode not moved: ${e.runtimeType}');
  }
}

/// Set once the old "Tor for all connections" switch was mapped onto the mode ([foldTorSwitch]).
const String torSwitchFoldedKey = 'app.torSwitchFolded';

/// The old Tor switch (Network & privacy, gone in 26.10.26) on in Normal becomes Tor only, once,
/// before anything connects: Tor only is the one whole-wallet Tor control. Desktop: the app-wide
/// `desk.tor_switch`, else Wallet 1's `desk.autostart`; phone: Wallet 1's
/// `phone.tor_receiving.<chain>.legacy`. Never throws; the marker follows the write.
Future<void> foldTorSwitch(SecretStore store, SettingsFileController file) async {
  try {
    if (await store.read(torSwitchFoldedKey) != null) return;
    Object? json(String? t) {
      try {
        return t == null ? null : jsonDecode(t);
      } on FormatException {
        return null;
      }
    }

    final desk = json(await store.read('desk.tor_switch')) ?? json(await store.read('desk.autostart'));
    var on = desk is Map && (desk['on'] == true || (desk['on'] == null && desk['tor'] == true));
    for (final chain in const ['mainnet', 'floonet', 'usernet']) {
      on = on || await store.read('phone.tor_receiving.$chain.legacy') == 'true';
    }
    if (torBuilt && on && networkModeIn(file.settings) == NetworkMode.standard) {
      await saveNetworkMode(NetworkMode.torOnly, file.setAll);
      if (networkModeIn(file.settings) != NetworkMode.torOnly) return;
      logInfo('settings', 'tor switch was on: tor_only');
    }
    await store.write(torSwitchFoldedKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String()}));
  } on Object catch (e) {
    logWarn('settings', 'tor switch not mapped: ${e.runtimeType}');
  }
}
