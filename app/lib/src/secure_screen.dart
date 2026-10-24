import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/secure_screen');

/// While [secure] is true: on Android, blocks screenshots, screen recording and the recent-apps
/// preview (FLAG_SECURE, every API level); on iOS, covers the window whenever the app is
/// inactive, so the app switcher's snapshot shows nothing (iOS cannot block screenshots).
///
/// Unused since 26.10.6: the recovery phrase screens allow screenshots and Copy. Kept for a
/// screen that must stay private.
///
/// A no-op elsewhere. Failures are ignored: the phrase must still be shown.
Future<void> setSecureScreen(bool secure) => _call('setSecure', secure);

Future<void> _call(String method, bool on) async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  try {
    await _channel.invokeMethod<void>(method, on);
  } on MissingPluginException {
    // Not running inside MainActivity, e.g. in widget tests.
  } on PlatformException {
    // Ignored for the same reason.
  }
}
