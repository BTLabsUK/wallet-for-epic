// SPDX-License-Identifier: Apache-2.0
/// Connection servers: the Epicbox servers where two wallets find each other when they connect
/// by the spoken method (Settings › Advanced › Experimental, under Pairing), shared by the phone
/// and the desktop. A set of up to [connectionServersLimit], any server of the Epicbox list;
/// absent in the store means the defaults, which LEPIC's built-in meeting relays are.
///
/// The set changes only where words meet. An invite by message, In person and everything after
/// the connection use the wallet's own Epicbox server, so a change here never moves a pairing.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;

import 'l10n.dart';
import 'models.dart' show Chain;
import 'network.dart' show EpicboxRelay;
import 'relay_directory.dart' show NodeHealthState;
import 'server_list.dart';
import 'tor_build.dart' show torBuilt;

/// The most servers that may be chosen: each costs a connection on both sides, and the joiner
/// waits for the slowest.
const int connectionServersLimit = 3;

/// The meeting servers every Epic Cash wallet knows on [chain], as Epicbox list values: LEPIC's
/// built-in relays. Empty where there are none (floonet and the local test network): the
/// setting is not shown there.
List<String> defaultConnectionServers(Chain chain) => chain == Chain.mainnet
    ? const ['epicbox.epiccash.com', 'epicbox.stackwallet.com', 'flooepicbox.btlabs.uk']
    : const [];

/// Whether the setting shows on [chain].
bool connectionServersShown(Chain chain) => defaultConnectionServers(chain).isNotEmpty;

/// The secret-store key of the set on [chain] in the phone's store; the desktop's is
/// `desk.pairingRelays.<chain>`. Absent = the defaults.
String pairingRelaysKey(Chain chain) => 'app.pairingRelays.${chain.name}';

/// A stored set (a JSON list of `host[:port]`): at most [connectionServersLimit] valid servers,
/// each once, or null (the defaults) when [raw] is missing, broken or holds none.
List<String>? decodeConnectionServers(String? raw) {
  if (raw == null) return null;
  try {
    final d = jsonDecode(raw);
    if (d is! List) return null;
    final out = <String>[];
    final keys = <String>{};
    for (final e in d) {
      final v = e is String ? typedRelayLabel(e) : null;
      // A local address chosen before it was refused: other wallets never met there.
      if (v != null && !isLocalRelay(v) && keys.add(serverKeyOf(ServerKind.relay, v)) && out.length < connectionServersLimit) out.add(v);
    }
    return out.isEmpty ? null : out;
  } on FormatException {
    return null;
  }
}

String encodeConnectionServers(List<String> hosts) => jsonEncode(hosts);

/// What a set stores: null (absent) when it is the defaults in their order, else the list.
List<String>? storableConnectionServers(Chain chain, List<String> chosen) {
  final defaults = defaultConnectionServers(chain);
  return listEquals(_keys(chosen), _keys(defaults)) ? null : chosen;
}

List<String> _keys(List<String> values) => [for (final v in values) serverKeyOf(ServerKind.relay, v)];

/// The set in force: the stored one, else the defaults.
List<String> connectionServersIn(Chain chain, List<String>? stored) => stored ?? defaultConnectionServers(chain);

/// What the state line under the setting says.
enum ConnectionServersLineKind { defaults, changed, down, allDown, epicboxOff, offline, nonDefault }

/// The state line of the setting: [kind] decides the sentence and [tone] its colour; [n], [down]
/// and [host] fill it in.
class ConnectionServersLine {
  const ConnectionServersLine(this.kind, {this.n = 0, this.down = 0, this.host = ''});

  final ConnectionServersLineKind kind;
  final int n;
  final int down;
  final String host;

  /// Needs attention (some servers down, none answers).
  bool get warn => kind == ConnectionServersLineKind.down;
  bool get risk => kind == ConnectionServersLineKind.allDown;

  /// The line is a plain fact in the dim colour (defaults, changed, paused).
  bool get dim =>
      kind == ConnectionServersLineKind.defaults ||
      kind == ConnectionServersLineKind.changed ||
      kind == ConnectionServersLineKind.epicboxOff ||
      kind == ConnectionServersLineKind.offline;

  String text(AppLocalizations l) => switch (kind) {
    ConnectionServersLineKind.defaults => l.connServersDefaults(n),
    ConnectionServersLineKind.changed => l.connServersChanged(n),
    ConnectionServersLineKind.down => l.connServersDown(down, n),
    ConnectionServersLineKind.allDown => l.connServersAllDown,
    ConnectionServersLineKind.epicboxOff => l.connServersEpicboxOff,
    ConnectionServersLineKind.offline => l.connServersOffline,
    ConnectionServersLineKind.nonDefault => l.connServersNonDefault(host),
  };
}

/// The state line for [chosen] against [defaults]. [health] says how each chosen server is
/// doing by its key ([serverKeyOf]); a server it does not know counts as answering. Offline and
/// Epicbox off come first: nothing is reached then, so health says nothing.
ConnectionServersLine connectionServersLine({
  required List<String> chosen,
  required List<String> defaults,
  required Map<String, NodeHealthState?> health,
  bool epicboxOff = false,
  bool offline = false,
}) {
  if (offline) return const ConnectionServersLine(ConnectionServersLineKind.offline);
  if (epicboxOff) return const ConnectionServersLine(ConnectionServersLineKind.epicboxOff);
  final n = chosen.length;
  final down = [
    for (final v in chosen)
      if (health[serverKeyOf(ServerKind.relay, v)] == NodeHealthState.down) v,
  ];
  if (down.isNotEmpty && down.length == n) return ConnectionServersLine(ConnectionServersLineKind.allDown, n: n, down: n);
  if (down.isNotEmpty) return ConnectionServersLine(ConnectionServersLineKind.down, n: n, down: down.length);
  final defaultKeys = {for (final d in defaults) serverKeyOf(ServerKind.relay, d)};
  final other = chosen.where((v) => !defaultKeys.contains(serverKeyOf(ServerKind.relay, v))).firstOrNull;
  if (other != null) return ConnectionServersLine(ConnectionServersLineKind.nonDefault, n: n, host: EpicboxRelay.parse(other)?.label ?? other);
  return ConnectionServersLine(
    sameServerSet(ServerKind.relay, chosen, defaults) ? ConnectionServersLineKind.defaults : ConnectionServersLineKind.changed,
    n: n,
  );
}

/// The info sheet's text: the paragraphs in order, the Tor sentence only in a build with Tor.
String connectionServersInfo(AppLocalizations l) => [
  l.connServersInfo1,
  l.connServersInfo2,
  l.connServersInfo3,
  l.connServersInfo4,
  if (torBuilt) l.connServersInfoTor,
].join('\n\n');
