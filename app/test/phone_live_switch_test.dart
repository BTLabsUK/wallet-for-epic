// Settings › Network on the phone switches the node or the epicbox relay of the open wallet
// live: no LaunchScreen, no PIN, the session stays open and the listener keeps running and
// receives on the new relay. Another network still restarts the app flow.
import 'dart:io';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/launch_screen.dart';
import 'package:epic_wallet/src/ui/setup_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _dir = '/fake/wallets/mainnet';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

typedef _World = ({
  ProviderContainer container,
  FakeWalletService service,
  FakeWalletSession session,
});

/// An unlocked mainnet wallet on the default servers, its listener running, and Settings ›
/// Network open over a home page.
Future<_World> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final service = FakeWalletService(existingWallets: {_dir});
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      walletServiceProvider.overrideWithValue(service),
      secretStoreProvider.overrideWithValue(MemorySecretStore()),
      relayDirectoryProvider.overrideWithValue(_NoRelays()),
    ],
  );
  addTearDown(container.dispose);
  final config = mainnetPreset.config(
    dataDir: _dir,
    nodeUrl: mainnetPreset.nodeUrl,
  );
  container.read(walletConfigProvider.notifier).select(config);
  final session = service.session..openedConfig = config;
  container.read(sessionProvider.notifier).unlocked(session);
  container.listen(listenerProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SetupScreen()),
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
  expect(find.byType(SetupScreen), findsOneWidget);
  return (container: container, service: service, session: session);
}

