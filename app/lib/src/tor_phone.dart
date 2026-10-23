/// The one Tor switch on the phone: its [TorState] from [PhoneTorState] (the switch is the
/// per-wallet `receiving`), and the app's own requests following it.
library;

import 'btlabs_onions.dart';
import 'net/tor_net.dart';
import 'phone_tor.dart';
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
/// has connected (LEPIC E-12), and wait while it has not.
void phoneTorFollow(PhoneTorState s) => TorNet.follow(phoneTorState(s), proxy: phoneTorSocks(s));

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
