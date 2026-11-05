// SPDX-License-Identifier: Apache-2.0
/// The open wallet's directories: contact pairings whose peer claims the directory feature and
/// proved it with a valid hello. The service reads the payloads of contact pairings (the devices
/// service leaves them alone), keeps the book ([DirectoryBook]), joins and leaves a directory,
/// and drains the listings. No part of it knows which service a directory is.
///
/// Nothing runs by itself in the background: the app calls [sync] on open, resume, unlock and
/// from its foreground tick, and the hello wait runs only while a screen shows it.
library;

// Private fields from public named parameters.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import '../log.dart';
import '../sas_table.dart';
import '../trust/policy.dart' show featureDirectory;
import '../wallet_service.dart';
import 'base58.dart' show netFloonet, netMainnet;
import 'codes.dart' show listingCodeIndexes;
import 'directory_model.dart';
import 'directory_store.dart';
import 'membership.dart';
import 'receipts.dart' show DirectoryReceipts;
import 'payment_refusals.dart';
import 'verify.dart';
import 'wire.dart';

export '../sas_table.dart' show sasIndexesOf;

/// How long the wallet waits for the directory's hello once the pairing is Paired.
const Duration helloWait = Duration(seconds: 30);

/// How often the wait collects the pairing and reads its payloads.
const Duration helloPoll = Duration(seconds: 2);

/// The longest payload from a directory this wallet reads.
const int directoryPayloadMaxBytes = 2048;

/// Why a sync runs.
enum DirectorySyncTrigger { open, resume, unlock, tick }

/// Where the pairing words step stands for a directory.
enum HelloStep {
  /// Waiting for the hello (Cancel is offered).
  waiting,

  /// A valid hello came: compare the directory code.
  check,

  /// No (valid) hello, or Cancel: the ordinary words step.
  words,
}

/// What the directory service needs from the open wallet. The phone and the desktop each make
/// one over their session ([SessionDirectoryHost]).
abstract interface class DirectoryHost {
  PairingApi get pairing;

  /// The channel may reach the servers now.
  bool get online;

  /// `0` mainnet, `1` floonet.
  int get net;

  /// The signature check of the wallet service.
  DirectoryVerifier get verifier;

  /// The listing address of [dkeyHex] at [generation], on the wallet's home Epicbox server.
  Future<String> listingAddress(String dkeyHex, int generation);

  Future<Uint8List> sign(String dkeyHex, int generation, String domain, Uint8List message);

  /// Reads that listing's address once.
  Future<PaymentsDrainReport> drain(String dkeyHex, int generation);
}

/// A [DirectoryHost] over a [WalletSession]; a session without listing keys refuses.
class SessionDirectoryHost implements DirectoryHost {
  SessionDirectoryHost(this._session, {required this.net, required this.verifier, required bool Function() online})
    : _online = online;

  final WalletSession _session;
  final bool Function() _online;
  @override
  final int net;
  @override
  final DirectoryVerifier verifier;

  ListingKeys get _keys =>
      _session.listingKeys ?? (throw const WalletError(kind: WalletErrorKind.other, message: 'listing keys need LEPIC with directories'));

  @override
  PairingApi get pairing => _session.pairing;

  @override
  bool get online => _online();

  @override
  Future<String> listingAddress(String dkeyHex, int generation) => _keys.listingAddress(dkeyHex, generation);

  @override
  Future<Uint8List> sign(String dkeyHex, int generation, String domain, Uint8List message) =>
      _keys.signWithListing(dkeyHex, generation, domain, message);

  @override
  Future<PaymentsDrainReport> drain(String dkeyHex, int generation) => _keys.drainListing(dkeyHex, generation);
}

/// The net byte of a chain.
int netOfChain(Chain chain) => chain == Chain.mainnet ? netMainnet : netFloonet;

class DirectoryService implements DirectoryMembership, PaymentRefusals, DirectoryReceipts {
  DirectoryService({
    required DirectoryHost host,
    required DirectoryStore store,
    DateTime Function()? clock,
    this.wait = helloWait,
    this.poll = helloPoll,
    this.onDrained,
  }) : _host = host,
       _store = store,
       _clock = clock ?? DateTime.now;

  final DirectoryHost _host;
  final DirectoryStore _store;
  final DateTime Function() _clock;

  /// How long the hello is waited for, and how often the wait reads.
  final Duration wait;
  final Duration poll;

  /// A listing drain received or finalized something: the lists read again.
  final void Function(PaymentsDrainReport report)? onDrained;

