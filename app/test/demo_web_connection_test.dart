// W-06: the web demo's connection states in the UI: the warning while the socket is down,
// the success notice once it is back, the unlock screen when the server dropped the open
// wallet, and no retrying once the demo is over.

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/demo_web_connection.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/remote/channel.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/remote/dispatcher.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _pin = '123456';
const String _dir = '/demo/floonet';

final AppLocalizations l = englishStrings;

/// The demo server: sessions outlive its sockets, as they outlive a reload there.
class _Server {
  final FakeWalletService service = FakeWalletService(existingWallets: {_dir});
  final WalletSessions sessions = WalletSessions();
  RpcChannel? live;
  WalletDispatcher? dispatcher;
  bool down = false;
  int connects = 0;

  Future<RpcChannel> connect() async {
    if (down) throw StateError('down');
    connects++;
    final (client, server) = loopbackPair();
    dispatcher = WalletDispatcher(service, server, sessions: sessions);
    live = server;
    return client;
  }

  Future<void> drop() async {
    await live?.close();
    live = null;
  }
}

/// A root that calls [listenForDemoConnection], as the app root does in demo mode.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    listenForDemoConnection(ref, _navigator);
    return MaterialApp(
      navigatorKey: _navigator,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('home')),
    );
  }
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  final server = _Server();
  late final RemoteWalletService client = RemoteWalletService.reconnecting(
    server.connect,
    closingPushes: const {'demoEnded'},
  );
  final api = FakeDemoApi(
    status: DemoActive(DateTime.now().add(const Duration(hours: 5))),
  );
  final store = MemorySecretStore();
  late ProviderContainer container;

  /// The real app root in demo mode, unlocked on Home, over the remote service.
  Future<void> pumpApp(WidgetTester tester) async {
    store.values['wallet.floonet.pinSealed'] = fakeSealedPassword(_pin);
    store.values['wallet.floonet.backedUp'] = '1';
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          demoModeProvider.overrideWithValue(true),
          demoApiProvider.overrideWithValue(api),
          walletServiceProvider.overrideWithValue(client),
          walletDirProvider.overrideWithValue((chain) async => _dir),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner()),
          sharedFilesCleanupProvider.overrideWithValue(() async {}),
        ],
        child: const WalletApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await client.close();
    });
  }

  Future<void> pump(WidgetTester tester) async {
    store.values['wallet.floonet.pinSealed'] = fakeSealedPassword(_pin);
    store.values['wallet.floonet.backedUp'] = '1';
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          demoModeProvider.overrideWithValue(true),
          demoApiProvider.overrideWithValue(api),
          walletServiceProvider.overrideWithValue(client),
          walletDirProvider.overrideWithValue((chain) async => _dir),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
        ],
        child: const _Root(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.text('home')));
    // The demo status loads, so the listener sees it change later.
    await container.read(demoStatusProvider.future);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await client.close();
    });
  }

  Notice? get notice => container.read(noticeProvider);
}

void main() {
  testWidgets('a drop warns until the socket is back, then says so', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.runAsync(() => h.client.walletExists(config: _config));
    await tester.pump();
    expect(h.notice, isNull, reason: 'the first connection is no news');

    h.server.down = true;
    await tester.runAsync(h.server.drop);
    await tester.pump();
    expect(h.notice?.text, l.demoConnectionLost);
    expect(h.notice?.level, NoticeLevel.warning);
    expect(h.notice?.persistent, isTrue);

    // Still down after the first retry: the warning stays.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump();
    expect(h.notice?.text, l.demoConnectionLost);
    expect(h.client.connection, RemoteConnection.reconnecting);

    h.server.down = false;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    await tester.pump();
    expect(h.client.connection, RemoteConnection.connected);
    expect(h.notice?.text, l.demoConnectionBack);
    expect(h.notice?.level, NoticeLevel.success);
    // One notice in place of the other, not a queue.
    expect(h.container.read(noticeProvider.notifier).queued, isEmpty);
    h.container.read(noticeProvider.notifier).clear();
  });

  testWidgets('a session the server dropped sends the app to unlock', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    final session = (await tester.runAsync(
      () => h.client.openWithPin(
        config: _config,
        pin: _pin,
        sealedPassword: fakeSealedPassword(_pin),
      ),
    ))!;
    h.container.read(sessionProvider.notifier).unlocked(session);
    await tester.pump();

    // The socket dropped for longer than the server's idle window.
    await tester.runAsync(h.server.drop);
    h.server.sessions.disposeAll();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump();
    expect(h.client.connection, RemoteConnection.connected);

    await tester.runAsync(
      () => session.epicboxAddress().then((_) {}, onError: (Object _) {}),
    );
    // The unlock screen asks the server whether the wallet exists, over real async.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(h.container.read(sessionProvider), isNull);
    expect(find.text('home'), findsNothing);
    expect(find.widgetWithText(TextField, l.pinLabel), findsOneWidget);
    h.container.read(noticeProvider.notifier).clear();
  });

  testWidgets('another session lost is not the open one', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    final open = (await tester.runAsync(
      () => h.client.openWithPin(
        config: _config,
        pin: _pin,
        sealedPassword: fakeSealedPassword(_pin),
      ),
    ))!;
    final other = (await tester.runAsync(
      () => h.client.openWithPin(
        config: _config,
        pin: _pin,
        sealedPassword: fakeSealedPassword(_pin),
      ),
    ))!;
    h.container.read(sessionProvider.notifier).unlocked(open);
    await tester.pump();
    h.server.sessions.remove((other as RemoteWalletSession).handle);
    await tester.runAsync(
      () => other.epicboxAddress().then((_) {}, onError: (Object _) {}),
    );
    await tester.pumpAndSettle();
    expect(h.container.read(sessionProvider), same(open));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the end of the demo closes the socket without a warning', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.runAsync(() => h.client.walletExists(config: _config));
    h.server.dispatcher!.push('demoEnded');
    await tester.runAsync(h.server.drop);
    await tester.pump();
    expect(h.client.connection, RemoteConnection.idle);
    expect(h.notice, isNull);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    expect(h.server.connects, 1, reason: 'no retry after the end');
  });

  testWidgets('ending the demo disconnects and clears the warning', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.runAsync(() => h.client.walletExists(config: _config));
    h.server.down = true;
    await tester.runAsync(h.server.drop);
    await tester.pump();
    expect(h.notice?.text, l.demoConnectionLost);

    await tester.runAsync(
      () => h.container.read(demoStatusProvider.notifier).end(),
    );
    await tester.pump();
    expect(h.client.connection, RemoteConnection.idle);
    expect(h.notice, isNull);
  });

  testWidgets('the app root shows the connection warning in demo mode', (
    tester,
  ) async {
    final h = _Harness();
    await h.pumpApp(tester);
    // The launch screen asks the server about the wallet, which connects the socket; the
    // unlock screen then asks for the PIN failures. Both answer before the drop.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(h.client.connection, RemoteConnection.connected);
    expect(find.widgetWithText(TextField, l.pinLabel), findsOneWidget);
    expect(h.notice, isNull);
    h.server.down = true;
    await tester.runAsync(h.server.drop);
    await tester.pump();
    expect(h.notice?.text, l.demoConnectionLost);
    h.container.read(noticeProvider.notifier).clear();
    // No retry timer outlives the test.
    await h.client.close();
  });
}

const _config = WalletConfig(
  dataDir: _dir,
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.example',
  epicboxDomain: 'flooepicbox.example',
  epicboxPort: 443,
);
