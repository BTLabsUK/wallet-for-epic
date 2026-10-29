// SPDX-License-Identifier: Apache-2.0
/// What tells a relay's refused TLS handshake, in plain Dart: the wallet core imports it, and
/// the core runs without Flutter (relay_block.dart, which also reads the public relay list,
/// re-exports it).
library;

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
