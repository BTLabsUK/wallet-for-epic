/// The network mode at run time (Settings › Advanced): what may reach the network now, for the
/// screens (status lines, disabled buttons, the Tor switch) and for the code that makes the
/// calls. Pure Dart, also on the web.
///
/// - Standard: today's app; the Tor switch is the user's.
/// - Tor only: the Tor switch is on and stays on; nothing goes on the clearnet (a node on this
///   computer may stay direct). Covered routes wait for tor and never fall back.
/// - Offline: no network call at all. The wallet shows what it last saw.
///
/// Any stored mode other than Tor only and Offline runs as Standard ([netModeOf]).
library;

import 'dart:async';

import 'advanced.dart';
import 'tor_routes.dart';

/// Why network actions (Send over Epicbox/Direct, Recheck balance, starting a listener, checking a node) can't run now.
enum NetBlock {
  /// They can run.
  none,

  /// The Offline mode: nothing reaches the network until the mode changes.
  offline,

  /// Tor only, and tor is starting or failed: they wait for tor and never go direct.
  waitingForTor,
}

/// Why network actions can't run in [mode] with the Tor switch [tor] (`tor_view.dart`'s
/// `torStateOf` on the desktop, `phoneTorState` on the phone).
NetBlock netBlockFor(NetworkMode mode, TorState tor) => switch (mode) {
  NetworkMode.offline => NetBlock.offline,
  NetworkMode.torOnly when tor != TorState.on => NetBlock.waitingForTor,
  _ => NetBlock.none,
};

/// The mode the runtime follows for a stored one: Tor only and Offline as they are, anything
/// else (an older build's choice included) as Standard.
NetworkMode netModeOf(NetworkMode? mode) => switch (mode) {
  NetworkMode.torOnly => NetworkMode.torOnly,
  NetworkMode.offline => NetworkMode.offline,
  _ => NetworkMode.standard,
};

/// The transaction file method in [mode]. LEPIC asks the node for its tip before it creates a
/// send file, signs a received one or finalizes one (and finalizing also posts), so the whole
/// file method needs the node: Offline blocks it with [NetBlock.offline].
NetBlock fileBlockFor(NetworkMode mode) =>
    netModeOf(mode) == NetworkMode.offline ? NetBlock.offline : NetBlock.none;

/// The Tor switch can't be turned off: Tor only keeps it on.
bool torSwitchLocked(NetworkMode mode) => netModeOf(mode) == NetworkMode.torOnly;

/// The Tor switch does nothing: Offline starts no tor.
bool torSwitchDisabled(NetworkMode mode) => netModeOf(mode) == NetworkMode.offline;

/// Push notifications register with a relay over the clearnet: off in Tor only and Offline.
bool pushAllowed(NetworkMode mode) => netModeOf(mode) == NetworkMode.standard;

/// A network action refused by the mode: [what] is for the log, [mode] says why (Offline, or
/// Tor only refusing a clearnet connection).
class NetBlocked implements Exception {
  const NetBlocked(this.mode, this.what);

  final NetworkMode mode;
  final String what;

  @override
  String toString() => 'NetBlocked(${mode.name}): $what';
}

/// The current mode for code without a Riverpod ref (the app's own HTTP, the wallet adapters).
/// The phone's settings and the desktop's store set it at launch, before any request, and on
/// every change; [changes] lets a long-lived owner (the desktop wallet) resume or stop.
abstract final class NetGate {
  static NetworkMode _mode = NetworkMode.standard;
  static final StreamController<NetworkMode> _changes = StreamController.broadcast(sync: true);

  static NetworkMode get mode => _mode;

  static bool get offline => _mode == NetworkMode.offline;

  static bool get torOnly => _mode == NetworkMode.torOnly;

  /// Every change of [mode], after it is set.
  static Stream<NetworkMode> get changes => _changes.stream;

  static void set(NetworkMode? mode) {
    final next = netModeOf(mode);
    if (next == _mode) return;
    _mode = next;
    _changes.add(next);
  }

  /// Throws [NetBlocked] in Offline: for every call that would reach the network.
  static void check(String what) {
    if (offline) throw NetBlocked(NetworkMode.offline, what);
  }
}
