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

import 'advanced_on.dart';

const _password = 'test-pass-1234';

/// A session whose transaction list breaks with an error that is not a WalletError.
class _ListBreaks extends core.FakeWalletSession {
  bool breaks = false;

  @override
  Future<List<core.TxEntry>> transactions({required bool refresh}) =>
      breaks ? Future.error(StateError('list broke')) : super.transactions(refresh: refresh);
}

/// The mock, counting Stop.
class _Stops extends MockDeskWallet {
  _Stops() : super(delay: const Duration(milliseconds: 10));

  int stops = 0;

  @override
  Future<void> stopRescan() {
    stops++;
    return super.stopRescan();
  }
}

/// The mock, failing its scan.
class _Fails extends MockDeskWallet {
  _Fails() : super(delay: const Duration(milliseconds: 10));

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false}) => Stream.error(const DeskError('The node did not answer.'));
}

void main() {
  Future<void> pump(WidgetTester tester, [MockDeskWallet? api]) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      deskApiProvider.overrideWithValue(api ?? MockDeskWallet(delay: const Duration(milliseconds: 10))),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
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
    // F18: one name (Recheck balance), and the row does not repeat the group's title.
    expect(find.text('Recheck balance'), findsNWidgets(2)); // the section chip and the group head
    expect(find.textContaining('Rescan'), findsNothing);
    expect(find.textContaining('coins'), findsNothing);
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
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('The balance is up to date. Unconfirmed transactions were cancelled and their outputs unlocked.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Start again'), findsOneWidget);
  });

  testWidgets('running and finished without Delete unconfirmed', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(EButton, 'Start'));
    await run(tester, const Duration(milliseconds: 40));
    expect(find.textContaining('Checking…'), findsOneWidget);
    expect(find.text('Scanning the chain. The wallet stays usable; the balance updates when the scan ends.'), findsOneWidget);
    expect(find.text('Scan log'), findsOneWidget);
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Scan finished'), findsOneWidget);
    expect(find.text('The balance is up to date.'), findsOneWidget);
    expect(find.text('Deleted'), findsNothing);
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

  testWidgets('Stop waits for the scan to answer; leaving the screen stops the scan', (tester) async {
    final api = _Stops();
    await pump(tester, api);
    await tester.tap(find.widgetWithText(EButton, 'Start'));
    await tester.pump();
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Stop')).onPressed, isNull);
    await run(tester, const Duration(milliseconds: 40));
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Stop')).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
    expect(api.stops, 1);
    await run(tester, const Duration(milliseconds: 400));
  });

  testWidgets('a failed scan says so, with the error, and offers Start again', (tester) async {
    await pump(tester, _Fails());
    await tester.tap(find.widgetWithText(EButton, 'Start'));
    await run(tester, const Duration(milliseconds: 40));
    await tester.pumpAndSettle();
    expect(find.text('Scan failed'), findsOneWidget);
    expect(find.text('The node did not answer.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Start again'), findsOneWidget);
    expect(find.text('Scan finished'), findsNothing);
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

    test('a second scan while one runs: "A scan is already running."', () async {
      final scan = StreamController<core.ScanProgress>();
      service.session.scanStream = scan.stream;
      final first = wallet.rescan().listen((_) {}).asFuture<void>();
      scan.add(const core.ScanProgress(message: 'Scanning', percent: 10, finished: false));
      await pumpEventQueue();
      await expectLater(wallet.rescan().toList(), throwsA(isA<DeskError>().having((e) => e.message, 'message', scanRunning)));
      await scan.close();
      await first;
    });

    test('LEPIC refusing a concurrent scan (WalletBusy) reads "A scan is already running."', () async {
      service.session.scanStream = Stream.error(const core.WalletError(kind: core.WalletErrorKind.walletBusy, message: 'scan running'));
      await expectLater(wallet.rescan().toList(), throwsA(isA<DeskError>().having((e) => e.message, 'message', scanRunning)));
      // The next scan is not refused by the app.
      service.session.scanStream = null;
      expect((await wallet.rescan().toList()).last.finished, isTrue);
    });
  });

  group('LepicDeskWallet due scan', () {
    late Directory support;
    late _ListBreaks session;
    late core.FakeWalletService service;
    late MemorySecretStore secrets;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-rescan-test-');
      session = _ListBreaks();
      service = core.FakeWalletService(password: _password, session: session);
      secrets = MemorySecretStore();
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory('${support.path}/wallets/${chain.name}');
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: secrets,
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
      );
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    Future<bool> pending() async {
      final id = (await wallet.wallets()).single.id;
      final raw = await secrets.read('desk.wallet.mainnet.$id') ?? await secrets.read('desk.wallet.mainnet');
      return raw != null && raw.contains('"scanPending":true');
    }

    test('a due scan that ends without "finished" stays due', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '));
      expect(await pending(), isTrue);
      final scan = StreamController<core.ScanProgress>.broadcast();
      session.scanStream = scan.stream;
      expect(await wallet.unlock(_password), isTrue);
      await pumpEventQueue();
      expect(session.scanCalls, greaterThan(0));
      scan.add(const core.ScanProgress(message: 'Scanning', percent: 10, finished: false));
      await scan.close();
      await wallet.sync();
      await pumpEventQueue();
      expect(await pending(), isTrue);
      final calls = session.scanCalls;
      session.scanStream = null;
      await wallet.sync();
      expect(session.scanCalls, calls + 1);
      expect(await pending(), isFalse);
    });

    test('a sync while Recheck balance scans skips the due scan', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '));
      final due = StreamController<core.ScanProgress>.broadcast();
      session.scanStream = due.stream;
      expect(await wallet.unlock(_password), isTrue);
      await pumpEventQueue();
      await due.close();
      await wallet.sync();
      expect(await pending(), isTrue);
      final user = StreamController<core.ScanProgress>.broadcast();
      session.scanStream = user.stream;
      final rescan = wallet.rescan().listen((_) {}).asFuture<void>();
      await pumpEventQueue();
      final calls = session.scanCalls;
      await wallet.sync();
      expect(session.scanCalls, calls);
      user.add(const core.ScanProgress(message: 'Done', percent: 100, finished: true));
      await user.close();
      await rescan;
      expect(await pending(), isFalse);
    });

    test('a sync that breaks after a finished scan is logged, not a failed scan', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      session.breaks = true;
      final steps = await wallet.rescan().toList();
      expect(steps.last.finished, isTrue);
    });
  });
}
