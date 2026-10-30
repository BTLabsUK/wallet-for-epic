// SPDX-License-Identifier: Apache-2.0
/// What a typed, pasted or scanned recipient is: an Epicbox address, an onion (Tor) or a
/// wallet URL (HTTP). Pure Dart, shared by the phone and desktop screens.
library;

import 'wallet_service.dart' show onionAddressFormat, onionHost;

/// Where a payment goes.
enum RecipientKind { epicbox, tor, http }

class Recipient {
  const Recipient(this.kind, this.address);

  final RecipientKind kind;

  /// `<address>@<relay>` for epicbox, `<56 characters>.onion` for Tor, the full URL for HTTP.
  final String address;
}

/// Reads a bare epicbox address, `epicbox://<address>`, an onion address in any of its forms,
/// or an `http(s)://` wallet URL from typed, pasted or scanned text. Removes whitespace, which
/// QR codes and chat apps sometimes add. An onion (with or without `.onion`, with
/// `http://`, a port, a trailing slash, in upper case) comes back as `<56 characters>.onion`
/// in lower case, the one form the app shows. Does not validate; see [checkRecipient].
Recipient parseRecipient(String text) {
  final clean = text.replaceAll(RegExp(r'\s'), '');
  final lower = clean.toLowerCase();
  // Before the URL check: `http://<onion>` goes over Tor, not HTTP.
  if (onionAddressFormat(clean)) {
    return Recipient(RecipientKind.tor, onionHost(clean));
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Recipient(RecipientKind.http, clean);
  }
  const scheme = 'epicbox://';
  final address = lower.startsWith(scheme)
      ? clean.substring(scheme.length)
      : clean;
  return Recipient(RecipientKind.epicbox, address);
}

final RegExp _epicboxShape = RegExp(
  r'^[1-9A-HJ-NP-Za-km-z]{40,}(?:@[^@\s]+)?$',
);
final RegExp _ipv4 = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');

/// Whether [to] has the shape of its kind at all: an Epicbox key of 40 or more base58
/// characters with an optional `@host`, a URL with a host, or an onion. Text that has none
/// (a name, a stray word) is no kind, and never moves Send's method.
bool recipientShaped(Recipient to) => switch (to.kind) {
  RecipientKind.epicbox => _epicboxShape.hasMatch(to.address),
  RecipientKind.http => Uri.tryParse(to.address)?.host.isNotEmpty ?? false,
  RecipientKind.tor => true,
};

/// Whether [url] is a whole HTTP(S) address to send to: a host that is an IPv4 address,
/// `localhost` or a name with a dot, no user part, and a port from 1 to 65535 when it has one.
/// While `http://192.168.` is still being typed it is not.
bool httpAddressComplete(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  if (host.isEmpty || host.endsWith('.onion') || uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) return false;
  // Digits and dots are an IPv4 address only with all four parts; a name needs a dot with
  // something after it.
  if (RegExp(r'^[\d.]+$').hasMatch(host)) return _ipv4.hasMatch(host);
  return host == 'localhost' || (host.contains('.') && !host.endsWith('.'));
}

/// Plain `http` to another device: the transaction travels unencrypted, so Send asks first,
/// and LEPIC refuses it without that consent. `localhost`, 127.0.0.0/8 and ::1 are this device.
bool plainHttpToOtherDevice(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme.toLowerCase() != 'http' || uri.host.isEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  final loopback =
      host == 'localhost' ||
      host == '::1' ||
      host == '[::1]' ||
      (_ipv4.hasMatch(host) && host.startsWith('127.'));
  return !loopback;
}

const String _base32 = 'abcdefghijklmnopqrstuvwxyz234567';

/// The payment proof address of a v3 onion: its ed25519 public key in 64 hex characters, the
/// first 32 of the 35 bytes the 56 base32 characters spell. Null for anything else. Proofs are
/// signed with the key of the receiver's onion, so a send to a contact with a known onion can
/// ask the receiver for one whatever way it travels.
String? proofAddressOfOnion(String onion) {
  if (!onionAddressFormat(onion)) return null;
  final chars = onionHost(onion).substring(0, 56);
  final bits = StringBuffer();
  for (final c in chars.split('')) {
    final v = _base32.indexOf(c);
    if (v < 0) return null;
    bits.write(v.toRadixString(2).padLeft(5, '0'));
  }
  final all = bits.toString();
  final hex = StringBuffer();
  for (var i = 0; i < 32; i++) {
    final byte = int.parse(all.substring(i * 8, i * 8 + 8), radix: 2);
    hex.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return hex.toString();
}

/// A route that does not carry the slate in the clear, for a plain `http` wallet URL whose
/// contact also has one: Epicbox first, then the onion, then the same wallet over `https`.
class SaferRoute {
  const SaferRoute(this.name, this.recipient);

  /// The contact's name.
  final String name;
  final Recipient recipient;
}

/// A contact's name and addresses, as the phone's and the desktop's address books both give
/// them.
typedef ContactWays = ({String name, String? epicbox, String? http, String? tor});

/// The [SaferRoute] for sending to [url], or null when [url] is not plain `http` to another
/// device or no contact with that wallet URL has another way in.
SaferRoute? saferRouteFor(String url, Iterable<ContactWays> contacts) {
  if (!plainHttpToOtherDevice(url)) return null;
  final want = _sameUrl(url);
  for (final c in contacts) {
    final http = c.http;
    if (http == null || _sameUrl(http) != want) continue;
    final epicbox = c.epicbox;
    if (epicbox != null) {
      return SaferRoute(c.name, Recipient(RecipientKind.epicbox, epicbox));
    }
    final tor = c.tor;
    if (tor != null && onionAddressFormat(tor)) {
      return SaferRoute(c.name, Recipient(RecipientKind.tor, onionHost(tor)));
    }
    if (http.trim().toLowerCase().startsWith('https://')) {
      return SaferRoute(c.name, Recipient(RecipientKind.http, http.trim()));
    }
  }
  return null;
}

/// The payment proof address for a send to [to]: the onion's own key, or the onion of the
/// contact a wallet URL belongs to. Null when the receiver's key is not known.
String? proofAddressFor(Recipient to, Iterable<ContactWays> contacts) {
  if (to.kind == RecipientKind.tor) return proofAddressOfOnion(to.address);
  if (to.kind != RecipientKind.http) return null;
  final want = _sameUrl(to.address);
  for (final c in contacts) {
    final http = c.http;
    final tor = c.tor;
    if (http != null && tor != null && _sameUrl(http) == want) {
      return proofAddressOfOnion(tor);
    }
  }
  return null;
}

/// A wallet URL compared without its scheme, case, or trailing slash: `http://host:3415/` and
/// `https://HOST:3415` are the same wallet.
String _sameUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url.trim().toLowerCase();
  final path = uri.path.endsWith('/')
      ? uri.path.substring(0, uri.path.length - 1)
      : uri.path;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.host.toLowerCase()}$port$path';
}
