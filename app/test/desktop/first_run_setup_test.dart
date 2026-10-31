// SPDX-License-Identifier: Apache-2.0
// After a wallet is created or restored the first run goes password → phrase →
// Node → Epicbox → Review → Unlock. Setup starts on the node step with no way back to the
// phrase, preselects only a healthy node, and Save goes to Unlock. A second wallet starts from
// the current node.
import 'dart:async';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/log.dart' show AppLog, MemoryLogSink;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

  /// As the real wallet (LepicDeskWallet): Setup runs before Unlock, and a locked wallet has no
  /// address to read. Reading it made every first-run Save fail (26.10.13–26.10.15).
  @override
  Future<String> epicboxAddress() async => throw DeskError.l10n((l) => l.deskErrWalletLocked);

  @override
  Future<List<NodeServer>> nodes() async => const [
    NodeServer(url: 'https://slow.example:3413', label: 'Slow', operator: 'Slow', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1'),
    NodeServer(url: 'https://fast.example:3413', label: 'Fast', operator: 'Fast', health: ServiceHealth.ok, latencyMs: 90, height: 2914414, version: '4.1.1'),
    NodeServer(url: 'https://current.example:3413', label: 'Current', operator: 'Current', health: ServiceHealth.ok, latencyMs: 400, height: 2914414, version: '4.1.1'),
  ];

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    return ServiceStatus(
      node: const NodeServer(url: 'https://current.example:3413', label: 'Current', operator: 'Current'),
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: s.tor,
    );
  }

  @override
  Future<void> useNode(String url) {
    calls.add('node $url');
    return super.useNode(url);
  }

  @override
  Future<void> useEpicbox(String domain) {
    calls.add('epicbox $domain');
    return super.useEpicbox(domain);
  }

  @override
  Future<void> setListening(bool on) {
    calls.add('listening $on');
    return super.setListening(on);
  }
}

/// The real wallet's first answer while locked: every node still being checked, and no refresh
/// from the app; the checks finish later and [changes] says so.
class _Checking extends _Wallet {
  final _changes = StreamController<void>.broadcast();
  bool answered = false;

  @override
  Stream<void> changes() => _changes.stream;

  void finish() {
    answered = true;
    _changes.add(null);
  }

  @override
  Future<List<NodeServer>> nodes() async => answered
      ? super.nodes()
      : [for (final n in await super.nodes()) NodeServer(url: n.url, label: n.label, operator: n.operator, health: ServiceHealth.checking)];
}

/// A wallet whose Epicbox change fails, and optionally whose setup mark cannot be cleared
/// (a store that cannot be written): Save fails on every try.
class _Refusing extends _Wallet {
  _Refusing({this.markStuck = false});

  final bool markStuck;

  @override
  Future<void> useEpicbox(String domain) async => throw DeskError.l10n((l) => l.deskErrWalletLocked);

  @override
  Future<void> setSetupPending(String id, bool pending) async {
    if (markStuck && !pending) throw DeskError.l10n((l) => l.deskErrListNotSaved);
    return super.setSetupPending(id, pending);
  }
}

