// SPDX-License-Identifier: Apache-2.0
/// The app's log sink, chosen by platform. Off the web, `app_log_io.dart`: the rotating file
/// `<application support>/logs/wfe.log`, logcat on Android, stderr in desktop debug builds. In
/// the browser, `app_log_web.dart`: the newest lines in memory, nothing written anywhere.
///
/// Both re-export `log.dart`, so callers in the UI keep importing this file alone.
library;

export 'app_log_io.dart' if (dart.library.js_interop) 'app_log_web.dart';
