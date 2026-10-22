/// Settings › Help › Logs: the log level (Normal, or Detailed for a day), the log's files, and
/// clearing them. The level is app-wide, saved under [logsKey] in [DeskStore].
///
/// LEPIC's runtime takes its level when it starts and has no setter, so Detailed reaches the
/// wallet core's lines only from the next start. That is why Detailed lasts 24 hours rather
/// than ending at a restart: a restart is what turns it on in the core.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_log_io.dart';
import 'desk_store.dart';

const String logsKey = 'desk.logs';

/// How long Detailed stays on.
const Duration detailedFor = Duration(hours: 24);

/// The saved level: Detailed until [until], else Normal.
class LogsState {
  const LogsState({this.until, this.coreDetailed = false});

  /// When Detailed ends; null is Normal.
  final DateTime? until;

  /// Whether LEPIC's runtime started at the detailed level (this run's, fixed).
  final bool coreDetailed;

  bool get detailed => until != null;

  /// The level a report names.
  String get label => detailed ? 'detailed${coreDetailed ? '' : ' (app only)'}' : 'normal';
}

/// Reads the saved level before the wallet core starts, so its runtime starts at it. An
/// expired Detailed is turned back to Normal here.
Future<void> applySavedLogLevel(DeskStore store, {DateTime? now}) async {
  final until = await _savedUntil(store);
  final at = now ?? DateTime.now();
  _coreDetailed = false;
  if (until != null && until.isAfter(at)) {
    AppLog.detailedUntil = until;
    _coreDetailed = true;
    logInfo('log', 'detailed logging until ${until.toUtc().toIso8601String()}');
  } else if (until != null) {
    await store.writeJson(logsKey, {'until': null});
  }
}

/// Whether this run's LEPIC runtime started at the detailed level.
bool _coreDetailed = false;

Future<DateTime?> _savedUntil(DeskStore store) async {
  try {
    final j = await store.readJson(logsKey);
    final ms = j is Map<String, dynamic> ? j['until'] : null;
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  } on Object catch (e) {
    logWarn('log', 'level not read: ${e.runtimeType}');
    return null;
  }
}

/// The level. Detailed ends by itself at its time ([AppLog.detailed]); the screen shows it
/// as Normal from the next time it is built.
class LogsController extends Notifier<LogsState> {
  @override
  LogsState build() {
    final until = AppLog.detailed ? AppLog.detailedUntil : null;
    unawaited(_load());
    return LogsState(until: until, coreDetailed: _coreDetailed);
  }

  DateTime _now() => ref.read(logsClockProvider)();

  Future<void> _load() async {
    final store = ref.read(deskStoreProvider);
    if (store == null) return;
    final until = await _savedUntil(store);
    if (until != null && until.isAfter(_now())) {
      _apply(until);
    } else if (state.detailed) {
      _apply(null);
    }
  }

  void _apply(DateTime? until) {
    AppLog.detailedUntil = until;
    state = LogsState(until: until, coreDetailed: _coreDetailed);
  }

  /// Detailed for [detailedFor] from now, or back to Normal.
  Future<void> setDetailed(bool on) async {
    final until = on ? _now().add(detailedFor) : null;
    _apply(until);
    logInfo('log', on ? 'detailed logging on' : 'detailed logging off');
    try {
      await ref.read(deskStoreProvider)?.writeJson(logsKey, {'until': until?.millisecondsSinceEpoch});
    } on Object catch (e) {
      logWarn('log', 'level not saved: ${e.runtimeType}');
    }
  }
}

final logsProvider = NotifierProvider<LogsController, LogsState>(LogsController.new);

/// The time Detailed is measured against; tests fix it.
final logsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The log's files and folder: the running [FileLogSink], none in tests and the mock.
abstract interface class LogFiles {
  /// `wfe.log` and `wfe.log.1`, newest first.
  Future<List<LogFileInfo>> files();

  /// The folder that holds them; null when the log is in memory only.
  String? get folder;

  /// Empties the log.
  Future<void> clear();
}

class AppLogFiles implements LogFiles {
  const AppLogFiles();

  @override
  Future<List<LogFileInfo>> files() => AppLog.sink.files();

  @override
  String? get folder => switch (AppLog.sink) {
    final FileLogSink f => f.dir.path,
    _ => null,
  };

  @override
  Future<void> clear() async {
    final sink = AppLog.sink;
    if (sink is FileLogSink) {
      sink.clear();
    } else if (sink is MemoryLogSink) {
      sink.entries.clear();
    }
    logInfo('log', 'logs cleared');
  }
}

final logFilesProvider = Provider<LogFiles>((ref) => const AppLogFiles());

/// [bytes] as `640 KB` or `1.0 MB`.
String logSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// What a report attaches of each file, newest first, when it takes the newest [budget] bytes
/// across them: `wfe.log (last 256 KB of 1.0 MB)`, `wfe.log.1 (all, 40 KB)` or
/// `wfe.log.1 (not included)`.
List<String> describeLogFiles(List<LogFileInfo> files, int budget) {
  var left = budget;
  final out = <String>[];
  for (final f in files) {
    if (left <= 0) {
      out.add('${f.name} (not included)');
    } else if (f.bytes <= left) {
      out.add('${f.name} (all, ${logSize(f.bytes)})');
      left -= f.bytes;
    } else {
      out.add('${f.name} (last ${logSize(left)} of ${logSize(f.bytes)})');
      left = 0;
    }
  }
  return out;
}

/// Files of the log as a test sees them.
class FakeLogFiles implements LogFiles {
  FakeLogFiles(this.list, {this.folder = '/logs'});

  List<LogFileInfo> list;
  int cleared = 0;

  @override
  final String? folder;

  @override
  Future<List<LogFileInfo>> files() async => list;

  @override
  Future<void> clear() async {
    cleared++;
    list = const [];
  }
}
