// SPDX-License-Identifier: Apache-2.0
/// The optional receipt for a payment made from a payment link: a type 5 payload posted to the
/// directory the card came from, once per stage, only when the user ticks the line. The directory
/// service implements [DirectoryReceipts]; until then the default tells nothing, so no receipt
/// line shows.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_payments.dart';
import 'pins.dart';
import 'wire.dart';

export 'link_payments.dart';

/// The wallet's way to the directories it is paired with.
abstract class DirectoryReceipts {
  /// Whether a receipt can reach the directory [dkeyHex] (a pairing exists and is usable).
  bool canTell(String dkeyHex);

  /// The directory's name for the card, shown as the payee; null when it has none.
  String? labelFor(String dkeyHex);

  /// Posts the payload bytes to the directory contact. True when it was handed over.
  Future<bool> post(String dkeyHex, Uint8List payload);
}

/// Tells nothing: no directory is paired.
class NoDirectoryReceipts implements DirectoryReceipts {
  const NoDirectoryReceipts();

  @override
  bool canTell(String dkeyHex) => false;

  @override
  String? labelFor(String dkeyHex) => null;

  @override
  Future<bool> post(String dkeyHex, Uint8List payload) async => false;
}

final directoryReceiptsProvider = Provider<DirectoryReceipts>((ref) => const NoDirectoryReceipts());

final linkPaymentRecordsProvider = Provider<LinkPaymentRecords>((ref) => MemoryLinkPayments());

/// Bumped when a record changes, so the lines that read it rebuild.
class LinkPaymentTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final linkPaymentTickProvider = NotifierProvider<LinkPaymentTick, int>(LinkPaymentTick.new);

/// The record of the payment [slateId], or null for a payment not made from a link.
final linkPaymentProvider = Provider.family<LinkPaymentRec?, String>((ref, slateId) {
  ref.watch(linkPaymentTickProvider);
  return ref.watch(linkPaymentRecordsProvider).of(slateId);
});

/// The receipt line's state for a payment.
class ReceiptLineState {
  const ReceiptLineState({required this.stage, required this.told});

  /// `1` sent, `2` posted (went to the network).
  final int stage;

  /// The receipt of [stage] was posted: the line reads as done.
  final bool told;
}

/// The line to show for [rec], or null when none: the directory cannot be told, or the payment
/// is not at a stage yet. [posted]: the payment was finalized and posted.
ReceiptLineState? receiptLineOf(DirectoryReceipts receipts, LinkPaymentRec? rec, {required bool posted}) {
  if (rec == null || !receipts.canTell(rec.dkey)) return null;
  final stage = posted ? 2 : 1;
  return ReceiptLineState(stage: stage, told: rec.told.contains(stage));
}

final Set<String> _inFlight = {};

/// Posts the receipt of [stage] for the payment [slateId] once. [at] is the unix second of the
/// stage (sent: the payment's, posted: when it went to the network). False when it was not
/// posted: no record, not tellable, already told, a post under way, or the directory refused.
Future<bool> tellPayee({
  required DirectoryReceipts receipts,
  required LinkPaymentRecords records,
  required String slateId,
  required int stage,
  required int at,
}) async {
  final rec = records.of(slateId);
  if (rec == null || !receipts.canTell(rec.dkey) || rec.told.contains(stage)) return false;
  final flight = '$slateId:$stage';
  if (!_inFlight.add(flight)) return false;
  try {
    final payload = ReceiptPayload.encode(
      reqid: fromHex(rec.reqid),
      stage: stage,
      amount: rec.amount,
      at: at,
    );
    if (!await receipts.post(rec.dkey, payload)) return false;
    await records.markTold(slateId, stage);
    return true;
  } finally {
    _inFlight.remove(flight);
  }
}

/// What a status label is given for the payee of a payment link that has no name, so the
/// 24 hour and 7 day words still show.
const String linkPayeeUnnamed = '';

/// The name to show for the payee: the directory's, else the one on the link.
String? linkPayeeName(DirectoryReceipts receipts, LinkPaymentRec rec) =>
    receipts.labelFor(rec.dkey) ?? rec.label;

/// The unix second a receipt of [stage] carries: the payment's for `1`, the time it went to the
/// network (the finalize) for `2`.
int receiptAt(LinkPaymentRec rec, int stage, int? finalizedAtUnix) =>
    stage == 2 ? (finalizedAtUnix ?? rec.paidAt) : rec.paidAt;

/// The saved Epicbox address of the contact that is the payee's, or null: the one whose key is
/// the key of the listing address the payment went to.
String? contactEpicboxFor(LinkPaymentRec rec, Iterable<String?> epicboxes) {
  final key = rec.address.split('@').first.toLowerCase();
  for (final a in epicboxes) {
    if (a != null && a.contains('@') && a.split('@').first.toLowerCase() == key) return a;
  }
  return null;
}
