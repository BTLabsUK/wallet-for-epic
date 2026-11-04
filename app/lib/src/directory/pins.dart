// SPDX-License-Identifier: Apache-2.0
/// What the wallet remembers of payments made from payment links: which listing key a
/// directory's (dkey, handle) pointed to when the user paid, and which requests were paid
/// (replay). Pure data and decisions; `history/directory_pins.dart` stores them in the meta
/// file, where deleting the history deletes them.
library;

import 'dart:typed_data';

import 'wire.dart';

/// How long a paid request id is kept.
const Duration paidRequestKept = Duration(days: 30);

/// What the wallet keeps of one payment made from a payment link, by its slate id: for the
/// optional receipt and the silent-payee rows. Pruned at [paidRequestKept] like the request ids.
class LinkPaymentRec {
  const LinkPaymentRec({
    required this.reqid,
    required this.dkey,
    this.label,
    required this.amount,
    required this.address,
    required this.paidAt,
    this.told = const {},
  });

  /// 16 bytes, lower-case hex.
  final String reqid;

  /// 33 bytes, lower-case hex: the directory the card came from.
  final String dkey;

  /// The card's label, when it has one.
  final String? label;

  /// Smallest unit.
  final BigInt amount;

  /// The listing address (`key@server[:port]`) the payment went to.
  final String address;

  /// Unix seconds.
  final int paidAt;

  /// Receipt stages already posted (`1` sent, `2` posted).
  final Set<int> told;

  /// The first 8 hex digits of the request id, as the receipt line shows it.
  String get shortId => reqid.length < 8 ? reqid : reqid.substring(0, 8);

  LinkPaymentRec withTold(int stage) => LinkPaymentRec(
    reqid: reqid,
    dkey: dkey,
    label: label,
    amount: amount,
    address: address,
    paidAt: paidAt,
    told: {...told, stage},
  );

  Map<String, Object?> toJson() => {
    'reqid': reqid,
    'dkey': dkey,
    if (label != null) 'label': label,
    'amount': amount.toString(),
    'address': address,
    'paid_at': paidAt,
    if (told.isNotEmpty) 'told': ([...told]..sort()),
  };

  @override
  bool operator ==(Object other) =>
      other is LinkPaymentRec &&
      other.reqid == reqid &&
      other.dkey == dkey &&
      other.label == label &&
      other.amount == amount &&
      other.address == address &&
      other.paidAt == paidAt &&
      other.told.length == told.length &&
      other.told.containsAll(told);

  @override
  int get hashCode => Object.hash(reqid, dkey, label, amount, address, paidAt, told.length);
}

/// The pin of a directory's listing: the listing key (hex) the user last paid for it.
class ListingPin {
  const ListingPin({required this.listingKey, required this.firstPaid, required this.lastPaid});

  /// 33 bytes, lower-case hex.
  final String listingKey;

  /// Unix seconds.
  final int firstPaid;
  final int lastPaid;

  Map<String, Object?> toJson() => {
    'listing_key': listingKey,
    'first_paid': firstPaid,
    'last_paid': lastPaid,
  };

  @override
  bool operator ==(Object other) =>
      other is ListingPin &&
      other.listingKey == listingKey &&
      other.firstPaid == firstPaid &&
      other.lastPaid == lastPaid;

  @override
  int get hashCode => Object.hash(listingKey, firstPaid, lastPaid);
}

/// The key of a pin: `<dkey hex>:<handle hex>`.
String pinKey(Uint8List dkey, Uint8List handle) => '${toHex(dkey)}:${toHex(handle)}';

/// How much the wallet trusts the directory a link comes from (the trust line on Send).
enum DirectoryTrust {
  /// The card's `dkey` is a directory the user pairs with.
  directoryYouUse,

  /// Any other directory: shown with the listing code only.
  notADirectoryYouUse,

  /// The user paid this (dkey, handle) before, to another listing key.
  changedWallet,
}

/// The trust line of a link and what the wallet already knows of its request.
class LinkStanding {
  const LinkStanding(this.trust, {this.paidBefore, this.changedSince});

  final DirectoryTrust trust;

  /// When this request id was paid, within the last [paidRequestKept]; null when it was not.
  final DateTime? paidBefore;

  /// For [DirectoryTrust.changedWallet]: when the user last paid the earlier listing key.
  final DateTime? changedSince;
}

DateTime _at(int seconds) => DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

/// The standing of a verified [request]. [pinnedDkeys] are the directories the user pairs with
/// (lower-case hex of the 33-byte `dkey`), [pins] the stored pins by [pinKey] and [paidRequests]
/// the paid request ids (hex) with the unix second each was paid. Changed wallet wins over the
/// directory's own standing: it is the warning that matters.
LinkStanding linkStanding(
  Payreq request, {
  required Set<String> pinnedDkeys,
  required Map<String, ListingPin> pins,
  required Map<String, int> paidRequests,
  required int nowSeconds,
}) {
  final card = request.card;
  final pin = pins[pinKey(card.dkey, card.handle)];
  final paid = paidRequests[toHex(request.reqid)];
  final cutoff = nowSeconds - paidRequestKept.inSeconds;
  final paidBefore = paid != null && paid > cutoff ? _at(paid) : null;
  if (pin != null && pin.listingKey != toHex(card.listingKey)) {
    return LinkStanding(
      DirectoryTrust.changedWallet,
      paidBefore: paidBefore,
      changedSince: _at(pin.lastPaid),
    );
  }
  return LinkStanding(
    pinnedDkeys.contains(toHex(card.dkey))
        ? DirectoryTrust.directoryYouUse
        : DirectoryTrust.notADirectoryYouUse,
    paidBefore: paidBefore,
  );
}

/// What the wallet remembers of link payments, as the meta file holds it.
class LinkMemory {
  const LinkMemory({this.pins = const {}, this.paidRequests = const {}});

  /// By [pinKey].
  final Map<String, ListingPin> pins;

  /// Paid request ids (hex) with the unix second each was paid.
  final Map<String, int> paidRequests;
}
