/// The phone's one owner of Tor for the open wallet: starts it on unlock when the user's
/// "Tor receiving" switch is on, on demand for a send to an onion, restarts it after the app
/// comes back or the network returns, and resets on lock (LEPIC stops tor then).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'btlabs_onions.dart';
import 'providers.dart';
import 'tor_location.dart';
import 'wallet_service.dart';

enum PhoneTorPhase {
  /// This build or platform has no tor (iOS, or a build without it).
  unavailable,

  /// Not running: locked, or not wanted.
  off,

  /// Connecting to the Tor network, [PhoneTorState.progress] percent done.
  starting,

  /// Sends to onions work; the onion is not published yet, or could not be
  /// ([PhoneTorState.failure] `listener` or `keys`).
  connected,

  /// Sends work and other wallets can reach this one at [PhoneTorState.onion].
  ready,

  /// Tor stopped for [PhoneTorState.failure]; it is restarted by itself while wanted.
  failed,
}

class PhoneTorState {
  const PhoneTorState({
    required this.phase,
    this.progress,
    this.onion,
    this.failure,
    this.receiving = false,
  });

  final PhoneTorPhase phase;

  /// For `starting`, 0 to 100.
  final int? progress;

  /// This wallet's onion, `<56 characters>.onion`, known once unlocked, even while off.
  final String? onion;

  /// For `failed`, and for `connected` when the onion could not be published.
  final TorFailure? failure;

  /// The user's per-wallet "Tor receiving" switch.
  final bool receiving;

  /// Sends to onions work now.
  bool get canSend =>
      phase == PhoneTorPhase.connected || phase == PhoneTorPhase.ready;

  PhoneTorState copyWith({
    PhoneTorPhase? phase,
    int? Function()? progress,
    String? onion,
    TorFailure? Function()? failure,
    bool? receiving,
  }) => PhoneTorState(
    phase: phase ?? this.phase,
    progress: progress == null ? this.progress : progress(),
    onion: onion ?? this.onion,
    failure: failure == null ? this.failure : failure(),
    receiving: receiving ?? this.receiving,
  );

  @override
  int get hashCode =>
      phase.hashCode ^
      progress.hashCode ^
      onion.hashCode ^
      failure.hashCode ^
      receiving.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneTorState &&
          phase == other.phase &&
          progress == other.progress &&
          onion == other.onion &&
          failure == other.failure &&
          receiving == other.receiving;

  @override
  String toString() =>
      'PhoneTorState(${phase.name}, $progress%, ${failure?.name}, receiving: $receiving)';
}

/// Epicbox over Tor for the open wallet and the ones opened later: while on and the wallet's
/// tor runs, starts, or ended by itself, the Epicbox connection goes through tor and never
/// directly. On until [EpicboxOverTor.set]; not saved here, the app's Tor setting drives it.
final epicboxOverTorProvider = NotifierProvider<EpicboxOverTor, bool>(
  EpicboxOverTor.new,
);

class EpicboxOverTor extends Notifier<bool> {
  @override
  bool build() => true;

  /// Applies [on] to the open wallet at once, and to every wallet opened later.
  Future<void> set(bool on) async {
    state = on;
    await ref.read(sessionProvider)?.setEpicboxOverTor(on);
  }
}

/// The Epicbox connection is waiting for tor: Epicbox over Tor is on, tor is not off, and the
/// listener runs but is not connected. Show it as "Connecting via Tor", not offline: it never
/// falls back to a direct connection.
final epicboxWaitingForTorProvider = Provider<bool>((ref) {
  if (!ref.watch(epicboxOverTorProvider)) return false;
  final tor = ref.watch(phoneTorProvider).phase;
  if (tor == PhoneTorPhase.off || tor == PhoneTorPhase.unavailable) return false;
  final listener = ref.watch(listenerProvider);
  return !listener.connected && !listener.stopped;
});

/// Finds the tor binary: `findTorBundle()` (on Android the app's `libtor.so`), null on the
/// web. Tests override it.
final torBundleFinderProvider = Provider<Future<TorBundle?> Function()>(
  (ref) => kIsWeb ? () async => null : findTorBundle,
);

