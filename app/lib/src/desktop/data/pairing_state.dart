// SPDX-License-Identifier: Apache-2.0
/// The desktop's pairing state (RFC 0002): the open wallet's [PairingApi] through
/// [DeskWalletApi.pairing], its records, the requests to its address, its events, and the
/// name others see. The types are the core's, shared with the phone. Pairing is on for
/// everyone: there is no switch.
library;

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkModeRestricted;
import '../../log.dart';
import '../../name_service/payment_refusals.dart' show PairingRefusals, PaymentRefusals;
import '../../models.dart' show PairRequest, PairingEndReason, PairingEvent, PairingEventKind, PairingRecord, PairingSlate, PairingState, contactPairingOf, epicboxKey;
import '../../pairing_api.dart';
import '../../l10n.dart' show AppLocalizations;
import '../../pairing_providers.dart' show dismissStrangers, requestPassOnProvider;
import '../../pairing_text.dart' show pairingName, pairingStrings, unnamedPeerName;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../trust/policy.dart';
import 'invoices.dart' show deskFailureKind;
import 'models.dart' show Contact, Tx, TxDirection, TxState;
import 'state.dart';

/// Invoices are on (Settings › Advanced › Experimental; off by default).
final deskInvoicesOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.invoicesOn)));

/// The invoices show: the wallet takes them and Invoices is on. Off, the Invoices page,
/// Settings › Invoices, Requests on Activity and every invoice block are hidden.
final deskInvoicesShownProvider = Provider<bool>(
  (ref) => ref.watch(deskInvoicesOnProvider) && ref.watch(deskApiProvider).supportsInvoices,
);

/// The open wallet's pairing; [NoPairing] while locked. Follows the unlock and the reopen a
/// node or Epicbox change makes, which closes the old session's pairing.
final deskPairingApiProvider = Provider<PairingApi>((ref) {
  ref.watch(deskProvider.select((s) => s.account));
  ref.watch(deskProvider.select((s) => s.session));
  final api = ref.watch(deskApiProvider).pairing;
  api.setConnectionServers(ref.watch(hostSettingsProvider.select((s) => s.pairingServers)));
  return api;
});

/// Whether this wallet pairs: Pair, the Pairing block and the trust badges show.
final deskPairsProvider = Provider<bool>((ref) => ref.watch(deskPairingApiProvider).supported);

/// What reaches the relays now: Offline, Epicbox off (by hand only), or online.
enum DeskPairNet { online, offline, epicboxOff }

final deskPairNetProvider = Provider<DeskPairNet>((ref) {
  final s = ref.watch(deskProvider.select((s) => s.settings));
  if (s.advanced.networkMode.restricted) return DeskPairNet.offline;
  return s.payments.epicbox ? DeskPairNet.online : DeskPairNet.epicboxOff;
});

/// Every pairing, newest first; reloads on every pairing event.
final deskPairingsProvider = AsyncNotifierProvider<DeskPairings, List<PairingRecord>>(DeskPairings.new);

class DeskPairings extends AsyncNotifier<List<PairingRecord>> {
  @override
  Future<List<PairingRecord>> build() async {
    final api = ref.watch(deskPairingApiProvider);
    if (!api.supported) return const [];
    final sub = api.events().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return api.pairings();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Disposed meanwhile: nothing to show it to.
    }
  }
}

/// [PairingRefusals] over the open wallet's pairings, for [paymentRefusalsProvider]; none while
/// they load.
final deskPairingRefusalsProvider = Provider<PaymentRefusals>((ref) => PairingRefusals(ref.watch(deskPairingsProvider).value ?? const []));

/// The Epicbox keys of the desktop's address book, or null while it is unknown: not loaded
/// yet ([contacts] null) or [closed] (the shared book has no key for this wallet yet).
Set<String>? deskContactKeysOf(List<Contact>? contacts, {bool closed = false}) => closed || contacts == null
    ? null
    : {
        for (final c in contacts)
          if (c.epicbox case final a? when a.trim().isNotEmpty) epicboxKey(a),
      };

