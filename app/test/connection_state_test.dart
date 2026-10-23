// The settled statuses (walletStatusProvider): node offline, node syncing and Epicbox offline
// show only once they have lasted statusSettle (5 s); a shorter drop or refresh shows nothing,
// and a way back shows at once. Driven by a fake raw status on a fake clock.

import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/log.dart';
import 'package:epic_wallet/src/phone_tor.dart' show networkEvent;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _online = NodeStatus(NodeState.online);
const _offline = NodeStatus(NodeState.offline);
const _syncing = NodeStatus(NodeState.syncing, percent: 40);

class _Raw extends Notifier<WalletStatus> {
  @override
  WalletStatus build() => (node: _online, epicbox: EpicboxState.online);

  void set({NodeStatus? node, EpicboxState? epicbox}) =>
      state = (node: node ?? state.node, epicbox: epicbox ?? state.epicbox);
}

final _raw = NotifierProvider<_Raw, WalletStatus>(_Raw.new);

class _Harness {
  _Harness(FakeAsync async) : _async = async {
    container = ProviderContainer(
      overrides: [rawWalletStatusProvider.overrideWith((ref) => ref.watch(_raw))],
    );
    container.listen(walletStatusProvider, (_, _) {}, fireImmediately: true);
    // Online from the start: settled once the first 5 s pass.
    elapse(statusSettle);
  }

  final FakeAsync _async;
  late final ProviderContainer container;

  WalletStatus get shown => container.read(walletStatusProvider);

  void set({NodeStatus? node, EpicboxState? epicbox}) {
    container.read(_raw.notifier).set(node: node, epicbox: epicbox);
    // Riverpod passes the change on at its next turn.
    _async.elapse(Duration.zero);
  }

  void elapse(Duration d) {
    _async.elapse(d);
    _async.flushMicrotasks();
  }
}

const _s = Duration(seconds: 1);

