// SPDX-License-Identifier: Apache-2.0
/// Connection servers: the Epicbox servers where two wallets find each other when they connect
/// by the spoken method (Settings › Advanced › Experimental, under Pairing), shared by the phone
/// and the desktop. A set of up to [connectionServersLimit], any server of the Epicbox list:
/// `pairing.servers` of the settings file; the defaults are the shipped file's.
///
/// The set changes only where words meet. An invite by message, In person and everything after
/// the connection use the wallet's own Epicbox server, so a change here never moves a pairing.
library;

import 'l10n.dart';
import 'models.dart' show Chain;
import 'network.dart' show EpicboxRelay;
import 'relay_directory.dart' show NodeHealthState;
import 'server_list.dart';
import 'settings_file/host_settings.dart' show shippedHostSettings;
import 'settings_file/settings_providers.dart' show writeHostSettings;
import 'tor_build.dart' show torBuilt;

/// The most servers that may be chosen: each costs a connection on both sides, and the joiner
/// waits for the slowest.
const int connectionServersLimit = 3;

/// The meeting servers the shipped settings name (of the chain the app runs on), as Epicbox
/// list values: "Reset to defaults" brings them back. Empty where there are none: the setting
/// is not shown there.
List<String> defaultConnectionServers(Chain chain) => shippedHostSettings.pairingServers;

/// Whether the setting shows on [chain].
bool connectionServersShown(Chain chain) => defaultConnectionServers(chain).isNotEmpty;

/// [hosts] as the file keeps them: at most [connectionServersLimit] valid servers, each once,
/// none on this device's network (other wallets never meet there).
List<String> cleanConnectionServers(Iterable<String> hosts) {
  final out = <String>[];
  final keys = <String>{};
  for (final e in hosts) {
    final v = typedRelayLabel(e);
    if (v != null && !isLocalRelay(v) && keys.add(serverKeyOf(ServerKind.relay, v)) && out.length < connectionServersLimit) out.add(v);
  }
  return out;
}

/// Writes [chosen] as `pairing.servers`.
Future<void> saveConnectionServers(List<String> chosen) => writeHostSettings({'pairing.servers': cleanConnectionServers(chosen)});

/// The set in force: [stored] (the file's), else the defaults.
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
