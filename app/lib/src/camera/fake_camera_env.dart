// SPDX-License-Identifier: Apache-2.0
/// `WFE_FAKE_CAMERA` from the process environment, for qr_camera.dart's `fakeCameraMode`.
library;

export 'fake_camera_env_io.dart' if (dart.library.js_interop) 'fake_camera_env_web.dart';
