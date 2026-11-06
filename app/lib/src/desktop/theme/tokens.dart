// SPDX-License-Identifier: Apache-2.0
/// The desktop interface's tokens: one set for type, space, sizes, radii and colour, used by
/// every desktop screen. Values follow the Electron wallet's Modern look (6.1.6,
/// `src/assets/css/modern/_tokens.scss`), which is Wallet for Epic's Protocol palette; the
/// sizes are tightened into one consistent scale.
library;

import 'package:flutter/material.dart';

import '../../ui/theme/palette.dart';
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

  /// The one grid of a two-column page (Activity + detail, Send + Summary, Contacts + detail,
  /// Outputs): the gap between the columns and the padding inside their panels.
  static double get col => x6;
  static double get panel => x5;
}

/// Radii: tags, controls and panels, dialogs. Nothing else.
abstract final class Rad {
  static double get xs => _px(4);
  static double get sm => _px(8);
  static double get lg => _px(14);
}

/// Control sizes. Three heights, one rule: the height says how big the action is.
///  - [inline] 28: actions inside text, rows and notices; icon buttons (copy, QR, help); tags.
///  - [sm] 36: a row's control: Settings row controls ([ERowControl] widths), Reachable segments,
///    server picker, toolbar and dialog-secondary buttons, "Open" in list rows, the tabs and the
///    Send method selector in a panel's header band.
///  - [md] 44: every form field and the page's primary button.
/// Nothing is taller than 44: the Electron app's 52 px "large" button is gone.
abstract final class Ctl {
  static double get inline => _px(28);
  static double get sm => _px(36);
  static double get md => _px(44);

  /// Icons: 16 inline and in tags, 20 in navigation and buttons, 24 in empty states.
  static double get iconSm => _px(16);
  static double get icon => _px(20);
  static double get iconLg => _px(24);

  static double get sidebar => _px(224);

  /// The Settings column that takes the sidebar's place while a Settings page is open.
  static double get settingsNav => _px(288);
  static double get rail => _px(72);
  static double get topbar => _px(64);

  /// Reading widths.
  static double get narrow => _px(720);
  static double get mid => _px(960);

  /// A card's header bar ([EPanel]'s title, a list's tabs, a detail pane's title and close):
  /// one height, so the headers' bottom lines and the first rows of panels side by side line up.
  static double get header => _px(52);

  /// The side column of a two-column page: the Send summary, and a detail pane ([sideWide]
  /// from a 1400 px window at 100 %).
  static double get sideSm => _px(300);
  static double get side => _px(380);
  static double get sideWide => _px(440);

  /// The Contacts list beside its detail pane.
  static double get sideList => _px(340);

  /// Activity's detail pane never takes more than this share of the row, and takes [sideWide]
  /// from this window width (at 100 %).
  static const double sideMaxFraction = 0.42;
  static double get sideWideFrom => _px(1400);

  /// The trailing control of a Settings row ([ERowControl]): [sm] tall and one of two widths,
  /// [rowW] for buttons, dropdowns and fields, [rowWide] for segmented choices and server
  /// pickers. The switch keeps its own size. Both fit the longest label at every scale.
  static double get rowW => _px(200);
  static double get rowWide => _px(300);
}

/// Breakpoints: phone below 600, tablet/narrow desktop to 1000, desktop from 1000 at 100 %, as
/// in 6.1.6. They grow with the interface scale (not with [deskBase]), so a larger scale moves to
/// the narrower layout sooner.
abstract final class Bp {
  static double get phone => _sc(600);
  static double get desktop => _sc(1000);
}

/// Content-width breakpoints: compared with the width a component itself gets (a
/// LayoutBuilder's maxWidth), never the window's. Every layout switch in the desktop screens
/// uses one of these; a wider layout that needs more room takes the next one up, never a new
/// number. They come from the columns' minimums: a list 480, a detail pane 376, a Settings
/// row's words 240, a tile 180, a choice card 220, a step 120.
abstract final class Lay {
  /// Below: one column of everything; labels above their values.
  static double get xs => _px(360);

  /// Steppers go down, the phrase grid 2 columns, tile rows 2 across.
  static double get sm => _px(480);

  /// Three tiles or cards across, the phrase grid 4 columns; a header row keeps its action
  /// beside its words.
  static double get md => _px(600);

  /// The QR beside the address, three choice cards in a row.
  static double get lg => _px(720);

  /// Any two columns side by side: list and detail, form and Summary, Settings' section list
  /// beside the page, the onboarding step rail.
  static double get xl => _px(880);

  /// Receive's two columns, the node panel's status beside its peers.
  static double get wide => _px(1040);
}

