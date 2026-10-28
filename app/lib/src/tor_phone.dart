/// The one Tor switch on the phone: its [TorState] from [PhoneTorState] (the switch is the
/// per-wallet `receiving`), and the app's own requests following it.
library;

import 'btlabs_onions.dart';
import 'net/tor_net.dart';
import 'net/tor_switch.dart';
import 'phone_tor.dart';
import 'tor_build.dart';
import 'tor_routes.dart';

/// Off while the switch is off (tor started only for one send stays a send's own) or this
/// build has no tor; on once tor is connected.
TorState phoneTorState(PhoneTorState s) {
  if (!s.receiving || s.phase == PhoneTorPhase.unavailable) return TorState.off;
  return switch (s.phase) {
    PhoneTorPhase.connected || PhoneTorPhase.ready => TorState.on,
    PhoneTorPhase.failed => TorState.failed,
    PhoneTorPhase.off || PhoneTorPhase.starting || PhoneTorPhase.unavailable => TorState.starting,
  };
}

/// For a `ref.listen(phoneTorProvider, …)` on a screen that is always up while a wallet is
/// open: the app's requests and the price follow the switch, through tor's SOCKS port once tor
/// has connected, and wait while it has not. Before the wallet's switch is read
/// (locked, or opening) a switch that was on, saved at launch or the last one followed, keeps
/// them waiting: never direct for a moment.
void phoneTorFollow(PhoneTorState s) {
  if (!s.settled) {
    if (TorSwitch.on) TorNet.waitForTor();
    return;
  }
  TorNet.follow(phoneTorState(s), proxy: phoneTorSocks(s));
}

/// At launch, before any request: the phone's saved Tor switch on holds the app's own
/// requests waiting for tor (and the price on BT Labs' copy) until the wallet is open and tor
/// has connected; [phoneTorFollow] takes over from there. Never in the build without Tor.
void phoneTorAtLaunch({required bool savedOn}) {
  if (savedOn && torBuilt) TorNet.follow(TorState.starting);
}

/// tor's SOCKS proxy while it can carry requests, else null (requests then wait).
SocksProxy? phoneTorSocks(PhoneTorState s) {
  final port = s.socksPort;
  return s.canSend && port != null ? SocksProxy('127.0.0.1', port) : null;
}

/// BT Labs' onion for a host from [onions] (the signed list in use), else the built-in table.
OnionLookup onionLookupOf(OnionDirectory onions) => (host, port) {
  final e = onions.onionFor(host, port);
  return e == null ? torBuiltInOnion(host, port) : (onion: e.onion, port: e.onionPort, tls: e.tls);
};
