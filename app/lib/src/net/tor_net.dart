// SPDX-License-Identifier: Apache-2.0
/// How the app's own requests leave this computer, set from the Tor switch: directly, through
/// the wallet's tor, or not at all while Tor is on but not connected. `http_io.dart`,
/// `ws_probe_io.dart` and the node probes ask it for every client they make, so no request
/// picks its own way. Whether these requests are covered at all is `tor_routes.dart`'s
/// [TorRoute.appHttp]; the adapters set the mode from that.
library;

import 'dart:async';
import 'dart:io';

import '../advanced.dart';
import '../network_gate.dart';
import '../settings_file/host_settings.dart';
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

/// [NetError.message] of a request refused in Offline.
const String offlineError = 'Offline mode';

abstract final class TorNet {
  static TorNetMode _mode = TorNetMode.direct;
  static SocksProxy? _proxy;
  static OnionLookup? _onions;

  /// In Tor only nothing goes direct, even before the switch, forced on, is followed.
  static TorNetMode get mode =>
      NetGate.torOnly && _mode == TorNetMode.direct ? TorNetMode.waiting : _mode;

  /// How long a request held by [untilConnected] waits for tor before it fails. Zero refuses
  /// at once (tests); the phone sets its hold at launch (`main.dart`).
  static Duration hold = Duration.zero;

  /// Completed when the mode leaves [TorNetMode.waiting].
  static Completer<void>? _connected;

  /// The onion of a server, from the signed list in use; null goes back to [torBuiltInOnion].
  static set onions(OnionLookup? lookup) => _onions = lookup;

  static void useDirect() {
    _mode = TorNetMode.direct;
    TorSwitch.carried = false;
    _proxy = null;
    _release();
  }

  static void useTor(SocksProxy proxy) {
    _mode = TorNetMode.tor;
    TorSwitch.carried = true;
    _proxy = proxy;
    _release();
  }

  static void _release() {
    _connected?.complete();
    _connected = null;
  }

  /// While Tor is on but not connected, holds a request until tor connects (or the switch is
  /// turned off), for at most [hold]; [configure] then refuses one still waiting. Nothing is
  /// opened meanwhile.
  static Future<void> untilConnected() async {
    if (NetGate.offline) return;
    if (mode != TorNetMode.waiting || hold <= Duration.zero) return;
    final connected = _connected ??= Completer<void>();
    try {
      await connected.future.timeout(hold);
    } on TimeoutException {
      // Still waiting: configure refuses it.
    }
  }

  static void waitForTor() {
    _mode = TorNetMode.waiting;
    TorSwitch.carried = false;
    _proxy = null;
  }

  /// Follows the Tor switch for the app's own requests ([TorRoute.appHttp]): through tor at
  /// [proxy] once it is connected, none while it starts or failed, direct while it is off or
  /// does not cover them. Over Tor without a known [proxy] waits.
  ///
  /// In Tor only a switch not on yet waits ([torWayIn]); Offline is checked by [configure]
  /// at every request, so following the switch meanwhile changes nothing that goes out.
  static void follow(TorState state, {SocksProxy? proxy}) {
    TorSwitch.on = state != TorState.off || NetGate.torOnly;
    final mode = NetGate.offline ? NetworkMode.standard : NetGate.mode;
    switch (torWayIn(TorRoute.appHttp, state, mode)) {
      case TorWay.overTor:
        proxy == null ? waitForTor() : useTor(proxy);
      case TorWay.wait || TorWay.blocked || TorWay.needsTor || TorWay.off:
        waitForTor();
      case TorWay.clearnet:
        useDirect();
    }
  }

  /// Makes [client] go the current way. Throws [NetError] while Tor is not connected or the
  /// network mode is Offline, before anything is opened. [loopback] clients (a node on this
  /// computer) always go direct; [local] ones (a literal LAN address, `local_address.dart`) go
  /// direct in Offline, which allows them.
  static void configure(HttpClient client, {bool loopback = false, bool local = false}) {
    if (loopback) return;
    if (NetGate.offline) {
      if (local) return;
      throw const NetError(offlineError);
    }
    switch (mode) {
      case TorNetMode.direct:
        return;
      case TorNetMode.waiting:
        throw const NetError('Tor not connected');
      case TorNetMode.tor:
        // No environment proxy either: the factory is the only way out.
        client
          ..findProxy = ((_) => 'DIRECT')
          ..connectionFactory = socksConnectionFactory(_proxy!, onions: _onions ?? torBuiltInOnion, pinnedPlain: torBuiltInOnion);
    }
  }
}

/// The onion of [host]:[port] from the settings file (`[tor] onions`; the signed btlabs.json
/// list replaces those under the onion-only domains, `TorNet.onions`). Hosts under
/// `[tor] onion_only_domains` refuse Tor exits, so over Tor they are reached only at their
/// onions ([socksConnectionFactory] refuses one without).
OnionTarget? torBuiltInOnion(String host, int port) {
  if (!hostSettingsLoaded) return null;
  final h = host.toLowerCase();
  for (final r in hostSettings.torOnions) {
    if (r.host.toLowerCase() == h && r.port == port) return (onion: r.onion, port: r.onionPort, tls: r.tls);
  }
  return null;
}

/// [url]'s host is this computer.
bool isLoopbackUrl(Uri url) {
  final h = url.host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '[::1]';
}
