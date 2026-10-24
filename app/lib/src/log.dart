/// The log calls, without Flutter or `dart:io`: levels, the [LogSink] interface, the memory
/// sink, the process-wide [AppLog] with redaction at the call, and [logInfo], [logWarn] and
/// [logError]. The wallet core (`lepic_wallet_service.dart`) logs through this file alone, so it
/// also runs in a plain `dart run` and in the demo server.
///
/// The file sink, logcat and `path_provider` are in `app_log.dart`, which re-exports this file.
///
/// Log one fact per line, and never a secret: no PIN, password, phrase, seed, slate, token or
/// full address. Redaction is the safety net, not the plan.
library;

import 'dart:convert';

import 'redact.dart';

/// Severity of a log line. `debug` is written only while [AppLog.detailed] is on.
enum LogLevel { error, warn, info, debug }

/// Longer messages are cut.
const int maxLogMessageBytes = 4096;

/// Prefix of the targets of the app's own lines.
const String dartTarget = 'dart';

/// Where log lines go. [record] takes a full target; [write] is the app's `dart.<tag>`.
abstract class LogSink {
  void record(LogLevel level, String target, String message);

  /// The newest [maxBytes] of the log, from a whole line on.
  Future<String> tail(int maxBytes);

  /// The log's files, newest first, with their sizes; none for a sink without files.
  Future<List<LogFileInfo>> files() async => const [];

  void write(LogLevel level, String tag, String message) =>
      record(level, '$dartTarget.${_cleanTag(tag)}', message);
}

/// Letters, digits and `_`, at most 32.
String _cleanTag(String tag) {
  final kept = tag.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
  return kept.length > 32 ? kept.substring(0, 32) : kept;
}

/// One file of the log: `wfe.log` or `wfe.log.1`, and its size.
class LogFileInfo {
  const LogFileInfo(this.name, this.bytes);

  final String name;
  final int bytes;
}

/// Whether [level] lines from [target] are written. While [AppLog.detailed] is on, everything
/// is; otherwise `info` only from the app and LEPIC, and no `debug`.
bool logPasses(LogLevel level, String target) {
  if (AppLog.detailed) return true;
  if (level == LogLevel.debug) return false;
  bool ours(String prefix) =>
      target == prefix ||
      target.startsWith('$prefix.') ||
      target.startsWith('$prefix::') ||
      target.startsWith('${prefix}_');
  return ours(dartTarget) || ours('lepic') || level != LogLevel.info;
}

/// One line as the file holds it: `2026-10-01T00:22:20.700Z INFO  dart.unlock: message`, with
/// later lines of a multi-line message indented by four spaces.
String formatLogLine(
  DateTime at,
  LogLevel level,
  String target,
  String message,
) {
  final body = shortenLogMessage(message).replaceAll('\n', '\n    ');
  return '${logTimestamp(at)} ${level.name.toUpperCase().padRight(5)} '
      '$target: $body\n';
}

/// [at] in UTC to the millisecond, `2026-10-01T00:22:20.700Z`.
String logTimestamp(DateTime at) {
  final u = at.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}.'
      '${u.millisecond.toString().padLeft(3, '0')}Z';
}

/// [message] cut to [maxLogMessageBytes] of UTF-8, ending in `…` when it was cut.
String shortenLogMessage(String message) {
  final bytes = utf8.encode(message);
  if (bytes.length <= maxLogMessageBytes) return message;
  final cut = utf8.decode(
    bytes.sublist(0, maxLogMessageBytes),
    allowMalformed: true,
  );
  // A character split by the cut decodes to U+FFFD; drop it.
  return '${cut.replaceFirst(RegExp('\uFFFD\$'), '')}…';
}

/// Keeps the newest [capacity] lines in memory. The sink before `startLogging`, and the one
/// widget tests read.
class MemoryLogSink extends LogSink {
  MemoryLogSink({this.capacity = 500});

  final int capacity;
  final List<({DateTime at, LogLevel level, String target, String message})>
  entries = [];

  List<String> get lines => [
    for (final e in entries)
      formatLogLine(e.at, e.level, e.target, e.message).trimRight(),
  ];

