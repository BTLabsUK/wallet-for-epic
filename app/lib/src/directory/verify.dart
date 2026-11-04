// SPDX-License-Identifier: Apache-2.0
/// Verification of the directory records in the order of docs/design/directory-wire.md: network,
/// then signatures, then expiry and `for`; for payloads the record's own signature, an embedded
/// card's, then `bind` or `dkey`. The first failure is the error. Structure (`checksum`,
/// `malformed`) is checked by the decoders in `wire.dart`.
library;

import 'dart:typed_data';

import 'base58.dart';
import 'wire.dart';

/// Checks a K3 signature: `verifyAddressSignatureAt` of LEPIC. [publicKeyText] is the Epicbox
/// key text, [message] the signed bytes, [der] the DER signature. Injected, so tests run
/// without the library and a core without one refuses.
typedef DirectoryVerifier =
    Future<bool> Function(
      String publicKeyText,
      String domain,
      Uint8List message,
      Uint8List der,
    );

/// A verifier that refuses everything, for a core with no LEPIC.
Future<bool> refusingVerifier(String publicKeyText, String domain, Uint8List message, Uint8List der) async =>
    false;

/// Domains of LEPIC ADR 0033.
const String domainHello = 'epic-dir-hello/1';
const String domainListing = 'epic-listing/1';
const String domainListingMoved = 'epic-listing-moved/1';
const String domainPayreq = 'epic-payreq/1';
const String domainUnlist = 'epic-unlist/1';

/// Seconds a request may be past its expiry (clock skew).
const int expirySkewSeconds = 120;

Never _fail(DirectoryError e) => throw DirectoryException(e);

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Network and signature checks of a card: the card's net and the net of its address key text
/// must be [net], then its signature under `epic-listing/1` with the key in its address.
void _cardNetwork(ListingCard card, int net) {
  if (card.net != net || card.listing.net != net) _fail(DirectoryError.network);
}

Future<void> _cardSignature(ListingCard card, DirectoryVerifier verify) async {
  if (!await verify(card.listing.keyText, domainListing, card.signedBytes, card.signature!)) {
    _fail(DirectoryError.signature);
  }
}

/// A card for a wallet on [net]. Throws `network` or `signature`.
Future<ListingCard> verifyCard(ListingCard card, int net, DirectoryVerifier verify) async {
  _cardNetwork(card, net);
  await _cardSignature(card, verify);
  return card;
}

/// A payment request for a wallet on [net] at [nowSeconds] (unix). [listingKey] is this
/// wallet's listing key for the card's directory (33 bytes), null when it has none. Throws
/// `network`, `signature`, `expired` or `for_other`. Replay and changed wallets are wallet
/// state: see `pins.dart`.
Future<Payreq> verifyPayreq(
  Payreq request, {
  required int net,
  required int nowSeconds,
  Uint8List? listingKey,
  required DirectoryVerifier verifier,
}) async {
  final card = request.card;
  if (request.net != net || card.net != request.net) _fail(DirectoryError.network);
  _cardNetwork(card, request.net);
  final dkeyText = epicboxKeyText(card.dkey, request.net);
  if (!await verifier(dkeyText, domainPayreq, request.signedBytes, request.signature!)) {
    _fail(DirectoryError.signature);
  }
  await _cardSignature(card, verifier);
  if (BigInt.from(nowSeconds) > request.expires + BigInt.from(expirySkewSeconds)) {
    _fail(DirectoryError.expired);
  }
  final forKey = request.forKey;
  if (forKey != null && (listingKey == null || !_same(forKey, listingKey))) {
    _fail(DirectoryError.forOther);
  }
  return request;
}

/// A link text to a verified request: the decoders and [verifyPayreq] in one.
Future<Payreq> verifyPayreqText(
  String text, {
  required int net,
  required int nowSeconds,
  Uint8List? listingKey,
  required DirectoryVerifier verifier,
}) => verifyPayreq(
  Payreq.fromText(text),
  net: net,
  nowSeconds: nowSeconds,
  listingKey: listingKey,
  verifier: verifier,
);

/// A directory payload on a pairing of a wallet on [net]. [dkey] is the receiving directory's
/// key (type 2), [bind] the four SAS-table indexes the wallet expects (type 1). A payload of an
/// unknown type is returned unchecked: acknowledge and drop it. Throws `network`, `signature`,
/// `bind` or `dkey`.
Future<DirectoryPayload> verifyPayload(
  DirectoryPayload payload, {
  required int net,
  Uint8List? dkey,
  Uint8List? bind,
  required DirectoryVerifier verifier,
}) async {
  switch (payload) {
    case DroppedPayload():
      break;
    case DirHello():
      if (payload.net != net) _fail(DirectoryError.network);
      if (!await verifier(epicboxKeyText(payload.dkey, net), domainHello, payload.signedBytes, payload.signature!)) {
        _fail(DirectoryError.signature);
      }
      if (bind == null || !_same(payload.bind, bind)) _fail(DirectoryError.bind);
    case ListingPayload():
      _cardNetwork(payload.card, net);
      await _cardSignature(payload.card, verifier);
      if (dkey == null || !_same(payload.card.dkey, dkey)) _fail(DirectoryError.dkey);
    case UnlistPayload():
      final key = parseListingAddress(payload.address)!;
      if (payload.net != net || key.net != net) _fail(DirectoryError.network);
      if (!await verifier(key.keyText, domainUnlist, payload.signedBytes, payload.signature!)) {
        _fail(DirectoryError.signature);
      }
    case MovedPayload():
      final key = parseListingAddress(payload.oldAddress)!;
      if (payload.net != net || key.net != net) _fail(DirectoryError.network);
      _cardNetwork(payload.card, net);
      if (!await verifier(key.keyText, domainListingMoved, payload.signedBytes, payload.signature!)) {
        _fail(DirectoryError.signature);
      }
      await _cardSignature(payload.card, verifier);
    case UnlistedPayload() || ReceiptPayload():
      break;
  }
  return payload;
}
