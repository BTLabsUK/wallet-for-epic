// SPDX-License-Identifier: Apache-2.0
/// Whether the Tor switch is on, whatever tor is doing, and whether tor carries the app's
/// requests now, for code that also runs on the web (`tor_net.dart` is `dart:io` only).
/// `TorNet` sets both.
library;

abstract final class TorSwitch {
  /// On: the price comes from BT Labs' copy, never CoinGecko directly.
  static bool on = false;

  /// Tor is connected and the app's requests go through it.
  static bool carried = false;
}
