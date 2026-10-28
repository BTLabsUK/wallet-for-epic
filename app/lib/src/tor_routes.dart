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

  /// A Direct send to an http(s) address.
  httpDirect,

  /// The node the wallet reads the chain from and posts to.
  node,

  /// The app's own requests: status.btlabs.uk, the price, the update check, support reports
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

  /// Not offered while Tor is on (the clearnet HTTP listener, push), in Tor only (also a
  /// Direct http(s) send) or in Offline (everything).
  off,
}

/// The routes the switch carries through Tor: Epicbox and the node in LEPIC, the
/// app's own requests through tor's SOCKS port with names resolved by tor ([TorNet]). A node
/// on this computer stays direct ([torSkipsLocalNode]).
const Set<TorRoute> torCovered = {TorRoute.epicbox, TorRoute.node, TorRoute.appHttp};

/// Off while Tor is on: they would show this computer's address.
const Set<TorRoute> torStops = {TorRoute.httpListener};

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
/// - Offline: nothing goes ([TorWay.off]); a node on this computer is the caller's business.
/// - Tor only: never the clearnet. A Direct http(s) send, the HTTP listener and push are
///   [TorWay.off]; with the switch not on yet (it is being forced on) covered routes and
///   onions [TorWay.wait].
/// - Any other mode is Standard: [torWay].
TorWay torWayIn(TorRoute route, TorState state, NetworkMode mode) {
  switch (mode) {
    case NetworkMode.offline:
      return TorWay.off;
    case NetworkMode.torOnly:
      if (route == TorRoute.httpDirect) return TorWay.off;
      final way = torWay(route, state == TorState.off ? TorState.starting : state);
      return way == TorWay.clearnet ? TorWay.off : way;
    default:
      return torWay(route, state);
  }
}

/// [way] lets the connection go now.
bool torGoes(TorWay way) =>
    way == TorWay.clearnet || way == TorWay.overTor;
