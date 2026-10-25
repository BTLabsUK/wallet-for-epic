import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/secure_screen');

/// While [secure] is true: on Android, blocks screenshots, screen recording and the recent-apps
/// preview (FLAG_SECURE, every API level); on iOS, covers the window whenever the app is
/// inactive, so the app switcher's snapshot shows nothing (iOS cannot block screenshots).
///
/// Used by a screen that must stay private: the payment QR. (The recovery phrase screens have
/// allowed screenshots and Copy since 26.10.6.)
///
/// A no-op elsewhere. Failures are ignored: the phrase must still be shown.
Future<void> setSecureScreen(bool secure) => _call('setSecure', secure);

/// While [on] is true the screen does not turn off by itself (Android FLAG_KEEP_SCREEN_ON, iOS
/// idle timer): a restore's chain scan keeps the network Android cuts once the app is away.
/// A no-op elsewhere; failures are ignored.
Future<void> keepScreenOn(bool on) => _call('keepScreenOn', on);

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

/// Opens this app's page in the phone's settings, where the camera can be allowed again.
/// False where it cannot be opened (the web, tests, a phone that refuses).
Future<bool> openAppSettings() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return false;
  }
  try {
    return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
