// SPDX-License-Identifier: Apache-2.0
/// `last_session.dart` off the web.
///
/// - `logs/session.json` is written at start and removed on a clean end: the desktop's close
///   (`deskCloseDown`), and on a phone whenever the app goes to the background, where the
///   system may end it at any time without telling. Found at the next start, the last session
///   did not end cleanly.
/// - Android 11+ says how the last process ended (`ExitReasons.kt`): an ANR or a crash counts,
///   with the ANR's thread stacks; any other end (the user, the system freeing memory, an
///   update) does not, whatever the marker says. `logs/last-exit.json` keeps the newest end
///   seen, so each is judged once.
/// - At such a start, before anything is logged, the log's tail and LEPIC's ring are copied to
///   `logs/last-session/` with `incident.json`, replacing an older copy. It stays until the next
///   incident; [LastSession.offered] marks it offered, so the notice shows once.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart' show AppLifecycleListener;

import 'last_session_types.dart';
import 'log.dart';

const String sessionMarkerName = 'session.json';
const String lastExitName = 'last-exit.json';
const String lastSessionFolder = 'last-session';
const String _incidentName = 'incident.json';
const String _logName = 'wfe.log';
const String _traceName = 'trace.txt';
const String _ringFolder = 'ring';

/// How much of `wfe.log` is kept: what a report attaches (`feedbackLogBytes`).
const int lastSessionLogBytes = 256 * 1024;

/// Android's record of the last process's end (`ExitReasons.kt`).
class AndroidExit {
  const AndroidExit({required this.reason, required this.timestamp, this.description, this.trace});

  /// `anr`, `crash`, `native` or `other`.
  final String reason;

  /// Milliseconds since the epoch.
  final int timestamp;
  final String? description;
  final String? trace;
}

/// What Android answered: [supported] false before Android 11; [exit] null when nothing ended
/// after the time asked about.
typedef ExitAnswer = ({bool supported, AndroidExit? exit});

/// Asks for the newest end after [sinceMs]; null where there is no such record (off Android,
/// a failed call).
typedef ExitQuery = Future<ExitAnswer?> Function(int sinceMs);

const _exitChannel = MethodChannel('epic_wallet/exit_reasons');

/// [ExitQuery] on Android; null elsewhere.
Future<ExitAnswer?> androidLastExit(int sinceMs) async {
  if (!Platform.isAndroid) return null;
  try {
    final answer = await _exitChannel.invokeMapMethod<String, Object?>('lastExit', {'since': sinceMs});
    if (answer == null || answer['error'] != null) return null;
    final exit = answer['exit'];
    return (
      supported: answer['supported'] == true,
      exit: exit is Map
          ? AndroidExit(
              reason: '${exit['reason']}',
              timestamp: (exit['timestamp'] as num).toInt(),
              description: exit['description'] as String?,
              trace: exit['trace'] as String?,
            )
          : null,
    );
  } on Object catch (e) {
    logWarn('session', 'exit reason not read: ${e.runtimeType}');
    return null;
  }
}

/// How the last session ended, or null for a clean end. Where Android keeps the record
/// ([exits] supported) it decides alone: only an ANR or a crash after the last one seen counts.
/// Elsewhere a [markerLeft] behind means the session never closed.
({LastSessionEnd end, String cause})? judgeLastSession({required bool markerLeft, ExitAnswer? exits}) {
  if (exits != null && exits.supported) {
    return switch (exits.exit?.reason) {
      'anr' => (end: LastSessionEnd.froze, cause: 'anr'),
      'crash' => (end: LastSessionEnd.closed, cause: 'crash'),
      'native' => (end: LastSessionEnd.closed, cause: 'native crash'),
      _ => null,
    };
  }
  return markerLeft ? (end: LastSessionEnd.closed, cause: 'not closed') : null;
}

/// The last session's watch, for the app's lifetime: one per process ([lastSession]).
class LastSession implements LastSessionSource {
  LastSession(this.logs, {ExitQuery? exits, DateTime Function()? now})
    : _exits = exits ?? androidLastExit,
      _now = now ?? DateTime.now;

  /// `<application support>/logs`.
  final Directory logs;
  final ExitQuery _exits;
  final DateTime Function() _now;
  AppLifecycleListener? _lifecycle;

  String _p(String a, [String? b, String? c]) =>
      [logs.path, a, ?b, ?c].join(Platform.pathSeparator);

  File get _marker => File(_p(sessionMarkerName));
  File get _lastExit => File(_p(lastExitName));
  File get _incident => File(_p(lastSessionFolder, _incidentName));

