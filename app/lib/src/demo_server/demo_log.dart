/// The demo server's log: one line per entry on stdout (pm2 keeps it), through [redact].
///
/// Nothing about a visitor is logged but [shortDemoId] of their demo: no address, cookie, PIN,
/// sealed text or slate. Callers pass ids through [shortDemoId]; [redact] catches the rest.
library;

import 'dart:io';

import '../redact.dart';

enum ServerLogLevel { info, warn, error }

typedef ServerLogSink = void Function(String line);

/// Where [serverLog] writes. Tests replace it to read what was logged.
ServerLogSink serverLogSink = stdout.writeln;

void serverLog(ServerLogLevel level, String message) {
  final time = DateTime.now().toUtc().toIso8601String();
  serverLogSink('$time ${level.name.toUpperCase()} ${redact(message)}');
}
