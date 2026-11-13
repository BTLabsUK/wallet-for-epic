// SPDX-License-Identifier: Apache-2.0
// Watch mode (watch_mode.dart): which payment steps and blocks boost the node's tip check, for
// how long, and the notes a payment waiting for its block gets.
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/ui/tx_details_screen.dart' show txExplanation;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/watch_mode.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

final _now = DateTime(2026, 10, 25, 12);
int _ago(Duration d) => _now.subtract(d).millisecondsSinceEpoch ~/ 1000;
final _tip = BigInt.from(1000);

void main() {
  group('boostNode', () {
    // Boosts of the node's tip check begun by [run], counted as the boosts' change events
    // (a boost starting or ending), with the pace left when it is done.
    (int, Duration) boosted(void Function(Boosts boosts) run) {
      late (int, Duration) out;
      fakeAsync((async) {
        final boosts = MemoryBoosts();
        var started = 0;
        boosts.changed.listen((_) => started++);
        run(boosts);
        out = (started, boosts.interval(Poller.node, const Duration(seconds: 15)));
      });
      return out;
    }

    TxEntry waiting(String key, Duration ago) =>
        fakeTx(key: key, kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _ago(ago));
    TxEntry inBlock(String key, BigInt height, {TxKind kind = TxKind.sent}) =>
        fakeTx(key: key, kind: kind, status: TxStatus.confirmed, createdAtUnix: _ago(const Duration(minutes: 5)), blockHeight: height);

    void boost(BlockWatch w, Boosts b, List<TxEntry> txs, [BigInt? tip]) {
      w.saw(txs, tip ?? _tip, now: _now);
      w.boostNode(b, txs, tip ?? _tip, minConfirmations: 3, now: _now);
    }

    test('a payment step boosts the node once, for the window left; a re-read boosts nothing', () {
      final (count, pace) = boosted((b) {
        final w = BlockWatch();
        final tx = waiting('a', const Duration(seconds: 10));
        boost(w, b, [tx]);
        boost(w, b, [tx]);
        boost(w, b, [tx]);
      });
      expect(count, 1);
      expect(pace, boostMinInterval);
    });

    test('a step the list shows boosts again; a payment past the window does not boost', () {
      final (count, _) = boosted((b) {
        final w = BlockWatch();
        final tx = waiting('a', const Duration(seconds: 10));
        boost(w, b, [tx]);
        final posted = fakeTx(key: 'a', kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: tx.createdAtUnix, kernelExcess: '08ab');
        w.saw([posted], _tip, now: _now);
        w.boostNode(b, [posted], _tip, minConfirmations: 3, now: _now);
      });
      expect(count, 2);
      final (late, _) = boosted((b) => boost(BlockWatch(), b, [waiting('b', watchWindow)]));
      expect(late, 0, reason: 'its window is over');
    });

    test('a payment in a block boosts on each new block, until it has its confirmations', () {
      final (count, _) = boosted((b) {
        final w = BlockWatch();
        final tx = inBlock('a', _tip);
        boost(w, b, [tx]);
        boost(w, b, [tx]);
        boost(w, b, [tx], _tip + BigInt.one);
        boost(w, b, [tx], _tip + BigInt.one);
        boost(w, b, [tx], _tip + BigInt.two);
      });
      expect(count, 2, reason: 'blocks 1 and 2 of 3 boost; the third has them all');
    });

    test('cancelled, imported and done payments do not boost', () {
      final (count, _) = boosted((b) {
        boost(BlockWatch(), b, [
          fakeTx(kind: TxKind.sentCancelled, status: TxStatus.cancelled, createdAtUnix: _ago(Duration.zero)),
          fakeTx(kind: TxKind.received, status: TxStatus.awaitingConfirmation, source: TxSource.imported, createdAtUnix: _ago(Duration.zero)),
          inBlock('done', _tip - BigInt.two),
        ]);
      });
      expect(count, 0);
    });
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
      expect(txExplanation(l, tx, _tip, now: _now, wait: BlockWait.noNewBlock), _l.txWaitNoNewBlock);
      expect(
        txExplanation(l, tx, _tip, now: _now, wait: BlockWait.notInBlock),
        _l.txWaitNotInBlock,
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

  test('a change the list shows (finalized, posted) restarts the watch, as LEPIC keeps no finalize time', () {
    final waiting = fakeTx(key: 's', kind: TxKind.sent, status: TxStatus.awaitingRecipient, createdAtUnix: _ago(const Duration(minutes: 20)));
    final finalized = fakeTx(key: 's', kind: TxKind.sent, status: TxStatus.awaitingConfirmation, createdAtUnix: waiting.createdAtUnix, kernelExcess: '08ab', repostable: true);
    final watch = BlockWatch()..saw([waiting], _tip, now: _now.subtract(const Duration(seconds: 10)));
    expect(watch.stepAt('s'), isNull, reason: 'first seen is no step');
    watch.saw([finalized], _tip, now: _now.subtract(const Duration(seconds: 3)));
    expect(watch.stepAt('s'), _ago(const Duration(seconds: 3)));
    expect(postingNow(finalized, _now, watch), isTrue);
    expect(postingNow(finalized, _now.add(postingFor), watch), isFalse);
  });
}
