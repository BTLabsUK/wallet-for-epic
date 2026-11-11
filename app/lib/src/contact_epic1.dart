// SPDX-License-Identifier: Apache-2.0
/// The epic1 link of a contact, checked by LEPIC: the contact editors (phone and desktop) and
/// epic1 Send use it. LEPIC pays only an `epic:epic1…` link that names a server; a bare epic1
/// address, or a link with no server, is an address alone and cannot be paid.
library;

import 'epic1.dart' show Epic1Wallet;
import 'l10n.dart';
import 'models.dart' show WalletError, WalletErrorKind;
import 'recipient.dart' show epic1AddressOnly, epic1Shaped;

/// What LEPIC makes of a text of epic1 shape.
enum Epic1Check {
  /// A link this wallet can pay: stored as typed.
  link,

  /// A bare epic1 address, or a link that names no server.
  addressOnly,

  /// A link or address of the other network.
  otherNetwork,

  /// A link whose servers this wallet cannot reach.
  cannotPay,

  /// Not an epic1 link or address.
  invalid,
}

/// Checks [text] with [wallet]'s `readLink`, LEPIC's own parser. A bare address is read as
/// `epic:<address>`, so a mistyped one is [Epic1Check.invalid] and a well-formed one
/// [Epic1Check.addressOnly]. With no wallet (locked) only the shape is known: a link counts.
Future<Epic1Check> checkEpic1(Epic1Wallet? wallet, String text) async {
  final t = text.trim().replaceAll(RegExp(r'\s'), '');
  if (!epic1Shaped(t)) return Epic1Check.invalid;
  final alone = epic1AddressOnly(t);
  if (wallet == null) return alone ? Epic1Check.addressOnly : Epic1Check.link;
  final link = t.toLowerCase().startsWith('epic:') ? t : 'epic:$t';
  try {
    await wallet.readLink(link);
    return alone ? Epic1Check.addressOnly : Epic1Check.link;
  } on WalletError catch (e) {
    return switch (e.kind) {
      WalletErrorKind.epic1CannotPay => alone ? Epic1Check.addressOnly : Epic1Check.cannotPay,
      WalletErrorKind.epic1WrongNetwork => Epic1Check.otherNetwork,
      _ => Epic1Check.invalid,
    };
  }
}

/// The line under the field for [check]; null for a payable link. [invalid] is the field's own
/// "not a valid address" sentence.
String? epic1CheckText(AppLocalizations l, Epic1Check check, {required String invalid}) => switch (check) {
  Epic1Check.link => null,
  Epic1Check.addressOnly => l.epic1AddressAlone,
  Epic1Check.otherNetwork => l.deskE1ErrWrongNetwork,
  Epic1Check.cannotPay => l.deskE1ErrCannotPay,
  Epic1Check.invalid => invalid,
};
