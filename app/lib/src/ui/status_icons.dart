// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';

/// The status, method and trust glyphs (the Link family is the link), drawn from assets/icons/*.svg
/// (Tor: Bootstrap Icons, MIT; Epicbox: Carbon, Apache-2.0; Direct · HTTP: Material Symbols,
/// Apache-2.0; Node, Node only, the plug, No payments and the pairing shields and lock: ours, Apache-2.0) and built into
/// assets/fonts/EpicStatusIcons.ttf by tools/status_icons_font.py.
/// Plain [IconData], so colour, size and `find.byIcon` work as for any Material icon.
abstract final class EpicGlyphs {
  static const _family = 'EpicStatusIcons';
  static const tor = IconData(0xE000, fontFamily: _family);
  static const epicbox = IconData(0xE001, fontFamily: _family);
  static const http = IconData(0xE002, fontFamily: _family);
  static const node = IconData(0xE003, fontFamily: _family);
  static const link = IconData(0xE004, fontFamily: _family);

  /// Pairing trust (RFC 0002 17.1): a shield with a check, Verified.
  static const verified = IconData(0xE005, fontFamily: _family);

  /// The outline shield: Paired, not verified.
  static const paired = IconData(0xE006, fontFamily: _family);

  /// The shield with a mark: Keys changed.
  static const keysChanged = IconData(0xE007, fontFamily: _family);

  /// The lock: Sealed.
  static const sealed = IconData(0xE008, fontFamily: _family);

  /// Node only: one server box with short rays, "this one".
  static const nodeOnly = IconData(0xE009, fontFamily: _family);

  /// Kill switch: a plug pulled out.
  static const unplugged = IconData(0xE00A, fontFamily: _family);

  /// No payments: a coin with an E, struck through. The bare mark in lists, with the words
  /// on a contact's page.
  static const noPayments = IconData(0xE00B, fontFamily: _family);
}
