// SPDX-License-Identifier: Apache-2.0
// Node failover (Settings › Advanced, on by default): the shared rules, the stored switch, and
// the phone's adapter on the engine, on a fake clock. When the node in use stops answering the
// wallet asks the list at once and moves to the best node that answers for this session; the
// chosen node and the list stay as saved.

import 'dart:async';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/devices/phone_devices.dart' show deviceServiceProvider;
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/node_failover.dart';
import 'package:epic_wallet/src/node_failover_engine.dart' show FailoverSearch;
import 'package:epic_wallet/src/node_failover_phone.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' as dir;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/server_list_file.dart';
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/server_switch.dart' show ServerSwitcher;
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

import 'support/settings_modes.dart';
import 'support/test_settings.dart';

const _a = 'https://a.example';
const _b = 'https://b.example';
const _c = 'https://c.example';
const _d = 'https://d.example';
const _e = 'https://e.example';
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

  test('the failover texts', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(l.nodeFailoverInsteadOf('a.example'), 'Instead of a.example');
    expect(l.advNodeFailoverHint, 'When the node in use stops answering, the wallet uses the next working node in the list for this session.');
  });

  group('phone watcher', () {
    test('a node that stops answering: the list is asked at once, the best answer is used; nothing saved', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        // b is down on the monitor; c is the first healthy one.
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
        expect(h.container.read(walletConfigProvider)?.nodeUrl, _c);
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.idle);
        // Saved choice and list as they were.
        expect(h.container.read(hostSettingsProvider).nodeUse, _a);
        expect(serverListOf(h.container.read(hostSettingsProvider), ServerKind.node).entries, [_a, _b, _c, _d]);
        h.dispose();
      });
    });

    test('a node that answers behind the wallet is left after 30 s, as behind', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeBehind(504);
        h.elapse(const Duration(seconds: 28));
        expect(h.failover, isNull);
        h.elapse(const Duration(seconds: 4));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        expect(h.failover?.inUse, _c);
        expect(h.failover?.behind, isTrue);
        h.dispose();
      });
    });

    test('a node that never answered since the wallet opened: left as soon as it reads offline', () {
      fakeAsync((async) {
        final h = _Harness(async, answered: false);
        h.elapse(const Duration(seconds: 1));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
        h.dispose();
      });
    });

    test('a healthy node that does not answer is passed over', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c});
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_d]);
        h.dispose();
      });
    });

    test('a 5 s blip starts no search; the node is back before the settle time', () {
      fakeAsync((async) {
        final h = _Harness(async, settle: nodeSettle);
        h.nodeDown();
        h.elapse(const Duration(seconds: 5));
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.idle);
        expect(h.container.read(walletStatusProvider).node.state, NodeState.connecting);
        h.nodeUp();
        h.elapse(const Duration(seconds: 30));
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.idle);
        expect(h.container.read(walletStatusProvider).node.state, NodeState.online);
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('a 60 s outage starts the search once the settle time has passed', () {
      fakeAsync((async) {
        final h = _Harness(async, settle: nodeSettle);
        h.nodeDown();
        h.elapse(nodeSettle - const Duration(seconds: 1));
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.idle);
        h.elapse(const Duration(seconds: 36));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), isNotEmpty);
        h.dispose();
      });
    });

    test('a node that never returns its answer is counted failed at the probe budget', () {
      fakeAsync((async) {
        final h = _Harness(async, hungNodes: {_c});
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        // d answered at once; c, ranked above it, still has its budget.
        expect(h.session.serverSwitches, isEmpty);
        h.elapse(const Duration(seconds: 1));
        // The prefer window after the first good answer is over: d is used.
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_d]);
        h.dispose();
      });
    });

    test('searching reads connecting, a round that found nothing reads offline', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a}, hungNodes: {_c, _d});
        h.nodeDown();
        h.elapse(const Duration(seconds: 6));
        // Offline has lasted the settle time, but a node is still being looked for.
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.searching);
        expect(h.shown, NodeState.connecting);
        h.elapse(const Duration(seconds: 3));
        // Every probe ran out its budget (8 s): the truth is offline.
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.noneAnswer);
        expect(h.shown, NodeState.offline);
        h.dispose();
      });
    });

    test('nothing working: stays, says nothing, and keeps asking with a backoff up to a minute', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        h.elapse(const Duration(milliseconds: 100));
        expect(h.asked(_c), 1);
        // The first wait is 2 s, +-20 %.
        h.elapse(const Duration(milliseconds: 1400));
        expect(h.asked(_c), 1);
        h.elapse(const Duration(seconds: 1));
        expect(h.asked(_c), 2);
        h.elapse(const Duration(minutes: 10));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.failover, isNull);
        // Never more than a minute (+-20 %) apart, and it never stops.
        final before = h.asked(_c);
        h.elapse(const Duration(seconds: 73));
        expect(h.asked(_c), greaterThan(before));
        expect(h.asked(_c), lessThan(before + 4));
        h.dispose();
      });
    });

    test('a node that comes back ends the search; nothing more is asked', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        expect(h.asked(_c), 1);
        h.nodeUp();
        h.elapse(const Duration(minutes: 2));
        expect(h.asked(_c), 1);
        expect(h.container.read(nodeFailoverSearchProvider), FailoverSearch.idle);
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('off screen: nothing is asked; back on screen it asks at once', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        final watch = h.container.read(nodeFailoverWatchProvider.notifier);
        watch.paused();
        final before = h.asked(_c);
        h.elapse(const Duration(minutes: 10));
        expect(h.asked(_c), before);
        watch.resumed();
        h.elapse(Duration.zero);
        expect(h.asked(_c), before + 1);
        h.dispose();
      });
    });

    test('a network change or a resume (the recheck) runs a waiting round now', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        h.elapse(const Duration(seconds: 30));
        final before = h.asked(_c);
        unawaited(h.container.read(nodeRecheckProvider.notifier).recheck('network'));
        h.elapse(Duration.zero);
        expect(h.asked(_c), before + 1);
        h.dispose();
      });
    });

    test('a node added to the list while nothing works: a round runs now and moves to it', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        h.nodeDown();
        // Far into the backoff: the next round is a minute away.
        h.elapse(const Duration(minutes: 3));
        expect(h.session.serverSwitches, isEmpty);
        unawaited(h.container.read(serverListProvider((ServerKind.node, h.session.chain)).notifier).add(_e));
        h.elapse(const Duration(milliseconds: 500));
        expect(h.asked(_e), greaterThan(0));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_e]);
        expect(h.failover, const NodeFailover(chosen: _a, inUse: _e));
        h.dispose();
      });
    });

    test('a resume or a network change with a session open asks the wallet for fresh connections', () {
      fakeAsync((async) {
        final h = _Harness(async);
        final before = h.session.nodeConnectionDrops;
        h.container.read(nodeFailoverWatchProvider.notifier).resumed();
        h.elapse(Duration.zero);
        expect(h.session.nodeConnectionDrops, before + 1);
        unawaited(h.container.read(nodeRecheckProvider.notifier).recheck('network'));
        h.elapse(Duration.zero);
        expect(h.session.nodeConnectionDrops, before + 2);
        h.dispose();
      });
    });

    test('a node that stops answering: fresh connections once, before the first probe', () {
      fakeAsync((async) {
        final h = _Harness(async, deadNodes: {_a, _c, _d});
        final before = h.session.nodeConnectionDrops;
        var atProbe = -1;
        h.session.onNodeTipFor = () {
          if (atProbe < 0) atProbe = h.session.nodeConnectionDrops;
        };
        h.nodeDown();
        h.elapse(const Duration(seconds: 1));
        expect(atProbe, before + 1, reason: 'dropped before the first node was asked');
        h.elapse(const Duration(seconds: 30));
        expect(h.session.nodeConnectionDrops, before + 1, reason: 'later rounds do not');
        h.dispose();
      });
    });

    test('switch off: the node in use is asked again, the wallet never moves', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withNodeFailover(false));
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.asked(_c), 0);
        h.dispose();
      });
    });

    test('Node only: never moves', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.nodeOnly));
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.asked(_c), 0);
        h.dispose();
      });
    });

    test('a node on this computer: never left', () {
      fakeAsync((async) {
        final h = _Harness(async, inUse: _local);
        h.nodeDown();
        h.elapse(const Duration(minutes: 2));
        expect(h.session.serverSwitches, isEmpty);
        h.dispose();
      });
    });

    test('Tor only: nothing asked while Tor is not up, moved over Tor once it is', () {
      fakeAsync((async) {
        final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.torOnly), tor: true);
        h.nodeDown();
        h.elapse(const Duration(minutes: 1));
        expect(h.session.serverSwitches, isEmpty);
        expect(h.asked(_c), 0);
        h.torUp();
        h.elapse(const Duration(seconds: 1));
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
        h.elapse(const Duration(seconds: 1));
        expect(h.session.serverSwitches.map((c) => c.nodeUrl), [_c]);
        h.dispose();
      });
    });

    test('a node the user picks becomes the chosen one; a new session starts on the chosen node', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.nodeDown();
        h.elapse(const Duration(seconds: 2));
        expect(h.failover?.inUse, _c);
        // The user picks d: saved and switched (what switchServersLive does).
        unawaited(h.container.read(networkChoiceProvider.notifier).save(mainnetPreset, _d));
        h.container.read(walletConfigProvider.notifier).select(h.config(_d));
        h.elapse(Duration.zero);
        expect(h.failover, isNull);

        // Lock and unlock: the failover is gone; the next open reads the saved choice.
        final h2 = _Harness(async);
        h2.nodeDown();
        h2.elapse(const Duration(seconds: 2));
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

  group('server switcher', () {
    test('switches run one at a time; only the latest waiting pick runs; failover gives way to a pick', () async {
      final s = ServerSwitcher();
      final ran = <String>[];
      final first = Completer<bool>();
      final a = s.user(() {
        ran.add('a');
        return first.future;
      });
      await Future<void>.delayed(Duration.zero);
      final b = s.user(() async {
        ran.add('b');
        return true;
      });
      final c = s.user(() async {
        ran.add('c');
        return true;
      });
      // A failover switch asked while picks wait is dropped.
      final f = s.failover(() async {
        ran.add('f');
        return true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(ran, ['a']);
      first.complete(true);
      expect(await a, isTrue);
      expect(await b, isTrue, reason: 'replaced by c: nothing to do');
      expect(await c, isTrue);
      expect(await f, isFalse);
      expect(ran, ['a', 'c']);

      // A failover switch waiting behind another is dropped when the user picks meanwhile.
      final hold = Completer<bool>();
      final g = s.failover(() => hold.future);
      await Future<void>.delayed(Duration.zero);
      final f2 = s.failover(() async {
        ran.add('f2');
        return true;
      });
      final d = s.user(() async {
        ran.add('d');
        return true;
      });
      hold.complete(true);
      expect(await g, isTrue);
      expect(await f2, isFalse);
      expect(await d, isTrue);
      expect(ran, ['a', 'c', 'd']);
    });
  });
}

class _Raw extends Notifier<WalletStatus> {
  @override
  WalletStatus build() => (node: const NodeStatus(NodeState.online), epicbox: null);

  void set(NodeState s) => state = (node: NodeStatus(s), epicbox: null);

  void behind(int blocks) => state = (
    // The node in use answers that many blocks below the others (2 500 000).
    node: NodeStatus(
      NodeState.offline,
      tip: NodeTip(height: BigInt.from(2500000 - blocks), nodeVersion: '3.6.0'),
      validated: false,
      behind: blocks,
    ),
    epicbox: null,
  );
}

final _raw = NotifierProvider<_Raw, WalletStatus>(_Raw.new);

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.starting, receiving: true);

  void up() => state = const PhoneTorState(phase: PhoneTorPhase.connected, receiving: true);
}