/// The requests to pair that came to this wallet's address, from contacts only, newest
/// first; reloads on every pairing event and when the address book loads. Strangers' requests
/// are dismissed ([dismissStrangers]) once the book is known: while it loads or is closed,
/// every request is kept and none is listed.
final deskPairRequestsProvider = AsyncNotifierProvider<DeskPairRequests, List<PairRequest>>(DeskPairRequests.new);

class DeskPairRequests extends AsyncNotifier<List<PairRequest>> {
  @override
  Future<List<PairRequest>> build() async {
    final api = ref.watch(deskPairingApiProvider);
    if (!api.supported) return const [];
    final sub = api.events().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    final keys = deskContactKeysOf(
      ref.watch(deskProvider.select((s) => s.contacts)),
      closed: ref.watch(deskProvider.select((s) => s.status?.contactsClosed ?? false)),
    );
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
      // Disposed meanwhile: nothing to show it to.
    }
  }
}

/// The contact a request came from, by the key of its address, or null.
Contact? deskContactOfRequest(Iterable<Contact> contacts, PairRequest r) {
  final key = epicboxKey(r.fromAddress);
  return contacts.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull;
}

/// The pairing the contact [contactId] uses ([contactPairingOf]), or null.
final deskContactPairingProvider = Provider.family<PairingRecord?, String>(
  (ref, contactId) => contactPairingOf(ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[], contactId),
);

final deskPairingByIdProvider = Provider.family<PairingRecord?, String>((ref, id) {
  final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
  return all.where((r) => r.id == id).firstOrNull;
});

/// Paired records (heard, not ended), newest first.
final deskPairedProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPaired) r,
]);

/// Pairings in no contact (never saved, or deleted from the shared book): Contacts lists them
/// by the name they chose. Waiting and ended records too, and an answer to a code waiting
/// for its confirm.
final deskOrphanPairingsProvider = Provider<List<PairingRecord>>((ref) {
  final ids = {for (final c in ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[]) c.id};
  return [
    for (final r in pairingsInContacts(ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[]))
      if (r.contactId == null || !ids.contains(r.contactId)) r,
  ];
});

/// In flight and in Contacts: a request sent, an answer waiting for its confirm.
final deskPendingPairingsProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in pairingsInContacts(ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[]))
    if (r.state.isPending) r,
]);

/// The pending pairing of the contact [contactId], or null.
final deskContactPendingProvider = Provider.family<PairingRecord?, String>(
  (ref, contactId) => ref.watch(deskPendingPairingsProvider).where((r) => r.contactId == contactId).firstOrNull,
);

final deskPairingEventsProvider = StreamProvider<PairingEvent>((ref) => ref.watch(deskPairingApiProvider).events());

/// The sealed sends through the pairing [pairingId] still waiting for the recipient: after a
/// mismatch they are held, never finalized, and each offers Cancel.
final deskHeldSendsProvider = Provider.family<List<Tx>, String>((ref, pairingId) => [
  for (final t in ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[])
    if (t.pairingId == pairingId && t.direction == TxDirection.sent && t.state == TxState.waitingRecipient && t.cancellable) t,
]);

/// The pairings whose keys a re-pair found again this session (RFC 7.8): their contact page
/// docks "keys are back" until it is closed. The shell keeps it listening.
final deskKeysBackProvider = NotifierProvider<DeskKeysBack, Set<String>>(DeskKeysBack.new);

