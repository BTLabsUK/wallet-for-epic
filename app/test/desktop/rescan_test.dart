// SPDX-License-Identifier: Apache-2.0
// Settings › Recheck balance: Stop, Delete unconfirmed and the result, on the mock wallet; and
// LepicDeskWallet's rescan over FakeWalletSession (the flag passed, Stop calling cancelScan).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_rescan.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/scan_start.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'advanced_on.dart';

final _l = englishStrings;

const _password = 'test-pass-1234';

/// A session whose transaction list breaks with an error that is not a WalletError.
class _ListBreaks extends core.FakeWalletSession {
  bool breaks = false;

  /// When set, every scan fails with it.
  core.WalletError? scanError;

  @override
  Stream<core.ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    final e = scanError;
    if (e != null) {
      scanStarts.add(startHeight);
      return Stream.error(e);
    }
    return super.scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed);
  }

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

/// The mock, keeping where each scan started.
class _Starts extends MockDeskWallet {
  _Starts() : super(delay: const Duration(milliseconds: 10));

  final List<BigInt?> starts = [];

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight}) {
    starts.add(startHeight);
    return super.rescan(deleteUnconfirmed: deleteUnconfirmed, startHeight: startHeight);
  }
}

/// The mock, failing its scan.
class _Fails extends MockDeskWallet {
  _Fails() : super(delay: const Duration(milliseconds: 10));

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight}) => Stream.error(const DeskError('The node did not answer.'));
}

