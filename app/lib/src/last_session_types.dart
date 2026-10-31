// SPDX-License-Identifier: Apache-2.0
/// What `last_session.dart` hands the UI and the report, without `dart:io`.
library;

import 'log.dart';

/// How the last session ended, as the notice words it.
enum LastSessionEnd {
  /// Android's ANR: the app stopped responding and was closed.
  froze,

  /// A crash, a native crash, or a session that never closed (killed, power lost).
  closed,
}

/// The last session's log as it was kept at this start, for a report.
class LastSessionLog {
  const LastSessionLog({
    required this.end,
    required this.cause,
    this.endedAt,
    this.version,
    this.ring,
    this.log,
    this.trace,
  });

  final LastSessionEnd end;

  /// For the report's facts: `anr`, `crash`, `native crash` or `not closed`.
  final String cause;

  /// When Android says the process ended; null where only the marker tells.
  final DateTime? endedAt;

  /// The app version the last session ran.
  final String? version;

  /// LEPIC's log ring as it was at the end, oldest file first; null without one.
  final List<LogRingFile>? ring;

  /// The tail of `wfe.log` as it was at the end, redacted as `FileLogSink.tail` gives it.
  final String? log;

  /// Android's account of the end: its description and, for an ANR, the threads' stacks.
  final String? trace;
}

/// The kept last session as the notice and the report see it (`LastSession` off the web).
abstract interface class LastSessionSource {
  /// A kept log not yet offered: the notice is due.
  bool get due;

  /// Marks the kept log offered, so the notice never shows again for it.
  void offered();

  /// The kept log, for a report; null when there is none or it cannot be read.
  Future<LastSessionLog?> read();

  /// Marks this session ended cleanly (the desktop's close).
  void clean();
}
