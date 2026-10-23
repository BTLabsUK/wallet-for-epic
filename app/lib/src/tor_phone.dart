/// The one Tor switch on the phone: its [TorState] from [PhoneTorState] (the switch is the
/// per-wallet `receiving`), and the app's own requests following it.
library;

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
/// open: the app's requests and the price follow the switch. tor's SOCKS port joins once LEPIC
/// reports it (E-12).
void phoneTorFollow(PhoneTorState s) => TorNet.follow(phoneTorState(s));
