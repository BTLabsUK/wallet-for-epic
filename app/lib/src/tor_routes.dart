/// The one Tor switch: which connections go over Tor while it is on, which wait for it, and
/// which stay on the clearnet. Every screen and the wallet adapters ask [torWay]; nothing
/// decides a route on its own, so what the switch covers changes here and nowhere else.
library;

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

  /// Push notifications (phone).
  push,
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

  /// Not offered while Tor is on (the clearnet HTTP listener, push).
  off,
}

/// The routes the switch carries through Tor in this build. The node and the app's own
/// requests join once LEPIC's node client and the app's HTTP can use tor's SOCKS port with
/// remote DNS (LEPIC E-12); until then they stay on the clearnet and the switch's text says so.
const Set<TorRoute> torCovered = {TorRoute.epicbox};

/// Off while Tor is on: they would show this computer's address.
const Set<TorRoute> torStops = {TorRoute.httpListener, TorRoute.push};

/// A node on this computer (local or built-in) never goes over Tor: there is nothing to hide.
const bool torSkipsLocalNode = true;

/// How [route] goes while the switch is [state].
TorWay torWay(TorRoute route, TorState state) {
  if (route == TorRoute.onionDirect) {
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

/// [way] lets the connection go now.
bool torGoes(TorWay way) =>
    way == TorWay.clearnet || way == TorWay.overTor;
