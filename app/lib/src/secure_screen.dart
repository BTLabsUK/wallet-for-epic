import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/secure_screen');

/// Blocks screenshots and the recent-apps preview on Android while [secure] is true.
///
/// A no-op elsewhere. Failures are ignored: the phrase must still be shown.
Future<void> setSecureScreen(bool secure) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _channel.invokeMethod<void>('setSecure', secure);
  } on MissingPluginException {
    // Not running inside MainActivity, e.g. in widget tests.
  } on PlatformException {
    // Ignored for the same reason.
  }
}
