// SPDX-License-Identifier: Apache-2.0
// Epicbox over Tor on the phone, the mechanism the app's Tor setting drives: on by default and
// applied to the open wallet at once; a wallet that opens with Tor receiving on announces tor
// before its first Epicbox connection and gets the onion routes; Retry keeps the connection
// waiting for the new tor; turning Tor off after it ended lets the connection go direct; and
// the waiting state is exposed for the "Connecting via Tor" status.

import 'dart:async';

import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

final _config = mainnetPreset.config(
  dataDir: '/fake/wallets/mainnet',
  nodeUrl: 'https://node',
);

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => _config;
}

class _Harness {
  _Harness({TorBundle? bundle = _bundle}) {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        walletConfigProvider.overrideWith(_Config.new),
        torBundleFinderProvider.overrideWithValue(() async => bundle),
        networkChangesProvider.overrideWithValue(network.stream),
      ],
    );
  }

  final store = MemorySecretStore();
  final session = FakeWalletSession();
  final network = StreamController<bool>.broadcast();
  late final ProviderContainer container;

  Future<void> receivingOn() => store.write(PhoneTor.receivingKey(_config), 'true');

  /// Opens the wallet as the unlock screens do, then lets the listener and tor start.
  Future<void> open() async {
    await container.read(sessionProvider.notifier).open(session);
    container.listen(listenerProvider, (_, _) {}, fireImmediately: true);
    container.listen(phoneTorProvider, (_, _) {}, fireImmediately: true);
    container.listen(epicboxWaitingForTorProvider, (_, _) {}, fireImmediately: true);
    final end = DateTime.now().add(const Duration(seconds: 3));
    while (container.read(phoneTorProvider).onion == null &&
        container.read(phoneTorProvider).phase != PhoneTorPhase.unavailable) {
      if (DateTime.now().isAfter(end)) fail('tor controller never read its state');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await pumpEventQueue();
  }

  void dispose() {
    container.dispose();
    unawaited(network.close());
  }
}

void main() {
  // Tor's own behaviour: nothing of it is in the build without Tor.
  if (!torBuilt) {
    test('Tor', () {}, skip: 'no Tor in this build');
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on by default; a change reaches the open wallet at once and the next one', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    expect(h.container.read(epicboxOverTorProvider), isTrue);
    await h.open();
    expect(h.session.epicboxOverTorValue, isTrue, reason: 'given before the wallet opens');

    await h.container.read(epicboxOverTorProvider.notifier).set(false);
    expect(h.session.epicboxOverTorValue, isFalse);

    final next = FakeWalletSession();
    await h.container.read(sessionProvider.notifier).open(next);
    expect(next.epicboxOverTorValue, isFalse);
  });

  test('the TLS onion routes of the directory reach the wallet when it opens', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.open();
    final routes = h.session.onionRoutes!;
    expect(routes, onionRoutesOf(OnionDirectory()));
    expect(routes.map((r) => r.host), contains('box.lab.invalid'));
    expect(routes.map((r) => r.host), isNot(contains('status.lab.invalid')), reason: 'plain HTTP');
    expect(
      routes.firstWhere((r) => r.host == 'box.lab.invalid').onion,
      hostSettings.torOnions.firstWhere((r) => r.host == 'box.lab.invalid').onion,
    );
  });

  test('with Tor receiving on, tor is announced before the first Epicbox connection', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.receivingOn();
    await h.open();
    final log = h.session.routeLog;
    expect(log.first, 'epicboxOverTor:true');
    expect(log, containsAllInOrder(['expectTor', 'listener', 'startTor']));
    expect(log.indexOf('expectTor'), lessThan(log.indexOf('listener')), reason: 'no direct connection first');
  });

  test('with Epicbox over Tor off, Tor receiving off or no tor, nothing waits for tor', () async {
    final off = _Harness();
    addTearDown(off.dispose);
    off.container.read(epicboxOverTorProvider.notifier).state = false;
    await off.receivingOn();
    await off.open();
    expect(off.session.routeLog, isNot(contains('expectTor')));
    expect(off.session.routeLog.first, 'epicboxOverTor:false');

    final noTor = _Harness();
    addTearDown(noTor.dispose);
    await noTor.open();
    expect(noTor.session.routeLog, isNot(contains('expectTor')));
    expect(noTor.session.routeLog, contains('listener'));

    final noBundle = _Harness(bundle: null);
    addTearDown(noBundle.dispose);
    await noBundle.receivingOn();
    await noBundle.open();
    expect(noBundle.session.routeLog, isNot(contains('expectTor')), reason: 'no tor to wait for');
  });

  test('Retry announces the new tor before stopping the old one', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.receivingOn();
    await h.open();
    h.session.routeLog.clear();
    await h.container.read(phoneTorProvider.notifier).retry();
    expect(h.session.routeLog, ['expectTor', 'stopTor', 'startTor']);
  });

  test('Tor receiving off after tor ended by itself lets the connection go direct', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.receivingOn();
    await h.open();
    h.session.torEvents.add(const TorEvent(kind: TorEventKind.failed, failure: TorFailure.missing));
    h.session.torEvents.add(const TorEvent(kind: TorEventKind.stopped));
    await pumpEventQueue();
    expect(h.container.read(phoneTorProvider).phase, PhoneTorPhase.failed);
    h.session.routeLog.clear();
    await h.container.read(phoneTorProvider.notifier).setReceiving(false);
    expect(h.session.routeLog, ['stopTor']);
  });

  test('waiting for tor while not connected through it; not once connected or off', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.receivingOn();
    await h.open();
    expect(h.container.read(epicboxWaitingForTorProvider), isTrue, reason: 'tor starting, listener not connected');

    h.session.listenerEvents.add(const ListenerEvent(kind: ListenerEventKind.connected, message: ''));
    await pumpEventQueue();
    expect(h.container.read(epicboxWaitingForTorProvider), isFalse);

    h.session.listenerEvents.add(const ListenerEvent(kind: ListenerEventKind.disconnected, message: 'lost'));
    await pumpEventQueue();
    expect(h.container.read(epicboxWaitingForTorProvider), isTrue, reason: 'waits for tor, not offline');

    await h.container.read(epicboxOverTorProvider.notifier).set(false);
    expect(h.container.read(epicboxWaitingForTorProvider), isFalse);

    final noTor = _Harness();
    addTearDown(noTor.dispose);
    await noTor.open();
    expect(noTor.container.read(epicboxWaitingForTorProvider), isFalse, reason: 'tor off: direct');
  });
}
