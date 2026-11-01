// SPDX-License-Identifier: Apache-2.0
// Wallet levels, first start on the desktop: Welcome's dial holds the doors until a stop is
// picked, Shallow skips Set up, Settings › Advanced at Shallow is the Depth row alone, Change
// level saves a pick, About names the depth.
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/depth_dial.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/welcome_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_level.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/first_start.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

  @override
  Future<String> epicboxAddress() async => throw DeskError.l10n((l) => l.deskErrWalletLocked);

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
}

class _Router extends ConsumerWidget {
  const _Router();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(deskNavProvider);
    return KeyedSubtree(
      key: ValueKey(at.route),
      child: switch (at.route) {
        DeskRoute.welcome => WelcomeScreen(arg: at.arg),
        DeskRoute.setup => SetupScreen(arg: at.arg),
        DeskRoute.unlock => UnlockScreen(arg: at.arg),
        DeskRoute.settingsAdvanced => SettingsAdvancedScreen(arg: at.arg),
        DeskRoute.settingsLevel => SettingsLevelScreen(arg: at.arg),
        _ => Text('at ${at.route.name}'),
      },
    );
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;
  late MemorySecretStore store;

  ProviderContainer make({WalletLevel? level}) => ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(wallet),
      deskNodeProvider.overrideWithValue(MockDeskNode()),
      secretStoreProvider.overrideWithValue(store),
      relayProbeProvider.overrideWithValue(FakeRelayProbe()),
      if (level != null) deskLevelProvider.overrideWithValue(level),
    ],
  );

  setUp(() {
    wallet = _Wallet();
    store = MemorySecretStore();
  });

  tearDown(() {
    NetGate.releaseFirstStart();
    container.dispose();
  });

  Future<void> pumpApp(WidgetTester tester, DeskRoute route, {Object? arg, int height = 800}) async {
    tester.view.physicalSize = Size(1280, height.toDouble());
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

  testWidgets('Welcome on a fresh install: no stop picked, the doors wait for one, the pick opens the gate', (tester) async {
    NetGate.holdFirstStart();
    container = make();
    await pumpApp(tester, DeskRoute.welcome);
    expect(find.text('Pick your view'), findsOneWidget);
    expect(find.text('Pick a stop'), findsOneWidget);
    expect(find.text('Pick a view first. Nothing connects until you do.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('door-create')), warnIfMissed: false);
    await tester.pump();
    expect(container.read(deskNavProvider).route, DeskRoute.welcome, reason: 'a door does nothing before a stop is picked');
    expect(NetGate.firstStartHold, isTrue);

    await tester.tap(find.byKey(deskLevelStopKey(WalletLevel.justSendReceive)));
    await tester.pump();
    expect(find.text('Send, receive, done. The wallet minds the rest.'), findsOneWidget);
    expect(find.text('Pick a view first. Nothing connects until you do.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('door-create')));
    await wait(tester, 300);
    expect(container.read(deskNavProvider).route, DeskRoute.create);
    expect(container.read(deskLevelProvider), WalletLevel.justSendReceive);
    expect(NetGate.firstStartHold, isFalse, reason: 'the gate opens with the answer');
    expect(await store.read(levelKey), '1');
    await end(tester);
  });

  testWidgets('Welcome with nothing held: the current depth is on the dial and the doors work without a pick', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.welcome);
    expect(container.read(firstStartProvider), isFalse);
    expect(find.text('Deep end'), findsWidgets);
    expect(find.text('Pick a stop'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('door-restore')));
    await wait(tester, 200);
    expect(container.read(deskNavProvider).route, DeskRoute.restore);
    expect(await store.read(levelKey), isNot(anyOf('1', '2', '3')), reason: 'no depth stored without a change');
    await end(tester);
  });

  testWidgets('Welcome with nothing held: another stop is stored when a door is pressed', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.welcome);
    await tester.tap(find.byKey(deskLevelStopKey(WalletLevel.casual)));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('door-create')));
    await wait(tester, 300);
    expect(container.read(deskLevelProvider), WalletLevel.casual);
    expect(container.read(deskNavProvider).route, DeskRoute.create);
    await end(tester);
  });

  testWidgets('Set up at Shallow: skipped after the phrase, its defaults saved, Unlock follows', (tester) async {
    container = make(level: WalletLevel.justSendReceive);
    await pumpApp(tester, DeskRoute.setup, arg: const SetupFirstRun(UnlockAdded('Wallet', id: 'x')));
    await wait(tester, 800);
    expect(find.text('Choose a node'), findsNothing);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    expect(wallet.calls.where((c) => c.startsWith('node ')), isEmpty, reason: 'the node stays automatic');
    await end(tester);
  });

  testWidgets('Set up at Deeper: the wizard as today', (tester) async {
    container = make(level: WalletLevel.casual);
    await pumpApp(tester, DeskRoute.setup, arg: const SetupFirstRun(UnlockAdded('Wallet', id: 'x')));
    await wait(tester, 800);
    expect(find.text('Choose a node'), findsOneWidget);
    expect(container.read(deskNavProvider).route, DeskRoute.setup);
    await end(tester);
  });

  testWidgets('Unlock at Shallow has no Add a wallet; at Deep end it does', (tester) async {
    container = make(level: WalletLevel.justSendReceive);
    await pumpApp(tester, DeskRoute.unlock);
    await wait(tester, 500);
    expect(find.text('Add a wallet'), findsNothing);
    await end(tester);
    container.dispose();
    container = make(level: WalletLevel.everything);
    await pumpApp(tester, DeskRoute.unlock);
    await wait(tester, 500);
    expect(find.text('Add a wallet'), findsOneWidget);
    await end(tester);
  });

  testWidgets('Settings › Advanced at Shallow: the Depth row alone', (tester) async {
    container = make(level: WalletLevel.justSendReceive);
    await pumpApp(tester, DeskRoute.settingsAdvanced, height: 900);
    expect(find.byKey(const ValueKey('adv-depth')), findsOneWidget);
    expect(find.text('Shallow'), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-outputs')), findsNothing);
    expect(find.byKey(const ValueKey('adv-experimental')), findsNothing);
    expect(find.byKey(const ValueKey('adv-mode-standard')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('adv-depth-change')));
    await tester.pump();
    expect(container.read(deskNavProvider).route, DeskRoute.settingsLevel);
    await end(tester);
  });

  testWidgets('Settings › Advanced at Deeper: the Depth row on top of today\'s page', (tester) async {
    container = make(level: WalletLevel.casual);
    await pumpApp(tester, DeskRoute.settingsAdvanced, height: 900);
    expect(find.byKey(const ValueKey('adv-depth')), findsOneWidget);
    expect(find.text('Deeper'), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-outputs')), findsOneWidget);
    expect(find.byKey(const ValueKey('adv-experimental')), findsOneWidget);
    await end(tester);
  });

  testWidgets('Change level: a pick applies at once, no Save; the preview follows', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.settingsAdvanced, height: 900);
    container.read(deskNavProvider.notifier).go(DeskRoute.settingsLevel);
    await tester.pump();
    expect(find.text('Save'), findsNothing);
    expect(find.byKey(deskLevelPreviewKey), findsOneWidget);
    await tester.tap(find.byKey(deskLevelStopKey(WalletLevel.casual)));
    await wait(tester, 300);
    expect(container.read(deskLevelProvider), WalletLevel.casual);
    expect(await store.read(levelKey), '2');
    expect(container.read(deskNavProvider).route, DeskRoute.settingsLevel, reason: 'stays on the page');
    await end(tester);
  });
}
