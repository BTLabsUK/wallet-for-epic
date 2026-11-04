// SPDX-License-Identifier: Apache-2.0
/// What Send makes of a payment link: the checks of the spec's §5.3 (network, signatures, expiry,
/// `for`, paid before) and the standing that the trust line shows. Pure: the verifier, the clock,
/// the membership and the pins come in.
library;


import 'base58.dart';
import 'codes.dart';
import 'membership.dart';
import 'pins.dart';
import 'verify.dart';
import 'wire.dart';

/// Why a link opens nothing.
enum LinkRefusal {
  /// Not a payment link (checksum or structure).
  notALink,

  /// Made for the other network.
  network,

  /// A signature does not hold.
  changed,

  expired,

  /// Made for another payer.
  forOther,
}

sealed class LinkOutcome {
  const LinkOutcome();
}

final class LinkRefused extends LinkOutcome {
  const LinkRefused(this.reason, {this.expiredAt, this.madeFor});

  final LinkRefusal reason;

  /// For [LinkRefusal.expired].
  final DateTime? expiredAt;

  /// For [LinkRefusal.network]: the network the link was made for ([netMainnet] or [netFloonet]).
  final int? madeFor;
}

/// A verified link, ready to fill Send.
final class LinkOpened extends LinkOutcome {
  const LinkOpened({required this.request, required this.standing, this.directoryLabel, this.payeeLabel});

  final Payreq request;
  final LinkStanding standing;

  /// The directory contact's label, when the directory is one this wallet uses.
  final String? directoryLabel;

  /// The request's `@name`, shown only when the directory is one this wallet uses.
  final String? payeeLabel;

  /// This request was paid before ([LinkStanding.paidBefore]): Send asks first.
  bool get alreadyPaid => standing.paidBefore != null;

  /// The listing code of the card's key, four table indexes.
  List<int> get listingCode => listingCodeIndexes(request.card.listingKey);
}

/// Opens the link that decoded to [request], or failed to with [error] (`checksum` or
/// `malformed`). [net] is the wallet's network, [nowSeconds] unix time.
Future<LinkOutcome> openLink({
  Payreq? request,
  DirectoryError? error,
  required int net,
  required int nowSeconds,
  required DirectoryVerifier verifier,
  required DirectoryMembership membership,
  required LinkMemory memory,
}) async {
  if (request == null) return const LinkRefused(LinkRefusal.notALink);
  final dkeyHex = toHex(request.card.dkey);
  final forKeyText = membership.listingKeyFor(dkeyHex);
  final forKey = forKeyText == null ? null : parseEpicboxKeyText(forKeyText)?.$2;
  try {
    await verifyPayreq(request, net: net, nowSeconds: nowSeconds, listingKey: forKey, verifier: verifier);
  } on DirectoryException catch (e) {
    return switch (e.error) {
      DirectoryError.network => LinkRefused(LinkRefusal.network, madeFor: request.net),
      DirectoryError.signature => const LinkRefused(LinkRefusal.changed),
      DirectoryError.expired => LinkRefused(
        LinkRefusal.expired,
        expiredAt: DateTime.fromMillisecondsSinceEpoch(request.expires.toInt() * 1000),
      ),
      DirectoryError.forOther => const LinkRefused(LinkRefusal.forOther),
      _ => const LinkRefused(LinkRefusal.notALink),
    };
  }
  final label = membership.labelFor(dkeyHex);
  final inUse = label != null || forKeyText != null;
  final standing = linkStanding(
    request,
    pinnedDkeys: inUse ? {dkeyHex} : const {},
    pins: memory.pins,
    paidRequests: memory.paidRequests,
    nowSeconds: nowSeconds,
  );
  final shown = standing.trust == DirectoryTrust.directoryYouUse;
  return LinkOpened(
    request: request,
    standing: standing,
    directoryLabel: shown ? label : null,
    payeeLabel: shown ? request.label : null,
  );
}
