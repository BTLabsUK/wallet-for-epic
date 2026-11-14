// SPDX-License-Identifier: Apache-2.0
/// The phone's pairing state (RFC 0002): the open wallet's [PairingApi], its records, the
/// requests that came to its address, its events, and what the screens need around them.
/// Empty while the wallet is locked or its core does not pair, so nothing pairing-related
/// shows then. Pairing is on for everyone: there is no switch.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart' show NetworkMode;
import 'contact_check.dart' show contactsInFlight;
import 'contacts.dart';
import 'log.dart' show logWarn;
import 'name_service/payment_refusals.dart' show PairingRefusals, PaymentRefusals;
import 'pairing_text.dart' show pairingName, pairingStrings, unnamedPeerName;
import 'providers.dart';
import 'settings.dart';
import 'settings_file/settings_providers.dart' show hostSettingsProvider;
import 'trust/policy.dart';
import 'wallet_service.dart';

export 'pairing_text.dart' show pairingName;

/// The open wallet when it handles invoices, else null: every invoice provider, screen and
/// notice reads it. What arrives is each contact's Allow invoices, in LEPIC.
final invoiceSessionProvider = Provider<WalletSession?>((ref) {
  final session = ref.watch(sessionProvider);
  return session != null && session.supportsInvoices ? session : null;
});

/// Whether invoices show: [invoiceSessionProvider] has a wallet.
final invoicesShownProvider = Provider<bool>((ref) => ref.watch(invoiceSessionProvider) != null);

/// The open wallet's pairing, or [NoPairing] while locked or on a core without it.
final pairingApiProvider = Provider<PairingApi>((ref) {
  final session = ref.watch(sessionProvider);
  final api = session?.pairing ?? const NoPairing();
  api.setConnectionServers(ref.watch(hostSettingsProvider.select((s) => s.pairingServers)));
  return api;
});

/// Whether this wallet pairs: the screens show Pair, the Pairing block and the trust badges.
final pairingSupportedProvider = Provider<bool>((ref) => ref.watch(pairingApiProvider).supported);

/// What reaches the relays now, for pairing (RFC 8.7): online, off by the network mode (Node
/// only, Kill switch: [PairNet.offline]), or Epicbox off. By hand works in all three.
enum PairNet { online, offline, epicboxOff }

final pairNetProvider = Provider<PairNet>((ref) {
  if (ref.watch(networkModeProvider.select((m) => m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch))) return PairNet.offline;
  final epicbox = ref.watch(appSettingsProvider.select((s) => s.value?.payments.epicbox)) ?? true;
  return epicbox ? PairNet.online : PairNet.epicboxOff;
});

/// Now, for countdowns. Tests and the tour override it.
final pairingClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Every pairing of the open wallet, newest first; reloads on every pairing event.
final pairingsProvider = AsyncNotifierProvider<PairingsNotifier, List<PairingRecord>>(PairingsNotifier.new);

class PairingsNotifier extends AsyncNotifier<List<PairingRecord>> {
  @override
  Future<List<PairingRecord>> build() async {
    final api = ref.watch(pairingApiProvider);
    if (!api.supported) return const [];
    // A payment through a contact starting or finishing changes `awaiting`, with no pairing event.
    ref.watch(
      homeProvider.select(
        (h) => [
          for (final t in h.value?.transactions ?? const <TxEntry>[])
            if (t.pairingId != null) '${t.key}:${t.status.name}',
        ].join(','),
      ),
    );
    final sub = api.events().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return api.pairings();
  }

  /// Reads the records again (after a call that changed one).
  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Disposed meanwhile (the screen closed): nothing to show it to.
    }
  }
}

/// [PairingRefusals] over the open wallet's pairings, for [paymentRefusalsProvider]; none while
/// they load.
final pairingRefusalsProvider = Provider<PaymentRefusals>((ref) => PairingRefusals(ref.watch(pairingsProvider).value ?? const []));

/// The requests to pair that came to this wallet's address, from contacts only, newest first;
/// reloads on every pairing event and when the address book loads. A request from someone not
/// in Contacts is dismissed ([dismissStrangers]) and never listed, but only once the book is
/// known: while it loads or is closed, every request is kept and none is listed.
final pairRequestsProvider = AsyncNotifierProvider<PairRequestsNotifier, List<PairRequest>>(PairRequestsNotifier.new);

