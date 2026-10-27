// The rules for coins another linked device holds: what a send notice holds, what a status does,
// the chain deciding, and each fallback when no word comes.
import 'package:epic_wallet/src/devices/device_locks.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:flutter_test/flutter_test.dart';

String _c(int i) => '08${i.toRadixString(16).padLeft(64, '0')}';

final _t0 = DateTime.utc(2026, 10, 27, 12);

HeldPayment _hold({HoldState state = HoldState.held, int? cutoff, int? posted, DateTime? at}) => HeldPayment(
  deviceId: 'd' * 32,
  slateId: 'slate-1',
  commitments: [_c(1), _c(2)],
  amount: BigInt.from(500),
  lockedAt: at ?? _t0,
  state: state,
  cutoffHeight: cutoff,
  postedHeight: posted,
);

void main() {
  group('a send notice', () {
    final body = {
      'slateId': 'slate-1',
      'inputs': [_c(1), _c(9)],
      'amount': '500',
      'fee': '7',
      'cutoffHeight': 1000,
      'createdAt': 1790000000,
    };

    test('holds the inputs this wallet has', () {
      final h = holdFromSend(deviceId: 'd' * 32, deviceName: 'Desktop', body: body, own: {_c(1), _c(2)}, now: _t0)!;
      expect(h.commitments, [_c(1)]);
      expect(h.amount, BigInt.from(500));
      expect(h.fee, BigInt.from(7));
      expect(h.state, HoldState.held);
      expect(h.deviceName, 'Desktop');
    });

    test('naming none of this wallet coins holds nothing', () {
      expect(holdFromSend(deviceId: 'd' * 32, deviceName: 'Desktop', body: body, own: {_c(5)}, now: _t0), isNull);
    });
  });

  group('a status notice', () {
    for (final s in ['cancelled', 'expired', 'failed', 'released']) {
      test('$s releases unspent coins', () {
        final h = applyStatus(_hold(), s, spent: const {}, now: _t0);
        expect(h.state, HoldState.released);
        expect(h.reason, s);
      });
    }

    test('a release of coins the chain shows spent makes it history', () {
      expect(applyStatus(_hold(), 'cancelled', spent: {_c(2)}, now: _t0).state, HoldState.spent);
    });

    test('finalized keeps them held, posted remembers its height', () {
      expect(applyStatus(_hold(), 'finalized', kernel: 'k', spent: const {}, now: _t0).state, HoldState.held);
      final posted = applyStatus(_hold(), 'posted', height: 900, spent: const {}, now: _t0);
      expect(posted.state, HoldState.posted);
      expect(posted.postedHeight, 900);
    });

    test('after a release here, a late posted only adds details', () {
      final byHand = releaseByHand(_hold(), _t0);
      expect(byHand.state, HoldState.byHand);
      final after = applyStatus(byHand, 'posted', height: 950, kernel: 'k1', spent: const {}, now: _t0);
      expect(after.state, HoldState.byHand);
      expect(after.postedHeight, 950);
      expect(after.kernel, 'k1');
      expect(applyStatus(sweepHold(_hold(), spent: const {}, tip: null, now: _t0.add(holdMaxAge)), 'posted', spent: const {}, now: _t0).state, HoldState.timedOut);
    });

    test('a late notice never moves a confirmed payment back', () {
      for (final s in ['finalized', 'posted', 'cancelled', 'released']) {
        expect(applyStatus(_hold(state: HoldState.spent), s, spent: const {}, now: _t0).state, HoldState.spent);
      }
    });
  });

  group('the fallbacks', () {
    test('the chain showing a coin spent makes it history', () {
      expect(sweepHold(_hold(), spent: {_c(1)}, tip: 10, now: _t0).state, HoldState.spent);
    });

    test('past the cutoff and 10 blocks, unspent, it expired', () {
      expect(sweepHold(_hold(cutoff: 1000), spent: const {}, tip: 1010, now: _t0).state, HoldState.held);
      expect(sweepHold(_hold(cutoff: 1000), spent: const {}, tip: 1011, now: _t0).state, HoldState.expired);
    });

    test('posted and 1,440 blocks without the spend, it is given up', () {
      final h = _hold(state: HoldState.posted, posted: 2000, cutoff: 100000);
      expect(sweepHold(h, spent: const {}, tip: 3439, now: _t0).state, HoldState.posted);
      expect(sweepHold(h, spent: const {}, tip: 3440, now: _t0).state, HoldState.timedOut);
    });

    test('held 7 days, it is given up', () {
      final h = _hold();
      expect(sweepHold(h, spent: const {}, tip: null, now: _t0.add(const Duration(days: 6, hours: 23))).state, HoldState.held);
      expect(sweepHold(h, spent: const {}, tip: null, now: _t0.add(const Duration(days: 7))).state, HoldState.timedOut);
    });

    test('unlinking frees its device holds after the chain check', () {
      final other = HeldPayment(deviceId: 'e' * 32, slateId: 's2', commitments: [_c(3)], amount: BigInt.one, lockedAt: _t0);
      final spentOne = HeldPayment(deviceId: 'd' * 32, slateId: 's3', commitments: [_c(4)], amount: BigInt.one, lockedAt: _t0);
      final out = unlinkHolds([_hold(), other, spentOne], 'd' * 32, spent: {_c(4)}, now: _t0);
      expect(out.map((h) => h.state), [HoldState.unlinked, HoldState.held, HoldState.spent]);
    });

    test('release by hand frees only held coins, on this device', () {
      expect(releaseByHand(_hold(), _t0).state, HoldState.byHand);
      expect(releaseByHand(_hold(state: HoldState.spent), _t0).state, HoldState.spent);
    });

    test('the chain confirms from held or from any release', () {
      expect(sweepHold(releaseByHand(_hold(), _t0), spent: {_c(1)}, tip: 1, now: _t0).state, HoldState.spent);
      for (final s in [HoldState.released, HoldState.expired, HoldState.timedOut, HoldState.unlinked]) {
        expect(sweepHold(_hold(state: s), spent: {_c(2)}, tip: 1, now: _t0).state, HoldState.spent);
      }
    });
  });

  group('a coin freed by one payment and taken by the next', () {
    // Seen live on floonet: the device cancels a send, the next send takes the same coin and is
    // mined. The spend is the second payment's; the first stays as it ended.
    final first = HeldPayment(deviceId: 'd' * 32, slateId: 'first', commitments: [_c(1)], amount: BigInt.one, lockedAt: _t0, state: HoldState.released, reason: 'cancelled');
    final second = HeldPayment(deviceId: 'd' * 32, slateId: 'second', commitments: [_c(1)], amount: BigInt.two, lockedAt: _t0.add(const Duration(minutes: 1)), state: HoldState.posted);

    test('once spent, the newer payment is confirmed and the older one stays cancelled', () {
      final out = sweepHolds([first, second], spent: {_c(1)}, tip: 10, now: _t0);
      expect(out.map((h) => h.state), [HoldState.released, HoldState.spent]);
      expect(out.first.ending, first.ending);
    });

    test('the older payment\'s own cancel, coming late, does not take the spend', () {
      final stillHeld = HeldPayment(deviceId: 'd' * 32, slateId: 'first', commitments: [_c(1)], amount: BigInt.one, lockedAt: _t0);
      final spent = spentFor(stillHeld, [stillHeld, second], {_c(1)});
      expect(applyStatus(stillHeld, 'cancelled', spent: spent, now: _t0).state, HoldState.released);
    });

    test('an older payment still held when the newer one spent the coin expired', () {
      final stillHeld = HeldPayment(deviceId: 'd' * 32, slateId: 'first', commitments: [_c(1)], amount: BigInt.one, lockedAt: _t0);
      final out = sweepHolds([stillHeld, second], spent: {_c(1)}, tip: 10, now: _t0);
      expect(out.map((h) => h.state), [HoldState.expired, HoldState.spent]);
    });

    test('with no newer payment, a late landing still confirms the older one', () {
      expect(sweepHolds([first], spent: {_c(1)}, tip: 10, now: _t0).single.state, HoldState.spent);
    });
  });

  test('the book leaves out only held coins', () {
    final book = DeviceBook(
      deviceId: 'a' * 32,
      deviceName: 'Phone',
      holds: [_hold(), HeldPayment(deviceId: 'e' * 32, slateId: 's2', commitments: [_c(3)], amount: BigInt.one, lockedAt: _t0, state: HoldState.released)],
    );
    expect(book.heldCommitments, {_c(1), _c(2)});
    expect(DeviceBook.fromJson(book.toJson())!.heldCommitments, {_c(1), _c(2)});
  });
}
