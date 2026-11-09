// SPDX-License-Identifier: Apache-2.0
import '../l10n.dart';
import '../models.dart' show TxEntry;
import '../recipient.dart';
import 'method_icons.dart';

/// The phone names a payment method through `ui/method_icons.dart` (the one source):
/// Epicbox, Link · HTTP, Link · Tor or Direct · File Transfer. These map LEPIC's transport
/// words and an address's kind to the method.

/// The method behind the transport LEPIC names (`epicbox`, `http`, `tor`, `file`); null for
/// one it does not know.
MethodKind? methodKindOfTransport(String? transport) => switch (transport) {
  'epicbox' => MethodKind.epicbox,
  'http' => MethodKind.linkHttp,
  'tor' => MethodKind.linkTor,
  'file' => MethodKind.directFile,
  _ => null,
};

/// The name of a method as LEPIC names its transport (`epicbox`, `http`, `tor`, `file`), or
/// "Unknown".
String txMethodWord(AppLocalizations l, String? transport) {
  final m = methodKindOfTransport(transport);
  return m == null ? l.txMethodUnknown : MethodIcons.fullName(l, m);
}

/// The name of the method [tx] went by: an epic1 exchange by its own name (epic1 link, In
/// person), else [txMethodWord] of its transport.
String txMethodName(AppLocalizations l, TxEntry tx) =>
    tx.epic1Via == null ? txMethodWord(l, tx.transport) : MethodIcons.epic1Name(l, tx.epic1Via!);

/// The name of the method an address is reached by.
String recipientMethodWord(AppLocalizations l, RecipientKind kind) => MethodIcons.fullName(l, MethodKind.ofRecipient(kind));
