// The server pickers on the phone (Home's status icons, Settings › Privacy & network, the
// first-run and lock-screen button) switch the node or the epicbox relay of the open wallet
// live: no LaunchScreen, no PIN, the session stays open and the listener keeps running and
// receives on the new relay. Another network (development builds) still restarts the app flow.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/ui/first_run_screen.dart' show NetworkSettingsButton;
import 'package:epic_wallet/src/ui/launch_screen.dart';
import 'package:epic_wallet/src/ui/network_menu.dart';
import 'package:epic_wallet/src/ui/pin_unlock_screen.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/ui/server_picker.dart';
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

/// An unlocked mainnet wallet on the default servers, its listener running, and a picker sheet
/// of [open] over a home page.
Future<_World> _open(
  WidgetTester tester, {
  Future<void> Function(BuildContext context) open = showEpicboxPicker,
}) async {
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
      relayProbeProvider.overrideWithValue(FakeRelayProbe()),
      // The network chooser is for development builds; one test switches networks.
      devNetworksProvider.overrideWithValue(true),
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
              onPressed: () => open(context),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
  return (container: container, service: service, session: session);
}

/// Types [text] into the field at the top and taps the Add row: the server is tested, added
/// and offered for a switch at the foot.
Future<void> _offer(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(serverListFieldKey), text);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(serverListAddKey));
  await tester.pumpAndSettle();
}

