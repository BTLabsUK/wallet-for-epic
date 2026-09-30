/// The app's log. UI lines are redacted here ([redact]), then handed to the Rust core, which
/// redacts them again and writes them with its own lines to one rotating file,
/// `<application support>/logs/wfe.log` (`rust/src/core/logging.rs`: 2 files of 1 MB, logcat on
/// Android). Before the core is loaded, and in widget tests, lines stay in memory.
///
/// Log one fact per line, and never a secret: no PIN, password, phrase, seed, slate, token or
/// full address. Redaction is the safety net, not the plan.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'redact.dart';
import 'rust/api/diagnostics.dart' as rust;

export 'rust/api/diagnostics.dart' show LogLevel;

/// Where log lines go.
abstract interface class LogSink {
  void write(rust.LogLevel level, String tag, String message);

  /// The newest [maxBytes] of the log, from a whole line on.
  Future<String> tail(int maxBytes);
}

/// Keeps the newest [capacity] lines in memory. The sink before the core is loaded, and the one
/// widget tests read.
class MemoryLogSink implements LogSink {
  MemoryLogSink({this.capacity = 500});

  final int capacity;
  final List<({DateTime at, rust.LogLevel level, String tag, String message})>
  entries = [];

  List<String> get lines => [
    for (final e in entries)
      '${e.at.toUtc().toIso8601String()} ${e.level.name.toUpperCase()} '
          'dart.${e.tag}: ${e.message}',
  ];

  @override
  void write(rust.LogLevel level, String tag, String message) {
    entries.add((at: DateTime.now(), level: level, tag: tag, message: message));
    if (entries.length > capacity) entries.removeAt(0);
  }

  @override
  Future<String> tail(int maxBytes) async {
    final out = <String>[];
    var bytes = 0;
    for (final line in lines.reversed) {
      bytes += line.length + 1;
      if (bytes > maxBytes) break;
      out.add(line);
    }
    return out.reversed.map((l) => '$l\n').join();
  }
}

/// The core's log file. Needs `RustLib.init()` first.
class RustLogSink implements LogSink {
  const RustLogSink();

  @override
  void write(rust.LogLevel level, String tag, String message) =>
      rust.logMessage(level: level, tag: tag, message: message);

  @override
  Future<String> tail(int maxBytes) => rust.readLogTail(maxBytes: maxBytes);
}

/// The process-wide log. Error handlers run outside any widget, so this is a static rather
/// than a provider; [feedbackLogProvider] hands the sink to the feedback screen.
abstract final class AppLog {
  static LogSink _sink = MemoryLogSink();

  static LogSink get sink => _sink;

  /// Switches to [sink], handing over what the memory sink held.
  static void use(LogSink sink) {
    final previous = _sink;
    _sink = sink;
    if (previous is MemoryLogSink && !identical(previous, sink)) {
      for (final e in previous.entries) {
        sink.write(e.level, e.tag, e.message);
      }
      previous.entries.clear();
    }
  }

  static void write(rust.LogLevel level, String tag, String message) {
    try {
      _sink.write(level, tag, redact(message));
    } catch (error) {
      // Logging must never break the caller; the console is the last resort.
      if (kDebugMode) debugPrint('log write failed: $error');
    }
  }
}

void logInfo(String tag, String message) =>
    AppLog.write(rust.LogLevel.info, tag, message);

void logWarn(String tag, String message) =>
    AppLog.write(rust.LogLevel.warn, tag, message);

/// Logs [error] with the top of [stack].
void logError(String tag, Object error, [StackTrace? stack]) {
  final top = stack?.toString().trimRight().split('\n').take(8).join('\n');
  AppLog.write(
    rust.LogLevel.error,
    tag,
    top == null || top.isEmpty ? '$error' : '$error\n$top',
  );
}

/// Starts the log file under `<application support>/logs`. Call after `RustLib.init()`. A
/// failure keeps lines in the core's memory and in logcat, and is itself logged.
Future<void> startLogging() async {
  AppLog.use(const RustLogSink());
  try {
    final support = await getApplicationSupportDirectory();
    await rust.initLogging(dir: '${support.path}${Platform.pathSeparator}logs');
  } catch (error) {
    logWarn('log', 'no log file: $error');
  }
}
