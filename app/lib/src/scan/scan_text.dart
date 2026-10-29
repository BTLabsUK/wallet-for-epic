// SPDX-License-Identifier: Apache-2.0
/// The words for a payment code that the phone and the desktop share: where it came from,
/// what was dropped from it, and the host of a Direct address.
library;

import '../l10n.dart';
import 'scan_checks.dart' show CodeOrigin;
import 'scan_router.dart' show RequestProblem, untrustedTextForbidden;

/// "From a QR code", "From a link", "Pasted".
String originText(AppLocalizations l, CodeOrigin origin) => switch (origin) {
  CodeOrigin.qr => l.sendOriginQr,
  CodeOrigin.link => l.sendOriginLink,
  CodeOrigin.paste => l.sendOriginPasted,
};

/// The request banner's line for each part of the code that was dropped, amount first.
List<String> requestProblemLines(
  AppLocalizations l,
  Set<RequestProblem> problems,
) => [
  if (problems.contains(RequestProblem.amountInvalid)) l.sendCodeAmountInvalid,
  if (problems.contains(RequestProblem.amountTooLarge))
    l.sendCodeAmountTooLarge,
  if (problems.contains(RequestProblem.tooLong)) l.sendCodeTooLong,
];

/// The host of a Direct address, with its port: `203.0.113.4:3415`, `<56 characters>.onion`.
String directHostOf(String address) {
  final uri = Uri.tryParse(
    address.contains('://') ? address : 'http://$address',
  );
  if (uri == null || uri.host.isEmpty) return address;
  return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
}

/// The host line for the review of a Direct payment, or null when the address already is the
/// host (a bare onion address, a `host:port` pair, either with only a scheme before it): the
/// address line shows it once, with its ends marked. A web address with a path keeps the host
/// line: it names the place the payment goes, without the scheme and path.
String? directHostBesideOf(String address) {
  final host = directHostOf(address);
  final bare = address.trim().replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '').replaceFirst(RegExp(r'/+$'), '');
  return host.toLowerCase() == bare.toLowerCase() ? null : host;
}

/// Code points of the scanned text the preview shows.
const int scanPreviewLength = 80;

/// The first [scanPreviewLength] characters of [text], with "…" when it was longer, without
/// the characters that could turn it around on screen (direction overrides, controls).
String scanPreview(String text) {
  final shown = text.replaceAll(untrustedTextForbidden, '');
  final runes = shown.runes.toList();
  return runes.length <= scanPreviewLength
      ? shown
      : '${String.fromCharCodes(runes.take(scanPreviewLength))}…';
}
