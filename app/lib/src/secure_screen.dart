import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/secure_screen');

/// Blocks screenshots and the recent-apps preview on Android while [secure] is true.
///
/// A no-op elsewhere. Failures are ignored: the phrase must still be shown.
Future<void> setSecureScreen(bool secure) => _call('setSecure', secure);

/// Keeps the screen out of the recent-apps preview on Android 13+ while [hidden] is true, and
/// still allows screenshots. A no-op elsewhere, and failures are ignored.
Future<void> hideRecentsPreview(bool hidden) => _call('hidePreview', hidden);

Future<void> _call(String method, bool on) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _channel.invokeMethod<void>(method, on);
  } on MissingPluginException {
    // Not running inside MainActivity, e.g. in widget tests.
  } on PlatformException {
    // Ignored for the same reason.
  }
}
