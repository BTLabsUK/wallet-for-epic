// SPDX-License-Identifier: Apache-2.0
// Node failover (Settings › Advanced, on by default): the shared rules, the stored switch, and
// the phone's watcher on a fake clock. When the node in use has not answered for 30 s the
// wallet moves to the next working node of the list for this session; the chosen node and the
// list stay as saved.

import 'dart:async';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/node_failover.dart';
import 'package:epic_wallet/src/node_failover_phone.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' as dir;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/server_list_file.dart';
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

const _a = 'https://a.example';
const _b = 'https://b.example';
const _c = 'https://c.example';
const _d = 'https://d.example';
const _local = 'http://127.0.0.1:3413';
const _dir = '/fake/wallets/mainnet';

FailoverHealth _healthOf(Map<String, FailoverHealth> m, String url) => m[url] ?? FailoverHealth.unknown;

void main() {
  group('rules', () {
    test('candidates: healthy first in list order, then unknown; never down, current, chosen or local', () {
      final health = {_b: FailoverHealth.down, _c: FailoverHealth.unknown, _d: FailoverHealth.healthy};
      expect(
        failoverCandidates(
          entries: [_a, _b, _c, _d, _local, 'https://d.example:443'],
          current: _a,
          chosen: _a,
          health: (u) => _healthOf(health, u),
        ),
        [_d, _c],
      );
      // On a failover node, the chosen one is not gone back to and the current one is skipped.
      expect(
        failoverCandidates(entries: [_a, _c, _d], current: _c, chosen: _a, health: (_) => FailoverHealth.healthy),
        [_d],
      );
    });

    test('Tor only keeps only the nodes Tor reaches', () {
      final list = failoverCandidates(
        entries: [_a, _c, _d],
        current: _a,
        chosen: _a,
        mode: NetworkMode.torOnly,
        overTor: (u) => u == _d,
        health: (_) => FailoverHealth.healthy,
      );
      expect(list, [_d]);
      expect(
        failoverCandidates(entries: [_a, _c], current: _a, chosen: _a, mode: NetworkMode.torOnly, health: (_) => FailoverHealth.healthy),
        isEmpty,
      );
      // The node route goes over Tor, so every node is reachable while Tor is on.
      expect(torCovered.contains(TorRoute.node), isTrue);
      expect(failoverOverTor(_c, hasOnion: (_, _) => false), isTrue);
    });

    test('holds: off, Offline, a node on this computer, Tor not up, a payment going out', () {
      FailoverHold? hold({bool on = true, NetworkMode mode = NetworkMode.standard, TorState tor = TorState.off, String url = _a, bool busy = false}) =>
          failoverHold(on: on, mode: mode, tor: tor, nodeUrl: url, busy: busy);
      expect(hold(), isNull);
      expect(hold(on: false), FailoverHold.off);
      expect(hold(mode: NetworkMode.nodeOnly), FailoverHold.offline);
      expect(hold(mode: NetworkMode.killSwitch), FailoverHold.offline);
      expect(hold(url: _local), FailoverHold.localNode);
      expect(hold(url: 'http://localhost:3413'), FailoverHold.localNode);
      expect(hold(mode: NetworkMode.torOnly, tor: TorState.starting), FailoverHold.waitingForTor);
      expect(hold(mode: NetworkMode.torOnly, tor: TorState.on), isNull);
      expect(hold(tor: TorState.starting), FailoverHold.waitingForTor);
      expect(hold(tor: TorState.on), isNull);
      expect(hold(busy: true), FailoverHold.busy);
    });
  });

  group('AdvancedPrefs.nodeFailover', () {
    test('on by default, an old stored value reads as on, off survives encode and JSON', () {
      expect(const AdvancedPrefs().nodeFailover, isTrue);
      expect(AdvancedPrefs.decode('outputs|torOnly').nodeFailover, isTrue);
      expect(AdvancedPrefs.decode(null).nodeFailover, isTrue);
      expect(AdvancedPrefs.fromJson({'features': <String>[], 'networkMode': 'standard'}).nodeFailover, isTrue);
      final off = const AdvancedPrefs().withFeature(AdvancedFeature.outputs, true).withNodeFailover(false);
      expect(AdvancedPrefs.decode(off.encode()), off);
      expect(AdvancedPrefs.fromJson(off.toJson()), off);
      expect(off.withMode(NetworkMode.nodeOnly).nodeFailover, isFalse);
      expect(off == off.withNodeFailover(true), isFalse);
    });

    test('the hub counts failover only when it is turned off', () {
      expect(AdvancedPrefs.none.any, isFalse);
      expect(AdvancedPrefs.none.withNodeFailover(false).any, isTrue);
    });
  });

  test('the notice text', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(l.nodeFailoverSwitched('c.example'), 'Node not answering. Switched to c.example.');
    expect(l.nodeFailoverInsteadOf('a.example'), 'Instead of a.example');
    expect(l.advNodeFailoverHint, 'When your node stops answering, the wallet uses the next working node in your list for this session.');
  });

  group('phone watcher', () {
    test('moves after 30 s of no answer, not before, to the next healthy node; nothing saved', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeDown();
        h.elapse(const Duration(seconds: 28));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.failover, isNull);
        h.elapse(const Duration(seconds: 4));
        // b is down on the monitor; c is the first healthy one.
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
        expect(h.container.read(walletConfigProvider)?.nodeUrl, _c);
        // Saved choice and list as they were.
        expect(h.container.read(hostSettingsProvider).nodeUse, _a);
        expect(serverListOf(h.container.read(hostSettingsProvider), ServerKind.node).entries, [_a, _b, _c, _d]);
        h.dispose();
      });
    });

    test('a healthy node that does not answer is passed over', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c});
        h.nodeDown();
        h.elapse(const Duration(seconds: 50));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_d]);
        h.dispose();
      });
    });

    test('nothing working: stays, says nothing', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        h.elapse(const Duration(minutes: 3));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.failover, isNull);
        h.dispose();
      });
    });

    test('nothing working: tries again after 30 s, then 1, 2 and 5 minutes', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        int tries() => h.session.nodeTipsFor.where((c) => c.nodeUrl == _c).length;
        h.nodeDown();
        h.elapse(const Duration(seconds: 31));
        expect(tries(), 1);
        for (final (wait, after) in [(30, 2), (60, 3), (120, 4), (300, 5), (300, 6)]) {
          h.elapse(Duration(seconds: wait - 2));
          expect(tries(), after - 1, reason: 'before the ${wait}s wait ends');
          h.elapse(const Duration(seconds: 2));
          expect(tries(), after, reason: 'after the ${wait}s wait');
        }
        h.dispose();
      });
    });

    test('off screen: nothing is asked; back on screen it tries after 30 s', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        int tries() => h.session.nodeTipsFor.where((c) => c.nodeUrl == _c).length;
        h.nodeDown();
        h.elapse(const Duration(seconds: 31));
        expect(tries(), 1);
        final watch = h.container.read(nodeFailoverWatchProvider.notifier);
        watch.paused();
        h.elapse(const Duration(minutes: 10));
        expect(tries(), 1);
        watch.resumed();
        h.elapse(const Duration(seconds: 29));
        expect(tries(), 1);
        h.elapse(const Duration(seconds: 2));
        expect(tries(), 2);
        h.dispose();
      });
    });

    test('a node that answers again in time: no move', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeDown();
        h.elapse(const Duration(seconds: 20));
        h.nodeUp();
        h.elapse(const Duration(minutes: 1));
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('switch off: never', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withNodeFailover(false));
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('Offline: never', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.nodeOnly));
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('a node on this computer: never', () {
      fakeAsync((async) {
        final h = _Harness(async, inUse: _local);
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('Tor only: not while Tor is not up, over Tor once it is', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.torOnly), tor: true);
        h.nodeDown();
        h.elapse(const Duration(minutes: 1));
        expect(h.session.serverSwitches, isEmpty);
        h.torUp();
        h.elapse(const Duration(seconds: 35));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        h.dispose();
      });
    });

    test('a payment going out: the move waits until it is done', () {
      fakeAsync((async) {
        final h = _Harness(async);
        final sending = Completer<void>();
        unawaited(h.container.read(autoLockHoldProvider.notifier).during(() => sending.future));
        h.nodeDown();
        h.elapse(const Duration(minutes: 1));
        expect(h.session.serverSwitches, isEmpty);
        sending.complete();
        h.elapse(const Duration(seconds: 35));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        h.dispose();
      });
    });

    test('a node the user picks becomes the chosen one; a new session starts on the chosen node', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeDown();
        h.elapse(const Duration(seconds: 35));
        expect(h.failover?.inUse, _c);
        // The user picks d: saved and switched (what switchServersLive does).
        unawaited(h.container.read(networkChoiceProvider.notifier).save(mainnetPreset, _d));
        h.container.read(walletConfigProvider.notifier).select(h.config(_d));
        h.elapse(Duration.zero);
        expect(h.failover, isNull);

        // Lock and unlock: the failover is gone; the next open reads the saved choice.
        final h2 = _Harness(async);
        h2.nodeDown();
        h2.elapse(const Duration(seconds: 35));
        expect(h2.failover?.inUse, _c);
        h2.container.read(sessionProvider.notifier).unlocked(FakeWalletSession()..openedConfig = h2.config(_a));
        h2.elapse(Duration.zero);
        expect(h2.failover, isNull);
        expect(h2.container.read(hostSettingsProvider).nodeUse, _a);
        h.dispose();
        h2.dispose();
      });
    });
  });
}

