// SPDX-License-Identifier: Apache-2.0
/// The one-time import of what 26.10.23 and older kept in the app's store into `settings.toml`
/// (26.10.24 started the file from the default copy and read none of it, so an update lost the
/// user's servers and choices).
///
/// Read from the store, mainnet only (a dev network's records stay apart):
/// - the Node and Epicbox lists: `desk.serverList.<kind>.mainnet` (desktop) and
///   `app.serverList.<kind>.mainnet` (phone), a [ServerList] JSON; without one, the older own
///   lists (`desk.nodes`, `app.myNodes.mainnet`, `app.myRelays.mainnet`) and the desktop's
///   `removedNodes` (`desk.prefs`);
/// - the node and the Epicbox server in use: `app.node.mainnet`, `app.relay.mainnet` (both
///   apps);
/// - Epicbox servers the lists did not hold: a desktop wallet's own (wallet record `epicbox`)
///   and the Connection servers (`desk.pairingRelays.mainnet`, `app.pairingRelays.mainnet`);
/// - the status-site switch: `app.status_site` (phone), `useStatusSite` of `desk.settings`.
///
/// Per key of the file: one still as the default copy has it takes the old choice (the server
/// in use first, then the old list in its order, then the default servers it did not hold,
/// except those the user removed). One the user has changed since keeps that change, and only
/// the user's own servers it lacks join at its end. The old records are never deleted;
/// [legacyImportedKey] marks them imported, so this runs once.
library;

import 'dart:convert';

import '../log.dart';
import '../network.dart' show EpicboxRelay;
import '../secret_store_api.dart';
import '../server_list.dart' show ServerKind, ServerList, serverKeyOf;
import 'host_settings.dart';
import 'settings_controller.dart';
import 'settings_layout.dart' show checkEpicboxServer, checkNodeAddress;
import 'toml_edit.dart' show deepEquals;

/// Set once the old records were imported (or there were none).
const String legacyImportedKey = 'app.settingsImported';

/// The chain whose records are imported: the only one with a settings file of its own in the
/// data folder.
const String _chain = 'mainnet';

/// What the store held for one kind.
class LegacyList {
  const LegacyList({this.entries = const [], this.removed = const {}, this.inUse, this.extra = const []});

  /// The list in its order.
  final List<String> entries;

  /// Keys ([serverKeyOf]) of default servers the user took out.
  final Set<String> removed;

  /// The server in use.
  final String? inUse;

  /// Servers in use elsewhere that the list did not hold (a wallet's own Epicbox server, the
  /// Connection servers): kept, after the list.
  final List<String> extra;

  bool get isEmpty => entries.isEmpty && removed.isEmpty && inUse == null && extra.isEmpty;
}

/// Everything 26.10.23 kept that the settings file now holds.
class LegacySettings {
  const LegacySettings({this.nodes = const LegacyList(), this.relays = const LegacyList(), this.statusSite});

  final LegacyList nodes;
  final LegacyList relays;

  /// The status-site switch; null when never set.
  final bool? statusSite;

  bool get isEmpty => nodes.isEmpty && relays.isEmpty && statusSite == null;
}

