// SPDX-License-Identifier: Apache-2.0
/// Watch mode: while a payment of the open wallet is in a state a block can move, the node is
/// boosted ([Boosts], LEPIC ADR 0058) so the tip check runs every [boostMinInterval] and the app
/// refreshes as soon as a new block is in. The sender and the receiver then both see a payment
/// move within moments of the same block. Phone and desktop share the rule and the wait notes.
///
/// A boost runs [watchWindow] from a payment's last step (created, finalized, posted), once per
/// step; a payment in a block gets a new one with each new block until it is confirmed. After
/// the window a calm note says why a payment is still waiting ([BlockWait]). Nothing here
/// changes what the payments are or when they may be cancelled.
///
/// The window is longer than the node's Dandelion embargo (180 s on Epic 4.x): an Epicbox
/// payment is posted through the stem phase, and the network may first see it only then.
library;

import 'boosts.dart';
import 'models.dart';
import 'settings_file/host_settings.dart' show appConfig;

/// How long a payment that waits for a block (or for the other side) is watched, from its last
/// step: created, finalized, or reported posted by the sender (`payments.watch_for_s`). After
/// it, a note says why it is still waiting.
Duration get watchWindow => appConfig.watchFor;

/// Why a payment past [watchWindow] is still not in a block, for the note on it.
enum BlockWait {
  /// Nothing to say: in a block, done, or still inside the window.
  none,

  /// No block came since its last step: the network is slow to mine, nothing is wrong here.
  noNewBlock,

  /// Blocks came, and it is in none of them: it may still be on its way to the network.
  notInBlock,
}

/// Seconds from the last step of [tx] that this wallet knows of to [now]: created, reported
/// posted by the sender, or a change [steps] saw on the list (finalized, posted, answered). LEPIC
/// keeps no finalize time, so the change is the app's own sighting. A step dated after [now] (a
/// clock moved back, or the sender's clock ahead in its report) is not counted.
int _sinceLastStep(TxEntry tx, DateTime now, BlockWatch? steps) {
  final nowUnix = now.millisecondsSinceEpoch ~/ 1000;
  var at = tx.createdAtUnix > nowUnix ? 0 : tx.createdAtUnix;
  for (final step in [tx.finalizedAtUnix, tx.senderReportedPostedAtUnix, steps?.stepAt(tx.key)]) {
    if (step != null && step > at && step <= nowUnix) at = step;
  }
  return nowUnix - at;
}

/// How long after finalizing a send that reads not posted is read again at each tip ask: LEPIC
/// records the finalize before its post, so a list read meanwhile says "not on the network"
/// for a payment that is being posted.
const Duration postingFor = Duration(seconds: 30);

/// Whether [tx] is a send that changed (was finalized) under [postingFor] before [now] and still
/// reads posting or not posted: its post may be under way, and the list is read again rather
/// than at the next block. A row still posting is read again until it settles.
bool postingNow(TxEntry tx, DateTime now, BlockWatch? steps) =>
    tx.posting || (tx.repostable && _sinceLastStep(tx, now, steps) < postingFor.inSeconds);

/// Whether [tx] is one the wait note can speak for at [now]: a payment that waits only for a
/// block. That is a send this wallet finalized, or a payment we answered whose sender reports it
/// posted ([senderReportsPosted]); any other receive still waits for its sender, and says so. A
/// send the node refused has its own state (not posted, posted again by itself); an unpaid
/// request waits for its payer.
bool _waitsForBlock(TxEntry tx, DateTime now) =>
    tx.source == TxSource.wallet &&
    tx.status == TxStatus.awaitingConfirmation &&
    tx.blockHeight == null &&
    !tx.repostable &&
    !tx.awaitingPayer &&
    ((tx.kind == TxKind.sent && tx.kernelExcess != null) || senderReportsPosted(tx, now: now));

/// The tip each waiting payment was first seen at, for one open wallet, to tell "no block came"
/// from "blocks came without it" once [watchWindow] has passed. In memory: a payment first seen
/// after a restart counts from then.
class BlockWatch {
  final _tipAt = <String, BigInt>{};
  final _shape = <String, Object>{};
  final _stepAt = <String, int>{};
  final _boosted = <String, (bool, int)>{};

  /// When the list last showed [key] change, in unix seconds; null when it has not since it was
  /// first seen.
  int? stepAt(String key) => _stepAt[key];

  /// Notes when each of [txs] changed and the tip for each one waiting for a block, and forgets
  /// the rest. Call it with each list read and the tip it was read at.
  void saw(Iterable<TxEntry> txs, BigInt tip, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final nowUnix = at.millisecondsSinceEpoch ~/ 1000;
    final keys = <String>{};
    for (final t in txs) {
      keys.add(t.key);
      final shape = Object.hash(t.status, t.kernelExcess != null, t.repostable, t.blockHeight, t.senderReportedPostedAtUnix);
      final before = _shape[t.key];
      if (before != null && before != shape) _stepAt[t.key] = nowUnix;
      _shape[t.key] = shape;
    }
    _shape.removeWhere((k, _) => !keys.contains(k));
    _stepAt.removeWhere((k, _) => !keys.contains(k));
    if (tip <= BigInt.zero) return;
    final waiting = {for (final t in txs) if (_waitsForBlock(t, at)) t.key};
    _tipAt.removeWhere((k, _) => !waiting.contains(k));
    for (final k in waiting) {
      _tipAt.putIfAbsent(k, () => tip);
    }
  }

  /// Boosts the node for the payments of [txs] (already [saw]) that took a step or, in a block
  /// under [minConfirmations], saw a new block since the last call: for the window left since
  /// the step, or [watchWindow] for a block. One boost, for the longest window. Nothing when
  /// [boosts] is null (the wallet is locked) or nothing is new.
  void boostNode(Boosts? boosts, Iterable<TxEntry> txs, BigInt tip, {required int minConfirmations, DateTime? now}) {
    if (boosts == null) return;
    final at = now ?? DateTime.now();
    final nowUnix = at.millisecondsSinceEpoch ~/ 1000;
    final marks = <String, (bool, int)>{};
    Duration? longest;
    for (final t in txs) {
      if (t.source != TxSource.wallet || t.status == TxStatus.cancelled) continue;
      final height = t.blockHeight;
      final (bool, int) mark;
      Duration window;
      if (height != null) {
        if (tip <= BigInt.zero || height > tip || (tip - height).toInt() + 1 >= minConfirmations) continue;
        mark = (true, tip.toInt());
        window = watchWindow;
      } else if (t.status == TxStatus.confirmed) {
        continue;
      } else {
        final since = _sinceLastStep(t, at, this);
        window = watchWindow - Duration(seconds: since);
        if (window <= Duration.zero) continue;
        mark = (false, nowUnix - since);
      }
      marks[t.key] = mark;
      if (_boosted[t.key] != mark && (longest == null || window > longest)) longest = window;
    }
    _boosted
      ..clear()
      ..addAll(marks);
    if (longest != null) boosts.boost(Poller.node, longest, boostMinInterval);
  }

  /// Why [tx] is still not in a block at [now] with the node at [tip], once its window passed.
  BlockWait waitOf(TxEntry tx, {required DateTime now, required BigInt tip}) {
    if (!_waitsForBlock(tx, now)) return BlockWait.none;
    if (_sinceLastStep(tx, now, this) < watchWindow.inSeconds) return BlockWait.none;
    final at = _tipAt[tx.key];
    if (at == null || tip <= BigInt.zero) return BlockWait.none;
    return tip > at ? BlockWait.notInBlock : BlockWait.noNewBlock;
  }
}
