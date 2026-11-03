// SPDX-License-Identifier: Apache-2.0
// Node failover on the desktop (Settings › Advanced, on by default): after 30 s of the wallet's
// node reading down, the open wallet moves to the next working node of the list for this
// session (useNodeForSession, never useNode); the chosen node stays saved.

import 'dart:async';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_failover.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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

  @override
  Future<ServiceStatus> status() async => ServiceStatus(
    node: NodeServer(url: inUse, label: inUse),
    nodeHealth: dead.contains(inUse) ? ServiceHealth.down : ServiceHealth.ok,
    nodeHeight: 2914414,
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
    return NodeServer(url: url, label: url, health: dead.contains(url) ? ServiceHealth.down : ServiceHealth.ok);
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
  _Harness(this._async, {String inUse = _a, Set<String> dead = const {_a}, AdvancedPrefs? prefs, bool tor = false, bool answered = true})
    : wallet = _Wallet(inUse: inUse, dead: answered ? const {} : dead) {
    // The failover walks the node list of the settings.
    hostSettings = hostSettings.withValues({
      'node.servers': const [_a, _b, _c, _d],
    });
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
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
