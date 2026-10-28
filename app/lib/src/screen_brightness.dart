// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart' as plugin;

/// The screen at full brightness while a payment QR code shows, so the other phone's camera
/// reads it: [holdFullBrightness] when the code appears, [releaseBrightness] when it hides,
/// the screen closes or the app goes to the background. The plugin sets the app window's
/// brightness only (Android `WindowManager.LayoutParams.screenBrightness`, iOS the screen's
/// brightness restored on reset), never the phone's setting, and the reset puts the user's
/// level back.
///
/// A no-op on the web and the desktops, and in tests (no plugin); failures are ignored: the
/// code must still show.
abstract final class QrBrightness {
  static bool _held = false;

  /// For tests: how many times the brightness was held and released.
  @visibleForTesting
  static int holds = 0;
  @visibleForTesting
  static int releases = 0;

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Full brightness until [releaseBrightness]. Holding twice is one hold.
  static Future<void> holdFullBrightness() async {
    if (_held) return;
    _held = true;
    holds++;
    if (!_supported) return;
    try {
      await plugin.ScreenBrightness.instance.setApplicationScreenBrightness(1);
    } catch (_) {
      // The plugin is missing (a test) or the phone refused: the code shows at the level it has.
    }
  }

  /// Back to the user's level. Nothing when not held.
  static Future<void> releaseBrightness() async {
    if (!_held) return;
    _held = false;
    releases++;
    if (!_supported) return;
    try {
      await plugin.ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // As above.
    }
  }
}
