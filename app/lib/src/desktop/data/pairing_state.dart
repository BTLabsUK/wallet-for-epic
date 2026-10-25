/// The desktop's pairing state (RFC 0002): the open wallet's [PairingApi] through
/// [DeskWalletApi.pairing], its records, its events, and the name others see. The types are
/// the core's, shared with the phone.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkMode;
import '../../models.dart' show PairingEvent, PairingRecord, PairingState;
import '../../pairing_api.dart';
import 'models.dart' show Contact;
import 'state.dart';

/// The open wallet's pairing; [NoPairing] while locked. Follows the unlock.
final deskPairingApiProvider = Provider<PairingApi>((ref) {
  ref.watch(deskProvider.select((s) => s.account));
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

/// The pairing attached to the contact [contactId], or null.
final deskContactPairingProvider = Provider.family<PairingRecord?, String>((ref, contactId) {
  final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
  return all.where((r) => r.contactId == contactId && r.state.isPaired).firstOrNull;
});

final deskPairingByIdProvider = Provider.family<PairingRecord?, String>((ref, id) {
  final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
  return all.where((r) => r.id == id).firstOrNull;
});

/// Paired records, newest first.
final deskPairedProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPaired) r,
]);

/// In flight: invites, answers, pairings still to check.
final deskPendingPairingsProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPending || r.awaitsCheck) r,
]);

final deskPairingEventsProvider = StreamProvider<PairingEvent>((ref) => ref.watch(deskPairingApiProvider).events());

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

/// The name others see when pairing, for this run of the app.
final deskSeenAsProvider = NotifierProvider<DeskSeenAs, String>(DeskSeenAs.new);

class DeskSeenAs extends Notifier<String> {
  @override
  String build() => '';

  void set(String name) => state = name.trim();
}

/// Runs [call], then reads the records again.
Future<T> deskPairingCall<T>(WidgetRef ref, Future<T> Function(PairingApi api) call) async {
  try {
    return await call(ref.read(deskPairingApiProvider));
  } finally {
    unawaited(ref.read(deskPairingsProvider.notifier).reload());
  }
}

/// Whether [r] waits for the words: a pairing nobody checked yet.
bool deskAwaitsCheck(PairingRecord r) => r.state == PairingState.paired && !r.checkSkipped;
