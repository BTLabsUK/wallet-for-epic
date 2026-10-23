/// Whether the Tor switch is on, whatever tor is doing, for code that also runs on the web
/// (`tor_net.dart` is `dart:io` only). `TorNet.follow` sets it.
library;

abstract final class TorSwitch {
  /// On: the price comes from BT Labs' copy, never CoinGecko directly.
  static bool on = false;
}
