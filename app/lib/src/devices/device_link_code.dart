/// The text a device link's QR carries, and that is copied to paste on the other device:
/// `epiccash://device-link/1/<base64url of the private invite>`. The prefix tells the scan and
/// paste routes it is a device link (Linked devices › Link a device), not a contact invite; the
/// contact pairing routes never open it ([pairingLinkIn] does not match it).
library;

import 'dart:convert';

const String deviceLinkPrefix = 'epiccash://device-link/1/';

/// The device link text for the private invite [inviteLink].
String deviceLinkText(String inviteLink) => '$deviceLinkPrefix${base64Url.encode(utf8.encode(inviteLink)).replaceAll('=', '')}';

final RegExp _code = RegExp(r'epiccash://device-link/1/([A-Za-z0-9_\-]+)', caseSensitive: false);

/// Whether [text] holds a device link (surrounding words and whitespace allowed).
bool isDeviceLinkText(String text) => _code.hasMatch(text.replaceAll(RegExp(r'\s'), ''));

/// The private invite in the device link [text], or null when it holds none or it is damaged.
String? deviceInviteIn(String text) {
  final m = _code.firstMatch(text.replaceAll(RegExp(r'\s'), ''));
  if (m == null) return null;
  final b64 = m.group(1)!;
  try {
    final link = utf8.decode(base64Url.decode(b64.padRight((b64.length + 3) ~/ 4 * 4, '=')));
    return link.isEmpty ? null : link;
  } on FormatException {
    return null;
  }
}
