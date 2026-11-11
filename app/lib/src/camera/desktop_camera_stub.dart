// SPDX-License-Identifier: Apache-2.0
/// The web build's stand-in for `desktop_qr_camera.dart`: a browser has no desktop camera.
library;

import '../ui/qr_camera.dart' show QrCamera, QrCameraProblem, FakeQrCamera;
import 'camera_presence.dart' show CameraProbe, NoCameraProbe;
import 'desktop_camera.dart' show DesktopCameraTimings;

QrCamera createDesktopQrCamera(DesktopCameraTimings timings) => FakeQrCamera(problem: QrCameraProblem.unsupported, torchAvailable: false);

CameraProbe createDesktopCameraProbe() => const NoCameraProbe();
