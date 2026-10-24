import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/wallet_service.dart';
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

/// The phone's providers over a fake wallet, with the network mode set through the real
/// settings (AppSettingsNotifier.setNetworkMode), as the Advanced page sets it.
class _Phone {
  _Phone() {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        walletConfigProvider.overrideWith(_Config.new),
        torBundleFinderProvider.overrideWithValue(() async => _bundle),
        networkChangesProvider.overrideWithValue(const Stream<bool>.empty()),
      ],
    );
    container.listen(phoneTorProvider, (_, _) {}, fireImmediately: true);
  }

  final store = MemorySecretStore();
  final session = FakeWalletSession();
  late final ProviderContainer container;

  String get torKey => PhoneTor.receivingKey(_config);
  PhoneTorState get tor => container.read(phoneTorProvider);

  Future<void> mode(NetworkMode m) async {
    await container.read(appSettingsProvider.future);
    await container.read(appSettingsProvider.notifier).setNetworkMode(m);
    await settle();
  }

  /// Unlocks with the listener and home watched, as the shell does.
  Future<void> unlock() async {
    await container.read(appSettingsProvider.future);
    container.read(sessionProvider.notifier).unlocked(session);
    container.listen(listenerProvider, (_, _) {}, fireImmediately: true);
    container.listen(homeProvider, (_, _) {}, fireImmediately: true);
    await until(() => tor.settled);
    await settle();
  }

  Future<void> until(bool Function() ok) async {
    final end = DateTime.now().add(const Duration(seconds: 3));
    while (!ok()) {
      if (DateTime.now().isAfter(end)) fail('never reached; tor $tor');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    NetGate.set(NetworkMode.standard);
    TorNet.useDirect();
  });

  group('netBlockFor', () {
    test('Standard never blocks, whatever Tor does', () {
      for (final t in TorState.values) {
        expect(netBlockFor(NetworkMode.standard, t), NetBlock.none, reason: t.name);
      }
    });

    test('Tor only waits for Tor until it is on', () {
      for (final t in TorState.values) {
        expect(
          netBlockFor(NetworkMode.torOnly, t),
          t == TorState.on ? NetBlock.none : NetBlock.waitingForTor,
          reason: t.name,
        );
      }
    });

    test('Offline blocks always; the file method too (LEPIC asks the node)', () {
      for (final t in TorState.values) {
        expect(netBlockFor(NetworkMode.offline, t), NetBlock.offline);
      }
      expect(fileBlockFor(NetworkMode.offline), NetBlock.offline);
      expect(fileBlockFor(NetworkMode.torOnly), NetBlock.none);
    });

    test('the Tor switch: locked in Tor only, disabled in Offline', () {
      expect(torSwitchLocked(NetworkMode.torOnly), isTrue);
      expect(torSwitchLocked(NetworkMode.standard), isFalse);
      expect(torSwitchDisabled(NetworkMode.offline), isTrue);
      expect(pushAllowed(NetworkMode.standard), isTrue);
      expect(pushAllowed(NetworkMode.torOnly), isFalse);
      expect(pushAllowed(NetworkMode.offline), isFalse);
    });
  });

  group('torWayIn', () {
    test('Tor only: nothing ever on the clearnet; Link http(s) refused', () {
      for (final route in TorRoute.values) {
        for (final t in TorState.values) {
          expect(torWayIn(route, t, NetworkMode.torOnly), isNot(TorWay.clearnet), reason: '${route.name} ${t.name}');
        }
      }
      for (final t in TorState.values) {
        expect(torWayIn(TorRoute.httpDirect, t, NetworkMode.torOnly), TorWay.off);
        expect(torWayIn(TorRoute.push, t, NetworkMode.torOnly), TorWay.off);
        expect(torWayIn(TorRoute.httpListener, t, NetworkMode.torOnly), TorWay.off);
      }
      // A switch not on yet (being forced on): covered routes wait, never go direct.
      expect(torWayIn(TorRoute.epicbox, TorState.off, NetworkMode.torOnly), TorWay.wait);
      expect(torWayIn(TorRoute.onionDirect, TorState.off, NetworkMode.torOnly), TorWay.wait);
      expect(torWayIn(TorRoute.node, TorState.failed, NetworkMode.torOnly), TorWay.blocked);
      expect(torWayIn(TorRoute.appHttp, TorState.on, NetworkMode.torOnly), TorWay.overTor);
    });

    test('Offline: nothing goes; Standard is torWay', () {
      for (final route in TorRoute.values) {
        for (final t in TorState.values) {
          expect(torWayIn(route, t, NetworkMode.offline), TorWay.off);
          expect(torWayIn(route, t, NetworkMode.standard), torWay(route, t));
        }
      }
    });
  });

  group('TorNet and the mode', () {
    test('Offline refuses the app\'s own requests before opening anything; loopback stays', () {
      NetGate.set(NetworkMode.offline);
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      expect(() => TorNet.configure(client), throwsA(isA<NetError>().having((e) => e.message, 'message', offlineError)));
      TorNet.configure(client, loopback: true);
    });

    test('Offline: httpGet fails without a connection', () async {
      NetGate.set(NetworkMode.offline);
      // Nothing listens on this port: a request that went out would fail differently.
      await expectLater(httpGet(Uri.parse('https://example.invalid/x')), throwsA(isA<NetError>().having((e) => e.message, 'message', offlineError)));
    });

    test('Tor only: never direct, even before the forced switch is followed', () {
      TorNet.useDirect();
      NetGate.set(NetworkMode.torOnly);
      expect(TorNet.mode, TorNetMode.waiting);
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      expect(() => TorNet.configure(client), throwsA(isA<NetError>()));
      TorNet.follow(TorState.off);
      expect(TorNet.mode, TorNetMode.waiting);
      NetGate.set(NetworkMode.standard);
      TorNet.follow(TorState.off);
      expect(TorNet.mode, TorNetMode.direct);
    });

    test('NetGate: no stored mode is Standard; Offline refuses', () {
      NetGate.set(null);
      expect(NetGate.mode, NetworkMode.standard);
      expect(() => NetGate.check('x'), returnsNormally);
      NetGate.set(NetworkMode.offline);
      expect(() => NetGate.check('x'), throwsA(isA<NetBlocked>()));
    });
  });

  group('phone, Offline', () {
    late _Phone p;
    setUp(() => p = _Phone());
    tearDown(() => p.dispose());

    test('opens on local data: no listener, no node, no tor, no refresh', () async {
      p.store.values[p.torKey] = 'true';
      await p.mode(NetworkMode.offline);
      expect(NetGate.offline, isTrue);
      await p.unlock();
      expect(p.session.listenerStarts, 0);
      expect(p.session.torStarts, isEmpty);
      expect(p.session.refreshCalls, 0);
      expect(p.container.read(listenerProvider).offline, isTrue);
      final home = await p.container.read(homeProvider.future);
      expect(home.syncing, isFalse);
      await expectLater(p.container.read(nodeTipProvider.future), throwsA(isA<NetBlocked>()));
      expect(p.session.nodeTipsFor, isEmpty);
      expect(await p.container.read(scanProvider.notifier).run(), isFalse);
      expect(p.session.scanCalls, 0);
      await expectLater(p.container.read(phoneTorProvider.notifier).ensureForSend(), throwsA(isA<NetBlocked>()));
      expect(p.session.torStarts, isEmpty);
    });

    test('back to Standard resumes without a restart', () async {
      p.store.values[p.torKey] = 'true';
      await p.mode(NetworkMode.offline);
      await p.unlock();
      expect(p.session.listenerStarts, 0);
      await p.mode(NetworkMode.standard);
      await p.until(() => p.session.listenerStarts == 1 && p.session.torStarts.length == 1);
      await p.until(() => p.session.refreshCalls > 0);
      expect(p.container.read(listenerProvider).offline, isFalse);
    });

    test('going Offline while open stops tor and the listener', () async {
      p.store.values[p.torKey] = 'true';
      await p.unlock();
      expect(p.session.listenerStarts, 1);
      expect(p.session.torStarts, hasLength(1));
      await p.mode(NetworkMode.offline);
      expect(p.session.torStops, greaterThan(0));
      expect(p.session.listenerStops, greaterThan(0));
      expect(p.tor.phase, PhoneTorPhase.off);
      // The switch itself is kept for when the mode changes.
      expect(p.store.values[p.torKey], 'true');
    });
  });

  group('phone, Tor only', () {
    late _Phone p;
    setUp(() => p = _Phone());
    tearDown(() => p.dispose());

    test('opening a wallet turns its Tor switch on, and off is refused', () async {
      await p.mode(NetworkMode.torOnly);
      await p.unlock();
      expect(p.tor.receiving, isTrue);
      expect(p.store.values[p.torKey], 'true');
      expect(p.session.torStarts, hasLength(1));
      await p.container.read(phoneTorProvider.notifier).setReceiving(false);
      expect(p.tor.receiving, isTrue);
      expect(p.store.values[p.torKey], 'true');
      await p.container.read(epicboxOverTorProvider.notifier).set(false);
      expect(p.container.read(epicboxOverTorProvider), isTrue);
    });

    test('choosing Tor only while open turns the switch on; Standard leaves it on', () async {
      await p.unlock();
      expect(p.tor.receiving, isFalse);
      await p.mode(NetworkMode.torOnly);
      await p.until(() => p.tor.receiving);
      expect(p.session.torStarts, hasLength(1));
      await p.mode(NetworkMode.standard);
      expect(p.tor.receiving, isTrue);
      await p.container.read(phoneTorProvider.notifier).setReceiving(false);
      expect(p.tor.receiving, isFalse);
    });
  });
}
