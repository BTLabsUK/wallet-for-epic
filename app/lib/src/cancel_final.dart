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
/// A spend back that fails is tried again with each later list read while the wallet stays
/// open. Nothing is stored for it: after a restart a cancelled payment whose coins were not
/// moved reads "may still complete" ([cancelFinal]), and any later spend of those coins makes
/// it final as well.
library;

import 'log.dart';
import 'wallet_service.dart';

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
  /// wallet.
  Future<CancelResult> cancel(WalletSession session, TxEntry tx) async {
    final id = tx.id;
    if (id == null) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'no local id');
    }
    if (!cancelSpendsBack(tx)) {
      await session.cancelTransaction(txId: id);
      return CancelResult.cancelled;
    }
    // The coins it locks, read first: once cancelled they are this wallet's again, and the
    // spend back spends exactly these.
    var coins = const <String>[];
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
  /// does: the network refused the send, but a copy of it could still reach it.
  Future<CancelResult> release(WalletSession session, TxEntry tx) async {
    final id = tx.id;
    var coins = const <String>[];
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
  Future<CancelResult> _afterCancel(WalletSession session, int id, List<String> coins) async {
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
        final free = _freedBy(id, outputs).where(coins.contains).toList();
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

  /// Spends [coins] to this wallet. One confirmation is enough: they were spendable when the
  /// payment chose them.
  Future<CancelResult> _spendBack(WalletSession session, int id, List<String> coins) async {
    try {
      await session.spendOutputsToSelf(commitments: coins, minimumConfirmations: BigInt.one);
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
          _owed[id] = coins;
          logWarn('cancel', 'spend back failed, tried again later: ${e.kind.name}');
          return CancelResult.spendBackPending;
      }
    }
  }

  static List<String> _lockedBy(int id, Iterable<WalletOutput> outputs) => [
    for (final o in outputs)
      if (o.txId == id && o.status == WalletOutputStatus.locked) o.commitment,
  ];

  static List<String> _freedBy(int id, Iterable<WalletOutput> outputs) => [
    for (final o in outputs)
      if (o.txId == id && o.status == WalletOutputStatus.unspent) o.commitment,
  ];
}
