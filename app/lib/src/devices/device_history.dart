/// The other devices' payments in this wallet's history: "Sent from `<device>`".
///
/// A payment another device is making shows as a pending row from its `send` notice. Once the
/// chain shows its coins spent, LEPIC's chain check lists a row of [TxOrigin.otherWallet] whose
/// `spentCommits` include them: that row becomes the device's row, with the details the notice
/// brought, so the payment never shows twice. Coins freed without being spent show nothing.
library;

import '../models.dart';
import 'device_model.dart';

/// The key of the pending row for [h], before the chain shows it.
String deviceRowKey(HeldPayment h) => 'd:${h.deviceId}:${h.slateId}';

/// [rows] (this wallet's history, newest first) with the linked devices' payments of [book]
/// merged in, newest first.
List<TxEntry> mergeDeviceHistory(List<TxEntry> rows, DeviceBook book) {
  final shown = [for (final h in book.holds) if (h.state.holds || h.state == HoldState.spent) h];
  if (shown.isEmpty) return rows;
  final used = <HeldPayment>{};
  final out = <TxEntry>[];
  for (final r in rows) {
    if (r.origin == TxOrigin.otherWallet && r.spentCommits.isNotEmpty) {
      final h = shown.where((h) => !used.contains(h) && h.commitments.any(r.spentCommits.contains)).firstOrNull;
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
  return TxEntry(
    key: chain?.key ?? deviceRowKey(h),
    slateId: h.slateId,
    kind: TxKind.sent,
    status: chain?.status ?? (h.state == HoldState.posted || h.kernel != null || h.state == HoldState.spent ? TxStatus.awaitingConfirmation : TxStatus.awaitingRecipient),
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
