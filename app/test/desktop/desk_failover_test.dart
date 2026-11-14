// SPDX-License-Identifier: Apache-2.0
// Node failover on the desktop (Settings › Advanced, on by default), on the engine both apps
// run: a node that stops answering is left at once for the best node of the list that answers,
// for this session (useNodeForSession, never useNode); the chosen node stays saved. A node that
// answers but reads behind is left after the wait for a node ahead of it. Nothing tells the user
// with a notice: the node's health and the rail name the node in use.

import 'dart:async';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_failover.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/server_lists.dart' show ServerKind, deskServerListProvider;
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = 'https://a.example';
const _b = 'https://b.example';
const _c = 'https://c.example';
const _d = 'https://d.example';
const _e = 'https://e.example';
const _local = 'http://127.0.0.1:3413';
const _home = 'http://192.168.1.5:3413';

/// A wallet on [inUse] whose nodes in [dead] give no answer; b was seen down.
class _Wallet extends MockDeskWallet {
  _Wallet({required this.inUse, required Set<String> dead}) : dead = {...dead}, saved = inUse, super(delay: Duration.zero);

  String inUse;
  String saved;
  final Set<String> dead;
  final List<String> picked = [];
  bool torStarting = false;

  /// The height of each node that answers; [height] for those not named.
  final Map<String, int> heights = {};
  static const int height = 2914414;
  Set<String> added = const {};
  bool working = false;

  /// Nodes whose ask answers only when the test completes it (one that never does hangs).
  final Map<String, Completer<NodeServer>> held = {};

  /// Holds the next session moves until completed, as a reopen that takes its time.
  Completer<void>? moving;

  /// Counts the user's picks: a session move overtaken by one is dropped (`_picks` in LEPIC's
  /// desktop wallet).
  int picks = 0;

  @override
  bool get busy => working;

  @override
  Future<ServiceStatus> status() async => ServiceStatus(
    node: NodeServer(url: inUse, label: inUse, own: added.contains(inUse)),
    nodeHealth: dead.contains(inUse) ? ServiceHealth.down : ServiceHealth.ok,
    nodeHeight: heights[inUse] ?? height,
    epicbox: const EpicboxServer(domain: 'box.stack.invalid'),
    epicboxHealth: ServiceHealth.ok,
    httpListener: ServiceHealth.off,
    tor: torStarting ? ServiceHealth.checking : ServiceHealth.ok,
    torCanSend: !torStarting,
  );

  @override
  Future<List<NodeServer>> nodes() async => const [
    NodeServer(url: _a, label: 'a'),
    NodeServer(url: _b, label: 'b', health: ServiceHealth.down),
    NodeServer(url: _c, label: 'c', health: ServiceHealth.ok),
    NodeServer(url: _d, label: 'd', health: ServiceHealth.ok),
  ];

  /// Every node [checkNode] asked, in order.
  final List<String> checked = [];

  /// How many fresh-connection asks had been made when the first node was asked.
  int? dropsAtFirstCheck;

  @override
  Future<NodeServer> checkNode(String url) async {
    checked.add(url);
    dropsAtFirstCheck ??= nodeConnectionDrops;
    final hold = held[url];
    if (hold != null) return hold.future;
    return NodeServer(url: url, label: url, height: heights[url] ?? height, health: dead.contains(url) ? ServiceHealth.down : ServiceHealth.ok);
  }

  @override
  Future<void> useNodeForSession(String url) async {
    final pick = picks;
    await moving?.future;
    if (pick != picks) return;
    await super.useNodeForSession(url);
    inUse = url;
  }

  @override
  Future<void> useNode(String url) async {
    picks++;
    await super.useNode(url);
    picked.add(url);
    inUse = saved = url;
  }
}

