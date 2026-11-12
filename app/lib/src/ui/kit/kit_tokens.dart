// SPDX-License-Identifier: Apache-2.0
/// The phone redesign's sizes, radii, spaces and type (HANDOFF 5.3 and 5.4), in one place. A
/// screen or a kit part reads a value from here and never writes a literal size, radius or font
/// size. Colours are [WalletTokens] (`ui/theme/tokens.dart`).
library;

import 'package:flutter/material.dart';

import '../theme/fonts.dart' show interFamily, interFeatures;
import '../theme/tokens.dart' show jetBrainsMono, montserrat;

/// Sizes, radii and spaces, in logical pixels.
abstract final class Kit {
  // Space. The grid is 4.
  static const double grid = 4;

  /// The side margin of a screen and of a group.
  static const double gutter = 16;

  /// The gap between two groups.
  static const double groupGap = 12;

  /// The smallest tappable size.
  static const double hitMin = 44;

  /// The smallest tap target Android accepts; icon buttons and the back link use it.
  static const double hitTarget = 48;
  /// The tap target of a control that sits on its own (Android's guideline); the pill, chip or
  /// field drawn inside may be shorter.
  static const double touchMin = 48;

  // Radii.
  /// A group, a card, a toast, an announcement.
  static const double rGroup = 20;
  static const double rButton = 16;
  static const double rButtonSmall = 12;
  static const double rField = 16;
  static const double rSearch = 13;
  static const double rIconButton = 14;

  /// The 40 px avatar and icon well.
  static const double rAvatar = 13;

  /// The 54 px avatar of the contact strip.
  static const double rAvatarStrip = 18;
  static const double rSheetTop = 28;
  static const double rQr = 22;
  static const double rBrandTile = 26;
  static const double rPill = 999;

  // Sizes.
  static const double button = 52;
  static const double buttonSmall = 36;
  static const double tabBar = 86;
  static const double scanButton = 50;
  static const double avatar = 40;
  static const double avatarStrip = 54;

  /// The direction badge on an avatar.
  static const double avatarBadge = 19;
  static const double key = 56;
  static const double pinDot = 14;
  static const double toastMin = 56;
  static const double toastIcon = 34;

  /// The distance of a toast from the top edge of the screen, and from each side.
  static const double toastTop = 50;
  static const double toastSide = 12;
  static const double slotCard = 90;
  static const double announcementImage = 64;
  static const double qr = 212;
  static const double brandTile = 96;
  static const double flowHeader = 44;
  static const double pageTitleHeader = 48;
  static const double searchField = 42;

  /// The segmented filter: its track, the radius of track and chosen segment.
  static const double segmented = 38;
  static const double rSegmented = 12;
  static const double rSegment = 9;
  static const double field = 52;
  static const double pill = 32;
  static const double chip = 28;
  static const double stepDot = 10;
  static const double availableBar = 46;
  static const double maxPill = 34;
  static const double emptyWell = 72;
  static const double switchWidth = 50;
  static const double switchHeight = 30;
  static const double switchKnob = 24;
  static const double grabberWidth = 36;
  static const double grabberHeight = 5;

  /// The radio ring and its dot, and the stepper's pill.
  static const double radio = 26;
  static const double radioDot = 12;
  // `.stepper`: 38 tall, 3 in, 36 wide ends around a 24 count; the layout box is 44 tall to touch.
  static const double stepperWidth = 102;
  static const double stepperHeight = 44;
  static const double stepperDrawn = 38;

  // Row heights.
  static const double rowList = 62;
  static const double rowSettings = 56;
  static const double rowSheet = 48;

  // Blur behind a toast and a sheet.
  static const double blur = 24;

  /// A row's left edge to its text: gutter, avatar, gap. A list's divider starts here.
  static const double dividerInsetList = 66;

  /// A plain settings group's divider starts at the row's padding.
  static const double dividerInsetPlain = 14;
}

/// The type of the redesign, from wallet.css: Montserrat 600 for figures and titles, Inter for
/// rows and buttons, JetBrains Mono for amounts and addresses. Colour is left to the caller (a
/// part copies the style with its colour). Figures are tabular. A CSS letter-spacing in em is
/// written here as em × size; a CSS line-height as the same multiple.
abstract final class KitType {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _head(double size, double tracking, {FontWeight weight = FontWeight.w600, double height = 1.3}) => TextStyle(
    fontFamily: montserrat,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * tracking,
    height: height,
    fontFeatures: _tabular,
  );