/// The widest a component gets that must not stretch with the window.
abstract final class Max {
  /// The depth dial with its caption.
  static double get dial => _px(440);

  /// The Overview picture beside or under the depth dial.
  static double get preview => _px(520);

  /// Payment steps laid across.
  static double get steps => _px(880);

  /// Send's method selector strip, Receive's method head.
  static double get selector => _px(720);

  /// A form's fields (Send, Add contact, an invoice).
  static double get form => Ctl.narrow;

  /// A dialog (EDialog's default width).
  static double get dialog => _px(560);

  /// The card of Unlock and the other single-question screens ([EAuthCard]).
  static double get auth => _px(520);

  /// One tile in a tile row (a balance breakdown, node facts).
  static double get tile => _px(320);
}

/// Durations. Motion is short and only ever confirms a change.
abstract final class Dur {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}

/// The one expand/collapse motion (`widgets/motion.dart` [ExpandFade]). Same length both
/// ways; the curve is mirrored: ease-out opening, ease-in closing. The content's fade trails
/// the height by [fadeLag] ms so nothing jumps. `disableAnimations` swaps in one frame.
abstract final class Motion {
  static const expand = Duration(milliseconds: 240);
  static const cross = Duration(milliseconds: 160); // crossfades (strip, state words)
  static const easeOut = Curves.easeOutCubic; // forward: opening
  static const easeIn = Curves.easeInCubic; // reverse: closing
  static const fadeLag = 40; // ms the fade trails the height
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
    required this.info,
    required this.infoSoft,
    required this.txSent,
    required this.txReceived,
    required this.txCancelled,
    required this.hover,
    required this.press,
    required this.grid,
    required this.scrim,
    required this.shadow,
    required this.glow,
    required this.lift,
    required this.wash,
    required this.hero,
    required this.tint,
    required this.dots,
  });

  /// Window, then four elevation steps: sidebar and panels, fields, hover and selection,
  /// dialogs and popovers.
  final Color bg, s1, s2, s3, s4;

  /// Hairlines: between rows, around panels, around fields.
  final Color line, lineStrong, lineField;

  final Color text, dim, faint;

  /// The brand gold and its ink, text, soft and faint fills, and the corner ticks. Buttons,
  /// focus, links, the mark. Never a state colour (see [ok], [info] and [s3] for selection).
  final Color accent, accentDeep, accentInk, accentText, accentSoft, accentFaint, tick;

  /// Status: [ok] green (connected, synced, confirmed, success), [warn] amber
  /// (needs attention, not ready), [risk] red (error), [info] blue (in progress: confirming,
  /// the current step, checking). Each `Soft` is the translucent fill behind it. A selected or
  /// current row takes [s3], plus an [ok] check only when it is working.
  final Color ok, okSoft, warn, warnSoft, risk, riskSoft, info, infoSoft;

  /// A transaction's direction on its arrow, icon and amount (Activity, Overview, details,
  /// Outputs, invoices, toasts). The rule (26.10.18, after 26.10.8's gold): sent red,
  /// received green, cancelled a neutral grey. [txSent] is money out, not a problem: a vivid
  /// red apart from the softer [risk], which stays for errors, and never the brand gold.
  /// States keep theirs: confirming [info], failed or stalled [warn] or [risk].
  final Color txSent, txReceived, txCancelled;
  final Color hover, press, grid, scrim, glow;

  /// The one soft shadow under a floating surface (popover, menu, server list, tour card),
  /// drawn with [popShadow]. Never [scrim]: that is the dialog barrier, and as a shadow it
  /// draws a hard grey band in light.
  final Color shadow;

  /// The one low shadow under a resting panel ([EPanel], [ETicked]) and the warm tint of
  /// the page backdrop ([DeskBackdrop]). Both are transparent in dark, where a panel is its
  /// fill and hairline and the window stays flat.
  final Color lift, wash;

  /// Light only, transparent in dark: the balance frame's warm fill ([ETicked]), the brand
  /// tint of icon tiles and the selected navigation item, the page backdrop's dot texture.
  final Color hero, tint, dots;

  /// The resting panel's shadow, drawn with [lift]; nothing in dark.
  List<BoxShadow>? get panelShadow =>
      lift.a == 0 ? null : [BoxShadow(color: lift, blurRadius: 18.u, offset: Offset(0, 6.u), spreadRadius: -4.u)];

  /// The shadow under a floating surface: soft and low, the same for every popover and menu.
  List<BoxShadow> get popShadow => [BoxShadow(color: shadow, blurRadius: 24.u, offset: Offset(0, 8.u))];

  /// [shadow] at full strength, for a Material `shadowColor` (a MenuAnchor's menu draws its
  /// own elevation, which thins the colour itself).
  Color get shadowInk => shadow.withValues(alpha: 1);

  /// A floating surface: [s4] with a [lineStrong] hairline and [popShadow]. Popovers, the
  /// server list, the tour card; menus take the same look from `deskMenuStyle`.
  BoxDecoration get popover => BoxDecoration(
    color: s4,
    border: Border.all(color: lineStrong),
    borderRadius: BorderRadius.circular(Rad.sm),
    boxShadow: popShadow,
  );

  /// A read-only box of text in a panel or a dialog (a code's text, the payee's note, a
  /// command, an id): the field fill with a hairline on every side, so it shows in both themes.
  /// The phone's `WalletTokens.well` is the same.
  BoxDecoration get well => BoxDecoration(
    color: s2,
    border: Border.all(color: line),
    borderRadius: BorderRadius.circular(Rad.sm),
  );

  @override
  DeskColors copyWith() => this;

  @override
  DeskColors lerp(DeskColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

/// Both sets come from the shared palette (`ui/theme/palette.dart`), as the phone's.
const DeskColors deskDark = DeskColors(
  bg: PaletteDark.bg,
  s1: PaletteDark.s1,
  s2: PaletteDark.s2,
  s3: PaletteDark.s3,
  s4: PaletteDark.s4,
  line: PaletteDark.line,
  lineStrong: PaletteDark.lineStrong,
  lineField: PaletteDark.lineField,
  text: PaletteDark.text,
  dim: PaletteDark.dim,
  faint: PaletteDark.faint,
  accent: PaletteDark.accent,
  accentDeep: PaletteDark.accentDeep,
  accentInk: PaletteDark.accentInk,
  accentText: PaletteDark.accentText,
  accentSoft: PaletteDark.accentSoft,
  accentFaint: PaletteDark.accentFaint,
  tick: PaletteDark.tick,
  ok: PaletteDark.ok,
  okSoft: PaletteDark.okSoft,
  warn: PaletteDark.warn,
  warnSoft: PaletteDark.warnSoft,
  risk: PaletteDark.risk,
  riskSoft: PaletteDark.riskSoft,
  info: PaletteDark.info,
  infoSoft: PaletteDark.infoSoft,
  txSent: PaletteDark.txSent,
  txReceived: PaletteDark.txReceived,
  txCancelled: PaletteDark.txCancelled,
  hover: PaletteDark.hover,
  press: PaletteDark.press,
  grid: PaletteDark.grid,
  scrim: PaletteDark.scrim,
  shadow: PaletteDark.shadow,
  glow: PaletteDark.glow,
  lift: PaletteDark.lift,
  wash: PaletteDark.wash,
  hero: PaletteDark.hero,
  tint: PaletteDark.tint,
  dots: PaletteDark.dots,
);

const DeskColors deskLight = DeskColors(
  bg: PaletteLight.bg,
  s1: PaletteLight.s1,
  s2: PaletteLight.s2,
  s3: PaletteLight.s3,
  s4: PaletteLight.s4,
  line: PaletteLight.line,
  lineStrong: PaletteLight.lineStrong,
  lineField: PaletteLight.lineField,
  text: PaletteLight.text,
  dim: PaletteLight.dim,
  faint: PaletteLight.faint,
  accent: PaletteLight.accent,
  accentDeep: PaletteLight.accentDeep,
  accentInk: PaletteLight.accentInk,
  accentText: PaletteLight.accentText,
  accentSoft: PaletteLight.accentSoft,
  accentFaint: PaletteLight.accentFaint,
  tick: PaletteLight.tick,
  ok: PaletteLight.ok,
  okSoft: PaletteLight.okSoft,
  warn: PaletteLight.warn,
  warnSoft: PaletteLight.warnSoft,
  risk: PaletteLight.risk,
  riskSoft: PaletteLight.riskSoft,
  info: PaletteLight.info,
  infoSoft: PaletteLight.infoSoft,
  txSent: PaletteLight.txSent,
  txReceived: PaletteLight.txReceived,
  txCancelled: PaletteLight.txCancelled,
  hover: PaletteLight.hover,
  press: PaletteLight.press,
  grid: PaletteLight.grid,
  scrim: PaletteLight.scrim,
  shadow: PaletteLight.shadow,
  glow: PaletteLight.glow,
  lift: PaletteLight.lift,
  wash: PaletteLight.wash,
  hero: PaletteLight.hero,
  tint: PaletteLight.tint,
  dots: PaletteLight.dots,
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
