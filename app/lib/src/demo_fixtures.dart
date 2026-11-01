// SPDX-License-Identifier: Apache-2.0
/// Values every demo, mock and screenshot fixture shares, on the phone and the desktop, so the
/// screens agree: the network tip, the node version and uptime, and the version an update offers.
/// Sample heights are written as the tip less a distance; no fixture names its own.
library;

import 'app_version.dart';

/// The demo network's tip.
const int demoTip = 3764975;

/// The node software version every demo node reports (the released one).
const String demoNodeVersion = '4.1.1';

/// The 24-hour uptime every demo node reports, as the status site gives it (99.7 %).
const double demoNodeUptime = 0.997;

/// The version a demo update offers: this build's next patch, so it is always newer (the updater
/// offers nothing that is not newer than the running version: `isNewerVersion`).
String get demoUpdateVersion {
  final parts = appVersion.split('-').first.split('.');
  final patch = int.tryParse(parts.last) ?? 0;
  return [...parts.take(parts.length - 1), '${patch + 1}'].join('.');
}
