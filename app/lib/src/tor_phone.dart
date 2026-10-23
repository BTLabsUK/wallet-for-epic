/// The phone's Tor in the words of the one Tor switch ([TorState]); main's copy replaces this
/// file at merge.
library;

import 'phone_tor.dart';
import 'tor_routes.dart';

/// [s] as the switch's state: starting is starting, connected or ready is on, failed is
/// failed, and off or unavailable is off.
TorState phoneTorState(PhoneTorState s) => switch (s.phase) {
  PhoneTorPhase.starting => TorState.starting,
  PhoneTorPhase.connected || PhoneTorPhase.ready => TorState.on,
  PhoneTorPhase.failed => TorState.failed,
  PhoneTorPhase.off || PhoneTorPhase.unavailable => TorState.off,
};
