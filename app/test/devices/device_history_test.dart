// The other devices' payments in history: a pending row from the notice, merged with the chain
// check's "another wallet" row once spent, never shown twice; freed coins show nothing.
import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/models.dart' show DeviceEnding;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _c(int i) => '08${i.toRadixString(16).padLeft(64, '0')}';

final _desk = 'd' * 32;

HeldPayment _hold(String slate, List<int> coins, {HoldState state = HoldState.held, int at = 1790000100}) => HeldPayment(
  deviceId: _desk,
  slateId: slate,
  commitments: [for (final c in coins) _c(c)],
  amount: BigInt.from(300),
  fee: BigInt.from(7),
  lockedAt: DateTime.fromMillisecondsSinceEpoch(at * 1000),
  createdAt: DateTime.fromMillisecondsSinceEpoch(at * 1000),
  counterparty: 'esBob@epicbox.epiccash.com',
  message: 'rent',
  state: state,
);

TxEntry _otherWallet(String key, List<int> coins, int time) => TxEntry(
  key: key,
  kind: TxKind.sent,
  status: TxStatus.confirmed,
  source: TxSource.wallet,
  createdAtUnix: time,
  timeUnix: time,
  confirmed: true,
  blockHeight: BigInt.from(900),
  amountCredited: BigInt.zero,
  amountDebited: BigInt.from(307),
  numInputs: coins.length,
  numOutputs: 0,
  outputCommits: const [],
  cancellable: false,
  repostable: false,
  releasable: false,
  origin: TxOrigin.otherWallet,
  spentCommits: [for (final c in coins) _c(c)],
);

DeviceBook _book(List<HeldPayment> holds) => DeviceBook(
  deviceId: 'a' * 32,
  deviceName: 'Phone',
  devices: [LinkedDevice(deviceId: _desk, name: 'Desktop', pairings: const {'s': 'p'}, linkedAt: DateTime.utc(2026))],
  holds: holds,
);

void main() {
  test('a payment under way shows as pending from the device', () {
    final rows = mergeDeviceHistory([fakeTx(key: 'mine', createdAtUnix: 1790000000)], _book([_hold('s1', [1])]));
    expect(rows, hasLength(2));
    final row = rows.first;
    expect(row.origin, TxOrigin.linkedDevice);
    expect(row.deviceName, 'Desktop');
    expect(row.confirmed, isFalse);
    expect(row.status, TxStatus.awaitingRecipient);
    expect(row.amountDebited, BigInt.from(307));
    expect(row.counterparty, 'esBob@epicbox.epiccash.com');
    expect(row.messages.single.text, 'rent');
  });

  test('the chain row and the notice merge into one row', () {
    final chain = _otherWallet('k:abc', [1, 2], 1790000500);
    final rows = mergeDeviceHistory([chain], _book([_hold('s1', [1, 2], state: HoldState.spent)]));
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.key, deviceRowKey(_hold('s1', [1, 2])));
    expect(row.origin, TxOrigin.linkedDevice);
    expect(row.confirmed, isTrue);
    expect(row.blockHeight, BigInt.from(900));
    expect(row.deviceName, 'Desktop');
    expect(row.counterparty, 'esBob@epicbox.epiccash.com');
  });

  test('another wallet row that matches no hold stays as it is', () {
    final chain = _otherWallet('k:zzz', [5], 1790000500);
    final rows = mergeDeviceHistory([chain], _book([_hold('s1', [1])]));
    expect(rows.map((r) => r.origin), containsAll([TxOrigin.otherWallet, TxOrigin.linkedDevice]));
  });

  test('a payment the device ended shows how: cancelled, failed with its code, expired', () {
    HeldPayment ended(String reason, {String? why}) => _hold('s1', [1], state: HoldState.released).copyWith(reason: reason, why: why);
    final cancelled = mergeDeviceHistory(const [], _book([ended('cancelled')])).single;
    expect(cancelled.status, TxStatus.cancelled);
    expect(cancelled.deviceEnding, DeviceEnding.cancelled);
    final released = mergeDeviceHistory(const [], _book([ended('released')])).single;
    expect(released.deviceEnding, DeviceEnding.cancelled);
    final failed = mergeDeviceHistory(const [], _book([ended('failed', why: 'refused')])).single;
    expect(failed.deviceEnding, DeviceEnding.failed);
    expect(failed.deviceWhy, 'refused');
    final expired = mergeDeviceHistory(const [], _book([ended('expired')])).single;
    expect(expired.deviceEnding, DeviceEnding.expired);
    expect(expired.deviceWhy, isNull);
  });

  test('the fallbacks read Expired, a hand release and a removal read released here', () {
    for (final s in [HoldState.expired, HoldState.timedOut]) {
      expect(mergeDeviceHistory(const [], _book([_hold('s1', [1], state: s)])).single.deviceEnding, DeviceEnding.expired);
    }
    for (final s in [HoldState.byHand, HoldState.unlinked]) {
      expect(mergeDeviceHistory(const [], _book([_hold('s1', [1], state: s)])).single.deviceEnding, DeviceEnding.releasedHere);
    }
    expect(mergeDeviceHistory(const [], _book([_hold('s1', [1])])).single.deviceEnding, isNull);
  });

  test('coins released here show as a released row until the chain decides', () {
    for (final s in [HoldState.byHand, HoldState.expired, HoldState.timedOut, HoldState.unlinked]) {
      final row = mergeDeviceHistory(const [], _book([_hold('s1', [1], state: s)])).single;
      expect(row.status, TxStatus.cancelled);
      expect(row.kind, TxKind.sentCancelled);
      expect(row.origin, TxOrigin.linkedDevice);
    }
  });

  test('released, then confirmed: the same row comes back confirmed, once', () {
    for (final s in [HoldState.byHand, HoldState.timedOut, HoldState.released, HoldState.held]) {
      final hold = _hold('s1', [1], state: s);
      final before = mergeDeviceHistory(const [], _book([hold]));
      final rows = mergeDeviceHistory([_otherWallet('k:abc', [1], 1790000500)], _book([hold]));
      expect(rows, hasLength(1), reason: s.name);
      expect(rows.single.confirmed, isTrue);
      expect(rows.single.status, TxStatus.confirmed);
      expect(rows.single.kind, TxKind.sent);
      expect(rows.single.counterparty, 'esBob@epicbox.epiccash.com');
      if (before.isNotEmpty) expect(rows.single.key, before.single.key);
    }
  });

  test('a removed device keeps its name on its rows', () {
    final book = DeviceBook(deviceId: 'a' * 32, deviceName: 'Phone', holds: [_hold('s1', [1], state: HoldState.spent).copyWith()]);
    final named = DeviceBook.fromJson({...book.toJson(), 'holds': [{...book.holds.single.toJson(), 'name': 'Old laptop'}]})!;
    expect(mergeDeviceHistory(const [], named).single.deviceName, 'Old laptop');
  });
}