/// Nodes in [dead] give no answer; nodes in [hung] never answer at all.
class _Service extends FakeWalletService {
  _Service(this.dead, this.hung) : super(existingWallets: {_dir});

  final Set<String> dead;
  final Set<String> hung;

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) async {
    if (hung.contains(config.nodeUrl)) return Completer<NodeTip>().future;
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
  _Harness(this._async, {Set<String> deadNodes = const {_a}, Set<String> hungNodes = const {}, String inUse = _a, AdvancedPrefs? prefs, bool tor = false, bool answered = true, Duration settle = Duration.zero}) {
    // The node in use and the Node list: the settings file's.
    hostSettings = testSettings().withValues({
      'node.servers': [_a, _b, _c, _d],
    });
    if (prefs != null) {
      store.values['app.advanced_prefs'] = prefs.encode();
      useNetworkModeFile(prefs.networkMode);
    }
    final service = _Service(deadNodes, hungNodes);
    session = service.session;
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(service),
        secretStoreProvider.overrideWithValue(store),
        dir.relayDirectoryProvider.overrideWithValue(_Directory()),
        rawWalletStatusProvider.overrideWith((ref) => ref.watch(_raw)),
        // These tests count failures at once; the settle window has its own tests.
        nodeSettleProvider.overrideWithValue(settle),
        // No linked devices: their service reads the app's lifecycle, which a plain test has not.
        deviceServiceProvider.overrideWithValue(null),
        if (tor) phoneTorProvider.overrideWith(_Tor.new),
      ],
    );
    // A node that never answers from here: offline from the start.
    if (!answered) container.read(_raw.notifier).set(NodeState.offline);
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

  /// How often [url] was asked its tip.
  int asked(String url) => session.nodeTipsFor.where((c) => c.nodeUrl == url).length;

  NodeState get shown => container.read(walletStatusProvider).node.state;

  void nodeDown() {
    container.read(_raw.notifier).set(NodeState.offline);
    elapse(Duration.zero);
  }

  void nodeBehind(int blocks) {
    container.read(_raw.notifier).behind(blocks);
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
