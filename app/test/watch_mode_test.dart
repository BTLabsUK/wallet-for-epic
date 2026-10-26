// Watch mode (watch_mode.dart): which payments make the app ask the node for its tip every few
// seconds, for how long, and how the asks back off while the node does not answer.
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/ui/tx_details_screen.dart' show txExplanation;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/watch_mode.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 25, 12);
int _ago(Duration d) => _now.subtract(d).millisecondsSinceEpoch ~/ 1000;
final _tip = BigInt.from(1000);

bool _watched(TxEntry tx) => watchesChain(tx, now: _now, tip: _tip, minConfirmations: 3);

void main() {
  test('each step a block can move is watched', () {
    final recent = _ago(const Duration(minutes: 1));
    for (final (what, tx) in [
      (
        'we sent, waiting for the answer',
        fakeTx(kind: TxKind.sent, status: TxStatus.awaitingRecipient, createdAtUnix: recent),
      ),
      (
        'we answered',
        fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: recent),
      ),
      (
        'we posted',
        fakeTx(
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: _ago(const Duration(hours: 1)),
          finalizedAtUnix: recent,
          kernelExcess: '08ab',
        ),
      ),
      (
        'the sender reports posted',
        fakeTx(
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: _ago(const Duration(hours: 1)),
          senderReportedPostedAtUnix: recent,
        ),
      ),
      (
        'in a block, 1 of 3',
        fakeTx(
          kind: TxKind.received,
          status: TxStatus.confirmed,
          createdAtUnix: _ago(const Duration(minutes: 5)),
          blockHeight: _tip,
        ),
      ),
      (
        'in a block, 2 of 3',
        fakeTx(
          kind: TxKind.sent,
          status: TxStatus.confirmed,
          createdAtUnix: _ago(const Duration(minutes: 5)),
          blockHeight: _tip - BigInt.one,
        ),
      ),
    ]) {
      expect(_watched(tx), isTrue, reason: what);
    }
  });

  test('done, cancelled, imported, or waiting past the window is not', () {
    for (final (what, tx) in [
      (
        'confirmed at 3 of 3',
        fakeTx(
          kind: TxKind.sent,
          status: TxStatus.confirmed,
          createdAtUnix: _ago(const Duration(minutes: 5)),
          blockHeight: _tip - BigInt.two,
        ),
      ),
      (
        'cancelled',
        fakeTx(kind: TxKind.sentCancelled, status: TxStatus.cancelled, createdAtUnix: _ago(Duration.zero)),
      ),
      (
        'imported',
        fakeTx(
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          source: TxSource.imported,
          createdAtUnix: _ago(Duration.zero),
        ),
      ),
      (
        'answered 10 minutes ago, never posted',
        fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(watchWindow)),
      ),
      (
        'finalized 10 minutes ago, its post failed',
        fakeTx(
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: _ago(const Duration(minutes: 12)),
          finalizedAtUnix: _ago(watchWindow),
          repostable: true,
        ),
      ),
    ]) {
      expect(_watched(tx), isFalse, reason: what);
    }
  });

  test('fast for 2 minutes after the last step, slow to 5, then the normal pace', () {
    WatchPace at(Duration ago) => watchPace(
      fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(ago)),
      now: _now,
      tip: _tip,
      minConfirmations: 3,
    );
    expect(at(const Duration(seconds: 10)), WatchPace.fast);
    expect(at(const Duration(minutes: 1, seconds: 59)), WatchPace.fast);
    expect(at(const Duration(minutes: 2)), WatchPace.slow);
    expect(at(const Duration(minutes: 4, seconds: 59)), WatchPace.slow);
    expect(at(const Duration(minutes: 5)), WatchPace.none);
    // A block-counting payment keeps the list fast.
    expect(
      listPace(
        [
          fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(const Duration(minutes: 3))),
          fakeTx(kind: TxKind.sent, status: TxStatus.confirmed, createdAtUnix: _ago(const Duration(minutes: 3)), blockHeight: _tip),
        ],
        now: _now,
        tip: _tip,
        minConfirmations: 3,
      ),
      WatchPace.fast,
    );
  });

  test('past the window, the note tells no new block from blocks without it', () {
    final posted = fakeTx(
      key: 'posted',
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _ago(const Duration(minutes: 6)),
      finalizedAtUnix: _ago(const Duration(minutes: 6)),
      kernelExcess: '08ab',
    );
    final refused = fakeTx(
      key: 'refused',
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _ago(const Duration(minutes: 6)),
      repostable: true,
    );
    final fresh = fakeTx(key: 'fresh', kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(const Duration(minutes: 1)));
    final watch = BlockWatch()..saw([posted, refused, fresh], _tip);
    expect(watch.waitOf(posted, now: _now, tip: _tip), BlockWait.noNewBlock);
    expect(watch.waitOf(posted, now: _now, tip: _tip + BigInt.one), BlockWait.notInBlock);
    expect(watch.waitOf(fresh, now: _now, tip: _tip + BigInt.one), BlockWait.none, reason: 'inside its window');
    expect(watch.waitOf(refused, now: _now, tip: _tip + BigInt.one), BlockWait.none, reason: 'Not posted has its own state');
    // In a block: no note, and it is forgotten.
    final mined = fakeTx(key: 'posted', kind: TxKind.sent, status: TxStatus.confirmed, createdAtUnix: posted.createdAtUnix, blockHeight: _tip + BigInt.one);
    watch.saw([mined], _tip + BigInt.one);
    expect(watch.waitOf(mined, now: _now, tip: _tip + BigInt.one), BlockWait.none);
  });

  test('the pacer asks at the watch pace, backs off while the node fails, and never past normal', () {
    final pace = TipPacer(normal: const Duration(seconds: 15), step: const Duration(seconds: 1));
    int ticksTo(WatchPace p) {
      var n = 1;
      while (!pace.tick(p)) {
        n++;
      }
      return n;
    }

    expect(ticksTo(WatchPace.none), 15);
    expect(ticksTo(WatchPace.fast), 4);
    expect(ticksTo(WatchPace.slow), 10);
    pace.failed();
    expect(ticksTo(WatchPace.fast), 8);
    pace.failed();
    expect(ticksTo(WatchPace.fast), 15, reason: '16 s capped at the normal 15 s');
    expect(pace.answered(), isTrue, reason: 'back after failing');
    expect(pace.answered(), isFalse);
    expect(ticksTo(WatchPace.fast), 4);
  });

  test('the details say it in one calm line, on both sides', () {
    final l = englishStrings;
    final answered = fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(const Duration(minutes: 6)));
    final posted = fakeTx(
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _ago(const Duration(minutes: 6)),
      kernelExcess: '08ab',
      amountDebited: BigInt.from(300000000),
    );
    for (final tx in [answered, posted]) {
      expect(txExplanation(l, tx, _tip, now: _now, wait: BlockWait.noNewBlock), 'Waiting for the next block to be mined.');
      expect(
        txExplanation(l, tx, _tip, now: _now, wait: BlockWait.notInBlock),
        'Not in a block yet. It may still be on its way to the network.',
      );
      expect(txExplanation(l, tx, _tip, now: _now), isNot(contains('block')), reason: 'no note inside the window');
    }
  });

  test('a send just finalized that reads not posted is read again until its post shows', () {
    TxEntry at(Duration ago, {bool repostable = true}) => fakeTx(
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _ago(const Duration(minutes: 1)),
      finalizedAtUnix: _ago(ago),
      repostable: repostable,
    );
    expect(postingNow(at(const Duration(seconds: 2)), _now, null), isTrue);
    expect(postingNow(at(postingFor), _now, null), isFalse, reason: 'a refused post keeps Not posted');
    expect(postingNow(at(const Duration(seconds: 2), repostable: false), _now, null), isFalse);
  });

  test('a receive still waiting for its sender keeps saying so; one the sender reports posted gets the note', () {
    final answered = fakeTx(key: 'a', kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(const Duration(minutes: 20)));
    final reported = fakeTx(
      key: 'r',
      kind: TxKind.received,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _ago(const Duration(minutes: 20)),
      senderReportedPostedAtUnix: _ago(const Duration(minutes: 6)),
      transport: 'epicbox',
    );
    final watch = BlockWatch()..saw([answered, reported], _tip, now: _now);
    expect(watch.waitOf(answered, now: _now, tip: _tip + BigInt.one), BlockWait.none);
    expect(watch.waitOf(reported, now: _now, tip: _tip + BigInt.one), BlockWait.notInBlock);
  });

  test('a step dated in the future, or a block count stuck for half an hour, is not watched', () {
    expect(
      _watched(fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(const Duration(hours: 2)), senderReportedPostedAtUnix: _ago(const Duration(minutes: -30)))),
      isFalse,
    );
    expect(
      _watched(fakeTx(kind: TxKind.sent, status: TxStatus.confirmed, createdAtUnix: _ago(watchInBlockFor), blockHeight: _tip)),
      isFalse,
    );
  });

  test('the step keeps every pace exact', () {
    expect(TipPacer(normal: const Duration(seconds: 15)).step, const Duration(seconds: 1));
    expect(TipPacer(normal: const Duration(seconds: 30)).step, const Duration(seconds: 2));
  });

  test('a change the list shows (finalized, posted) restarts the watch, as LEPIC keeps no finalize time', () {
    final waiting = fakeTx(key: 's', kind: TxKind.sent, status: TxStatus.awaitingRecipient, createdAtUnix: _ago(const Duration(minutes: 20)));
    final finalized = fakeTx(key: 's', kind: TxKind.sent, status: TxStatus.awaitingConfirmation, createdAtUnix: waiting.createdAtUnix, kernelExcess: '08ab', repostable: true);
    final watch = BlockWatch()..saw([waiting], _tip, now: _now.subtract(const Duration(seconds: 10)));
    WatchPace pace(TxEntry t) => watchPace(t, now: _now, tip: _tip, minConfirmations: 3, steps: watch);
    expect(pace(waiting), WatchPace.none, reason: 'first seen is no step');
    watch.saw([finalized], _tip, now: _now.subtract(const Duration(seconds: 3)));
    expect(pace(finalized), WatchPace.fast);
    expect(postingNow(finalized, _now, watch), isTrue);
    expect(postingNow(finalized, _now.add(postingFor), watch), isFalse);
  });
}
