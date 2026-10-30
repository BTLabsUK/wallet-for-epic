// SPDX-License-Identifier: Apache-2.0
/// What Cancel does to an outgoing payment, shared by phone and desktop.
///
/// A cancel is certain while nothing this wallet signed has left it: a send still waiting for
/// the recipient's answer cannot be posted without this wallet's final signature. Once the
/// other side may hold a signed copy, a cancel alone only stops waiting: an invoice this wallet
/// paid (the issuer holds its signed half and can finish it) and a send both wallets signed
/// that the node did not take (the whole transaction may be out). LEPIC's cancel unlocks the
/// coins and keeps watching for the payment ([WalletSession.cancelTransaction]); here the
/// cancel then spends those same coins back to this wallet ([WalletSession.spendOutputsToSelf]),
/// for a network fee, so the old payment can never complete. No extra step: Cancel does both.
///
/// Where the other side may finish it, the user also has a free choice ([CancelFinal.cancel]
/// with `spendBack: false`, "Stop waiting"): the coins are unlocked here and nothing is spent;
/// if the other side still finishes the payment, LEPIC's watch shows it paid. Nothing is owed
/// then, so nothing is retried.
///
/// A spend back that fails is tried again with each later list read while the wallet stays
/// open. Nothing is stored for it: after a restart a cancelled payment whose coins were not
/// moved reads "may still complete" ([cancelFinal]), and any later spend of those coins makes
/// it final as well.
library;

import 'dart:math' as math;

import 'log.dart';
import 'smart_outputs.dart' show SmartOutputsRule;
import 'wallet_service.dart';

/// LEPIC's base fee per unit of fee weight (0.001 EPIC). Only for choosing [spendBackOutputs];
/// the fee paid is the one LEPIC computes.
final BigInt _baseFee = BigInt.from(100000);

/// The fee LEPIC takes for a spend back of [inputs] coins into [outputs]: fee weight
/// `max(4 × outputs + 1 − inputs, 1)` times the base fee. Each output past the first adds
/// 0.004 EPIC.
BigInt spendBackFee(int inputs, int outputs) => BigInt.from(math.max(4 * outputs + 1 - inputs, 1)) * _baseFee;

/// The outputs a spend back of coins worth [values] makes: one per coin, so the wallet keeps
/// its number of spendable coins (the owner, 2026-10-31), at most 10 (LEPIC's limit); fewer, down
/// to 1, while an equal split of what is left after the fee would leave an output under
/// [minChange] (SmartOutputs' smallest change, 1 EPIC).
int spendBackOutputs(List<BigInt> values, {int minChange = SmartOutputsRule.standardMinChange}) {
  final total = values.fold(BigInt.zero, (a, b) => a + b);
  var n = math.min(math.max(values.length, 1), 10);
  while (n > 1 && (total - spendBackFee(values.length, n)) ~/ BigInt.from(n) < BigInt.from(minChange)) {
    n--;
  }
  return n;
}

/// Whether cancelling [tx] also spends its coins back to this wallet: an outgoing payment the
/// other side may complete without this wallet. An invoice this wallet paid, or a send both
/// wallets signed that is not confirmed.
bool cancelSpendsBack(TxEntry tx) =>
    tx.kind == TxKind.sent &&
    (tx.flow == TxFlow.invoice || tx.status == TxStatus.awaitingConfirmation);

/// A cancelled payment of the kind [cancelSpendsBack] covers: an invoice this wallet paid, or
/// a send it finalized. Whether its cancel is final is [cancelFinal].
bool cancelledMayComplete(TxEntry tx) =>
    tx.kind == TxKind.sentCancelled && (tx.flow == TxFlow.invoice || tx.finalizedAtUnix != null);

/// For a cancelled outgoing payment: false while any coin it had locked is unspent with its
/// link to it ([WalletOutput.txId]) still in place, so the other side could still complete it.
/// True once every such coin was spent again, by the spend back or by a later payment, and for
/// a payment that locked none.
bool cancelFinal(TxEntry tx, Iterable<WalletOutput> outputs) {
  final id = tx.id;
  if (id == null) return true;
  return !outputs.any((o) => o.txId == id && o.status == WalletOutputStatus.unspent);
}

/// How a cancel ended.
enum CancelResult {
  /// Cancelled; nothing this wallet signed had left it, so nothing else was needed.
  cancelled,

  /// Cancelled, and its coins spent back to this wallet: it can no longer complete.
  spentBack,

  /// Cancelled, but spending its coins back failed: tried again with the next list read.
  spendBackPending,

  /// Stopped waiting, as the user chose: cancelled with no spend back, so the other side may
  /// still finish it (it then shows as paid).
  stoppedWaiting,

  /// The spend back was refused because the payment itself already went through: its coins
  /// are spent by it, and the watch shows it paid.
  alreadyPaid,
}

/// The cancels of one open wallet, with the spends back still owed. One per open wallet.
class CancelFinal {
  /// Payments cancelled while the wallet is open whose spend back failed, with the coins it is
  /// to spend.
  final _owed = <int, List<String>>{};
  bool _retrying = false;

