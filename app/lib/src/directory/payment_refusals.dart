// SPDX-License-Identifier: Apache-2.0
/// What the screens may ask about contacts that take no payments (a directory hello flag, see
/// docs/design/directory-wire.md), without knowing the directory service. Each app overrides
/// [paymentRefusalsProvider] with its open wallet's service.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart' show epicboxKey;
import 'directory_model.dart';

abstract class PaymentRefusals {
  /// Whether the contact of [pairingId], or the contact with the Epicbox [address] (matched on
  /// its key part, as `epicboxKey` does), takes no payments.
  bool refusesPayments({String? pairingId, String? address});
}

/// Refuses none: the default, and what a locked wallet has.
class NoPaymentRefusals implements PaymentRefusals {
  const NoPaymentRefusals();

  @override
  bool refusesPayments({String? pairingId, String? address}) => false;
}

/// The refusals the flags in a [DirectoryBook] say. A new one per book, so a screen that
/// watches the provider rebuilds when a flag changes.
class BookRefusals implements PaymentRefusals {
  const BookRefusals(this.book);

  final DirectoryBook book;

  @override
  bool refusesPayments({String? pairingId, String? address}) {
    if (pairingId != null && (book.byPairing(pairingId)?.noPayments ?? false)) return true;
    if (address == null || address.trim().isEmpty) return false;
    final key = epicboxKey(address);
    return book.entries.values.any((e) => e.noPayments && e.paymentsKey == key);
  }
}

final paymentRefusalsProvider = Provider<PaymentRefusals>((ref) => const NoPaymentRefusals());
