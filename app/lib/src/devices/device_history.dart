/// The other devices' payments in this wallet's history: "Sent from `<device>`".
///
/// A payment another device is making shows as a pending row from its `send` notice. Once the
/// chain shows its coins spent, LEPIC's chain check lists a row of [TxOrigin.otherWallet] whose
/// `spentCommits` include them: that row becomes the device's row, with the details the notice
/// brought, so the payment never shows twice, whether its coins were held or released here.
/// A payment that ended without spending its coins stays as a cancelled row that says how
/// (released here, cancelled, failed or expired on the device) until the chain decides: a
/// payment whose cancel came too late comes back as the same row, confirmed.
library;

import '../models.dart';
import 'device_model.dart';

/// The key of the pending row for [h], before the chain shows it.
String deviceRowKey(HeldPayment h) => 'd:${h.deviceId}:${h.slateId}';

/// [rows] (this wallet's history, newest first) with the linked devices' payments of [book]
/// merged in, newest first.
List<TxEntry> mergeDeviceHistory(List<TxEntry> rows, DeviceBook book) {
  if (book.holds.isEmpty) return rows;
  // Held, ended without spending (by the device, by the fallbacks or by hand) and confirmed all
  // keep their row.
  final shown = [for (final h in book.holds) if (h.state.holds || h.state.freed || h.state == HoldState.spent) h];
  final used = <HeldPayment>{};
  final out = <TxEntry>[];
  for (final r in rows) {
    if (r.origin == TxOrigin.otherWallet && r.spentCommits.isNotEmpty) {
      // Any hold: the chain's word is final, whatever this device did with the coins. Of the
      // payments that held these coins (a coin freed by one is often taken by the next), the
      // one the chain check confirmed, else the newest.
      final h = (book.holds.where((h) => !used.contains(h) && h.commitments.any(r.spentCommits.contains)).toList()
            ..sort((a, b) => (a.state == HoldState.spent) != (b.state == HoldState.spent) ? (a.state == HoldState.spent ? -1 : 1) : b.lockedAt.compareTo(a.lockedAt)))
          .firstOrNull;
      if (h != null) {
        used.add(h);
        out.add(deviceRow(h, _nameOf(book, h), chain: r));
        continue;
      }
    }
    out.add(r);
  }
  for (final h in shown) {
    if (!used.contains(h)) out.add(deviceRow(h, _nameOf(book, h)));
  }
  out.sort((a, b) => b.timeUnix.compareTo(a.timeUnix));
  return out;
}

String _nameOf(DeviceBook book, HeldPayment h) => book.device(h.deviceId)?.name ?? h.deviceName ?? '';

/// The history row of [h] made on device [name]: [chain]'s row (amount, height, confirmations as
/// the chain shows them) with the notice's details, or a pending row from the notice alone.
TxEntry deviceRow(HeldPayment h, String name, {TxEntry? chain}) {
  final made = (h.createdAt ?? h.lockedAt).millisecondsSinceEpoch ~/ 1000;
  final spent = h.amount + (h.fee ?? BigInt.zero);
  final message = h.message;
  final ending = chain == null ? h.ending : null;
  final released = ending != null;
  return TxEntry(
    // One key from the first notice on, so the row stays the same row once the chain confirms it.
    key: deviceRowKey(h),
    slateId: h.slateId,
    kind: released ? TxKind.sentCancelled : TxKind.sent,
    status:
        chain?.status ??
        (released
            ? TxStatus.cancelled
            : h.state == HoldState.posted || h.kernel != null || h.state == HoldState.spent
            ? TxStatus.awaitingConfirmation
            : TxStatus.awaitingRecipient),
    source: TxSource.wallet,
    createdAtUnix: made,
    timeUnix: chain?.timeUnix ?? made,
    confirmed: chain?.confirmed ?? false,
    blockHeight: chain?.blockHeight,
    blockTimeUnix: chain?.blockTimeUnix,
    amountCredited: chain?.amountCredited ?? BigInt.zero,
    amountDebited: chain?.amountDebited ?? spent,
    fee: h.fee ?? chain?.fee,
    numInputs: chain?.numInputs ?? h.commitments.length,
    numOutputs: chain?.numOutputs ?? 0,
    kernelExcess: chain?.kernelExcess ?? h.kernel,
    outputCommits: chain?.outputCommits ?? const [],
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
