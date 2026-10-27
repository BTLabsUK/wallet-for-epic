/// The rules for coins another linked device holds (D-14, "Output locks" in the sync plan).
/// Pure: the service hands in the chain's view and the clock.
///
/// - A `send` notice holds the inputs this wallet has (unspent or locked); one naming none of
///   them is dropped.
/// - Only the device that held coins can release them by notice. `cancelled`, `expired`,
///   `failed` and `released` free them unless the chain shows them spent; `finalized` and
///   `posted` keep them held (posted remembers its height). A `posted` for coins released here
///   by hand holds them again until the chain decides.
/// - The chain showing any of them spent makes the payment history ([HoldState.spent]).
/// - With no word from the device: past its cutoff height + [holdCutoffMargin] blocks, still
///   unspent → expired; posted [holdPostedBlocks] blocks ago and unspent → timed out; held
///   [holdMaxAge] → timed out; its device removed → unlinked (after the chain check).
/// - Release by hand: always, this device only.
library;

import 'device_model.dart';

/// Blocks past a payment's cutoff height before its coins are freed here.
const int holdCutoffMargin = 10;

/// Blocks after a posted payment before its coins are freed here, as LEPIC makes its own sends
/// releasable.
const int holdPostedBlocks = 1440;

/// The longest coins stay held without the chain or the device deciding: the servers' 7 days.
const Duration holdMaxAge = Duration(days: 7);

/// The hold a `send` notice from [deviceId] makes, or null when this wallet holds none of its
/// [inputs] (then nothing is held). [own] is this wallet's unspent and locked commitments.
HeldPayment? holdFromSend({
  required String deviceId,
  required String deviceName,
  required Map<String, Object?> body,
  required Set<String> own,
  required DateTime now,
}) {
  final inputs = [
    for (final c in body['inputs'] as List)
      if (own.contains(c)) c as String,
  ];
  if (inputs.isEmpty) return null;
  final created = body['createdAt'] as int?;
  return HeldPayment(
    deviceId: deviceId,
    deviceName: deviceName,
    slateId: body['slateId'] as String,
    commitments: inputs,
    amount: BigInt.parse(body['amount'] as String),
    fee: body['fee'] == null ? null : BigInt.parse(body['fee'] as String),
    lockedAt: now,
    txId: body['txId'] as int?,
    counterparty: body['counterparty'] as String?,
    method: body['method'] as String?,
    message: body['message'] as String?,
    cutoffHeight: body['cutoffHeight'] as int?,
    createdAt: created == null ? null : DateTime.fromMillisecondsSinceEpoch(created * 1000),
  );
}

/// Whether the chain shows any of [h]'s coins spent.
bool holdSpent(HeldPayment h, Set<String> spent) => h.commitments.any(spent.contains);

/// [h] after a `status` notice [state] at [height]. [spent]: commitments the chain shows spent.
HeldPayment applyStatus(HeldPayment h, String state, {int? height, String? kernel, required Set<String> spent, required DateTime now}) {
  if (h.state == HoldState.spent) return h;
  switch (state) {
    case 'finalized':
      return h.state.holds ? h.copyWith(kernel: kernel, changedAt: now) : h;
    case 'posted':
      // A late "posted" holds coins released by hand again: the chain decides.
      if (h.state.holds || h.state == HoldState.byHand) {
        return h.copyWith(state: HoldState.posted, postedHeight: height ?? h.postedHeight, kernel: kernel, changedAt: now);
      }
      return h;
    default:
      if (!h.state.holds) return h;
      if (holdSpent(h, spent)) return h.copyWith(state: HoldState.spent, changedAt: now);
      return h.copyWith(state: HoldState.released, reason: state, changedAt: now);
  }
}

/// [holds] after the chain and the clock: spent ones become history, the fallbacks free the
/// rest. [tip] is the chain height (null: unknown, height rules wait).
List<HeldPayment> sweepHolds(List<HeldPayment> holds, {required Set<String> spent, required int? tip, required DateTime now}) => [
  for (final h in holds) sweepHold(h, spent: spent, tip: tip, now: now),
];

HeldPayment sweepHold(HeldPayment h, {required Set<String> spent, required int? tip, required DateTime now}) {
  if (h.state == HoldState.spent) return h;
  // Coins freed here and then spent on chain are still history of that device's payment.
  if (holdSpent(h, spent) && (h.state.holds || h.state == HoldState.byHand || h.state == HoldState.timedOut || h.state == HoldState.expired)) {
    return h.copyWith(state: HoldState.spent, changedAt: now);
  }
  if (!h.state.holds) return h;
  final cutoff = h.cutoffHeight;
  if (tip != null && h.state == HoldState.held && cutoff != null && tip > cutoff + holdCutoffMargin) {
    return h.copyWith(state: HoldState.expired, changedAt: now);
  }
  final posted = h.postedHeight;
  if (tip != null && h.state == HoldState.posted && posted != null && tip >= posted + holdPostedBlocks) {
    return h.copyWith(state: HoldState.timedOut, changedAt: now);
  }
  if (now.difference(h.lockedAt) >= holdMaxAge) return h.copyWith(state: HoldState.timedOut, changedAt: now);
  return h;
}

/// [holds] once [deviceId] is removed: its held coins are spent (the chain says so) or freed.
List<HeldPayment> unlinkHolds(List<HeldPayment> holds, String deviceId, {required Set<String> spent, required DateTime now}) => [
  for (final h in holds)
    if (h.deviceId != deviceId || !h.state.holds)
      h
    else
      h.copyWith(state: holdSpent(h, spent) ? HoldState.spent : HoldState.unlinked, changedAt: now),
];

/// [h] released by hand on this device. Only held coins change.
HeldPayment releaseByHand(HeldPayment h, DateTime now) => h.state.holds ? h.copyWith(state: HoldState.byHand, changedAt: now) : h;

/// How long a freed or spent hold is kept before it is forgotten (spent ones stay as history).
const Duration holdForgetAfter = Duration(days: 30);

/// [holds] without freed ones older than [holdForgetAfter].
List<HeldPayment> pruneHolds(List<HeldPayment> holds, DateTime now) => [
  for (final h in holds)
    if (!h.state.freed || now.difference(h.changedAt ?? h.lockedAt) < holdForgetAfter) h,
];
