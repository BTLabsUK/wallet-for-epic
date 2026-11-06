// SPDX-License-Identifier: Apache-2.0
// Node failover on the desktop (Settings › Advanced, on by default): after 30 s of the wallet's
// node reading down, the open wallet moves to the next working node of the list for this
// session (useNodeForSession, never useNode); the chosen node stays saved.
// A node that answers but reads behind is left the same way, for a node ahead of it.

import 'dart:async';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_failover.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = 'https://a.example';
const _b = 'https://b.example';
const _c = 'https://c.example';
const _d = 'https://d.example';
const _local = 'http://127.0.0.1:3413';

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

  @override
  Future<NodeServer> checkNode(String url) async {
    checked.add(url);
    return NodeServer(url: url, label: url, height: heights[url] ?? height, health: dead.contains(url) ? ServiceHealth.down : ServiceHealth.ok);
  }

  @override
  Future<void> useNodeForSession(String url) async {
    await super.useNodeForSession(url);
    inUse = url;
  }

  @override
  Future<void> useNode(String url) async {
    await super.useNode(url);
    picked.add(url);
    inUse = saved = url;
  }
}

class _Harness {
  /// [answered]: the node in use answered once before it went down (the 30 s rule); without, it
  /// never answered since the wallet opened and is left at once.
  _Harness(this._async, {String inUse = _a, Set<String> dead = const {_a}, AdvancedPrefs? prefs, bool tor = false, bool answered = true, this.node})
    : wallet = _Wallet(inUse: inUse, dead: answered ? const {} : dead) {
    // The failover walks the node list of the settings.
    hostSettings = hostSettings.withValues({
      'node.servers': const [_a, _b, _c, _d],
    });
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), if (node != null) deskNodeProvider.overrideWithValue(node!)]);
    container.listen(deskFailoverWatchProvider, (_, _) {}, fireImmediately: true);
    container.listen(deskFailoverProvider, (_, _) {}, fireImmediately: true);
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
    unawaited(h.container.read(deskFailoverWatchProvider.notifier).askBehind());
    h.elapse(wait);
  }
}

void main() {
  test('the toast and the cue', () {
    expect(englishStrings.deskNodeFailoverSwitched('c.example'), 'Node not answering. Switched to c.example.');
    expect(englishStrings.deskNodeFailoverInsteadOf('a.example'), 'Instead of a.example');
    expect(englishStrings.deskSetAdvNodeFailover, 'Node failover');
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

  test('moves after 30 s down, not before, to the next healthy node, for this session only', () {
    fakeAsync((async) {
      final h = _Harness(async);
      expect(h.container.read(deskProvider).status?.nodeHealth, ServiceHealth.down);
      h.elapse(const Duration(seconds: 29));
      expect(h.wallet.sessionNodes, isEmpty);
      h.elapse(const Duration(seconds: 2));
      expect(h.wallet.sessionNodes, [_c]);
      expect(h.wallet.picked, isEmpty);
      expect(h.wallet.saved, _a);
      expect(h.failover, const NodeFailover(chosen: _a, inUse: _c));
      expect(h.container.read(deskProvider).status?.node.url, _c);
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
        expect(moved.behind, isTrue, reason: 'the toast says behind, not silent');
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

    test('a late monitor reading moves nobody: stays when no node answers ahead, asks less often', () {
      fakeAsync((async) {
        final b = _Behind(async, ahead: 3);
        b.ask(wait);
        b.h.elapse(past);
        expect(b.h.wallet.sessionNodes, isEmpty);
        final asked = b.h.wallet.checked.length;
        expect(asked, greaterThan(0));
        // The second try comes at 30 s, the third only after a minute.
        b.h.elapse(const Duration(seconds: 31));
        final second = b.h.wallet.checked.length;
        expect(second, greaterThan(asked));
        b.h.elapse(const Duration(seconds: 31));
        expect(b.h.wallet.checked.length, second);
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

  test('a healthy node that does not answer is passed over; nothing working stays put', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c});
      h.elapse(const Duration(seconds: 31));
      expect(h.wallet.sessionNodes, [_d]);
      h.dispose();
      final none = _Harness(async, dead: {_a, _c, _d});
      none.elapse(const Duration(minutes: 3));
      expect(none.wallet.sessionNodes, isEmpty);
      expect(none.failover, isNull);
      none.dispose();
    });
  });

  test('nothing working: tries again after 30 s, then 1, 2 and 5 minutes; the window coming back starts over', () {
    fakeAsync((async) {
      final h = _Harness(async, dead: {_a, _c, _d});
      int tries() => h.wallet.checked.where((u) => u == _c).length;
      h.elapse(const Duration(seconds: 31));
      expect(tries(), 1);
      for (final (wait, after) in [(30, 2), (60, 3), (120, 4), (300, 5), (300, 6)]) {
        h.elapse(Duration(seconds: wait - 2));
        expect(tries(), after - 1, reason: 'before the ${wait}s wait ends');
        h.elapse(const Duration(seconds: 2));
        expect(tries(), after, reason: 'after the ${wait}s wait');
      }
      h.container.read(deskFailoverWatchProvider.notifier).resumed();
      h.elapse(const Duration(seconds: 31));
      expect(tries(), 7);
      h.dispose();
    });
  });

  test('a node that answers again in time: no move', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.elapse(const Duration(seconds: 20));
      h.wallet.dead.clear();
      h.poll();
      h.elapse(const Duration(minutes: 1));
      expect(h.wallet.sessionNodes, isEmpty);
      h.dispose();
    });
  });

  test('switch off, Offline, a node on this computer: never', () {
    fakeAsync((async) {
      for (final h in [
        _Harness(async, prefs: AdvancedPrefs.none.withNodeFailover(false)),
        _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.nodeOnly)),
        _Harness(async, inUse: _local, dead: {_local}),
      ]) {
        h.elapse(const Duration(minutes: 2));
        expect(h.wallet.sessionNodes, isEmpty);
        h.dispose();
      }
    });
  });

  test('Tor only: not while Tor is not up, over Tor once it is', () {
    fakeAsync((async) {
      final h = _Harness(async, prefs: AdvancedPrefs.none.withMode(NetworkMode.torOnly), tor: true);
      h.wallet.torStarting = true;
      h.poll();
      h.elapse(const Duration(minutes: 1));
      expect(h.wallet.sessionNodes, isEmpty);
      h.wallet.torStarting = false;
      h.poll();
      h.elapse(const Duration(seconds: 31));
      expect(h.wallet.sessionNodes, [_c]);
      h.dispose();
    });
  });

  test('a node the user picks becomes the chosen one; the next unlock is on the chosen node', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.elapse(const Duration(seconds: 31));
      expect(h.failover?.inUse, _c);
      unawaited(h.container.read(deskProvider.notifier).useNode(_d));
      h.elapse(Duration.zero);
      expect(h.failover, isNull);
      expect(h.wallet.saved, _d);
      h.dispose();

      final h2 = _Harness(async);
      h2.elapse(const Duration(seconds: 31));
      expect(h2.failover?.inUse, _c);
      unawaited(h2.container.read(deskProvider.notifier).lock());
      h2.elapse(Duration.zero);
      expect(h2.failover, isNull);
      expect(h2.wallet.saved, _a);
      h2.dispose();
    });
  });
}
