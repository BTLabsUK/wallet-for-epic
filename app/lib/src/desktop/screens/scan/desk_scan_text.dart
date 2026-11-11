// SPDX-License-Identifier: Apache-2.0
/// What a screen needs from a text scan: the text, and whether the camera read it.
library;

import '../../../scan/scan_checks.dart' show CodeOrigin;
import 'desk_scan.dart';

extension DeskScanTextResult on DeskScanResult<String> {
  /// The code's text, trimmed (camera or pasted).
  String get scanText => switch (this) {
    DeskScanned<String>(:final value) => value.trim(),
    DeskPasted<String>(:final text) => text.trim(),
  };

  /// The origin the text goes down the paste path with: qr from the camera, paste otherwise.
  CodeOrigin get origin => this is DeskScanned<String> ? CodeOrigin.qr : CodeOrigin.paste;
}
