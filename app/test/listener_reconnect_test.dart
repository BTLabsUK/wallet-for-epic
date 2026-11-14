// SPDX-License-Identifier: Apache-2.0
// A listener that dropped is restarted at once when the app comes back to the foreground or
// the network returns, instead of waiting out LEPIC's reconnect backoff (up to 60 s, on a
// clock that stops while the phone sleeps). The listener's own state stays raw: a drop is
// `lost` at once, and walletStatusProvider decides when the status shows it.

import 'dart:async';

import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  void open(FakeAsync async) {
    unawaited(container.read(sessionProvider.notifier).open(session));
    async.flushMicrotasks();
    container.listen(listenerProvider, (_, _) {}, fireImmediately: true);
    async.flushMicrotasks();
  }

  void event(FakeAsync async, ListenerEventKind kind) {
    session.listenerEvents.add(ListenerEvent(kind: kind, message: 'x'));
    async.flushMicrotasks();
  }

  void dispose() {
    container.dispose();
    unawaited(network.close());
  }
}

void main() {
  test('back in the foreground, a listener that is down is restarted at once', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      h.event(async, ListenerEventKind.disconnected);
      expect(h.state.lost, isTrue, reason: 'raw: lost at once');
      expect(h.session.listenerStarts, 1);

      unawaited(h.container.read(listenerProvider.notifier).wake('resume'));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1);
      expect(h.state.lost, isFalse);
      expect(h.state.connected, isFalse);
      h.event(async, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2, reason: 'a fresh listener, with no backoff');
      h.event(async, ListenerEventKind.connected);
      expect(h.state.connected, isTrue);
      h.dispose();
    });
  });

  test('a resume with the listener connected, or still connecting at start, restarts nothing', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      unawaited(h.container.read(listenerProvider.notifier).wake('resume'));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0, reason: 'the first connection is under way');

      h.event(async, ListenerEventKind.connected);
      unawaited(h.container.read(listenerProvider.notifier).wake('resume'));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0);
      h.dispose();
    });
  });

  test('after a long absence a listener that says connected is restarted; a short one leaves it', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      expect(h.state.connected, isTrue);

      unawaited(h.container.read(listenerProvider.notifier).wake('resume', stale: false));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0, reason: 'a short absence: the socket is trusted');

      unawaited(h.container.read(listenerProvider.notifier).wake('resume', stale: true));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1, reason: 'a long absence: a fresh socket');
      h.event(async, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2);
      h.dispose();
    });
  });

  test('a long absence restarts nothing while the first connection is still under way', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      unawaited(h.container.read(listenerProvider.notifier).wake('resume', stale: true));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0);
      h.dispose();
    });
  });

  test('the network returning restarts a listener that dropped', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      // Android reports the network that is up as soon as the app watches: not a change.
      h.network.add(true);
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0);

      h.event(async, ListenerEventKind.connected);
      h.event(async, ListenerEventKind.disconnected);
      h.network.add(true);
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1);
      h.event(async, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2);
      h.dispose();
    });
  });

  test('a network handover restarts a listener that still thinks it is connected', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      // Wi-Fi to mobile data: the socket's route is gone, though LEPIC has not noticed yet.
      h.network.add(false);
      async.flushMicrotasks();
      expect(h.session.listenerStops, 0, reason: 'nothing to reconnect over yet');
      h.network.add(true);
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1);
      h.dispose();
    });
  });

  group('self-heal', () {
    test('a listener not connected for 30 s is restarted once', () {
      fakeAsync((async) {
        final h = _Harness();
        h.open(async);
        h.event(async, ListenerEventKind.connected);
        h.event(async, ListenerEventKind.disconnected);
        async.elapse(listenerHealAfter - const Duration(seconds: 1));
        expect(h.session.listenerStops, 0, reason: 'LEPIC retries on its own first');

        async.elapse(const Duration(seconds: 2));
        expect(h.session.listenerStops, 1);
        h.event(async, ListenerEventKind.stopped);
        expect(h.session.listenerStarts, 2);
        h.event(async, ListenerEventKind.connected);
        async.elapse(const Duration(minutes: 10));
        expect(h.session.listenerStops, 1, reason: 'connected again: nothing more');
        h.dispose();
      });
    });

    test('a connected listener is never restarted', () {
      fakeAsync((async) {
        final h = _Harness();
        h.open(async);
        h.event(async, ListenerEventKind.connected);
        async.elapse(const Duration(minutes: 10));
        expect(h.session.listenerStops, 0);
        expect(h.session.listenerStarts, 1);
        h.dispose();
      });
    });

    test('a first connection that fails, or a stream that ended, is retried with a '
        'growing wait', () {
      fakeAsync((async) {
        final h = _Harness();
        h.open(async);
        // Still making its first connection: LEPIC's to finish.
        async.elapse(listenerHealAfter * 2);
        expect(h.session.listenerStops, 0, reason: 'no word yet');
        // The first attempt failed.
        h.event(async, ListenerEventKind.disconnected);
        async.elapse(listenerHealAfter + const Duration(seconds: 1));
        expect(h.session.listenerStops, 1, reason: 'never connected');
        // The old listener never says stopped: the new one starts after the stop wait.
        async.elapse(listenerStopWait);
        expect(h.session.listenerStarts, 2);
        // The new listener fails too: the next try waits twice as long.
        h.event(async, ListenerEventKind.disconnected);
        async.elapse(listenerHealAfter);
        expect(h.session.listenerStops, 1);
        async.elapse(listenerHealAfter);
        expect(h.session.listenerStops, 2);
        // Never under the floor, never over the cap: at most one restart per listenerHealMax.
        for (var minute = 0; minute < 60; minute++) {
          async.elapse(listenerStopWait);
          h.event(async, ListenerEventKind.disconnected);
          async.elapse(const Duration(minutes: 1) - listenerStopWait);
        }
        final stops = h.session.listenerStops;
        expect(stops, lessThanOrEqualTo(2 + 60 ~/ listenerHealMax.inMinutes + 1));
        expect(stops, greaterThan(2));
        h.dispose();
      });
    });

    test('a listener that stopped on its own is started again', () {
      fakeAsync((async) {
        final h = _Harness();
        h.open(async);
        h.event(async, ListenerEventKind.stopped);
        expect(h.state.stopped, isTrue);
        async.elapse(listenerHealAfter + const Duration(seconds: 1));
        expect(h.session.listenerStops, 1, reason: 'a stopped listener is expected to run');
        h.dispose();
      });
    });
  });
}
