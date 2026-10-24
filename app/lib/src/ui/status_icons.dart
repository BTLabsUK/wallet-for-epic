import 'package:flutter/widgets.dart';

/// The four status and method glyphs, drawn from assets/icons/*.svg (Tor: Bootstrap Icons, MIT;
/// Epicbox: Carbon, Apache-2.0; Direct · HTTP: Material Symbols, Apache-2.0; Node: ours,
/// Apache-2.0) and built into assets/fonts/EpicStatusIcons.ttf by tools/status_icons_font.py.
/// Plain [IconData], so colour, size and `find.byIcon` work as for any Material icon.
abstract final class EpicGlyphs {
  static const _family = 'EpicStatusIcons';
  static const tor = IconData(0xE000, fontFamily: _family);
  static const epicbox = IconData(0xE001, fontFamily: _family);
  static const http = IconData(0xE002, fontFamily: _family);
  static const node = IconData(0xE003, fontFamily: _family);
}
