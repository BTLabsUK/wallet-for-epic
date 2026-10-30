// SPDX-License-Identifier: Apache-2.0
/// The one Tor switch: which connections go over Tor while it is on, which wait for it, and
/// which stay on the clearnet. Every screen and the wallet adapters ask [torWay] (or
/// [torWayIn] with the network mode of Settings › Advanced); nothing decides a route on its
/// own, so what the switch covers changes here and nowhere else.
library;

import 'advanced.dart';
import 'tor_build.dart';

/// What the Tor switch is doing now, shown the same everywhere (status card, Send, Receive,
/// Settings › Privacy).
enum TorState {
  /// The switch is off: every connection uses this computer's own internet address.
  off,

  /// The switch is on and tor is connecting to the Tor network.
  starting,

  /// Tor is connected: sends to onions work and the covered connections go through it.
  on,

  /// Tor stopped or could not connect. Covered connections wait; nothing falls back.
  failed,
}

/// The connections the app makes.
enum TorRoute {
  /// The wallet's connection to its Epicbox relay: receiving and every Epicbox send.
  epicbox,

  /// A Direct send to an onion address. Needs Tor whatever the switch says.
  onionDirect,

  /// A Direct send to an `https://` address, or to `http://` on this computer.
  httpDirect,

  /// A Direct send to a plain `http://` address on another device. Whoever answers on the way
  /// can take the payment, so it never goes through a Tor exit: off while the switch is on.
  plainHttpDirect,

  /// The node the wallet reads the chain from and posts to.
  node,

  /// The app's own requests: the status site, the price, the update check, support reports
  /// and the relay probes.
  appHttp,

  /// The clearnet HTTP listener (desktop Direct receiving without Tor).
  httpListener,
}

/// How a [TorRoute] goes right now.
enum TorWay {
  /// Straight from this computer's own address.
  clearnet,

  /// Through Tor.
  overTor,

  /// Covered by Tor, which is starting: it waits, it never goes on the clearnet meanwhile.
  wait,

  /// Covered by Tor, which failed: nothing goes until Retry or Tor off.
  blocked,

  /// An onion address with the switch off: Tor must be turned on first.
  needsTor,

  /// Not offered while Tor is on (the clearnet HTTP listener, a plain `http://` send), in
  /// Node only (everything but the node) or in Kill switch (everything).
  off,
}

/// The routes the switch carries through Tor: Epicbox, the node and Direct https sends in
/// LEPIC (tor resolves the names), the app's own requests through tor's SOCKS port with names
/// resolved by tor ([TorNet]). A node or wallet on this computer stays direct
/// ([torSkipsLocalNode]). With the switch on none of them ever goes on the clearnet: while tor
/// starts they wait, when it failed (or its files are missing) they are blocked.
const Set<TorRoute> torCovered = {TorRoute.epicbox, TorRoute.node, TorRoute.appHttp, TorRoute.httpDirect};

/// Off while Tor is on: the clearnet listener would show this computer's address, and a plain
/// `http://` send through a Tor exit could be answered by the exit instead of the recipient.
const Set<TorRoute> torStops = {TorRoute.httpListener, TorRoute.plainHttpDirect};

/// A node on this computer (local or built-in) never goes over Tor: there is nothing to hide.
const bool torSkipsLocalNode = true;

/// How [route] goes while the switch is [state]. In the build without Tor ([torBuilt]) an
/// onion is never offered ([TorWay.off]): nothing can turn Tor on for it.
TorWay torWay(TorRoute route, TorState state) {
  if (route == TorRoute.onionDirect) {
    if (!torBuilt) return TorWay.off;
    return switch (state) {
      TorState.off => TorWay.needsTor,
      TorState.starting => TorWay.wait,
      TorState.on => TorWay.overTor,
      TorState.failed => TorWay.blocked,
    };
  }
  if (torStops.contains(route)) {
    return state == TorState.off ? TorWay.clearnet : TorWay.off;
  }
  if (!torCovered.contains(route)) return TorWay.clearnet;
  return switch (state) {
    TorState.off => TorWay.clearnet,
    TorState.starting => TorWay.wait,
    TorState.on => TorWay.overTor,
    TorState.failed => TorWay.blocked,
  };
}

/// How [route] goes in the network [mode] while the switch is [state].
///
/// - Kill switch: nothing goes ([TorWay.off]).
/// - Node only: the node follows the switch as in Normal; nothing else goes ([TorWay.off]).
/// - Tor only: never the clearnet. The HTTP listener and a plain `http://` send are
///   [TorWay.off]; with the switch not on yet (it is being forced on) covered routes, Direct
///   https and onions [TorWay.wait]. For sends this is what Normal does with the switch on;
///   Tor only differs in keeping the switch on and in the app's own requests.
/// - Any other mode is Standard: [torWay].
TorWay torWayIn(TorRoute route, TorState state, NetworkMode mode) {
  switch (mode) {
    case NetworkMode.killSwitch:
      return TorWay.off;
    case NetworkMode.nodeOnly:
      return route == TorRoute.node ? torWay(route, state) : TorWay.off;
    case NetworkMode.torOnly:
      final way = torWay(route, state == TorState.off ? TorState.starting : state);
      return way == TorWay.clearnet ? TorWay.off : way;
    default:
      return torWay(route, state);
  }
}

/// [way] lets the connection go now.
bool torGoes(TorWay way) =>
    way == TorWay.clearnet || way == TorWay.overTor;
