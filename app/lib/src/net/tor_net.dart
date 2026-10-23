/// How the app's own requests leave this computer, set from the Tor switch: directly, through
/// the wallet's tor, or not at all while Tor is on but not connected. `http_io.dart`,
/// `ws_probe_io.dart` and the node probes ask it for every client they make, so no request
/// picks its own way. Whether these requests are covered at all is `tor_routes.dart`'s
/// [TorRoute.appHttp]; the adapters set the mode from that.
library;

import 'dart:io';

import '../tor_routes.dart';
import 'http_types.dart';
import 'socks.dart';
import 'tor_switch.dart';

export 'socks.dart' show OnionLookup, OnionTarget, SocksProxy;

enum TorNetMode {
  /// Straight from this computer, names looked up by its resolver.
  direct,

  /// Through tor's SOCKS port, names resolved by tor.
  tor,

  /// Tor is on but not connected: every request fails at once, none goes direct.
  waiting,
}

abstract final class TorNet {
  static TorNetMode _mode = TorNetMode.direct;
  static SocksProxy? _proxy;
  static OnionLookup? _onions;

  static TorNetMode get mode => _mode;

  /// The onion of a BT Labs server, from the signed list; null goes back to [builtInOnions].
  static set onions(OnionLookup? lookup) => _onions = lookup;

  static void useDirect() {
    _mode = TorNetMode.direct;
    _proxy = null;
  }

  static void useTor(SocksProxy proxy) {
    _mode = TorNetMode.tor;
    _proxy = proxy;
  }

  static void waitForTor() {
    _mode = TorNetMode.waiting;
    _proxy = null;
  }

  /// Follows the Tor switch for the app's own requests ([TorRoute.appHttp]): through tor at
  /// [proxy] once it is connected, none while it starts or failed, direct while it is off or
  /// does not cover them. Over Tor without a known [proxy] waits.
  static void follow(TorState state, {SocksProxy? proxy}) {
    TorSwitch.on = state != TorState.off;
    switch (torWay(TorRoute.appHttp, state)) {
      case TorWay.overTor:
        proxy == null ? waitForTor() : useTor(proxy);
      case TorWay.wait || TorWay.blocked || TorWay.needsTor || TorWay.off:
        waitForTor();
      case TorWay.clearnet:
        useDirect();
    }
  }

  /// Makes [client] go the current way. Throws [NetError] while Tor is not connected, before
  /// anything is opened. [loopback] clients (a node on this computer) always go direct.
  static void configure(HttpClient client, {bool loopback = false}) {
    if (loopback) return;
    switch (_mode) {
      case TorNetMode.direct:
        return;
      case TorNetMode.waiting:
        throw const NetError('Tor not connected');
      case TorNetMode.tor:
        // No environment proxy either: the factory is the only way out.
        client
          ..findProxy = ((_) => 'DIRECT')
          ..connectionFactory = socksConnectionFactory(_proxy!, onions: _onions ?? builtInOnions);
    }
  }
}

/// BT Labs' onions as built in (the signed btlabs.json list replaces them, `TorNet.onions`).
/// Tor exits cannot reach btlabs.uk's own address, so over Tor these hosts are reached only
/// at their onions ([socksConnectionFactory] refuses a btlabs.uk host without one).
OnionTarget? builtInOnions(String host, int port) => switch ((host.toLowerCase(), port)) {
  ('node.btlabs.uk', 443) => (onion: '5drwoknehnzducfsxsl45dazaw3cwcmpx3ycamynagmcpv6aalrbrtqd.onion', port: 443, tls: true),
  ('support.btlabs.uk', 443) => (onion: 'lowiz5jnnu5vyyqc5guig3zag3k7azorbjfkcszfqwdxh3yarfei66yd.onion', port: 443, tls: true),
  ('flooepicbox.btlabs.uk', 443) => (onion: 'j2xf5rizkow5jtrdf6edotk5qam4kohavip23dqeuih5bq4yqisbz5ad.onion', port: 443, tls: true),
  // The status site's onion is plain HTTP on port 80 (the onion is the encryption).
  ('status.btlabs.uk', _) => (onion: 't6furoapbsowxp3hvmjwp223zenmauwldfv2noddih7bfuuavwyvaqad.onion', port: 80, tls: false),
  _ => null,
};

/// [url]'s host is this computer.
bool isLoopbackUrl(Uri url) {
  final h = url.host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '[::1]';
}
