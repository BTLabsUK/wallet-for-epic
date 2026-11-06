// SPDX-License-Identifier: Apache-2.0
/// The desktop's view of the trust policy (`trust/policy.dart`): what the wallet knows about a
/// contact's Epicbox key, and the line a contact's details show for it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../models.dart' show PairingRecord, sameEpicboxServer;
import '../../trust/contact_trust.dart';
import '../../trust/policy.dart';
import 'clock.dart';
import 'models.dart' show Contact, Tx, TxDirection, TxState;
import 'pairing_state.dart';
import 'state.dart';

/// What the wallet learned about the software behind an Epicbox [address]; null while it
/// loads or knows nothing. Asked again after every unlock, as the rows are pruned then.
final deskPeerCompatProvider = FutureProvider.autoDispose.family<PeerCompat?, String>((ref, address) {
  ref.watch(deskProvider.select((s) => s.session));
  return ref.watch(deskApiProvider).peerCompat(address);
});

/// The relationship with [contact], from its card and [pairing].
Relationship deskRelationship(Contact contact, PairingRecord? pairing) =>
    relationshipOf(inContacts: true, epicboxAddress: contact.epicbox, pairing: pairing);

/// The compatibility the policy is asked about for [contact], if a key is known.
PeerCompat? deskPeerCompatOf(WidgetRef ref, Contact contact, PairingRecord? pairing) {
  final address = trustAddressOf(contact.epicbox, pairing);
  return address == null ? null : ref.watch(deskPeerCompatProvider(address)).value;
}

/// The line a contact's details show for [contact], or none.
ContactLine deskContactLine(WidgetRef ref, Contact contact) {
  final pairing = ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(contact.id)) : null;
  return contactLine(
    deskPeerCompatOf(ref, contact, pairing),
    deskRelationship(contact, pairing),
    ref.watch(deskClockProvider)(),
    lastSealedIn: pairing?.lastSealedIn,
  );
}

/// Where desktop Send stands on the pairing route for [contact] (paired through [pairing]):
/// hidden, on, or off with the reason (`trust/policy.dart`). [watch] false reads once, for a
/// handler outside build; the screen that shows the switch watches, so the sources stay alive.
MailboxDefault deskMailboxDefaultFor(WidgetRef ref, Contact contact, PairingRecord pairing, {bool watch = true}) {
  T get<T>(ProviderListenable<T> p) => watch ? ref.watch(p) : ref.read(p);
  final now = get(deskClockProvider)();
  final sent = [
    for (final t in get(deskProvider.select((s) => s.txs)) ?? const <Tx>[])
      if (t.pairingId == pairing.id && t.direction == TxDirection.sent && t.state == TxState.waitingRecipient) t.created,
  ];
  final address = trustAddressOf(contact.epicbox, pairing);
  return mailboxDefault(
    r: deskRelationship(contact, pairing),
    opensSealed: pairing.caps.opensSealed,
    online: get(deskPairNetProvider) == DeskPairNet.online,
    compat: address == null ? null : get(deskPeerCompatProvider(address)).value,
    now: now,
    lastSealedIn: pairing.lastSealedIn,
    unansweredSince: mailboxUnansweredAmong(sent, pairing.lastSealedIn, now),
    notAnswering: pairing.notAnswering,
    relayDown: pairing.relayDown,
    relayShared: sameEpicboxServer(contact.epicbox, pairing.homeRelay),
  );
}
