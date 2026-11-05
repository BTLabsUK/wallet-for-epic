// SPDX-License-Identifier: Apache-2.0
/// What the screens may ask about contacts that take no payments (the profile word of a paired
/// contact's card, see docs/design/peer-profile.md), without knowing where the pairings come
/// from. Each app overrides [paymentRefusalsProvider] with [PairingRefusals] over its pairings.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart' show PairingRecord, epicboxKey;
import '../trust/policy.dart' show profileNoPayments, statedNoPayments;

abstract class PaymentRefusals {
  /// Whether the contact of [pairingId], or the contact with the Epicbox [address] (matched on
  /// its key part, as `epicboxKey` does), takes no payments.
  bool refusesPayments({String? pairingId, String? address});

  /// The contact name the wallet last showed for the one that [refusesPayments], else null:
  /// what "‹name› takes no payments." says.
  String? refusedName({String? pairingId, String? address});
}

/// Refuses none: the default, and what a locked wallet has.
class NoPaymentRefusals implements PaymentRefusals {
  const NoPaymentRefusals();

  @override
  bool refusesPayments({String? pairingId, String? address}) => false;

  @override
  String? refusedName({String? pairingId, String? address}) => null;
}

/// The refusals the pairings say: a contact whose card's profile word has
/// [profileNoPayments] set. A new one per list of records, so a screen that watches the
/// provider rebuilds when a card changes.
class PairingRefusals implements PaymentRefusals {
  const PairingRefusals(this.pairings);

  final List<PairingRecord> pairings;

  @override
  bool refusesPayments({String? pairingId, String? address}) => _refusing(pairingId, address) != null;

  @override
  String? refusedName({String? pairingId, String? address}) => _refusing(pairingId, address)?.shownName;

  PairingRecord? _refusing(String? pairingId, String? address) {
    final refusing = pairings.where((p) => statedNoPayments(p.peerProfile));
    if (pairingId != null) {
      final byPairing = refusing.where((p) => p.id == pairingId).firstOrNull;
      if (byPairing != null) return byPairing;
    }
    if (address == null || address.trim().isEmpty) return null;
    final key = epicboxKey(address);
    return refusing.where((p) => p.paymentsAddress != null && epicboxKey(p.paymentsAddress!) == key).firstOrNull;
  }
}

final paymentRefusalsProvider = Provider<PaymentRefusals>((ref) => const NoPaymentRefusals());
