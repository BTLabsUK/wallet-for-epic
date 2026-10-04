/// The app's log: one rotating file, `<application support>/logs/wfe.log`, fed by the UI's own
/// calls ([logInfo], [logWarn], [logError]) and by LEPIC's `LepicRuntime.logs()` stream
/// ([logLepicEntry]). Every line goes through [redact] at the sink ([FileLogSink]). On Android
/// lines also go to logcat under the tag `wfe`; desktop debug builds copy them to stderr.
/// Before [startLogging], and in widget tests, lines stay in memory ([MemoryLogSink]).
///
/// Levels: `info` for the app (`dart.*` targets) and LEPIC (`lepic*` targets), `warn` for
/// anything else. Size: `wfe.log` grows to [maxLogFileBytes], then becomes `wfe.log.1`,
/// replacing the one before, so the log never takes more than 2 MB, and the 256 KB a feedback
/// report attaches always fits, even right after a rotation.
///
/// Log one fact per line, and never a secret: no PIN, password, phrase, seed, slate, token or
/// full address. Redaction is the safety net, not the plan.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:path_provider/path_provider.dart';

import 'redact.dart';

/// Severity of a log line. Nothing below `info` is written.
enum LogLevel { error, warn, info }

const String logFileName = 'wfe.log';

/// Size at which `wfe.log` becomes `wfe.log.1`.
const int maxLogFileBytes = 1024 * 1024;

/// Longer messages are cut.
const int maxLogMessageBytes = 4096;

/// Prefix of the targets of the app's own lines.
const String dartTarget = 'dart';

/// Where log lines go. [record] takes a full target; [write] is the app's `dart.<tag>`.
abstract class LogSink {
  void record(LogLevel level, String target, String message);

  /// The newest [maxBytes] of the log, from a whole line on.
  Future<String> tail(int maxBytes);

  void write(LogLevel level, String tag, String message) =>
      record(level, '$dartTarget.${_cleanTag(tag)}', message);
}

/// Letters, digits and `_`, at most 32.
String _cleanTag(String tag) {
  final kept = tag.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
  return kept.length > 32 ? kept.substring(0, 32) : kept;
}