  DirectoryBook _book = const DirectoryBook();
  bool _loaded = false;
  bool _disposed = false;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<DirectoryEntry> _lateNoPayments = StreamController<DirectoryEntry>.broadcast();

  DirectoryBook get book => _book;
  bool get loaded => _loaded;
  Stream<void> get changes => _changes.stream;

  /// A hello that arrived after the words step was over said the contact takes no payments:
  /// the entry, once per contact (the flag is set when this fires). The screens show one notice.
  Stream<DirectoryEntry> get lateNoPayments => _lateNoPayments.stream;

  /// The directory of the pairing [pairingId] the user compared the code of, or null.
  DirectoryEntry? verifiedFor(String pairingId) {
    final e = _book.byPairing(pairingId);
    return e != null && e.pinned ? e : null;
  }

  DirectoryEntry? entryOf(String dkeyHex) => _book.byDkey(dkeyHex);

  // Membership, for readers outside (Send from a link).

  @override
  String? labelFor(String dkeyHex) {
    final e = _book.byDkey(dkeyHex);
    return e != null && e.pinned && e.label.isNotEmpty ? e.label : null;
  }

  @override
  String? listingKeyFor(String dkeyHex) {
    final e = _book.byDkey(dkeyHex);
    final address = e?.joined == true ? e?.address : null;
    if (address == null) return null;
    return parseListingAddress(address)?.keyText;
  }

  // Payment refusals, for the contact and Send screens.

  @override
  bool refusesPayments({String? pairingId, String? address}) {
    return BookRefusals(_book).refusesPayments(pairingId: pairingId, address: address);
  }

  @override
  String? refusedName({String? pairingId, String? address}) =>
      BookRefusals(_book).refusedName(pairingId: pairingId, address: address);

  // Receipts, for a payment made from a link.

  DirectoryEntry? _usable(String dkeyHex) {
    final e = _book.byDkey(dkeyHex);
    return e != null && e.pinned ? e : null;
  }

  @override
  bool canTell(String dkeyHex) => _usable(dkeyHex) != null;

  @override
  Future<bool> post(String dkeyHex, Uint8List payload) async {
    final e = _usable(dkeyHex);
    if (e == null) return false;
    try {
      await _host.pairing.postPayload(id: e.pairingId, bytes: payload);
      return true;
    } on Object {
      return false;
    }
  }

  /// The four indexes of the listing code of a joined directory (the key of this wallet's
  /// listing), or null when it is not joined.
  List<int>? listingCodeFor(String dkeyHex) {
    final e = _book.byDkey(dkeyHex);
    final address = e?.joined == true ? e?.address : null;
    final parsed = address == null ? null : parseListingAddress(address);
    return parsed == null ? null : listingCodeIndexes(parsed.key);
  }

  void _changed() {
    if (!_disposed && !_changes.isClosed) _changes.add(null);
  }

  Future<void> _put(DirectoryBook next) async {
    _book = next;
    await _store.save(next);
    _changed();
  }

