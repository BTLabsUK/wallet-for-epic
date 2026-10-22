// D-14, spec §21: after a wallet is created or restored the first run goes password → phrase →
// Node → Epicbox → Review → Unlock. Setup starts on the node step with no way back to the
// phrase, preselects only a healthy node, and Save goes to Unlock. A second wallet starts from
// the current node.
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/create_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/combo.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

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
    expect(tester.widget<ServiceCombo>(find.byType(ServiceCombo)).value, node);
    await tester.tap(find.text('Continue'));
    await wait(tester, 1000);
    expect(find.text('Receive when offline'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await wait(tester, 300);
    expect(find.text('Check settings'), findsOneWidget);
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
    await tester.tap(find.textContaining('Written down'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await wait(tester, 800);
    final arg = container.read(deskNavProvider).arg;
    expect(arg, isA<SetupFirstRun>());
    // The mock keeps a legacy wallet, so this one is a second wallet: the current node first.
    expect((arg! as SetupFirstRun).added.name, 'Wallet 1');
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
    await tester.tap(find.text('Use 12 words'));
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
}
