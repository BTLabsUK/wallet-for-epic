// SPDX-License-Identifier: Apache-2.0
// First start on the desktop: a Welcome door answers the first-start step and opens the gate,
// a first run shows the Set up wizard, Unlock offers Add a wallet, and
// Settings › Advanced lists every switch.
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/undercover_row.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/setup_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/welcome_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/more_options.dart' show EMoreOptions;
import 'package:epic_wallet/src/first_start.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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
        _ => Text('at ${at.route.name}'),
      },
    );
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;
  late MemorySecretStore store;

  ProviderContainer make() => ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(wallet),
      deskNodeProvider.overrideWithValue(MockDeskNode()),
      secretStoreProvider.overrideWithValue(store),
      relayProbeProvider.overrideWithValue(FakeRelayProbe()),
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

  testWidgets('Welcome on a fresh install: a door answers the first step and opens the gate', (tester) async {
    NetGate.holdFirstStart();
    container = make();
    await pumpApp(tester, DeskRoute.welcome);
    expect(NetGate.firstStartHold, isTrue);
    await tester.tap(find.byKey(const ValueKey('door-create')));
    await wait(tester, 300);
    expect(container.read(deskNavProvider).route, DeskRoute.create);
    expect(NetGate.firstStartHold, isFalse, reason: 'the gate opens with the answer');
    expect(await store.read(firstStartKey), firstStartDone);
    await end(tester);
  });

  testWidgets('Welcome with nothing held: the doors work and nothing is stored', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.welcome);
    expect(container.read(firstStartProvider), isFalse);
    expect(find.byKey(deskUndercoverKey), findsNothing, reason: 'Tor only from the start is for a fresh install');
    await tester.tap(find.byKey(const ValueKey('door-restore')));
    await wait(tester, 200);
    expect(container.read(deskNavProvider).route, DeskRoute.restore);
    expect(await store.read(firstStartKey), isNull);
    await end(tester);
  });

  testWidgets('Set up on a first run: the wizard, after the phrase', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.setup, arg: const SetupFirstRun(UnlockAdded('Wallet', id: 'x')));
    await wait(tester, 800);
    expect(find.text(_l.deskSetupNodeTitle), findsOneWidget);
    expect(container.read(deskNavProvider).route, DeskRoute.setup);
    await end(tester);
  });

  testWidgets('Set up run again: the wizard', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.setup);
    await wait(tester, 800);
    expect(find.text(_l.deskSetupNodeTitle), findsOneWidget);
    expect(container.read(deskNavProvider).route, DeskRoute.setup);
    await end(tester);
  });

  testWidgets('Unlock offers Add a wallet', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.unlock);
    await wait(tester, 500);
    expect(find.text(_l.deskOnbWelcomeAdd), findsOneWidget);
    await end(tester);
  });

  testWidgets('Settings › Advanced lists every switch, none behind ⇕', (tester) async {
    container = make();
    await pumpApp(tester, DeskRoute.settingsAdvanced, height: 900);
    for (final f in ['outputs', 'technicalDetails', 'sendOptions', 'serverDetails', 'recheckFromHeight', 'builtInNode', 'logs']) {
      expect(find.byKey(ValueKey('adv-$f')), findsOneWidget, reason: f);
    }
    expect(find.byType(EMoreOptions), findsNothing);
    await end(tester);
  });
}
