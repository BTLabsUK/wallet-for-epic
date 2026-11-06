// SPDX-License-Identifier: Apache-2.0
/// Which Epicbox relays the app knows, so Send can warn about an address whose relay it has
/// never heard of (a mistyped domain, linux-14). A warning only: any relay may be typed.
library;

import 'network.dart';
import 'public_servers.dart';
import 'settings_file/host_settings.dart';

/// [relay] is one the app lists: the settings file's relays (the shipped ones too), the one in
/// use and the default, or one of [extra] (the monitor's list, the user's servers, the
/// wallet's own relay). Host names compare without case; the port too.
bool isKnownRelay(EpicboxRelay relay, {Iterable<EpicboxRelay> extra = const []}) {
  bool same(EpicboxRelay r) => r.host.toLowerCase() == relay.host.toLowerCase() && r.port == relay.port;
  final s = hostSettings;
  return builtInRelays.any((r) => same(r.relay)) ||
      s.epicboxServers.any((b) => same(EpicboxRelay(host: b.host, port: b.port))) ||
      [s.epicboxUse, s.epicboxDefault].map(EpicboxRelay.parse).any((r) => r != null && same(r)) ||
      extra.any(same);
}

/// The relay of an `<key>@<relay>[:port]` address, or null when it has none.
EpicboxRelay? recipientRelay(String address) {
  final at = address.lastIndexOf('@');
  return at < 0 ? null : EpicboxRelay.parse(address.substring(at + 1));
}