void main() {
  // The start month shows as a month and year (localMonthYear).
  setUpAll(initializeDateFormatting);
  /// [whole]: the start block is January 2025 until changed; the tests that only run a recheck
  /// pick Scan from the start (block 0) through the info popover.
  Future<void> pump(WidgetTester tester, [MockDeskWallet? api, bool whole = true]) async {
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
    if (whole) {
      await tester.tap(find.byKey(ScanStart.infoKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanStart.fromStartKey));
      await tester.pumpAndSettle();
    }
  }

  // The mock's waits are timers in the test's fake time.
  Future<void> run(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 5)) {
      await tester.pump(const Duration(milliseconds: 5));
    }
  }

  testWidgets('the phone\u2019s start choices: a month (January 2025 by default), a typed height, or the start (0)', (tester) async {
    final api = _Starts();
    await pump(tester, api, false);
    expect(find.text(_l.deskSetRescanStartHeading), findsOneWidget);
    // The shared scan-start line (scan_start.dart): January 2025 until another month is picked.
    expect(find.text(_l.restoreScanningFrom('January 2025')), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.starts, [defaultStartMonth.height]);
    await tester.tap(find.byKey(ScanStart.changeKey));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsWidgets, reason: 'GP-030: the phone\u2019s choices');
    await tester.tap(find.text(_l.restoreStartByHeight));
    await tester.pumpAndSettle();
    // An empty height is the start (block 0); a typed one shows on the line.
    expect(find.text(_l.restoreScanningFromStart), findsOneWidget);
    await tester.enterText(find.byKey(ScanStart.heightKey), '2800000');
    await tester.pump();
    expect(find.text(_l.restoreScanningFromBlock('2,800,000')), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheckAgain));
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ScanStart.infoKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ScanStart.fromStartKey));
    await tester.pumpAndSettle();
    expect(find.text(_l.restoreScanningFromStart), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheckAgain));
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.starts, [defaultStartMonth.height, BigInt.from(2800000), BigInt.zero]);
  });

  testWidgets('a full scan shows the balance before and after and the counts', (tester) async {
    await pump(tester);
    expect(find.textContaining('Checks the chain again for this wallet’s coins'), findsOneWidget);
    // One name (Recheck balance): the page title only; the group has no second heading.
    expect(find.text(_l.deskSetFrameRescan), findsOneWidget);
    expect(find.textContaining('Rescan'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('rescan-delete-unconfirmed')));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetRescanFinished), findsOneWidget);
    expect(find.text(_l.deskSetRescanBefore), findsOneWidget);
    expect(find.text(_l.deskSetRescanAfter), findsOneWidget);
    expect(find.text(_l.deskSetRescanFound), findsOneWidget);
    expect(find.text(_l.deskSetRescanDeleted), findsOneWidget);
    expect(find.text(_l.deskSetRescanUnlocked), findsOneWidget);
    expect(find.text('The balance is up to date. Unconfirmed transactions were cancelled and their outputs unlocked.'), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSetRescanRecheckAgain), findsOneWidget);
  });

  testWidgets('running and finished without Delete unconfirmed', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await run(tester, const Duration(milliseconds: 40));
    expect(find.textContaining(_l.deskSetFrameChecking), findsOneWidget);
    expect(find.text(_l.deskSetRescanScanning), findsOneWidget);
    expect(find.text(_l.deskSetRescanLog), findsOneWidget);
    await run(tester, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetRescanFinished), findsOneWidget);
    expect(find.text(_l.deskSetRescanUpToDate), findsOneWidget);
    expect(find.text(_l.deskSetRescanDeleted), findsNothing);
  });

  testWidgets('Stop ends the scan; with Delete unconfirmed it says nothing was deleted', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('rescan-delete-unconfirmed')));
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await run(tester, const Duration(milliseconds: 40));
    expect(find.widgetWithText(EButton, _l.deskSetLnodeStop), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetLnodeStop));
    await tester.pump();
    expect(find.text(_l.deskSetRescanStopping), findsOneWidget);
    await run(tester, const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetRescanStoppedLine), findsWidgets);
    expect(find.textContaining('Unconfirmed transactions were not deleted'), findsOneWidget);
    expect(find.text(_l.deskSetRescanFound), findsNothing);
  });

  testWidgets('Stop waits for the scan to answer; leaving the screen stops the scan', (tester) async {
    final api = _Stops();
    await pump(tester, api);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await tester.pump();
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskSetLnodeStop)).onPressed, isNull);
    await run(tester, const Duration(milliseconds: 40));
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskSetLnodeStop)).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
    expect(api.stops, 1);
    await run(tester, const Duration(milliseconds: 400));
  });

  testWidgets('a failed scan says so, with the error, and offers Start again', (tester) async {
    await pump(tester, _Fails());
    await tester.tap(find.widgetWithText(EButton, _l.deskSetRescanRecheck));
    await run(tester, const Duration(milliseconds: 40));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetRescanFailed), findsOneWidget);
    expect(find.text('The node did not answer.'), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.deskSetRescanRecheckAgain), findsOneWidget);
    expect(find.text(_l.deskSetRescanFinished), findsNothing);
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
          final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
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
          final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
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

    Future<Map<String, dynamic>> meta() async {
      final id = (await wallet.wallets()).single.id;
      final raw = await secrets.read('desk.wallet.mainnet.$id') ?? await secrets.read('desk.wallet.mainnet');
      return raw == null ? const {} : jsonDecode(raw) as Map<String, dynamic>;
    }

    test('the core\'s restore flag makes the scan due without the app\'s note (closed mid-restore)', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await pending(), isFalse);
      session.restoreScanPending = true;
      final scan = StreamController<core.ScanProgress>.broadcast();
      session.scanStream = scan.stream;
      expect(await wallet.unlock(_password), isTrue);
      await pumpEventQueue();
      expect(session.scanStarts, [null], reason: 'no height: the core scans from block 0');
      scan.add(const core.ScanProgress(message: 'Scanning', percent: 40, finished: false));
      await pumpEventQueue();
      final running = (await wallet.status()).restoreScan;
      expect(running?.state, RestoreScanState.running);
      expect(running?.percent, 40);
      session.restoreScanPending = false;
      scan.add(const core.ScanProgress(message: 'Done', percent: 100, finished: true));
      await scan.close();
      await wallet.sync();
      expect((await wallet.status()).restoreScan, isNull, reason: 'the core says the scan finished');
    });

    test('a restore from a height scans from it once, which finishes it', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '), startHeight: BigInt.from(2800000));
      expect(service.createdRestoreFrom, BigInt.from(2800000), reason: 'the core records the start');
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      expect(session.scanStarts, [BigInt.from(2800000)]);
      expect(session.restoreScanPending, isFalse);
      expect((await meta())['scanFrom'], isNull);
      expect((await wallet.status()).restoreScan, isNull);
    });

    test('a core that did not record the height: the scan from block 0 follows by itself while the flag stays', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '), startHeight: BigInt.from(2800000));
      session.restoreFrom = BigInt.zero;
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      expect(session.scanStarts, [BigInt.from(2800000), null]);
      expect(session.restoreScanPending, isFalse);
      expect((await meta())['scanFrom'], isNull);
      expect(await pending(), isFalse);
      expect((await wallet.status()).restoreScan, isNull);
      // Nothing runs again at the next sync.
      await wallet.sync();
      expect(session.scanStarts, hasLength(2));
    });

    test('a flag the finished scan did not clear is no loop: the state offers Try again, which runs it once more', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      session.restoreScanPending = true;
      // A core that never clears the flag (a height start, say).
      session.scanStream = Stream.fromIterable(const [core.ScanProgress(message: 'Done', percent: 100, finished: true)]);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      await wallet.sync();
      expect(session.scanStarts, [null], reason: 'one whole-chain scan by itself, not one per sync');
      expect((await wallet.status()).restoreScan?.state, RestoreScanState.failed);
      session.scanStream = Stream.fromIterable(const [core.ScanProgress(message: 'Done', percent: 100, finished: true)]);
      await wallet.syncNow();
      expect(session.scanStarts, [null, null]);
    });

    test('a failed due scan shows as failed and stays due; a node that does not answer is waiting for the network', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '));
      session.restoreScanPending = true;
      session.scanError = const core.WalletError(kind: core.WalletErrorKind.io, message: 'disk');
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      expect((await wallet.status()).restoreScan?.state, RestoreScanState.failed);
      expect(await pending(), isTrue);
      session.scanError = const core.WalletError(kind: core.WalletErrorKind.nodeUnreachable, message: 'no answer');
      await wallet.sync();
      final waits = (await wallet.status()).restoreScan;
      expect(waits?.state, RestoreScanState.waiting);
      expect(waits?.offline, isFalse);
    });

    test('a finished Recheck forgets the restore\'s start height; the scan from block 0 the core still owes follows', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: service.phrase.split(' '), startHeight: BigInt.from(2800000));
      // Locked out of the due scan: Recheck runs first.
      final due = StreamController<core.ScanProgress>.broadcast();
      session.scanStream = due.stream;
      expect(await wallet.unlock(_password), isTrue);
      await pumpEventQueue();
      await due.close();
      await wallet.sync();
      expect((await meta())['scanFrom'], 2800000);
      session.restoreScanPending = true;
      session.scanStream = null;
      final steps = await wallet.rescan(startHeight: BigInt.from(2900000)).toList();
      expect(steps.last.finished, isTrue);
      expect((await meta())['scanFrom'], isNull);
      expect(session.scanStarts.where((h) => h != BigInt.from(2800000)), [BigInt.from(2900000), null], reason: 'the Recheck from its height, then the owed scan with no height');
      expect(session.restoreScanPending, isFalse);
    });

    test('Recheck "The whole chain" passes block 0', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
      await wallet.rescan(startHeight: BigInt.zero).drain<void>();
      expect(session.scanStarts.last, BigInt.zero);
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
