// SPDX-License-Identifier: Apache-2.0
/// The web build's stand-in for `announcement_desk_io.dart`: no desktop there, so no system
/// browser and no desktop toast.
library;

import 'package:flutter/widgets.dart' show BuildContext;

/// The web opens nothing from here.
Future<bool> announcementOpenInBrowser(String url) async => false;

/// The dense (desktop) card is not shown on the web.
void showAnnouncementDeskToast(BuildContext context, String note, {required String url, required String copyLabel}) {}
