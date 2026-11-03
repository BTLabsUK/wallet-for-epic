// SPDX-License-Identifier: Apache-2.0
/// Values every mock, preview and screenshot fixture shares, on the phone and the desktop, so the
/// screens agree: the network tip, the node version and uptime, and the version an update offers.
/// Sample heights are written as the tip less a distance; no fixture names its own.
library;

import 'app_version.dart';

/// The fixtures' network tip.
const int mockTip = 3764975;

/// The node software version every mock node reports (the released one).
const String mockNodeVersion = '4.1.1';

/// The 24-hour uptime every mock node reports, as the status site gives it (99.7 %).
const double mockNodeUptime = 0.997;

/// The version a mock update offers: this build's next patch, so it is always newer (the updater
/// offers nothing that is not newer than the running version: `isNewerVersion`).
String get mockUpdateVersion {
  final parts = appVersion.split('-').first.split('.');
  final patch = int.tryParse(parts.last) ?? 0;
  return [...parts.take(parts.length - 1), '${patch + 1}'].join('.');
}
