// The Epicbox status follows the listener's socket without crying wolf: a drop that LEPIC
// mends within [listenerOfflineGrace] never reads Offline, a longer one does; and a listener
// that is down is restarted at once when the app comes back to the foreground or the network
// returns, instead of waiting out LEPIC's reconnect backoff (up to 60 s, on a clock that stops
// while the phone sleeps).

import 'dart:async';

import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/status.dart';
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

  EpicboxState? get epicbox => state.stopped
      ? null
      : state.connected
      ? EpicboxState.online
      : state.lost
      ? EpicboxState.offline
      : EpicboxState.connecting;

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
  test('the grace covers LEPIC\'s first reconnect attempts and stays under a glance', () {
    // LEPIC waits 0.5–1 s, 1–2 s, 2–4 s before its first three retries: at most 7 s, plus a
    // handshake on a mobile network.
    expect(listenerOfflineGrace, greaterThanOrEqualTo(const Duration(seconds: 10)));
    expect(listenerOfflineGrace, lessThanOrEqualTo(const Duration(seconds: 15)));
  });

  test('a drop mended within the grace never reads Offline', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      expect(h.epicbox, EpicboxState.online);

      h.event(async, ListenerEventKind.disconnected);
      expect(h.epicbox, EpicboxState.connecting, reason: 'a blip, not offline');
      async.elapse(listenerOfflineGrace - const Duration(seconds: 1));
      expect(h.epicbox, EpicboxState.connecting);
      h.event(async, ListenerEventKind.connected);
      expect(h.epicbox, EpicboxState.online);

      // The grace was cancelled by the reconnect: it does not fire later.
      async.elapse(listenerOfflineGrace * 2);
      expect(h.epicbox, EpicboxState.online);
      h.dispose();
    });
  });

  test('a drop that outlasts the grace reads Offline; repeated failures do not restart it', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      h.event(async, ListenerEventKind.disconnected);
      async.elapse(const Duration(seconds: 6));
      // Another failed attempt counts from the first drop, not from itself.
      h.event(async, ListenerEventKind.disconnected);
      async.elapse(listenerOfflineGrace - const Duration(seconds: 6));
      expect(h.epicbox, EpicboxState.offline);
      expect(h.state.status, contains('Reconnecting'));
      h.dispose();
    });
  });

  test('a first connection that fails is Connecting for the grace, then Offline', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      expect(h.epicbox, EpicboxState.connecting);
      h.event(async, ListenerEventKind.disconnected);
      expect(h.epicbox, EpicboxState.connecting);
      async.elapse(listenerOfflineGrace);
      expect(h.epicbox, EpicboxState.offline);
      h.dispose();
    });
  });

  test('a stream error and a stopped listener still show at once', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.stopped);
      expect(h.epicbox, isNull);
      h.dispose();
    });
  });

  test('back in the foreground, a listener that is down is restarted at once', () {
    fakeAsync((async) {
      final h = _Harness();
      h.open(async);
      h.event(async, ListenerEventKind.connected);
      h.event(async, ListenerEventKind.disconnected);
      async.elapse(listenerOfflineGrace);
      expect(h.epicbox, EpicboxState.offline);
      expect(h.session.listenerStarts, 1);

      unawaited(h.container.read(listenerProvider.notifier).wake('resume'));
      async.flushMicrotasks();
      expect(h.session.listenerStops, 1);
      expect(h.epicbox, EpicboxState.connecting);
      h.event(async, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2, reason: 'a fresh listener, with no backoff');
      h.event(async, ListenerEventKind.connected);
      expect(h.epicbox, EpicboxState.online);
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

  test('the network returning restarts a listener that dropped, within the grace too', () {
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
