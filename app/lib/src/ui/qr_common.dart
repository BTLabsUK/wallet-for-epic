// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The rounded square [rect] with corner radius [radius], as a closed path that starts at the
/// top centre and runs clockwise. The time line of the show screen and the segment ring of the
/// scan screen follow it.
Path roundedSquarePath(Rect rect, double radius) {
  final r = Radius.circular(radius);
  return Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right - radius, rect.top)
    ..arcToPoint(Offset(rect.right, rect.top + radius), radius: r)
    ..lineTo(rect.right, rect.bottom - radius)
    ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: r)
    ..lineTo(rect.left + radius, rect.bottom)
    ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: r)
    ..lineTo(rect.left, rect.top + radius)
    ..arcToPoint(Offset(rect.left + radius, rect.top), radius: r)
    ..close();
}

/// Keeps the QR screens in portrait: they are not designed for landscape. Counted, so the
/// scanner opened over the show screen does not free the orientation when it closes.
class PortraitLock {
  PortraitLock._();

  static int _holders = 0;

  static void hold() {
    if (_holders++ == 0) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  static void release() {
    if (_holders > 0 && --_holders == 0) {
      // An empty list gives the phone's own choice back.
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
    }
  }
}

/// A haptic tap that never fails a screen: phones without a vibrator, tests and the web
/// answer with an error or nothing.
Future<void> tap(Future<void> Function() haptic) async {
  try {
    await haptic();
  } catch (_) {
    // No haptics here.
  }
}
