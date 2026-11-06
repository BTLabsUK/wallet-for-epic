// SPDX-License-Identifier: Apache-2.0
/// The other devices' payments in this wallet's history: "Sent from `<device>`", one row per
/// payment, as the chain shows it.
///
/// A payment another device is making shows as a pending row from its `send` notice. What the
/// chain shows of it joins that row, whatever this device's chain check made of it:
/// - LEPIC's row of [TxOrigin.otherWallet] whose `spentCommits` include its coins (its spend);
/// - an output the chain check took for a receive by another wallet when it is the payment's
///   change: one its notice named, one with its kernel, or, for a notice that named none, the
///   one worth what the spend leaves after the amount and the fee. A scan that saw the block
///   before the refresh saw the coins go, or a spend outside the scan's window, splits a
///   payment in two that way;
/// - its kernel's block, once this device found it ([HeldPayment.minedHeight]).
/// The row then confirms with the chain: waiting for a block, confirming, confirmed. A payment
/// that ended without spending its coins stays as a cancelled row that says how (released here,
/// cancelled, replaced, failed or expired on the device) until the chain decides: a payment
/// whose cancel came too late comes back as the same row, confirmed. One whose coins another
/// payment spent ([HeldPayment.replaced]) never takes the chain's row of those coins.
///
/// Coins the linked device received reach this wallet as a chain-check row too. That row reads
/// "Received on `<device>`" only when the device said so: an output its `recv` notice named.
/// Anything else that is no payment's change reads "Received by another device": a third
/// install on the same phrase may have received it. A payment both devices answered (one
/// address, one relay) shows once: this device's own answer is left out once the chain shows
/// the linked device's ([answersTakenThere]).
///
/// A block reward carries the device's name only when the device said it built it: an output
/// its `reward` notice named. Nothing is worked out from the row, so no reward is named wrongly;
/// one not told about reads "Mining reward".
library;

import '../models.dart';
import 'device_model.dart';

/// The key of the pending row for [h], before the chain shows it.
String deviceRowKey(HeldPayment h) => 'd:${h.deviceId}:${h.slateId}';

/// [rows] (this wallet's history, newest first) with the linked devices' payments of [book]
/// merged in, newest first.
List<TxEntry> mergeDeviceHistory(List<TxEntry> rows, DeviceBook book) {
  if (book.holds.isEmpty && book.devices.isEmpty && book.theirReceives.isEmpty) return rows;
  final taken = answersTakenThere(rows, book).toSet();
  final linked = book.linked;
  final theirOutputs = {for (final o in book.theirReceives.values) ...o};
  final theirRewards = book.theirRewards.toSet();
  // Held, ended without spending (by the device, by the fallbacks or by hand) and confirmed all
  // keep their row.
  final shown = [for (final h in book.holds) if (h.state.holds || h.state.freed || h.state == HoldState.spent) h];

  // The chain's spends: of the payments that held these coins (a coin freed by one is often
  // taken by the next), the one the chain confirmed, else the newest. The chain's word is
  // final, whatever this device did with the coins, unless another payment spent them.
  final spendOf = Map<HeldPayment, TxEntry>.identity();
  final folded = Set<TxEntry>.identity();
  for (final r in rows) {
    if (r.origin != TxOrigin.otherWallet || r.spentCommits.isEmpty) continue;
    final h =
        (book.holds.where((h) => !spendOf.containsKey(h) && !h.replaced && h.commitments.any(r.spentCommits.contains)).toList()
              ..sort((a, b) => (a.state == HoldState.spent) != (b.state == HoldState.spent) ? (a.state == HoldState.spent ? -1 : 1) : b.lockedAt.compareTo(a.lockedAt)))
            .firstOrNull;
    if (h == null) continue;
    spendOf[h] = r;
    folded.add(r);
  }

  // The payments' change the chain check listed as received: part of the payment's row.
  final changeOf = Map<HeldPayment, List<TxEntry>>.identity();
  for (final r in rows) {
    if (r.origin != TxOrigin.otherWallet || r.spentCommits.isNotEmpty || r.amountCredited <= BigInt.zero) continue;
    if (r.outputCommits.any(theirOutputs.contains)) continue;
    final h = book.holds.where((h) => !h.replaced && _isChange(r, h, spendOf[h])).firstOrNull;
    if (h == null) continue;
    (changeOf[h] ??= []).add(r);
    folded.add(r);
  }

  final out = <TxEntry>[];
  for (final r in rows) {
    if (folded.contains(r) || taken.contains(r)) continue;
    if (linked != null && r.origin == TxOrigin.otherWallet && r.spentCommits.isEmpty && r.amountCredited > BigInt.zero) {
      // Coins of this wallet the linked device received: the answers it told about. Nothing
      // else is its for sure.
      if (r.outputCommits.any(theirOutputs.contains)) {
        out.add(r.withDeviceName(linked.name));
        continue;
      }
    }
    if (linked != null && linked.name.isNotEmpty && r.kind == TxKind.coinbase && r.outputCommits.any(theirRewards.contains)) {
      out.add(r.withDeviceName(linked.name));
      continue;
    }
    out.add(r);
  }
  for (final h in shown) {
    out.add(deviceRow(h, _nameOf(book, h), chain: spendOf[h], change: changeOf[h] ?? const []));
  }
  out.sort((a, b) => b.timeUnix.compareTo(a.timeUnix));
  return out;
}

