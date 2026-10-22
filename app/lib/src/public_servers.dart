/// The public mainnet nodes and Epicbox relays built into the app, and their merge with the
/// live lists from `status.btlabs.uk` ([NodeDirectory], [RelayDirectory]).
///
/// The built-in lists are what the monitor listed in October 2026, so the pickers are complete
/// offline or when the monitor is down. The monitor can add servers; it cannot remove or reorder
/// the built-in ones. Nothing here picks a server: the user does (D4).
library;

import 'network.dart';
import 'relay_directory.dart';

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

/// Public mainnet nodes, the default first. All answer `/v2/foreign` over https.
const List<PublicNode> builtInNodes = [
  PublicNode(url: 'https://node.btlabs.uk', operator: 'BT Labs'),
  PublicNode(url: 'https://node.epicnet.us:3413', operator: 'EpicNet'),
  PublicNode(url: 'https://node.epiccash.com:3413', operator: 'Epic Cash'),
  PublicNode(url: 'https://epic.stackwallet.com:3413', operator: 'Cypher Stack'),
  PublicNode(url: 'https://epic-node.iniaku.my.id', operator: 'Iniaku pool'),
];

/// Public mainnet Epicbox relays, in the desktop's order: [defaultEpicboxHost] first (D-13).
const List<PublicRelay> builtInRelays = [
  PublicRelay(relay: EpicboxRelay(host: defaultEpicboxHost), operator: 'Epic Cash'),
  PublicRelay(relay: EpicboxRelay(host: 'epicbox.stackwallet.com'), operator: 'Cypher Stack'),
  PublicRelay(relay: EpicboxRelay(host: 'epicbox.epicnet.us'), operator: 'EpicNet'),
  PublicRelay(relay: EpicboxRelay(host: 'epicbox.iniaku.my.id'), operator: 'Iniaku pool'),
];

/// `host:port` of a node address, the port filled in from the scheme; null for junk.
String? nodeKey(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return null;
  return '${u.host.toLowerCase()}:${u.port}';
}

/// [builtIn] in its order with the monitor's view of each, then nodes only the monitor lists,
/// in its order. One row per `host:port`.
List<PublicNode> mergePublicNodes(List<NodeStatus>? listed, {List<PublicNode> builtIn = builtInNodes}) {
  final byKey = <String, NodeStatus>{};
  for (final s in listed ?? const <NodeStatus>[]) {
    final key = nodeKey(s.url);
    if (key != null) byKey.putIfAbsent(key, () => s);
  }
  final out = <PublicNode>[];
  final seen = <String>{};
  for (final n in builtIn) {
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
List<PublicRelay> mergePublicRelays(List<RelayStatus>? listed, {List<PublicRelay> builtIn = builtInRelays}) {
  final byRelay = <EpicboxRelay, RelayStatus>{};
  for (final s in listed ?? const <RelayStatus>[]) {
    byRelay.putIfAbsent(s.relay, () => s);
  }
  final out = <PublicRelay>[];
  final seen = <EpicboxRelay>{};
  for (final r in builtIn) {
    if (!seen.add(r.relay)) continue;
    out.add(PublicRelay(relay: r.relay, operator: r.operator, status: byRelay[r.relay]));
  }
  for (final MapEntry(key: relay, value: s) in byRelay.entries) {
    if (!seen.add(relay)) continue;
    out.add(PublicRelay(relay: relay, operator: s.operator ?? s.label ?? relay.host, status: s));
  }
  return out;
}
