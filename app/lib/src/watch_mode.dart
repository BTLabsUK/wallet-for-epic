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

import 'models.dart';

/// How often the tip is asked in the first part of watch mode.
const Duration watchFastEvery = Duration(seconds: 4);

/// How long after a payment's last step the tip is asked every [watchFastEvery].
const Duration watchFastFor = Duration(minutes: 2);

/// How often the tip is asked after [watchFastFor], until [watchWindow].
const Duration watchSlowEvery = Duration(seconds: 10);

/// How long a payment that waits for a block (or for the other side) is watched, from its last
/// step: created, finalized, or reported posted by the sender. After it, a note says why it is
/// still waiting.
const Duration watchWindow = Duration(minutes: 5);

/// How often the tip is asked in watch mode at its fastest; the pacing step.
const Duration watchTipEvery = watchFastEvery;

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

/// Seconds from the last step of [tx] that this wallet knows of to [now]. A step dated after
/// [now] (a clock moved back, or the sender's clock ahead in its report) is not counted.
int _sinceLastStep(TxEntry tx, DateTime now) {
  final nowUnix = now.millisecondsSinceEpoch ~/ 1000;
  var at = tx.createdAtUnix > nowUnix ? 0 : tx.createdAtUnix;
  for (final step in [tx.finalizedAtUnix, tx.senderReportedPostedAtUnix]) {
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
}) {
  if (tx.source != TxSource.wallet || tx.status == TxStatus.cancelled) return WatchPace.none;
  final since = _sinceLastStep(tx, now);
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
}) => watchPace(tx, now: now, tip: tip, minConfirmations: minConfirmations) != WatchPace.none;

/// The closest watch over [txs].
WatchPace listPace(
  Iterable<TxEntry> txs, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
}) {
  var pace = WatchPace.none;
  for (final t in txs) {
    final p = watchPace(t, now: now, tip: tip, minConfirmations: minConfirmations);
    if (p.index > pace.index) pace = p;
    if (pace == WatchPace.fast) break;
  }
  return pace;
}

/// How long after finalizing a send that reads not posted is read again at each tip ask: LEPIC
/// records the finalize before its post, so a list read meanwhile says "not on the network"
/// for a payment that is being posted.
const Duration postingFor = Duration(seconds: 30);

/// Whether [tx] is a send finalized under [postingFor] before [now] that still reads not
/// posted: its post may be under way, and the list is read again rather than at the next block.
bool postingNow(TxEntry tx, DateTime now) {
  final finalized = tx.finalizedAtUnix;
  if (!tx.repostable || finalized == null) return false;
  final since = now.millisecondsSinceEpoch ~/ 1000 - finalized;
  return since >= 0 && since < postingFor.inSeconds;
}

/// Whether any of [txs] is watched ([watchesChain]).
bool anyWatched(
  Iterable<TxEntry> txs, {
  required DateTime now,
  required BigInt tip,
  required int minConfirmations,
}) => listPace(txs, now: now, tip: tip, minConfirmations: minConfirmations) != WatchPace.none;

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
    ((tx.kind == TxKind.sent && tx.finalizedAtUnix != null) || senderReportsPosted(tx, now: now));

/// The tip each waiting payment was first seen at, for one open wallet, to tell "no block came"
/// from "blocks came without it" once [watchWindow] has passed. In memory: a payment first seen
/// after a restart counts from then.
class BlockWatch {
  final _tipAt = <String, BigInt>{};

  /// Notes the tip for each of [txs] waiting for a block, and forgets the rest. Call it with
  /// each list read and the tip it was read at.
  void saw(Iterable<TxEntry> txs, BigInt tip, {DateTime? now}) {
    if (tip <= BigInt.zero) return;
    final at = now ?? DateTime.now();
    final waiting = {for (final t in txs) if (_waitsForBlock(t, at)) t.key};
    _tipAt.removeWhere((k, _) => !waiting.contains(k));
    for (final k in waiting) {
      _tipAt.putIfAbsent(k, () => tip);
    }
  }

  /// Why [tx] is still not in a block at [now] with the node at [tip], once its window passed.
  BlockWait waitOf(TxEntry tx, {required DateTime now, required BigInt tip}) {
    if (!_waitsForBlock(tx, now)) return BlockWait.none;
    if (_sinceLastStep(tx, now) < watchWindow.inSeconds) return BlockWait.none;
    final at = _tipAt[tx.key];
    if (at == null || tip <= BigInt.zero) return BlockWait.none;
    return tip > at ? BlockWait.notInBlock : BlockWait.noNewBlock;
  }
}

/// Paces the tip asks of one open wallet. Its owner calls [tick] every [step] and asks the
/// node when it says so, then reports [answered] or [failed]. It counts ticks rather than
/// reading the clock, so it keeps time under a test's fake clock too.
class TipPacer {
  TipPacer({
    required this.normal,
    this.watch = watchFastEvery,
    this.watchSlow = watchSlowEvery,
    Duration? step,
  }) : step = step ?? _common([normal, watch, watchSlow]);

  /// The longest step every pace is a whole number of: the paces keep their exact length.
  static Duration _common(List<Duration> paces) {
    int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
    final ms = paces.map((d) => d.inMilliseconds).where((m) => m > 0).fold(0, gcd);
    return Duration(milliseconds: ms > 0 ? ms : 1000);
  }

  /// The pace outside watch mode.
  final Duration normal;

  /// The pace in watch mode, at its fastest.
  final Duration watch;

  /// The pace in its slower part.
  final Duration watchSlow;

  /// How often [tick] is called.
  final Duration step;

  Duration _since = Duration.zero;
  int _failures = 0;

  /// Asks that failed in a row.
  int get failures => _failures;

  /// The wait before the next ask: [normal] outside watch mode; in it [watch] or [watchSlow],
  /// doubled for each failed ask in a row, never past [normal].
  Duration every(WatchPace pace) {
    if (pace == WatchPace.none) return normal;
    final base = pace == WatchPace.fast ? watch : watchSlow;
    final backedOff = base * (1 << (_failures > 4 ? 4 : _failures));
    return backedOff < normal ? backedOff : normal;
  }

  /// One [step] passed: true when an ask is due.
  bool tick(WatchPace pace) {
    _since += step;
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