/// Network regained (true) and lost (false). Empty by default: `main.dart` overrides it with
/// [androidNetworkChanges], and tests leave it or give their own stream. (Under `flutter test`
/// the platform reads as Android but no plugin answers the channel, and its failure is
/// reported through [FlutterError], not thrown: the app, not the provider, wires it.)
final networkChangesProvider = Provider<Stream<bool>>(
  (ref) => const Stream<bool>.empty(),
);

/// The Android app's network events (`NetworkWatch.kt`); nothing elsewhere.
Stream<bool> androidNetworkChanges() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const Stream<bool>.empty();
  }
  return const EventChannel('epic_wallet/network')
      .receiveBroadcastStream()
      .map((e) => e == 'available')
      .handleError((Object _) {});
}

/// How long [PhoneTor] waits. Tests shorten them.
class PhoneTorTiming {
  const PhoneTorTiming({
    this.backoff = const [
      Duration(seconds: 2),
      Duration(seconds: 10),
      Duration(seconds: 30),
      Duration(seconds: 60),
    ],
    this.sendWait = const Duration(minutes: 3),
    this.networkSettle = const Duration(milliseconds: 1500),
    this.awayRenew = const Duration(seconds: 30),
  });

  /// Before each restart in a row; the last one repeats. A start that stalls is LEPIC's to
  /// end (its own deadlines, longer on a first start); it ends as failed and comes back here.
  final List<Duration> backoff;

  /// [PhoneTor.ensureForSend] gives up after this.
  final Duration sendWait;

  /// The network must stay back this long before tor is refreshed: a flap refreshes once.
  final Duration networkSettle;

  /// Away from the screen this long, the app may have lost its network meanwhile (Android 15
  /// and later cut a backgrounded app's network after about 50 s): on return tor renews its
  /// connections, as after a network change, instead of only waking.
  final Duration awayRenew;
}

final phoneTorTimingProvider = Provider<PhoneTorTiming>(
  (ref) => const PhoneTorTiming(),
);

/// Tor for the open wallet. Something always on screen while a wallet is open must watch it,
/// so it starts on unlock.
final phoneTorProvider = NotifierProvider<PhoneTor, PhoneTorState>(
  PhoneTor.new,
);

class PhoneTor extends Notifier<PhoneTorState> {
  /// Bumped on every build (unlock, lock, another wallet): work of an older one stops.
  int _generation = 0;
  WalletSession? _session;
  WalletConfig? _config;
  TorBundle? _bundle;
  StreamSubscription<TorEvent>? _tor;

  /// Started for a send; runs until lock even with receiving off.
  bool _forSends = false;
  int _sendsInFlight = 0;

  /// Receiving was turned off while a send ran: stop once the sends end.
  bool _stopAfterSends = false;
  int _restarts = 0;
  bool _foreground = true;

  /// Runs while the app is off screen; null on screen.
  Stopwatch? _away;
  Timer? _restartTimer;
  Timer? _networkTimer;

  /// A [_stop] waiting on LEPIC; a start waits for it, or its stream would end at once.
  Future<void>? _stopping;
  final List<Completer<void>> _sendWaiters = [];

  static String receivingKey(WalletConfig config) =>
      'phone.tor_receiving.${config.chain.name}.${config.walletId ?? 'legacy'}';

  /// Before [session] opens: hands it Epicbox over Tor ([epicboxOverTorProvider]) and the onion
  /// routes ([onionDirectoryProvider]) and, when tor will start for receiving, has its Epicbox
  /// connection wait for that tor (`expectTor`) instead of going directly until tor is up.
  static Future<void> prepare(Ref ref, WalletSession session) async {
    final over = ref.read(epicboxOverTorProvider);
    await session.setEpicboxOverTor(over);
    try {
      await session.setOnionRoutes(onionRoutesOf(ref.read(onionDirectoryProvider)));
    } on WalletError catch (e) {
      logWarn('tor', 'onion routes not set: ${e.kind.name}');
    }
    if (!over) return;
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final receiving = await ref.read(secretStoreProvider).read(receivingKey(config));
    if (receiving != 'true') return;
    if (await ref.read(torBundleFinderProvider)() == null) return;
    await session.expectTor();
  }

