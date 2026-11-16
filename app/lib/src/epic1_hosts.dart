// SPDX-License-Identifier: Apache-2.0
/// Which epic1 relays need "Send through this server?" (ui-spec: "not in your server list").
///
/// LEPIC marks a host [Epic1Host.inRelayList] only when it is the relay the wallet is on now;
/// the app's server list has more. A host is known here when LEPIC says so, when the app lists
/// it ([isKnownRelay]: the Epicbox list, the shipped relays, the default), or when the user
/// pressed "Use server" for it before: `[epicbox] accepted` of `settings.toml`, matched by
/// `host:port` without case, 443 when a port is not named.
library;

import 'epic1.dart' show Epic1Host;
import 'known_relays.dart';
import 'network.dart' show EpicboxRelay;
import 'settings_file/host_settings.dart';

/// The key of the accepted relays in `settings.toml`.
const String epicboxAcceptedKey = 'epicbox.accepted';

/// Writes `settings.toml` values: `writeHostSettings` once the file is open
/// (`settings_providers.dart`). Without an open file (tests) only [hostSettings] change.
Future<void> Function(Map<String, Object> values) writeEpic1Accepted = (values) async =>
    hostSettings = hostSettings.withValues(values);

/// [host] as the relay the lists hold.
EpicboxRelay _relayOf(Epic1Host host) => EpicboxRelay(host: host.host.toLowerCase(), port: host.port);

/// The relays accepted in [s].
List<EpicboxRelay> acceptedRelaysIn(HostSettings s) => [
  for (final text in s.value(epicboxAcceptedKey) as List<String>) ?EpicboxRelay.parse(text),
];

/// Whether [host] goes without the question: LEPIC knows it, the app lists it, or it was
/// accepted. [extra]: more relays the caller knows (the session's list).
bool epic1HostKnown(Epic1Host host, {Iterable<EpicboxRelay> extra = const []}) =>
    host.inRelayList || isKnownRelay(_relayOf(host), extra: [...extra, ...acceptedRelaysIn(hostSettings)]);

/// The first of [hosts] that needs the question, or null.
Epic1Host? epic1UnknownHost(Iterable<Epic1Host> hosts) {
  for (final h in hosts) {
    if (!epic1HostKnown(h)) return h;
  }
  return null;
}

/// Keeps "Use server" for [hosts]: the next link or code through them goes without the
/// question. Hosts already known are not written.
Future<void> rememberEpic1Hosts(Iterable<Epic1Host> hosts) async {
  final s = hostSettings;
  final add = <String>[
    for (final h in hosts)
      if (!epic1HostKnown(h)) _relayOf(h).label,
  ];
  if (add.isEmpty) return;
  final now = s.value(epicboxAcceptedKey) as List<String>;
  await writeEpic1Accepted({
    epicboxAcceptedKey: [...now, ...{...add}],
  });
}
