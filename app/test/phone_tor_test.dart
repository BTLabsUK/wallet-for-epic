import 'dart:async';

import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/tor_phone.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

final _config = mainnetPreset.config(
  dataDir: '/fake/wallets/mainnet',
  nodeUrl: 'https://node',
);

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => _config;
}

class _Harness {
  _Harness({TorBundle? bundle = _bundle}) {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        walletConfigProvider.overrideWith(_Config.new),
        torBundleFinderProvider.overrideWithValue(() async => bundle),
        networkChangesProvider.overrideWithValue(network.stream),
        phoneTorTimingProvider.overrideWithValue(
          const PhoneTorTiming(
            backoff: [
              Duration(milliseconds: 20),
              Duration(milliseconds: 60),
              Duration(milliseconds: 120),
            ],
            sendWait: Duration(milliseconds: 600),
            networkSettle: Duration(milliseconds: 30),
            awayRenew: Duration(milliseconds: 50),
          ),
        ),
      ],
    );
    container.listen(phoneTorProvider, (_, _) {}, fireImmediately: true);
  }

  final store = MemorySecretStore();
  final session = FakeWalletSession();
  final network = StreamController<bool>.broadcast();
  late final ProviderContainer container;

  PhoneTorState get state => container.read(phoneTorProvider);
  PhoneTor get tor => container.read(phoneTorProvider.notifier);
  String get key => PhoneTor.receivingKey(_config);

  /// Unlocks and waits for the controller to read the bundle, onion and setting.
  Future<void> unlock() async {
    container.read(sessionProvider.notifier).unlocked(session);
    await until((s) => s.onion != null || s.phase == PhoneTorPhase.unavailable);
  }

  void emit(TorEventKind kind, {int? progress, TorFailure? failure}) =>
      session.torEvents.add(
        TorEvent(
          kind: kind,
          progress: progress,
          failure: failure,
          onion: kind == TorEventKind.ready ? session.onion : null,
        ),
      );

  Future<void> until(bool Function(PhoneTorState) ok) async {
    final end = DateTime.now().add(const Duration(seconds: 3));
    while (!ok(state)) {
      if (DateTime.now().isAfter(end)) fail('never reached; now $state');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> settle([int ms = 30]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  void dispose() {
    container.dispose();
    unawaited(network.close());
  }
}

void _lifecycle(List<AppLifecycleState> states) {
  for (final s in states) {
    WidgetsBinding.instance.handleAppLifecycleStateChanged(s);
  }
}

void _background() => _lifecycle(const [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
]);

void _foreground() => _lifecycle(const [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Harness h;

  setUp(() {
    _lifecycle(const [AppLifecycleState.resumed]);
    h = _Harness();
  });
  tearDown(() => h.dispose());

  test('locked: off, no onion', () {
    expect(h.state, const PhoneTorState(phase: PhoneTorPhase.off));
  });

  test('unlock with receiving on starts tor; events move the phase', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    expect(h.session.torStarts.single.torBinary, _bundle.binary);
    expect(h.state.phase, PhoneTorPhase.starting);
    expect(h.state.receiving, isTrue);
    expect(h.state.onion, h.session.onion);
    h.emit(TorEventKind.starting, progress: 40);
    await h.until((s) => s.progress == 40);
    h.emit(TorEventKind.bootstrapped);
    await h.until((s) => s.phase == PhoneTorPhase.connected);
    expect(h.state.canSend, isTrue);
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
  });

  test(
    'unlock with receiving off does not start; the onion is known',
    () async {
      await h.unlock();
      await h.settle();
      expect(h.session.torStarts, isEmpty);
      expect(h.state.phase, PhoneTorPhase.off);
      expect(h.state.onion, h.session.onion);
      expect(h.state.receiving, isFalse);
    },
  );

  test('no bundle: unavailable, sends throw torNotRunning', () async {
    h.dispose();
    h = _Harness(bundle: null);
    h.store.values[h.key] = 'true';
    await h.unlock();
    expect(h.state.phase, PhoneTorPhase.unavailable);
    expect(h.session.torStarts, isEmpty);
    await expectLater(
      h.tor.ensureForSend(),
      throwsA(
        isA<WalletError>().having(
          (e) => e.kind,
          'kind',
          WalletErrorKind.torNotRunning,
        ),
      ),
    );
  });

  test('setReceiving persists per wallet and starts, then stops', () async {
    await h.unlock();
    await h.tor.setReceiving(true);
    expect(h.store.values[h.key], 'true');
    expect(h.key, contains('mainnet'));
    expect(h.session.torStarts, hasLength(1));
    expect(h.state.phase, PhoneTorPhase.starting);
    await h.tor.setReceiving(false);
    expect(h.store.values[h.key], 'false');
    expect(h.session.torStops, 1);
    expect(h.state.phase, PhoneTorPhase.off);
    expect(h.state.receiving, isFalse);
  });

  test('ensureForSend starts tor and completes once bootstrapped', () async {
    await h.unlock();
    var done = false;
    final send = h.tor.ensureForSend().then((_) => done = true);
    await h.settle();
    expect(h.session.torStarts, hasLength(1));
    expect(done, isFalse);
    h.emit(TorEventKind.bootstrapped);
    await send;
    expect(done, isTrue);
    // Already up: completes at once, no second start.
    await h.tor.ensureForSend();
    expect(h.session.torStarts, hasLength(1));
  });

  test('ensureForSend throws torNotRunning when tor fails', () async {
    await h.unlock();
    final send = h.tor.ensureForSend();
    await h.settle();
    h.emit(TorEventKind.failed, failure: TorFailure.network);
    h.emit(TorEventKind.stopped);
    await expectLater(
      send,
      throwsA(
        isA<WalletError>().having(
          (e) => e.kind,
          'kind',
          WalletErrorKind.torNotRunning,
        ),
      ),
    );
    expect(h.state.phase, PhoneTorPhase.failed);
    expect(h.state.failure, TorFailure.network);
  });

  test('ensureForSend throws when tor takes too long', () async {
    await h.unlock();
    await expectLater(h.tor.ensureForSend(), throwsA(isA<WalletError>()));
  });

  test('a listener failure leaves tor connected for sends', () async {
    await h.unlock();
    final send = h.tor.ensureForSend();
    await h.settle();
    h.emit(TorEventKind.bootstrapped);
    h.emit(TorEventKind.failed, failure: TorFailure.listener);
    await send;
    await h.until((s) => s.failure == TorFailure.listener);
    expect(h.state.phase, PhoneTorPhase.connected);
  });

  test('receiving off during a Tor send stops tor after the send', () async {
    await h.tor.setReceiving(true);
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    final gate = Completer<void>();
    final sending = h.tor.whileSending(() => gate.future);
    await h.settle();
    await h.tor.setReceiving(false);
    expect(h.session.torStops, 0);
    expect(h.state.phase, PhoneTorPhase.ready);
    gate.complete();
    await sending;
    expect(h.session.torStops, 1);
    expect(h.state.phase, PhoneTorPhase.off);
  });

  test('tor started for a send keeps running with receiving off', () async {
    await h.unlock();
    final send = h.tor.ensureForSend();
    await h.settle();
    h.emit(TorEventKind.bootstrapped);
    await send;
    await h.settle(60);
    expect(h.session.torStops, 0);
    expect(h.state.phase, PhoneTorPhase.connected);
  });

  test('tor that stopped is restarted with growing backoff', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    final starts = <DateTime>[DateTime.now()];
    for (var i = 1; i <= 3; i++) {
      h.emit(TorEventKind.failed, failure: TorFailure.network);
      h.emit(TorEventKind.stopped);
      await h.until((s) => s.phase == PhoneTorPhase.failed);
      await h.until((s) => s.phase == PhoneTorPhase.starting);
      starts.add(DateTime.now());
      expect(h.session.torStarts, hasLength(i + 1));
    }
    final gaps = [
      for (var i = 1; i < starts.length; i++)
        starts[i].difference(starts[i - 1]),
    ];
    expect(gaps[0], greaterThanOrEqualTo(const Duration(milliseconds: 20)));
    expect(gaps[1], greaterThanOrEqualTo(const Duration(milliseconds: 60)));
    expect(gaps[2], greaterThanOrEqualTo(const Duration(milliseconds: 120)));
    // Connected again: the next failure waits the first step again.
    h.emit(TorEventKind.bootstrapped);
    await h.until((s) => s.phase == PhoneTorPhase.connected);
    final before = DateTime.now();
    h.emit(TorEventKind.stopped);
    await h.until((s) => s.phase == PhoneTorPhase.starting);
    expect(
      DateTime.now().difference(before),
      lessThan(const Duration(milliseconds: 100)),
    );
  });

  test('no restart while in the background; resume restarts', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    _background();
    h.emit(TorEventKind.stopped);
    await h.until((s) => s.phase == PhoneTorPhase.failed);
    await h.settle(80);
    expect(h.session.torStarts, hasLength(1));
    _foreground();
    await h.until((s) => s.phase == PhoneTorPhase.starting);
    expect(h.session.torStarts, hasLength(2));
  });

  test(
    'resume: refreshTor says tor is not running, so it is restarted',
    () async {
      h.store.values[h.key] = 'true';
      await h.unlock();
      h.emit(TorEventKind.ready);
      await h.until((s) => s.phase == PhoneTorPhase.ready);
      _background();
      // Tor died while frozen and said nothing.
      h.session.torStatusValue = TorStatus.off;
      _foreground();
      await h.until((s) => s.phase == PhoneTorPhase.starting);
      expect(h.session.torStarts, hasLength(2));
    },
  );

  test('resume with tor running and fine leaves it alone', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    h.session.torStatusValue = TorStatus(
      kind: TorStatusKind.ready,
      onion: h.session.onion,
    );
    _background();
    _foreground();
    await h.settle(60);
    expect(h.session.torStarts, hasLength(1));
    expect(h.state.phase, PhoneTorPhase.ready);
    expect(h.session.torRefreshes, [false]);
  });

  test('back after a long time away renews the tor connections', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    h.session.torStatusValue = TorStatus(
      kind: TorStatusKind.ready,
      onion: h.session.onion,
    );
    _background();
    await h.settle(80);
    _foreground();
    await h.settle(60);
    expect(h.session.torRefreshes, [true]);
    expect(h.session.torStarts, hasLength(1));
  });

  test('network regained while tor runs refreshes its connections', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    h.session.torStatusValue = TorStatus(
      kind: TorStatusKind.ready,
      onion: h.session.onion,
    );
    h.network.add(true);
    await h.settle(100);
    expect(h.session.torRefreshes, [true]);
    expect(h.session.torStarts, hasLength(1));
    expect(h.state.phase, PhoneTorPhase.ready);
  });

  test('network regained restarts a failed tor', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    _background();
    h.emit(TorEventKind.failed, failure: TorFailure.network);
    h.emit(TorEventKind.stopped);
    await h.until((s) => s.phase == PhoneTorPhase.failed);
    _lifecycle(const [AppLifecycleState.hidden, AppLifecycleState.inactive]);
    // Not resumed yet; the network event alone does not run while in background.
    h.network.add(true);
    await h.settle(100);
    expect(h.session.torStarts, hasLength(1));
    _lifecycle(const [AppLifecycleState.resumed]);
    await h.until((s) => s.phase == PhoneTorPhase.starting);
    h.emit(TorEventKind.failed, failure: TorFailure.network);
    h.emit(TorEventKind.stopped);
    await h.until((s) => s.phase == PhoneTorPhase.failed);
    h.network.add(true);
    await h.until((s) => s.phase == PhoneTorPhase.starting);
    expect(h.session.torStarts, hasLength(3));
  });

  test(
    'a slow start is left to LEPIC; when it gives up, tor is restarted',
    () async {
      h.store.values[h.key] = 'true';
      await h.unlock();
      h.emit(TorEventKind.starting, progress: 10);
      await h.until((s) => s.progress == 10);
      // No progress for a while: the app does not stop it (LEPIC's deadlines decide).
      await h.settle(250);
      expect(h.session.torStops, 0);
      expect(h.session.torStarts, hasLength(1));
      expect(h.state.phase, PhoneTorPhase.starting);
      // LEPIC's deadline passed: failed (network) and stopped, then the backoff restart.
      h.emit(TorEventKind.failed, failure: TorFailure.network);
      h.emit(TorEventKind.stopped);
      await h.until((s) => s.phase == PhoneTorPhase.failed);
      await h.until((s) => s.phase == PhoneTorPhase.starting);
      expect(h.session.torStarts, hasLength(2));
    },
  );

  test('a start while tor is still stopping waits for the stop', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    final gate = h.session.torStopGate = Completer<void>();
    final stopping = h.tor.setReceiving(false);
    await h.until((s) => s.phase == PhoneTorPhase.off);
    final send = h.tor.ensureForSend();
    await h.settle();
    expect(h.session.torStarts, hasLength(1));
    expect(h.state.phase, PhoneTorPhase.starting);
    gate.complete();
    await stopping;
    await h.until((_) => h.session.torStarts.length == 2);
    // The old tor's `stopped` did not end the new start.
    expect(h.state.phase, PhoneTorPhase.starting);
    h.emit(TorEventKind.bootstrapped);
    await send;
    expect(h.state.phase, PhoneTorPhase.connected);
  });

  test('a refresh that answers late leaves a newer tor alone', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    final gate = h.session.torRefreshGate = Completer<void>();
    _background();
    _foreground();
    await h.settle();
    expect(h.session.torRefreshes, [false]);
    // The tor ends while the refresh waits, and is restarted.
    h.emit(TorEventKind.stopped);
    await h.until((_) => h.session.torStarts.length == 2);
    h.session.torStatusValue = TorStatus.off;
    gate.complete();
    await h.settle(100);
    expect(h.session.torStarts, hasLength(2));
    expect(h.state.phase, PhoneTorPhase.starting);
  });

  test('a send from before a lock does not upset the count after it', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    final old = Completer<void>();
    final oldSend = h.tor.whileSending(() => old.future);
    await h.settle();
    h.container.read(sessionProvider.notifier).lock();
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    old.complete();
    await oldSend;
    final gate = Completer<void>();
    final sending = h.tor.whileSending(() => gate.future);
    await h.settle();
    final stops = h.session.torStops;
    await h.tor.setReceiving(false);
    // A send runs: tor stops only after it.
    expect(h.session.torStops, stops);
    gate.complete();
    await sending;
    expect(h.session.torStops, stops + 1);
    expect(h.state.phase, PhoneTorPhase.off);
  });

  test('a network flap refreshes tor once', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.ready);
    await h.until((s) => s.phase == PhoneTorPhase.ready);
    h.session.torStatusValue = TorStatus(
      kind: TorStatusKind.ready,
      onion: h.session.onion,
    );
    h.network
      ..add(true)
      ..add(false)
      ..add(true);
    await h.settle(10);
    expect(h.session.torRefreshes, isEmpty);
    await h.settle(100);
    expect(h.session.torRefreshes, [true]);
  });

  test('retry stops and starts again', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    h.emit(TorEventKind.failed, failure: TorFailure.clock);
    h.emit(TorEventKind.stopped);
    await h.until((s) => s.phase == PhoneTorPhase.failed);
    await h.tor.retry();
    expect(h.state.phase, PhoneTorPhase.starting);
    expect(h.state.failure, isNull);
  });

  test('lock resets the state; a pending send fails', () async {
    h.store.values[h.key] = 'true';
    await h.unlock();
    final send = h.tor.ensureForSend().then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );
    h.container.read(sessionProvider.notifier).lock();
    expect(h.state, const PhoneTorState(phase: PhoneTorPhase.off));
    expect(await send, isA<WalletError>());
    // Events of the old tor change nothing.
    h.emit(TorEventKind.ready);
    await h.settle();
    expect(h.state.phase, PhoneTorPhase.off);
    // The setting stays for the next unlock.
    await h.unlock();
    expect(h.state.receiving, isTrue);
    expect(h.session.torStarts, hasLength(2));
  });

  test('the phone Tor in the one switch\'s words', () {
    expect(
      {
        for (final phase in PhoneTorPhase.values)
          phase: phoneTorState(PhoneTorState(phase: phase)),
      },
      {
        PhoneTorPhase.unavailable: TorState.off,
        PhoneTorPhase.off: TorState.off,
        PhoneTorPhase.starting: TorState.starting,
        PhoneTorPhase.connected: TorState.on,
        PhoneTorPhase.ready: TorState.on,
        PhoneTorPhase.failed: TorState.failed,
      },
    );
  });
}
