/// An Epicbox relay this network blocks (report gwuouzfy, 2026-10-25): a filter on the way
/// (a provider's DNS filter, a router's blocklist) sends the relay's name to its own server,
/// which ends every TLS handshake with an alert, "received fatal alert: CloseNotify" from one,
/// InternalError from another. The real relay is up and the monitor says so; LEPIC retries
/// forever. Ordinary outages look different (refused, reset, timed out, an HTTP error, a
/// dropped websocket), so only an alert during the handshake counts, and only twice in a row.
library;

import 'network.dart';
import 'public_servers.dart';

/// How many failed connections in a row must be refused handshakes before the relay reads as
/// blocked: LEPIC's second attempt follows about a second after the first.
const int relayBlockedAfter = 2;

/// [reason], a listener's text for one failed connection, is the relay's address answering the
/// TLS handshake with an alert: rustls' "received fatal alert: …" under LEPIC's "could not
/// connect to the relay". A dropped connection after the handshake, a refused or timed-out
/// one, a certificate this device refuses and an HTTP answer do not match.
bool refusedHandshake(String? reason) {
  if (reason == null) return false;
  final text = reason.toLowerCase();
  return text.contains('could not connect to the relay') && text.contains('received fatal alert');
}

/// Counts a listener's failed connections; [blocked] once [relayBlockedAfter] in a row were
/// refused handshakes. Any other failure, or a connection, starts the count again.
class RelayBlockWatch {
  int _refused = 0;

  bool get blocked => _refused >= relayBlockedAfter;

  /// One failed connection, with the listener's [reason]; returns [blocked].
  bool failed(String? reason) {
    _refused = refusedHandshake(reason) ? _refused + 1 : 0;
    return blocked;
  }

  void reset() => _refused = 0;
}

/// The relay to offer instead of [blocked], from [public] in its order: the first other one
/// the monitor last saw up, else the first it did not list; never one it saw down, nor one in
/// [skip] (relays this network blocked before). Null when none is left.
EpicboxRelay? relayInstead(
  EpicboxRelay blocked,
  List<PublicRelay> public, {
  Set<EpicboxRelay> skip = const {},
}) {
  bool same(EpicboxRelay a, EpicboxRelay b) =>
      a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;
  final others = [
    for (final r in public)
      if (!same(r.relay, blocked) && !skip.any((s) => same(s, r.relay))) r,
  ];
  return others.where((r) => r.status?.healthy == true).firstOrNull?.relay ??
      others.where((r) => r.status == null).firstOrNull?.relay;
}
