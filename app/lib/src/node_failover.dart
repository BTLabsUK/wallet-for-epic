/// Node failover, the rules both apps share (Settings › Advanced › Node failover, on by
/// default): when the node in use has not answered for [nodeFailoverAfter], the wallet moves
/// to the next working node in the user's list for this session only. The chosen node stays
/// saved; the next start opens on it, and a node the user picks becomes the chosen one.
///
/// Never in Offline, never away from a node on this computer, never while Tor is still
/// starting (the node waits for Tor, it is not gone), and in Tor only only to a node reachable
/// over Tor. Epicbox has no failover: another relay is another address.
///
/// Pure Dart: the phone (`node_failover_phone.dart`) and the desktop
/// (`desktop/data/desk_failover.dart`) watch their own status and call these.
library;

import 'advanced.dart';
import 'network_gate.dart';
import 'server_list.dart';
import 'tor_routes.dart';

/// How long the node in use must have stopped answering before the wallet moves on.
const Duration nodeFailoverAfter = Duration(seconds: 30);

/// How long a node the wallet may move to has to answer a tip request.
const Duration nodeFailoverProbe = Duration(seconds: 15);

/// What is known of a node in the list before it is asked.
enum FailoverHealth {
  /// The monitor (phone) or the last check (desktop) saw it answer at the tip.
  healthy,

  /// Not known, or answering but not at its best: asked after the healthy ones.
  unknown,

  /// Seen down: skipped.
  down,
}

/// Why the wallet may not move off its node now; null when it may.
enum FailoverHold {
  /// The switch on the Advanced page is off.
  off,

  /// Offline mode: no network at all.
  offline,

  /// The node is on this computer: the user's own, never left.
  localNode,

  /// The node waits for Tor (starting or failed): it is not gone.
  waitingForTor,

  /// A payment is being sent or posted: the move waits for it.
  busy,
}

/// Why the wallet may not move off [nodeUrl] now, or null.
FailoverHold? failoverHold({
  required bool on,
  required NetworkMode mode,
  required TorState tor,
  required String nodeUrl,
  bool busy = false,
}) {
  if (!on) return FailoverHold.off;
  if (netModeOf(mode) == NetworkMode.offline) return FailoverHold.offline;
  if (isLocalNodeUrl(nodeUrl)) return FailoverHold.localNode;
  final torWanted = netModeOf(mode) == NetworkMode.torOnly || tor != TorState.off;
  if (torWanted && tor != TorState.on) return FailoverHold.waitingForTor;
  if (busy) return FailoverHold.busy;
  return null;
}

/// A node on this computer: `localhost`, `127.x`, `::1`.
bool isLocalNodeUrl(String url) {
  final host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
  return host == 'localhost' || host == '::1' || host == '[::1]' || host.startsWith('127.');
}

/// Whether [url] can be reached over Tor: the node route goes through Tor while the switch is
/// on ([torCovered]), or BT Labs lists an onion for it ([hasOnion]).
bool failoverOverTor(String url, {required bool Function(String host, int port) hasOnion}) {
  if (torCovered.contains(TorRoute.node)) return true;
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return false;
  return hasOnion(u.host, u.hasPort ? u.port : (u.scheme == 'http' ? 80 : 443));
}

/// The nodes to try, in order: of [entries] (the user's list), the healthy ones first, then
/// those not known, each in list order; never [current] or [chosen], never one seen down, never
/// one on this computer. In [NetworkMode.torOnly] only those [overTor] says Tor reaches.
List<String> failoverCandidates({
  required List<String> entries,
  required String current,
  required String chosen,
  required FailoverHealth Function(String url) health,
  NetworkMode mode = NetworkMode.standard,
  bool Function(String url)? overTor,
}) {
  final torOnly = netModeOf(mode) == NetworkMode.torOnly;
  final healthy = <String>[];
  final unknown = <String>[];
  final seen = <String>{};
  for (final e in entries) {
    if (sameServer(ServerKind.node, e, current) || sameServer(ServerKind.node, e, chosen)) continue;
    if (!seen.add(serverKeyOf(ServerKind.node, e)) || isLocalNodeUrl(e)) continue;
    if (torOnly && !(overTor?.call(e) ?? false)) continue;
    switch (health(e)) {
      case FailoverHealth.healthy:
        healthy.add(e);
      case FailoverHealth.unknown:
        unknown.add(e);
      case FailoverHealth.down:
        break;
    }
  }
  return [...healthy, ...unknown];
}

/// A node the wallet moved to for this session, instead of the [chosen] one.
class NodeFailover {
  const NodeFailover({required this.chosen, required this.inUse});

  /// The node the user chose: saved, used at the next start.
  final String chosen;

  /// The node in use now.
  final String inUse;

  @override
  bool operator ==(Object other) => other is NodeFailover && other.chosen == chosen && other.inUse == inUse;

  @override
  int get hashCode => Object.hash(chosen, inUse);
}