  /// Cancels [tx] ([WalletSession.cancelTransaction], whose errors it passes on: nothing changed
  /// then), and when [cancelSpendsBack] says so, spends the coins it had locked back to this
  /// wallet; with [spendBack] false (the free "Stop waiting") it only cancels.
  Future<CancelResult> cancel(WalletSession session, TxEntry tx, {bool spendBack = true}) async {
    final id = tx.id;
    if (id == null) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'no local id');
    }
    if (!cancelSpendsBack(tx)) {
      await session.cancelTransaction(txId: id);
      return CancelResult.cancelled;
    }
    if (!spendBack) {
      await session.cancelTransaction(txId: id);
      return CancelResult.stoppedWaiting;
    }
    // The coins it locks, read first: once cancelled they are this wallet's again, and the
    // spend back spends exactly these.
    var coins = const <WalletOutput>[];
    try {
      coins = _lockedBy(id, await session.outputs());
    } on WalletError catch (e) {
      logWarn('cancel', 'locked coins not read: ${e.kind.name}');
    }
    await session.cancelTransaction(txId: id);
    return _afterCancel(session, id, coins);
  }

  /// Releases the stuck send [tx] ([WalletSession.releaseStuckSend], whose errors it passes on:
  /// nothing changed then) and spends the coins it had locked back to this wallet, as [cancel]
  /// does: the network refused the send, but a copy of it could still reach it. With [spendBack]
  /// false it only releases ([CancelResult.stoppedWaiting]).
  Future<CancelResult> release(WalletSession session, TxEntry tx, {bool spendBack = true}) async {
    if (!spendBack) {
      await session.releaseStuckSend(key: tx.key);
      return CancelResult.stoppedWaiting;
    }
    final id = tx.id;
    var coins = const <WalletOutput>[];
    if (id != null) {
      try {
        coins = _lockedBy(id, await session.outputs());
      } on WalletError catch (e) {
        logWarn('cancel', 'locked coins not read: ${e.kind.name}');
      }
    }
    await session.releaseStuckSend(key: tx.key);
    if (id == null) return CancelResult.cancelled;
    return _afterCancel(session, id, coins);
  }

  /// After [id] was cancelled or released: spends back [coins], or when none were read before,
  /// the coins the cancel freed (they keep their link to it).
  Future<CancelResult> _afterCancel(WalletSession session, int id, List<WalletOutput> coins) async {
    if (coins.isEmpty) {
      try {
        coins = _freedBy(id, await session.outputs());
      } on WalletError catch (e) {
        logWarn('cancel', 'freed coins not read: ${e.kind.name}');
      }
    }
    if (coins.isEmpty) return CancelResult.cancelled;
    return _spendBack(session, id, coins);
  }

  /// True while a spend back is owed.
  bool get owed => _owed.isNotEmpty;

  /// Tries each owed spend back once. True when one went through, so the caller can read the
  /// list again. It stops for good, per payment, once its coins are no longer free: spent by the
  /// payment itself after all (the watch then shows it paid), by the spend back, or by another
  /// payment. A spend back that can never work (the fee takes the coins' whole value) is not
  /// owed either.
  Future<bool> retry(WalletSession session) async {
    if (_owed.isEmpty || _retrying) return false;
    _retrying = true;
    try {
      final outputs = await session.outputs();
      var spent = false;
      for (final MapEntry(key: id, value: coins) in _owed.entries.toList()) {
        final free = _freedBy(id, outputs).where((o) => coins.contains(o.commitment)).toList();
        if (free.isEmpty) {
          _owed.remove(id);
          continue;
        }
        if (await _spendBack(session, id, free) != CancelResult.spendBackPending) spent = true;
      }
      return spent;
    } on WalletError catch (e) {
      logWarn('cancel', 'spend back not retried: ${e.kind.name}');
      return false;
    } finally {
      _retrying = false;
    }
  }

  /// Spends [coins] to this wallet, into as many outputs as [spendBackOutputs] says. One
  /// confirmation is enough: they were spendable when the
  /// payment chose them.
  Future<CancelResult> _spendBack(WalletSession session, int id, List<WalletOutput> coins) async {
    try {
      await session.spendOutputsToSelf(
        commitments: [for (final c in coins) c.commitment],
        minimumConfirmations: BigInt.one,
        outputs: spendBackOutputs([for (final c in coins) c.value]),
      );
      _owed.remove(id);
      logInfo('cancel', 'cancelled payment made final: its coins spent back');
      return CancelResult.spentBack;
    } on WalletError catch (e) {
      switch (e.kind) {
        // The payment won the race: LEPIC ended the spend back and shows the payment paid.
        case WalletErrorKind.inputsSpentByOwnPayment:
          _owed.remove(id);
          logInfo('cancel', 'spend back refused: the payment went through');
          return CancelResult.alreadyPaid;
        case WalletErrorKind.notEnoughFunds:
          _owed.remove(id);
          logWarn('cancel', 'spend back not possible: the fee takes the coins');
          return CancelResult.spendBackPending;
        default:
          // notPosted: LEPIC stored it and reposts it until it is mined or its coins are spent
          // (then it ends it); its coins are locked, no longer free, so a retry finds nothing
          // left to do.
          _owed[id] = [for (final c in coins) c.commitment];
          logWarn('cancel', 'spend back failed, tried again later: ${e.kind.name}');
          return CancelResult.spendBackPending;
      }
    }
  }

  static List<WalletOutput> _lockedBy(int id, Iterable<WalletOutput> outputs) => [
    for (final o in outputs)
      if (o.txId == id && o.status == WalletOutputStatus.locked) o,
  ];

  static List<WalletOutput> _freedBy(int id, Iterable<WalletOutput> outputs) => [
    for (final o in outputs)
      if (o.txId == id && o.status == WalletOutputStatus.unspent) o,
  ];
}
