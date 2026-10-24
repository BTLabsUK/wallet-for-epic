/// The network mode at run time (Settings › Advanced): what may reach the network now, for the
/// screens (status lines, disabled buttons, the Tor switch) and for the code that makes the
/// calls. Pure Dart, also on the web.
///
/// - Standard: today's app; the Tor switch is the user's.
/// - Tor only: the Tor switch is on and stays on; nothing goes on the clearnet (a node on this
///   computer may stay direct). Covered routes wait for tor and never fall back.
/// - Offline: nothing beyond this computer and the local network (`net/local_address.dart`).
///   With a local node in use (the built-in one, any loopback or LAN node) the wallet still
///   talks to it: refresh, transaction files, posting. Direct sends go to local addresses only;
///   Epicbox, Tor, public nodes and the app's own requests stay off.
///
/// Any stored mode other than Tor only and Offline runs as Standard ([netModeOf]).
library;

import 'dart:async';

import 'advanced.dart';
import 'tor_routes.dart';

export 'net/local_address.dart' show isLocalAddressUrl;

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
/// `torStateOf` on the desktop, `phoneTorState` on the phone). [localNode]: the action reaches
/// only the node (Recheck balance, posting) or local addresses (a Direct send, which refuses a
/// non-local one itself), and the node in use is local ([isLocalAddressUrl]): Offline lets it run.
NetBlock netBlockFor(NetworkMode mode, TorState tor, {bool localNode = false}) => switch (mode) {
  NetworkMode.offline => localNode ? NetBlock.none : NetBlock.offline,
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
/// file method needs the node: Offline blocks it with [NetBlock.offline] unless the node in use
/// is [localNode].
NetBlock fileBlockFor(NetworkMode mode, {bool localNode = false}) =>
    netModeOf(mode) == NetworkMode.offline && !localNode ? NetBlock.offline : NetBlock.none;

/// The Tor switch can't be turned off: Tor only keeps it on.
bool torSwitchLocked(NetworkMode mode) => netModeOf(mode) == NetworkMode.torOnly;

/// The Tor switch does nothing: Offline starts no tor.
bool torSwitchDisabled(NetworkMode mode) => netModeOf(mode) == NetworkMode.offline;

/// Push notifications register with a relay over the clearnet: off in Tor only and Offline.
bool pushAllowed(NetworkMode mode) => netModeOf(mode) == NetworkMode.standard;

/// A network action refused by the mode: [what] is for the log, [mode] says why (Offline, or
/// Tor only refusing a clearnet connection). [notLocal]: Offline refused a Direct send to an
/// address that is not local ("Offline: only local addresses.").
class NetBlocked implements Exception {
  const NetBlocked(this.mode, this.what, {this.notLocal = false});

  final NetworkMode mode;
  final String what;
  final bool notLocal;

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

  /// Throws [NetBlocked] in Offline: for every call that would reach the network. [local]: the
  /// call reaches only this computer or the local network (a local node), which Offline allows.
  static void check(String what, {bool local = false}) {
    if (offline && !local) throw NetBlocked(NetworkMode.offline, what);
  }
}
