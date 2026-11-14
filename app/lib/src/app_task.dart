// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('epic_wallet/app_task');

/// Back on Home. On Android the app goes to the background, as the system does for an app's
/// first screen since Android 12: finishing the activity would end the Flutter engine while
/// the wallet core, which lives as long as the process, still holds the wallet open, and the
/// next engine could not open it again ("still finishing a task"). Elsewhere, or with an older
/// app build, the system pops as before.
Future<void> leaveApp() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      if (await _channel.invokeMethod<bool>('toBack') == true) return;
    } on MissingPluginException {
      // An app build without the channel.
    } on PlatformException {
      // As above.
    }
  }
  await SystemNavigator.pop();
}
