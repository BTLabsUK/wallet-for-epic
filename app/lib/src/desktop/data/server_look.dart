// SPDX-License-Identifier: Apache-2.0
/// How a server looks wherever the desktop names one: the status site's icon for it, the phone's
/// rule ([serverIconFor]): the server's own icon, else the one the site holds for another server
/// of the same operator, else none (the tile then shows initials on a tint).
library;

import '../../network.dart' show EpicboxRelay;
import '../../server_list.dart' show serverIconFor;
import 'models.dart';

/// A server's operator as the status site lists it (else the wallet's own name) and the icon to
/// draw for it.
typedef ServerLook = ({String? operator, ServerIcon? icon});

/// Every (operator, icon) the monitor listed, nodes and relays alike.
Iterable<ServerLook> knownServerLooks(Iterable<NodeServer> nodes, Iterable<EpicboxServer> boxes) sync* {
  for (final n in nodes) {
    yield (operator: n.listedAs ?? n.operator, icon: n.icon);
  }
  for (final b in boxes) {
    yield (operator: b.listedAs ?? b.operator, icon: b.icon);
  }
}

/// The look of node [n]: its own list entry (the same url) when [n] carries none of the site's
/// data, then the operator fallback.
ServerLook nodeLook(NodeServer? n, Iterable<NodeServer> nodes, Iterable<EpicboxServer> boxes) {
  var node = n;
  if (node != null && node.icon == null && node.listedAs == null) {
    final listed = nodes.where((o) => o.url == node!.url).firstOrNull;
    if (listed != null) node = listed;
  }
  final operator = node?.listedAs ?? node?.operator;
  return (operator: operator, icon: serverIconFor(node?.icon, operator, knownServerLooks(nodes, boxes)));
}

/// The look of relay [r] (null: none known by that name), as [nodeLook].
ServerLook relayLook(EpicboxServer? r, Iterable<NodeServer> nodes, Iterable<EpicboxServer> boxes) {
  var box = r;
  if (box != null && box.icon == null && box.listedAs == null) {
    final listed = boxes.where((o) => o.domain == box!.domain && o.port == box.port).firstOrNull;
    if (listed != null) box = listed;
  }
  final operator = box?.listedAs ?? box?.operator;
  return (operator: operator, icon: serverIconFor(box?.icon, operator, knownServerLooks(nodes, boxes)));
}

/// The look of the relay written [relay] (`host` or `host:port`, as a link or an offer names it).
ServerLook relayLookOf(String relay, Iterable<NodeServer> nodes, Iterable<EpicboxServer> boxes) {
  final parsed = EpicboxRelay.parse(relay);
  final host = parsed?.host ?? relay;
  final port = parsed?.port ?? 443;
  final found = boxes.where((b) => b.domain == host && b.port == port).firstOrNull;
  return relayLook(found ?? EpicboxServer(domain: host, port: port), nodes, boxes);
}