/// The foot line's Switch, which a Node switches with and an Epicbox server asks first with.
Future<void> _footSwitch(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byKey(serverListFootKey), matching: find.text(_l.slSwitch)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Switches to the server just added, confirming the Epicbox dialog when it opens.
Future<void> _switch(WidgetTester tester, {bool settle = true}) async {
  await _footSwitch(tester);
  if (find.byKey(serverListSwitchKey).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(serverListSwitchKey));
  }
  if (settle) {
    await tester.pumpAndSettle();
    // The success notice's timer runs on after the switch.
    await tester.pump(const Duration(seconds: 10));
  } else {
    // The launch screen's spinner never settles.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// The app flow started again: the launch screen, or the lock screen it routes to.
void _relaunched() {
  expect(find.byType(ServerListSheet), findsNothing);
  expect(
    find.byType(LaunchScreen).evaluate().isNotEmpty ||
        find.byType(PinUnlockScreen).evaluate().isNotEmpty,
    isTrue,
  );
}

/// The open wallet, on the same session, not locked and not handed to the PIN screen.
void _stillOpen(_World w) {
  expect(find.byType(LaunchScreen), findsNothing);
  expect(find.text('home'), findsOneWidget);
  expect(w.container.read(sessionProvider), same(w.session));
  expect(w.session.disposeCalls, 0);
}

void main() {
  testWidgets('a live relay switch leaves Epicbox over Tor as it was: the same session keeps '
      'the choice, the onion routes and tor', (tester) async {
    final w = await _open(tester);
    await w.session.setEpicboxOverTor(true);
    await w.session.setOnionRoutes(const [
      (host: 'flooepicbox.btlabs.uk', port: 443, onion: 'x.onion', onionPort: 443),
    ]);
    w.session.routeLog.clear();

    await _offer(tester, 'relay.example.org');
    await _switch(tester);

    _stillOpen(w);
    expect(w.session.serverSwitches.single.epicboxDomain, 'relay.example.org');
    // LEPIC's switch keeps the session's tor routing; the app must not undo or redo it.
    expect(w.session.routeLog, isEmpty, reason: 'no setting change, tor stop or listener restart');
    expect(w.session.epicboxOverTorValue, isTrue);
    expect(w.session.onionRoutes, hasLength(1));
  });

  testWidgets('a new relay is switched live after the dialog says the address changes, and the '
      'listener receives on it', (tester) async {
    final w = await _open(tester);
    expect(w.session.listenerStarts, 1);

    await _offer(tester, 'relay.example.org');
    // The dialog's Switch, with its line, is the confirmation.
    await _footSwitch(tester);
    // The sheet says the same under its list; the dialog's body is what asks.
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text(_l.slSwitchBody)), findsOneWidget);
    expect(find.byKey(serverListSwitchKey), findsOneWidget);
    await tester.tap(find.byKey(serverListSwitchKey));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

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

  testWidgets('after a live relay switch the shown address carries the new relay, even while '
      'a page showing it stays open', (tester) async {
    final w = await _open(tester);
    // Receive watches it; held here as an open page holds it.
    final receive = w.container.listen(addressProvider, (_, _) {});
    expect(await w.container.read(addressProvider.future), endsWith('@epicbox.epiccash.com'));

    await _offer(tester, 'relay.example.org');
    await _switch(tester);

    _stillOpen(w);
    expect(await w.container.read(addressProvider.future), endsWith('@relay.example.org'));
    receive.close();
  });

  testWidgets('a relay switch that finishes after its sheet was closed still moves the wallet '
      'onto the new relay: the config, the shown address and push follow it', (tester) async {
    final w = await _open(tester);
    final gate = w.session.serverSwitchGate = Completer<void>();
    await _offer(tester, 'relay.example.org');
    await _switch(tester, settle: false);
    // Back out of the sheet while the switch waits for a payment in hand.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ServerListSheet), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();

    _stillOpen(w);
    expect(w.session.serverSwitches.single.epicboxDomain, 'relay.example.org');
    expect(w.container.read(walletConfigProvider)?.epicboxDomain, 'relay.example.org');
    expect(await w.container.read(addressProvider.future), endsWith('@relay.example.org'));
  });

  group('first run and the lock screen: the button\'s menu opens the same sheets', () {
    /// A locked wallet on the default servers, with the lock screen's button pressed and
    /// [entry] ([networkMenuNodeKey] or [networkMenuEpicboxKey]) chosen from its menu.
    Future<ProviderContainer> openFromLockScreen(
      WidgetTester tester,
      Key entry,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(
            FakeWalletService(existingWallets: {_dir}),
          ),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PinUnlockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider), isNull);
      await tester.tap(find.byType(NetworkSettingsButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(entry));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsOneWidget);
      return container;
    }

    testWidgets('a new relay asks first (the dialog), and Cancel saves nothing', (tester) async {
      final container = await openFromLockScreen(tester, networkMenuEpicboxKey);
      await _offer(tester, 'relay.example.org');
      await _footSwitch(tester);
      // The sheet says the same under its list; the dialog's body is what asks.
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text(_l.slSwitchBody)), findsOneWidget);
      await tester.tap(find.byKey(serverListCancelKey));
      await tester.pumpAndSettle();

      expect(find.byKey(serverListSwitchKey), findsNothing);
      expect(find.byType(ServerListSheet), findsOneWidget);
      expect(
        (await container.read(networkChoiceProvider.future)).relay,
        mainnetPreset.defaultRelay,
      );
    });

    testWidgets('Switch saves the relay and starts the app again on it', (tester) async {
      final container = await openFromLockScreen(tester, networkMenuEpicboxKey);
      await _offer(tester, 'relay.example.org');
      await _switch(tester, settle: false);

      expect(find.byType(ServerListSheet), findsNothing);
      expect(
        (await container.read(networkChoiceProvider.future)).relay.host,
        'relay.example.org',
      );
      // The launch flow lands on the lock screen again (a wallet exists).
      _relaunched();
    });

    testWidgets('a new node needs no confirm', (tester) async {
      final container = await openFromLockScreen(tester, networkMenuNodeKey);
      await _offer(tester, 'https://node.example.org');
      await _switch(tester, settle: false);
      expect(find.byType(AlertDialog), findsNothing);

      expect(
        (await container.read(networkChoiceProvider.future)).nodeUrl,
        'https://node.example.org',
      );
      _relaunched();
      // The node's tip check and the foot line end their timers.
      await tester.pump(const Duration(seconds: 10));
    });
  });

  testWidgets('cancelling the dialog switches nothing', (tester) async {
    final w = await _open(tester);
    await _offer(tester, 'relay.example.org');
    await _footSwitch(tester);
    await tester.tap(find.byKey(serverListCancelKey));
    await tester.pumpAndSettle();

    expect(find.byType(ServerListSheet), findsOneWidget);
    expect(find.byKey(serverListSwitchKey), findsNothing);
    expect(w.session.serverSwitches, isEmpty);
    expect(
      (await w.container.read(networkChoiceProvider.future)).relay,
      mainnetPreset.defaultRelay,
    );
  });

  testWidgets('a new node switches live without a dialog', (tester) async {
    final w = await _open(tester, open: showNodePicker);
    await _offer(tester, 'https://node.example.org');
    await _switch(tester);
    expect(find.byType(AlertDialog), findsNothing);

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

  testWidgets('a refused switch keeps the wallet, the sheet and the saved servers', (tester) async {
    final w = await _open(tester, open: showNodePicker);
    w.session.openedConfig = mainnetPreset.config(
      dataDir: '/elsewhere',
      nodeUrl: mainnetPreset.nodeUrl,
    );
    await _offer(tester, 'https://node.example.org');
    await _switch(tester);

    expect(find.byType(ServerListSheet), findsOneWidget);
    expect(w.container.read(sessionProvider), same(w.session));
    expect(
      (await w.container.read(networkChoiceProvider.future)).nodeUrl,
      mainnetPreset.nodeUrl,
    );
  });

  testWidgets('another network (development builds) still restarts the app flow', (tester) async {
    final w = await _open(tester, open: showNetworkChooser);
    await tester.tap(find.text(_l.networkFloonet));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(w.session.serverSwitches, isEmpty);
    expect(w.container.read(sessionProvider), isNull);
    expect(
      (await w.container.read(networkChoiceProvider.future)).preset,
      floonetPreset,
    );
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