/// Whether [level] lines from [target] are written.
bool logPasses(LogLevel level, String target) {
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
  final body = _shorten(message).replaceAll('\n', '\n    ');
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

String _shorten(String message) {
  final bytes = utf8.encode(message);
  if (bytes.length <= maxLogMessageBytes) return message;
  final cut = utf8.decode(
    bytes.sublist(0, maxLogMessageBytes),
    allowMalformed: true,
  );
  // A character split by the cut decodes to U+FFFD; drop it.
  return '${cut.replaceFirst(RegExp('\uFFFD\$'), '')}…';
}

/// The last [max] bytes of [bytes], from the first whole line in them. [bytes] holds at least
/// one byte more than [max] when it was cut, so a line that starts exactly at the limit is seen
/// as whole.
Uint8List _lastBytes(Uint8List bytes, int max) {
  if (bytes.length <= max) return bytes;
  final start = bytes.length - max;
  if (bytes[start - 1] == 0x0a) return Uint8List.sublistView(bytes, start);
  final line = bytes.indexOf(0x0a, start);
  return line < 0 ? Uint8List(0) : Uint8List.sublistView(bytes, line + 1);
}

Uint8List _readLast(File file, int max) {
  try {
    final raf = file.openSync();
    try {
      final len = raf.lengthSync();
      raf.setPositionSync(len > max ? len - max : 0);
      return raf.readSync(max);
    } finally {
      raf.closeSync();
    }
  } on FileSystemException {
    return Uint8List(0);
  }
}

/// Keeps the newest [capacity] lines in memory. The sink before [startLogging], and the one
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

/// Copies a written line elsewhere: logcat, stderr, or nowhere.
typedef LogMirror = void Function(LogLevel level, String target, String body);

/// `<dir>/wfe.log`, rotated to `wfe.log.1` at [maxBytes]. Redacts every line before it is
/// written or mirrored, and the tail once more, in case an older build wrote it.
class FileLogSink extends LogSink {
  FileLogSink._(this.dir, this.maxBytes, this._mirror, this._file, this._size);

  /// Opens or creates `<dir>/wfe.log` and carries on where it ended. Throws a
  /// [FileSystemException] when the directory cannot be created or the file opened.
  factory FileLogSink.open(
    Directory dir, {
    int maxBytes = maxLogFileBytes,
    LogMirror? mirror,
  }) {
    dir.createSync(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$logFileName')
        .openSync(mode: FileMode.append);
    return FileLogSink._(
      dir,
      maxBytes,
      mirror ?? platformLogMirror,
      file,
      file.lengthSync(),
    );
  }

  final Directory dir;
  final int maxBytes;
  final LogMirror _mirror;
  RandomAccessFile _file;
  int _size;

  File get file => File('${dir.path}${Platform.pathSeparator}$logFileName');
  File get previous => File('${file.path}.1');

  @override
  void record(LogLevel level, String target, String message) {
    if (!logPasses(level, target)) return;
    final clean = redact(message);
    _mirror(level, target, _shorten(clean).replaceAll('\n', '\n    '));
    final line = utf8.encode(
      formatLogLine(DateTime.now(), level, target, clean),
    );
    if (_size > 0 && _size + line.length > maxBytes) _rotate();
    _file.writeFromSync(line);
    _size += line.length;
  }

  /// Moves `wfe.log` to `wfe.log.1`. If that fails (a sharing violation on Windows, a
  /// scanner holding the file), it keeps writing to `wfe.log`, says so there, and tries again
  /// after another [maxBytes].
  void _rotate() {
    _file.closeSync();
    FileSystemException? failed;
    try {
      final old = previous;
      // Windows cannot rename over a file; remove it first.
      if (old.existsSync()) old.deleteSync();
      file.renameSync(old.path);
    } on FileSystemException catch (error) {
      failed = error;
    } finally {
      _file = file.openSync(mode: FileMode.append);
      _size = 0;
    }
    if (failed != null) {
      final line = utf8.encode(
        formatLogLine(
          DateTime.now(),
          LogLevel.warn,
          '$dartTarget.log',
          redact('rotation failed: ${failed.message} ${failed.osError ?? ''}'),
        ),
      );
      _file.writeFromSync(line);
      _size = line.length;
    }
  }

  /// The newest [maxBytes] across `wfe.log.1` and `wfe.log`, from a whole line on.
  @override
  Future<String> tail(int maxBytes) async {
    // One byte more than asked, so a cut inside a line is seen and dropped by _lastBytes.
    var bytes = _readLast(file, maxBytes + 1);
    if (bytes.length <= maxBytes) {
      final older = _readLast(previous, maxBytes - bytes.length + 1);
      bytes = Uint8List.fromList([...older, ...bytes]);
    }
    return redact(
      utf8.decode(_lastBytes(bytes, maxBytes), allowMalformed: true),
    );
  }

  void close() => _file.closeSync();
}

/// logcat tag `wfe` on Android, stderr in desktop debug builds, nothing otherwise.
void platformLogMirror(LogLevel level, String target, String body) {
  if (Platform.isAndroid) {
    _Logcat.instance?.write(level, '$target: $body');
  } else if (kDebugMode) {
    stderr.writeln('${level.name.toUpperCase().padRight(5)} $target: $body');
  }
}

/// `__android_log_write` from liblog, through dart:ffi, so lines carry the tag `wfe` rather
/// than Flutter's `flutter`.
final class _Logcat {
  _Logcat._(this._write, this._malloc, this._free);

  static final _Logcat? instance = _load();

  static _Logcat? _load() {
    try {
      final log = DynamicLibrary.open('liblog.so');
      final libc = DynamicLibrary.process();
      return _Logcat._(
        log.lookupFunction<
          Int32 Function(Int32, Pointer<Uint8>, Pointer<Uint8>),
          int Function(int, Pointer<Uint8>, Pointer<Uint8>)
        >('__android_log_write'),
        libc.lookupFunction<
          Pointer<Uint8> Function(IntPtr),
          Pointer<Uint8> Function(int)
        >('malloc'),
        libc.lookupFunction<
          Void Function(Pointer<Uint8>),
          void Function(Pointer<Uint8>)
        >('free'),
      );
    } catch (_) {
      return null;
    }
  }

  final int Function(int, Pointer<Uint8>, Pointer<Uint8>) _write;
  final Pointer<Uint8> Function(int) _malloc;
  final void Function(Pointer<Uint8>) _free;

  Pointer<Uint8> _cString(String text) {
    final bytes = utf8.encode(text.replaceAll('\x00', ' '));
    final p = _malloc(bytes.length + 1);
    p.asTypedList(bytes.length + 1)
      ..setAll(0, bytes)
      ..[bytes.length] = 0;
    return p;
  }

  void write(LogLevel level, String text) {
    final prio = switch (level) {
      LogLevel.error => 6,
      LogLevel.warn => 5,
      LogLevel.info => 4,
    };
    final tag = _cString('wfe');
    final body = _cString(text);
    try {
      _write(prio, tag, body);
    } finally {
      _free(tag);
      _free(body);
    }
  }
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
      // Logging must never break the caller; the console is the last resort.
      if (kDebugMode) debugPrint('log write failed: $error');
    }
  }
}

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
/// as LEPIC's own log ring keeps them (`lepic-telemetry/src/mobile.rs`, `KEPT_FIELDS`). Any
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

/// Logs one entry of `LepicRuntime.logs()` under its own target:
/// `lepic_wallet::send: slate received in send slate_id=… height=…`. Debug and trace entries
/// are dropped.
void logLepicEntry(lepic.LogEntry entry) {
  final level = switch (entry.level) {
    lepic.LogLevel.error => LogLevel.error,
    lepic.LogLevel.warn => LogLevel.warn,
    lepic.LogLevel.info => LogLevel.info,
    lepic.LogLevel.debug || lepic.LogLevel.trace => null,
  };
  if (level == null) return;
  final line = StringBuffer(entry.message);
  if (entry.spans.isNotEmpty) line.write(' in ${entry.spans.join('>')}');
  for (final field in entry.fields) {
    final value = field.name == 'error'
        ? redactQuoted(field.value)
        : lepicKeptFields.contains(field.name)
        ? field.value
        : redacted;
    line.write(' ${field.name}=$value');
  }
  AppLog.record(level, entry.target, line.toString());
}

/// Starts the log file under `<application support>/logs`, with the lines logged so far. A
/// failure keeps lines in memory, and is itself logged.
Future<void> startLogging() async {
  try {
    final support = await getApplicationSupportDirectory();
    AppLog.use(
      FileLogSink.open(
        Directory('${support.path}${Platform.pathSeparator}logs'),
      ),
    );
  } catch (error) {
    logWarn('log', 'no log file: $error');
  }
}