class _Harness {
  /// [answered]: the node in use answered once before it went down; without, it never answered
  /// since the wallet opened.
  _Harness(this._async, {Duration blip = Duration.zero, String inUse = _a, Set<String> dead = const {_a}, AdvancedPrefs? prefs, bool tor = false, bool answered = true, this.node, SettingsPrefs? settingsPrefs, void Function(_Wallet)? before})
    : wallet = _Wallet(inUse: inUse, dead: answered ? const {} : dead) {
    // What the fake does from the first round on: the harness already runs one.
    before?.call(wallet);
    hostSettings = hostSettings.withValues({
      'node.servers': const [_a, _b, _c, _d],
    });
    container = ProviderContainer(overrides: [nodeBlipWindowProvider.overrideWithValue(blip), deskApiProvider.overrideWithValue(wallet), if (node != null) deskNodeProvider.overrideWithValue(node!)]);
    if (settingsPrefs != null) container.read(settingsPrefsProvider.notifier).set(settingsPrefs);
    container.listen(deskFailoverWatchProvider, (_, _) {}, fireImmediately: true);
    container.listen(deskFailoverProvider, (_, _) {}, fireImmediately: true);
    container.listen(deskNodeHealthProvider, (_, _) {}, fireImmediately: true);
    final n = container.read(deskProvider.notifier);
    unawaited(n.refresh());
    elapse(Duration.zero);
    final s = container.read(deskProvider).settings;
    unawaited(n.saveSettings(s.copyWith(advanced: prefs ?? s.advanced, tor: tor)));
    elapse(Duration.zero);
    if (answered && dead.isNotEmpty) {
      wallet.dead.addAll(dead);
      poll();
    }
  }

  final FakeAsync _async;
  final _Wallet wallet;
  final MockDeskNode? node;
  late final ProviderContainer container;

  NodeFailover? get failover => container.read(deskFailoverProvider);
  ServiceHealth? get health => container.read(deskNodeHealthProvider);
  FailoverSearch get search => container.read(deskFailoverSearchProvider);
  DeskFailoverWatch get watch => container.read(deskFailoverWatchProvider.notifier);

  /// The status is read again, as the 5 s poll does.
  void poll() {
    unawaited(container.read(deskProvider.notifier).refresh());
    elapse(Duration.zero);
  }

  void elapse(Duration d) {
    _async.elapse(d);
    _async.flushMicrotasks();
  }

  void dispose() => container.dispose();
}

/// [node] read by the monitor at [behind] blocks under the network's tip.
NodeInfo _lagging(String url, int height, int behind) => NodeInfo(
  url: url,
  source: NodeInfoSource.directory,
  at: DateTime(2026),
  state: NodeHealthState.degraded,
  height: height,
  networkHeight: height + behind,
  blocksBehind: behind,
);

/// A node that answers and reads [behind] blocks under the tip, the others [ahead] over it.
class _Behind {
  _Behind(FakeAsync async, {int behind = 12, int ahead = 12, Set<String> added = const {}, AdvancedPrefs? prefs, bool working = false, String inUse = _a})
    : h = _Harness(async, inUse: inUse, dead: const {}, prefs: prefs, node: MockDeskNode()) {
    h.wallet
      ..added = added
      ..working = working
      ..heights.addAll({inUse: _Wallet.height, _c: _Wallet.height + ahead, _d: _Wallet.height + ahead});
    h.node!.infos[nodeHost(inUse)] = _lagging(inUse, _Wallet.height, behind);
    h.poll();
  }

  final _Harness h;

  /// The shell's ask, then [wait].
  void ask([Duration wait = Duration.zero]) {
    unawaited(h.watch.askBehind());
    h.elapse(wait);
  }
}

