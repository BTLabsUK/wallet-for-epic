// SPDX-License-Identifier: Apache-2.0
/// Stores the payment-link pins and paid request ids in the meta file ([Meta.directoryPins],
/// [Meta.paidRequests]). The file goes with the history, so deleting the history deletes them.
library;

import '../directory/pins.dart';
import '../directory/receipts.dart' show LinkPaymentRecords;
import '../directory/wire.dart';
import 'meta_store.dart';

extension DirectoryPinsMeta on Meta {
  /// Records that the user paid [request] at [paidAt] (unix seconds): pins the card's listing key
  /// for its (dkey, handle), a key the user paid after the changed-wallet warning replacing the
  /// old one, and remembers the request id. Request ids older than [paidRequestKept] are dropped.
  ///
  /// With [txId] (the slate id) it also keeps a [LinkPaymentRec] under it, for the receipt line
  /// and the silent-payee rows; those are pruned at the same age, by their `paidAt`.
  void recordLinkPayment(Payreq request, int paidAt, {String? txId}) {
    final card = request.card;
    final key = pinKey(card.dkey, card.handle);
    final listing = toHex(card.listingKey);
    final old = directoryPins[key];
    directoryPins[key] = ListingPin(
      listingKey: listing,
      firstPaid: old != null && old.listingKey == listing ? old.firstPaid : paidAt,
      lastPaid: paidAt,
    );
    paidRequests[toHex(request.reqid)] = paidAt;
    final cutoff = paidAt - paidRequestKept.inSeconds;
    paidRequests.removeWhere((_, at) => at <= cutoff);
    if (txId != null) {
      final told = linkPayments[txId]?.told;
      linkPayments[txId] = LinkPaymentRec(
        reqid: toHex(request.reqid),
        dkey: toHex(card.dkey),
        label: request.label,
        amount: request.amount,
        address: card.address,
        paidAt: paidAt,
        told: told ?? const {},
      );
    }
    linkPayments.removeWhere((_, r) => r.paidAt <= cutoff);
  }
}

/// [LinkPaymentRecords] over the meta file of the open wallet.
class MetaLinkPayments implements LinkPaymentRecords {
  MetaLinkPayments(this.store, {this.onChange});

  final MetaStore store;

  /// Called after a change, so the lines that read the records rebuild.
  final void Function()? onChange;

  @override
  LinkPaymentRec? of(String slateId) => store.snapshot.linkPayments[slateId];

  @override
  Future<void> markTold(String slateId, int stage) async {
    await store.update((m) {
      final r = m.linkPayments[slateId];
      if (r != null) m.linkPayments[slateId] = r.withTold(stage);
    });
    onChange?.call();
  }
}
