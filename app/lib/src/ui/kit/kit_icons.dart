// SPDX-License-Identifier: Apache-2.0
/// The one line icon set of the redesign: Material's outlined and rounded glyphs, which the
/// app already ships (no icon package). A screen takes its icons from here, so one weight and
/// one style run through the whole phone. Add a name here before using a new glyph.
library;

import 'package:flutter/material.dart';

abstract final class KitIcons {
  // Navigation.
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData backLink = Icons.chevron_left_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData chevron = Icons.chevron_right_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData more = Icons.more_horiz_rounded;

  // Tab bar.
  static const IconData home = Icons.home_outlined;
  static const IconData homeOn = Icons.home_rounded;
  static const IconData activity = Icons.receipt_long_outlined;
  static const IconData activityOn = Icons.receipt_long_rounded;
  static const IconData contacts = Icons.people_outline_rounded;
  static const IconData contactsOn = Icons.people_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsOn = Icons.settings_rounded;

  // Actions.
  static const IconData scan = Icons.qr_code_scanner_rounded;
  static const IconData qr = Icons.qr_code_2_rounded;
  static const IconData send = Icons.north_east_rounded;
  static const IconData receive = Icons.south_west_rounded;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData paste = Icons.content_paste_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData swap = Icons.swap_vert_rounded;
  static const IconData backspace = Icons.backspace_outlined;
  static const IconData fingerprint = Icons.fingerprint_rounded;
  static const IconData check = Icons.check_rounded;

  // Things.
  static const IconData security = Icons.shield_outlined;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData network = Icons.public_rounded;
  static const IconData outputs = Icons.grid_view_rounded;
  static const IconData backup = Icons.cloud_upload_outlined;
  static const IconData devices = Icons.devices_other_rounded;
  static const IconData bell = Icons.notifications_none_rounded;
  static const IconData language = Icons.translate_rounded;
  static const IconData palette = Icons.palette_outlined;
  static const IconData invoice = Icons.description_outlined;
  static const IconData contact = Icons.person_outline_rounded;

  // States, for toasts and notices.
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
}
