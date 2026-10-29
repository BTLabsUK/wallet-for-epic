// SPDX-License-Identifier: Apache-2.0
// The fallback decisions as the wallet acts on them: to the local node at once when it is
// synced, to the public node only after 60 s of not synced without a break, nothing before the
// user answered, nothing after a no. On a fake clock and a fake local node state stream.

import 'dart:async';

import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Timers that fire only when [elapse] passes their time.
class _Clock {
  Duration now = Duration.zero;
  final List<_Timer> _timers = [];

  Timer timer(Duration d, void Function() f) {
    final t = _Timer(now + d, f);
    _timers.add(t);
    return t;
  }

  void elapse(Duration d) {
    now += d;
    for (final t in _timers.where((t) => t.isActive && t.due <= now).toList()) {
      t.fire();
    }
  }
}

class _Timer implements Timer {
  _Timer(this.due, this._f);

  final Duration due;
  final void Function() _f;
  bool _active = true;

  void fire() {
    _active = false;
    _f();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

final _public = defaultFallbackNodeUrl;
const _accepted = FallbackChoice(FallbackConsent.accepted);
const _declined = FallbackChoice(FallbackConsent.declined);

final _syncing = mockLocalNode(LocalNodePhase.syncing, overall: 0.4);
final _synced = mockLocalNode(LocalNodePhase.synced);

class _Controller implements LocalNodeController {
  _Controller(this._state);

  LocalNodeState _state;
  final _out = StreamController<LocalNodeState>.broadcast();

  void show(LocalNodeState s) {
    _state = s;
    _out.add(s);
  }

  @override
  LocalNodeState get state => _state;

  @override
  Stream<LocalNodeState> get states => _out.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A store whose first reads wait for [release], as libsecret answering slowly.
class _SlowStore extends MemorySecretStore {
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<String?> read(String key) async {
    final before = values[key];
    await _gate.future;
    return before;
  }
}

void main() {
  group('FallbackSwitch', () {
    late _Clock clock;
    late List<FallbackDecision> moves;
    late FallbackSwitch sw;

    setUp(() {
      clock = _Clock();
      moves = [];
      sw = FallbackSwitch(moves.add, timer: clock.timer);
    });

    void see(LocalNodeState s, FallbackChoice c) => sw.update(decideFallback(s, c));

    test('unasked: nothing moves while the user is asked', () {
      see(_syncing, const FallbackChoice.unasked());
      clock.elapse(const Duration(minutes: 5));
      expect(moves, isEmpty);
    });

    test('accepted and syncing: the public node after 60 s, not before, once', () {
      see(_syncing, _accepted);
      clock.elapse(const Duration(seconds: 59));
      expect(moves, isEmpty);
      see(mockLocalNode(LocalNodePhase.syncing, overall: 0.5), _accepted);
      clock.elapse(const Duration(seconds: 1));
      expect(moves.map((d) => (d.action, d.nodeUrl)), [(FallbackAction.usePublic, _public)]);
      see(mockLocalNode(LocalNodePhase.syncing, overall: 0.6), _accepted);
      clock.elapse(const Duration(minutes: 2));
      expect(moves, hasLength(1));
    });

    test('synced: the local node at once', () {
      see(_syncing, _accepted);
      clock.elapse(const Duration(seconds: 60));
      see(_synced, _accepted);
      expect(moves.map((d) => d.action), [FallbackAction.usePublic, FallbackAction.useLocal]);
    });

    test('declined: stays on the local node', () {
      see(_syncing, _declined);
      clock.elapse(const Duration(minutes: 5));
      see(mockLocalNode(LocalNodePhase.stopped), _declined);
      expect(moves.map((d) => d.action), [FallbackAction.useLocal]);
    });

    test('a synced node that drops out for less than 60 s does not move', () {
      see(_synced, _accepted);
      expect(moves, hasLength(1));
      for (var i = 0; i < 5; i++) {
        see(_syncing, _accepted);
        clock.elapse(const Duration(seconds: 50));
        see(_synced, _accepted);
        clock.elapse(const Duration(seconds: 50));
      }
      expect(moves.map((d) => d.action), [FallbackAction.useLocal]);
      // Out for good: after 60 s without a break.
      see(_syncing, _accepted);
      clock.elapse(const Duration(seconds: 30));
      see(mockLocalNode(LocalNodePhase.stopped), _accepted);
      clock.elapse(const Duration(seconds: 30));
      expect(moves.map((d) => d.action), [FallbackAction.useLocal, FallbackAction.usePublic]);
    });

    test('another public node while on one moves at once', () {
      see(_syncing, _accepted);
      clock.elapse(const Duration(seconds: 60));
      see(_syncing, const FallbackChoice(FallbackConsent.accepted, nodeUrl: 'https://other.example'));
      expect(moves.map((d) => d.nodeUrl), [_public, 'https://other.example']);
    });

    test('dispose stops a wait', () {
      see(_syncing, _accepted);
      sw.dispose();
      clock.elapse(const Duration(minutes: 2));
      expect(moves, isEmpty);
    });
  });

  group('LepicDeskNode', () {
    late _Controller controller;
    late MemorySecretStore secrets;
    late List<FallbackDecision> moves;
    late ProviderContainer container;
    late LepicDeskNode node;
    late _Clock clock;

    Future<void> setUpWith(FallbackChoice choice, LocalNodeState first) async {
      controller = _Controller(first);
      secrets = MemorySecretStore();
      await NodeSettings(secrets, Chain.mainnet).setFallbackChoice(choice);
      moves = [];
      clock = _Clock();
      final p = Provider<LepicDeskNode>(
        (ref) => LepicDeskNode(ref, chain: Chain.mainnet, onDecision: (d) async => moves.add(d), fallbackTimer: clock.timer),
      );
      container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(secrets),
          localNodeControllerProvider(Chain.mainnet).overrideWith((ref) async => controller),
        ],
      );
      node = container.read(p);
    }

    tearDown(() => container.dispose());

    Future<void> pass(Duration d) async {
      await pumpEventQueue();
      clock.elapse(d);
      await pumpEventQueue();
    }

    test('a syncing local node: the public node after 60 s; synced: the local node at once', () async {
      await setUpWith(_accepted, _syncing);
      final sub = node.states().listen((_) {});
      await pass(const Duration(seconds: 30));
      controller.show(mockLocalNode(LocalNodePhase.syncing, overall: 0.7));
      await pass(const Duration(seconds: 29));
      expect(moves, isEmpty);
      await pass(const Duration(seconds: 1));
      expect(moves.map((d) => d.action), [FallbackAction.usePublic]);
      controller.show(_synced);
      await pass(Duration.zero);
      expect(moves.map((d) => d.action), [FallbackAction.usePublic, FallbackAction.useLocal]);
      // A short drop out of synced moves nothing.
      controller.show(_syncing);
      await pass(const Duration(seconds: 40));
      controller.show(_synced);
      await pass(const Duration(seconds: 40));
      expect(moves, hasLength(2));
      // The async* stream's cancel waits on the generator; not what is tested here.
      unawaited(sub.cancel());
    });

    test('the node while syncing follows the state: none once the local node is synced', () async {
      await setUpWith(_accepted, _synced);
      expect(await node.nodeWhileSyncing(), isNull);
      controller.show(_syncing);
      expect(await node.nodeWhileSyncing(), _public);
      await NodeSettings(secrets, Chain.mainnet).setFallbackChoice(_declined);
      expect(await node.nodeWhileSyncing(), isNull);
    });
  });
  group('the wizard\'s answer while the stored one is still being read (linux-03)', () {
    test('Save\'s answer stays: a read that started before it does not bring back the old one', () async {
      final store = _SlowStore();
      final controller = _Controller(_syncing);
      final container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          localNodeControllerProvider(Chain.mainnet).overrideWith((ref) async => controller),
          deskNodeProvider.overrideWith((ref) => LepicDeskNode(ref, chain: Chain.mainnet)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(deskFallbackProvider, (_, _) {});
      addTearDown(sub.close);
      // The wizard's Save is the first to ask: the provider's read of the store is still out.
      final saved = container.read(deskFallbackProvider.notifier).set(_accepted);
      await pumpEventQueue();
      store.release();
      await saved;
      await pumpEventQueue();
      expect(container.read(deskFallbackProvider).value?.consent, FallbackConsent.accepted);
      expect((await container.read(deskNodeProvider).fallbackChoice()).consent, FallbackConsent.accepted);
      expect(await NodeSettings(store, Chain.mainnet).fallbackChoice(), _accepted);
    });
  });
}
