// SPDX-License-Identifier: Apache-2.0
/// "The app stopped responding last time. Send the log?": a session that ended in a freeze, a
/// crash or a kill is noticed at the next start, its log kept aside, and offered once, after
/// unlock, as a problem report (`feedback.dart`), so a frozen app can still be reported.
///
/// Off the web, `last_session_io.dart`: a marker in `logs/` while the app runs, Android's own
/// record of how the last process ended (ANR, crash), and the kept log in
/// `logs/last-session/`. A page has no file and no last session (`last_session_web.dart`).
library;

export 'last_session_types.dart';
export 'last_session_io.dart' if (dart.library.js_interop) 'last_session_web.dart';