Future<void> _useRelay(WidgetTester tester, String relay) async {
  final field = find.widgetWithText(TextField, _l.setupCustomRelayLabel);
  await tester.scrollUntilVisible(
    field,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(field, relay);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, {bool settle = true}) async {
  await tester.ensureVisible(find.text(_l.commonSave));
  await tester.tap(find.text(_l.commonSave));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // The launch screen's spinner never settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// The open wallet, on the same session, not locked and not handed to the PIN screen.
void _stillOpen(_World w) {
  expect(find.byType(LaunchScreen), findsNothing);
  expect(find.byType(SetupScreen), findsNothing);
  expect(find.text('home'), findsOneWidget);
  expect(w.container.read(sessionProvider), same(w.session));
  expect(w.session.disposeCalls, 0);
}

void main() {
  testWidgets('a new relay is confirmed with the new address, switched live, and the listener '
      'receives on it', (tester) async {
    final w = await _open(tester);
    expect(w.session.listenerStarts, 1);

    await _useRelay(tester, 'relay.example.org');
    await _save(tester);
    expect(find.text(_l.serverSwitchRelayTitle), findsOneWidget);
    expect(find.textContaining('…@relay.example.org'), findsOneWidget);
    await tester.tap(find.text(_l.serverSwitchRelayConfirm));
    await tester.pumpAndSettle();

    _stillOpen(w);
    final switched = w.session.serverSwitches.single;
    expect(switched.epicboxDomain, 'relay.example.org');
    expect(switched.dataDir, _dir);
    expect(switched.nodeUrl, mainnetPreset.nodeUrl);
    expect(w.container.read(walletConfigProvider), switched);
    expect(
      await w.container.read(addressProvider.future),
      endsWith('@relay.example.org'),
    );
    final saved = await w.container.read(networkChoiceProvider.future);
    expect(saved.relay.host, 'relay.example.org');
    // The listener moved with the session: it was not restarted and still reports payments.
    expect(w.session.listenerStarts, 1);
    expect(w.session.listenerStops, 0);
    w.session.listenerEvents.add(
      const ListenerEvent(kind: ListenerEventKind.received, txId: 7, message: ''),
    );
    await tester.pumpAndSettle();
    expect(w.container.read(listenerProvider).last?.txId, 7);
  });

  testWidgets('cancelling the relay confirm switches nothing', (tester) async {
    final w = await _open(tester);
    await _useRelay(tester, 'relay.example.org');
    await _save(tester);
    await tester.tap(find.text(_l.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(w.session.serverSwitches, isEmpty);
    expect(
      (await w.container.read(networkChoiceProvider.future)).relay,
      mainnetPreset.defaultRelay,
    );
  });

  testWidgets('a new node switches live without a confirm', (tester) async {
    final w = await _open(tester);
    await tester.enterText(
      find.widgetWithText(TextField, _l.setupNodeUrlLabel),
      'https://node.example.org',
    );
    await _save(tester);

    expect(find.text(_l.serverSwitchRelayTitle), findsNothing);
    _stillOpen(w);
    expect(w.session.serverSwitches.single.nodeUrl, 'https://node.example.org');
    expect(
      w.session.serverSwitches.single.epicboxDomain,
      mainnetPreset.defaultRelay.host,
    );
    expect(
      (await w.container.read(networkChoiceProvider.future)).nodeUrl,
      'https://node.example.org',
    );
  });

  testWidgets('a refused switch keeps the wallet, the screen and the saved servers', (tester) async {
    final w = await _open(tester);
    w.session.openedConfig = mainnetPreset.config(
      dataDir: '/elsewhere',
      nodeUrl: mainnetPreset.nodeUrl,
    );
    await tester.enterText(
      find.widgetWithText(TextField, _l.setupNodeUrlLabel),
      'https://node.example.org',
    );
    await _save(tester);

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(w.container.read(sessionProvider), same(w.session));
    expect(
      (await w.container.read(networkChoiceProvider.future)).nodeUrl,
      mainnetPreset.nodeUrl,
    );
  });

  testWidgets('another network still restarts the app flow', (tester) async {
    final w = await _open(tester);
    await tester.tap(find.text(_l.networkFloonet));
    await tester.pumpAndSettle();
    await _save(tester, settle: false);

    expect(w.session.serverSwitches, isEmpty);
    expect(w.container.read(sessionProvider), isNull);
  });

  test('the LEPIC adapter hands the new servers to the open wallet', () async {
    final wallet = _ServersWallet();
    final session = LepicWalletSession(wallet);
    await session.setServers(
      config: const WalletConfig(
        dataDir: '/data/mainnet',
        chain: Chain.mainnet,
        nodeUrl: 'https://node.example.org',
        nodeApiSecret: 'secret',
        epicboxDomain: 'relay.example.org',
        epicboxPort: 444,
      ),
    );
    final c = wallet.switched.single;
    expect(c.dataDir, '/data/mainnet${Platform.pathSeparator}lepic');
    expect(c.chain, lepic.Chain.mainnet);
    expect(c.nodeUrl, 'https://node.example.org');
    expect(c.nodeApiSecret, 'secret');
    expect(c.epicboxDomain, 'relay.example.org');
    expect(c.epicboxPort, 444);

    wallet.refusal = lepic.WalletError(
      kind: lepic.WalletErrorKind.invalidArgument,
      code: 0,
      message: 'not a relay',
    );
    await expectLater(
      session.setServers(
        config: const WalletConfig(
          dataDir: '/data/mainnet',
          chain: Chain.mainnet,
          nodeUrl: 'https://node.example.org',
          epicboxDomain: 'not a host',
          epicboxPort: 443,
        ),
      ),
      throwsA(
        isA<WalletError>().having(
          (e) => e.kind,
          'kind',
          WalletErrorKind.invalidArgument,
        ),
      ),
    );
  });
}

/// LEPIC's open wallet, keeping the configs it was switched to. Fails any other native call.
class _ServersWallet implements lepic.EpicWallet {
  final List<lepic.WalletConfig> switched = [];
  lepic.WalletError? refusal;

  @override
  Future<void> setServers({required lepic.WalletConfig config}) async {
    final error = refusal;
    if (error != null) throw error;
    switched.add(config);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');
}
