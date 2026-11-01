// SPDX-License-Identifier: Apache-2.0
// One row per payment of a linked device, driven by the chain: the change of its send folds into
// the send's row on both devices, never a receive of its own; the copy of a send follows the
// chain (waiting for a block, confirming, confirmed) or ends, a cancel or a replacement on the
// sending device included; holds a 26.10.24 install stored resolve on open.
import 'dart:convert';

import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_locks.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/ui/common.dart' show TxPhase, txPhase;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

final _phone = 'b' * 32;
final _k1 = '09${'1' * 64}';
final _k2 = '09${'2' * 64}';

/// A payment of 1 EPIC (fee 0.008) from coin 2 (3 EPIC): its change is 1.992 EPIC.
final _amount = BigInt.from(100000000);
final _fee = BigInt.from(800000);
final _inputs = BigInt.from(300000000);
final _change = _inputs - _amount - _fee;

int _unix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

HeldPayment _hold({HoldState state = HoldState.posted, String? kernel}) => HeldPayment(
  deviceId: _phone,
  deviceName: 'Mobile P7',
  slateId: 'pay-1',
  commitments: [cm(2)],
  amount: _amount,
  fee: _fee,
  lockedAt: DateTime.utc(2026, 11, 1, 14, 58),
  createdAt: DateTime.utc(2026, 11, 1, 14, 58),
  counterparty: 'esIos@epicbox.epiccash.com',
  state: state,
  kernel: kernel,
);

DeviceBook _book(List<HeldPayment> holds, {Map<String, List<String>> theirReceives = const {}}) => DeviceBook(
  deviceId: 'a' * 32,
  deviceName: 'Desktop',
  devices: [LinkedDevice(deviceId: _phone, name: 'Mobile P7', pairings: const {'s': 'p'}, linkedAt: DateTime.utc(2026))],
  holds: holds,
  theirReceives: theirReceives,
);

/// LEPIC's "received by another wallet" row: an output of this wallet an update scan found.
TxEntry _received(String key, int commit, BigInt amount, {int height = 1001}) => fakeTx(
  key: key,
  kind: TxKind.received,
  status: TxStatus.confirmed,
  confirmed: true,
  createdAtUnix: _unix(DateTime.utc(2026, 11, 1, 14, 59)),
  blockHeight: BigInt.from(height),
  amountCredited: amount,
  amountDebited: BigInt.zero,
  outputCommits: [cm(commit)],
  origin: TxOrigin.otherWallet,
);

/// LEPIC's "sent from another wallet" row for [coins], its change credited ([changeNo]) or not.
TxEntry _spend({List<int> coins = const [2], int? changeNo, int height = 1003}) => fakeTx(
  key: 'l:spend',
  kind: TxKind.sent,
  status: TxStatus.confirmed,
  confirmed: true,
  createdAtUnix: _unix(DateTime.utc(2026, 11, 1, 15)),
  blockHeight: BigInt.from(height),
  amountCredited: changeNo != null ? _change : BigInt.zero,
  amountDebited: _inputs,
  outputCommits: [?(changeNo == null ? null : cm(changeNo))],
  origin: TxOrigin.otherWallet,
  spentCommits: [for (final c in coins) cm(c)],
);

/// [side]'s own send [slate] from [coinNo] with its change [changeNo], as LEPIC lists it.
TxEntry _payRow(String slate, {required int tx, int changeNo = 20, String? kernel, bool posted = true, bool cancelled = false}) => fakeTx(
  id: tx,
  slateId: slate,
  kind: cancelled ? TxKind.sentCancelled : TxKind.sent,
  status: cancelled
      ? TxStatus.cancelled
      : posted
      ? TxStatus.awaitingConfirmation
      : TxStatus.awaitingRecipient,
  amountDebited: _inputs,
  amountCredited: cancelled ? BigInt.zero : _change,
  fee: _fee,
  finalizedAtUnix: posted && !cancelled ? 1790000100 : null,
  kernelExcess: kernel,
  outputCommits: cancelled ? const [] : [cm(changeNo)],
  counterparty: 'esIos@epicbox.epiccash.com',
  cancelReason: cancelled ? CancelReason.user : null,
);

