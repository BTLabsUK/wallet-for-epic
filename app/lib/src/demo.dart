// SPDX-License-Identifier: Apache-2.0
/// The web demo's side of the app (`app/README.md` "Web demo"): whether this build is the demo,
/// what the demo server answers about the visitor's demo, and the floonet faucet. Everything
/// the demo changes in the UI asks [demoModeProvider] first; with it off nothing here runs.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';

/// Set by `--dart-define=WFE_DEMO=true`, which only the web build passes.
const bool demoBuild = bool.fromEnvironment('WFE_DEMO');

/// Whether the app runs as the web demo. Tests override it.
final demoModeProvider = Provider<bool>((ref) => demoBuild);

/// `--dart-define=WFE_DEV_NETWORKS=true`: the test networks (floonet, usernet) are offered
/// in the UI. Off in every release build: the wallet runs on one network and never names it.
const bool devNetworksBuild = bool.fromEnvironment('WFE_DEV_NETWORKS');

/// Whether the UI offers and names networks: a dev build, or the web demo, which runs on
/// floonet for good. Tests override it to reach the picker.
final devNetworksProvider = Provider<bool>(
  (ref) => devNetworksBuild || ref.watch(demoModeProvider),
);

/// `--dart-define=WFE_WEB_FAKE=true`: the web preview on the fake wallet (`web/preview.dart`).
const bool _webPreviewBuild = bool.fromEnvironment('WFE_WEB_FAKE');

/// The web demo and the web previews ask for no PIN: the app starts in the wallet, a lock
/// still works, and unlocking takes one tap. Only a web build can be one; a phone or desktop
/// build always asks for the PIN, whatever it was built with.
const bool pinlessBuild = kIsWeb && (demoBuild || _webPreviewBuild);

/// Whether this build asks for no PIN ([pinlessBuild]). Tests override it.
final pinlessProvider = Provider<bool>((ref) => pinlessBuild);

/// The PIN every demo wallet is created with, filled in for the visitor (`ui/demo_pin.dart`).
/// It is no secret: a demo is guarded by the server's HttpOnly cookie, and its wallet is a
/// throwaway one on floonet. Still never shown or logged. Used only while [demoModeProvider]
/// or [pinlessProvider] is on.
const String demoPin = '135790';

/// Where the visitor's demo stands.
sealed class DemoStatus {
  const DemoStatus();
}

/// No demo yet, or one that was ended by the visitor: the welcome screen shows.
final class DemoNone extends DemoStatus {
  const DemoNone();
}

/// A demo with a wallet on the server until [expiresAt].
final class DemoActive extends DemoStatus {
  const DemoActive(this.expiresAt);

  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      other is DemoActive && other.expiresAt == expiresAt;

  @override
  int get hashCode => expiresAt.hashCode;
}

/// The demo ran out and its wallet is gone: the ended screen shows.
final class DemoEnded extends DemoStatus {
  const DemoEnded();
}

/// What the faucet said to a claim.
sealed class TestCoinsResult {
  const TestCoinsResult();
}

/// The faucet sent the coins; they arrive over epicbox.
final class TestCoinsPaid extends TestCoinsResult {
  const TestCoinsPaid();
}

/// The faucet pays one claim per visitor every so often; the next one in [seconds].
final class TestCoinsCooldown extends TestCoinsResult {
  const TestCoinsCooldown(this.seconds);

  final int seconds;
}

/// The faucet did not pay, or did not answer.
final class TestCoinsFailed extends TestCoinsResult {
  const TestCoinsFailed();
}

/// The demo server and the faucet, as the UI needs them. The demo server serves it; tests
/// and the tour use [FakeDemoApi].
abstract interface class DemoApi {
  /// The visitor's demo, as the server knows it.
  Future<DemoStatus> status();

  /// Starts a demo and returns it. The usual first run with a PIN follows.
  Future<DemoActive> start();

  /// Ends the visitor's demo at once; the server deletes its wallet.
  Future<void> end();

  /// Asks the floonet faucet to pay [address], an epicbox address of the demo wallet.
  Future<TestCoinsResult> claimTestCoins(String address);

  /// Fires when the server ended the demo (its time ran out).
  Stream<void> get ended;
}

/// The [DemoApi] in use. Until the server's exists, the fake, so a demo build without a
/// server still reaches its screens. The fake reports test coins it never pays, so no demo
/// build may be deployed before the server's replaces it.
final demoApiProvider = Provider<DemoApi>((ref) {
  final api = FakeDemoApi();
  ref.onDispose(api.dispose);
  return api;
});

