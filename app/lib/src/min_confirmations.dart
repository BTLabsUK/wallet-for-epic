// SPDX-License-Identifier: Apache-2.0
/// The phone's Settings › Advanced › Confirmations: the open wallet's minimum confirmations
/// (LEPIC keeps it per wallet, 1–30, default 6). A change applies at once; taps in quick
/// succession are stored as one, then the balance is read again so Spendable and Confirming
/// re-split without the node.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart'
    show defaultMinimumConfirmations, maxMinimumConfirmations, minMinimumConfirmations;
import 'providers.dart' show homeProvider, sessionProvider;
import 'wallet_service.dart' show WalletSession;

/// The open wallet's minimum confirmations as the row shows it: the stored count, or the
/// count a pending change asks for. The default while locked.
final minimumConfirmationsSettingProvider =
    AsyncNotifierProvider<MinimumConfirmationsSetting, int>(
      MinimumConfirmationsSetting.new,
    );

class MinimumConfirmationsSetting extends AsyncNotifier<int> {
  /// How long taps on the stepper gather before the count is stored.
  static Duration debounce = const Duration(milliseconds: 400);

  Timer? _timer;
  Completer<void>? _pending;
  int? _stored;
  WalletSession? _session;
  int? _wanted;

  @override
  Future<int> build() async {
    final session = ref.watch(sessionProvider);
    _session = session;
    ref.onDispose(() {
      final timer = _timer;
      final pending = _pending;
      final wanted = _wanted;
      _timer = null;
      _pending = null;
      timer?.cancel();
      // A change still waiting is stored anyway, on the wallet it was made for: the user
      // asked for it. The balance follows on its next read.
      if (pending == null || wanted == null) return;
      if (session == null || wanted == _stored) {
        pending.complete();
        return;
      }
      session.setMinimumConfirmations(wanted).then((_) => pending.complete(), onError: pending.completeError);
    });
    final count = session == null ? defaultMinimumConfirmations : await session.minimumConfirmations();
    _stored = count;
    return count;
  }

  /// Shows [count] at once and stores it after [debounce]. Completes once it is stored, with
  /// the core's error if it was refused; the row then shows the stored count again. Out of
  /// 1–30 throws a [RangeError].
  Future<void> set(int count) {
    RangeError.checkValueInInterval(count, minMinimumConfirmations, maxMinimumConfirmations, 'count');
    _wanted = count;
    state = AsyncData(count);
    _timer?.cancel();
    final pending = _pending ??= Completer<void>();
    _timer = Timer(debounce, () => unawaited(_commit()));
    return pending.future;
  }

  Future<void> _commit() async {
    final pending = _pending;
    _pending = null;
    final wanted = _wanted;
    if (pending == null || wanted == null) return;
    try {
      await _store(wanted);
      pending.complete();
    } catch (error, stack) {
      if (ref.mounted && _wanted == wanted) {
        _wanted = _stored;
        state = AsyncData(_stored ?? defaultMinimumConfirmations);
      }
      pending.completeError(error, stack);
    }
  }

  Future<void> _store(int count) async {
    final session = _session;
    if (session == null) throw StateError('Wallet is locked');
    if (count == _stored) return;
    await session.setMinimumConfirmations(count);
    _stored = count;
    if (!ref.mounted) return;
    try {
      await ref.read(homeProvider.notifier).resummarize();
    } catch (_) {
      // The next refresh reads the balance with the new count.
    }
  }
}
