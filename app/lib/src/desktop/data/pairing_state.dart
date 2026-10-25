/// The desktop's pairing state (RFC 0002): the open wallet's [PairingApi] through
/// [DeskWalletApi.pairing], its records, its events, and the name others see. The types are
/// the core's, shared with the phone.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkMode;
import '../../log.dart';
import '../../models.dart' show PairingCard, PairingEvent, PairingEventKind, PairingRecord, PairingSlate, PairingState, contactPairingOf;
import '../../pairing_api.dart';
import 'invoices.dart' show deskFailureKind;
import 'models.dart' show Contact;
import 'state.dart';

/// Pairing is on (Settings › Advanced › Experimental; off by default). Off, nothing of
/// pairing shows and nothing collects; the stored pairings come back when it is on again.
final deskPairingOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.pairingOn)));

/// Invoices are on (Settings › Advanced › Experimental; off by default, never without
/// Pairing): the Invoices page, requests, notices and Settings › Invoices.
final deskInvoicesOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.invoicesOn)));

/// The invoices show: the wallet takes them and Invoices is on. Off, the Invoices page,
/// Settings › Invoices, Requests on Activity and every invoice block are hidden.
final deskInvoicesShownProvider = Provider<bool>(
  (ref) => ref.watch(deskInvoicesOnProvider) && ref.watch(deskApiProvider).supportsInvoices,
);

/// The open wallet's pairing; [NoPairing] while locked or while Pairing is off. Follows the unlock and the reopen a
/// node or Epicbox change makes, which closes the old session's pairing.
final deskPairingApiProvider = Provider<PairingApi>((ref) {
  if (!ref.watch(deskPairingOnProvider)) return const NoPairing();
  ref.watch(deskProvider.select((s) => s.account));
  ref.watch(deskProvider.select((s) => s.session));
  return ref.watch(deskApiProvider).pairing;
});

/// Whether this wallet pairs: Pair, the Pairing block and the trust badges show.
final deskPairsProvider = Provider<bool>((ref) => ref.watch(deskPairingApiProvider).supported);

/// What reaches the relays now: Offline, Epicbox off (only in person and by hand), or online.
enum DeskPairNet { online, offline, epicboxOff }

final deskPairNetProvider = Provider<DeskPairNet>((ref) {
  final s = ref.watch(deskProvider.select((s) => s.settings));
  if (s.advanced.networkMode == NetworkMode.offline) return DeskPairNet.offline;
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
    await future;
  }
}

/// The pairing the contact [contactId] uses ([contactPairingOf]), or null.
final deskContactPairingProvider = Provider.family<PairingRecord?, String>(
  (ref, contactId) => contactPairingOf(ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[], contactId),
);

final deskPairingByIdProvider = Provider.family<PairingRecord?, String>((ref, id) {
  final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
  return all.where((r) => r.id == id).firstOrNull;
});

/// Paired records, newest first.
final deskPairedProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPaired) r,
]);

/// Pairings in no contact (never saved, or deleted from the shared book): Contacts lists them
/// by the name they chose (PAIR-AND-8).
final deskOrphanPairingsProvider = Provider<List<PairingRecord>>((ref) {
  final ids = {for (final c in ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[]) c.id};
  return [
    for (final r in ref.watch(deskPairedProvider))
      if (r.contactId == null || !ids.contains(r.contactId)) r,
  ];
});

/// In flight: invites, answers, pairings still to check.
final deskPendingPairingsProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPending || r.awaitsCheck) r,
]);

final deskPairingEventsProvider = StreamProvider<PairingEvent>((ref) => ref.watch(deskPairingApiProvider).events());

/// The pairings whose keys a re-pair found again this session (RFC 7.8): their contact page
/// docks "keys are back" until it is closed (SPEC 2.4). The shell keeps it listening.
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

/// The name for [record]: its contact's, else the one it chose.
String deskPairingName(PairingRecord record, Iterable<Contact>? contacts) {
  final cid = record.contactId;
  final c = cid == null ? null : contacts?.where((c) => c.id == cid).firstOrNull;
  return c?.name ?? record.shownName;
}

final deskPairingNameProvider = Provider.family<String, String>((ref, id) {
  final r = ref.watch(deskPairingByIdProvider(id));
  if (r == null) return '';
  return deskPairingName(r, ref.watch(deskProvider.select((s) => s.contacts)));
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

/// This wallet's in-person card while one is out (RFC 7.4): the card the other wallet's card
/// link is read against. Memory only; it ends with the pairing it made and with the wallet.
final deskOwnCardProvider = NotifierProvider<DeskOwnCard, PairingCard?>(DeskOwnCard.new);

class DeskOwnCard extends Notifier<PairingCard?> {
  @override
  PairingCard? build() {
    ref.watch(deskPairingApiProvider);
    return null;
  }

  void set(PairingCard? card) => state = card;
}

/// The name others see when pairing ("They will see you as"), kept in the settings.
final deskSeenAsProvider = NotifierProvider<DeskSeenAs, String>(DeskSeenAs.new);

class DeskSeenAs extends Notifier<String> {
  Timer? _save;

  @override
  String build() {
    ref.onDispose(() => _save?.cancel());
    return ref.watch(deskProvider.select((s) => s.settings.pairingSeenAs));
  }

  /// Takes [name] at once and keeps it in the settings once typing pauses, as the phone keeps
  /// it on the device.
  void set(String name) {
    final shown = name.trim();
    if (shown == state) return;
    state = shown;
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () {
      final desk = ref.read(deskProvider.notifier);
      desk.saveSettings(ref.read(deskProvider).settings.copyWith(pairingSeenAs: shown)).ignore();
    });
  }
}

/// Runs [call], then reads the records again. A failure is logged by its kind.
Future<T> deskPairingCall<T>(WidgetRef ref, Future<T> Function(PairingApi api) call) async {
  try {
    return await call(ref.read(deskPairingApiProvider));
  } on Object catch (e) {
    logWarn('pairing', 'call failed: ${deskFailureKind(e)}');
    rethrow;
  } finally {
    unawaited(ref.read(deskPairingsProvider.notifier).reload());
  }
}

/// Whether [r] waits for the words: a pairing nobody checked yet.
bool deskAwaitsCheck(PairingRecord r) => r.state == PairingState.paired && !r.checkSkipped;
