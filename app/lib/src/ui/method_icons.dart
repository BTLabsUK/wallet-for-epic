// SPDX-License-Identifier: Apache-2.0
/// The payment methods' one icon each, and their short names, for the whole app: badges,
/// the Send and Receive segments, settings, contacts, history, help.
///
/// The model of 2026-10-25: Epicbox · Link (Link · HTTP, Link · Tor) · Direct (Direct · QR
/// Payment, Direct · File Transfer). Where space is short (a badge, a segment) the short name:
/// Epicbox, HTTP, Tor, QR, File, with the icon where it helps, or the icon alone with the full
/// name in a tooltip where the meaning is obvious. This file is the single source: every other
/// method→icon switch delegates here.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../payment_method.dart';
import 'status_icons.dart';

export '../payment_method.dart';


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

  /// The name where space is short (badges, tags, segments): Epicbox, Link · HTTP, Link · Tor,
  /// Direct · QR, Direct · File. Never a sub-option alone (2026-10-25).
  static String shortName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.epicbox => l.methodEpicbox,
    MethodKind.linkHttp => l.methodShortHttp,
    MethodKind.linkTor => l.methodShortTor,
    MethodKind.directQr => l.methodShortQr,
    MethodKind.directFile => l.methodShortFile,
  };

  /// The full name, with the family: Epicbox, Link · HTTP, Link · Tor, Direct · QR Payment,
  /// Direct · File Transfer. For a place with no family header around it.
  static String fullName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.epicbox => l.methodEpicbox,
    MethodKind.linkHttp => l.methodDirectHttp,
    MethodKind.linkTor => l.methodDirectTor,
    MethodKind.directQr => l.methodDirectQr,
    MethodKind.directFile => l.methodDirectFile,
  };

  /// The name under its family's header (Settings, a grouped list): Epicbox, HTTP, Tor,
  /// QR Payment, File Transfer.
  static String groupName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.epicbox => l.methodEpicbox,
    MethodKind.linkHttp => l.methodGroupHttp,
    MethodKind.linkTor => l.methodGroupTor,
    MethodKind.directQr => l.methodQr,
    MethodKind.directFile => l.methodFile,
  };

  /// The family's name: Epicbox, Link, Direct.
  static String familyName(AppLocalizations l, MethodFamily f) => switch (f) {
    MethodFamily.epicbox => l.methodEpicbox,
    MethodFamily.link => l.methodDirect,
    MethodFamily.direct => l.methodDirectFamily,
  };
}
