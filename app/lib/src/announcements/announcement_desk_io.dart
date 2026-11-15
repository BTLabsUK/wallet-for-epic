// SPDX-License-Identifier: Apache-2.0
/// The desktop's part of the announcement card: the system browser and the desktop toast. The
/// web build takes `announcement_desk_web.dart` instead, so it does not compile the desktop.
library;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart' show BuildContext;

import '../desktop/data/files.dart' show openInBrowser;
import '../desktop/widgets/kit.dart' show ETone, showEToast;

/// Opens [url] in the desktop's browser.
Future<bool> announcementOpenInBrowser(String url) => openInBrowser(url);

/// [note] as a desktop warning toast with [copyLabel], which copies [url].
void showAnnouncementDeskToast(BuildContext context, String note, {required String url, required String copyLabel}) {
  showEToast(context, note, text: url, tone: ETone.warn, action: (label: copyLabel, run: () {
    Clipboard.setData(ClipboardData(text: url));
  }));
}
