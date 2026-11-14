// SPDX-License-Identifier: Apache-2.0
/// The open wallet's name services: contact pairings whose peer claims the name service feature and
/// proved it with a valid hello. The service reads the payloads of contact pairings (the devices
/// service leaves them alone), keeps the book ([NameServiceBook]), joins and leaves a name service,
/// and drains the listings. No part of it knows which service a name service is.
///
/// Nothing runs by itself in the background: the app calls [sync] on open, resume, unlock and
/// from its foreground tick, and the hello wait runs only while a screen shows it.
library;

// Private fields from public named parameters.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math' show min;
import 'dart:typed_data';

import '../log.dart';
import '../sas_table.dart';
import '../trust/policy.dart' show featureNameService;
import '../wallet_service.dart';
import 'base58.dart' show netFloonet, netMainnet;
import 'codes.dart' show listingCodeIndexes;
import 'name_service_model.dart';
import 'name_service_store.dart';
import 'membership.dart';
import 'receipts.dart' show NameServiceReceipts;
import 'verify.dart';
import 'wire.dart';

export '../sas_table.dart' show sasIndexesOf;

/// How long the wallet waits for the name service's hello once the pairing is Paired.
const Duration helloWait = Duration(seconds: 30);

/// The longest payload from a name service this wallet reads.
const int nameServicePayloadMaxBytes = 2048;

/// Why a sync runs.
enum NameServiceSyncTrigger { open, resume, unlock, tick }

/// Where the pairing words step stands for a name service.
enum HelloStep {
  /// Waiting for the hello (Cancel is offered).
  waiting,

  /// A valid hello came: compare the service code.
  check,

  /// No (valid) hello, or Cancel: the ordinary words step.
  words,
}

/// What the name service needs from the open wallet. The phone and the desktop each make
/// one over their session ([SessionNameServiceHost]).
abstract interface class NameServiceHost {
  PairingApi get pairing;

  /// The wallet's boosts: a wait for a hello checks the relays more often.
  Boosts get boosts;

  /// The channel may reach the servers now.
  bool get online;

  /// `0` mainnet, `1` floonet.
  int get net;

  /// The signature check of the wallet service.
  NameServiceVerifier get verifier;

  /// The listing address of [serviceKeyHex] at [generation], on the wallet's home Epicbox server.
  Future<String> listingAddress(String serviceKeyHex, int generation);

  Future<Uint8List> sign(String serviceKeyHex, int generation, String domain, Uint8List message);

  /// Reads that listing's address once.
  Future<PaymentsDrainReport> drain(String serviceKeyHex, int generation);

  /// Reads each of [listings] once, one result per listing in the order given. At most
  /// [listingDrainBatch] at a time; fails as a whole only before any relay is contacted.
  Future<List<ListingDrainResult>> drainMany(List<ListingDrain> listings);
}

/// A listing to read: the service's key in hex and the listing's generation.
typedef ListingDrain = ({String serviceKeyHex, int generation});

/// The most listings one drain call takes (LEPIC's limit).
const listingDrainBatch = 16;

/// A [NameServiceHost] over a [WalletSession]; a session without listing keys refuses.
class SessionNameServiceHost implements NameServiceHost {
  SessionNameServiceHost(this._session, {required this.net, required this.verifier, required bool Function() online})
    : _online = online;

  final WalletSession _session;
  final bool Function() _online;
  @override
  final int net;
  @override
  final NameServiceVerifier verifier;

  ListingKeys get _keys =>
      _session.listingKeys ?? (throw const WalletError(kind: WalletErrorKind.other, message: 'listing keys need LEPIC with name services'));

  @override
  PairingApi get pairing => _session.pairing;

  @override
  Boosts get boosts => _session.boosts;

  @override
  bool get online => _online();

  @override
  Future<String> listingAddress(String serviceKeyHex, int generation) => _keys.listingAddress(serviceKeyHex, generation);

  @override
  Future<Uint8List> sign(String serviceKeyHex, int generation, String domain, Uint8List message) =>
      _keys.signWithListing(serviceKeyHex, generation, domain, message);

  @override
  Future<PaymentsDrainReport> drain(String serviceKeyHex, int generation) => _keys.drainListing(serviceKeyHex, generation);

  @override
  Future<List<ListingDrainResult>> drainMany(List<ListingDrain> listings) => _keys.drainListings([for (final l in listings) (l.serviceKeyHex, l.generation)]);
}

/// The net byte of a chain.
int netOfChain(Chain chain) => chain == Chain.mainnet ? netMainnet : netFloonet;

