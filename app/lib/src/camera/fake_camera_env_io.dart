// SPDX-License-Identifier: Apache-2.0
/// `fake_camera_env.dart` off the browser.
library;

import 'dart:io';

/// The process environment's `WFE_FAKE_CAMERA`, or empty.
String fakeCameraEnv() => Platform.environment['WFE_FAKE_CAMERA'] ?? '';
