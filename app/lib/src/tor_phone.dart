/// The phone's Tor in the words of the one Tor switch ([TorState]); main's copy replaces this
/// file at merge (the mapping is the Tor lead's, so the swap changes nothing).
library;

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