/// Whether [r], an output of this wallet the chain check found, is the change of [h], whose
/// spend the chain check listed as [spend] (or not yet): its notice named it, it has [h]'s
/// kernel, or, for a notice that named no change, it is worth exactly what the spend leaves
/// after the amount and the fee and is no newer than the spend.
bool _isChange(TxEntry r, HeldPayment h, TxEntry? spend) {
  final kernel = r.kernelExcess;
  if (kernel != null && kernel == h.kernel) return true;
  if (h.change.isNotEmpty) return r.outputCommits.any(h.change.contains);
  final fee = h.fee;
  if (spend == null || fee == null || spend.amountCredited > BigInt.zero) return false;
  final at = r.blockHeight;
  final spentAt = spend.blockHeight;
  if (at != null && spentAt != null && at > spentAt) return false;
  return r.amountCredited == spend.amountDebited - h.amount - fee;
}

/// This device's own answers to payments the linked device answered too, once the chain shows
/// the linked device's outputs for the same payment: the sender used that answer, so these never
/// confirm. They are left out of history and cancelled quietly ([DeviceService]).
List<TxEntry> answersTakenThere(List<TxEntry> rows, DeviceBook book) {
  if (book.theirReceives.isEmpty) return const [];
  final onChain = {
    for (final r in rows)
      if (r.origin == TxOrigin.otherWallet) ...r.outputCommits,
  };
  if (onChain.isEmpty) return const [];
  return [
    for (final r in rows)
      if (r.origin == TxOrigin.thisWallet && !r.confirmed && (r.kind == TxKind.received || r.kind == TxKind.receivedCancelled))
        if (book.theirReceives[r.slateId] case final theirs? when theirs.any(onChain.contains)) r,
  ];
}

String _nameOf(DeviceBook book, HeldPayment h) => book.device(h.deviceId)?.name ?? h.deviceName ?? '';

/// The history row of [h] made on device [name]: what the chain shows of it ([chain], its
/// spend; [change], its change listed apart; its kernel's block) with the notice's details, or
/// a pending row from the notice alone.
TxEntry deviceRow(HeldPayment h, String name, {TxEntry? chain, List<TxEntry> change = const []}) {
  final made = (h.createdAt ?? h.lockedAt).millisecondsSinceEpoch ~/ 1000;
  final spent = h.amount + (h.fee ?? BigInt.zero);
  final message = h.message;
  // The change not in the spend's own row already.
  final apart = [
    for (final c in change)
      if (chain == null || !c.outputCommits.any(chain.outputCommits.contains)) c,
  ];
  final credit = apart.fold(BigInt.zero, (sum, c) => sum + c.amountCredited);
  // On chain: its spend, its change or its kernel shows, or its coins are spent.
  final onChain = chain != null || apart.isNotEmpty || h.minedHeight != null || h.state == HoldState.spent;
  final ending = onChain ? null : h.ending;
  final released = ending != null;
  // The block: its kernel's, else its change's (the spend's row is dated at the check that
  // found it).
  final heights = [for (final c in apart) ?c.blockHeight];
  final block = h.minedHeight != null
      ? BigInt.from(h.minedHeight!)
      : heights.isNotEmpty
      ? heights.reduce((a, b) => a < b ? a : b)
      : chain?.blockHeight;
  final status =
      chain?.status ??
      (onChain
          ? TxStatus.confirmed
          : released
          ? TxStatus.cancelled
          : h.state == HoldState.posted || h.kernel != null
          ? TxStatus.awaitingConfirmation
          : TxStatus.awaitingRecipient);
  return TxEntry(
    // One key from the first notice on, so the row stays the same row once the chain confirms it.
    key: deviceRowKey(h),
    slateId: h.slateId,
    kind: released ? TxKind.sentCancelled : TxKind.sent,
    status: status,
    source: TxSource.wallet,
    createdAtUnix: made,
    timeUnix: chain?.timeUnix ?? apart.firstOrNull?.timeUnix ?? made,
    confirmed: status == TxStatus.confirmed,
    blockHeight: block,
    blockTimeUnix: chain?.blockTimeUnix ?? apart.firstOrNull?.blockTimeUnix,
    amountCredited: (chain?.amountCredited ?? BigInt.zero) + credit,
    amountDebited: chain?.amountDebited ?? spent + credit,
    fee: h.fee ?? chain?.fee,
    numInputs: chain?.numInputs ?? h.commitments.length,
    numOutputs: (chain?.numOutputs ?? 0) + apart.length,
    kernelExcess: chain?.kernelExcess ?? h.kernel,
    outputCommits: [...?chain?.outputCommits, for (final c in apart) ...c.outputCommits],
    counterparty: h.counterparty,
    deviceName: name,
    deviceEnding: ending,
    deviceWhy: ending == DeviceEnding.failed ? h.why : null,
    transport: h.method,
    note: chain?.note,
    label: chain?.label,
    manualFields: chain?.manualFields ?? const {},
    manualEditedAtUnix: chain?.manualEditedAtUnix,
    messages: [if (message != null && message.isNotEmpty) SlateMessage(role: SlateRole.sender, text: message)],
    cancellable: false,
    repostable: false,
    releasable: false,
    origin: TxOrigin.linkedDevice,
    spentCommits: chain?.spentCommits ?? h.commitments,
  );
}
