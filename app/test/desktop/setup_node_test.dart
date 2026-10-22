// The first run's node step (spec §21, §22): the combo preselects the first healthy node in
// the neutral order (never a hard-coded host); Local goes to its own step; the existing node
// needs a successful check; nothing starts the node before Save; Save sets the D-7 answer.
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/local_node_step.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/combo.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
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
    final combo = tester.widget<ServiceCombo>(find.byType(ServiceCombo));
    expect(combo.value, 'https://node.epicnet.us:3413', reason: 'healthy, the lowest latency');
    expect(combo.fieldText, 'node.epicnet.us');
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

  testWidgets('the bundled node: Review names the type, the fallback and the folder; Save is the only start and answers D-7', (tester) async {
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
    expect(find.text('Check settings'), findsOneWidget);
    expect(find.text('Local node, bundled'), findsOneWidget);
    expect(find.text('node.epiccash.com'), findsOneWidget);
    expect(find.text(mockDataFolder), findsOneWidget);
    expect(find.textContaining('Save starts the node. The first sync takes hours'), findsOneWidget);
    expect(wallet.calls, isEmpty);
    expect(node.calls.where((c) => c.startsWith('start')), isEmpty);

    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    // Another node left chain data on the mock's computer: the reuse question first.
    expect(find.text('Chain data found on this computer'), findsOneWidget);
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
