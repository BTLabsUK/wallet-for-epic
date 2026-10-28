// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/secure_screen');

/// While [secure] is true: on Android, blocks screenshots, screen recording and the recent-apps
/// preview (FLAG_SECURE, every API level); on iOS, covers the window whenever the app is
/// inactive, so the app switcher's snapshot shows nothing (iOS cannot block screenshots).
///
/// Used by a screen that must stay private: the payment QR. The recovery phrase screens allow
/// screenshots and Copy (since 26.10.6: most people keep the phrase as a screenshot, after the
/// warning the backup screen shows) and only hide the app switcher's preview ([hidePreview]).
///
/// A no-op elsewhere. Failures are ignored: the phrase must still be shown.
Future<void> setSecureScreen(bool secure) => _call('setSecure', secure);

/// While [hide] is true the recent-apps preview of the app is blank, while screenshots stay
/// allowed: Android 13+ (setRecentsScreenshotEnabled); iOS covers the window while the app is
/// inactive, as for [setSecureScreen]. A no-op elsewhere; failures are ignored.
Future<void> hidePreview(bool hide) => _call('hidePreview', hide);

/// Copies [text] as sensitive clipboard content on Android: Android 13+ hides it from the
/// clipboard preview, and keyboards that keep a clipboard history (Gboard) leave it out. False
/// where that is not possible (other systems, an older app build), so the caller copies plainly.
Future<bool> copySensitiveText(String text) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await _channel.invokeMethod<bool>('copySensitive', text) ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

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
