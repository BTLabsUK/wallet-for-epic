// SPDX-License-Identifier: Apache-2.0
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
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

final _l = englishStrings;

/// The mock wallet with a shuffled node list, recording the node calls.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

  @override
  Future<List<NodeServer>> nodes() async => const [
    NodeServer(url: 'https://node.pool.example.org', label: 'Pool op', operator: 'Pool op', health: ServiceHealth.down, version: '4.1.1'),
    NodeServer(url: 'https://node.epic.invalid:3413', label: 'Epic Cash', operator: 'Epic Cash', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1'),
    NodeServer(url: 'https://node.stack.invalid:3413', label: 'Cypher Stack', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 210, height: 2914414, version: '4.1.1'),
    NodeServer(url: 'https://node.net.invalid:3413', label: 'EpicNet', operator: 'EpicNet', health: ServiceHealth.ok, latencyMs: 132, height: 2914414, version: '4.1.1'),
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

/// No network: every node's check came back down.
class _AllDown extends _Wallet {
  @override
  Future<List<NodeServer>> nodes() async =>
      [for (final n in await super.nodes()) NodeServer(url: n.url, label: n.label, operator: n.operator, health: ServiceHealth.down)];
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
    expect(find.text(_l.deskSetupNodeTitle), findsOneWidget);
    expect(find.text(_l.deskSetupNodeLead), findsOneWidget);
    final combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, 'https://node.net.invalid:3413', reason: 'healthy, the lowest latency');
    expect(combo.fieldText, 'node.net.invalid:3413');
    expect(find.text(_l.deskSendDefaultTag), findsNothing);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('no node answers (no network): nothing preselected, and the step says why', (tester) async {
    wallet = _AllDown();
    container.dispose();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskNodeProvider.overrideWithValue(node)]);
    await show(tester, SetupStep.node);
    expect(tester.widget<ServerListPanel>(find.byType(ServerListPanel)).value, '');
    expect(find.byKey(const ValueKey('setup-no-node-answers')), findsOneWidget);
    expect(find.text(_l.deskOnbNodeNoAnswer), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNull);
    await end(tester);
  });

  testWidgets('a healthy node: no "No node answers" line', (tester) async {
    await show(tester, SetupStep.node);
    expect(find.byKey(const ValueKey('setup-no-node-answers')), findsNothing);
    await end(tester);
  });

  testWidgets('Local → its own step; Continue needs a found node for the existing option; the bundled node needs nothing', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text(_l.deskSetupLocalTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text('What running the node here means, and which node to use.'), findsOneWidget);
    expect(find.text(_l.deskOnbNodeBundled), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Use node.epic.invalid until the local node is synced')), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNotNull, reason: 'bundled is preselected when nothing answers');

    await tester.tap(find.text(_l.deskOnbNodeExisting));
    await tester.pumpAndSettle();
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNull, reason: 'not checked yet');
    await tester.tap(find.text(_l.deskOnbNodeCheck));
    await tester.pumpAndSettle();
    expect(find.textContaining(_l.deskOnbNodeNoAnswer, findRichText: true), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNull);

    node.probeAnswer = const LocalNodeProbe(url: 'http://127.0.0.1:3413', answers: true, version: '4.1.1', height: 3764975, readyForTxs: true, latencyMs: 2);
    await tester.tap(find.text(_l.deskOnbNodeCheck));
    await tester.pumpAndSettle();
    expect(find.textContaining(_l.deskOnbNodeFound, findRichText: true), findsOneWidget);
    expect(find.textContaining('Found\u00A0· Epic 4.1.1 at 127.0.0.1:3413\u00A0· height 3,764,975\u00A0· synced', findRichText: true), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNotNull);
    expect(node.calls.where((c) => c == 'start'), isEmpty);
    expect(wallet.calls, isEmpty, reason: 'nothing moves before Save');
    await end(tester);
  });

  testWidgets('an empty Node list: no fallback is offered, Review says the wallet waits, Save declines it', (tester) async {
    // Audit 26.10.24: the checkbox read "Use  until…" with no host and a yes stored an empty node.
    hostSettings = testSettings().withValues({'node.servers': <String>[]});
    expect(hasFallbackNode, isFalse);
    await show(tester, SetupStep.node);
    await tester.tap(find.text(_l.deskSetupLocalTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskOnbNodeBundled), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('until the local node is synced')), findsNothing);
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetupReviewTitle), findsOneWidget);
    expect(find.text(_l.deskSetupWait), findsOneWidget);
    expect(find.textContaining('stands in'), findsNothing);
    await tester.tap(find.text(_l.deskSetupSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.deskSetLndFresh));
    await tester.tap(find.text(_l.commonContinue));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(node.calls.where((c) => c.startsWith('fallback accepted')), isEmpty);
    await end(tester);
  });

  testWidgets('the bundled node: Review names the type, the fallback and the folder; Save is the only start and answers the fallback question', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text(_l.deskSetupLocalTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetupEpicboxText), findsOneWidget);
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetupReviewTitle), findsOneWidget);
    expect(find.text(_l.deskSetupBundledNode), findsWidgets);
    expect(find.text(hostPort(defaultFallbackNodeUrl)), findsOneWidget);
    expect(find.text(mockDataFolder), findsOneWidget);
    expect(find.textContaining('Save starts the node; ${hostPort(defaultFallbackNodeUrl)} stands in'), findsOneWidget);
    expect(wallet.calls, isEmpty);
    expect(node.calls.where((c) => c.startsWith('start')), isEmpty);

    await tester.tap(find.text(_l.deskSetupSave));
    await tester.pumpAndSettle();
    // Another node left chain data on the mock's computer: the reuse question first.
    expect(find.text(_l.deskSetLndReuseTitle), findsOneWidget);
    await tester.tap(find.text(_l.deskSetLndFresh));
    await tester.tap(find.text(_l.commonContinue));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(wallet.calls, ['builtin true']);
    expect(node.calls, contains('fallback accepted $defaultFallbackNodeUrl'));
    expect(container.read(settingsPrefsProvider).builtin, isTrue);
    await end(tester);
  });

  testWidgets('the remote path: Save uses the picked node and leaves the local node alone', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text(_l.commonContinue));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.commonContinue));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetupRemoteNode), findsOneWidget);
    expect(find.text('node.net.invalid:3413'), findsOneWidget);
    await tester.tap(find.text(_l.deskSetupSave));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(wallet.calls, ['node https://node.net.invalid:3413']);
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
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNull);

    checking.answered = true;
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pump();
    combo = tester.widget<ServerListPanel>(find.byType(ServerListPanel));
    expect(combo.value, 'https://node.net.invalid:3413', reason: 'healthy, the lowest latency');
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonContinue)).onPressed, isNotNull);
    await end(tester);
  });

  testWidgets('a pick stays when later results come in', (tester) async {
    final checking = _Checking();
    wallet = checking;
    container.dispose();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(checking), deskNodeProvider.overrideWithValue(node)]);
    await show(tester, SetupStep.node);
    tester.widget<ServerListPanel>(find.byType(ServerListPanel)).onChoose('node.stack.invalid:3413');
    await tester.pump();
    checking.answered = true;
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pump();
    expect(tester.widget<ServerListPanel>(find.byType(ServerListPanel)).value, 'https://node.stack.invalid:3413', reason: 'typed without a scheme: https');
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
    await tester.tap(find.text(_l.commonContinue));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  Future<void> toReviewAndSave(WidgetTester tester) async {
    while (find.text(_l.deskSetupReviewTitle).evaluate().isEmpty) {
      await tester.tap(find.text(_l.commonContinue));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(_l.deskSetupSave));
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
    expect(tester.widget<EChoiceCard>(find.widgetWithText(EChoiceCard, _l.deskSetupLocalTitle)).selected, isTrue);
    await toReviewAndSave(tester);
    expect(wallet.calls, isEmpty, reason: 'no useNode to a public node, no second start');
    expect(container.read(settingsPrefsProvider).builtin, isTrue);
    await end(tester);
  });

  testWidgets('the fallback answer is stored only after the reuse question is answered', (tester) async {
    await show(tester, SetupStep.node);
    await tester.tap(find.text(_l.deskSetupLocalTitle));
    await tester.pumpAndSettle();
    await toReviewAndSave(tester);
    expect(find.text(_l.deskSetLndReuseTitle), findsOneWidget);
    expect(node.calls.where((c) => c.startsWith('fallback')), isEmpty, reason: 'nothing answered while the question is open');
    await tester.tap(find.text(_l.commonCancel));
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
    expect(find.text(_l.deskOnbNodeDialogTitle), findsOneWidget);
    expect(find.text(_l.deskOnbNodeUseThis), findsOneWidget, reason: 'a found node preselects the existing option');
    await tester.tap(find.text(_l.deskOnbNodeBundled));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskOnbNodeStart), findsOneWidget);
    await tester.tap(find.text(_l.deskOnbNodeStart));
    await tester.pumpAndSettle();
    expect(out?.how, LocalNodeHow.bundled);
    expect(out?.useFallback, isTrue);
    expect(out?.ports.api, hostSettings.localNodeApiPort, reason: 'Advanced untouched: the default ports');
    expect(node.calls.where((c) => c == 'start'), isEmpty, reason: 'the dialog starts nothing');
  });

  group('the Settings dialog, Advanced: the ports', () {
    Future<LocalNodeChoice? Function()> openDialog(WidgetTester tester) async {
      // Tall enough for the open fold and its error lines above the dialog's actions.
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      LocalNodeChoice? out;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(body: Builder(builder: (c) => EButton(label: 'open', onPressed: () async => out = await showLocalNodeSetupDialog(c, demo: LocalNodeDemo.notFound)))),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOnbNodeStart), findsOneWidget, reason: 'nothing found: the bundled node is chosen');
      return () => out;
    }

    Finder field(String label) => find.bySemanticsLabel(label);

    /// What the field with [label] holds (its hint shows the default, so the text is not unique).
    String textOf(WidgetTester tester, String label) =>
        tester.widget<EditableText>(find.descendant(of: field(label), matching: find.byType(EditableText))).controller.text;

    testWidgets('closed by default, with the defaults in the fields and no subtitle; the choice carries the typed ports', (tester) async {
      final out = await openDialog(tester);
      expect(find.text(_l.deskOnbNodeAdvanced), findsOneWidget);
      expect(find.text('API port'), findsNothing, reason: 'the fold is closed');
      expect(find.textContaining('API ${hostSettings.localNodeApiPort}', findRichText: true), findsNothing, reason: 'no subtitle at the defaults');
      await tester.tap(find.text(_l.deskOnbNodeAdvanced));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOnbNodeApiPort), findsOneWidget);
      expect(find.text(_l.deskOnbNodeP2pPort), findsOneWidget);
      expect(textOf(tester, _l.deskOnbNodeApiPort), '${hostSettings.localNodeApiPort}');
      expect(textOf(tester, 'P2P port'), '${hostSettings.localNodeP2pPort}');
      await tester.enterText(field('API port'), '13413');
      await tester.enterText(field('P2P port'), '13414');
      await tester.pumpAndSettle();
      expect(find.textContaining('API 13413 · P2P 13414', findRichText: true), findsOneWidget, reason: 'the subtitle names changed ports');
      await tester.tap(find.text(_l.deskOnbNodeStart));
      await tester.pumpAndSettle();
      expect(out()?.ports.api, 13413);
      expect(out()?.ports.p2p, 13414);
    });

    testWidgets('out of range or equal: an error under the field and the primary action off', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text(_l.deskOnbNodeAdvanced));
      await tester.pumpAndSettle();
      await tester.enterText(field(_l.deskOnbNodeApiPort), '80');
      await tester.pumpAndSettle();
      expect(find.text('A number from 1024 to 65535.'), findsOneWidget);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskOnbNodeStart)).onPressed, isNull);
      await tester.enterText(field(_l.deskOnbNodeApiPort), '13414');
      await tester.enterText(field(_l.deskOnbNodeP2pPort), '13414');
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOnbNodePortsSame), findsOneWidget);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskOnbNodeStart)).onPressed, isNull);
      await tester.enterText(field('P2P port'), '13415');
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOnbNodePortsSame), findsNothing);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskOnbNodeStart)).onPressed, isNotNull);
    });

    testWidgets('a port another program uses: named with the next free one on Save, a link fills it in, nothing is returned until free', (tester) async {
      node.busyPorts.addAll({13413, 13414});
      final out = await openDialog(tester);
      await tester.tap(find.text(_l.deskOnbNodeAdvanced));
      await tester.pumpAndSettle();
      await tester.enterText(field(_l.deskOnbNodeApiPort), '13413');
      await tester.enterText(field(_l.deskOnbNodeP2pPort), '13500');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.deskOnbNodeStart));
      await tester.pumpAndSettle();
      expect(out(), isNull, reason: 'the dialog stays open');
      expect(find.text('Port 13413 is used by another program. 13415 is free.'), findsOneWidget, reason: '13414 is taken too');
      await tester.tap(find.text('Use 13415'));
      await tester.pumpAndSettle();
      expect(find.textContaining('is used by another program'), findsNothing);
      expect(textOf(tester, 'API port'), '13415', reason: 'the link filled the field');
      await tester.tap(find.text(_l.deskOnbNodeStart));
      await tester.pumpAndSettle();
      expect(out()?.ports.api, 13415);
      expect(out()?.ports.p2p, 13500);
    });
  });
}
