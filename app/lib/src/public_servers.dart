// SPDX-License-Identifier: Apache-2.0
/// The public nodes and Epicbox relays of the default copy of `settings.toml`
/// (`docs/settings-file.md`), and their merge with the live lists from the status site
/// ([NodeDirectory], [RelayDirectory]): the health, icons and operator names of the servers.
/// The merge never adds a server to the user's list. Nothing here picks a server: the user does.
library;

import 'network.dart';
import 'relay_directory.dart';
import 'settings_file/host_settings.dart';
import 'settings_file/settings_layout.dart' show hostOf;

/// A public node: its address as the wallet stores it, and who runs it.
class PublicNode {
  const PublicNode({required this.url, required this.operator, this.status});

  final String url;
  final String operator;

  /// The monitor's last look, or null when it did not list this node.
  final NodeStatus? status;
}

/// A public Epicbox relay and who runs it.
class PublicRelay {
  const PublicRelay({required this.relay, required this.operator, this.status});

  final EpicboxRelay relay;
  final String operator;

  /// The monitor's last look, or null when it did not list this relay.
  final RelayStatus? status;
}

/// The public nodes of the default copy (of the chain the app runs on), in its order, each
/// with its operator from `[operators]` of `app-config.toml`.
List<PublicNode> get builtInNodes => [
  for (final n in shippedHostSettings.nodeServers) PublicNode(url: n.url, operator: n.operator ?? hostOf(n.url)),
];

/// The public Epicbox relays of the default copy, in its order.
List<PublicRelay> get builtInRelays => [
  for (final b in shippedHostSettings.epicboxServers)
    PublicRelay(relay: EpicboxRelay(host: b.host, port: b.port), operator: b.operator ?? b.host),
];

/// `host:port` of a node address, the port filled in from the scheme; null for junk.
String? nodeKey(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return null;
  return '${u.host.toLowerCase()}:${u.port}';
}

/// [builtIn] in its order with the monitor's view of each, then nodes only the monitor lists,
/// in its order. One row per `host:port`.
List<PublicNode> mergePublicNodes(List<NodeStatus>? listed, {List<PublicNode>? builtIn}) {
  final byKey = <String, NodeStatus>{};
  for (final s in listed ?? const <NodeStatus>[]) {
    final key = nodeKey(s.url);
    if (key != null) byKey.putIfAbsent(key, () => s);
  }
  final out = <PublicNode>[];
  final seen = <String>{};
  for (final n in builtIn ?? builtInNodes) {
    final key = nodeKey(n.url) ?? n.url;
    if (!seen.add(key)) continue;
    out.add(PublicNode(url: n.url, operator: n.operator, status: byKey[key]));
  }
  for (final MapEntry(:key, value: s) in byKey.entries) {
    if (!seen.add(key)) continue;
    out.add(PublicNode(url: s.url, operator: s.operator ?? Uri.parse(s.url).host, status: s));
  }
  return out;
}

/// [builtIn] in its order with the monitor's view of each, then relays only the monitor lists,
/// in its order. One row per host and port.
List<PublicRelay> mergePublicRelays(List<RelayStatus>? listed, {List<PublicRelay>? builtIn}) {
  final byRelay = <EpicboxRelay, RelayStatus>{};
  for (final s in listed ?? const <RelayStatus>[]) {
    byRelay.putIfAbsent(s.relay, () => s);
  }
  final out = <PublicRelay>[];
  final seen = <EpicboxRelay>{};
  for (final r in builtIn ?? builtInRelays) {
    if (!seen.add(r.relay)) continue;
    out.add(PublicRelay(relay: r.relay, operator: r.operator, status: byRelay[r.relay]));
  }
  for (final MapEntry(key: relay, value: s) in byRelay.entries) {
    if (!seen.add(relay)) continue;
    out.add(PublicRelay(relay: relay, operator: s.operator ?? s.label ?? relay.host, status: s));
  }
  return out;
}
