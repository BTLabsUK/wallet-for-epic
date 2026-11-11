// SPDX-License-Identifier: Apache-2.0
/// One rule for Send, Contacts, the contact picker, contact import and the QR scan: what kind
/// of address a typed or pasted text is, and its canonical form.
library;

import '../../recipient.dart' show RecipientKind, httpAddressComplete, parseRecipient;
import '../../scan/scan_router.dart';
import 'api.dart' show DeskWalletApi;
import 'http_address.dart';
import 'models.dart' show TxMethod;

enum AddressKind { epicbox, http, tor, none }

class ParsedAddress {
  const ParsedAddress(this.kind, this.canonical, {required this.complete});

  final AddressKind kind;

  /// Epicbox: `key@host` (no `epicbox://`); Tor: `<56 lowercase>.onion`; HTTP: the trimmed
  /// URL; none: the text without whitespace.
  final String canonical;

  /// The validator accepts it (checksum, chain, host), so Send may switch to its method.
  final bool complete;
}

final RegExp _epicboxShape = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{40,}(?:@[^@\s]+)?$');
final RegExp _ipv4 = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');

/// Whitespace removed; `epicbox://` dropped; an onion in any form → `<56 lowercase>.onion`
/// (`http://`, port, path, case, trailing slash ignored; `http://…onion` is Tor, not HTTP);
/// `http(s)://` with a host → http, canonical = the text; else epicbox when the text is 40+
/// base58 characters with an optional `@host`, else none. A Tor address with a bad checksum
/// or version is still Tor, but not [ParsedAddress.complete].
ParsedAddress parseAddress(String text, DeskWalletApi api) => _parse(text, api);

/// The kind of [text] by its shape alone (no checksum): what a saved contact's address is.
AddressKind addressKindOf(String text) => _parse(text, null).kind;

/// The Send method for an address kind; null for [AddressKind.none].
TxMethod? methodForKind(AddressKind k) => switch (k) {
  AddressKind.epicbox => TxMethod.epicbox,
  AddressKind.http => TxMethod.http,
  AddressKind.tor => TxMethod.tor,
  AddressKind.none => null,
};

ParsedAddress _parse(String text, DeskWalletApi? api) {
  final r = parseRecipient(text);
  switch (r.kind) {
    case RecipientKind.tor:
      return ParsedAddress(AddressKind.tor, r.address, complete: api?.isOnionAddress(r.address) ?? false);
    case RecipientKind.http:
      final uri = Uri.tryParse(r.address);
      if (uri == null || uri.host.isEmpty) {
        return ParsedAddress(AddressKind.none, r.address, complete: false);
      }
      final host = uri.host.toLowerCase();
      final named = _ipv4.hasMatch(host) || host == 'localhost' || host.contains('.');
      return ParsedAddress(
        AddressKind.http,
        r.address,
        complete: named && httpAddressProblem(r.address) == null,
      );
    case RecipientKind.epic1:
      // An epic1 link is no address a method pays; the contact form checks it with LEPIC.
      return ParsedAddress(AddressKind.none, r.address, complete: false);
    case RecipientKind.epicbox:
      if (!_epicboxShape.hasMatch(r.address)) {
        return ParsedAddress(AddressKind.none, r.address, complete: false);
      }
      return ParsedAddress(AddressKind.epicbox, r.address, complete: api?.isEpicboxAddress(r.address) ?? false);
  }
}

/// The scan router's address check on the desktop: the wallet's own checks, the ones Send runs.
AddressCheck deskScanCheck(DeskWalletApi api) => (to) => switch (to.kind) {
  RecipientKind.epicbox => api.isEpicboxAddress(to.address)
      ? AddressVerdict.valid
      : (api.epicboxAddressOtherChain(to.address) ? AddressVerdict.otherChain : AddressVerdict.invalid),
  RecipientKind.tor => api.isOnionAddress(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.http => httpAddressComplete(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.epic1 => AddressVerdict.invalid,
};

/// What a pasted or linked [text] is, checked against [api].
ScannedCode deskClassify(DeskWalletApi api, String text) => classifyScan(text, check: deskScanCheck(api));
