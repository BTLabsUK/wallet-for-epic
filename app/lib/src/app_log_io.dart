// SPDX-License-Identifier: Apache-2.0
/// The app's log file: one rotating file, `<application support>/logs/wfe.log`, fed by the
/// calls in `log.dart` ([logInfo], [logWarn], [logError]) and by LEPIC's `LepicRuntime.logs()`
/// stream (`logLepicEntry` in `lepic_wallet_service.dart`). Every line goes through [redact] at
/// the sink ([FileLogSink]). On Android lines also go to logcat under the tag `wfe`; desktop
/// debug builds copy them to stderr. Before [startLogging], and in widget tests, lines stay in
/// memory ([MemoryLogSink]).
///
/// Levels: `info` for the app (`dart.*` targets) and LEPIC (`lepic*` targets), `warn` for
/// anything else. Size: `wfe.log` grows to [maxLogFileBytes], then becomes `wfe.log.1`,
/// replacing the one before, so the log never takes more than 2 MB, and the 256 KB a feedback
/// report attaches always fits, even right after a rotation.
///
/// LEPIC's log ring, which redacts at the source and is what a problem report attaches, is in
/// its own folder beside it, `logs/ring/` ([logRingFolder], [readLogRing], [clearLogRing]).
///
/// `app_log.dart` picks this file off the web. It re-exports `log.dart`.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'data_folder_io.dart' show appDataDirectory;

import 'log.dart';
import 'redact.dart';

export 'log.dart';

const String logFileName = 'wfe.log';

/// Size at which `wfe.log` becomes `wfe.log.1`.
const int maxLogFileBytes = 1024 * 1024;

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
    final clean = redact(message, details: AppLog.detailed);
    _mirror(level, target, shortenLogMessage(clean).replaceAll('\n', '\n    '));
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
    // What Detailed logging kept stays for the report to drop or keep ([cleanForReport]).
    return redact(
      utf8.decode(_lastBytes(bytes, maxBytes), allowMalformed: true),
      details: true,
    );
  }

  @override
  Future<List<LogFileInfo>> files() async => [
    for (final f in [file, previous])
      if (f.existsSync()) LogFileInfo(f.uri.pathSegments.last, f.lengthSync()),
  ];

  /// Empties `wfe.log` and deletes `wfe.log.1`. The next line starts a new file.
  void clear() {
    _file.closeSync();
    try {
      if (previous.existsSync()) previous.deleteSync();
    } on FileSystemException catch (_) {
      // Held by another program (Windows); it goes at the next rotation.
    } finally {
      _file = file.openSync(mode: FileMode.write);
      _size = 0;
    }
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
      LogLevel.debug => 3,
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

/// LEPIC's log ring's folder inside `logs/`. It holds the ring's files and nothing else.
const String logRingFolder = 'ring';

/// The ring's files, oldest first (LEPIC's `lepic.0.log` is the newest).
const List<String> logRingFiles = [
  'lepic.3.log',
  'lepic.2.log',
  'lepic.1.log',
  'lepic.0.log',
];

/// Starts the log file under `<application support>/logs`, with the lines logged so far, and
/// names `logs/ring/` for LEPIC's log ring ([AppLog.ringDir]). A failure keeps lines in memory,
/// and is itself logged.
Future<void> startLogging() async {
  try {
    final support = await appDataDirectory();
    final sep = Platform.pathSeparator;
    AppLog.ringDir = '${support.path}${sep}logs$sep$logRingFolder';
    AppLog.use(
      FileLogSink.open(
        Directory('${support.path}${Platform.pathSeparator}logs'),
      ),
    );
  } catch (error) {
    logWarn('log', 'no log file: $error');
  }
}

File _ringFile(String dir, String name) =>
    File('$dir${Platform.pathSeparator}$name');

/// LEPIC's log ring as a report attaches it: its files that hold lines, oldest first, at most
/// [logRingBytes] together, each from and to a whole line (LEPIC may be writing the newest).
/// Null where there is no ring ([AppLog.ringDir], the web, tests) or it holds no line yet.
Future<List<LogRingFile>?> readLogRing() async {
  final dir = AppLog.ringDir;
  if (dir == null) return null;
  final out = <LogRingFile>[];
  var left = logRingBytes;
  for (final name in logRingFiles.reversed) {
    if (left <= 0) break;
    // One byte more than asked, so a cut inside a line is seen and dropped by _lastBytes.
    final read = _readLast(_ringFile(dir, name), left + 1);
    var bytes = _lastBytes(read, left);
    final end = bytes.lastIndexOf(0x0a);
    bytes = Uint8List.sublistView(bytes, 0, end + 1);
    if (bytes.isNotEmpty) {
      out.insert(0, (name: name, text: utf8.decode(bytes, allowMalformed: true)));
    }
    // A file that did not fit whole is the oldest that goes: no gap before the newest lines.
    left = read.length > left ? 0 : left - bytes.length;
  }
  return out.isEmpty ? null : out;
}

/// Empties LEPIC's log ring with the log ("Clear logs"): the newest file, which LEPIC holds
/// open and appends to, is emptied in place; the older ones are deleted. Nothing else in the
/// folder is touched.
void clearLogRing() {
  final dir = AppLog.ringDir;
  if (dir == null) return;
  for (final name in logRingFiles) {
    final file = _ringFile(dir, name);
    try {
      if (!file.existsSync()) continue;
      if (name == logRingFiles.last) {
        file.writeAsBytesSync(const [], flush: true);
      } else {
        file.deleteSync();
      }
    } on FileSystemException catch (_) {
      // Held by another program (Windows); LEPIC's next rotation drops it.
    }
  }
}
