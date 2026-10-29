// SPDX-License-Identifier: Apache-2.0
/// The settings text's home on this platform: the data folder's `settings.toml`, or on the web
/// a key in the app's store.
library;

export 'settings_platform_io.dart' if (dart.library.js_interop) 'settings_platform_web.dart';