  /// The platform face: Inter, with tnum and cv11 like the frames' body. [height] is the CSS
  /// line-height (the frames' body is 1.3).
  static TextStyle _body(double size, {FontWeight weight = FontWeight.w400, double height = 1.3}) => TextStyle(
    fontFamily: interFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    // wallet.css sets none on the body; without it the theme's Material spacing leaks in.
    letterSpacing: 0,
    fontFeatures: interFeatures,
  );

  /// `.amt`: Home balance, 50, line-height 1 (the fraction at [homeBalanceFraction] of it).
  static final TextStyle homeBalance = _head(50, -0.03, height: 1);
  static const double homeBalanceFraction = 0.42;

  /// `.big`: amount entry, 68, line-height 1; [amountEntryLong] when the figure is long.
  static final TextStyle amountEntry = _head(68, -0.035, height: 1);
  static final TextStyle amountEntryLong = _head(50, -0.035, height: 1);

  /// `.ttl h1`.
  static final TextStyle tabTitle = _head(30, -0.025);

  /// `.ptitle`.
  static final TextStyle pageTitle = _head(28, -0.025);

  /// `.hdr .t`.
  static final TextStyle flowTitle = _head(17, -0.01);

  /// `.sheet h2`.
  static final TextStyle sheetTitle = _head(20, -0.015);

  /// `.sec h2`.
  static final TextStyle sectionHead = _head(18, -0.015);

  /// `.key`.
  static final TextStyle keypad = _head(26, 0);

  /// `.who h1`, the contact page's name.
  static final TextStyle whoName = _head(22, -0.02);

  /// The EPIC unit, `.amt u`: 12, +0.16 em, in gold.
  static final TextStyle unit = _head(12, 0.16);

  /// `.av`: the avatar's initials, 13, +0.02 em.
  static final TextStyle initials = _head(13, 0.02);

  // The platform face.
  /// `.rt b`.
  static final TextStyle rowTitle = _body(15, weight: FontWeight.w500);

  /// `.val`.
  static final TextStyle rowValue = _body(15);

  /// `.rt span`.
  static final TextStyle rowSub = _body(13);

  /// A subtitle allowed to wrap (`.rt.multi span`): line-height 1.4.
  static final TextStyle rowSubMulti = _body(13, height: 1.4);

  /// The stepper's count (`.stepper b`): Montserrat 600, 15.
  static final TextStyle stepperValue = _head(15, 0);

  /// `.glabel`.
  static final TextStyle groupLabel = _body(13, weight: FontWeight.w500);

  /// `.btn`.
  static final TextStyle button = _body(16, weight: FontWeight.w600);

  /// `.btn.sm`.
  static final TextStyle buttonSmall = _body(14, weight: FontWeight.w600);

  /// `.chip`.
  static final TextStyle chip = _body(12.5, weight: FontWeight.w500);

  /// `.pill`.
  static final TextStyle pill = _body(13, weight: FontWeight.w500);

  /// `.tag`.
  static final TextStyle tag = _body(11.5, weight: FontWeight.w500);

  /// `.toast`.
  static final TextStyle toast = _body(14.5);

  /// `.toast .ta`.
  static final TextStyle toastAction = _body(14.5, weight: FontWeight.w600);

  /// Running text; the frames use 1.4 to 1.45 (`.need p`, `.hint`, `.lead`).
  static final TextStyle body = _body(15, height: 1.4);

  /// `.back`.
  static final TextStyle navLink = _body(16);

  /// `.tab`: the tab bar label.
  static final TextStyle tabLabel = _body(10.5, weight: FontWeight.w500);

  /// `.search`, `.val`, `.lnk`.
  static final TextStyle field = _body(15);

  /// `.sec button`.
  static final TextStyle sectionLink = _body(14, weight: FontWeight.w500);

  /// `.ra span`.
  static final TextStyle rowTrailSub = _body(12);

  // JetBrains Mono (400; tracking is CSS em × size).
  /// `.hero .a`: 40, line-height 1, -0.04 em.
  static const TextStyle amountOnPage = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 40,
    letterSpacing: -1.6,
    fontFeatures: _tabular,
    height: 1,
  );

  /// `.ra b`: 15, weight 400, -0.02 em.
  static const TextStyle rowAmount = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 15,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
    height: 1.3,
  );

  /// `.addr`: 14, line-height 1.55, -0.01 em.
  static const TextStyle address = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 14,
    letterSpacing: -0.14,
    fontFeatures: _tabular,
    height: 1.55,
  );
}
