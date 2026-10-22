/// The demo server's log: one line per entry on stdout (pm2 keeps it), through [redact].
///
/// Nothing about a visitor is logged but [shortDemoId] of their demo: no address, cookie, PIN,
/// sealed text or slate. Callers pass ids through [shortDemoId]; [redact] catches the rest,
/// including a whole demo id inside a path from LEPIC or an exception, which it writes `[hex]`.
library;

import 'dart:io';

import '../log.dart';
import '../redact.dart';

enum ServerLogLevel { info, warn, error }

typedef ServerLogSink = void Function(String line);

/// Where [serverLog] writes. Tests replace it to read what was logged.
ServerLogSink serverLogSink = stdout.writeln;

final RegExp _longHex = RegExp(r'[0-9a-f]{64}');

/// [message] as the log may show it.
String serverLogText(String message) =>
    redact(message)
        .replaceAllMapped(_longHex, (m) => '${m[0]!.substring(0, 8)}…');

void serverLog(ServerLogLevel level, String message) {
  final time = DateTime.now().toUtc().toIso8601String();
  serverLogSink('$time ${level.name.toUpperCase()} ${serverLogText(message)}');
}

/// The app's [AppLog] on the server: LEPIC's lines and the wallet service's own, as
/// `<target>: <message>`. They arrive redacted already; [serverLog] redacts again.
class DemoLogSink extends LogSink {
  @override
  void record(LogLevel level, String target, String message) {
    if (!logPasses(level, target)) return;
    serverLog(switch (level) {
      LogLevel.error => ServerLogLevel.error,
      LogLevel.warn => ServerLogLevel.warn,
      LogLevel.info || LogLevel.debug => ServerLogLevel.info,
    }, '$target: $message');
  }

  /// The server keeps no log of its own; pm2 does.
  @override
  Future<String> tail(int maxBytes) async => '';
}