  /// At start, before this session logs anything to the file: judges the last session, keeps
  /// its log if it did not end cleanly ([log] the tail of `wfe.log`, [ring] LEPIC's ring), and
  /// marks this one running. [version] is this build's. Never throws: a failure is logged.
  Future<void> begin({
    required Future<String?> Function() log,
    required Future<List<LogRingFile>?> Function() ring,
    String version = '',
    bool watchLifecycle = false,
  }) async {
    try {
      final marker = _readJson(_marker);
      final exits = await _exits(_readJson(_lastExit)?['timestamp'] as int? ?? 0);
      if (exits?.exit case final exit?) {
        _writeJson(_lastExit, {'timestamp': exit.timestamp});
      }
      final judged = judgeLastSession(markerLeft: marker != null, exits: exits);
      if (judged != null) {
        await _keep(judged, marker, exits?.exit, log: log, ring: ring);
        logInfo('session', 'last session did not end cleanly: ${judged.cause}');
      }
      running(version: version);
    } on Object catch (e) {
      logWarn('session', 'last session not checked: ${e.runtimeType}');
    }
    if (watchLifecycle) {
      // A phone may be ended at any time in the background, unannounced: that is a clean end.
      _lifecycle ??= AppLifecycleListener(
        onPause: clean,
        onDetach: clean,
        onResume: () => running(version: version),
      );
    }
  }

  String? _version;

  /// Marks this session running (at start, on a phone's return to the foreground).
  void running({String? version}) {
    if (version != null) _version = version;
    try {
      _writeJson(_marker, {
        'started': _now().toUtc().toIso8601String(),
        'version': _version ?? '',
      });
    } on FileSystemException catch (e) {
      logWarn('session', 'marker not written: ${e.message}');
    }
  }

  @override
  void clean() {
    try {
      if (_marker.existsSync()) _marker.deleteSync();
    } on FileSystemException catch (e) {
      logWarn('session', 'marker not removed: ${e.message}');
    }
  }

  Future<void> _keep(
    ({LastSessionEnd end, String cause}) judged,
    Map<String, Object?>? marker,
    AndroidExit? exit, {
    required Future<String?> Function() log,
    required Future<List<LogRingFile>?> Function() ring,
  }) async {
    final folder = Directory(_p(lastSessionFolder));
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    Directory(_p(lastSessionFolder, _ringFolder)).createSync(recursive: true);
    final text = await log();
    if (text != null && text.isNotEmpty) File(_p(lastSessionFolder, _logName)).writeAsStringSync(text);
    final files = await ring() ?? const [];
    for (final f in files) {
      File(_p(lastSessionFolder, _ringFolder, f.name)).writeAsStringSync(f.text);
    }
    final trace = [
      if (exit?.description case final d? when d.isNotEmpty) d,
      if (exit?.trace case final t? when t.isNotEmpty) t,
    ].join('\n\n');
    if (trace.isNotEmpty) File(_p(lastSessionFolder, _traceName)).writeAsStringSync(trace);
    _writeJson(_incident, {
      'end': judged.end.name,
      'cause': judged.cause,
      if (exit != null) 'endedAt': DateTime.fromMillisecondsSinceEpoch(exit.timestamp, isUtc: true).toIso8601String(),
      if (marker?['version'] case final String v when v.isNotEmpty) 'version': v,
      'ring': [for (final f in files) f.name],
      'offered': false,
    });
  }

  /// A kept log not yet offered: the notice is due.
  @override
  bool get due {
    final incident = _readJson(_incident);
    return incident != null && incident['offered'] == false;
  }

  /// Marks the kept log offered, so the notice never shows again for it.
  @override
  void offered() {
    final incident = _readJson(_incident);
    if (incident == null) return;
    try {
      _writeJson(_incident, {...incident, 'offered': true});
    } on FileSystemException catch (e) {
      logWarn('session', 'offer not recorded: ${e.message}');
    }
  }

  /// The kept log, for a report; null when there is none or it cannot be read.
  @override
  Future<LastSessionLog?> read() async {
    final incident = _readJson(_incident);
    if (incident == null) return null;
    String? text(File f) => f.existsSync() ? f.readAsStringSync() : null;
    try {
      final names = [for (final n in incident['ring'] as List? ?? const []) '$n'];
      final ring = <LogRingFile>[
        for (final name in names)
          if (text(File(_p(lastSessionFolder, _ringFolder, name))) case final t?) (name: name, text: t),
      ];
      return LastSessionLog(
        end: LastSessionEnd.values.asNameMap()[incident['end']] ?? LastSessionEnd.closed,
        cause: '${incident['cause'] ?? 'not closed'}',
        endedAt: DateTime.tryParse('${incident['endedAt'] ?? ''}'),
        version: incident['version'] as String?,
        ring: ring.isEmpty ? null : ring,
        log: text(File(_p(lastSessionFolder, _logName))),
        trace: text(File(_p(lastSessionFolder, _traceName))),
      );
    } on Object catch (e) {
      logWarn('session', 'last session log not read: ${e.runtimeType}');
      return null;
    }
  }

  static Map<String, Object?>? _readJson(File file) {
    try {
      if (!file.existsSync()) return null;
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, Object?> ? value : null;
    } on Object {
      // Half written when the app died: there was a session all the same.
      return file.existsSync() ? const {} : null;
    }
  }

  static void _writeJson(File file, Map<String, Object?> value) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(value), flush: true);
  }
}

/// This process's [LastSession], once `startLogging` has made it; null before, on the web and
/// in widget tests.
LastSession? lastSession;
