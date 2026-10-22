// Settings › Recheck balance: Stop, Delete unconfirmed and the result, on the mock wallet; and
// LepicDeskWallet's rescan over FakeWalletSession (the flag passed, Stop calling cancelScan).
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_rescan.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: const Duration(milliseconds: 10))),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsRescanScreen())),
    ));
    await tester.pumpAndSettle();
  }

  // The mock's waits are timers in the test's fake time.
  Future<void> run(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 5)) {
      await tester.pump(const Duration(milliseconds: 5));
    }
  }

  testWidgets('a full scan shows the balance before and after and the counts', (tester) async {
    await pump(tester);
    expect(find.textContaining('Reads the chain again and rebuilds the balance'), findsOneWidget);
    await tester.tap(find.text('Delete unconfirmed'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Start'));
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Scan finished'), findsOneWidget);
    expect(find.text('Balance before'), findsOneWidget);
    expect(find.text('Balance after'), findsOneWidget);
    expect(find.text('Outputs found'), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Start again'), findsOneWidget);
  });

  testWidgets('Stop ends the scan; with Delete unconfirmed it says nothing was deleted', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Delete unconfirmed'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Start'));
    await run(tester, const Duration(milliseconds: 40));
    expect(find.widgetWithText(EButton, 'Stop'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Stop'));
    await tester.pump();
    expect(find.text('Stopping…'), findsOneWidget);
    await run(tester, const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Scan stopped'), findsWidgets);
    expect(find.textContaining('Unconfirmed transactions were not deleted'), findsOneWidget);
    expect(find.text('Outputs found'), findsNothing);
  });

  group('LepicDeskWallet', () {
    late Directory support;
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-rescan-test-');
      service = core.FakeWalletService(password: _password);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory('${support.path}/wallets/${chain.name}');
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
      );
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    test('passes Delete unconfirmed on and reports the counts', () async {
      service.session.scanEvents = const [
        core.ScanProgress(message: 'Scanning', percent: 50, finished: false),
        core.ScanProgress(
          message: 'Done',
          percent: 100,
          finished: true,
          result: core.ScanResult(found: 4, restored: 1, revived: 2, unlocked: 1, deleted: 3),
        ),
      ];
      final steps = await wallet.rescan(deleteUnconfirmed: true).toList();
      expect(service.session.scanDeleteUnconfirmed, isTrue);
      expect(steps.last.finished, isTrue);
      final c = steps.last.counts!;
      expect((c.found, c.restored, c.revived, c.unlocked, c.deleted), (4, 1, 2, 1, 3));
    });

    test('Stop asks the core to cancel; the stream ends without a finished step', () async {
      final scan = StreamController<core.ScanProgress>();
      service.session.scanStream = scan.stream;
      final steps = <ScanStep>[];
      final done = wallet.rescan().listen(steps.add).asFuture<void>();
      scan.add(const core.ScanProgress(message: 'Scanning', percent: 10, finished: false));
      await pumpEventQueue();
      await wallet.stopRescan();
      expect(service.session.scanCancels, 1);
      await scan.close();
      await done;
      expect(steps.map((s) => s.finished), [false]);
      expect(service.session.scanDeleteUnconfirmed, isFalse);
    });
  });
}
