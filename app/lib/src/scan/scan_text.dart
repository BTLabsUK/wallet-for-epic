// SPDX-License-Identifier: Apache-2.0
/// The words for a payment code that the phone and the desktop share: where it came from,
/// what was dropped from it, and the host of a Direct address.
library;

import '../address_format.dart' show hostPort;
import '../services/service_rules.dart';
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
  if (problems.contains(RequestProblem.minimumInvalid)) l.sendCodeMinimumInvalid,
];

/// What Send says while [message] is empty, or null. [codeAsks]: the code that filled the
/// address requires a message; that warning is the code's own and needs no service file.
/// Otherwise whatever a service rule says about [address]. Only a warning: the user may send
/// anyway.
String? noteWarning(AppLocalizations l, String address, String message, {required bool codeAsks}) {
  if (message.trim().isNotEmpty) return null;
  if (codeAsks) return l.sendNoteMissingCode;
  final hint = matchService(address, serviceRules)?.hints.firstOrNull;
  return hint == null ? null : serviceHintText(l, hint);
}

/// Whether Send reads Message as a field to fill, not an optional one: [codeNote], the code that
/// filled the address carries or asks for a note, or a service rule has a hint for [address].
bool noteExpected(String address, {required bool codeNote}) =>
    codeNote || (matchService(address, serviceRules)?.hints.isNotEmpty ?? false);

/// The translated string of a service file's hint id.
String serviceHintText(AppLocalizations l, ServiceHint hint) => switch (hint) {
  ServiceHint.exchangeCheckNote => l.serviceHintExchangeCheckNote,
};

/// The host of a Direct address, with its port: `203.0.113.4:<port>`, `<56 characters>.onion`
/// ([hostPort]).
String directHostOf(String address) => hostPort(address);

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