class DeskKeysBack extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final sub = ref.watch(deskPairingApiProvider).events().listen((e) {
      final id = e.pairingId;
      if (e.kind == PairingEventKind.keysRestored && id != null) state = {...state, id};
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  void close(String id) => state = {...state}..remove(id);
}

/// The name for [record]: its contact's, else [peerLabel] (the label, the name it chose, or
/// "Unnamed wallet"). Without [l] a pairing with no name reads empty.
String deskPairingName(PairingRecord record, Iterable<Contact>? contacts, {AppLocalizations? l}) {
  final cid = record.contactId;
  final c = cid == null ? null : contacts?.where((c) => c.id == cid).firstOrNull;
  return c?.name ?? pairingName(record, const [], l: l);
}

final deskPairingNameProvider = Provider.family<String, String>((ref, id) {
  final r = ref.watch(deskPairingByIdProvider(id));
  if (r == null) return '';
  final language = ref.watch(deskProvider.select((s) => s.settings.language));
  final locale = language == null ? null : Locale(language);
  return deskPairingName(r, ref.watch(deskProvider.select((s) => s.contacts)), l: pairingStrings(locale));
});

/// The paired contact and purpose of the transaction with slate [slateId] (a withdrawal from
/// an exchange, ...), or null; read again on every pairing event.
final deskPairingSlateProvider = FutureProvider.autoDispose.family<PairingSlate?, String>((ref, slateId) async {
  final api = ref.watch(deskPairingApiProvider);
  if (!api.supported) return null;
  final sub = api.events().listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return api.slateOf(slateId);
});

/// The name others see when pairing ("They see you as"), kept in the settings; empty means
/// none (the wire then carries [unnamedPeerName]).
final deskSeenAsProvider = NotifierProvider<DeskSeenAs, String>(DeskSeenAs.new);

class DeskSeenAs extends Notifier<String> {
  @override
  String build() {
    return ref.watch(deskProvider.select((s) => s.settings.pairingSeenAs)).trim();
  }

  /// Keeps [name] in the settings and tells the engine: every later code and request carries
  /// it, and the paired contacts get a fresh card (L7).
  Future<void> set(String name) async {
    final shown = name.trim();
    if (shown == state) return;
    state = shown;
    final desk = ref.read(deskProvider.notifier);
    await desk.saveSettings(ref.read(deskProvider).settings.copyWith(pairingSeenAs: shown));
    final api = ref.read(deskPairingApiProvider);
    if (api.supported) {
      try {
        await api.setOwnName(shown.isEmpty ? unnamedPeerName : shown);
      } on Object catch (e) {
        logWarn('pairing', 'own name not set: ${deskFailureKind(e)}');
      }
    }
  }
}

/// The trust policy's view of the contact [contactId]: what the user has with it.
final deskContactRelationshipProvider = Provider.family<Relationship, String>((ref, contactId) {
  final contact = (ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[]).where((c) => c.id == contactId).firstOrNull;
  if (contact == null) return const Relationship.none();
  final p = ref.watch(deskContactPairingProvider(contactId));
  final pending = ref.watch(deskContactPendingProvider(contactId));
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
final deskPeerCompatProvider = FutureProvider.autoDispose.family<PeerCompat?, String>((ref, address) async {
  if (address.trim().isEmpty) return null;
  return ref.watch(deskApiProvider).peerCompat(address);
});

/// The pairings whose wait is up in a dialog (the answerer's wait for the confirm): a
/// confirmation for one of them, pasted or offered, leaves the next step to that dialog.
final Set<String> deskPairingStepsOnScreen = {};

/// Runs [call], then reads the records again. A failure is logged by its kind.
Future<T> deskPairingCall<T>(WidgetRef ref, Future<T> Function(PairingApi api) call) async {
  try {
    return await call(ref.read(deskPairingApiProvider));
  } on Object catch (e) {
    logWarn('pairing', 'call failed: ${deskFailureKind(e)}');
    rethrow;
  } finally {
    unawaited(ref.read(deskPairingsProvider.notifier).reload());
    unawaited(ref.read(deskPairRequestsProvider.notifier).reload());
  }
}

/// Writes the proven address of the verified pairing [r] into its contact's empty Epicbox
/// slot (at Verified only, never over an address). Best effort.
Future<void> deskWriteProvenAddress(WidgetRef ref, PairingRecord r) async {
  final address = r.paymentsAddress;
  final cid = r.contactId;
  if (address == null || cid == null || r.state != PairingState.verified) return;
  final contact = (ref.read(deskProvider).contacts ?? const <Contact>[]).where((c) => c.id == cid).firstOrNull;
  if (contact == null || (contact.epicbox ?? '').trim().isNotEmpty) return;
  try {
    await ref.read(deskProvider.notifier).saveContact(
      Contact(
        id: contact.id,
        name: contact.name,
        epicbox: address,
        http: contact.http,
        tor: contact.tor,
        note: contact.note,
        label: contact.label,
        favourite: contact.favourite,
        lastUsed: contact.lastUsed,
        hasPicture: contact.hasPicture,
      ),
    );
  } on Object catch (e) {
    logWarn('pairing', 'address not written: ${deskFailureKind(e)}');
  }
}
