// The first run's node step: the combo preselects the first healthy node in
// the neutral order (never a hard-coded host); Local goes to its own step; the existing node
// needs a successful check; nothing starts the node before Save; Save sets the fallback answer.
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/local_node_step.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart' show nodeUrlOf;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mock wallet with a shuffled node list, recording the node calls.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

  @override
  Future<List<NodeServer>> nodes() async => const [
    NodeServer(url: 'https://epic-node.iniaku.my.id', label: 'Iniaku pool', operator: 'Iniaku pool', health: ServiceHealth.down, version: '4.1.1'),
    NodeServer(url: 'https://node.epiccash.com:3413', label: 'Epic Cash', operator: 'Epic Cash', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1'),
    NodeServer(url: 'https://epic.stackwallet.com:3413', label: 'Cypher Stack', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 210, height: 2914414, version: '4.1.1'),
    NodeServer(url: 'https://node.epicnet.us:3413', label: 'EpicNet', operator: 'EpicNet', health: ServiceHealth.ok, latencyMs: 132, height: 2914414, version: '4.1.1'),
  ];

  @override
  Future<void> useBuiltInNode(bool on) {
    calls.add('builtin $on');
    return super.useBuiltInNode(on);
  }

  @override
  Future<void> useNode(String url) {
    calls.add('node $url');
    return super.useNode(url);
  }
}

/// The real wallet's first answer: every node still being checked, in list order; [answer]
/// brings the results.
class _Checking extends _Wallet {
  bool answered = false;

  @override
  Future<List<NodeServer>> nodes() async => answered
      ? super.nodes()
      : [for (final n in await super.nodes()) NodeServer(url: n.url, label: n.label, operator: n.operator, health: ServiceHealth.checking)];
}

