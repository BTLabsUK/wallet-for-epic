/// The text a device link's QR carries, and that is copied to paste on the other device:
/// `epiccash://device-link/1/<base64url of the private invite>/<wallet fingerprint>`. The prefix
/// tells the scan and paste routes it is a device link (Linked devices › Link a device), not a
/// contact invite; the contact pairing routes never open it ([pairingLinkIn] does not match it).
///
/// The fingerprint ([deviceLinkFingerprint]) lets the scanning device refuse a code of another
/// wallet at once, before it answers. It proves nothing: the hello's proof does, so a code
/// without one (made before it existed) is answered and left to the proof.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

const String deviceLinkPrefix = 'epiccash://device-link/1/';

/// What a device link carries: the private invite and, when the code has one, the fingerprint
/// of the wallet that made it.
typedef DeviceLinkCode = ({String invite, String? fingerprint});

/// The device link text for the private invite [inviteLink] of the wallet whose fingerprint is
/// [fingerprint].
String deviceLinkText(String inviteLink, {required String fingerprint}) =>
    '$deviceLinkPrefix${base64Url.encode(utf8.encode(inviteLink)).replaceAll('=', '')}/$fingerprint';

/// The short fingerprint of the wallet with the payments key [walletKey] that a device link
/// carries: the first 8 bytes of SHA-256 of a tag and the key, in hex. Not the key itself, so
/// the code does not show the wallet's address.
String deviceLinkFingerprint(String walletKey) =>
    sha256.convert(utf8.encode('epiccash/device-link/fp/v1$walletKey')).toString().substring(0, 16);

final RegExp _code = RegExp(r'epiccash://device-link/1/([A-Za-z0-9_\-]+)(?:/([0-9a-fA-F]{16}))?', caseSensitive: false);

/// Whether [text] holds a device link (surrounding words and whitespace allowed).
bool isDeviceLinkText(String text) => _code.hasMatch(text.replaceAll(RegExp(r'\s'), ''));

/// The device link in [text], or null when it holds none or it is damaged.
DeviceLinkCode? deviceLinkIn(String text) {
  final m = _code.firstMatch(text.replaceAll(RegExp(r'\s'), ''));
  if (m == null) return null;
  final b64 = m.group(1)!;
  try {
    final link = utf8.decode(base64Url.decode(b64.padRight((b64.length + 3) ~/ 4 * 4, '=')));
    return link.isEmpty ? null : (invite: link, fingerprint: m.group(2)?.toLowerCase());
  } on FormatException {
    return null;
  }
}

/// The private invite in the device link [text], or null when it holds none or it is damaged.
String? deviceInviteIn(String text) => deviceLinkIn(text)?.invite;
