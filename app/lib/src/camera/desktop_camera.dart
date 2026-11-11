// SPDX-License-Identifier: Apache-2.0
/// The desktop QR camera (Linux, macOS, Windows) as the rest of the app sees it: its picture
/// checks and the two makers. The camera itself is in `desktop_qr_camera.dart`, which needs
/// `dart:io` and `dart:ffi`; the web build gets `desktop_camera_stub.dart` instead.
library;

import '../settings_file/host_settings.dart' show AppConfig;
import '../ui/qr_camera.dart' show QrCamera;
import 'camera_presence.dart' show CameraProbe;
import 'desktop_camera_stub.dart' if (dart.library.io) 'desktop_qr_camera.dart' as impl;

/// How long the desktop camera waits before it says No picture or Dark (`[camera]` of
/// `app-config.toml`).
class DesktopCameraTimings {
  const DesktopCameraTimings({
    this.firstFrame = const Duration(milliseconds: 6000),
    this.stall = const Duration(milliseconds: 3000),
    this.frozen = const Duration(milliseconds: 5000),
    this.dark = const Duration(milliseconds: 3000),
  });

  DesktopCameraTimings.of(AppConfig config)
    : firstFrame = config.cameraFirstFrame,
      stall = config.cameraStall,
      frozen = config.cameraFrozen,
      dark = config.cameraDark;

  /// From the start to the first frame.
  final Duration firstFrame;

  /// Between two frames.
  final Duration stall;

  /// The same picture, frame after frame.
  final Duration frozen;

  /// A black picture before it counts as Dark.
  final Duration dark;
}

/// The camera of one desktop scan screen.
QrCamera createDesktopQrCamera(DesktopCameraTimings timings) => impl.createDesktopQrCamera(timings);

/// The desktop probe: lists the cameras, never opens one.
CameraProbe createDesktopCameraProbe() => impl.createDesktopCameraProbe();