class _Raw extends Notifier<WalletStatus> {
  @override
  WalletStatus build() => (node: const NodeStatus(NodeState.online), epicbox: null);

  void set(NodeState s) => state = (node: NodeStatus(s), epicbox: null);
}

final _raw = NotifierProvider<_Raw, WalletStatus>(_Raw.new);

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.starting, receiving: true);

  void up() => state = const PhoneTorState(phase: PhoneTorPhase.connected, receiving: true);
}

/// Nodes in [dead] give no answer.
class _Service extends FakeWalletService {
  _Service(this.dead) : super(existingWallets: {_dir});

  final Set<String> dead;

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) async {
    if (dead.contains(config.nodeUrl)) throw const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'no answer');
    return NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');
  }
}

class _Directory implements dir.RelayDirectory, dir.NodeDirectory {
  @override
  Future<List<dir.NodeStatus>> nodes(String chain) async => const [
    dir.NodeStatus(url: _b, healthy: false, verified: true, state: dir.NodeHealthState.down),
    dir.NodeStatus(url: _c, healthy: true, verified: true, state: dir.NodeHealthState.healthy),
    dir.NodeStatus(url: _d, healthy: true, verified: true, state: dir.NodeHealthState.healthy),
  ];

  @override
  Future<List<dir.RelayStatus>> relays(String chain) async => const [];
}

