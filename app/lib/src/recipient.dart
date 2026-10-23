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
/// QR codes and chat apps sometimes add. An onion (F9: with or without `.onion`, with
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
/// While `http://192.168` is still being typed it is not.
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
  return _ipv4.hasMatch(host) || host == 'localhost' || host.contains('.');
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