/// [side]'s outputs with coin [coinNo] an input of [tx] (or free again) and [changeNo] its change.
void _coins(Side side, Map<int, int?> inputsOf, {Map<int, int> change = const {}}) {
  side.session.outputsValue = [
    for (final o in [coin(1, 5), coin(2, 3), coin(3, 2)])
      if (inputsOf[int.parse(o.commitment.substring(2), radix: 16)] case final tx?)
        coin(int.parse(o.commitment.substring(2), radix: 16), 3, status: WalletOutputStatus.locked, txId: tx)
      else
        o,
    for (final e in change.entries) coin(e.key, 2, status: WalletOutputStatus.unconfirmed, txId: e.value),
  ];
}

void _tip(Side side, int height) {
  final s = side.session.summaryValue;
  side.session.summaryValue = WalletSummary(
    lastConfirmedHeight: BigInt.from(height),
    minimumConfirmations: s.minimumConfirmations,
    total: s.total,
    spendable: s.spendable,
    awaitingConfirmation: s.awaitingConfirmation,
    awaitingFinalization: s.awaitingFinalization,
    immature: s.immature,
    locked: s.locked,
    validatedWithNode: true,
  );
}

/// [side]'s chain check shows [coins] spent.
void _spentHere(Side side, List<int> coins) {
  side.session.outputsValue = [
    for (final o in side.session.outputsValue)
      if (coins.any((c) => o.commitment == cm(c))) coin(int.parse(o.commitment.substring(2), radix: 16), 3, status: WalletOutputStatus.spent) else o,
  ];
}

Future<List<TxEntry>> _history(Side side) async => mergeDeviceHistory(await side.session.transactions(refresh: false), side.service.book);

String _describe(List<TxEntry> rows) => rows.map((r) => '${r.origin.name}:${r.slateId}:${r.kind.name}:${r.deviceName}').join(', ');

