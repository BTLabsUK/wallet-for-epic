// SPDX-License-Identifier: Apache-2.0
/// Watch mode: while a payment of the open wallet is in a state a block can move, the app asks
/// the node for its tip more often than its normal pace, and refreshes as soon as a new block
/// is in. The sender and the receiver then both see a payment move within moments of the same
/// block. Phone and desktop share the rule, the pacing and the wait notes.
///
/// Only the tip is asked that often (one small call to the node in use, over the connection the
/// wallet already uses); the refresh still runs once per block. Watch mode ends by itself: a
/// payment waiting for a block is watched every [watchFastEvery] for [watchFastFor] after its
/// last step, every [watchSlowEvery] until [watchWindow], then at the normal pace with a calm
/// note on the payment ([BlockWait]). A payment in a block is watched until it is done. While
/// the node does not answer, the asks back off to the normal pace. Nothing here changes what
/// the payments are or when they may be cancelled.
///
/// The window is longer than the node's Dandelion embargo (180 s on Epic 4.x): an Epicbox
/// payment is posted through the stem phase, and the network may first see it only then.
library;

import 'dart:async';

import 'models.dart';
import 'settings_file/host_settings.dart' show appConfig;

/// How often the tip is asked in the first part of watch mode (`payments.watch_fast_every_s`).
Duration get watchFastEvery => appConfig.watchFastEvery;

/// How long after a payment's last step the tip is asked every [watchFastEvery].
Duration get watchFastFor => appConfig.watchFastFor;

/// How often the tip is asked after [watchFastFor], until [watchWindow].
Duration get watchSlowEvery => appConfig.watchSlowEvery;

/// How long a payment that waits for a block (or for the other side) is watched, from its last
/// step: created, finalized, or reported posted by the sender. After it, a note says why it is
/// still waiting.
Duration get watchWindow => appConfig.watchFor;

/// How often the tip is asked in watch mode at its fastest.
Duration get watchTipEvery => watchFastEvery;

/// How closely a payment is watched now.
enum WatchPace { none, slow, fast }

/// Why a payment past [watchWindow] is still not in a block, for the note on it.
enum BlockWait {
  /// Nothing to say: in a block, done, or still inside the window.
  none,

  /// No block came since its last step: the network is slow to mine, nothing is wrong here.
  noNewBlock,

  /// Blocks came, and it is in none of them: it may still be on its way to the network.
  notInBlock,
}

/// How long a payment in a block is watched at most, from its last step: a node that answers
/// but stays at one height is then asked at the normal pace.
const Duration watchInBlockFor = Duration(minutes: 30);

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

/// How closely [tx] is watched at [now]: in a block under [minConfirmations] at [tip] fast
/// (its count moves with each block) until it is done; not in a block yet, and waiting for the
/// other side or for its kernel, fast then slow until [watchWindow] after its last step.
WatchPace watchPace(
  TxEntry tx, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
  BlockWatch? steps,
}) {
  if (tx.source != TxSource.wallet || tx.status == TxStatus.cancelled) return WatchPace.none;
  final since = _sinceLastStep(tx, now, steps);
  final height = tx.blockHeight;
  if (height != null) {
    if (tip <= BigInt.zero || height > tip || since >= watchInBlockFor.inSeconds) return WatchPace.none;
    return (tip - height).toInt() + 1 < minConfirmations ? WatchPace.fast : WatchPace.none;
  }
  if (tx.status == TxStatus.confirmed) return WatchPace.none;
  if (since < watchFastFor.inSeconds) return WatchPace.fast;
  if (since < watchWindow.inSeconds) return WatchPace.slow;
  return WatchPace.none;
}

/// Whether a block can move [tx] now ([watchPace] is not none).
bool watchesChain(
  TxEntry tx, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
  BlockWatch? steps,
}) => watchPace(tx, now: now, tip: tip, minConfirmations: minConfirmations, steps: steps) != WatchPace.none;

/// The closest watch over [txs].
WatchPace listPace(
  Iterable<TxEntry> txs, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
  BlockWatch? steps,
}) {
  var pace = WatchPace.none;
  for (final t in txs) {
    final p = watchPace(t, now: now, tip: tip, minConfirmations: minConfirmations, steps: steps);
    if (p.index > pace.index) pace = p;
    if (pace == WatchPace.fast) break;
  }
  return pace;
}

/// How long after finalizing a send that reads not posted is read again at each tip ask: LEPIC
/// records the finalize before its post, so a list read meanwhile says "not on the network"
/// for a payment that is being posted.
const Duration postingFor = Duration(seconds: 30);

/// Whether [tx] is a send that changed (was finalized) under [postingFor] before [now] and still
/// reads not posted: its post may be under way, and the list is read again rather than at the
/// next block.
bool postingNow(TxEntry tx, DateTime now, BlockWatch? steps) =>
    tx.repostable && _sinceLastStep(tx, now, steps) < postingFor.inSeconds;

/// Whether any of [txs] is watched ([watchesChain]).
bool anyWatched(
  Iterable<TxEntry> txs, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
  BlockWatch? steps,
}) => listPace(txs, now: now, tip: tip, minConfirmations: minConfirmations, steps: steps) != WatchPace.none;

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

  /// Why [tx] is still not in a block at [now] with the node at [tip], once its window passed.
  BlockWait waitOf(TxEntry tx, {required DateTime now, required BigInt tip}) {
    if (!_waitsForBlock(tx, now)) return BlockWait.none;
    if (_sinceLastStep(tx, now, this) < watchWindow.inSeconds) return BlockWait.none;
    final at = _tipAt[tx.key];
    if (at == null || tip <= BigInt.zero) return BlockWait.none;
    return tip > at ? BlockWait.notInBlock : BlockWait.noNewBlock;
  }
}

