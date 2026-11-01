// SPDX-License-Identifier: Apache-2.0
/// The phone's view of the trust policy: what the wallet knows about a contact's Epicbox key,
/// and the line its contact page shows for it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../models.dart';
import '../pairing_providers.dart';
import '../providers.dart';
import '../settings.dart' show clockProvider;
import 'contact_trust.dart';
import 'policy.dart';

/// What the wallet learned about the software behind an Epicbox [address]; null while it
/// loads or knows nothing. Asked again after every open, as the rows are pruned then.
final peerCompatProvider = FutureProvider.autoDispose.family<PeerCompat?, String>((ref, address) {
  ref.watch(sessionProvider);
  return ref.watch(walletServiceProvider).peerCompat(address);
});

/// The relationship with the contact [contactId], from the address book and its pairing.
Relationship contactRelationship(Ref ref, Contact? contact, PairingRecord? pairing) =>
    relationshipOf(inContacts: contact != null, epicboxAddress: contact?.epicbox, pairing: pairing);

/// The contact page's line for [contactId]: none while nothing is known, or the contact is gone.
final contactLineProvider = Provider.autoDispose.family<ContactLine, String>((ref, contactId) {
  final contact = (ref.watch(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == contactId).firstOrNull;
  if (contact == null) return const ContactLine.none();
  final pairing = ref.watch(pairingSupportedProvider) ? ref.watch(contactPairingProvider(contactId)) : null;
  final address = trustAddressOf(contact.epicbox, pairing);
  final compat = address == null ? null : ref.watch(peerCompatProvider(address)).value;
  return contactLine(
    compat,
    contactRelationship(ref, contact, pairing),
    ref.watch(clockProvider)(),
    lastSealedIn: pairing?.lastSealedIn,
  );
});

/// Whether Send offers the pairing mailbox route for [contact] (paired through [pairing]):
/// not while the contact page shows a trust line for it.
bool mailboxRouteOffered(WidgetRef ref, Contact contact, PairingRecord pairing) {
  final address = trustAddressOf(contact.epicbox, pairing);
  final compat = address == null ? null : ref.watch(peerCompatProvider(address)).value;
  return mayOfferMailboxRoute(
    compat,
    relationshipOf(inContacts: true, epicboxAddress: contact.epicbox, pairing: pairing),
    ref.watch(clockProvider)(),
    lastSealedIn: pairing.lastSealedIn,
  );
}
