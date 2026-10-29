// SPDX-License-Identifier: Apache-2.0
/// The Node and Epicbox lists ([ServerList]) as `settings.toml` holds them
/// (`docs/settings-file.md`): `[node] servers` and `[epicbox] servers`, plain lists whose first
/// entry is the one in use. The phone's and the desktop's list controllers read and write them
/// here; nothing else keeps a list. The status site never adds to them.
///
/// Who runs a server is not in the file: `[operators]` of `app-config.toml` by its domain, else
/// the status site's name for it, else none. A server outside the default copy that no
/// operator covers reads "Added by you".
library;

import 'network.dart' show EpicboxRelay;
import 'server_list.dart';
import 'settings_file/host_settings.dart';
import 'settings_file/settings_layout.dart' show hostOf;

/// The file's list of [kind] in [s].
ServerList serverListOf(HostSettings s, ServerKind kind) {
  final entries = kind == ServerKind.node ? s.nodeUrls : [for (final b in s.epicboxServers) b.label];
  final builtIn = {for (final v in shippedServers(kind)) serverKeyOf(kind, v)};
  return ServerList(
    entries: entries,
    added: {
      for (final v in entries)
        if (!builtIn.contains(serverKeyOf(kind, v)) && s.config.operatorOf(_hostOf(kind, v)) == null) serverKeyOf(kind, v),
    },
  );
}

String _hostOf(ServerKind kind, String value) =>
    kind == ServerKind.node ? hostOf(value) : (EpicboxRelay.parse(value)?.host ?? value);

/// The key of [kind] and its value for [list], to write with `setAll`.
Map<String, Object> serverListValues(ServerKind kind, ServerList list) => kind == ServerKind.node
    ? {'node.servers': [...list.entries]}
    : {
        'epicbox.servers': [
          for (final v in list.entries)
            if (EpicboxRelay.parse(v) case final r?) r.label,
        ],
      };

/// [values] with [value] first: the server picked to be in use moves to the top of its list
/// (it joins the list when it was not in it).
List<String> withFirst(ServerKind kind, List<String> values, String value) {
  final k = serverKeyOf(kind, value);
  return [value, for (final v in values) if (serverKeyOf(kind, v) != k) v];
}

/// The keys to write so that [node] and [relay] are in use: each moves to the top of its list.
/// An empty one is no server (its list is empty): that list is not written.
Map<String, Object> useServerValues(HostSettings s, {String? node, String? relay}) => {
  if (node != null && node.trim().isNotEmpty) 'node.servers': withFirst(ServerKind.node, s.nodeUrls, node),
  if (relay != null && relay.trim().isNotEmpty)
    'epicbox.servers': withFirst(ServerKind.relay, [for (final b in s.epicboxServers) b.label], EpicboxRelay.parse(relay)?.label ?? relay),
};

/// Who runs [value] of [kind]: `[operators]` of `app-config.toml` by its domain, else
/// [listed] (the status site's name), else null.
String? operatorFor(ServerKind kind, String value, {String? listed}) =>
    appConfig.operatorOf(_hostOf(kind, value)) ?? listed;

/// The default copy's servers of [kind], as list values: what "Reset to defaults" brings back.
List<String> shippedServers(ServerKind kind) => kind == ServerKind.node
    ? [...shippedHostSettings.nodeUrls]
    : [for (final b in shippedHostSettings.epicboxServers) b.label];