  @override
  PhoneTorState build() {
    final session = ref.watch(sessionProvider);
    final generation = ++_generation;
    _session = session;
    _config = ref.read(walletConfigProvider);
    _tor = null;
    _bundle = null;
    _forSends = false;
    _sendsInFlight = 0;
    _stopAfterSends = false;
    _restarts = 0;
    // A plain observer, not an AppLifecycleListener: on `paused` the app locks first, which
    // rebuilds this notifier and removes the observer while the binding is still dispatching
    // to its copy of the list; a disposed AppLifecycleListener asserts on that call.
    final lifecycle = _LifecycleObserver(_onLifecycle);
    WidgetsBinding.instance.addObserver(lifecycle);
    final network = ref.watch(networkChangesProvider).listen((available) {
      _networkTimer?.cancel();
      if (!available) return;
      _networkTimer = Timer(ref.read(phoneTorTimingProvider).networkSettle, () {
        if (_current(generation)) _wake('network');
      });
    });
    ref.onDispose(() {
      // LEPIC stops tor when the session is disposed (lock); only our side ends here.
      final sub = _tor;
      _tor = null;
      unawaited(sub?.cancel());
      _restartTimer?.cancel();
      _networkTimer?.cancel();
      _failWaiters('wallet locked');
      WidgetsBinding.instance.removeObserver(lifecycle);
      unawaited(network.cancel());
    });
    if (session == null) return const PhoneTorState(phase: PhoneTorPhase.off);
    unawaited(_open(session, generation));
    return const PhoneTorState(phase: PhoneTorPhase.off);
  }

  bool _current(int generation) => generation == _generation && ref.mounted;

  Future<void> _open(WalletSession session, int generation) async {
    final bundle = await ref.read(torBundleFinderProvider)();
    String? onion;
    try {
      onion = await session.onionAddress();
    } catch (e) {
      logWarn(
        'tor',
        'onion address: ${e is WalletError ? e.kind.name : e.runtimeType}',
      );
    }
    final config = _config;
    final saved = config == null
        ? null
        : await ref.read(secretStoreProvider).read(receivingKey(config));
    if (!_current(generation)) return;
    _bundle = bundle;
    final receiving = saved == 'true';
    state = PhoneTorState(
      phase: bundle == null ? PhoneTorPhase.unavailable : PhoneTorPhase.off,
      onion: onion == null ? null : onionHost(onion),
      receiving: receiving,
    );
    if (bundle != null && receiving) _start();
  }

  bool get _wanted => state.receiving || _forSends;

  bool get _running => _tor != null;

  /// Turns the user's "Tor receiving" switch for this wallet on or off, and starts or stops
  /// tor. Off waits for a Tor send that is running, then stops.
  Future<void> setReceiving(bool on) async {
    final config = _config;
    if (config != null) {
      await ref.read(secretStoreProvider).write(receivingKey(config), '$on');
    }
    if (!ref.mounted) return;
    state = state.copyWith(receiving: on);
    logInfo('tor', 'receiving ${on ? 'on' : 'off'}');
    if (_session == null || state.phase == PhoneTorPhase.unavailable) return;
    if (on) {
      _stopAfterSends = false;
      _restarts = 0;
      if (!_running) _start();
      return;
    }
    _forSends = false;
    if (_sendsInFlight > 0) {
      _stopAfterSends = true;
    } else {
      await _stop();
    }
  }

  /// Starts tor if it is not running and completes once sends to onions work. Throws a
  /// [WalletError] (`torNotRunning`) when tor fails, is unavailable, or takes too long.
  /// Tor started for a send keeps running until lock.
  Future<void> ensureForSend() async {
    if (_session == null || state.phase == PhoneTorPhase.unavailable) {
      throw const WalletError(
        kind: WalletErrorKind.torNotRunning,
        message: 'tor is not available',
      );
    }
    _forSends = true;
    if (state.canSend) return;
    final waiter = Completer<void>();
    _sendWaiters.add(waiter);
    if (!_running) {
      _restartTimer?.cancel();
      _start();
    }
    await waiter.future.timeout(
      ref.read(phoneTorTimingProvider).sendWait,
      onTimeout: () {
        _sendWaiters.remove(waiter);
        throw const WalletError(
          kind: WalletErrorKind.torNotRunning,
          message: 'tor did not connect in time',
        );
      },
    );
  }