  @override
  void record(LogLevel level, String target, String message) {
    if (!logPasses(level, target)) return;
    entries.add((
      at: DateTime.now(),
      level: level,
      target: target,
      message: message,
    ));
    if (entries.length > capacity) entries.removeAt(0);
  }

  @override
  Future<String> tail(int maxBytes) async {
    final out = <String>[];
    var bytes = 0;
    for (final line in lines.reversed) {
      bytes += utf8.encode(line).length + 1;
      if (bytes > maxBytes) break;
      out.add(line);
    }
    return out.reversed.map((l) => '$l\n').join();
  }
}

/// The process-wide log. Error handlers run outside any widget, so this is a static rather
/// than a provider; `feedbackLogProvider` hands the sink to the feedback screen.
abstract final class AppLog {
  static LogSink _sink = MemoryLogSink();

  /// Until when detailed logging is on, for troubleshooting: `debug` lines and `info` from
  /// every target; null is off. The app's lines switch at once and back by themselves at that
  /// time; LEPIC's runtime takes its level when it starts.
  static DateTime? detailedUntil;

  static bool get detailed {
    final until = detailedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  static LogSink get sink => _sink;

  /// Switches to [sink], handing over what the memory sink held.
  static void use(LogSink sink) {
    final previous = _sink;
    _sink = sink;
    if (previous is MemoryLogSink && !identical(previous, sink)) {
      for (final e in previous.entries) {
        sink.record(e.level, e.target, e.message);
      }
      previous.entries.clear();
    }
  }

  static void write(LogLevel level, String tag, String message) =>
      _guard(() => _sink.write(level, tag, redact(message)));

  static void record(LogLevel level, String target, String message) =>
      _guard(() => _sink.record(level, target, redact(message)));

  static void _guard(void Function() write) {
    try {
      write();
    } catch (error) {
      // Logging must never break the caller; in debug builds the console is the last resort.
      assert(() {
        // ignore: avoid_print
        print('log write failed: $error');
        return true;
      }());
    }
  }
}

/// Written only while Detailed is on ([AppLog.detailed]).
void logDebug(String tag, String message) =>
    AppLog.write(LogLevel.debug, tag, message);

void logInfo(String tag, String message) =>
    AppLog.write(LogLevel.info, tag, message);

void logWarn(String tag, String message) =>
    AppLog.write(LogLevel.warn, tag, message);

/// Logs [error] with the top of [stack].
void logError(String tag, Object error, [StackTrace? stack]) {
  final top = stack?.toString().trimRight().split('\n').take(8).join('\n');
  AppLog.write(
    LogLevel.error,
    tag,
    top == null || top.isEmpty ? '$error' : '$error\n$top',
  );
}

/// Fields of LEPIC's log vocabulary whose values say nothing about keys, amounts or addresses,
/// as LEPIC's own log ring keeps them (`lepic-telemetry/src/mobile.rs`, `KEPT_FIELDS`), and
/// the HTTP listener's `port` and `exposure` (local or public), the user's own settings. Any
/// other field is written as `[redacted]`, and `error` through [redactQuoted].
const Set<String> lepicKeptFields = {
  'wallet',
  'account',
  'tx_id',
  'slate_id',
  'stage',
  'codec',
  'transport',
  'relay',
  'node',
  'msg_id',
  'height',
  'attempt',
  'elapsed_ms',
  'retry_in_ms',
  'code',
  'port',
  'exposure',
  'error',
  'tag',
};

/// [error] with every span quoted with `"` or `` ` `` replaced by `[redacted]`, as LEPIC's
/// ring does (`redact_quoted` in `lepic-telemetry/src/mobile.rs`): decoder errors quote the
/// input they rejected, which may be an amount or an address. An unclosed quote redacts the
/// rest; inside `"`, `\"` does not close it.
String redactQuoted(String error) {
  final out = StringBuffer();
  final chars = error.runes.iterator;
  while (chars.moveNext()) {
    final c = chars.current;
    out.writeCharCode(c);
    if (c != 0x22 && c != 0x60) continue;
    out.write(redacted);
    var escaped = false;
    while (chars.moveNext()) {
      final inner = chars.current;
      if (inner == c && !escaped) {
        out.writeCharCode(c);
        break;
      }
      escaped = c == 0x22 && inner == 0x5c && !escaped;
    }
  }
  return out.toString();
}
