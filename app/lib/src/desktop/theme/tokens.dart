/// The desktop interface's tokens: one set for type, space, sizes, radii and colour, used by
/// every desktop screen. Values follow the Electron wallet's Modern look (6.1.6,
/// `src/assets/css/modern/_tokens.scss`), which is Wallet for Epic's Protocol palette; the
/// sizes are tightened into one consistent scale (see `docs/desktop-ui.md`).
library;

import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart' show montserrat, jetBrainsMono;

/// Interface scale (Settings › Appearance) as a factor, [deskBase] at 100 %. [DeskApp] sets it
/// before the tree builds and rebuilds everything below the theme when it changes. Layout sizes
/// follow it through the getters below (whole logical pixels, so nothing lands between pixels);
/// text follows it through the app's `TextScaler`, so [Fs] stays the size before scaling.
double deskScale = deskBase;

/// 100 % in the app: the Electron Modern interface's 17 px root over the 16 px the tokens are
/// written for (6.1.6 `shared/theme.js` MODERN_BASE), so text and space match it.
const double deskBase = 17 / 16;

double _px(double v) => (v * deskScale).roundToDouble();
double _sc(double v) => v * deskScale / deskBase;

/// A size with no token, scaled like the tokens: `200.u`.
extension DeskUnits on num {
  double get u => _px(toDouble());
}

/// Space, 4 px base. Every padding and gap on desktop is one of these.
abstract final class Sp {
  static double get x1 => _px(4);
  static double get x2 => _px(8);
  static double get x3 => _px(12);
  static double get x4 => _px(16);
  static double get x5 => _px(20);
  static double get x6 => _px(24);
  static double get x8 => _px(32);
  static double get x10 => _px(40);
  static double get x12 => _px(48);
  static double get x16 => _px(64);
}

/// Radii: tags, controls and panels, dialogs. Nothing else.
abstract final class Rad {
  static double get xs => _px(4);
  static double get sm => _px(8);
  static double get lg => _px(14);
}

/// Control sizes. Three button heights, one rule: the height says how big the action is.
///  - [inline] 28: an action inside a line of text, a row, a notice (Copy, Retry, Change).
///  - [sm] 36: a row's control (settings column, list toolbar, dialog secondary).
///  - [md] 44: the page's main action and every text field.
/// The Electron app's 52 px "large" button is gone: primary actions are [md].
abstract final class Ctl {
  static double get inline => _px(28);
  static double get sm => _px(36);
  static double get md => _px(44);

  /// Icons: 16 inline and in tags, 20 in navigation and buttons, 24 in empty states.
  static double get iconSm => _px(16);
  static double get icon => _px(20);
  static double get iconLg => _px(24);

  static double get sidebar => _px(224);
  static double get rail => _px(72);
  static double get topbar => _px(64);

  /// Reading widths.
  static double get narrow => _px(720);
  static double get mid => _px(960);
}

/// Breakpoints: phone below 600, tablet/narrow desktop to 1000, desktop from 1000 at 100 %, as
/// in 6.1.6. They grow with the interface scale (not with [deskBase]), so a larger scale moves to
/// the narrower layout sooner.
abstract final class Bp {
  static double get phone => _sc(600);
  static double get desktop => _sc(1000);
}

/// Durations. Motion is short and only ever confirms a change.
abstract final class Dur {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}

/// Colours for one brightness. Read with `context.dc`.
@immutable
class DeskColors extends ThemeExtension<DeskColors> {
  const DeskColors({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.line,
    required this.lineStrong,
    required this.lineField,
    required this.text,
    required this.dim,
    required this.faint,
    required this.accent,
    required this.accentDeep,
    required this.accentInk,
    required this.accentText,
    required this.accentSoft,
    required this.accentFaint,
    required this.tick,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.risk,
    required this.riskSoft,
    required this.hover,
    required this.press,
    required this.grid,
    required this.scrim,
    required this.glow,
  });

  /// Window, then four elevation steps: sidebar and panels, fields, hover and selection,
  /// dialogs and popovers.
  final Color bg, s1, s2, s3, s4;

  /// Hairlines: between rows, around panels, around fields.
  final Color line, lineStrong, lineField;

  final Color text, dim, faint;

  final Color accent, accentDeep, accentInk, accentText, accentSoft, accentFaint, tick;
  final Color ok, okSoft, warn, warnSoft, risk, riskSoft;
  final Color hover, press, grid, scrim, glow;

  @override
  DeskColors copyWith() => this;