  /// Runs [send] (a `sendTor` or `resendTor`) once tor is up ([ensureForSend]), so turning
  /// receiving off meanwhile stops tor only after it.
  Future<T> whileSending<T>(Future<T> Function() send) async {
    // A lock or another wallet resets the count: a send of an older one leaves it alone.
    final generation = _generation;
    _sendsInFlight++;
    try {
      await ensureForSend();
      return await send();
    } finally {
      if (generation == _generation) _sendsInFlight--;
      if (generation == _generation &&
          _sendsInFlight == 0 &&
          _stopAfterSends &&
          ref.mounted) {
        _stopAfterSends = false;
        if (!_wanted) await _stop();
      }
    }
  }

  /// Stops tor if it runs and starts it again now.
  Future<void> retry() async {
    final session = _session;
    if (session == null || state.phase == PhoneTorPhase.unavailable) return;
    _restartTimer?.cancel();
    _restarts = 0;
    // A restart: the Epicbox connection keeps waiting for the new tor.
    if (_running) await session.expectTor();
    await _stop(keepFailure: false, restarting: true);
    if (ref.mounted && _session != null) _start();
  }

  void _start() {
    final session = _session;
    final bundle = _bundle;
    if (session == null || bundle == null || _running) return;
    _restartTimer?.cancel();
    final generation = _generation;
    state = state.copyWith(
      phase: PhoneTorPhase.starting,
      progress: () => 0,
      failure: () => null,
    );
    final stopping = _stopping;
    if (stopping != null) {
      unawaited(
        stopping.whenComplete(() {
          if (_current(generation) && _wanted) _start();
        }),
      );
      return;
    }
    logInfo('tor', 'start');
    late final StreamSubscription<TorEvent> sub;
    sub = session
        .startTor(torBinary: bundle.binary, libDir: bundle.libDir)
        .listen(
          (e) {
            if (_tor == sub && _current(generation)) _onEvent(e);
          },
          onError: (Object e) {
            if (_tor != sub || !_current(generation)) return;
            logWarn(
              'tor',
              'ended: ${e is WalletError ? e.kind.name : e.runtimeType}',
            );
            _ended(TorFailure.stopped);
          },
          onDone: () {
            if (_tor != sub || !_current(generation)) return;
            _ended(state.failure ?? TorFailure.stopped);
          },
        );
    _tor = sub;
  }

  void _onEvent(TorEvent e) {
    switch (e.kind) {
      case TorEventKind.starting:
        if (state.phase != PhoneTorPhase.starting) break;
        final progress = e.progress ?? state.progress;
        state = state.copyWith(progress: () => progress);
      case TorEventKind.bootstrapped || TorEventKind.publishing:
        _restarts = 0;
        // A listener or keys failure stays shown: tor runs for sends only.
        state = state.copyWith(
          phase: PhoneTorPhase.connected,
          progress: () => null,
        );
        _completeWaiters();
      case TorEventKind.ready:
        _restarts = 0;
        state = state.copyWith(
          phase: PhoneTorPhase.ready,
          progress: () => null,
          failure: () => null,
          onion: e.onion == null ? null : onionHost(e.onion!),
        );
        _completeWaiters();
      case TorEventKind.failed:
        logWarn('tor', 'failed: ${e.failure?.name ?? '?'}');
        final forSends =
            e.failure == TorFailure.listener || e.failure == TorFailure.keys;
        if (forSends) {
          state = state.copyWith(
            phase: PhoneTorPhase.connected,
            progress: () => null,
            failure: () => e.failure,
          );
          _completeWaiters();
        } else {
          // `stopped` follows.
          state = state.copyWith(failure: () => e.failure);
        }
      case TorEventKind.stopped:
        _ended(state.failure ?? TorFailure.stopped);
      case TorEventKind.sending ||
          TorEventKind.received ||
          TorEventKind.refused:
        break;
    }
  }

  /// Tor ended by itself: failed, and restarted with backoff while wanted.
  void _ended(TorFailure failure) {
    final sub = _tor;
    _tor = null;
    unawaited(sub?.cancel());
    state = state.copyWith(
      phase: PhoneTorPhase.failed,
      progress: () => null,
      failure: () => failure,
    );
    _failWaiters(failure.name);
    _scheduleRestart();
  }