class NameService implements NameServiceMembership, NameServiceReceipts {
  NameService({
    required NameServiceHost host,
    required NameServiceStore store,
    DateTime Function()? clock,
    this.wait = helloWait,
    this.onDrained,
  }) : _host = host,
       _store = store,
       _clock = clock ?? DateTime.now;

  final NameServiceHost _host;
  final NameServiceStore _store;
  final DateTime Function() _clock;

  /// How long the hello is waited for.
  final Duration wait;

  /// A listing drain received or finalized something: the lists read again.
  final void Function(PaymentsDrainReport report)? onDrained;

  NameServiceBook _book = const NameServiceBook();
  bool _loaded = false;
  bool _disposed = false;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  NameServiceBook get book => _book;
  bool get loaded => _loaded;
  Stream<void> get changes => _changes.stream;

  /// The name service of the pairing [pairingId] the user compared the code of, or null.
  NameServiceEntry? verifiedFor(String pairingId) {
    final e = _book.byPairing(pairingId);
    return e != null && e.pinned ? e : null;
  }

  NameServiceEntry? entryOf(String serviceKeyHex) => _book.byServiceKey(serviceKeyHex);

  // Membership, for readers outside (Send from a link).

  @override
  String? labelFor(String serviceKeyHex) {
    final e = _book.byServiceKey(serviceKeyHex);
    return e != null && e.pinned && e.label.isNotEmpty ? e.label : null;
  }

  @override
  String? listingKeyFor(String serviceKeyHex) {
    final e = _book.byServiceKey(serviceKeyHex);
    final address = e?.joined == true ? e?.address : null;
    if (address == null) return null;
    return parseListingAddress(address)?.keyText;
  }

  // Receipts, for a payment made from a link.

  NameServiceEntry? _usable(String serviceKeyHex) {
    final e = _book.byServiceKey(serviceKeyHex);
    return e != null && e.pinned ? e : null;
  }

  @override
  bool canTell(String serviceKeyHex) => _usable(serviceKeyHex) != null;

  @override
  Future<bool> post(String serviceKeyHex, Uint8List payload) async {
    final e = _usable(serviceKeyHex);
    if (e == null) return false;
    try {
      await _host.pairing.postPayload(id: e.pairingId, bytes: payload);
      return true;
    } on Object {
      return false;
    }
  }

  /// The four indexes of the listing code of a joined name service (the key of this wallet's
  /// listing), or null when it is not joined.
  List<int>? listingCodeFor(String serviceKeyHex) {
    final e = _book.byServiceKey(serviceKeyHex);
    final address = e?.joined == true ? e?.address : null;
    final parsed = address == null ? null : parseListingAddress(address);
    return parsed == null ? null : listingCodeIndexes(parsed.key);
  }

  void _changed() {
    if (!_disposed && !_changes.isClosed) _changes.add(null);
  }

  Future<void> _put(NameServiceBook next) async {
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
    for (final end in _endBoosts.values) {
      end();
    }
    _changes.close();
  }

  // Reading.

  bool _busy = false;
  bool _again = false;