void main() {
  group('the change of a linked send', () {
    test('found by the scan before the spend: no receive row, the send row is on chain', () {
      final rows = mergeDeviceHistory([_received('l:chg', 20, _change)], _book([_hold(kernel: _k1).copyWithChange([cm(20)])]));
      expect(rows, hasLength(1), reason: _describe(rows));
      expect(rows.single.origin, TxOrigin.linkedDevice);
      expect(rows.single.status, TxStatus.confirmed);
      expect(rows.single.blockHeight, BigInt.from(1001));
      expect(rows.single.amountDebited - rows.single.amountCredited, _amount + _fee);
    });

    test('spend and change split in two rows, a notice that named no change: one row, the change folded in', () {
      final rows = mergeDeviceHistory([_spend(), _received('l:chg', 20, _change)], _book([_hold()]));
      expect(rows, hasLength(1), reason: _describe(rows));
      final row = rows.single;
      expect(row.origin, TxOrigin.linkedDevice);
      expect(row.amountDebited - row.amountCredited, _amount + _fee);
      expect(row.outputCommits, [cm(20)]);
      expect(row.blockHeight, BigInt.from(1001), reason: 'the change dates the block');
    });

    test('LEPIC folded the change itself: one row, not counted twice', () {
      final rows = mergeDeviceHistory([_spend(changeNo: 20)], _book([_hold().copyWithChange([cm(20)])]));
      expect(rows, hasLength(1));
      expect(rows.single.amountCredited, _change);
    });

    test('a receive worth something else stays a receive, by another device', () {
      final rows = mergeDeviceHistory([_spend(), _received('l:other', 21, BigInt.from(5))], _book([_hold()]));
      expect(rows, hasLength(2), reason: _describe(rows));
      final other = rows.singleWhere((r) => r.origin == TxOrigin.otherWallet);
      expect(other.deviceName, isNull);
    });

    test('coins spent with no chain row of the spend: the row reads sent, not confirming forever', () {
      final rows = mergeDeviceHistory(const [], _book([_hold(state: HoldState.spent)]));
      expect(rows.single.status, TxStatus.confirmed);
      expect(txPhase(rows.single, BigInt.from(5000), target: 10), TxPhase.completed);
    });
  });

  group('receives of the linked device', () {
    test('one its recv notice named reads Received on it, an unknown one Received by another device', () {
      final book = _book([_hold().copyWithChange([cm(20)])], theirReceives: {'r-1': [cm(30)]});
      final rows = mergeDeviceHistory([_received('l:theirs', 30, BigInt.from(7)), _received('l:unknown', 31, BigInt.from(9))], book);
      expect(rows.singleWhere((r) => r.key == 'l:theirs').deviceName, 'Mobile P7');
      expect(rows.singleWhere((r) => r.key == 'l:unknown').deviceName, isNull);
      expect(rows.singleWhere((r) => r.key == 'l:unknown').origin, TxOrigin.otherWallet);
    });
  });

  group('two linked devices', () {
    late Clock clock;
    late Side a;
    late Side b;

    setUp(() async {
      clock = Clock();
      final net = FakePrivateNet();
      a = Side('Mobile P7', clock: clock, net: net);
      b = Side('Desktop', clock: clock, net: net);
      await linkBoth(a, b);
    });

    test('a send follows the chain on the other device: waiting for a block, confirming, confirmed; its change folds in', () async {
      a.session.transactionsValue = [_payRow('pay-1', tx: 7, kernel: _k1)];
      _coins(a, {2: 7}, change: {20: 7});
      await settle(a, b);
      final hold = b.service.book.holds.single;
      expect(hold.state, HoldState.posted);
      expect(hold.change, [cm(20)]);
      expect(hold.postedHeight, 1000, reason: 'a first posted without a height counts from here');
      var rows = await _history(b);
      expect(rows.single.blockHeight, isNull);
      expect(txPhase(rows.single, BigInt.from(1000), target: 10), TxPhase.confirming, reason: 'waiting for a block');

      // The scan sees the block before the refresh sees the coin go.
      b.session.transactionsValue = [_received('l:chg', 20, _change)];
      rows = await _history(b);
      expect(rows, hasLength(1), reason: _describe(rows));
      expect(rows.single.blockHeight, BigInt.from(1001));

      // The kernel is found at its block; then the spend shows, apart from the change.
      b.session.kernelsOnChain = {_k1: const KernelLocation(height: 1001, mmrIndex: 1)};
      _tip(b, 1002);
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      expect(b.service.book.holds.single.minedHeight, 1001);
      expect(b.session.heldOutputs, isEmpty);
      _spentHere(b, [2]);
      b.session.transactionsValue = [_spend(), _received('l:chg', 20, _change)];
      rows = await _history(b);
      expect(rows, hasLength(1), reason: _describe(rows));
      final row = rows.single;
      expect(row.slateId, 'pay-1');
      expect(row.deviceName, 'Mobile P7');
      expect(row.amountDebited - row.amountCredited, _amount + _fee);
      expect(row.blockHeight, BigInt.from(1001));
      expect(txPhase(row, BigInt.from(1002), target: 10), TxPhase.confirming);
      expect(txPhase(row, BigInt.from(1010), target: 10), TxPhase.completed);

      // The sending device: its own row, the change in it, no receive.
      final mine = await _history(a);
      expect(mine, hasLength(1), reason: _describe(mine));
      expect(mine.single.kind, TxKind.sent);
    });

    test('cancelled on the sending device and sent again with the same coin: the first ends cancelled, the second follows the chain', () async {
      a.session.transactionsValue = [_payRow('pay-1', tx: 7, kernel: _k1)];
      _coins(a, {2: 7}, change: {20: 7});
      await settle(a, b);
      clock.now = clock.now.add(const Duration(minutes: 3));
      a.session.transactionsValue = [_payRow('pay-1', tx: 7, kernel: _k1, cancelled: true), _payRow('pay-2', tx: 8, kernel: _k2, changeNo: 21)];
      _coins(a, {2: 8}, change: {21: 8});
      await settle(a, b);
      expect({for (final h in b.service.book.holds) h.slateId: h.state}, {'pay-1': HoldState.released, 'pay-2': HoldState.posted});
      b.session.kernelsOnChain = {_k2: const KernelLocation(height: 1002, mmrIndex: 1)};
      _tip(b, 1003);
      _spentHere(b, [2]);
      b.session.transactionsValue = [_spend(), _received('l:chg', 21, _change, height: 1002)];
      await b.sync();
      final rows = await _history(b);
      expect(rows, hasLength(2), reason: _describe(rows));
      final second = rows.singleWhere((r) => r.slateId == 'pay-2');
      expect(second.status, TxStatus.confirmed);
      expect(second.blockHeight, BigInt.from(1002));
      expect(second.amountDebited - second.amountCredited, _amount + _fee);
      final first = rows.singleWhere((r) => r.slateId == 'pay-1');
      expect(first.status, TxStatus.cancelled);
      expect(first.deviceEnding, DeviceEnding.cancelled);
    });

    test("the cancel's notice never comes and the coin is sent again: the first still ends cancelled", () async {
      a.session.transactionsValue = [_payRow('pay-1', tx: 7, kernel: _k1)];
      _coins(a, {2: 7}, change: {20: 7});
      await settle(a, b);
      // The first payment is gone from what the sending device tells: no cancel goes out.
      clock.now = clock.now.add(const Duration(minutes: 3));
      a.session.transactionsValue = [_payRow('pay-2', tx: 8, kernel: _k2, changeNo: 21)];
      _coins(a, {2: 8}, change: {21: 8});
      await settle(a, b);
      expect({for (final h in b.service.book.holds) h.slateId: h.state}, {'pay-1': HoldState.posted, 'pay-2': HoldState.posted});
      b.session.kernelsOnChain = {_k2: const KernelLocation(height: 1002, mmrIndex: 1)};
      _tip(b, 1003);
      _spentHere(b, [2]);
      b.session.transactionsValue = [_spend(), _received('l:chg', 21, _change, height: 1002)];
      await b.sync();
      final rows = await _history(b);
      expect(rows, hasLength(2), reason: _describe(rows));
      expect(rows.singleWhere((r) => r.slateId == 'pay-2').blockHeight, BigInt.from(1002));
      final first = rows.singleWhere((r) => r.slateId == 'pay-1');
      expect(first.deviceEnding, DeviceEnding.cancelled);
      expect(b.service.book.holds.firstWhere((h) => h.slateId == 'pay-1').replaced, isTrue);
    });

    test('sent again with other coins and no word on the first: once its kernel stays off chain, its coin is free', () async {
      a.session.transactionsValue = [_payRow('pay-1', tx: 7, kernel: _k1)];
      _coins(a, {2: 7}, change: {20: 7});
      await settle(a, b);
      clock.now = clock.now.add(const Duration(minutes: 3));
      a.session.transactionsValue = [_payRow('pay-2', tx: 8, kernel: _k2, changeNo: 21)];
      _coins(a, {3: 8}, change: {21: 8});
      await settle(a, b);
      b.session.kernelsOnChain = {_k2: const KernelLocation(height: 1002, mmrIndex: 1)};
      _tip(b, 1003);
      await b.sync();
      expect(b.service.book.holds.firstWhere((h) => h.slateId == 'pay-1').state, HoldState.posted, reason: 'too early to say');
      _tip(b, 1000 + holdKernelAbsentBlocks);
      await b.sync();
      expect(b.service.book.holds.firstWhere((h) => h.slateId == 'pay-1').state, HoldState.timedOut);
      expect(b.session.heldOutputs, isNot(contains(cm(2))));
      expect(b.service.book.holds.firstWhere((h) => h.slateId == 'pay-2').minedHeight, 1002);
    });
  });

  group('holds a 26.10.24 install stored', () {
    late Clock clock;
    late Side b;
    final posted28 = DateTime.utc(2026, 10, 28, 13, 12);

    /// The book as 26.10.24-r2 wrote it: one posted hold, its kernel known, no height.
    Future<void> stored({String state = 'posted', String? kernel}) async {
      final hold = {
        'dev': 'd' * 32,
        'slate': 'old-1',
        'commits': [cm(2)],
        'amount': '100000000',
        'locked': posted28.millisecondsSinceEpoch,
        'state': state,
        'tx': 7,
        'fee': '800000',
        'to': 'esBob@epicbox.epiccash.com',
        'method': 'epicbox',
        'msg': null,
        'cutoff': null,
        'posted': null,
        'kernel': kernel ?? _k1,
        'created': posted28.millisecondsSinceEpoch,
        'name': 'Desktop',
        'changed': posted28.millisecondsSinceEpoch,
        'reason': null,
        'why': null,
      };
      await b.store.write(DeviceStore.keyFor(Chain.floonet, null), jsonEncode({'v': 1, 'id': 'a' * 32, 'name': 'Phone', 'holds': [hold]}));
    }

    Map<String, Object?> storedHold() => ((jsonDecode(b.store.values[DeviceStore.keyFor(Chain.floonet, null)]!) as Map)['holds'] as List).single as Map<String, Object?>;

    setUp(() {
      clock = Clock()..now = DateTime.utc(2026, 11, 1, 15);
      b = Side('Phone', clock: clock, net: FakePrivateNet());
      _tip(b, 9000);
    });

    test('posted, its kernel never mined, its coin unspent: it ends on open', () async {
      await stored();
      await b.service.load();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.timedOut);
      expect(b.session.heldOutputs, isEmpty);
      final row = (await _history(b)).single;
      expect(row.status, TxStatus.cancelled);
      expect(row.deviceEnding, DeviceEnding.expired);
      expect(storedHold()['state'], 'timedOut');
    });

    test('the same with no kernel lookup to be had: the posted fallback counts from when it was posted', () async {
      b.session.kernelLookupWorks = false;
      await stored();
      await b.service.load();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.timedOut);
    });

    test('its kernel is on chain: confirmed at its block, written in place', () async {
      b.session.kernelsOnChain = {_k1: const KernelLocation(height: 8990, mmrIndex: 3)};
      await stored();
      await b.service.load();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      final row = (await _history(b)).single;
      expect(row.status, TxStatus.confirmed);
      expect(row.blockHeight, BigInt.from(8990));
      final rec = storedHold();
      expect(rec['state'], 'spent');
      expect(rec['mined'], 8990);
      expect(rec['kernel'], _k1);
    });

    test('confirmed by its coins alone ("Confirming 0/4" before): its kernel gives the block', () async {
      b.session.kernelsOnChain = {_k1: const KernelLocation(height: 8990, mmrIndex: 3)};
      await stored(state: 'spent');
      await b.service.load();
      await b.sync();
      final row = (await _history(b)).single;
      expect(row.status, TxStatus.confirmed);
      expect(row.blockHeight, BigInt.from(8990));
    });

    test('its coin spent by another kernel: it ends cancelled, the chain row stays the other payment', () async {
      _spentHere(b, [2]);
      b.session.transactionsValue = [_spend()];
      await stored();
      await b.service.load();
      await b.sync();
      expect(b.service.book.holds.single.replaced, isFalse, reason: 'one lookup that missed it ends nothing');
      _tip(b, 9001);
      await b.sync();
      expect(b.service.book.holds.single.replaced, isTrue);
      final rows = await _history(b);
      expect(rows, hasLength(2), reason: _describe(rows));
      expect(rows.singleWhere((r) => r.origin == TxOrigin.linkedDevice).deviceEnding, DeviceEnding.cancelled);
      expect(rows.singleWhere((r) => r.origin == TxOrigin.otherWallet).spentCommits, [cm(2)]);
    });
  });
}

extension on HeldPayment {
  HeldPayment copyWithChange(List<String> change) => HeldPayment.fromJson({...toJson(), 'change': change})!;
}