void main() {
  test('the cue under the node in use', () {
    expect(englishStrings.deskNodeFailoverInsteadOf('a.example'), 'Instead of a.example');
    expect(englishStrings.deskSetAdvNodeFailover, 'Switch node automatically');
  });

  test('DeskSettings has no failover field of its own: the Advanced pref is on by default', () {
    expect(const DeskSettings().advanced.nodeFailover, isTrue);
  });

  test('a node that never answered since the wallet opened: left as soon as it reads down', () {
    fakeAsync((async) {
      final h = _Harness(async, answered: false);
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.sessionNodes, [_c]);
      h.dispose();
    });
  });

  test('a node that stops answering is left at once for the best that answers, for this session only', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.sessionNodes, [_c]);
      expect(h.wallet.picked, isEmpty);
      expect(h.wallet.saved, _a);
      expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
      expect(h.failover!.behind, isFalse);
      expect(h.container.read(deskProvider).status?.node.url, _c);
      expect(h.health, ServiceHealth.ok);
      expect(h.search, FailoverSearch.idle);
      h.dispose();
    });
  });

  group('a blip is not an outage', () {
    const blip = Duration(seconds: 25);

    test('5 s down: checking only, nothing searched or moved; back, nothing to clear', () {
      fakeAsync((async) {
        final h = _Harness(async, blip: blip);
        // _Harness already read the node down once the window is not zero.
        expect(h.container.read(deskProvider).status?.nodeHealth, ServiceHealth.down);
        h.elapse(const Duration(seconds: 5));
        expect(h.health, ServiceHealth.checking);
        expect(h.search, FailoverSearch.idle);
        expect(h.wallet.checked, isEmpty);
        expect(h.wallet.sessionNodes, isEmpty);
        h.wallet.dead.clear();
        h.poll();
        h.elapse(blip * 2);
        expect(h.health, ServiceHealth.ok);
        expect(h.wallet.sessionNodes, isEmpty);
        expect(h.failover, isNull);
        h.dispose();
      });
    });

    test('60 s down: red and failover after the window; recovery clears it', () {
      fakeAsync((async) {
        final h = _Harness(async, blip: blip, dead: {_a, _c, _d});
        h.elapse(const Duration(seconds: 20));
        expect(h.health, ServiceHealth.checking);
        expect(h.search, FailoverSearch.idle);
        h.elapse(const Duration(seconds: 6));
        expect(h.search, FailoverSearch.noneAnswer);
        expect(h.health, ServiceHealth.down);
        h.elapse(const Duration(seconds: 34));
        expect(h.health, ServiceHealth.down);
        h.wallet.dead.clear();
        h.elapse(const Duration(seconds: 75));
        expect(h.health, ServiceHealth.ok);
        h.dispose();
      });
    });
  });

  test('a node whose ask never returns does not hold the round: the next that answers is used', () {
    fakeAsync((async) {
      final h = _Harness(async, before: (w) => w.held[_c] = Completer<NodeServer>());
      h.elapse(const Duration(seconds: 2));
      expect(h.wallet.sessionNodes, [_d]);
      expect(h.failover, const NodeFailover(chosen: _a, inUse: _d));
      h.dispose();
    });
  });

  test('while a round looks for a node the health reads connecting; none answering reads down', () {
    fakeAsync((async) {
      final h = _Harness(async, answered: false, before: (w) => w.held..[_c] = Completer<NodeServer>()..[_d] = Completer<NodeServer>());
      h.elapse(const Duration(seconds: 1));
      expect(h.container.read(deskProvider).status?.nodeHealth, ServiceHealth.down);
      expect(h.search, FailoverSearch.searching);
      expect(h.health, ServiceHealth.checking);
      // The probe budget ends the round.
      h.elapse(const Duration(seconds: 30));
      expect(h.search, FailoverSearch.noneAnswer);
      expect(h.health, ServiceHealth.down);
      expect(h.wallet.sessionNodes, isEmpty);
      h.dispose();
    });
  });

  test('all nodes down: down, still trying, then back by itself when one answers', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c, _d});
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.sessionNodes, isEmpty);
      expect(h.failover, isNull);
      expect(h.search, FailoverSearch.noneAnswer);
      expect(h.health, ServiceHealth.down);
      int tries() => h.wallet.checked.where((u) => u == _c).length;
      // It never stops while the wallet is open: at least a round a minute and a quarter.
      for (var i = 0; i < 8; i++) {
        final before = tries();
        h.elapse(const Duration(seconds: 75));
        expect(tries(), greaterThan(before), reason: 'window $i');
      }
      expect(h.wallet.sessionNodes, isEmpty);
      h.wallet.dead.remove(_c);
      h.elapse(const Duration(seconds: 75));
      expect(h.wallet.sessionNodes, [_c]);
      expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
      expect(h.health, ServiceHealth.ok);
      h.dispose();
    });
  });

  test('the window coming back: a round at once, not at the end of the wait', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c, _d});
      int tries() => h.wallet.checked.where((u) => u == _c).length;
      // Past the first waits: a round, then the longest wait.
      h.elapse(const Duration(minutes: 3));
      final settled = tries();
      while (tries() == settled) {
        h.elapse(const Duration(seconds: 1));
      }
      final after = tries();
      h.watch.resumed();
      h.elapse(const Duration(seconds: 1));
      expect(tries(), after + 1);
      h.dispose();
    });
  });

  test('a node added to the list while nothing works: a round runs now and moves to it', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c, _d});
      int tries() => h.wallet.checked.where((u) => u == _c).length;
      // Just after a round, past the first waits: the next is up to a minute away.
      h.elapse(const Duration(minutes: 3));
      final settled = tries();
      while (tries() == settled) {
        h.elapse(const Duration(seconds: 1));
      }
      expect(h.wallet.sessionNodes, isEmpty);
      unawaited(h.container.read(deskServerListProvider(ServerKind.node).notifier).add(_e));
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.checked, contains(_e));
      expect(h.wallet.sessionNodes, [_e]);
      expect(h.failover, const NodeFailover(chosen: _a, inUse: _e));
      h.dispose();
    });
  });

  test('the window coming back asks the wallet for fresh connections', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.elapse(const Duration(seconds: 1));
      final before = h.wallet.nodeConnectionDrops;
      h.watch.resumed();
      h.elapse(Duration.zero);
      expect(h.wallet.nodeConnectionDrops, before + 1);
      h.dispose();
    });
  });

  test('a node that stops answering: fresh connections once, before the first node is asked', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c, _d});
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.dropsAtFirstCheck, greaterThanOrEqualTo(1), reason: 'dropped before the first ask (the wallet-opened kick and the search start)');
      final settled = h.wallet.nodeConnectionDrops;
      h.elapse(const Duration(seconds: 150));
      expect(h.wallet.nodeConnectionDrops, settled, reason: 'later rounds of the same search do not');
      h.dispose();
    });
  });

  group('a node that answers but reads behind', () {
    const wait = Duration(seconds: 29);
    const past = Duration(seconds: 2);

    test('moves to a node ahead after 30 s, for this session only', () {
      fakeAsync((async) {
        final b = _Behind(async);
        b.ask(wait);
        expect(b.h.wallet.sessionNodes, isEmpty, reason: 'one reading starts the wait');
        b.h.elapse(past);
        expect(b.h.wallet.sessionNodes, [_c]);
        expect(b.h.wallet.picked, isEmpty);
        expect(b.h.wallet.saved, _a);
        final moved = b.h.failover!;
        expect(moved, const NodeFailover(chosen: _a, inUse: _c));
        expect(moved.behind, isTrue);
        b.h.dispose();
      });
    });

    test('at the 10 blocks the app still calls synced, stays', () {
      fakeAsync((async) {
        final b = _Behind(async, behind: 10);
        b.ask(const Duration(seconds: 31));
        expect(b.h.wallet.sessionNodes, isEmpty);
        b.h.dispose();
      });
    });

    test('caught up during the wait, stays', () {
      fakeAsync((async) {
        final b = _Behind(async);
        b.ask(wait);
        b.h.wallet.heights[_a] = _Wallet.height + 5;
        b.h.poll();
        b.h.elapse(past);
        expect(b.h.wallet.sessionNodes, isEmpty);
        b.h.dispose();
      });
    });

    test('no node ahead: stays, and looks again no sooner than the wait', () {
      fakeAsync((async) {
        final b = _Behind(async, ahead: 3);
        b.ask(wait);
        b.h.elapse(past);
        expect(b.h.wallet.sessionNodes, isEmpty);
        final asked = b.h.wallet.checked.length;
        expect(asked, greaterThan(0));
        b.h.elapse(wait - const Duration(seconds: 3));
        expect(b.h.wallet.checked.length, asked);
        b.h.elapse(const Duration(seconds: 45));
        expect(b.h.wallet.checked.length, greaterThan(asked));
        expect(b.h.wallet.sessionNodes, isEmpty);
        expect(b.h.health, ServiceHealth.ok, reason: 'behind is not down');
        b.h.dispose();
      });
    });

    test('a node the user added stays', () {
      fakeAsync((async) {
        final b = _Behind(async, added: {_a});
        b.ask(const Duration(seconds: 31));
        expect(b.h.wallet.sessionNodes, isEmpty);
        b.h.dispose();
      });
    });

    test('a node on this computer stays', () {
      fakeAsync((async) {
        final b = _Behind(async, inUse: _local);
        b.ask(const Duration(seconds: 31));
        expect(b.h.wallet.sessionNodes, isEmpty);
        b.h.dispose();
      });
    });

    test('failover off and Node only stay', () {
      for (final prefs in [AdvancedPrefs.none.withNodeFailover(false), AdvancedPrefs.none.withMode(NetworkMode.nodeOnly)]) {
        fakeAsync((async) {
          final b = _Behind(async, prefs: prefs);
          b.ask(const Duration(seconds: 31));
          expect(b.h.wallet.sessionNodes, isEmpty);
          b.h.dispose();
        });
      }
    });

    test('a payment under way goes first', () {
      fakeAsync((async) {
        final b = _Behind(async, working: true);
        b.ask(wait);
        b.h.elapse(past);
        expect(b.h.wallet.sessionNodes, isEmpty);
        b.h.wallet.working = false;
        b.h.elapse(const Duration(seconds: 31));
        expect(b.h.wallet.sessionNodes, [_c]);
        b.h.dispose();
      });
    });
  });

  test('switch off, Node only, Kill switch, a node on this computer: never moves', () {
    fakeAsync((async) {
      for (final h in [
        _Harness(async, prefs: AdvancedPrefs.none.withNodeFailover(false)),
        _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.nodeOnly)),
        _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.killSwitch)),
        _Harness(async, inUse: _local, dead: {_local}),
      ]) {
        h.elapse(const Duration(minutes: 2));
        expect(h.wallet.sessionNodes, isEmpty);
        expect(h.failover, isNull);
        h.dispose();
      }
    });
  });

  test('Kill switch asks no node at all', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.killSwitch));
      h.elapse(const Duration(minutes: 2));
      expect(h.wallet.checked, isEmpty);
      h.dispose();
    });
  });

  test('Tor only: not while Tor is not up, over Tor once it is', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.torOnly), tor: true, before: (w) => w.torStarting = true);
      h.poll();
      h.elapse(const Duration(minutes: 1));
      expect(h.wallet.sessionNodes, isEmpty);
      h.wallet.torStarting = false;
      h.poll();
      h.elapse(const Duration(seconds: 2));
      expect(h.wallet.sessionNodes, [_c]);
      h.dispose();
    });
  });

  test('a node the user picks during a round wins: the round\'s answer is dropped', () {
    fakeAsync((async) {
      final h = _Harness(async, before: (w) => w.held..[_c] = Completer<NodeServer>()..[_d] = Completer<NodeServer>());
      h.elapse(Duration.zero);
      expect(h.search, FailoverSearch.searching);
      unawaited(h.container.read(deskProvider.notifier).useNode(_b));
      h.elapse(Duration.zero);
      h.wallet.held[_c]!.complete(const NodeServer(url: _c, label: 'c', height: _Wallet.height, health: ServiceHealth.ok));
      h.wallet.held[_d]!.complete(const NodeServer(url: _d, label: 'd', height: _Wallet.height, health: ServiceHealth.ok));
      h.elapse(const Duration(seconds: 5));
      expect(h.wallet.sessionNodes, isEmpty);
      expect(h.wallet.saved, _b);
      expect(h.container.read(deskProvider).status?.node.url, _b);
      expect(h.failover, isNull);
      h.dispose();
    });
  });

  test('a node the user picks during a running switch wins: the move is not recorded', () {
    fakeAsync((async) {
      final h = _Harness(async, answered: false, before: (w) => w.moving = Completer<void>());
      h.elapse(const Duration(seconds: 1));
      expect(h.wallet.sessionNodes, isEmpty, reason: 'the move to c runs');
      unawaited(h.container.read(deskProvider.notifier).useNode(_b));
      h.elapse(Duration.zero);
      h.wallet.moving!.complete();
      h.elapse(const Duration(seconds: 5));
      expect(h.wallet.sessionNodes, isEmpty);
      expect(h.wallet.saved, _b);
      expect(h.container.read(deskProvider).status?.node.url, _b);
      expect(h.failover, isNull);
      h.dispose();
    });
  });

  test('a node the user picks becomes the chosen one; the next unlock is on the chosen node', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.elapse(const Duration(seconds: 1));
      expect(h.failover?.inUse, _c);
      unawaited(h.container.read(deskProvider.notifier).useNode(_d));
      h.elapse(Duration.zero);
      expect(h.failover, isNull);
      expect(h.wallet.saved, _d);
      h.dispose();

      final h2 = _Harness(async);
      h2.elapse(const Duration(seconds: 1));
      expect(h2.failover?.inUse, _c);
      unawaited(h2.container.read(deskProvider.notifier).lock());
      h2.elapse(Duration.zero);
      expect(h2.failover, isNull);
      expect(h2.wallet.saved, _a);
      h2.dispose();
    });
  });

  group('the user\'s own node', () {
    test('down: a public node stands in; back after two good answers', () {
      fakeAsync((async) {
        final h = _Harness(async, inUse: _home, dead: {_home}, node: MockDeskNode());
        h.elapse(const Duration(seconds: 1));
        expect(h.wallet.sessionNodes, [_a]);
        expect(h.failover, const NodeFailover(chosen: _home, inUse: _a));
        h.wallet.dead.remove(_home);
        unawaited(h.watch.askOwn());
        h.elapse(Duration.zero);
        expect(h.wallet.sessionNodes, [_a], reason: 'one good answer is not yet back');
        unawaited(h.watch.askOwn());
        h.elapse(Duration.zero);
        expect(h.wallet.sessionNodes, [_a, _home]);
        expect(h.container.read(deskProvider).status?.node.url, _home);
        expect(h.failover, isNull);
        h.dispose();
      });
    });

    test('syncing, and the user wants a public node meanwhile: one stands in until it is synced', () {
      fakeAsync((async) {
        final node = MockDeskNode();
        node.infos[nodeHost(_home)] = mockOwnNodeInfo(_home, head: NodeHead.syncing);
        final h = _Harness(async, inUse: _home, dead: const {}, node: node, settingsPrefs: const SettingsPrefs(ownFallback: {_home: true}));
        unawaited(h.watch.askOwn());
        h.elapse(const Duration(seconds: 2));
        expect(h.wallet.sessionNodes, [_a]);
        final moved = h.failover!;
        expect(moved.chosen, _home);
        expect(moved.syncing, isTrue);
        node.infos[nodeHost(_home)] = mockOwnNodeInfo(_home);
        for (var i = 0; i < 2; i++) {
          unawaited(h.watch.askOwn());
          h.elapse(Duration.zero);
        }
        expect(h.wallet.sessionNodes, [_a, _home]);
        expect(h.failover, isNull);
        h.dispose();
      });
    });

    test('syncing, the user did not say so: the wallet waits on it', () {
      fakeAsync((async) {
        final node = MockDeskNode();
        node.infos[nodeHost(_home)] = mockOwnNodeInfo(_home, head: NodeHead.syncing);
        final h = _Harness(async, inUse: _home, dead: const {}, node: node);
        unawaited(h.watch.askOwn());
        h.elapse(const Duration(minutes: 1));
        expect(h.wallet.sessionNodes, isEmpty);
        h.dispose();
      });
    });
  });
}
