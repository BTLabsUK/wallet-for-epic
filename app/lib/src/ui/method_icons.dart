/// The payment methods' one icon each, and their short names, for the whole app: badges,
/// the Send and Receive segments, settings, contacts, history, help.
///
/// The owner's model (2026-10-25): Epicbox · Link (Link · HTTP, Link · Tor) · Direct (Direct · QR
/// Payment, Direct · File Transfer). Where space is short (a badge, a segment) the short name:
/// Epicbox, HTTP, Tor, QR, File, with the icon where it helps, or the icon alone with the full
/// name in a tooltip where the meaning is obvious. This file is the single source: every other
/// method→icon switch delegates here.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../recipient.dart' show RecipientKind;
import 'status_icons.dart';

/// A payment method, by family.
enum MethodKind {
  epicbox(MethodFamily.epicbox),
  linkHttp(MethodFamily.link),
  linkTor(MethodFamily.link),
  directQr(MethodFamily.direct),
  directFile(MethodFamily.direct);

  const MethodKind(this.family);

  final MethodFamily family;

  /// The method an address of [kind] is paid through.
  static MethodKind ofRecipient(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => MethodKind.epicbox,
    RecipientKind.http => MethodKind.linkHttp,
    RecipientKind.tor => MethodKind.linkTor,
  };
}

/// The three families: Epicbox (a relay holds the payment), Link (straight to their wallet
/// over the network), Direct (hand to hand: a QR code or a file, no network).
enum MethodFamily { epicbox, link, direct }

/// One icon per method and per family. Epicbox is the "44" glyph, Link · HTTP the http glyph,
/// Link · Tor the Tor glyph (all from `EpicStatusIcons`); QR and File are Material's; the Link
/// family is the link glyph, the Direct family two arrows.
abstract final class MethodIcons {
  static const epicbox = EpicGlyphs.epicbox;
  static const http = EpicGlyphs.http;
  static const tor = EpicGlyphs.tor;
  static const qr = Icons.qr_code_2;
  static const file = Icons.description_outlined;

  /// The families' own glyphs, for a header or a segment that names the family.
  static const link = EpicGlyphs.link;
  static const direct = Icons.sync_alt;

  static IconData of(MethodKind m) => switch (m) {
    MethodKind.epicbox => epicbox,
    MethodKind.linkHttp => http,
    MethodKind.linkTor => tor,
    MethodKind.directQr => qr,
    MethodKind.directFile => file,
  };

  static IconData family(MethodFamily f) => switch (f) {
    MethodFamily.epicbox => epicbox,
    MethodFamily.link => link,
    MethodFamily.direct => direct,
  };

  /// The short name: Epicbox, HTTP, Tor, QR, File.
  static String shortName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.epicbox => l.methodEpicbox,
    MethodKind.linkHttp => l.methodShortHttp,
    MethodKind.linkTor => l.methodShortTor,
    MethodKind.directQr => l.methodShortQr,
    MethodKind.directFile => l.methodFile,
  };

  /// The full name, with the family: Epicbox, Link · HTTP, Link · Tor, QR Payment, File.
  static String fullName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.epicbox => l.methodEpicbox,
    MethodKind.linkHttp => l.methodDirectHttp,
    MethodKind.linkTor => l.methodDirectTor,
    MethodKind.directQr => l.methodQr,
    MethodKind.directFile => l.methodFile,
  };
}