void main() {
  test('the settle time is 5 s', () {
    expect(statusSettle, const Duration(seconds: 5));
  });

  group('Epicbox', () {
    test('a 3 s drop shows nothing', () {
      fakeAsync((async) {
        final h = _Harness(async);
        expect(h.shown.epicbox, EpicboxState.online);
        h.set(epicbox: EpicboxState.offline);
        expect(h.shown.epicbox, EpicboxState.online);
        h.elapse(_s * 3);
        expect(h.shown.epicbox, EpicboxState.online);
        h.set(epicbox: EpicboxState.online);
        h.elapse(_s * 10);
        expect(h.shown.epicbox, EpicboxState.online, reason: 'the reconnect cancelled it');
        h.container.dispose();
      });
    });

    test('a 10 s drop shows offline from 5 s on, and the reconnect at once', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.set(epicbox: EpicboxState.offline);
        h.elapse(_s * 4);
        expect(h.shown.epicbox, EpicboxState.online);
        h.elapse(_s);
        expect(h.shown.epicbox, EpicboxState.offline);
        h.elapse(_s * 5);
        expect(h.shown.epicbox, EpicboxState.offline);
        h.set(epicbox: EpicboxState.online);
        expect(h.shown.epicbox, EpicboxState.online);
        h.container.dispose();
      });
    });

    test('a first connection that fails is Connecting for 5 s, then offline', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [rawWalletStatusProvider.overrideWith((ref) => ref.watch(_raw))],
        );
        container.read(_raw.notifier).set(epicbox: EpicboxState.offline);
        container.listen(walletStatusProvider, (_, _) {}, fireImmediately: true);
        expect(container.read(walletStatusProvider).epicbox, EpicboxState.connecting);
        async.elapse(statusSettle);
        expect(container.read(walletStatusProvider).epicbox, EpicboxState.offline);
        container.dispose();
      });
    });

    test('a stopped listener shows at once', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.container.read(_raw.notifier).state = (node: _online, epicbox: null);
        async.elapse(Duration.zero);
        expect(h.shown.epicbox, isNull);
        h.container.dispose();
      });
    });
  });

  group('node', () {
    test('a 3 s drop shows nothing', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.set(node: _offline);
        h.elapse(_s * 3);
        expect(h.shown.node.state, NodeState.online);
        h.set(node: _online);
        h.elapse(_s * 10);
        expect(h.shown.node.state, NodeState.online);
        h.container.dispose();
      });
    });

    test('a 10 s drop shows offline from 5 s on, and the way back at once', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.set(node: _offline);
        h.elapse(_s * 4);
        expect(h.shown.node.state, NodeState.online);
        h.elapse(_s);
        expect(h.shown.node.state, NodeState.offline);
        h.elapse(_s * 5);
        h.set(node: _online);
        expect(h.shown.node.state, NodeState.online);
        h.container.dispose();
      });
    });

    test('Syncing shows only for a refresh that runs past 5 s, with live progress', () {
      fakeAsync((async) {
        final h = _Harness(async);
        // A routine refresh.
        h.set(node: _syncing);
        h.elapse(_s * 2);
        expect(h.shown.node.state, NodeState.online);
        h.set(node: _online);
        h.elapse(_s * 10);
        expect(h.shown.node.state, NodeState.online);

        // A real catch-up.
        h.set(node: _syncing);
        h.elapse(statusSettle);
        expect(h.shown.node.state, NodeState.syncing);
        expect(h.shown.node.percent, 40);
        h.set(node: const NodeStatus(NodeState.syncing, percent: 70));
        expect(h.shown.node.percent, 70);
        h.set(node: _online);
        expect(h.shown.node.state, NodeState.online);
        h.container.dispose();
      });
    });

    test('a drop of one never delays the other', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.set(node: _offline);
        h.elapse(_s * 3);
        h.set(epicbox: EpicboxState.offline);
        h.elapse(_s * 2);
        expect(h.shown.node.state, NodeState.offline);
        expect(h.shown.epicbox, EpicboxState.online);
        h.elapse(_s * 3);
        expect(h.shown.epicbox, EpicboxState.offline);
        h.container.dispose();
      });
    });
  });

  test('the log gets one line per shown flip to offline and back, with its source', () {
    final log = MemoryLogSink();
    AppLog.use(log);
    addTearDown(() => AppLog.use(MemoryLogSink()));
    // use() hands over what the previous sink held: only what follows counts.
    final from = log.lines.length;
    Iterable<String> status() => log.lines.skip(from).where((l) => l.contains('status:'));
    fakeAsync((async) {
      final h = _Harness(async);
      h.set(epicbox: EpicboxState.offline);
      h.elapse(_s * 3);
      h.set(epicbox: EpicboxState.online);
      expect(status(), isEmpty, reason: 'a blip says nothing');
      h.set(epicbox: EpicboxState.offline, node: _offline);
      h.elapse(statusSettle);
      h.set(epicbox: EpicboxState.online, node: _online);
      final lines = status().toList();
      expect(lines, hasLength(4));
      expect(lines.where((l) => l.contains('epicbox offline (source: listener socket)')), hasLength(1));
      expect(lines.where((l) => l.contains('epicbox online (source: listener socket)')), hasLength(1));
      expect(lines.where((l) => l.contains('node offline (source: node tip and refresh)')), hasLength(1));
      h.container.dispose();
    });
  });

  test('a network event is logged with its kind and read as up or down', () {
    final log = MemoryLogSink();
    AppLog.use(log);
    addTearDown(() => AppLog.use(MemoryLogSink()));
    final from = log.lines.length;
    expect(networkEvent('available:wifi'), isTrue);
    expect(networkEvent('available:cellular'), isTrue);
    expect(networkEvent('available'), isTrue);
    expect(networkEvent('lost'), isFalse);
    expect(log.lines.skip(from).map((l) => l.substring(l.indexOf('network:'))), [
      'network: connection up (wifi)',
      'network: connection up (cellular)',
      'network: connection up (unknown)',
      'network: connection lost',
    ]);
  });

  test('the raw status is still walletStatus of the listener', () {
    final s = walletStatus(
      tip: const AsyncValue<NodeTip>.loading(),
      syncing: false,
      listener: const ListenerState(lost: true),
    );
    expect(s.epicbox, EpicboxState.offline);
  });
}
