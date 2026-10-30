// SPDX-License-Identifier: Apache-2.0
/// The phone's one "restore not finished" state, driven by the core's flag.
///
/// A wallet rebuilt from its phrase (a restore, or a damaged database the core set aside) gets
/// no new output keys until a scan from block 0 has finished: receiving, sending and invoices
/// are refused meanwhile ([WalletErrorKind.restoreScanRequired]). The core keeps the flag
/// ([WalletSession.restoreScanRequired]); a scan with no start height scans from block 0 while
/// it is set, goes on from a stopped one's last page, and clears it when it finishes.
///
/// This controller reads the flag on every unlock and after every scan, and while it is set
/// and the network allows, starts that scan by itself: one at a time, and after a failure only
/// again after a wait that doubles ([restoreRetryFirst] to [restoreRetryMax]), on Try again, a
/// network mode change or the next unlock. Home shows its state (`home_screen.dart`). The
/// Restore screen runs its own scan first and holds this one off meanwhile ([hold]).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'errors.dart';
import 'l10n.dart' show englishStrings;
import 'network_gate.dart';
import 'providers.dart';
import 'settings.dart' show networkModeProvider;
import 'wallet_service.dart';

/// The wait before the first automatic try after a failed restore scan.
const Duration restoreRetryFirst = Duration(seconds: 30);

/// The longest wait between two automatic tries.
const Duration restoreRetryMax = Duration(minutes: 10);

/// Where the restore of the open wallet stands. [required] false: nothing to show.
class RestoreScanState {
  const RestoreScanState({
    this.required = false,
    this.waitingNetwork = false,
    this.error,
  });

  /// The core's flag: the scan from block 0 has not finished.
  final bool required;

  /// Offline mode with a node that is not local: the scan waits until the mode changes.
  final bool waitingNetwork;

  /// Why the last try failed, for `describeError`; the next try waits or is the user's.
  final Object? error;
}

final restoreScanProvider =
    NotifierProvider<RestoreScanNotifier, RestoreScanState>(
      RestoreScanNotifier.new,
    );

/// Something always alive must watch it (`app.dart`), so it follows every unlock.
class RestoreScanNotifier extends Notifier<RestoreScanState> {
  /// Screens that run the restore's own scan ([hold]).
  int _holds = 0;

  /// Failed tries in a row since the last success or unlock; sets the next wait.
  int _failures = 0;

  Timer? _retry;

  /// A flag read is under way: a second one waits for it instead of starting a second scan.
  Future<void>? _checking;

  /// The running scan is the one started here, with no start height.
  bool _own = false;

  @override
  RestoreScanState build() {
    ref.onDispose(() => _retry?.cancel());
    ref.listen(sessionProvider, (previous, session) {
      if (identical(previous, session)) return;
      _retry?.cancel();
      _retry = null;
      _failures = 0;
      state = const RestoreScanState();
      if (session != null) unawaited(check());
    });
    // Every scan's end: a restore scan that finished from a start height leaves the flag set,
    // and this one then finishes from block 0; a failed one waits.
    ref.listen(scanProvider, (before, after) {
      if (before?.running != true || after.running) return;
      final own = _own;
      _own = false;
      if (after.error != null) {
        _failed(after.error!);
      } else {
        unawaited(check(afterOwn: own && !after.stopped));
      }
    });
    // Back from Offline: the waiting scan starts.
    ref.listen(networkModeProvider, (before, after) {
      if (before != after) unawaited(check(retry: true));
    });
    final open = ref.read(sessionProvider);
    if (open != null) scheduleMicrotask(() => unawaited(check()));
    return const RestoreScanState();
  }

  /// The running scan is the automatic one started here (Delete may stop it; a scan the user
  /// started is theirs to finish).
  bool get scanning => _own && ref.read(scanProvider).running;

  /// The Restore screen runs the restore's scan itself (with the user's start, and Stop and
  /// Try again): none starts from here until [release].
  void hold() => _holds++;

  /// The Restore screen is gone: the flag decides again.
  void release() {
    if (_holds == 0) return;
    _holds--;
    if (_holds == 0) unawaited(check());
  }

  /// Try again: starts now, whatever the last try did.
  Future<void> retry() => check(retry: true);

  /// Reads the flag and, while it is set, starts the scan unless one runs, the network mode
  /// refuses it, the Restore screen holds it, or a failed try waits ([retry] skips that wait).
  Future<void> check({bool retry = false, bool afterOwn = false}) async {
    final running = _checking;
    if (running != null) return running;
    final work = _check(retry: retry, afterOwn: afterOwn);
    _checking = work;
    try {
      await work;
    } finally {
      if (identical(_checking, work)) _checking = null;
    }
  }

  Future<void> _check({required bool retry, required bool afterOwn}) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final bool required;
    try {
      required = await session.restoreScanRequired();
    } catch (error) {
      logWarn('restore', 'flag not read: ${describeError(englishStrings, error)}');
      return;
    }
    if (!ref.mounted || !identical(ref.read(sessionProvider), session)) return;
    if (!required) {
      if (state.required) logInfo('restore', 'restore scan finished');
      _retry?.cancel();
      _retry = null;
      _failures = 0;
      state = const RestoreScanState();
      return;
    }
    // The scan from block 0 ended without an error and the flag stayed (the core skipped it,
    // or it did not count): a failure to wait out, never a scan straight after a scan.
    if (afterOwn) {
      _failed(const ScanFailed('the restore is still due after its scan'));
      return;
    }
    final blocked = NetGate.killSwitch;
    final waiting = state.error != null && !retry;
    state = RestoreScanState(
      required: true,
      waitingNetwork: blocked,
      error: waiting ? state.error : null,
    );
    if (blocked || waiting || _holds > 0 || ref.read(scanProvider).running) return;
    _retry?.cancel();
    _retry = null;
    logInfo('restore', 'restore scan due: scanning from block 0');
    _own = true;
    // No start height: the core scans from block 0 while the flag is set, and goes on from
    // the last page a stopped one stored.
    unawaited(ref.read(scanProvider.notifier).run());
    // run() marks the scan running before its first wait, or refused it.
    if (!ref.read(scanProvider).running) _own = false;
  }

  void _failed(Object error) {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    // A refusal of the mode (Offline) is not a failure to wait out: the mode change starts it.
    if (error is NetBlocked) {
      unawaited(check());
      return;
    }
    unawaited(() async {
      bool required;
      try {
        required = await session.restoreScanRequired();
      } catch (_) {
        required = state.required;
      }
      if (!ref.mounted || !identical(ref.read(sessionProvider), session) || !required) return;
      _failures++;
      final wait = Duration(
        seconds: math.min(
          restoreRetryMax.inSeconds,
          restoreRetryFirst.inSeconds * math.pow(2, _failures - 1).toInt(),
        ),
      );
      logInfo('restore', 'restore scan failed; next try in ${wait.inSeconds} s');
      state = RestoreScanState(required: true, error: error);
      _retry?.cancel();
      _retry = Timer(wait, () {
        _retry = null;
        unawaited(check(retry: true));
      });
    }());
  }
}

/// The wallet's database was rebuilt at unlock (it was damaged): its history, notes and labels
/// are not in the new one, so Home offers a history backup import until it is used or closed.
/// Gone with the session.
final historyImportOfferProvider = NotifierProvider<HistoryImportOffer, bool>(
  HistoryImportOffer.new,
);

class HistoryImportOffer extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(sessionProvider, (_, session) {
      if (session == null) state = false;
    });
    return false;
  }

  void set(bool on) => state = on;
}