class _Router extends ConsumerWidget {
  const _Router();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(deskNavProvider);
    return KeyedSubtree(
      key: ValueKey(at.route),
      child: switch (at.route) {
        DeskRoute.create => CreateScreen(arg: at.arg),
        DeskRoute.restore => RestoreScreen(arg: at.arg),
        DeskRoute.setup => SetupScreen(arg: at.arg),
        DeskRoute.unlock => UnlockScreen(arg: at.arg),
        _ => Text('at ${at.route.name}'),
      },
    );
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskNodeProvider.overrideWithValue(MockDeskNode())]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpApp(WidgetTester tester, DeskRoute route, [Object? arg]) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container.read(deskNavProvider.notifier).reset(route, arg);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: _Router())),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> wait(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Finder field(int i) => find.byType(EditableText).at(i);

  /// Node step → pick nothing → Continue → Epicbox → Continue → Review → Save.
  Future<void> throughSetup(WidgetTester tester, {required String node}) async {
    expect(container.read(deskNavProvider).route, DeskRoute.setup);
    expect(find.text('Choose a node'), findsOneWidget, reason: 'the first run starts on the node step');
    expect(find.text('Preferences'), findsNothing);
    expect(find.text('Back'), findsNothing, reason: 'no way back to the phrase');
    expect(find.text('Back to wallet'), findsNothing);
    expect(tester.widget<ServerListPanel>(find.byType(ServerListPanel)).value, node);
    await tester.tap(find.text('Continue'));
    await wait(tester, 1000);
    expect(find.text('Receive when offline'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await wait(tester, 300);
    expect(find.text('Review settings'), findsOneWidget);
    expect(find.text(node), findsOneWidget);
    expect(wallet.calls, isEmpty, reason: 'nothing happens before Save');
    await tester.tap(find.text('Save settings'));
    await wait(tester, 800);
  }

  testWidgets('create → node step → pick → Epicbox → Review → Save → Unlock with the new wallet', (tester) async {
    await pumpApp(tester, DeskRoute.create);
    await tester.enterText(field(0), 'longpassword');
    await tester.enterText(field(1), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Create wallet').last);
    await wait(tester, 4000);
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    await tester.tap(find.textContaining('I have written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await wait(tester, 800);
    final arg = container.read(deskNavProvider).arg;
    expect(arg, isA<SetupFirstRun>());
    // The mock keeps a legacy wallet, so this one is a second wallet: the current node first.
    expect((arg! as SetupFirstRun).added.name, 'Wallet');
    await throughSetup(tester, node: 'https://current.example:3413');
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    expect(container.read(deskNavProvider).arg, isA<UnlockAdded>());
    expect(wallet.calls, isNot(contains('listening true')), reason: 'a locked wallet listens once Unlock opens it');
    await end(tester);
  });

  testWidgets('restore → the same node step → Save → Unlock', (tester) async {
    await pumpApp(tester, DeskRoute.restore);
    await tester.enterText(field(0), [...List.filled(11, 'abandon'), 'about'].join(' '));
    await wait(tester, 500);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.enterText(field(0), 'longpassword');
    await tester.enterText(field(1), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Restore wallet').last);
    await wait(tester, 5000);
    expect(container.read(deskNavProvider).arg, isA<SetupFirstRun>());
    await throughSetup(tester, node: 'https://current.example:3413');
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    await end(tester);
  });

  testWidgets('the first wallet of a computer preselects only a healthy node, the fastest; Save keeps what was picked', (tester) async {
    await pumpApp(tester, DeskRoute.setup, const SetupFirstRun(UnlockAdded('Wallet 1', id: 'x')));
    await throughSetup(tester, node: 'https://fast.example:3413');
    expect(wallet.calls, contains('node https://fast.example:3413'));
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    await end(tester);
  });

  testWidgets('a second wallet starts from the current node and changes nothing when kept', (tester) async {
    await pumpApp(tester, DeskRoute.setup, const SetupFirstRun(UnlockAdded('Wallet 2', id: 'x'), second: true));
    await wait(tester, 800);
    await throughSetup(tester, node: 'https://current.example:3413');
    expect(wallet.calls.where((c) => c.startsWith('node ')), isEmpty, reason: 'the node is unchanged');
    await end(tester);
  });

  testWidgets('the checks finish after Setup opened on a locked wallet: the fastest healthy node is preselected from changes alone', (tester) async {
    final checking = _Checking();
    wallet = checking;
    container.dispose();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(checking), deskNodeProvider.overrideWithValue(MockDeskNode())]);
    await pumpApp(tester, DeskRoute.setup, const SetupFirstRun(UnlockAdded('Wallet 1', id: 'x')));
    var combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, '', reason: 'a node being checked is not healthy');
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNull);
    checking.finish();
    await wait(tester, 800);
    combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, 'https://fast.example:3413');
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('a wallet whose setup was not saved goes to Setup at Unlock, also after a restart; Save clears it', (tester) async {
    final added = (await tester.runAsync(() async {
      await wallet.createWallet(password: 'longpassword');
      final a = (await wallet.wallets()).last;
      await wallet.setSetupPending(a.id, true);
      return a;
    }))!;
    // A new start: nothing in memory but the wallet's own record.
    await pumpApp(tester, DeskRoute.unlock);
    await wait(tester, 800);
    expect(container.read(deskNavProvider).route, DeskRoute.setup);
    final arg = container.read(deskNavProvider).arg! as SetupFirstRun;
    expect(arg.added.id, added.id);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continue'));
    await wait(tester, 1000);
    await tester.tap(find.text('Continue'));
    await wait(tester, 300);
    await tester.tap(find.text('Save settings'));
    await wait(tester, 800);
    expect(await tester.runAsync(() => wallet.setupPending(added.id)), isFalse);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    await wait(tester, 800);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock, reason: 'cleared: Unlock stays');
    await end(tester);
  });

  for (final restored in [true, false]) {
    testWidgets('a resumed setup of a ${restored ? 'restored' : 'new'} wallet keeps how it came for Unlock\'s notice (WIN-2)', (tester) async {
      final added = (await tester.runAsync(() async {
        await wallet.createWallet(password: 'longpassword');
        final a = (await wallet.wallets()).last;
        await markSetupPending(wallet, a.id, restored: restored);
        return a;
      }))!;
      // A new start: only the wallet's own record says how it came.
      await pumpApp(tester, DeskRoute.unlock);
      await wait(tester, 800);
      final arg = container.read(deskNavProvider).arg! as SetupFirstRun;
      expect(arg.resumed, isTrue);
      expect(arg.added.id, added.id);
      expect(arg.added.notice, restored ? 'Wallet restored.' : isNull, reason: 'null: "New wallet added."');
      await end(tester);
    });
  }

  testWidgets('create marks the wallet pending until Save', (tester) async {
    await pumpApp(tester, DeskRoute.create);
    await tester.enterText(field(0), 'longpassword');
    await tester.enterText(field(1), 'longpassword');
    await tester.pump();
    await tester.tap(find.text('Create wallet').last);
    await wait(tester, 4000);
    await tester.tap(find.text('Reveal phrase'));
    await tester.pump();
    await tester.tap(find.textContaining('I have written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await wait(tester, 800);
    final id = (container.read(deskNavProvider).arg! as SetupFirstRun).added.id!;
    expect(await tester.runAsync(() => wallet.setupPending(id)), isTrue);
    await end(tester);
  });

  /// A first run offers Skip from the start, also after a Save that failed: Unlock opens and stays, also when the
  /// setup mark cannot be cleared. Never back into the same Setup (the 26.10.15 loop).
  for (final stuck in [false, true]) {
    testWidgets('Save fails on a first run → Skip setup → Unlock${stuck ? ' (mark not cleared)' : ''}', (tester) async {
      final refusing = _Refusing(markStuck: stuck);
      final log = MemoryLogSink();
      AppLog.use(log);
      wallet = refusing;
      container.dispose();
      container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(refusing), deskNodeProvider.overrideWithValue(MockDeskNode())]);
      final added = (await tester.runAsync(() async {
        await refusing.createWallet(password: 'longpassword');
        final a = (await refusing.wallets()).last;
        await refusing.setSetupPending(a.id, true);
        return a;
      }))!;
      await pumpApp(tester, DeskRoute.unlock);
      await wait(tester, 800);
      expect(container.read(deskNavProvider).route, DeskRoute.setup, reason: 'pending: Unlock sends it to Setup');
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.byKey(const ValueKey('setup-skip')), findsOneWidget, reason: 'Skip from the first step');
      expect(find.text(l.deskSetupResumeLead), findsOneWidget, reason: 'a resumed Setup says so');
      await tester.tap(find.text('Continue'));
      await wait(tester, 1000);
      await tester.tap(find.text('Continue'));
      await wait(tester, 300);
      await tester.tap(find.text('Save settings'));
      await wait(tester, 800);
      expect(container.read(deskNavProvider).route, DeskRoute.setup, reason: 'Save failed: still on Review');
      expect(find.text(l.deskSetupSaveFailedTitle), findsOneWidget);
      // The failure is in the log, with its kind (item 27).
      expect(log.lines.where((line) => line.contains('setup not saved (first run)')), isNotEmpty, reason: log.lines.join('\n'));
      await tester.pump(const Duration(seconds: 5)); // the toast goes
      await tester.tap(find.byKey(const ValueKey('setup-skip')));
      await wait(tester, 800);
      expect(container.read(deskNavProvider).route, DeskRoute.unlock);
      expect(await tester.runAsync(() => refusing.setupPending(added.id)), stuck ? isTrue : isFalse);
      await wait(tester, 1500);
      expect(container.read(deskNavProvider).route, DeskRoute.unlock, reason: 'skipped: Unlock stays in this session');
      setupSkippedThisSession.clear();
      await end(tester);
    });
  }
}