  /// Restarts after the next backoff step, while tor is wanted and the app is on screen.
  /// A missing binary is not retried.
  void _scheduleRestart() {
    if (!_wanted || !_foreground || _running || _session == null) return;
    if (state.failure == TorFailure.missing) return;
    if (_restartTimer?.isActive ?? false) return;
    final steps = ref.read(phoneTorTimingProvider).backoff;
    final delay = steps[_restarts.clamp(0, steps.length - 1)];
    _restarts++;
    final generation = _generation;
    logInfo('tor', 'restart in ${delay.inSeconds} s');
    _restartTimer = Timer(delay, () {
      if (_current(generation) && _wanted && !_running) _start();
    });
  }

  /// Stops tor (and its listener) and shows off. Unless [restarting], also tells LEPIC after tor
  /// ended by itself, as LEPIC keeps the Epicbox connection waiting for it until then.
  Future<void> _stop({bool keepFailure = false, bool restarting = false}) async {
    final sub = _tor;
    _tor = null;
    _restartTimer?.cancel();
    final session = _session;
    final ended = state.phase == PhoneTorPhase.failed;
    state = state.copyWith(
      phase: PhoneTorPhase.off,
      progress: () => null,
      failure: keepFailure ? null : () => null,
    );
    _failWaiters('stopped');
    if (sub == null) {
      if (ended && !restarting) {
        try {
          await session?.stopTor();
        } on WalletError catch (e) {
          logWarn('tor', 'stop: ${e.kind.name}');
        }
      }
      return;
    }
    logInfo('tor', 'stop');
    final stopping = _stopTor(session, sub);
    _stopping = stopping;
    try {
      await stopping;
    } finally {
      if (identical(_stopping, stopping)) _stopping = null;
    }
  }

  /// LEPIC's stop first: a start meanwhile waits on [_stopping], not on our cancel.
  Future<void> _stopTor(
    WalletSession? session,
    StreamSubscription<TorEvent> sub,
  ) async {
    try {
      await session?.stopTor();
    } on WalletError catch (e) {
      logWarn('tor', 'stop: ${e.kind.name}');
    }
    await sub.cancel();
  }

  void _onLifecycle(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.resumed:
        _foreground = true;
        final away = _away?.elapsed;
        _away = null;
        final renew =
            away != null && away >= ref.read(phoneTorTimingProvider).awayRenew;
        _wake('resume', renew: renew);
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _foreground = false;
        _away ??= Stopwatch()..start();
        // A restart waiting in the background would run frozen; resume starts it.
        _restartTimer?.cancel();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Back on screen, or the network returned: a tor that should run but does not is started
  /// again; one that runs is checked ([_nudge]).
  void _wake(String why, {bool renew = false}) {
    if (_session == null || _bundle == null || !_wanted) return;
    if (_running) {
      unawaited(_nudge(why, renew: renew || why == 'network'));
    } else {
      _scheduleRestart();
    }
  }

  /// Wakes a running tor after a freeze, and renews its connections after a network change
  /// or a long time away (LEPIC's `refreshTor`). A tor that no longer runs or answers ends,
  /// and is restarted.
  Future<void> _nudge(String why, {required bool renew}) async {
    final session = _session;
    final generation = _generation;
    // The tor checked: if it ended and another started meanwhile, that one is left alone.
    final sub = _tor;
    if (session == null) return;
    try {
      await session.refreshTor(networkChanged: renew);
      logInfo('tor', 'refreshed after $why${renew ? ', connections renewed' : ''}');
      return;
    } on WalletError catch (e) {
      if (e.kind != WalletErrorKind.torNotRunning) {
        logWarn('tor', 'refresh after $why: ${e.kind.name}');
        return;
      }
    } catch (e) {
      logWarn('tor', 'refresh after $why: ${e.runtimeType}');
      return;
    }
    if (!_current(generation) || sub == null || _tor != sub) return;
    // While tor still starts there is nothing to refresh, and LEPIC says so without an
    // error; torNotRunning here is a tor that ended.
    logInfo('tor', 'not running after $why');
    _ended(TorFailure.stopped);
  }

  void _completeWaiters() {
    final waiters = List.of(_sendWaiters);
    _sendWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) w.complete();
    }
  }

  void _failWaiters(String why) {
    final waiters = List.of(_sendWaiters);
    _sendWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.completeError(
          WalletError(kind: WalletErrorKind.torNotRunning, message: why),
        );
      }
    }
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onChange);

  final void Function(AppLifecycleState state) onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}
