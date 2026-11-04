// SPDX-License-Identifier: Apache-2.0
/// The records of payments made from payment links, apart from the receipt providers so the
/// wallet core (bin/core_check.dart) reads them without Flutter.
library;

import 'pins.dart';

/// The records of payments made from links, by slate id. The meta file holds them
/// (`Meta.linkPayments`); [MemoryLinkPayments] stands in until the wallet is wired.
abstract class LinkPaymentRecords {
  LinkPaymentRec? of(String slateId);

  /// Remembers that the receipt of [stage] was posted for [slateId].
  Future<void> markTold(String slateId, int stage);
}

class MemoryLinkPayments implements LinkPaymentRecords {
  MemoryLinkPayments([Map<String, LinkPaymentRec>? records]) : records = records ?? {};

  final Map<String, LinkPaymentRec> records;

  @override
  LinkPaymentRec? of(String slateId) => records[slateId];

  @override
  Future<void> markTold(String slateId, int stage) async {
    final r = records[slateId];
    if (r != null) records[slateId] = r.withTold(stage);
  }
}
