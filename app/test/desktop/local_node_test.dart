// The local node panel (spec §19, §22): a fake state stream through starting → headers →
// chain state download → kernels → blocks → synced, asserting the word, the stage line, the
// overall %, the step strip and the rail line; then stalled, each failure, stopped; the Ask
// dialog once and never again; Change… under While syncing; Delete's typed confirm; Reuse's
// candidates; nothing starts the node without Start.
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart';
import 'package:epic_wallet/src/desktop/screens/settings/local_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/local_node_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDeskNode node;
  late ProviderContainer container;

  setUp(() {
    node = MockDeskNode();
    fallbackAskedThisSession = false;
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskNodeProvider.overrideWithValue(node)]);
  });

  tearDown(() => container.dispose());

  /// Settings › Node with the local node in use.
  Future<void> show(WidgetTester tester, {FallbackChoice choice = const FallbackChoice.unasked(), LocalNodeState? state}) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (state != null) node.show(state);
    await node.setFallbackChoice(choice);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(settingsPrefsProvider.notifier).set(container.read(settingsPrefsProvider).copyWith(builtin: true));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsNodeScreen())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
  }

  Future<void> step(WidgetTester tester, LocalNodeState s) async {
    node.show(s);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String headText(WidgetTester tester) => tester.widget<ESignalBars>(find.byType(ESignalBars).last).state.name;

  testWidgets('a notice that goes away eases out with its own words, not an empty box', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.error, failure: NodeFailure.diskLow));
    expect(find.text('Less than 2 GB free on this volume.'), findsOneWidget);
    node.show(mockLocalNode(LocalNodePhase.synced));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Less than 2 GB free on this volume.'), findsOneWidget, reason: 'still the child while it closes');
    await end(tester);
  });

  testWidgets('reduced motion: an unknown amount shows a still bar; a panel under 150 u lays out', (tester) async {
    node.show(mockLocalNode(LocalNodePhase.starting));
    await node.setFallbackChoice(const FallbackChoice(FallbackConsent.accepted));
    for (final width in [900.0, 140.0]) {
      // Rows overflow at 140 (the page is never that narrow); what matters is no thrown clamp.
      final errors = <Object>[];
      final was = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exception);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true, size: Size(1280, 900)),
              child: Scaffold(
                body: SingleChildScrollView(child: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: const LocalNodePanel()))),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      FlutterError.onError = was;
      expect(errors.whereType<ArgumentError>(), isEmpty);
      if (width > 200) expect(errors, isEmpty);
      if (width > 200) expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 1, reason: 'no sweep');
    }
    await end(tester);
  });

  testWidgets('starting → headers → download → kernels → blocks → synced: word, stage line, %, strip, rail line', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.starting));
    expect(find.textContaining('Starting', findRichText: true), findsWidgets);
    expect(find.textContaining('waiting for peers', findRichText: true), findsOneWidget);
    expect(find.text('Connecting to peers'), findsOneWidget);
    expect(tester.widget<StageStrip>(find.byType(StageStrip)).step, isNull);

    final steps = <(LocalNodeState, String, int, String, String)>[
      (mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: 3764975, eta: const Duration(hours: 3)), 'Headers · 1,480,200 of 3,764,975', 0, '12 % · about 3 h left', 'epiccash.com · 12 %'),
      (mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateDownload, overall: 0.46, done: 1900000000, total: 4100000000, eta: const Duration(minutes: 40)), 'Chain state · 1.9 of 4.1 GB', 1, '46 % · about 40 min left', 'epiccash.com · 46 %'),
      (mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateKernels, overall: 0.7, done: 2100000, total: 3400000), 'Checking kernels · 2.1 of 3.4 million', 1, '70 % · no estimate; up to an hour', 'epiccash.com · 70 %'),
      (mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.blocks, overall: 0.96, done: 3702100, total: 3764975, eta: const Duration(minutes: 12)), 'Blocks · 3,702,100 of 3,764,975', 2, '96 % · about 12 min left', 'epiccash.com · 96 %'),
    ];
    for (final (s, line, strip, right, rail) in steps) {
      await step(tester, s);
      expect(find.textContaining('Syncing', findRichText: true), findsWidgets, reason: line);
      expect(find.text(line), findsOneWidget, reason: line);
      expect(find.text(right), findsOneWidget, reason: line);
      expect(tester.widget<StageStrip>(find.byType(StageStrip)).step, strip, reason: line);
      expect(find.textContaining('using node.epiccash.com meanwhile', findRichText: true), findsOneWidget, reason: line);
      expect(localNodeView(englishStrings, s, fallbackUrl: defaultFallbackNodeUrl).second, rail, reason: line);
      expect(tester.takeException(), isNull, reason: line);
    }

    await step(tester, mockLocalNode(LocalNodePhase.synced));
    expect(find.textContaining('Synced', findRichText: true), findsWidgets);
    expect(find.textContaining('3,764,975 · at tip', findRichText: true), findsOneWidget);
    expect(find.byType(StageStrip), findsNothing);
    expect(find.text('Peers'), findsWidgets, reason: 'the tiles');
    expect(localNodeView(englishStrings, mockLocalNode(LocalNodePhase.synced)).second, 'Local node');
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    await end(tester);
  });

  testWidgets('syncing without the fallback: the info notice offers the public node; stalled, each failure, stopped', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.declined), state: mockLocalNode(LocalNodePhase.syncing, overall: 0.12));
    expect(find.text('Nothing can be sent or received until the local node is synced.'), findsOneWidget);
    expect(find.text('Use node.epiccash.com meanwhile'), findsOneWidget);

    await step(tester, mockLocalNode(LocalNodePhase.error, stalled: true));
    expect(find.textContaining('Stalled', findRichText: true), findsWidgets);
    expect(find.text('The node makes no progress.'), findsOneWidget);
    expect(headText(tester), 'risk');

    final failures = <NodeFailure, String>{
      NodeFailure.portInUse: 'Port 3413 is used by another program.',
      NodeFailure.diskLow: 'Less than 2 GB free on this volume.',
      NodeFailure.binaryMissing: 'The node program is missing from this installation.',
      NodeFailure.exited: 'The node stopped by itself.',
    };
    for (final e in failures.entries) {
      await step(tester, mockLocalNode(LocalNodePhase.error, failure: e.key, reason: e.key == NodeFailure.exited ? 'exit code 101' : null));
      expect(find.textContaining('Failed', findRichText: true), findsWidgets, reason: e.key.name);
      expect(find.text(e.value), findsOneWidget, reason: e.key.name);
      expect(find.text('Start'), e.key == NodeFailure.binaryMissing ? findsNothing : findsOneWidget, reason: e.key.name);
      expect(find.byType(StageStrip), findsNothing, reason: e.key.name);
    }
    expect(find.textContaining('(exit code 101)', findRichText: true), findsOneWidget);

    await step(tester, mockLocalNode(LocalNodePhase.stopped));
    expect(find.textContaining('Stopped', findRichText: true), findsWidgets);
    expect(find.textContaining('nothing can be sent until it runs', findRichText: true), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('stopped 14:02'), findsOneWidget);
    expect(node.calls.where((c) => c == 'start'), isEmpty, reason: 'nothing starts the node by itself');
    await end(tester);
  });

  testWidgets('the Ask dialog (D-7) shows once when syncing starts unasked; its title names the fallback; never again after an answer', (tester) async {
    await show(tester, state: mockLocalNode(LocalNodePhase.stopped));
    expect(find.text('Use node.epiccash.com until the local node is synced?'), findsNothing);
    await step(tester, mockLocalNode(LocalNodePhase.syncing, overall: 0.1));
    await tester.pumpAndSettle();
    expect(find.text('Use node.epiccash.com until the local node is synced?'), findsOneWidget);
    await tester.tap(find.text('Use node.epiccash.com'));
    await tester.pumpAndSettle();
    expect(find.byType(EDialog), findsNothing);
    expect(node.calls, contains('fallback accepted $defaultFallbackNodeUrl'));
    await step(tester, mockLocalNode(LocalNodePhase.stopped));
    await step(tester, mockLocalNode(LocalNodePhase.syncing, overall: 0.2));
    await tester.pumpAndSettle();
    expect(find.byType(EDialog), findsNothing, reason: 'asked once');
    await end(tester);
  });

  testWidgets('flipping the While syncing switch answers an unasked state, so the dialog never shows', (tester) async {
    await show(tester, state: mockLocalNode(LocalNodePhase.stopped));
    await tester.tap(find.bySemanticsLabel('Use node.epiccash.com while syncing'));
    await tester.pump();
    expect(node.calls.last, startsWith('fallback accepted'));
    await step(tester, mockLocalNode(LocalNodePhase.syncing, overall: 0.1));
    await tester.pumpAndSettle();
    expect(find.byType(EDialog), findsNothing);
    await end(tester);
  });

  testWidgets('Change… under While syncing changes the row text, the detail and the rail line', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.syncing, overall: 0.12));
    expect(find.text('Use node.epiccash.com until the local node is synced. The local node takes over by itself.'), findsOneWidget);
    // Two Change… buttons: While syncing comes before Data folder.
    await tester.tap(find.text('Change…').first);
    await tester.pumpAndSettle();
    expect(find.text('Node while syncing'), findsOneWidget);
    expect(find.descendant(of: find.byType(EDialog), matching: find.text('Local node')), findsNothing, reason: 'no This computer group in the fallback list');
    await tester.tap(find.text('node.btlabs.uk'));
    await tester.pumpAndSettle();
    expect(find.text('Use node.btlabs.uk until the local node is synced. The local node takes over by itself.'), findsOneWidget);
    expect(find.textContaining('using node.btlabs.uk meanwhile', findRichText: true), findsOneWidget);
    expect(localNodeView(englishStrings, node.state, fallbackUrl: 'https://node.btlabs.uk').second, 'btlabs.uk · 12 %');
    await end(tester);
  });

  testWidgets('Delete chain data enables only on exactly "delete"; then stops and deletes', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.synced));
    await tester.tap(find.text('Delete…'));
    await tester.pumpAndSettle();
    expect(find.text('Delete chain data?'), findsOneWidget);
    expect(find.textContaining('Removes 5.2 GB from'), findsOneWidget);
    final button = find.widgetWithText(EButton, 'Delete chain data');
    expect(tester.widget<EButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(EditableText), 'Delete');
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNull, reason: 'case-sensitive');
    await tester.enterText(find.byType(EditableText), ' delete ');
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNotNull, reason: 'trimmed');
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(node.calls, containsAllInOrder(['stop', 'delete']));
    expect(find.text('Chain data deleted'), findsOneWidget);
    await end(tester);
  });

  testWidgets('a pointed folder: Delete is off with the sub-text', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.synced, origin: ChainDataOrigin.pointed));
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Delete…')).onPressed, isNull);
    expect(find.text('This node reads another program’s folder; delete it there.'), findsOneWidget);
    await end(tester);
  });

  testWidgets('Reuse lists the candidates, disables the one in use, and points the node at the pick', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.stopped));
    await tester.tap(find.text('Reuse existing…'));
    await tester.pumpAndSettle();
    expect(find.text('Chain data found'), findsOneWidget);
    expect(find.text('~/.epic/main/chain_data'), findsOneWidget);
    expect(find.text('~/.epic-gui/node/main/chain_data'), findsOneWidget);
    expect(find.textContaining('In use by another program'), findsOneWidget);
    expect(find.text('Download fresh'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(node.calls, contains('reuse point ~/.epic/main/chain_data'));
    await end(tester);
  });

  testWidgets('the node log: 200 lines, newest at the bottom, Copy', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.synced));
    await tester.tap(find.text('View node log'));
    await tester.pumpAndSettle();
    expect(find.text('Node log'), findsOneWidget);
    expect(find.textContaining('bad block from 203.0.113.9:3414', findRichText: true), findsOneWidget);
    expect(find.text('Last 200 lines of epic-server.log in the data folder. Newest at the bottom.'), findsOneWidget);
    await end(tester);
  });

  testWidgets('controls: Start when stopped; Stop and Restart while running; Start with the app switch', (tester) async {
    await show(tester, choice: const FallbackChoice(FallbackConsent.accepted), state: mockLocalNode(LocalNodePhase.stopped));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(node.calls, contains('start'));
    expect(find.text('Stop'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(node.calls.last, 'restart');
    expect(find.bySemanticsLabel('Start with the app'), findsOneWidget);
    await end(tester);
  });

  test('statusWords: the table of §19', () {
    expect(statusWords(englishStrings, mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.blocks), fallback: 'node.epiccash.com', accepted: true).detail, 'blocks · using node.epiccash.com meanwhile');
    expect(statusWords(englishStrings, mockLocalNode(LocalNodePhase.stopped), fallback: 'node.epiccash.com', accepted: true).detail, 'the wallet uses node.epiccash.com meanwhile');
    expect(statusWords(englishStrings, mockLocalNode(LocalNodePhase.error, failure: NodeFailure.diskLow), fallback: 'x', accepted: true).notice?.action, NodeAct.folder);
    expect(statusWords(englishStrings, mockLocalNode(LocalNodePhase.error, failure: NodeFailure.binaryMissing), fallback: 'x', accepted: true).notice?.action, isNull);
  });
}
