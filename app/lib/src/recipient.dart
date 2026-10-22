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