/// Reads the old records from [store]. [walletIds] are the registry ids of the desktop's added
/// wallets (their records hold their own Epicbox server). Throws when the store cannot be read.
Future<LegacySettings> readLegacySettings(SecretStore store, {List<String> walletIds = const []}) async {
  Future<Object?> json(String key) async {
    final raw = await store.read(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  List<String> texts(Object? j) => [if (j is List) for (final e in j) if (e is String && e.trim().isNotEmpty) e.trim()];

  Future<ServerList?> list(ServerKind kind) async {
    final desk = ServerList.decode(await store.read('desk.serverList.${kind.name}.$_chain'));
    final phone = ServerList.decode(await store.read('app.serverList.${kind.name}.$_chain'));
    if (desk == null) return phone;
    if (phone == null) return desk;
    return ServerList(entries: [...desk.entries, ...phone.entries], removed: {...desk.removed, ...phone.removed});
  }

  String? text(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

  // Nodes.
  final nodeList = await list(ServerKind.node);
  final List<String> nodeEntries;
  final Set<String> nodeRemoved;
  if (nodeList != null) {
    nodeEntries = nodeList.entries;
    nodeRemoved = nodeList.removed;
  } else {
    final deskNodes = await json('desk.nodes');
    final prefs = await json('desk.prefs');
    nodeEntries = [
      if (deskNodes is List)
        for (final n in deskNodes)
          if (n is Map && n['url'] is String) n['url'] as String,
      ...texts(await json('app.myNodes.$_chain')),
    ];
    nodeRemoved = {for (final u in texts(prefs is Map ? prefs['removedNodes'] : null)) serverKeyOf(ServerKind.node, u)};
  }

  // Epicbox servers.
  final relayList = await list(ServerKind.relay);
  final walletRelays = <String>[];
  for (final key in ['desk.wallet.$_chain', for (final id in walletIds) 'desk.wallet.$_chain.$id']) {
    final meta = await json(key);
    if (meta is Map && meta['epicbox'] is String) walletRelays.add(meta['epicbox'] as String);
  }
  final pairing = [...texts(await json('desk.pairingRelays.$_chain')), ...texts(await json('app.pairingRelays.$_chain'))];

  // The status-site switch.
  final phoneSite = await store.read('app.status_site');
  final desk = await json('desk.settings');
  final deskSite = desk is Map && desk['useStatusSite'] is bool ? desk['useStatusSite'] as bool : null;
  final site = phoneSite == 'false' || deskSite == false ? false : (phoneSite == 'true' || deskSite == true ? true : null);

  return LegacySettings(
    nodes: LegacyList(entries: nodeEntries, removed: nodeRemoved, inUse: text(await store.read('app.node.$_chain'))),
    relays: LegacyList(
      entries: relayList?.entries ?? texts(await json('app.myRelays.$_chain')),
      removed: relayList?.removed ?? const {},
      inUse: text(await store.read('app.relay.$_chain')),
      extra: [...walletRelays, ...pairing],
    ),
    statusSite: site,
  );
}

/// [value] as the file writes it, or null when the file would refuse it.
String? _fileValue(ServerKind kind, String value) {
  if (kind == ServerKind.node) return checkNodeAddress(value) == null ? value : null;
  final label = EpicboxRelay.parse(value)?.label;
  return label != null && checkEpicboxServer(label) == null ? label : null;
}

/// One kind's list after the import: [current] is the file's, [shipped] the default copy's.
List<String> mergeLegacyList(ServerKind kind, LegacyList old, {required List<String> current, required List<String> shipped}) {
  final out = <String>[];
  final keys = <String>{};
  void add(String v) {
    final value = _fileValue(kind, v);
    if (value != null && keys.add(serverKeyOf(kind, value))) out.add(value);
  }

  final mine = [?old.inUse, ...old.entries, ...old.extra];
  if (_sameList(kind, current, shipped)) {
    // Untouched since the default copy was written: the old list as it was.
    mine.forEach(add);
    for (final v in shipped) {
      if (!old.removed.contains(serverKeyOf(kind, v))) add(v);
    }
  } else {
    // Changed since: that change stays; only the user's own servers it lacks join it.
    current.forEach(add);
    final defaults = {for (final v in shipped) serverKeyOf(kind, v)};
    for (final v in mine) {
      if (!defaults.contains(serverKeyOf(kind, v))) add(v);
    }
  }
  return out;
}

bool _sameList(ServerKind kind, List<String> a, List<String> b) =>
    a.length == b.length && [for (var i = 0; i < a.length; i++) serverKeyOf(kind, a[i]) == serverKeyOf(kind, b[i])].every((s) => s);

/// The keys to write for [old] into [now] (the file's settings); [shipped] are the default
/// copy's. Empty when nothing changes.
Map<String, Object> legacyImportValues(LegacySettings old, {required HostSettings now, required HostSettings shipped}) {
  final out = <String, Object>{};
  if (!old.nodes.isEmpty) {
    final next = mergeLegacyList(ServerKind.node, old.nodes, current: now.nodeUrls, shipped: shipped.nodeUrls);
    if (!deepEquals(next, now.nodeUrls)) out['node.servers'] = next;
  }
  if (!old.relays.isEmpty) {
    List<String> labels(HostSettings s) => [for (final b in s.epicboxServers) b.label];
    final next = mergeLegacyList(ServerKind.relay, old.relays, current: labels(now), shipped: labels(shipped));
    if (!deepEquals(next, labels(now))) out['epicbox.servers'] = next;
  }
  final site = old.statusSite;
  if (site != null && now.statusEnabled == shipped.statusEnabled && site != now.statusEnabled) {
    out['online.status_site'] = site;
  }
  return out;
}

/// Imports the old records of [store] into [file] once (see the library comment). Never throws:
/// a store that cannot be read is tried again at the next start.
Future<void> importLegacySettings(
  SecretStore store,
  SettingsFileController file, {
  Future<List<String>> Function()? walletIds,
}) async {
  try {
    if (await store.read(legacyImportedKey) != null) return;
    final old = await readLegacySettings(store, walletIds: await walletIds?.call() ?? const []);
    if (!old.isEmpty) {
      final values = legacyImportValues(old, now: file.settings, shipped: file.shipped);
      if (values.isNotEmpty) {
        await file.setAll(values);
        // A write that failed leaves the file as it was: try again at the next start.
        for (final e in values.entries) {
          if (!deepEquals(file.settings.value(e.key), e.value)) {
            logWarn('settings', 'older settings not imported: ${e.key} not written');
            return;
          }
        }
      }
      logInfo('settings', 'older settings imported: ${values.keys.join(', ')}');
    }
    await store.write(legacyImportedKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String()}));
  } on Object catch (e) {
    logWarn('settings', 'older settings not imported: ${e.runtimeType}');
  }
}
