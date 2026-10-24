/// Whether the network mode lets a network action run now: one answer for every screen that
/// sends, rechecks, starts a listener or checks a node, so they all say the same thing.
library;

import 'advanced.dart';
import 'tor_routes.dart';

/// Why network actions (Send over Epicbox or Direct, Recheck balance, starting a listener,
/// checking a node) can't run now.
enum NetBlock {
  /// Nothing stops them.
  none,

  /// Offline mode: no network at all.
  offline,

  /// Tor only, and Tor is not connected yet (or failed): nothing goes until it is.
  waitingForTor,
}

/// What [mode] and the Tor [tor] state allow now.
NetBlock netBlockFor(NetworkMode mode, TorState tor) => switch (mode) {
  NetworkMode.offline => NetBlock.offline,
  NetworkMode.torOnly when tor != TorState.on => NetBlock.waitingForTor,
  _ => NetBlock.none,
};
