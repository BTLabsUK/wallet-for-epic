// SPDX-License-Identifier: Apache-2.0
/// Stores the payment-link pins and paid request ids in the meta file ([Meta.directoryPins],
/// [Meta.paidRequests]). The file goes with the history, so deleting the history deletes them.
library;

import '../directory/pins.dart';
import '../directory/wire.dart';
import 'meta_store.dart';

extension DirectoryPinsMeta on Meta {
  /// Records that the user paid [request] at [paidAt] (unix seconds): pins the card's listing key
  /// for its (dkey, handle), a key the user paid after the changed-wallet warning replacing the
  /// old one, and remembers the request id. Request ids older than [paidRequestKept] are dropped.
  void recordLinkPayment(Payreq request, int paidAt) {
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
  }
}
