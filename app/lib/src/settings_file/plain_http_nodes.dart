// SPDX-License-Identifier: Apache-2.0
/// The nodes the user agreed to reach over plain http (`lan_node_relay.dart`: a CGNAT address,
/// 100.64.0.0/10, a Tailscale tailnet or a provider's network): `[node] plain_http` of
/// `settings.toml`, next to `servers` (docs/settings-file.md). A node is matched by `host:port`
/// (80 when the address names none), so the agreement holds however its address is spelled.
/// Removing a node from the list in the app removes its agreement ([withPlainHttpKept]).
///
/// [importLanNodesFile] moves the agreements 26.10.25 and older kept in `lan_nodes.json` of the
/// data folder into the file once, where the file opens ([openAppSettings]). The old file is
/// left as it is and never written again (remove it one release later).
library;

import 'dart:convert';

import '../log.dart';
import '../secret_store_api.dart';
import 'host_settings.dart';
import 'settings_controller.dart';

/// The key of the agreed nodes in `settings.toml`.
const String plainHttpKey = 'node.plain_http';

/// Set once `lan_nodes.json` was moved into the file (or there was none).
const String lanNodesMovedKey = 'app.lanNodesMoved';

/// The text of `lan_nodes.json` in the data folder, or null when there is none: set at start
/// by `settleDataFolder` (data_folder_io.dart), so this file stays free of `dart:io`. Read only,
/// never written. Tests replace it.
Future<String?> Function() readLanNodesFile = () async => null;

/// Writes `settings.toml` values for code without a `ref` (`writeHostSettings`, set where the
/// file opens). Without an open file (tests) only the process-wide [hostSettings] change.
Future<void> Function(Map<String, Object> values) writePlainHttpNodes = (values) async =>
    hostSettings = hostSettings.withValues(values);

/// The key a node is agreed for by: `host:port`, lower case, 80 when [url] names no port; null
/// when it is not an address.
String? plainHttpNodeKey(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return null;
  return '${u.host.toLowerCase()}:${u.hasPort ? u.port : 80}';
}

/// The agreed nodes of [s], as written.
List<String> plainHttpNodesIn(HostSettings s) => s.value(plainHttpKey) as List<String>;

/// Whether [s] holds an agreement for [url].
bool plainHttpAgreedIn(HostSettings s, String url) {
  final key = plainHttpNodeKey(url);
  return key != null && plainHttpNodesIn(s).any((n) => plainHttpNodeKey(n) == key);
}

/// [s]'s agreements with [url] added (unchanged when it is there).
List<String> plainHttpWith(HostSettings s, String url) =>
    plainHttpAgreedIn(s, url) ? plainHttpNodesIn(s) : [...plainHttpNodesIn(s), url.trim()];

/// [values] (an app write) with the agreements of nodes it takes out of the list dropped: a
/// write of `node.servers` that leaves an agreed node out also writes `node.plain_http` without
/// it. Unchanged otherwise.
Map<String, Object> withPlainHttpKept(Map<String, Object> values, HostSettings now) {
  final servers = values['node.servers'];
  if (servers is! List || values.containsKey(plainHttpKey)) return values;
  final kept = plainHttpKept(plainHttpNodesIn(now), servers.whereType<String>());
  return kept.length == plainHttpNodesIn(now).length ? values : {...values, plainHttpKey: kept};
}

/// The agreements of [agreed] whose node is in [servers].
List<String> plainHttpKept(Iterable<String> agreed, Iterable<String> servers) {
  final listed = {for (final s in servers) ?plainHttpNodeKey(s)};
  return [
    for (final a in agreed)
      if (listed.contains(plainHttpNodeKey(a))) a,
  ];
}

/// The `host:port` keys `lan_nodes.json` agreed for (`{"plainHttp": [...]}`); empty when it
/// cannot be read.
Set<String> lanNodesFileKeys(String text) {
  try {
    final json = jsonDecode(text);
    if (json is Map && json['plainHttp'] is List) return {...(json['plainHttp'] as List).whereType<String>()};
  } on FormatException {
    // Unreadable: nothing agreed, as the old file's reader took it.
  }
  return const {};
}

/// Moves the agreements of `lan_nodes.json` into [file] once (see the library comment): each
/// node of the Node list the old file agreed for joins `node.plain_http`; agreements for nodes
/// no longer in the list are dropped. Never throws: a store that cannot be read, or a write that
/// did not take, is tried again at the next start; the marker is written only after the file
/// holds the agreements, and a rerun adds nothing the file already has.
Future<void> importLanNodesFile(SecretStore store, SettingsFileController file) async {
  try {
    if (await store.read(lanNodesMovedKey) != null) return;
    final text = await readLanNodesFile();
    if (text != null) {
      final keys = lanNodesFileKeys(text);
      var next = plainHttpNodesIn(file.settings);
      for (final node in file.settings.nodeUrls) {
        if (keys.contains(plainHttpNodeKey(node)) && !plainHttpAgreedIn(file.settings, node)) next = [...next, node];
      }
      if (next.length != plainHttpNodesIn(file.settings).length) {
        await file.setAll({plainHttpKey: next});
        if (plainHttpNodesIn(file.settings).length != next.length) {
          logWarn('settings', 'lan_nodes.json not moved: not written');
          return;
        }
      }
      logInfo('settings', 'lan_nodes.json moved to the settings file: ${next.length} node(s)');
    }
    await store.write(lanNodesMovedKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String()}));
  } on Object catch (e) {
    logWarn('settings', 'lan_nodes.json not moved: ${e.runtimeType}');
  }
}
