// SPDX-License-Identifier: Apache-2.0
/// The one line icon set of the redesign: Lucide (ISC, lucide-static 1.72.0), the set the designer's
/// frames draw, bundled as the icon font `Lucide` (assets/fonts/Lucide.ttf, a subset of the icons
/// named in tool/lucide_icons.txt; regenerate with tool/fonts_subset.py lucide). A screen takes
/// its icons from here, so one weight and one style run through the whole phone. Add a name to
/// tool/lucide_icons.txt and a getter here before using a new glyph; the codepoint is the one in
/// lucide-static's font/codepoints.json. The glyphs are stroke 2 outlines; the frames' 1.9 and
/// 2.2 strokes are not reproduced.
///
/// Not Lucide, and drawn elsewhere: the brand marks (BT logo, Apple), the QR pictures, the epic1
/// mark, the round progress rings and spinners, the status icons (EpicStatusIcons) and the
/// payment-method pictures.
library;

import 'package:flutter/widgets.dart';

abstract final class KitIcons {
  static const String family = 'Lucide';

  // Navigation.
  static const IconData back = IconData(0xe06e, fontFamily: family); // chevron-left
  static const IconData backLink = IconData(0xe06e, fontFamily: family); // chevron-left
  static const IconData close = IconData(0xe1b2, fontFamily: family); // x
  static const IconData chevron = IconData(0xe06f, fontFamily: family); // chevron-right
  static const IconData chevronDown = IconData(0xe06d, fontFamily: family); // chevron-down
  static const IconData chevronUp = IconData(0xe070, fontFamily: family); // chevron-up
  static const IconData expandLess = chevronUp;
  static const IconData help = IconData(0xe082, fontFamily: family); // circle-help
  static const IconData more = IconData(0xe0b6, fontFamily: family); // ellipsis

  // Tab bar. The frames draw the active tab in the same glyph, in gold; the On names stay for the call sites.
  static const IconData home = IconData(0xe0f5, fontFamily: family); // house
  static const IconData homeOn = IconData(0xe0f5, fontFamily: family); // house
  static const IconData activity = IconData(0xe106, fontFamily: family); // list
  static const IconData activityOn = IconData(0xe106, fontFamily: family); // list
  static const IconData contacts = IconData(0xe1a4, fontFamily: family); // users
  static const IconData contactsOn = IconData(0xe1a4, fontFamily: family); // users
  static const IconData settings = IconData(0xe154, fontFamily: family); // settings
  static const IconData settingsOn = IconData(0xe154, fontFamily: family); // settings

  // Actions.
  static const IconData scan = IconData(0xe258, fontFamily: family); // scan-line
  static const IconData qr = IconData(0xe1df, fontFamily: family); // qr-code
  static const IconData send = IconData(0xe04d, fontFamily: family); // arrow-up-right
  static const IconData external = IconData(0xe0b9, fontFamily: family); // external-link
  static const IconData receive = IconData(0xe043, fontFamily: family); // arrow-down-left
  static const IconData copy = IconData(0xe09e, fontFamily: family); // copy
  static const IconData paste = IconData(0xe085, fontFamily: family); // clipboard
  static const IconData share = IconData(0xe155, fontFamily: family); // share
  static const IconData add = IconData(0xe13d, fontFamily: family); // plus
  static const IconData remove = IconData(0xe11c, fontFamily: family); // minus
  static const IconData edit = IconData(0xe1f9, fontFamily: family); // pencil
  static const IconData delete = IconData(0xe18e, fontFamily: family); // trash-2
  static const IconData search = IconData(0xe151, fontFamily: family); // search
  static const IconData swap = IconData(0xe211, fontFamily: family); // chevrons-up-down
  static const IconData backspace = IconData(0xe0ae, fontFamily: family); // delete
  static const IconData fingerprint = IconData(0xe2cb, fontFamily: family); // fingerprint-pattern
  static const IconData check = IconData(0xe06c, fontFamily: family); // check
  static const IconData download = IconData(0xe0b2, fontFamily: family); // download
  static const IconData link = IconData(0xe102, fontFamily: family); // link
  static const IconData exchange = IconData(0xe24a, fontFamily: family); // arrow-left-right
  static const IconData fileUp = IconData(0xe32a, fontFamily: family); // file-up
  static const IconData fileDown = IconData(0xe318, fontFamily: family); // file-down

  // Things.
  static const IconData security = IconData(0xe158, fontFamily: family); // shield
  static const IconData lock = IconData(0xe10b, fontFamily: family); // lock
  static const IconData network = IconData(0xe0e8, fontFamily: family); // globe
  static const IconData outputs = IconData(0xe0ff, fontFamily: family); // layout-grid
  static const IconData backup = IconData(0xe091, fontFamily: family); // cloud-upload
  static const IconData devices = IconData(0xe3a2, fontFamily: family); // monitor-smartphone
  static const IconData bell = IconData(0xe059, fontFamily: family); // bell
  static const IconData language = IconData(0xe0fe, fontFamily: family); // languages
  static const IconData palette = IconData(0xe1dd, fontFamily: family); // palette
  static const IconData invoice = IconData(0xe0cc, fontFamily: family); // file-text
  static const IconData file = IconData(0xe0c0, fontFamily: family); // file
  static const IconData contact = IconData(0xe468, fontFamily: family); // user-round
  static const IconData addContact = IconData(0xe1a2, fontFamily: family); // user-plus
  static const IconData clock = IconData(0xe087, fontFamily: family); // clock
  static const IconData hourglass = IconData(0xe296, fontFamily: family); // hourglass
  static const IconData eye = IconData(0xe0ba, fontFamily: family); // eye
  static const IconData eyeOff = IconData(0xe0bb, fontFamily: family); // eye-off
  static const IconData bag = IconData(0xe15b, fontFamily: family); // shopping-bag
  static const IconData wallet = IconData(0xe204, fontFamily: family); // wallet
  static const IconData flag = IconData(0xe0d1, fontFamily: family); // flag
  static const IconData tools = IconData(0xe1b1, fontFamily: family); // wrench
  static const IconData code = IconData(0xe206, fontFamily: family); // code-xml
  static const IconData tuning = IconData(0xe29a, fontFamily: family); // sliders-horizontal
  static const IconData message = IconData(0xe117, fontFamily: family); // message-square
  static const IconData play = IconData(0xe080, fontFamily: family); // circle-play

  // States, for toasts and notices.
  static const IconData success = IconData(0xe226, fontFamily: family); // circle-check
  static const IconData info = IconData(0xe0f9, fontFamily: family); // info
  static const IconData warning = IconData(0xe193, fontFamily: family); // triangle-alert
  static const IconData error = IconData(0xe077, fontFamily: family); // circle-alert
}
