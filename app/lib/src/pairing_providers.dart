// SPDX-License-Identifier: Apache-2.0
/// The phone's pairing state (RFC 0002): the open wallet's [PairingApi], its records, its
/// events, and what the screens need around them. Empty while the wallet is locked or its
/// core does not pair, so nothing pairing-related shows then.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart' show NetworkMode;
import 'contacts.dart';
import 'providers.dart';
import 'settings.dart';
import 'settings_file/settings_providers.dart' show hostSettingsProvider;
import 'wallet_service.dart';

/// Pairing is on (Settings › Advanced › Experimental; off by default). Off, nothing of
/// pairing shows and nothing collects; the stored pairings come back when it is on again.
final pairingOnProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.value?.advanced.pairingOn)) ?? false,
);

/// Invoices are on (Settings › Advanced › Experimental; off by default, never without
/// Pairing): the invoice screens, requests, notices and Settings › Invoices.
final invoicesOnProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.value?.advanced.invoicesOn)) ?? false,
);

/// The open wallet when it handles invoices and Invoices is on, else null: every invoice
/// provider, screen and notice reads it, so Invoices off shows and checks nothing.
final invoiceSessionProvider = Provider<WalletSession?>((ref) {
  if (!ref.watch(invoicesOnProvider)) return null;
  final session = ref.watch(sessionProvider);
  return session != null && session.supportsInvoices ? session : null;
});

/// Whether invoices show: [invoiceSessionProvider] has a wallet.
final invoicesShownProvider = Provider<bool>((ref) => ref.watch(invoiceSessionProvider) != null);

/// The open wallet's pairing, or [NoPairing] while locked, on a core without it, or while
/// Pairing is off ([pairingOnProvider]).
final pairingApiProvider = Provider<PairingApi>((ref) {
  if (!ref.watch(pairingOnProvider)) return const NoPairing();
  final session = ref.watch(sessionProvider);
  final api = session?.pairing ?? const NoPairing();
  // The words calls meet on the first `epicbox.pairing_servers` of the Epicbox list.
  api.setConnectionServers(ref.watch(hostSettingsProvider.select((s) => s.pairingServers)));
  return api;
});

/// Whether this wallet pairs: the screens show Pair, the Pairing block and the trust badges.
final pairingSupportedProvider = Provider<bool>((ref) => ref.watch(pairingApiProvider).supported);

/// What reaches the relays now, for pairing (RFC 8.7): online, Offline, or Epicbox off. In
/// person and by hand work in all three.
enum PairNet { online, offline, epicboxOff }

final pairNetProvider = Provider<PairNet>((ref) {
  if (ref.watch(networkModeProvider) == NetworkMode.offline) return PairNet.offline;
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
    final sub = api.events().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return api.pairings();
  }

  /// Reads the records again (after a call that changed one).
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
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

/// Paired records (not pending), newest first.
final pairedProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(pairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPaired) r,
]);

/// Pairings of this wallet in no address-book contact (never saved, or the contact was
/// deleted from the shared book): Contacts lists them by the name they chose.
final orphanPairingsProvider = Provider<List<PairingRecord>>((ref) {
  final ids = {for (final c in ref.watch(contactsProvider).value ?? const <Contact>[]) c.id};
  return [
    for (final r in ref.watch(pairedProvider))
      if (r.contactId == null || !ids.contains(r.contactId)) r,
  ];
});

/// What Pending invites lists: invites and answers in flight, and pairings whose words are
/// still to be checked.
final pendingPairingsProvider = Provider<List<PairingRecord>>((ref) => [
  for (final r in ref.watch(pairingsProvider).value ?? const <PairingRecord>[])
    if (r.state.isPending || r.awaitsCheck) r,
]);

/// Second answers to used invites, for Pending invites.
final pairingStraysProvider = FutureProvider<List<PairingStray>>((ref) {
  ref.watch(pairingsProvider);
  return ref.watch(pairingApiProvider).strays();
});

/// The pairing events of the open wallet, for the notices.
final pairingEventsProvider = StreamProvider<PairingEvent>((ref) => ref.watch(pairingApiProvider).events());

/// The pairings whose keys a re-pair found again this session (RFC 7.8): their contact page
/// docks "keys are back" until OK. [PairingNotices] keeps it listening.
final keysBackProvider = NotifierProvider<KeysBack, Set<String>>(KeysBack.new);

class KeysBack extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final sub = ref.watch(pairingApiProvider).events().listen((e) {
      final id = e.pairingId;
      if (e.kind == PairingEventKind.keysRestored && id != null) state = {...state, id};
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  void close(String id) => state = {...state}..remove(id);
}

/// The name the user shows when pairing ("They will see you as"), remembered on the device.
final pairingSeenAsProvider = AsyncNotifierProvider<PairingSeenAs, String>(PairingSeenAs.new);

class PairingSeenAs extends AsyncNotifier<String> {
  static const key = 'pairing.seen_as';

  Timer? _save;

  @override
  Future<String> build() async {
    ref.onDispose(() => _save?.cancel());
    return await ref.read(secretStoreProvider).read(key) ?? '';
  }

  Future<void> set(String name) async {
    _save?.cancel();
    final text = name.trim();
    state = AsyncData(text);
    await ref.read(secretStoreProvider).write(key, text);
  }

  /// The name being typed: current for the screens at once, kept once typing pauses (the
  /// screen may close first).
  void type(String name) {
    final text = name.trim();
    state = AsyncData(text);
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () => set(text).ignore());
  }
}

/// The name the app shows for [record]: the contact's when it is attached, else the name the
/// other side chose, else the label of an invite.
String pairingName(PairingRecord record, Iterable<Contact> contacts) {
  final cid = record.contactId;
  if (cid != null) {
    final c = contacts.where((c) => c.id == cid).firstOrNull;
    if (c != null) return c.name;
  }
  return record.shownName;
}

/// [pairingName] with the open wallet's contacts.
final pairingNameProvider = Provider.family<String, String>((ref, id) {
  final r = ref.watch(pairingByIdProvider(id));
  if (r == null) return '';
  return pairingName(r, ref.watch(contactsProvider).value ?? const <Contact>[]);
});

/// Runs [call] on the open wallet's pairing, then reloads the records.
Future<T> pairingCall<T>(WidgetRef ref, Future<T> Function(PairingApi api) call) async {
  try {
    return await call(ref.read(pairingApiProvider));
  } finally {
    unawaited(ref.read(pairingsProvider.notifier).reload());
  }
}

/// Opens the pairing mailboxes every [every] while something is pending, then not at all
/// (RFC 8.2: every 10 s while an invite screen is open, every 5 s while waiting). The screen
/// that waits holds it; the timer stops with the screen.
class PairingCollector {
  PairingCollector(this._api, {this.every = const Duration(seconds: 10)});

  final PairingApi _api;
  final Duration every;
  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(every, (_) => _api.collect().ignore());
    _api.collect().ignore();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// The remembered name others see, once loaded.
Future<String> readSeenAs(WidgetRef ref) async {
  final String? now = ref.read(pairingSeenAsProvider).value;
  if (now != null) return now;
  final String loaded = await ref.read(pairingSeenAsProvider.future);
  return loaded;
}
