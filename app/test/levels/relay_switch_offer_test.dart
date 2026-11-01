// SPDX-License-Identifier: Apache-2.0
// The relay offer as RelaySwitchNotifier runs it, on a fake clock: a relay that keeps dropping
// (connected a minute, lost, reconnected at once) is offered away from, though its status never
// reads offline for long; and over Tor the status site gets its Tor time to say which relay is
// healthy (the owner 2026-11-01: epicbox.epiccash.com over Tor kept dropping, no offer came).

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/levels/level_features.dart';
import 'package:epic_wallet/src/levels/level_providers.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' show RelayStatus, relayStatusProvider;
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _inUse = EpicboxRelay(host: 'relay-a.test');
const _healthy = EpicboxRelay(host: 'box.stack.invalid');

class _Session extends SessionNotifier {
  @override
  WalletSession? build() => FakeWalletSession();
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => const WalletConfig(
    dataDir: 'unused',
    chain: Chain.mainnet,
    nodeUrl: 'https://node.test',
    epicboxDomain: 'relay-a.test',
    epicboxPort: 443,
  );
}

class _Choice extends NetworkChoiceNotifier {
  @override
  Future<NetworkChoice> build() async =>
      const NetworkChoice(preset: mainnetPreset, nodeUrl: 'https://node.test', relay: _inUse);
}

/// The settled status, in the test's hands.
class _Status extends WalletStatusNotifier {
  @override
  WalletStatus build() => (node: const NodeStatus(NodeState.online), epicbox: EpicboxState.online);

  void set(EpicboxState epicbox) => state = (node: state.node, epicbox: epicbox);
}

class _Listener extends ListenerNotifier {
  @override
  ListenerState build() => const ListenerState(connected: true);

  void set(ListenerState s) => state = s;
}

class _Harness {
  _Harness(this.async, {Duration siteAnswersAfter = Duration.zero}) {
    final start = DateTime.utc(2026, 11, 1);
    container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(_Session.new),
        walletConfigProvider.overrideWith(_Config.new),
        networkChoiceProvider.overrideWith(_Choice.new),
        walletStatusProvider.overrideWith(_Status.new),
        listenerProvider.overrideWith(_Listener.new),
        clockProvider.overrideWithValue(() => start.add(async.elapsed)),
        networkModeProvider.overrideWithValue(NetworkMode.standard),
        levelFeaturesProvider.overrideWithValue(
          LevelFeatures.of(WalletLevel.justSendReceive, AdvancedPrefs.none, torBuilt: true),
        ),
        relayStatusProvider.overrideWith((ref, _) async {
          siteAsks++;
          await Future<void>.delayed(siteAnswersAfter);
          return const [RelayStatus(relay: _healthy, healthy: true, verified: true)];
        }),
      ],
    );
    container.listen(relaySwitchProvider, (_, _) {}, fireImmediately: true);
    elapse(Duration.zero);
  }

  final FakeAsync async;
  late final ProviderContainer container;
  int siteAsks = 0;

  RelaySwitchOffer? get offer => container.read(relaySwitchProvider);

  void elapse(Duration d) {
    async.elapse(d);
    async.flushMicrotasks();
  }

  /// The connection was lost: LEPIC retries at once, so the status reads connecting.
  void drop() {
    (container.read(listenerProvider.notifier) as _Listener).set(const ListenerState(lost: true));
    (container.read(walletStatusProvider.notifier) as _Status).set(EpicboxState.connecting);
    elapse(Duration.zero);
  }

  void subscribed() {
    (container.read(listenerProvider.notifier) as _Listener).set(const ListenerState(connected: true));
    (container.read(walletStatusProvider.notifier) as _Status).set(EpicboxState.online);
    elapse(Duration.zero);
  }
}

void main() {
  tearDown(() => TorSwitch.on = false);

  test('a relay that drops every minute and reconnects at once is offered away from', () {
    fakeAsync((async) {
      final h = _Harness(async);
      // Three minutes of: lost, back 3 s later, up 57 s. The status never reads offline.
      for (var i = 0; i < 3; i++) {
        h.drop();
        h.elapse(const Duration(seconds: 3));
        h.subscribed();
        h.elapse(const Duration(seconds: 57));
      }
      h.drop();
      h.elapse(const Duration(seconds: 1));
      expect(h.offer?.to, _healthy);
      // It stays while the relay keeps flapping.
      h.subscribed();
      h.elapse(const Duration(seconds: 57));
      expect(h.offer, isNotNull);
      // Up for two minutes in one go: the outage is over.
      h.elapse(relayStableFor);
      expect(h.offer, isNull);
      h.container.dispose();
    });
  });

  test('one short drop that mends offers nothing', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.drop();
      h.elapse(const Duration(seconds: 3));
      h.subscribed();
      h.elapse(const Duration(minutes: 10));
      expect(h.offer, isNull);
      expect(h.siteAsks, 0);
      h.container.dispose();
    });
  });

  test('over Tor the status site has its Tor time to name a healthy relay', () {
    fakeAsync((async) {
      TorSwitch.on = true;
      // A cold onion: the site answers after 20 s.
      final h = _Harness(async, siteAnswersAfter: const Duration(seconds: 20));
      h.drop();
      (h.container.read(walletStatusProvider.notifier) as _Status).set(EpicboxState.offline);
      h.elapse(relaySwitchAfter + const Duration(seconds: 25));
      expect(h.offer?.to, _healthy);
      h.container.dispose();
    });
  });
}
