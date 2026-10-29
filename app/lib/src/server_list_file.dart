// SPDX-License-Identifier: Apache-2.0
/// The Node and Epicbox lists ([ServerList]) as the settings file holds them
/// (`docs/settings-file.md`): `[[node.servers]]` and `node.removed`, `[[epicbox.servers]]` and
/// `epicbox.removed`. The phone's and the desktop's list controllers read and write them here;
/// nothing else keeps a list.
///
/// A server the user typed in has no `operator` in the file: that is what "Added by you" reads.
library;

import 'network.dart' show EpicboxRelay;
import 'server_list.dart';
import 'settings_file/host_settings.dart';
import 'settings_file/settings_layout.dart' show hostOf;

/// The file's list of [kind] in [s].
ServerList serverListOf(HostSettings s, ServerKind kind) {
  if (kind == ServerKind.node) {
    final servers = s.nodeServers;
    return ServerList(
      entries: [for (final n in servers) n.url],
      removed: {for (final r in s.nodeRemoved) r.toLowerCase()},
      added: {
        for (final n in servers)
          if (n.operator == null) serverKeyOf(kind, n.url),
      },
    );
  }
  final servers = s.epicboxServers;
  return ServerList(
    entries: [for (final b in servers) b.label],
    removed: {for (final r in s.epicboxRemoved) serverKeyOf(kind, r)},
    added: {
      for (final b in servers)
        if (b.operator == null) serverKeyOf(kind, b.label),
    },
  );
}

/// The keys of [kind] and their values for [list], to write with `setAll`. An entry keeps the
/// operator the file gives it; a new one takes [operators] (by [serverKeyOf]), else the
/// shipped file's, else its host. One the user typed in ([ServerList.isAddedByUser]) has none.
Map<String, Object> serverListValues(
  HostSettings s,
  ServerKind kind,
  ServerList list, {
  Map<String, String> operators = const {},
}) {
  String? operatorOf(String value, String? current) {
    if (list.isAddedByUser(kind, value)) return null;
    final key = serverKeyOf(kind, value);
    return current ?? operators[key] ?? shippedOperators(kind)[key] ?? hostOf(value);
  }

  if (kind == ServerKind.node) {
    final now = {for (final n in s.nodeServers) serverKeyOf(kind, n.url): n};
    return {
      'node.servers': [
        for (final v in list.entries)
          NodeServer(url: now[serverKeyOf(kind, v)]?.url ?? v, operator: operatorOf(v, now[serverKeyOf(kind, v)]?.operator)),
      ],
      'node.removed': [...list.removed],
    };
  }
  final now = {for (final b in s.epicboxServers) serverKeyOf(kind, b.label): b};
  return {
    'epicbox.servers': [
      for (final v in list.entries)
        if (EpicboxRelay.parse(v) case final r?)
          EpicboxServer(host: r.host, port: r.port, operator: operatorOf(v, now[serverKeyOf(kind, v)]?.operator)),
    ],
    'epicbox.removed': [...list.removed],
  };
}

/// Who runs each server of the shipped file, by [serverKeyOf].
Map<String, String> shippedOperators(ServerKind kind) {
  final s = shippedHostSettings;
  return kind == ServerKind.node
      ? {for (final n in s.nodeServers) serverKeyOf(kind, n.url): ?n.operator}
      : {for (final b in s.epicboxServers) serverKeyOf(kind, b.label): ?b.operator};
}

/// The shipped file's servers of [kind], as list values: what "Restore removed servers" and
/// "Reset to defaults" bring back.
List<String> shippedServers(ServerKind kind) => kind == ServerKind.node
    ? [for (final n in shippedHostSettings.nodeServers) n.url]
    : [for (final b in shippedHostSettings.epicboxServers) b.label];

/// "Restore removed servers": every removal the user made is forgotten and [public] servers
/// come back, but the shipped file's own `removed` stay (servers the wallet no longer offers).
ServerList restoreRemoved(ServerKind kind, ServerList list, Iterable<String> public) {
  final shipped = serverListOf(shippedHostSettings, kind).removed;
  final back = list.restore(kind, [
    for (final v in public)
      if (!shipped.contains(serverKeyOf(kind, v))) v,
  ]);
  final removed = {
    for (final k in shipped)
      if (!back.has(kind, k)) k,
  };
  return ServerList(entries: back.entries, removed: removed, added: back.added);
}