class PairRequestsNotifier extends AsyncNotifier<List<PairRequest>> {
  @override
  Future<List<PairRequest>> build() async {
    final api = ref.watch(pairingApiProvider);
    if (!api.supported) return const [];
    final sub = api.events().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    final keys = phoneContactKeys(ref.watch(contactsProvider), closed: !(ref.watch(sessionProvider)?.contactsAvailable ?? true));
    final all = await api.requests();
    if (keys == null) return const [];
    unawaited(dismissStrangers(api, keys, all, passOn: ref.read(requestPassOnProvider).run));
    return requestsFromContacts(all, keys).reversed.toList();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Disposed meanwhile (the screen closed): nothing to show it to.
    }
  }
}

/// The Epicbox keys of [contacts] that have an address.
Set<String> contactKeysOf(Iterable<Contact> contacts) => {
  for (final c in contacts)
    if (c.epicbox case final a? when a.trim().isNotEmpty) epicboxKey(a),
};

/// The Epicbox keys of the phone's address book, or null while it is unknown: still loading,
/// failed to load, or [closed] (the shared book has no key for this wallet yet).
Set<String>? phoneContactKeys(AsyncValue<List<Contact>> contacts, {bool closed = false}) =>
    closed || !contacts.hasValue ? null : contactKeysOf(contacts.value!);

/// Whether the request that just arrived ([e]) is from a contact, by [contactKeys]; null keys
/// (the book not known yet) count as no. Nothing is dismissed here: the requests list does that
/// once the book is known ([dismissStrangers]), so a request that came before the book loaded
/// is kept.
bool requestFromContact(Set<String>? contactKeys, PairingEvent e) {
  final sender = e.sender;
  if (e.kind != PairingEventKind.requested || sender == null || e.requestId == null || contactKeys == null) return false;
  return contactKeys.contains(epicboxKey(sender));
}

/// Dismisses the requests of [all] whose sender is not in Contacts ([contactKeys], the book
/// known), as the plan has it: strangers never show. Each goes first to [passOn] (the linked
/// device, whose address book may hold the sender), then is dismissed here.
Future<void> dismissStrangers(
  PairingApi api,
  Set<String> contactKeys,
  Iterable<PairRequest> all, {
  Future<void> Function(PairRequest request)? passOn,
}) async {
  for (final r in all) {
    if (contactKeys.contains(epicboxKey(r.fromAddress))) continue;
    if (passOn != null) {
      try {
        await passOn(r);
      } on Object {
        // Not passed on: it is still dismissed here, as without a linked device.
      }
    }
    try {
      await api.dismissRequest(r.id);
    } on Object {
      // Gone already: nothing to hide.
    }
  }
}

/// Where a request this device is about to dismiss goes first: the linked device's service
/// sets [run] while Linked devices is on (address books are per device, so the sender may be
/// a contact there). Shared by the phone and the desktop.
class RequestPassOn {
  Future<void> Function(PairRequest request)? run;
}

final requestPassOnProvider = Provider<RequestPassOn>((ref) => RequestPassOn());

/// The contact a request came from, by the key of its address, or null.
Contact? contactOfRequest(Iterable<Contact> contacts, PairRequest r) {
  final key = epicboxKey(r.fromAddress);
  return contacts.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull;
}

/// The pairing the address-book contact [contactId] uses ([contactPairingOf]), or null.
final contactPairingProvider = Provider.family<PairingRecord?, String>(
  (ref, contactId) => contactPairingOf(ref.watch(pairingsProvider).value ?? const <PairingRecord>[], contactId),
);

/// The paired contact and purpose of the transaction with slate [slateId], or null; read
/// again on every pairing event.
final pairingSlateProvider = FutureProvider.autoDispose.family<PairingSlate?, String>((ref, slateId) async {
  final api = ref.watch(pairingApiProvider);
  if (!api.supported) return null;
  final sub = api.events().listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return api.slateOf(slateId);
});

/// The pairing [id], or null.
final pairingByIdProvider = Provider.family<PairingRecord?, String>((ref, id) {
  final all = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
  return all.where((r) => r.id == id).firstOrNull;
});

/// Paired records (heard, not ended), newest first.
final pairedProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(pairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPaired) r,
]);

