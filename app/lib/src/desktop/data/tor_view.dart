// SPDX-License-Identifier: Apache-2.0
/// The one Tor switch as the desktop shows it: its [TorState] from the open wallet's status,
/// and the words every place uses for it (status card, Settings › Privacy, Send, Receive).
library;

import '../../l10n.dart' show AppLocalizations;
import '../../tor_routes.dart';
import 'models.dart';
import 'state.dart';

export '../../tor_routes.dart';

/// The switch's state now. On with tor not started yet reads as starting.
TorState deskTorState(DeskState st) => torStateOf(st.settings, st.status);

TorState torStateOf(DeskSettings settings, ServiceStatus? status) {
  if (!settings.tor) return TorState.off;
  if (status == null) return TorState.starting;
  return switch (status.tor) {
    ServiceHealth.down => TorState.failed,
    ServiceHealth.off => TorState.starting,
    ServiceHealth.checking when !status.torCanSend => TorState.starting,
    _ => TorState.on,
  };
}

/// The one Tor switch's label (Settings › Privacy) and the status rail's Tor row: the label
/// alone, with [torNetworkHint] behind its info icon or hover card.
String torNetworkLabel(AppLocalizations l) => l.deskTorNetworkLabel;

/// What the switch does and what Tor is, in plain words. It never lists what does not go
/// over Tor (the rule); a send that skips Tor says so on that send.
String torNetworkHint(AppLocalizations l) => l.deskTorNetworkHint;

/// The state word: Off, Starting…, On, Not connected.
String torWord(AppLocalizations l, TorState s) => switch (s) {
  TorState.off => l.deskTorOff,
  TorState.starting => l.deskTorStarting,
  TorState.on => l.deskTorOn,
  TorState.failed => l.deskTorNotConnected,
};

/// What goes over Tor, from [torCovered]: one short sentence. The switch never lists what
/// does not (the rule); a send that skips Tor says so on that send.
String torCoverageText(AppLocalizations l) => l.deskTorCoverage;

/// A node on this computer: never over Tor ([torSkipsLocalNode]).
bool isLocalNodeUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'localhost' || host == '127.0.0.1' || host == '::1' || host == '[::1]';
}

/// The node's lines about Tor, for the status card and Settings › Node: over Tor (and a plain
/// http node is not encrypted past the exit), or waiting for it. Empty while the node is not
/// covered, or is on this computer.
List<String> torNodeLines(AppLocalizations l, String url, TorState tor) {
  if (torSkipsLocalNode && isLocalNodeUrl(url)) return const [];
  return switch (torWay(TorRoute.node, tor)) {
    TorWay.overTor => [l.deskTorNodeOver, if (Uri.tryParse(url)?.scheme == 'http') l.deskTorNodeNotEncrypted],
    TorWay.wait || TorWay.blocked => [l.deskTorNodeWaits],
    _ => const [],
  };
}
