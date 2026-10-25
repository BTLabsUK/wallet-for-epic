// Report gwuouzfy (26.10.16 r2): a network whose DNS filter sends epicbox.epiccash.com to a
// proxy that refuses every TLS handshake ("received fatal alert: CloseNotify"). The status
// flipped between Connecting and Not connected for ever, as LEPIC's retries and the self-heal
// restarts alternated. Now the listener reads as blocked after two refused handshakes in a
// row, the status shows it at once and keeps it, and nothing restarts the listener but a
// network change; LEPIC keeps retrying and a connection clears it.

import 'dart:async';

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Word for word from the report's log.
const _refused = 'could not connect to the relay: received fatal alert: CloseNotify';

class _Harness {
  _Harness() {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [networkChangesProvider.overrideWithValue(network.stream)],
    );
  }

  final session = FakeWalletSession();
  final network = StreamController<bool>.broadcast();
  late final ProviderContainer container;

  ListenerState get state => container.read(listenerProvider);
  EpicboxState? get shown => container.read(walletStatusProvider).epicbox;

  void open(FakeAsync async) {
    unawaited(container.read(sessionProvider.notifier).open(session));
    async.flushMicrotasks();
    container.listen(listenerProvider, (_, _) {}, fireImmediately: true);
    container.listen(walletStatusProvider, (_, _) {}, fireImmediately: true);
    async.flushMicrotasks();
  }

  void event(FakeAsync async, ListenerEventKind kind, {String? reason}) {
    session.listenerEvents.add(ListenerEvent(kind: kind, message: reason ?? 'x', reason: reason));
    async.flushMicrotasks();
  }

  void refused(FakeAsync async) => event(async, ListenerEventKind.disconnected, reason: _refused);

  void dispose() {
    container.dispose();
    unawaited(network.close());
  }
}

void main() {
  test('two refused handshakes in a row: blocked, shown at once', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.refused(async);
      expect(h.state.blocked, isFalse, reason: 'one alone may be a blip');
      h.refused(async);
      expect(h.state.blocked, isTrue);
      expect(h.state.connected, isFalse);
      async.elapse(const Duration(milliseconds: 1)); // Riverpod rebuilds on a zero timer.
      expect(h.shown, EpicboxState.blocked, reason: 'no settle wait: two attempts proved it');
      h.dispose();
    });
  });

  test('blocked stays: no self-heal restart, no restart on a resume, no flip to connecting', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.refused(async);
      h.refused(async);
      final seen = <EpicboxState?>{};
      h.container.listen(walletStatusProvider, (_, s) => seen.add(s.epicbox));
      // LEPIC's retries go on, refused each time, over many minutes.
      for (var i = 0; i < 20; i++) {
        async.elapse(const Duration(seconds: 30));
        h.refused(async);
      }
      unawaited(h.container.read(listenerProvider.notifier).wake('resume'));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0, reason: 'nothing restarted it');
      expect(h.session.listenerStarts, 1);
      expect(seen, {EpicboxState.blocked}, reason: 'never connecting or not connected');

      // Another network may not block it: that restarts it once.
      h.network.add(false);
      async.flushMicrotasks();
      h.network.add(true);
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1);
      h.dispose();
    });
  });

  test('a connection clears it; the block must be seen twice again', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.refused(async);
      h.refused(async);
      h.event(async, ListenerEventKind.connected);
      expect(h.state.blocked, isFalse);
      expect(h.state.connected, isTrue);
      h.refused(async);
      expect(h.state.blocked, isFalse);
      h.dispose();
    });
  });

  test('ordinary outages never read as blocked', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      for (final reason in [
        'could not connect to the relay: Connection refused (os error 111)',
        'timed out awaiting the connection',
        'websocket error: HTTP error: 502 Bad Gateway',
        _refused,
        'could not connect to the relay: Connection reset by peer (os error 104)',
        _refused,
      ]) {
        h.event(async, ListenerEventKind.disconnected, reason: reason);
        expect(h.state.blocked, isFalse, reason: reason);
      }
      async.elapse(statusSettle);
      expect(h.shown, EpicboxState.offline);
      h.dispose();
    });
  });
}
