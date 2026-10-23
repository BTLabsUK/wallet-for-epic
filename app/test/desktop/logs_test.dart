import 'dart:io';

import 'package:epic_wallet/src/app_log_io.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/data/logs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_logs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppLog.detailedUntil = null);

  test('a report takes the newest 256 KB across the files, and says how much of each', () {
    const kb = 1024;
    expect(describeLogFiles(const [LogFileInfo('wfe.log', 1024 * kb), LogFileInfo('wfe.log.1', 1024 * kb)], 256 * kb), [
      'wfe.log (last 256 KB of 1.0 MB)',
      'wfe.log.1 (not included)',
    ]);
    expect(describeLogFiles(const [LogFileInfo('wfe.log', 100 * kb), LogFileInfo('wfe.log.1', 1024 * kb)], 256 * kb), [
      'wfe.log (all, 100 KB)',
      'wfe.log.1 (last 156 KB of 1.0 MB)',
    ]);
    expect(describeLogFiles(const [LogFileInfo('wfe.log', 3 * kb)], 256 * kb), ['wfe.log (all, 3 KB)']);
  });

  test('the file log lists its files and clears them', () {
    final dir = Directory.systemTemp.createTempSync('logs_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final sink = FileLogSink.open(dir, maxBytes: 200, mirror: (_, _, _) {});
    addTearDown(sink.close);
    for (var i = 0; i < 6; i++) {
      sink.record(LogLevel.info, 'dart.test', 'line $i of the log');
    }
    return sink.files().then((files) async {
      expect(files.map((f) => f.name), ['wfe.log', 'wfe.log.1']);
      expect(files.every((f) => f.bytes > 0), isTrue);
      sink.clear();
      final after = await sink.files();
      expect(after.map((f) => (f.name, f.bytes)), [('wfe.log', 0)]);
      sink.record(LogLevel.info, 'dart.test', 'after');
      expect(await sink.tail(1000), contains('after'));
    });
  });

  test('Detailed lets debug and every target through', () {
    expect(logPasses(LogLevel.debug, 'dart.x'), isFalse);
    expect(logPasses(LogLevel.info, 'hyper::client'), isFalse);
    AppLog.detailedUntil = DateTime.now().add(const Duration(hours: 1));
    expect(logPasses(LogLevel.debug, 'dart.x'), isTrue);
    expect(logPasses(LogLevel.info, 'hyper::client'), isTrue);
  });

  test('a saved Detailed holds for 24 hours, and an expired one is turned back to Normal', () async {
    final secrets = MemorySecretStore();
    final store = DeskStore(secrets);
    final set = DateTime(2099, 10, 22, 12); // AppLog.detailed reads the real clock: keep it ahead
    await store.writeJson(logsKey, {'until': set.add(detailedFor).millisecondsSinceEpoch});
    await applySavedLogLevel(store, now: set.add(const Duration(hours: 23)));
    expect(AppLog.detailed, isTrue);
    AppLog.detailedUntil = null;
    await applySavedLogLevel(store, now: set.add(const Duration(hours: 25)));
    expect(AppLog.detailed, isFalse);
    expect(await store.readJson(logsKey), {'until': null});
  });

  testWidgets('Logs: level, size, open folder, clear with a confirm', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = DeskStore(MemorySecretStore());
    final files = FakeLogFiles([const LogFileInfo('wfe.log', 600 * 1024)]);
    final opened = <String>[];
    final now = DateTime(2099, 10, 22, 9, 30); // ahead of the real clock, which AppLog.detailed reads
    final container = ProviderContainer(overrides: [
      deskStoreProvider.overrideWithValue(store),
      logFilesProvider.overrideWithValue(files),
      logsClockProvider.overrideWithValue(() => now),
      deskOpenFolderProvider.overrideWithValue((dir) async {
        opened.add(dir);
        return true;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: const Scaffold(body: SingleChildScrollView(child: LogsGroup())),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Current size 600 KB of 2.0 MB. Keeps one older file.'), findsOneWidget);
    expect(find.textContaining('Detailed keeps more lines on disk for 24 hours; addresses may appear in the file, reports leave them out.'), findsOneWidget);

    await tester.tap(find.text('Detailed'));
    await tester.pumpAndSettle();
    expect(AppLog.detailed, isTrue);
    expect(find.textContaining('Detailed until tomorrow 09:30, then Normal. Addresses may appear in the file; reports leave them out.'), findsOneWidget);
    expect((await store.readJson(logsKey) as Map)['until'], now.add(detailedFor).millisecondsSinceEpoch);
    expect(container.read(logsProvider).label, 'detailed (app only)');

    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    expect(AppLog.detailed, isFalse);

    await tester.tap(find.text('Open log folder'));
    await tester.pumpAndSettle();
    expect(opened, ['/logs']);

    await tester.tap(find.widgetWithText(EButton, 'Clear logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(EButton, 'Keep logs'));
    await tester.pumpAndSettle();
    expect(files.cleared, 0);
    await tester.tap(find.widgetWithText(EButton, 'Clear logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(EButton, 'Clear logs').last);
    await tester.pumpAndSettle();
    expect(files.cleared, 1);
    expect(find.text('Current size 0 KB of 2.0 MB. Keeps one older file.'), findsOneWidget);
    // Let the toast go.
    await tester.pump(const Duration(seconds: 10));
  });
}
