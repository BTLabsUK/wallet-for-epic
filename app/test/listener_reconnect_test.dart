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
}