void main() {
  late _Wallet wallet;
  late MockDeskNode node;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    node = MockDeskNode();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskNodeProvider.overrideWithValue(node)]);
  });

  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester, Object? arg) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SetupScreen(arg: arg))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('the combo preselects the first healthy node in the neutral order, not the list’s first row', (tester) async {
    await show(tester, SetupStep.node);
    expect(find.text('Choose a node'), findsOneWidget);
    expect(find.text('The wallet reads the chain and sends through an Epic node.'), findsOneWidget);
    final combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, 'https://node.epicnet.us:3413', reason: 'healthy, the lowest latency');
    expect(combo.fieldText, 'node.epicnet.us:3413');
    expect(find.text('default'), findsNothing);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('Local → its own step; Continue needs a found node for the existing option; the bundled node needs nothing', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text('Local node'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('What running the node here means, and which node to use.'), findsOneWidget);
    expect(find.textContaining('A separate program.', findRichText: true), findsOneWidget);
    expect(find.text('Start the bundled node'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Use node.epiccash.com until the local node is synced')), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNotNull, reason: 'bundled is preselected when nothing answers');

    await tester.tap(find.text('Use a node already running on this computer'));
    await tester.pumpAndSettle();
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNull, reason: 'not checked yet');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No node answers', findRichText: true), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNull);

    node.probeAnswer = const LocalNodeProbe(url: 'http://127.0.0.1:3413', answers: true, version: '4.1.1', height: 3764975, readyForTxs: true, latencyMs: 2);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Found', findRichText: true), findsOneWidget);
    expect(find.textContaining('Epic 4.1.1 at 127.0.0.1:3413 · height 3,764,975 · synced', findRichText: true), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNotNull);
    expect(node.calls.where((c) => c == 'start'), isEmpty);
    expect(wallet.calls, isEmpty, reason: 'nothing moves before Save');
    await end(tester);
  });

  testWidgets('the bundled node: Review names the type, the fallback and the folder; Save is the only start and answers the fallback question', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text('Local node'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Receive when offline'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review settings'), findsOneWidget);
    expect(find.text('Local node, bundled'), findsOneWidget);
    expect(find.text('node.epiccash.com'), findsOneWidget);
    expect(find.text(mockDataFolder), findsOneWidget);
    expect(find.textContaining('Save starts the node; node.epiccash.com stands in'), findsOneWidget);
    expect(wallet.calls, isEmpty);
    expect(node.calls.where((c) => c.startsWith('start')), isEmpty);

    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    // Another node left chain data on the mock's computer: the reuse question first.
    expect(find.text('Chain data found'), findsOneWidget);
    await tester.tap(find.text('Download fresh'));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(wallet.calls, ['builtin true']);
    expect(node.calls, contains('fallback accepted $defaultFallbackNodeUrl'));
    expect(container.read(settingsPrefsProvider).builtin, isTrue);
    await end(tester);
  });

  testWidgets('the remote path: Save uses the picked node and leaves the local node alone', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Remote node'), findsOneWidget);
    expect(find.text('https://node.epicnet.us:3413'), findsOneWidget);
    await tester.tap(find.text('Save settings'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(wallet.calls, ['node https://node.epicnet.us:3413']);
    expect(node.calls, isEmpty);
    await end(tester);
  });

  testWidgets('every node still being checked: nothing preselected; as results come in, the fastest healthy one', (tester) async {
    final checking = _Checking();
    wallet = checking;
    container.dispose();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(checking), deskNodeProvider.overrideWithValue(node)]);
    await show(tester, SetupStep.node);
    var combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, '', reason: 'a node being checked is not healthy, whatever its place in the list');
    expect(combo.tone, ETone.neutral);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNull);

    checking.answered = true;
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pump();
    combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, 'https://node.epicnet.us:3413', reason: 'healthy, the lowest latency');
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Continue')).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('a pick stays when later results come in', (tester) async {
    final checking = _Checking();
    wallet = checking;
    container.dispose();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(checking), deskNodeProvider.overrideWithValue(node)]);
    await show(tester, SetupStep.node);
    tester.widget<ServerListPanel>(find.byType(ServerListPanel)).onChoose('epic.stackwallet.com:3413');
    await tester.pump();
    checking.answered = true;
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pump();
    expect(tester.widget<ServerListPanel>(find.byType(ServerListPanel)).value, 'https://epic.stackwallet.com:3413', reason: 'typed without a scheme: https');
    await end(tester);
  });

  testWidgets('a typed address without a scheme: https, except on this computer or the local network', (tester) async {
    expect(nodeUrlOf('node.example.org:3413'), 'https://node.example.org:3413');
    expect(nodeUrlOf('10.0.1.24:3413'), 'http://10.0.1.24:3413');
    expect(nodeUrlOf('127.0.0.1:3413'), 'http://127.0.0.1:3413');
    expect(nodeUrlOf('localhost:3413'), 'http://localhost:3413');
    expect(nodeUrlOf('http://node.example.org'), 'http://node.example.org');
  });

  Future<void> rerun(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    // From Settings › This wallet › Run setup: Back has somewhere to go.
    container.read(deskNavProvider.notifier)
      ..reset(DeskRoute.overview)
      ..go(DeskRoute.setup);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SetupScreen())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    // Preferences (the language) comes first; the node step is next.
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  Future<void> toReviewAndSave(WidgetTester tester) async {
    while (find.text('Review settings').evaluate().isEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save settings'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('run again with a remote node: starts from the current node; Save unchanged moves nothing', (tester) async {
    await rerun(tester);
    final current = container.read(deskProvider).status!.node.url;
    expect(tester.widget<ServerListPanel>(find.byType(ServerListPanel)).value, current, reason: 'not a preselection over the node in use');
    await toReviewAndSave(tester);
    expect(wallet.calls, isEmpty, reason: 'same node: no useNode, the local node untouched');
    expect(node.calls.where((c) => c == 'stop'), isEmpty);
    await end(tester);
  });

  testWidgets('run again with the local node: Local stays chosen; Save unchanged keeps it running', (tester) async {
    container.read(settingsPrefsProvider.notifier).set(container.read(settingsPrefsProvider).copyWith(builtin: true));
    await rerun(tester);
    expect(tester.widget<EChoiceCard>(find.widgetWithText(EChoiceCard, 'Local node')).selected, isTrue);
    await toReviewAndSave(tester);
    expect(wallet.calls, isEmpty, reason: 'no useNode to a public node, no second start');
    expect(container.read(settingsPrefsProvider).builtin, isTrue);
    await end(tester);
  });

  testWidgets('the fallback answer is stored only after the reuse question is answered', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text('Local node'));
    await tester.pumpAndSettle();
    await toReviewAndSave(tester);
    expect(find.text('Chain data found'), findsOneWidget);
    expect(node.calls.where((c) => c.startsWith('fallback')), isEmpty, reason: 'nothing answered while the question is open');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(node.calls.where((c) => c.startsWith('fallback')), isEmpty, reason: 'cancelled: nothing stored, nothing started');
    expect(wallet.calls, isEmpty);
    await end(tester);
  });

  testWidgets('the Settings dialog: the same content; the primary action follows the option', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    LocalNodeChoice? out;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: Builder(builder: (c) => EButton(label: 'open', onPressed: () async => out = await showLocalNodeSetupDialog(c, demo: LocalNodeDemo.found)))),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Local node'), findsOneWidget);
    expect(find.text('Use this node'), findsOneWidget, reason: 'a found node preselects the existing option');
    await tester.tap(find.text('Start the bundled node'));
    await tester.pumpAndSettle();
    expect(find.text('Start local node'), findsOneWidget);
    await tester.tap(find.text('Start local node'));
    await tester.pumpAndSettle();
    expect(out?.how, LocalNodeHow.bundled);
    expect(out?.useFallback, isTrue);
    expect(node.calls.where((c) => c == 'start'), isEmpty, reason: 'the dialog starts nothing');
  });
}
