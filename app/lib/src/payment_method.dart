// SPDX-License-Identifier: Apache-2.0
/// The payment methods, by family (the model of 2026-10-25): Epicbox · Link (Link · HTTP,
/// Link · Tor) · Direct (Direct · QR Payment, Direct · File Transfer). Pure Dart: the settings
/// model (`payment_prefs.dart`) and the gate (`network_gate.dart`) read it; the icons and
/// names are `ui/method_icons.dart`, which re-exports it.
library;

import 'recipient.dart' show RecipientKind;

/// A payment method, by family.
enum MethodKind {
  epicbox(MethodFamily.epicbox),
  linkHttp(MethodFamily.link),
  linkTor(MethodFamily.link),
  directQr(MethodFamily.direct),
  directFile(MethodFamily.direct);

  const MethodKind(this.family);

  final MethodFamily family;

  /// The method an address of [kind] is paid through; null for an epic1 link, which is paid
  /// in epic1 mode, not through a method.
  static MethodKind? ofRecipient(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => MethodKind.epicbox,
    RecipientKind.http => MethodKind.linkHttp,
    RecipientKind.tor => MethodKind.linkTor,
    RecipientKind.epic1 => null,
  };
}

/// The three families: Epicbox (a relay holds the payment), Link (straight to their wallet
/// over the network), Direct (hand to hand: a QR code or a file, no network).
enum MethodFamily { epicbox, link, direct }
