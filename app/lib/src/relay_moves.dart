// SPDX-License-Identifier: Apache-2.0
/// The rules for a paired contact's relay move (`ContactView.requestedRelay`):
///
/// - a domain-backed contact ([isDomainBacked]) asks: the request shows once (a dialog on the
///   desktop, a sheet on the phone), then waits on the contact page. Accept adds the relay to
///   the Epicbox servers when it is not listed and moves the contact; Refuse moves nothing and
///   tells the contact nothing, and that move is never asked again;
/// - any other contact is moved without a word, and the contact page and the pre-send line say
///   "moved here" for [relayMoveKeptFor];
/// - a relay that is not a public DNS name ([isPublicRelayHost]) is never followed, from
///   anyone: the contact page says so in a quiet line.
///
/// `PairingApi.settleRelayMoves` applies them. Before these rules a move went only to a relay
/// in the server list, and a refused one was remembered in memory only: a move stored then
/// settles by these rules at the first open, and there is nothing to carry over.
library;

import 'domain_backed.dart';
import 'history/relay_move_book.dart';
import 'models.dart';
import 'network.dart' show EpicboxRelay;

export 'history/relay_move_book.dart';

/// [relay] (`host` or `host:port`) as the server list writes it, or as given when it does not
/// parse.
String relayLabelOf(String relay) => EpicboxRelay.parse(relay)?.label ?? relay;

/// Whether [relay] (`host` or `host:port`) names a host by a public DNS name: not an address
/// literal, not `localhost`, no local or onion suffix, and at least one dot.
bool isPublicRelayHost(String relay) {
  final host = EpicboxRelay.parse(relay)?.host;
  if (host == null || !host.contains('.') || host.startsWith('.') || host.endsWith('.') || host.contains('..')) return false;
  // Every label all digits (or hex) reads as an IPv4 address to a resolver. IPv6 never parses.
  if (RegExp(r'^(0x[0-9a-f]+|[0-9]+)(\.(0x[0-9a-f]+|[0-9]+))*$').hasMatch(host)) return false;
  // A top label of digits is no DNS name either.
  if (RegExp(r'\.[0-9]+$').hasMatch(host)) return false;
  if (host == 'localhost') return false;
  const local = ['.localhost', '.local', '.lan', '.internal', '.home.arpa', '.onion'];
  return !local.any(host.endsWith);
}

/// Where [p]'s asked-for move stands, by [book].
RelayMoveState relayMoveStateOf(PairingRecord p, RelayMoveBook book) {
  final relay = p.requestedRelay;
  if (relay == null || p.ended) return RelayMoveState.none;
  if (!isPublicRelayHost(relay)) return RelayMoveState.notPublic;
  if (!isDomainBacked(p.domainFacts)) return RelayMoveState.none;
  final key = relayMoveKey(p.id, relayLabelOf(relay));
  if (book.refused.contains(key)) return RelayMoveState.refused;
  if (book.shown.contains(key)) return RelayMoveState.open;
  return RelayMoveState.ask;
}

/// Whether [p]'s asked-for move is made at once, without asking.
bool movesSilently(PairingRecord p) {
  final relay = p.requestedRelay;
  return relay != null && !p.ended && isPublicRelayHost(relay) && !isDomainBacked(p.domainFacts);
}

/// When this wallet last moved [p] to its relay now, within [relayMoveKeptFor] of [now].
DateTime? movedAtOf(PairingRecord p, RelayMoveBook book, DateTime now) {
  final here = relayLabelOf(p.homeRelay);
  for (final m in book.moved.reversed) {
    if (m.id != p.id) continue;
    if (relayLabelOf(m.to) != here) return null;
    final at = DateTime.fromMillisecondsSinceEpoch(m.at);
    return now.difference(at) < relayMoveKeptFor ? at : null;
  }
  return null;
}

/// [p] with its move state and "moved here" date from [book].
PairingRecord withRelayMoves(PairingRecord p, RelayMoveBook book, DateTime now) {
  final state = relayMoveStateOf(p, book);
  final at = movedAtOf(p, book, now);
  return state == p.relayMove && at == p.movedAt ? p : p.copyWith(relayMove: state, movedAt: at);
}

/// The first of [records] whose move asks now ([RelayMoveState.ask]): the dialog or sheet shows it.
PairingRecord? relayMoveToAsk(Iterable<PairingRecord> records) => records.where((r) => r.relayMove == RelayMoveState.ask).firstOrNull;
