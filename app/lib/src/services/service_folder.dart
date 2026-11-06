// SPDX-License-Identifier: Apache-2.0
/// The folder a user may drop service files into. Off the web, `service_folder_io.dart`; the
/// browser has no folder.
library;

export 'service_folder_io.dart' if (dart.library.js_interop) 'service_folder_web.dart';
