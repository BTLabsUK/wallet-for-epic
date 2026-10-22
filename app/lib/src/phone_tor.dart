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
    this.stall = const Duration(seconds: 45),
    this.sendWait = const Duration(minutes: 3),
  });

  /// Before each restart in a row; the last one repeats.
  final List<Duration> backoff;

  /// Starting with no progress for this long is a stall: stopped and started again, once.
  final Duration stall;

  /// [PhoneTor.ensureForSend] gives up after this.
  final Duration sendWait;
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
  bool _stallRetried = false;
  bool _foreground = true;
  Timer? _restartTimer;
  Timer? _stallTimer;
  final List<Completer<void>> _sendWaiters = [];

  static String receivingKey(WalletConfig config) =>
      'phone.tor_receiving.${config.chain.name}.${config.walletId ?? 'legacy'}';

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
    _stallRetried = false;
    // A plain observer, not an AppLifecycleListener: on `paused` the app locks first, which
    // rebuilds this notifier and removes the observer while the binding is still dispatching
    // to its copy of the list; a disposed AppLifecycleListener asserts on that call.
    final lifecycle = _LifecycleObserver(_onLifecycle);
    WidgetsBinding.instance.addObserver(lifecycle);
    final network = ref.watch(networkChangesProvider).listen((available) {
      if (available) _wake('network');
    });
    ref.onDispose(() {
      // LEPIC stops tor when the session is disposed (lock); only our side ends here.
      final sub = _tor;
      _tor = null;
      unawaited(sub?.cancel());
      _restartTimer?.cancel();
      _stallTimer?.cancel();
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
    _sendsInFlight++;
    try {
      await ensureForSend();
      return await send();
    } finally {
      _sendsInFlight--;
      if (_sendsInFlight == 0 && _stopAfterSends && ref.mounted) {
        _stopAfterSends = false;
        if (!_wanted) await _stop();
      }
    }
  }

  /// Stops tor if it runs and starts it again now.
  Future<void> retry() async {
    if (_session == null || state.phase == PhoneTorPhase.unavailable) return;
    _restartTimer?.cancel();
    _restarts = 0;
    _stallRetried = false;
    await _stop(keepFailure: false);
    if (ref.mounted && _session != null) _start();
  }

  void _start() {
    final session = _session;
    final bundle = _bundle;
    if (session == null || bundle == null || _running) return;
    _restartTimer?.cancel();
    final generation = _generation;
    logInfo('tor', 'start');
    state = state.copyWith(
      phase: PhoneTorPhase.starting,
      progress: () => 0,
      failure: () => null,
    );
    _armStall();
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
        if (progress != state.progress) _armStall();
        state = state.copyWith(progress: () => progress);
      case TorEventKind.bootstrapped || TorEventKind.publishing:
        _stallTimer?.cancel();
        _restarts = 0;
        _stallRetried = false;
        // A listener or keys failure stays shown: tor runs for sends only.
        state = state.copyWith(
          phase: PhoneTorPhase.connected,
          progress: () => null,
        );
        _completeWaiters();
      case TorEventKind.ready:
        _stallTimer?.cancel();
        _restarts = 0;
        _stallRetried = false;
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
          _stallTimer?.cancel();
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
    _stallTimer?.cancel();
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

  /// A start with no progress for a while is stopped and started again, once per run of
  /// starts (the first start sometimes stalls, a second one goes through).
  void _armStall() {
    _stallTimer?.cancel();
    if (_stallRetried) return;
    final generation = _generation;
    _stallTimer = Timer(ref.read(phoneTorTimingProvider).stall, () {
      if (!_current(generation) || state.phase != PhoneTorPhase.starting) {
        return;
      }
      _stallRetried = true;
      logInfo('tor', 'start stalled at ${state.progress}%, starting again');
      unawaited(_restartNow(generation));
    });
  }

  Future<void> _restartNow(int generation) async {
    await _stop(keepFailure: false, quiet: true);
    if (_current(generation)) _start();
  }

  /// Stops tor (and its listener) and shows off.
  Future<void> _stop({bool keepFailure = false, bool quiet = false}) async {
    final sub = _tor;
    _tor = null;
    _restartTimer?.cancel();
    _stallTimer?.cancel();
    final session = _session;
    if (!quiet) {
      state = state.copyWith(
        phase: PhoneTorPhase.off,
        progress: () => null,
        failure: keepFailure ? null : () => null,
      );
      _failWaiters('stopped');
    }
    if (sub == null) return;
    logInfo('tor', 'stop');
    await sub.cancel();
    try {
      await session?.stopTor();
    } on WalletError catch (e) {
      logWarn('tor', 'stop: ${e.kind.name}');
    }
  }

  void _onLifecycle(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _wake('resume');
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _foreground = false;
        // A restart waiting in the background would run frozen; resume starts it.
        _restartTimer?.cancel();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Back on screen, or the network returned: a tor that should run but does not is started
  /// again; one that runs is checked ([_nudge]).
  void _wake(String why) {
    if (_session == null || _bundle == null || !_wanted) return;
    if (_running) {
      unawaited(_nudge(why));
    } else {
      _scheduleRestart();
    }
  }

  /// Checks a running tor after a freeze or a network change. Today it asks [torStatus] and
  /// treats `off` as ended; LEPIC's refresh call goes here once it has one.
  Future<void> _nudge(String why) async {
    final session = _session;
    final generation = _generation;
    if (session == null) return;
    TorStatus status;
    try {
      status = await session.torStatus();
    } catch (_) {
      return;
    }
    if (!_current(generation) || !_running) return;
    if (status.kind == TorStatusKind.off) {
      logInfo('tor', 'not running after $why');
      _ended(TorFailure.stopped);
    }
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