  /// One read: the payloads of contact pairings, the home-server move, then the drains.
  Future<void> sync(NameServiceSyncTrigger trigger) async {
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
          logWarn('name service', 'name service read failed: ${e.runtimeType}');
        }
      } while (_again && !_disposed);
      _settleHellos();
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
    logWarn('name service', 'dropped: $why');
    return true;
  }

  /// Reads [p]; false leaves it with the engine for a later read.
  Future<bool> _receive(PairingPayload p) async {
    if (p.bytes.length > nameServicePayloadMaxBytes) return _drop('payload too large');
    final PairingRecord? rec;
    try {
      rec = await _host.pairing.pairing(p.pairingId);
    } on Object {
      return false;
    }
    if (rec == null || rec.state == PairingState.ended) return _drop('payload on a pairing that is gone');
    final NameServicePayload payload;
    try {
      payload = NameServicePayload.decode(Uint8List.fromList(p.bytes));
    } on NameServiceException {
      return _drop('payload not readable');
    }
    switch (payload) {
      case DirHello():
        return _receiveHello(rec, payload);
      case UnlistedPayload():
        return _receiveUnlisted(rec, payload);
      default:
        return _drop('payload type ${payload.type} from a name service');
    }
  }

  Future<bool> _receiveHello(PairingRecord rec, DirHello hello) async {
    if (rec.peerFeatures & featureNameService == 0) return _drop('hello without the name service feature');
    final serviceKey = toHex(hello.serviceKey);
    final known = _book.byPairing(rec.id);
    // A name service this contact is already verified for: only a valid hello with a greater `issued`
    // can change its label.
    if (rec.state == PairingState.verified && known != null && known.pinned) {
      final bind = sasIndexesOf(rec.sas);
      if (bind != null) {
        try {
          await verifyPayload(hello, net: _host.net, bind: bind, verifier: _host.verifier);
          final last = known.issued;
          if (last != null && hello.issued <= last) {
            // A replayed or repeated hello must not revert what a later one set.
            logDebug('name service', 'hello not newer (${hello.issued} <= $last): ignored');
          } else {
            await _put(
              _book.put(known.copyWith(payAs: () => hello.label, issued: hello.issued)),
            );
          }
        } on NameServiceException {
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
    } on NameServiceException catch (e) {
      return _drop('hello refused (${e.error.wireName})');
    }
    final existing = _book.byServiceKey(serviceKey);
    if (existing != null && existing.pinned && existing.pairingId != rec.id) {
      // Another pairing already holds this name service: only one that is gone gives way.
      final other = await _host.pairing.pairing(existing.pairingId);
      if (other != null && other.state != PairingState.ended) return _drop('hello for a name service held by another pairing');
    }
    final next = (existing ?? NameServiceEntry(serviceKey: serviceKey, pairingId: rec.id, handle: toHex(hello.handle))).copyWith(
      pairingId: rec.id,
      handle: toHex(hello.handle),
      label: _labelOf(rec),
      pinned: existing != null && existing.pairingId == rec.id && existing.pinned,
      payAs: () => hello.label,
      issued: hello.issued,
      paymentsKey: () => _keyOf(rec.paymentsAddress),
    );
    await _put(_book.put(next));
    return true;
  }

  Future<bool> _receiveUnlisted(PairingRecord rec, UnlistedPayload n) async {
    final e = _book.byPairing(rec.id);
    if (e == null || !e.pinned || e.serviceKey != toHex(n.serviceKey) || e.handle != toHex(n.handle)) {
      return _drop('unlisted for a name service or handle that is not known');
    }
    if (e.joined) await _put(_book.put(_retire(e, ListingState.unlisted)));
    return true;
  }

  /// [e] with its listed generation moved to the retired ones, read for [listingDrainWindow] more.
  NameServiceEntry _retire(NameServiceEntry e, ListingState state) {
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
  final Map<String, void Function()> _endBoosts = {};

  /// Where the words step of [pairingId] stands, null before [beginHello].
  HelloStep? stepOf(String pairingId) => _steps[pairingId];

  /// Every pairing's step, for the screens' view.
  Map<String, HelloStep> get steps => Map.of(_steps);

  /// Starts the wait for the hello of [pairingId], or reports where it stands. A pairing whose
  /// peer does not claim the name service feature, or that is not Paired, is the ordinary words
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
    if (rec == null || rec.state != PairingState.paired || rec.peerFeatures & featureNameService == 0) return HelloStep.words;
    if (_steps[pairingId] != null) return _steps[pairingId]!;
    final entry = _book.byPairing(pairingId);
    if (entry != null && !entry.pinned) return _setStep(pairingId, HelloStep.check);
    _deadlines[pairingId] = _clock().add(wait);
    _setStep(pairingId, HelloStep.waiting);
    // The regular collect brings the hello: it runs every 10 s for the wait.
    _endBoosts[pairingId] = boostRelays(_host.boosts, const Duration(seconds: 10), window: wait);
    unawaited(sync(NameServiceSyncTrigger.tick));
    return HelloStep.waiting;
  }

  HelloStep _setStep(String pairingId, HelloStep step) {
    if (_steps[pairingId] == step) return step;
    _steps[pairingId] = step;
    if (step != HelloStep.waiting) {
      _deadlines.remove(pairingId);
      _endBoosts.remove(pairingId)?.call();
    }
    _changed();
    return step;
  }

  /// After a read: a wait whose hello came goes on to the check, one past its time to the
  /// ordinary words.
  void _settleHellos() {
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
  }

  /// Cancel on the wait, or its time ran out: the ordinary words step.
  void cancelHello(String pairingId) {
    if (_steps[pairingId] == HelloStep.waiting) _setStep(pairingId, HelloStep.words);
  }

  /// They match: the user compared the service code and the verdict went through, so the serviceKey
  /// belongs to this contact. Call it after the words step's verdict call succeeded.
  Future<void> pin(String pairingId) async {
    final e = _book.byPairing(pairingId);
    if (e == null || e.pinned) return;
    await _put(_book.put(e.copyWith(pinned: true)));
  }

  /// They do not match: the name service is forgotten (the pairing ends in the words step's way).
  Future<void> dismiss(String pairingId) async {
    final e = _book.byPairing(pairingId);
    _steps[pairingId] = HelloStep.words;
    if (e == null || e.pinned) return;
    // An entry that never listed holds no generation: nothing to keep.
    await _put(e.maxGeneration < 0 ? _book.remove(e.serviceKey) : _book.put(e.copyWith(pinned: false)));
  }

  // Joining and leaving.

  /// The Epicbox server host a listing would use: the part of the listing address after `@`.
  Future<String> joinHost(String serviceKeyHex) async {
    final e = _book.byServiceKey(serviceKeyHex);
    final address = await _host.listingAddress(serviceKeyHex, e?.joined == true ? e!.generation! : (e?.nextGeneration ?? 0));
    return address.substring(address.indexOf('@') + 1);
  }

  int get _nowSeconds => _clock().millisecondsSinceEpoch ~/ 1000;

  Future<Uint8List> _signedCard(NameServiceEntry e, int generation, String address, int seq) async {
    final unsigned = listingCardUnsigned(
      net: _host.net,
      address: address,
      serviceKey: fromHex(e.serviceKey),
      handle: fromHex(e.handle),
      seq: seq,
      issued: _nowSeconds,
    );
    final sig = await _host.sign(e.serviceKey, generation, domainListing, unsigned);
    return withSignature(unsigned, sig);
  }

  /// Joins the name service [serviceKeyHex]: a new generation, its card signed by the listing key and
  /// posted over the pairing. Throws when the wallet is offline, the contact is not verified
  /// or the post fails (nothing is kept then).
  Future<void> join(String serviceKeyHex) async {
    final e = _book.byServiceKey(serviceKeyHex);
    if (e == null || !e.pinned) throw StateError('not a verified name service');
    if (e.joined) return;
    final generation = e.nextGeneration;
    final address = await _host.listingAddress(serviceKeyHex, generation);
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
    unawaited(_drainOne(serviceKeyHex, generation));
  }

  /// Leaves the name service: an `unlist` signed by the listing key is posted, the generation is
  /// retired and read for [listingDrainWindow] more. Throws when the post fails.
  Future<void> leave(String serviceKeyHex) async {
    final e = _book.byServiceKey(serviceKeyHex);
    final generation = e?.generation;
    final address = e?.address;
    if (e == null || !e.joined || generation == null || address == null) return;
    final unsigned = unlistPayloadUnsigned(
      net: _host.net,
      address: address,
      serviceKey: fromHex(e.serviceKey),
      handle: fromHex(e.handle),
      issued: _nowSeconds,
    );
    final sig = await _host.sign(e.serviceKey, generation, domainUnlist, unsigned);
    await _host.pairing.postPayload(id: e.pairingId, bytes: withSignature(unsigned, sig));
    await _put(_book.put(_retire(e, ListingState.notJoined)));
  }

  /// A new card with the next sequence number for a joined name service whose listing address
  /// moved with the wallet's home Epicbox server.
  Future<void> _followHome() async {
    for (final e in _book.entries.values.toList()) {
      final generation = e.generation;
      if (!e.joined || generation == null || e.address == null) continue;
      final String address;
      try {
        address = await _host.listingAddress(e.serviceKey, generation);
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
        logWarn('name service', 'new card after a server move not posted: ${error.runtimeType}');
      }
    }
  }

  // Draining.

  void _drained(PaymentsDrainReport report) {
    if (report.received > 0 || report.finalized > 0 || report.bounced > 0) onDrained?.call(report);
  }

  Future<void> _drainOne(String serviceKeyHex, int generation) async {
    try {
      _drained(await _host.drain(serviceKeyHex, generation));
    } on Object catch (e) {
      logWarn('name service', 'listing drain failed: ${e.runtimeType}');
    }
  }

  /// Every live listing: the joined generation and the retired ones within their window.
  Future<void> _drainAll() async {
    final now = _clock();
    final all = <ListingDrain>[
      for (final e in _book.entries.values.toList())
        for (final l in e.live(now)) (serviceKeyHex: e.serviceKey, generation: l.generation),
    ];
    for (var i = 0; i < all.length; i += listingDrainBatch) {
      if (_disposed) return;
      final batch = all.sublist(i, min(i + listingDrainBatch, all.length));
      try {
        for (final r in await _host.drainMany(batch)) {
          if (r.report case final report?) _drained(report);
          if (r.error case final error?) logWarn('name service', 'listing drain failed: ${error.kind.name}');
        }
      } on Object catch (e) {
        // The call failed as a whole, before any relay was contacted: this batch is left for the
        // next drain, the next batch goes on.
        logWarn('name service', 'listing drain failed: ${e.runtimeType}');
      }
    }
  }
}
