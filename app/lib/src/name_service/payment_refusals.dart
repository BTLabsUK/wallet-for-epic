// SPDX-License-Identifier: Apache-2.0
/// What the screens may ask about contacts that take no payments (a name service hello flag, see
/// docs/design/name-service-wire.md), without knowing the name service service. Each app overrides
/// [paymentRefusalsProvider] with its open wallet's service.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart' show epicboxKey;
import 'name_service_model.dart';

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

/// The refusals the flags in a [NameServiceBook] say. A new one per book, so a screen that
/// watches the provider rebuilds when a flag changes.
class BookRefusals implements PaymentRefusals {
  const BookRefusals(this.book);

  final NameServiceBook book;

  @override
  bool refusesPayments({String? pairingId, String? address}) => _refusing(pairingId, address) != null;

  @override
  String? refusedName({String? pairingId, String? address}) => _refusing(pairingId, address)?.label;

  NameServiceEntry? _refusing(String? pairingId, String? address) {
    final byPairing = pairingId == null ? null : book.byPairing(pairingId);
    if (byPairing != null && byPairing.noPayments) return byPairing;
    if (address == null || address.trim().isEmpty) return null;
    final key = epicboxKey(address);
    return book.entries.values.where((e) => e.noPayments && e.paymentsKey == key).firstOrNull;
  }
}

final paymentRefusalsProvider = Provider<PaymentRefusals>((ref) => const NoPaymentRefusals());