/// The soonest moment after [now] at which the watch of [txs] or a wait note on one of them can
/// change by time alone: a payment passing [watchFastFor], [watchWindow], [watchInBlockFor] or
/// [senderReportWindow] after its last step, or a step dated ahead of [now] coming due. Null when
/// none can. A list read can change them too; its owner arms the pacer again then.
Duration? nextWatchChange(Iterable<TxEntry> txs, {required DateTime now, BlockWatch? steps}) {
  final nowMs = now.millisecondsSinceEpoch;
  final nowUnix = nowMs ~/ 1000;
  int? soonest;
  void at(int unix) {
    if (unix > nowUnix && (soonest == null || unix < soonest!)) soonest = unix;
  }

  for (final t in txs) {
    if (t.source != TxSource.wallet || t.status == TxStatus.cancelled) continue;
    final last = nowUnix - _sinceLastStep(t, now, steps);
    for (final d in [watchFastFor, watchWindow, watchInBlockFor]) {
      at(last + d.inSeconds);
    }
    for (final step in [t.createdAtUnix, t.finalizedAtUnix, t.senderReportedPostedAtUnix, steps?.stepAt(t.key)]) {
      if (step != null) at(step);
    }
    final reported = t.senderReportedPostedAtUnix;
    if (reported != null) at(reported + senderReportWindow.inSeconds);
  }
  final unix = soonest;
  return unix == null ? null : Duration(milliseconds: unix * 1000 - nowMs);
}

/// Paces the tip asks of one open wallet with one timer, set to the next ask or to the next
/// moment the pace can change ([nextWatchChange]), whichever comes first. Its owner [arm]s it
/// with the pace now; when it fires, the owner asks the node if [due] says so, reports
/// [answered] or [failed], and arms it again. It counts the time it waited rather than reading
/// the clock, so it keeps time under a test's fake clock too; only an [arm] before the timer
/// fired reads the owner's clock, for the part already waited.
class TipPacer {
  TipPacer({
    required this.normal,
    Duration? watch,
    Duration? watchSlow,
  }) : watch = watch ?? watchFastEvery,
       watchSlow = watchSlow ?? watchSlowEvery;

  /// The pace outside watch mode.
  final Duration normal;

  /// The pace in watch mode, at its fastest.
  final Duration watch;

  /// The pace in its slower part.
  final Duration watchSlow;

  Duration _since = Duration.zero;
  int _failures = 0;
  Timer? _timer;
  Duration _armed = Duration.zero;
  DateTime? _armedAt;
  WatchPace? _armedPace;
  Duration? _armedEvery;

  /// Asks that failed in a row.
  int get failures => _failures;

  /// Whether the timer is set.
  bool get running => _timer != null;

  /// The wait before the next ask: [normal] outside watch mode; in it [watch] or [watchSlow],
  /// doubled for each failed ask in a row, never past [normal].
  Duration every(WatchPace pace) {
    if (pace == WatchPace.none) return normal;
    final base = pace == WatchPace.fast ? watch : watchSlow;
    final backedOff = base * (1 << (_failures > 4 ? 4 : _failures));
    return backedOff < normal ? backedOff : normal;
  }

  /// How long from the last count to the next ask at [pace], or to [change] when that is
  /// sooner.
  Duration next(WatchPace pace, {Duration? change}) {
    final left = every(pace) - _since;
    final wait = left > Duration.zero ? left : Duration.zero;
    return change != null && change < wait ? change : wait;
  }

  /// Sets the timer for [pace] at [now], with [change] from [nextWatchChange]; [fire] runs when
  /// it is up. Set already, it stays as it is unless the pace differs or [change] comes before
  /// it, or an answer or failure since changed the wait ([every]); otherwise the time already
  /// waited counts.
  void arm(WatchPace pace, {Duration? change, required DateTime now, required void Function() fire}) {
    final armedAt = _armedAt;
    if (_timer != null && armedAt != null) {
      final waited = now.difference(armedAt);
      final keep = pace == _armedPace && every(pace) == _armedEvery && (change == null || waited + change >= _armed);
      if (keep) return;
      _since += waited < Duration.zero ? Duration.zero : (waited > _armed ? _armed : waited);
      _timer!.cancel();
    }
    final wait = next(pace, change: change);
    _armed = wait;
    _armedAt = now;
    _armedPace = pace;
    _armedEvery = every(pace);
    _timer = Timer(wait, () {
      _timer = null;
      _armedAt = null;
      _since += wait;
      fire();
    });
  }

  /// Stops the timer, counting the time already waited up to [now].
  void stop({DateTime? now}) {
    final armedAt = _armedAt;
    if (_timer != null && armedAt != null && now != null) {
      final waited = now.difference(armedAt);
      _since += waited < Duration.zero ? Duration.zero : (waited > _armed ? _armed : waited);
    }
    _timer?.cancel();
    _timer = null;
    _armedAt = null;
  }

  /// The timer fired: true when an ask is due at [pace], which starts the count again.
  bool due(WatchPace pace) {
    if (_since < every(pace)) return false;
    _since = Duration.zero;
    return true;
  }

  /// The node answered. True when it had failed at least twice in a row before: it is back. One
  /// dropped ask (a flaky circuit) is not an outage.
  bool answered() {
    final back = _failures >= 2;
    _failures = 0;
    return back;
  }

  void failed() => _failures++;
}
