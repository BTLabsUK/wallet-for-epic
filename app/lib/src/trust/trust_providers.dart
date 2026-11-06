// SPDX-License-Identifier: Apache-2.0
/// The phone's view of the trust policy: what the wallet knows about a contact's Epicbox key,
/// and the line its contact page shows for it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

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

/// Where Send stands on the pairing route for [contact] (paired through [pairing]): hidden,
/// on, or off with the reason (`trust/policy.dart`). [watch] false reads once, for a handler
/// outside build; the screen that shows the switch watches, so the sources stay alive.
MailboxDefault mailboxDefaultFor(WidgetRef ref, Contact contact, PairingRecord pairing, {bool watch = true}) {
  T get<T>(ProviderListenable<T> p) => watch ? ref.watch(p) : ref.read(p);
  final address = trustAddressOf(contact.epicbox, pairing);
  final compat = address == null ? null : get(peerCompatProvider(address)).value;
  final now = get(clockProvider)();
  final txs = get(homeProvider).value?.transactions ?? const <TxEntry>[];
  return mailboxDefault(
    r: relationshipOf(inContacts: true, epicboxAddress: contact.epicbox, pairing: pairing),
    opensSealed: pairing.caps.opensSealed,
    online: get(pairNetProvider) == PairNet.online,
    compat: compat,
    now: now,
    lastSealedIn: pairing.lastSealedIn,
    unansweredSince: mailboxUnansweredSince(txs, pairing.id, pairing.lastSealedIn, now),
    notAnswering: pairing.notAnswering,
    relayDown: pairing.relayDown,
    relayShared: sameEpicboxServer(contact.epicbox, pairing.homeRelay),
  );
}
