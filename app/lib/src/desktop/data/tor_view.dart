/// The one Tor switch as the desktop shows it: its [TorState] from the open wallet's status,
/// and the words every place uses for it (status card, Settings › Privacy, Send, Receive).
library;

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

/// The state word: Off, Starting…, On, Not connected.
String torWord(TorState s) => switch (s) {
  TorState.off => 'Off',
  TorState.starting => 'Starting…',
  TorState.on => 'On',
  TorState.failed => 'Not connected',
};

/// Names of the routes, as lists read them.
String _routeName(TorRoute r) => switch (r) {
  TorRoute.epicbox => 'Epicbox',
  TorRoute.onionDirect => 'Tor addresses',
  TorRoute.httpDirect => 'Direct to http(s)',
  TorRoute.node => 'the node',
  TorRoute.appHttp => 'status and update checks',
  TorRoute.httpListener => 'HTTP receiving',
  TorRoute.push => 'push',
};

String _list(List<String> names) => switch (names.length) {
  0 => '',
  1 => names.first,
  _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
};

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// What goes over Tor and what does not, from [torCovered]: one or two short sentences.
String torCoverageText() {
  const shown = [TorRoute.epicbox, TorRoute.node, TorRoute.appHttp];
  final over = [for (final r in shown) if (torCovered.contains(r)) _routeName(r), _routeName(TorRoute.onionDirect)];
  final not = [for (final r in shown) if (!torCovered.contains(r)) _routeName(r), _routeName(TorRoute.httpDirect)];
  return 'Over Tor: ${_list(over)}. Not over Tor: ${_list(not)}.';
}

/// What waits while Tor starts or is not connected, e.g. "Epicbox and Tor addresses".
String torWaitingText() => _cap(_list([for (final r in TorRoute.values) if (torCovered.contains(r)) _routeName(r), _routeName(TorRoute.onionDirect)]));

/// A node on this computer: never over Tor ([torSkipsLocalNode]).
bool isLocalNodeUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'localhost' || host == '127.0.0.1' || host == '::1' || host == '[::1]';
}

/// The node's lines about Tor, for the status card and Settings › Node: over Tor (and a plain
/// http node is not encrypted past the exit), or waiting for it. Empty while the node is not
/// covered, or is on this computer.
List<String> torNodeLines(String url, TorState tor) {
  if (torSkipsLocalNode && isLocalNodeUrl(url)) return const [];
  return switch (torWay(TorRoute.node, tor)) {
    TorWay.overTor => ['Over Tor', if (Uri.tryParse(url)?.scheme == 'http') 'Not encrypted past Tor'],
    TorWay.wait || TorWay.blocked => const ['Waits until Tor is connected.'],
    _ => const [],
  };
}
