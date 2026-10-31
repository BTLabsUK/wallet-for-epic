// SPDX-License-Identifier: Apache-2.0
/// The coins a linked device is spending, one sum for the phone and the desktop (T-04): the
/// core can spend them, but this wallet holds them back, so the balance shows them as locked.
library;

import '../models.dart';
import '../wallet_service.dart' show WalletSession;

/// What the unspent spendable outputs of [session] whose commitment is in [held] are worth.
/// Zero without reading the outputs when [held] is empty. Throws what reading them throws.
Future<BigInt> heldSpendable(WalletSession session, Set<String> held) async {
  if (held.isEmpty) return BigInt.zero;
  return (await session.outputs())
      .where((o) => o.status == WalletOutputStatus.unspent && o.category == OutputCategory.spendable && held.contains(o.commitment))
      .fold<BigInt>(BigInt.zero, (sum, o) => sum + o.value);
}