  @override
  DeskColors lerp(DeskColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

const DeskColors deskDark = DeskColors(
  bg: Color(0xFF08080A),
  s1: Color(0xFF0D0D10),
  s2: Color(0xFF131318),
  s3: Color(0xFF1A1A21),
  s4: Color(0xFF22222B),
  line: Color(0xFF24242A),
  lineStrong: Color(0xFF33333D),
  lineField: Color(0xFF62626D),
  text: Color(0xFFFFF9F9),
  dim: Color(0xFFA4A4AD),
  faint: Color(0xFF8A8A94),
  accent: Color(0xFFF6D471),
  accentDeep: Color(0xFFC98A3E),
  accentInk: Color(0xFF08080A),
  accentText: Color(0xFFF6D471),
  accentSoft: Color(0x24F6D471),
  accentFaint: Color(0x0FF6D471),
  tick: Color(0xFFC98A3E),
  ok: Color(0xFF8AD98A),
  okSoft: Color(0x1F8AD98A),
  warn: Color(0xFFF0C274),
  warnSoft: Color(0x1FF0C274),
  risk: Color(0xFFF08A8A),
  riskSoft: Color(0x1FF08A8A),
  hover: Color(0x0DFFF9F9),
  press: Color(0x17FFF9F9),
  grid: Color(0x09FFF9F9),
  scrim: Color(0xB8050506),
  glow: Color(0x52F6D471),
);

const DeskColors deskLight = DeskColors(
  bg: Color(0xFFF7F7F8),
  s1: Color(0xFFFFFFFF),
  s2: Color(0xFFFFFFFF),
  s3: Color(0xFFEEEEF0),
  s4: Color(0xFFFFFFFF),
  line: Color(0xFFE0E0E4),
  lineStrong: Color(0xFFC9C9D0),
  lineField: Color(0xFF868690),
  text: Color(0xFF1C1E21),
  dim: Color(0xFF55555F),
  faint: Color(0xFF6B6B75),
  accent: Color(0xFF8F5E1F),
  accentDeep: Color(0xFF8F5E1F),
  accentInk: Color(0xFFFFFFFF),
  accentText: Color(0xFF815525),
  accentSoft: Color(0x1F8F5E1F),
  accentFaint: Color(0x0D8F5E1F),
  tick: Color(0xFF1C1E21),
  ok: Color(0xFF1F7A3A),
  okSoft: Color(0x1A1F7A3A),
  warn: Color(0xFF815525),
  warnSoft: Color(0x1A8F5E1F),
  risk: Color(0xFFB3261E),
  riskSoft: Color(0x14B3261E),
  hover: Color(0x0A000000),
  press: Color(0x12000000),
  grid: Color(0x0D1C1E21),
  scrim: Color(0x661C1E21),
  glow: Color(0x298F5E1F),
);

/// The type scale, about 1.2 per step. Montserrat for display (balance, titles, section heads),
/// the platform face for what people read and click, JetBrains Mono for data (amounts in lists,
/// addresses, ids, heights).
abstract final class Fs {
  static const double xs = 12;
  static const double sm = 13;
  static const double md = 14;
  static const double lg = 16;
  static const double h3 = 18;
  static const double h2 = 22;
  static const double h1 = 28;
  static const double display = 44;
}

/// Text styles built from [Fs] and a colour set. Read with `context.ts`.
class DeskText {
  DeskText(this.c);

  final DeskColors c;

  TextStyle get body => TextStyle(fontSize: Fs.md, height: 1.5, color: c.text);
  TextStyle get bodyDim => body.copyWith(color: c.dim);
  TextStyle get small => TextStyle(fontSize: Fs.sm, height: 1.45, color: c.dim);
  TextStyle get caption => TextStyle(fontSize: Fs.xs, height: 1.4, color: c.faint);
  TextStyle get lead => TextStyle(fontSize: Fs.lg, height: 1.5, color: c.dim);
  TextStyle get label => TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600, color: c.text, height: 1.3);
  TextStyle get strong => body.copyWith(fontWeight: FontWeight.w600);

  TextStyle _display(double size) => TextStyle(
    fontFamily: montserrat,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.2,
    letterSpacing: size * -0.022 * deskScale,
    color: c.text,
  );
  TextStyle get h1 => _display(Fs.h1);
  TextStyle get h2 => _display(Fs.h2);
  TextStyle get h3 => _display(Fs.h3);
  TextStyle get display => _display(Fs.display).copyWith(height: 1.05, letterSpacing: Fs.display * -0.03 * deskScale);

  TextStyle mono({double size = Fs.sm, Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: size,
    height: 1.5,
    color: color ?? c.text,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures(), FontFeature.slashedZero()],
  );
}

extension DeskThemeOf on BuildContext {
  DeskColors get dc => Theme.of(this).extension<DeskColors>() ?? deskDark;
  DeskText get ts => DeskText(dc);
}
