// The web demo's server: one temporary floonet wallet per visitor, on LEPIC.
//
//   dart run bin/wfe_demo_server.dart --help        (from app/, with Flutter's dart)
//
// app/README.md ("Web demo", the server) describes it. Exit codes: 0 for a stop,
// 1 for a crash, 2 for bad config.

import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/config.dart';
import 'package:epic_wallet/src/demo_server/demo_log.dart';
import 'package:epic_wallet/src/demo_server/file_secret_store.dart';
import 'package:epic_wallet/src/demo_server/server.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/log.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(DemoServerConfig.usage);
    return;
  }
  final DemoServerConfig config;
  try {
    config = DemoServerConfig.parse(args, Platform.environment);
  } on ConfigError catch (e) {
    stderr
      ..writeln('wfe_demo_server: ${e.message}')
      ..writeln()
      ..writeln(DemoServerConfig.usage);
    exit(2);
  }
  final library = config.lepicLibrary;
  if (library != null && !File(library).existsSync()) {
    stderr.writeln('wfe_demo_server: no LEPIC library at $library');
    exit(2);
  }

  await runZonedGuarded(
    () async {
      AppLog.use(DemoLogSink());
      await initLepic(libraryPath: library);
      final server = DemoServer(
        config: config,
        // Each demo has its own service and secret store file; they share one LEPIC runtime.
        serviceFor: (paths) =>
            LepicWalletService(secrets: FileSecretStore(paths.secrets)),
      );
      await server.start();

      final stopping = Completer<ProcessSignal>();
      for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
        signal.watch().listen((s) {
          if (!stopping.isCompleted) stopping.complete(s);
        });
      }
      final signal = await stopping.future;
      serverLog(ServerLogLevel.info, 'stopping on $signal');
      await server.stop();
      exit(0);
    },
    (error, stack) {
      serverLog(ServerLogLevel.error, 'crashed: $error\n$stack');
      exit(1);
    },
  );
}
