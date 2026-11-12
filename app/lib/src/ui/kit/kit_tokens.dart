// SPDX-License-Identifier: Apache-2.0
/// The phone redesign's sizes, radii, spaces and type (HANDOFF 5.3 and 5.4), in one place. A
/// screen or a kit part reads a value from here and never writes a literal size, radius or font
/// size. Colours are [WalletTokens] (`ui/theme/tokens.dart`).
library;

import 'package:flutter/material.dart';

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
  static const double stepperWidth = 128;
  static const double stepperHeight = 44;

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

/// The type of the redesign. Montserrat for figures and titles, the platform face for rows and
/// buttons, JetBrains Mono for amounts and addresses. Colour is left to the caller (a part
/// copies the style with its colour). Figures are tabular.
abstract final class KitType {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _head(double size, double tracking, {FontWeight weight = FontWeight.w600, double? height}) => TextStyle(
    fontFamily: montserrat,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * tracking,
    height: height,
    fontFeatures: _tabular,
  );

  /// Home balance, 50 (the fraction at [homeBalanceFraction] of it).
  static final TextStyle homeBalance = _head(50, -0.03, height: 1.05);
  static const double homeBalanceFraction = 0.42;

  /// Amount entry, 68; [amountEntryLong] when the figure is long.
  static final TextStyle amountEntry = _head(68, -0.035, height: 1.05);
  static final TextStyle amountEntryLong = _head(50, -0.035, height: 1.1);
  static final TextStyle tabTitle = _head(30, -0.025, height: 1.15);
  static final TextStyle pageTitle = _head(28, -0.025, height: 1.15);
  static final TextStyle flowTitle = _head(17, -0.01);
  static final TextStyle sheetTitle = _head(20, -0.01, height: 1.2);
  static final TextStyle sectionHead = _head(18, -0.015, height: 1.2);
  static final TextStyle keypad = _head(26, 0);

  /// The EPIC unit: 12, +0.16 em, in gold.
  static final TextStyle unit = _head(12, 0.16);

  /// The Max pill, "Available" figures and the avatar's initials share a small head face.
  static final TextStyle initials = _head(13, 0);

  // The platform face.
  static const TextStyle rowTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.25);
  static const TextStyle rowSub = TextStyle(fontSize: 13, height: 1.3);
  static const TextStyle groupLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3);
  static const TextStyle button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2);
  static const TextStyle buttonSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);
  static const TextStyle chip = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.2);
  static const TextStyle pill = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2);
  static const TextStyle tag = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.2);
  static const TextStyle toast = TextStyle(fontSize: 14.5, height: 1.3);
  static const TextStyle toastAction = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle body = TextStyle(fontSize: 15, height: 1.4);
  static const TextStyle navLink = TextStyle(fontSize: 16, height: 1.2);

  // JetBrains Mono.
  static const TextStyle amountOnPage = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 40,
    letterSpacing: -1.6,
    fontFeatures: _tabular,
    height: 1.1,
  );
  static const TextStyle rowAmount = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
    height: 1.25,
  );
  static const TextStyle address = TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 14,
    fontFeatures: _tabular,
    height: 1.4,
  );
}
