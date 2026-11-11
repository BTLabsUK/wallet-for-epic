// SPDX-License-Identifier: Apache-2.0
import '../l10n.dart';

/// How a payment travelled when nothing names its other side: no contact and no address. The
/// words "to Alice" / "from Alice" are for a name; this is for "via file".
enum Via { file, link, inPerson, epicbox, http, tor, qr }

/// The phrase for [via] inside a sentence: "via file", "via epic1 link", "in person".
String viaPhrase(AppLocalizations l, Via via) => l.txViaPhrase(via.name);

/// The [Via] of LEPIC's transport word (`epicbox`, `http`, `tor`, `file`), or null.
Via? viaOfTransport(String? transport) => switch (transport) {
  'epicbox' => Via.epicbox,
  'http' => Via.http,
  'tor' => Via.tor,
  'file' => Via.file,
  _ => null,
};
