// SPDX-License-Identifier: Apache-2.0
/// What the screens may ask about contacts that take no payments (a directory hello flag, see
/// docs/design/directory-wire.md), without knowing the directory service. Each app overrides
/// [paymentRefusalsProvider] with its open wallet's service.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final paymentRefusalsProvider = Provider<PaymentRefusals>((ref) => const NoPaymentRefusals());