/// A [DemoApi] in memory, for tests and the tour.
class FakeDemoApi implements DemoApi {
  FakeDemoApi({
    DemoStatus status = const DemoNone(),
    DateTime Function()? clock,
  }) : current = status,
       _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final StreamController<void> _ended = StreamController<void>.broadcast();

  /// What [status] answers. [start] and [end] change it.
  DemoStatus current;

  /// Answers for [claimTestCoins], in turn; paid once they run out.
  final List<TestCoinsResult> claims = [];

  /// When set, [claimTestCoins] waits for it before it answers.
  Completer<void>? claimGate;

  /// When set, [start] throws it.
  Object? startError;

  final List<String> claimedFor = [];
  int starts = 0;
  int ends = 0;

  @override
  Future<DemoStatus> status() async => current;

  @override
  Future<DemoActive> start() async {
    starts++;
    if (startError case final error?) throw error;
    final active = DemoActive(_clock().add(const Duration(hours: 24)));
    current = active;
    return active;
  }

  @override
  Future<void> end() async {
    ends++;
    current = const DemoNone();
  }

  @override
  Future<TestCoinsResult> claimTestCoins(String address) async {
    claimedFor.add(address);
    await claimGate?.future;
    return claims.isEmpty ? const TestCoinsPaid() : claims.removeAt(0);
  }

  @override
  Stream<void> get ended => _ended.stream;

  /// The server's time ran out.
  void endNow() {
    current = const DemoEnded();
    _ended.add(null);
  }

  void dispose() => _ended.close();
}

/// The visitor's demo. Loads from [DemoApi.status], turns to [DemoEnded] when the server says
/// so, and starts and ends demos. [DemoNone] without demo mode, and nothing is asked then.
final demoStatusProvider =
    AsyncNotifierProvider<DemoStatusNotifier, DemoStatus>(
      DemoStatusNotifier.new,
    );

class DemoStatusNotifier extends AsyncNotifier<DemoStatus> {
  /// The expiry whose 30-minute warning was shown, so it shows once.
  DateTime? _warnedFor;

  @override
  Future<DemoStatus> build() async {
    if (!ref.watch(demoModeProvider)) return const DemoNone();
    final api = ref.watch(demoApiProvider);
    final events = api.ended.listen((_) {
      // Only a running demo can run out; one the visitor ended is already gone.
      if (state.value is DemoActive) {
        logInfo('demo', 'ended by the server');
        state = const AsyncData(DemoEnded());
      }
    });
    ref.onDispose(events.cancel);
    return api.status();
  }

  /// Starts a demo. Throws what the server threw.
  Future<DemoActive> start() async {
    final active = await ref.read(demoApiProvider).start();
    logInfo('demo', 'started');
    state = AsyncData(active);
    return active;
  }

  /// Ends the demo: the welcome screen follows, not the ended one.
  Future<void> end() async {
    state = const AsyncData(DemoNone());
    await ref.read(demoApiProvider).end();
    logInfo('demo', 'ended by the visitor');
  }

  /// Asks the server again, as when the countdown reached zero.
  Future<void> recheck() async {
    final status = await ref.read(demoApiProvider).status();
    if (ref.mounted) state = AsyncData(status);
  }

  /// Whether the 30-minute warning for [expiresAt] is still to show; true once.
  bool takeWarning(DateTime expiresAt) {
    if (_warnedFor == expiresAt) return false;
    _warnedFor = expiresAt;
    return true;
  }
}

/// A claim of test coins, while one runs: true. Every Get test coins is disabled meanwhile.
final testCoinsProvider = NotifierProvider<TestCoinsNotifier, bool>(
  TestCoinsNotifier.new,
);

class TestCoinsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Claims for [address], or returns null when a claim runs already. A failure to reach the
  /// faucet is [TestCoinsFailed].
  Future<TestCoinsResult?> claim(String address) async {
    if (state) return null;
    state = true;
    try {
      final result = await ref.read(demoApiProvider).claimTestCoins(address);
      logInfo('demo', 'test coins: ${result.runtimeType}');
      return result;
    } catch (error) {
      logWarn('demo', 'test coins failed: $error');
      return const TestCoinsFailed();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// How the countdown words the time left: whole hours, rounded, from an hour on; whole minutes,
/// rounded up, below it. Null once nothing is left.
({int hours, int minutes})? demoTimeLeft(Duration left) {
  if (left <= Duration.zero) return null;
  if (left >= const Duration(hours: 1)) {
    return (hours: (left.inSeconds / 3600).round(), minutes: 0);
  }
  return (hours: 0, minutes: (left.inSeconds / 60).ceil());
}

/// When the countdown warns, once.
const Duration demoWarningAt = Duration(minutes: 30);