/// An open mainnet wallet on [inUse] (the saved choice a), the list a, b, c, d, the monitor
/// saying b is down and c, d healthy, and the failover watcher alive.
class _Harness {
  _Harness(this._async, {Set<String> deadNodes = const {_a}, String inUse = _a, AdvancedPrefs? prefs, bool tor = false}) {
    // The node in use and the Node list: the settings file's.
    hostSettings = testSettings().withValues({
      'node.servers': [_a, _b, _c, _d],
    });
    if (prefs != null) {
      store.values['app.advanced_prefs'] = prefs.encode();
      useNetworkModeFile(prefs.networkMode);
    }
    final service = _Service(deadNodes);
    session = service.session;
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(service),
        secretStoreProvider.overrideWithValue(store),
        dir.relayDirectoryProvider.overrideWithValue(_Directory()),
        rawWalletStatusProvider.overrideWith((ref) => ref.watch(_raw)),
        if (tor) phoneTorProvider.overrideWith(_Tor.new),
      ],
    );
    final config = this.config(inUse);
    session.openedConfig = config;
    container.read(walletConfigProvider.notifier).select(config);
    container.read(sessionProvider.notifier).unlocked(session);
    if (tor) container.read(phoneTorProvider);
    container.listen(walletStatusProvider, (_, _) {}, fireImmediately: true);
    container.listen(nodeFailoverWatchProvider, (_, _) {}, fireImmediately: true);
    container.listen(nodeFailoverProvider, (_, _) {}, fireImmediately: true);
    // Settings and the list read; online settled.
    unawaited(container.read(appSettingsProvider.future));
    elapse(statusSettle);
  }

  final FakeAsync _async;
  final MemorySecretStore store = MemorySecretStore();
  late final FakeWalletSession session;
  late final ProviderContainer container;

  WalletConfig config(String nodeUrl) => mainnetPreset.config(dataDir: _dir, nodeUrl: nodeUrl);

  NodeFailover? get failover => container.read(nodeFailoverProvider);

  void nodeDown() {
    container.read(_raw.notifier).set(NodeState.offline);
    elapse(Duration.zero);
  }

  void nodeUp() {
    container.read(_raw.notifier).set(NodeState.online);
    elapse(Duration.zero);
  }

  void torUp() {
    (container.read(phoneTorProvider.notifier) as _Tor).up();
    elapse(Duration.zero);
  }

  void elapse(Duration d) {
    _async.elapse(d);
    _async.flushMicrotasks();
  }

  void dispose() => container.dispose();
}