/// Pairings of this wallet in no address-book contact (never saved, or the contact was
/// deleted from the shared book): Contacts lists them by the name they chose. Waiting and
/// ended records too: each has its row.
final orphanPairingsProvider = Provider<List<PairingRecord>>((ref) {
  final ids = {for (final c in ref.watch(contactsProvider).value ?? const <Contact>[]) c.id};
  return [
    for (final r in ref.watch(pairingsProvider).value ?? const <PairingRecord>[])
      if (r.state.isRecord && (r.contactId == null || !ids.contains(r.contactId))) r,
  ];
});

/// The pairings in flight that sit in Contacts ([pairingsInContacts]): a request sent, an
/// answer waiting for its confirm. A code nobody answered is none of them.
final pendingPairingsProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in pairingsInContacts(ref.watch(pairingsProvider).value ?? const <PairingRecord>[]))
    if (r.state.isPending) r,
]);

/// The pending pairing for the contact [contactId] (a request sent to it, or an answer to
/// its code), or null.
final contactPendingPairingProvider = Provider.family<PairingRecord?, String>(
  (ref, contactId) => ref.watch(pendingPairingsProvider).where((r) => r.contactId == contactId).firstOrNull,
);

/// The contacts something is in flight with, as the ids the foreground check reads
/// ([contactsInFlight]): pairings in progress and contacts LEPIC marks as awaiting. Empty
/// while the wallet is locked.
final contactsInFlightProvider = Provider<List<String>>((ref) {
  return contactsInFlight(ref.watch(pairingsProvider).value ?? const <PairingRecord>[]);
});

/// Second answers to used codes.
final pairingStraysProvider = FutureProvider<List<PairingStray>>((ref) {
  ref.watch(pairingsProvider);
  return ref.watch(pairingApiProvider).strays();
});

/// The pairing events of the open wallet, for the notices.
final pairingEventsProvider = StreamProvider<PairingEvent>((ref) => ref.watch(pairingApiProvider).events());

/// The sealed sends through the pairing [pairingId] still waiting for the recipient: after a
/// mismatch they are held, never finalized, and each offers Cancel.
final heldSendsProvider = Provider.family<List<TxEntry>, String>((ref, pairingId) => [
  for (final tx in ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[])
    if (tx.pairingId == pairingId && tx.status == TxStatus.awaitingRecipient && tx.cancellable) tx,
]);

/// The keys of the sends through the pairing [pairingId] still waiting for the recipient:
/// outgoing, awaitingRecipient; answered, cancelled and confirmed ones are not in it.
List<String> waitingSendKeys(Iterable<TxEntry> txs, String pairingId) => [
  for (final t in txs)
    if (t.pairingId == pairingId && t.kind == TxKind.sent && t.status == TxStatus.awaitingRecipient) t.key,
];

/// Posts each of [txKeys] again to the contact's new mailbox once its keys came back (RFC 10.5).
/// A failure is logged and never shown: the 24 h card still applies.
Future<void> repostWaitingSends(PairingApi api, Iterable<String> txKeys) async {
  for (final key in txKeys) {
    try {
      await api.repostViaMailbox(key);
    } on Object catch (e) {
      logWarn('pairing', 'repost of a waiting send failed: ${e.runtimeType}');
    }
  }
}

/// The pairings whose keys a re-pair found again this session (RFC 7.8): their contact page
/// docks "keys are back" until OK. [PairingNotices] keeps it listening.
final keysBackProvider = NotifierProvider<KeysBack, Set<String>>(KeysBack.new);