  Future<void> load() async {
    _book = await _store.load();
    _loaded = true;
    _changed();
  }

  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    _changes.close();
    _lateNoPayments.close();
  }

  // Reading.

  bool _busy = false;
  bool _again = false;

  /// One read: the payloads of contact pairings, the home-server move, then the drains.
  Future<void> sync(DirectorySyncTrigger trigger) async {
    if (!_loaded || _disposed) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      do {
        _again = false;
        if (!_host.online) break;
        try {
          await readPayloads();
          await _refreshEntries();
          await _followHome();
          await _drainAll();
        } on Object catch (e) {
          logWarn('directory', 'directory read failed: ${e.runtimeType}');
        }
      } while (_again && !_disposed);
    } finally {
      _busy = false;
    }
  }

  /// Reads the payloads of contact pairings and acknowledges each once its effect is stored.
  /// Payloads of private pairings are the devices service's and stay.
  Future<void> readPayloads() async {
    if (!_loaded || _disposed) return;
    final api = _host.pairing;
    final list = await api.payloads();
    if (list.isEmpty) return;
    final private = {for (final r in await api.privatePairings()) r.id};
    final done = <String>[];
    for (final p in list) {
      if (private.contains(p.pairingId)) continue;
      if (await _receive(p)) done.add(p.id);
    }
    if (done.isNotEmpty) await _host.pairing.ackPayloads(done);
  }

  bool _drop(String why) {
    logWarn('directory', 'dropped: $why');
    return true;
  }

  /// Reads [p]; false leaves it with the engine for a later read.
  Future<bool> _receive(PairingPayload p) async {
    if (p.bytes.length > directoryPayloadMaxBytes) return _drop('payload too large');
    final PairingRecord? rec;
    try {
      rec = await _host.pairing.pairing(p.pairingId);
    } on Object {
      return false;
    }
    if (rec == null || rec.state == PairingState.ended) return _drop('payload on a pairing that is gone');
    final DirectoryPayload payload;
    try {
      payload = DirectoryPayload.decode(Uint8List.fromList(p.bytes));
    } on DirectoryException {
      return _drop('payload not readable');
    }
    switch (payload) {
      case DirHello():
        return _receiveHello(rec, payload);
      case UnlistedPayload():
        return _receiveUnlisted(rec, payload);
      default:
        return _drop('payload type ${payload.type} from a directory');
    }
  }

  Future<bool> _receiveHello(PairingRecord rec, DirHello hello) async {
    if (rec.peerFeatures & featureDirectory == 0) return _drop('hello without the directory feature');
    final dkey = toHex(hello.dkey);
    final known = _book.byPairing(rec.id);
    // A directory this contact is already verified for: only a valid hello with a greater `issued`
    // can change its flags.
    if (rec.state == PairingState.verified && known != null && known.pinned) {
      final bind = sasIndexesOf(rec.sas);
      if (bind != null) {
        try {
          await verifyPayload(hello, net: _host.net, bind: bind, verifier: _host.verifier);
          final last = known.issued;
          if (last != null && hello.issued <= last) {
            // A replayed or repeated hello must not revert what a later one set.
            logDebug('directory', 'hello not newer (${hello.issued} <= $last): ignored');
          } else {
            await _put(
              _book.put(known.copyWith(noPayments: hello.takesNoPayments, payAs: () => hello.label, issued: hello.issued)),
            );
          }
        } on DirectoryException {
          // An unreadable repeat changes nothing.
        }
      }
      return true;
    }
    // Paired, or Verified when the hello came after the words step ended without it.
    if (rec.state != PairingState.paired && rec.state != PairingState.verified) {
      return _drop('hello on a pairing that is not waiting for the check');
    }
    final bind = sasIndexesOf(rec.sas);
    if (bind == null) return _drop('hello without words to bind to');
    try {
      await verifyPayload(hello, net: _host.net, bind: bind, verifier: _host.verifier);
    } on DirectoryException catch (e) {
      return _drop('hello refused (${e.error.wireName})');
    }
    final existing = _book.byDkey(dkey);
    if (existing != null && existing.pinned && existing.pairingId != rec.id) {
      // Another pairing already holds this directory: only one that is gone gives way.
      final other = await _host.pairing.pairing(existing.pairingId);
      if (other != null && other.state != PairingState.ended) return _drop('hello for a directory held by another pairing');
    }
    final next = (existing ?? DirectoryEntry(dkey: dkey, pairingId: rec.id, handle: toHex(hello.handle))).copyWith(
      pairingId: rec.id,
      handle: toHex(hello.handle),
      label: _labelOf(rec),
      pinned: existing != null && existing.pairingId == rec.id && existing.pinned,
      noPayments: hello.takesNoPayments,
      payAs: () => hello.label,
      issued: hello.issued,
      paymentsKey: () => _keyOf(rec.paymentsAddress),
    );
    await _put(_book.put(next));
    // A late hello: no words step of this session was waiting for it or showing its code.
    final step = _steps[rec.id];
    final late = step == null || step == HelloStep.words;
    if (late && next.noPayments && !(known?.noPayments ?? false) && !_lateNoPayments.isClosed) _lateNoPayments.add(next);
    return true;
  }

  Future<bool> _receiveUnlisted(PairingRecord rec, UnlistedPayload n) async {
    final e = _book.byPairing(rec.id);
    if (e == null || !e.pinned || e.dkey != toHex(n.dkey) || e.handle != toHex(n.handle)) {
      return _drop('unlisted for a directory or handle that is not known');
    }
    if (e.joined) await _put(_book.put(_retire(e, ListingState.unlisted)));
    return true;
  }

  /// [e] with its listed generation moved to the retired ones, read for [listingDrainWindow] more.
  DirectoryEntry _retire(DirectoryEntry e, ListingState state) {
    final gen = e.generation;
    final address = e.address;
    return e.copyWith(
      state: state,
      generation: () => null,
      address: () => null,
      retired: [
        ...e.retired,
        if (gen != null && address != null)
          RetiredListing(generation: gen, address: address, drainUntil: _clock().add(listingDrainWindow)),
      ],
    );
  }

  static String? _keyOf(String? address) {
    final k = address == null ? '' : epicboxKey(address);
    return k.isEmpty ? null : k;
  }

  String _labelOf(PairingRecord rec) => (rec.name ?? rec.label ?? '').trim();

  /// Keeps each entry's label as its pairing shows it; a joined entry whose pairing is gone
  /// can no longer be left, so its listing is retired and read out its window.
  Future<void> _refreshEntries() async {
    var next = _book;
    var changed = false;
    for (final e in _book.entries.values) {
      final PairingRecord? rec;
      try {
        rec = await _host.pairing.pairing(e.pairingId);
      } on Object {
        continue;
      }
      if (rec == null) {
        if (e.joined) {
          next = next.put(_retire(e, ListingState.notJoined));
          changed = true;
        }
        continue;
      }
      final label = _labelOf(rec);
      final key = _keyOf(rec.paymentsAddress);
      if ((label.isNotEmpty && label != e.label) || key != e.paymentsKey) {
        next = next.put(e.copyWith(label: label.isNotEmpty ? label : null, paymentsKey: () => key));
        changed = true;
      }
    }
    if (changed) await _put(next);
  }

  // The hello wait.

  final Map<String, HelloStep> _steps = {};
  final Map<String, DateTime> _deadlines = {};
  Timer? _pollTimer;

  /// Where the words step of [pairingId] stands, null before [beginHello].
  HelloStep? stepOf(String pairingId) => _steps[pairingId];

  /// Every pairing's step, for the screens' view.
  Map<String, HelloStep> get steps => Map.of(_steps);

  /// Starts the wait for the hello of [pairingId], or reports where it stands. A pairing whose
  /// peer does not claim the directory feature, or that is not Paired, is the ordinary words
  /// step. Safe to call again.
  Future<HelloStep> beginHello(String pairingId) async {
    final known = _steps[pairingId];
    if (known != null) return known;
    final PairingRecord? rec;
    try {
      rec = await _host.pairing.pairing(pairingId);
    } on Object {
      return HelloStep.words;
    }
    if (rec == null || rec.state != PairingState.paired || rec.peerFeatures & featureDirectory == 0) return HelloStep.words;
    if (_steps[pairingId] != null) return _steps[pairingId]!;
    final entry = _book.byPairing(pairingId);
    if (entry != null && !entry.pinned) return _setStep(pairingId, HelloStep.check);
    _deadlines[pairingId] = _clock().add(wait);
    _setStep(pairingId, HelloStep.waiting);
    _pollTimer ??= Timer.periodic(poll, (_) => unawaited(_pollHello()));
    unawaited(_pollHello(collect: false));
    return HelloStep.waiting;
  }

  HelloStep _setStep(String pairingId, HelloStep step) {
    if (_steps[pairingId] == step) return step;
    _steps[pairingId] = step;
    if (step != HelloStep.waiting) _deadlines.remove(pairingId);
    if (_deadlines.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
    _changed();
    return step;
  }

  bool _polling = false;

  Future<void> _pollHello({bool collect = true}) async {
    if (_polling || _disposed) return;
    _polling = true;
    try {
      if (_host.online) {
        try {
          if (collect) await _host.pairing.collect();
          await readPayloads();
        } on Object catch (e) {
          logWarn('directory', 'waiting for the hello failed: ${e.runtimeType}');
        }
      }
      final now = _clock();
      for (final id in _deadlines.keys.toList()) {
        if (_steps[id] != HelloStep.waiting) continue;
        final entry = _book.byPairing(id);
        if (entry != null && !entry.pinned) {
          _setStep(id, HelloStep.check);
        } else if (!now.isBefore(_deadlines[id]!)) {
          _setStep(id, HelloStep.words);
        }
      }
    } finally {
      _polling = false;
    }
  }

  /// Cancel on the wait, or its time ran out: the ordinary words step.
  void cancelHello(String pairingId) {
    if (_steps[pairingId] == HelloStep.waiting) _setStep(pairingId, HelloStep.words);
  }

  /// They match: the user compared the directory code and the verdict went through, so the dkey
  /// belongs to this contact. Call it after the words step's verdict call succeeded.
  Future<void> pin(String pairingId) async {
    final e = _book.byPairing(pairingId);
    if (e == null || e.pinned) return;
    await _put(_book.put(e.copyWith(pinned: true)));
  }

  /// They do not match: the directory is forgotten (the pairing ends in the words step's way).
  Future<void> dismiss(String pairingId) async {
    final e = _book.byPairing(pairingId);
    _steps[pairingId] = HelloStep.words;
    if (e == null || e.pinned) return;
    // An entry that never listed holds no generation: nothing to keep.
    await _put(e.maxGeneration < 0 ? _book.remove(e.dkey) : _book.put(e.copyWith(pinned: false)));
  }

  // Joining and leaving.

  /// The Epicbox server host a listing would use: the part of the listing address after `@`.
  Future<String> joinHost(String dkeyHex) async {
    final e = _book.byDkey(dkeyHex);
    final address = await _host.listingAddress(dkeyHex, e?.joined == true ? e!.generation! : (e?.nextGeneration ?? 0));
    return address.substring(address.indexOf('@') + 1);
  }

  int get _nowSeconds => _clock().millisecondsSinceEpoch ~/ 1000;

  Future<Uint8List> _signedCard(DirectoryEntry e, int generation, String address, int seq) async {
    final unsigned = listingCardUnsigned(
      net: _host.net,
      address: address,
      dkey: fromHex(e.dkey),
      handle: fromHex(e.handle),
      seq: seq,
      issued: _nowSeconds,
    );
    final sig = await _host.sign(e.dkey, generation, domainListing, unsigned);
    return withSignature(unsigned, sig);
  }

  /// Joins the directory [dkeyHex]: a new generation, its card signed by the listing key and
  /// posted over the pairing. Throws when the wallet is offline, the contact is not verified
  /// or the post fails (nothing is kept then).
  Future<void> join(String dkeyHex) async {
    final e = _book.byDkey(dkeyHex);
    if (e == null || !e.pinned) throw StateError('not a verified directory');
    if (e.joined) return;
    final generation = e.nextGeneration;
    final address = await _host.listingAddress(dkeyHex, generation);
    final seq = e.seq + 1;
    final card = await _signedCard(e, generation, address, seq);
    await _host.pairing.postPayload(id: e.pairingId, bytes: listingPayloadBytes(card));
    await _put(
      _book.put(
        e.copyWith(
          state: ListingState.joined,
          maxGeneration: generation,
          generation: () => generation,
          seq: seq,
          joinedAt: () => _clock(),
          address: () => address,
        ),
      ),
    );
    unawaited(_drainOne(dkeyHex, generation));
  }

  /// Leaves the directory: an `unlist` signed by the listing key is posted, the generation is
  /// retired and read for [listingDrainWindow] more. Throws when the post fails.
  Future<void> leave(String dkeyHex) async {
    final e = _book.byDkey(dkeyHex);
    final generation = e?.generation;
    final address = e?.address;
    if (e == null || !e.joined || generation == null || address == null) return;
    final unsigned = unlistPayloadUnsigned(
      net: _host.net,
      address: address,
      dkey: fromHex(e.dkey),
      handle: fromHex(e.handle),
      issued: _nowSeconds,
    );
    final sig = await _host.sign(e.dkey, generation, domainUnlist, unsigned);
    await _host.pairing.postPayload(id: e.pairingId, bytes: withSignature(unsigned, sig));
    await _put(_book.put(_retire(e, ListingState.notJoined)));
  }

  /// A new card with the next sequence number for a joined directory whose listing address
  /// moved with the wallet's home Epicbox server.
  Future<void> _followHome() async {
    for (final e in _book.entries.values.toList()) {
      final generation = e.generation;
      if (!e.joined || generation == null || e.address == null) continue;
      final String address;
      try {
        address = await _host.listingAddress(e.dkey, generation);
      } on Object {
        continue;
      }
      if (address == e.address) continue;
      try {
        final seq = e.seq + 1;
        final card = await _signedCard(e, generation, address, seq);
        await _host.pairing.postPayload(id: e.pairingId, bytes: listingPayloadBytes(card));
        await _put(_book.put(e.copyWith(seq: seq, address: () => address)));
      } on Object catch (error) {
        logWarn('directory', 'new card after a server move not posted: ${error.runtimeType}');
      }
    }
  }

  // Draining.

  Future<void> _drainOne(String dkeyHex, int generation) async {
    try {
      final report = await _host.drain(dkeyHex, generation);
      if (report.received > 0 || report.finalized > 0 || report.bounced > 0) onDrained?.call(report);
    } on Object catch (e) {
      logWarn('directory', 'listing drain failed: ${e.runtimeType}');
    }
  }

  /// Every live listing: the joined generation and the retired ones within their window.
  Future<void> _drainAll() async {
    final now = _clock();
    for (final e in _book.entries.values.toList()) {
      for (final l in e.live(now)) {
        if (_disposed) return;
        await _drainOne(e.dkey, l.generation);
      }
    }
  }
}
