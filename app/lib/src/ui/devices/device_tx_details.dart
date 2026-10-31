// SPDX-License-Identifier: Apache-2.0
/// Lines about another linked device's payments: the details themselves are the shared
/// `TxDetailsScreen` (UP-007).
library;

import '../../devices/device_providers.dart';
import '../../l10n.dart';

/// The device a held coin's payment belongs to, for Outputs: "Held by Desktop's payment".
String? heldByLine(AppLocalizations l, DeviceView? view, String commitment) {
  if (view == null) return null;
  final h = holdOf(view.book, commitment);
  return h == null ? null : l.devicesHeldBy(view.nameOf(h.deviceId));
}
