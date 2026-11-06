// SPDX-License-Identifier: Apache-2.0
/// The label a user gives a contact: what kind of party it is, for display only. It is local to
/// the user: never sent to the peer, never in a LEPIC call, and no code branches on it except to
/// draw it. Stored on the address book entry as an optional key `label`, written only when it is
/// not [ContactLabel.wallet]; a missing or unknown value reads as [ContactLabel.wallet].
library;

enum ContactLabel {
  /// The default: shows nothing in lists.
  wallet,
  exchange,
  vendor,
  service;

  /// The stored value; null for the default, which is never written.
  String? get stored => this == wallet ? null : name;

  /// The label a stored value names; anything else is the default.
  static ContactLabel fromStored(Object? value) {
    if (value is! String) return ContactLabel.wallet;
    for (final l in const [exchange, vendor, service]) {
      if (l.name == value) return l;
    }
    return ContactLabel.wallet;
  }
}