class KeysBack extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final sub = ref.watch(pairingApiProvider).events().listen((e) {
      final id = e.pairingId;
      if (e.kind == PairingEventKind.keysRestored && id != null) {
        state = {...state, id};
        final keys = waitingSendKeys(ref.read(homeProvider).value?.transactions ?? const <TxEntry>[], id);
        if (keys.isNotEmpty) unawaited(repostWaitingSends(ref.read(pairingApiProvider), keys));
      }
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  void close(String id) => state = {...state}..remove(id);
}

/// The name the user shows when pairing ("They see you as"), remembered on the device; empty
/// means none (the wire then carries [unnamedPeerName]).
final pairingSeenAsProvider = AsyncNotifierProvider<PairingSeenAs, String>(PairingSeenAs.new);

class PairingSeenAs extends AsyncNotifier<String> {
  static const key = 'pairing.seen_as';

  @override
  Future<String> build() async {
    return (await ref.read(secretStoreProvider).read(key) ?? '').trim();
  }

  /// Keeps [name] and tells the engine: every later code and request carries it, and the
  /// paired contacts get a fresh card (L7). An empty name is kept as '' and sent as
  /// [unnamedPeerName], so paired contacts stop seeing the old one.
  Future<void> set(String name) async {
    final text = name.trim();
    state = AsyncData(text);
    await ref.read(secretStoreProvider).write(key, text);
    final api = ref.read(pairingApiProvider);
    if (api.supported) {
      try {
        await api.setOwnName(text.isEmpty ? unnamedPeerName : text);
      } on Object {
        // Told at the next code; nothing to show.
      }
    }
  }
}

/// [pairingName] with the open wallet's contacts.
final pairingNameProvider = Provider.family<String, String>((ref, id) {
  final r = ref.watch(pairingByIdProvider(id));
  if (r == null) return '';
  final locale = ref.watch(appSettingsProvider.select((s) => s.value?.locale));
  return pairingName(r, ref.watch(contactsProvider).value ?? const <Contact>[], l: pairingStrings(locale));
});

/// The trust policy's view of the contact [contactId]: what the user has with it. Used by
/// the Pair sheet (Way 1 offered?) and the contact lines.
final contactRelationshipProvider = Provider.family<Relationship, String>((ref, contactId) {
  final contact = (ref.watch(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == contactId).firstOrNull;
  if (contact == null) return const Relationship.none();
  final p = ref.watch(contactPairingProvider(contactId));
  final pending = ref.watch(contactPendingPairingProvider(contactId));
  final hasAddress = (contact.epicbox ?? '').trim().isNotEmpty || p?.paymentsAddress != null;
  if (p == null) return Relationship(RelationshipKind.contact, waiting: pending != null, hasEpicboxAddress: hasAddress);
  final kind = switch (p.state) {
    PairingState.ended => RelationshipKind.ended,
    PairingState.verified => RelationshipKind.verified,
    PairingState.keysChanged => RelationshipKind.keysChanged,
    PairingState.paired => RelationshipKind.paired,
    _ => RelationshipKind.contact,
  };
  return Relationship(
    kind,
    waiting: p.state == PairingState.waiting || pending != null,
    endedReason: switch (p.endedReason) {
      PairingEndReason.mismatch || PairingEndReason.peerMismatch => EndedReason.mismatch,
      PairingEndReason.unpaired => EndedReason.unpaired,
      PairingEndReason.neverFinished => EndedReason.notHeard,
      null => null,
    },
    hasEpicboxAddress: hasAddress,
    peerFeatures: p.peerFeatures,
    peerProfile: p.peerProfile,
  );
});

/// What the contact's Epicbox key has shown it can do (LEPIC's `peer_compat`), or null.
final contactPeerCompatProvider = FutureProvider.autoDispose.family<PeerCompat?, String>((ref, address) async {
  if (ref.watch(sessionProvider) == null || address.trim().isEmpty) return null;
  return ref.watch(walletServiceProvider).peerCompat(address);
});

/// Runs [call] on the open wallet's pairing, then reloads the records.
Future<T> pairingCall<T>(WidgetRef ref, Future<T> Function(PairingApi api) call) async {
  try {
    return await call(ref.read(pairingApiProvider));
  } finally {
    unawaited(ref.read(pairingsProvider.notifier).reload());
    unawaited(ref.read(pairRequestsProvider.notifier).reload());
  }
}

/// Writes the proven address of the verified pairing [r] into its contact's empty Epicbox
/// slot (pairing v2 §5: at Verified only, never over an address). Best effort.
Future<void> writeProvenAddress(WidgetRef ref, PairingRecord r) async {
  final address = r.paymentsAddress;
  final cid = r.contactId;
  if (address == null || cid == null || r.state != PairingState.verified) return;
  final contact = (ref.read(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == cid).firstOrNull;
  if (contact == null || (contact.epicbox ?? '').trim().isNotEmpty) return;
  if (parseRecipient(address).kind != RecipientKind.epicbox) return;
  try {
    await ref.read(contactsProvider.notifier).save(contact.withAddress(RecipientKind.epicbox, address));
  } on Object {
    // The page shows the pairing's address until then.
  }
}

/// The remembered name others see, once loaded.
Future<String> readSeenAs(WidgetRef ref) async {
  final String? now = ref.read(pairingSeenAsProvider).value;
  if (now != null) return now;
  final String loaded = await ref.read(pairingSeenAsProvider.future);
  return loaded;
}
