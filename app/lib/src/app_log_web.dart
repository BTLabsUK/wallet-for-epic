/// `app_log.dart` in the browser: a page has no file to write, so the log stays in memory for
/// the life of the tab, redacted at the call as everywhere (`AppLog` in `log.dart`), and is gone
/// on reload. Nothing goes to the browser console, which any extension or shared screen can
/// read.
library;

import 'log.dart';

export 'log.dart';

/// Lines the web log keeps, the newest ones. Enough for a feedback report's tail.
const int webLogLines = 2000;

/// Switches to the web's [MemoryLogSink], handing over the lines logged so far.
Future<void> startLogging() async {
  AppLog.use(MemoryLogSink(capacity: webLogLines));
}

/// The size at which the desktop log file rolls over; a page has no file, so only the
/// desktop Logs screen reads it.
const int maxLogFileBytes = 1024 * 1024;

/// Placeholder for `app_log_io.dart`'s file sink, so the desktop code compiles for the web.
/// Never constructed here.
class FileLogSink extends MemoryLogSink {
  ({String path}) get dir => (path: '');

  void clear() => entries.clear();
}
