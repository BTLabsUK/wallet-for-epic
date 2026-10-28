/// Linked devices at work for one open wallet: linking, the notices between devices, the coins
/// they hold, the runs that read the channel. Shared by the phone and the desktop; each app
/// gives it a [DeviceHost] and wraps it in its providers (`device_providers.dart`).
///
/// Receiving, in one path ([_receive]): the payload must come through a private pairing of a
/// linked device and name that device → at most [deviceNoticeMaxBytes] (before parsing) → not
/// seen before (by id) → in order (by seq, waiting up to [noticeWindow] ahead and [gapWait] for
/// a missing one) → a body valid for its type → its handler in [_handlers]. Anything else is
/// dropped and logged without amounts or addresses. A newer version or an unknown type keeps its
/// place in the order and is ignored.
///
/// Sending, in one path ([_send]): numbered per device, stamped, kept in the book's outbox and
/// posted to every pairing of the device (one per server).
///
/// What a notice can do here: hold or release coins, add history details, rename its device,
/// propose servers (the user accepts here), make a further pairing with this device over the
/// confirmed channel (second server, re-key), and remove a device. It never sends, signs or
/// changes a setting on its own.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../log.dart';
import '../models.dart';
import '../pairing_api.dart';
import '../scan/scan_router.dart' show cleanUntrustedText;
import '../wallet_service.dart' show WalletSession;
import 'device_link_code.dart';
import 'device_locks.dart';
import 'device_model.dart';
import 'device_store.dart';
import 'device_wire.dart';

/// What the service needs from the open wallet. [SessionDeviceHost] gives it from a
/// [WalletSession]; an app may give its own.
abstract interface class DeviceHost {
  /// The wallet's pairing engine, whatever the Pairing switch says.
  PairingApi get pairing;

  /// Whether the channel may reach the servers now (not Offline, Epicbox on).
  bool get online;

  /// This wallet's payments key (its Epicbox address without the server).
  Future<String> walletKey();

  /// [message] signed with this wallet's address key ([WalletSession.signWithAddressKey]).
  Future<String> signProof(List<int> message);

  /// Whether [signature] is [signProof] of [message] by the wallet with payments key [key].
  Future<bool> verifyProof(String key, List<int> message, String signature);

  Future<List<WalletOutput>> outputs();

  /// This wallet's history as the session lists it, chain-check rows included.
  Future<List<TxEntry>> transactions();

  /// The chain height last seen, or null.
  Future<int?> tipHeight();

  /// The coins every send, estimate and Send all leaves out ([WalletSession.heldOutputs]).
  set heldOutputs(Set<String> commitments);
}

class SessionDeviceHost implements DeviceHost {
  SessionDeviceHost(this.session, {bool Function()? online, BigInt? minimumConfirmations})
    : _online = online ?? (() => true),
      _confirmations = minimumConfirmations ?? BigInt.from(defaultMinimumConfirmations);

  final WalletSession session;
  final bool Function() _online;
  final BigInt _confirmations;

  @override
  PairingApi get pairing => session.pairing;

  @override
  bool get online => _online();

  @override
  Future<String> walletKey() async => epicboxKey(await session.epicboxAddress());

  @override
  Future<String> signProof(List<int> message) => session.signWithAddressKey(message);

  @override
  Future<bool> verifyProof(String key, List<int> message, String signature) =>
      session.verifyAddressSignature(key: key, message: message, signature: signature);

  @override
  Future<List<WalletOutput>> outputs() => session.outputs();

  @override
  Future<List<TxEntry>> transactions() => session.transactions(refresh: false);

  @override
  Future<int?> tipHeight() async =>
      (await session.summary(refresh: false, minimumConfirmations: _confirmations)).lastConfirmedHeight.toInt();

  @override
  set heldOutputs(Set<String> commitments) => session.heldOutputs = commitments;
}

/// What a hello's `proof` signs: a tag, the sending device's id and the four pictures of the
/// link's private pairing, which both devices see alike and LEPIC derives from both sides' keys,
/// so a proof holds for this pairing and sender only. JSON keeps the parts apart.
List<int> helloTranscript(String deviceId, List<SasWord> sas) =>
    utf8.encode(jsonEncode(['epiccash/device-link/hello/v1', deviceId, for (final w in sas) w.name]));

/// How far ahead of the next expected notice one is kept; further ones are dropped.
const int noticeWindow = 64;

/// How long a missing notice is waited for before the ones after it apply.
const Duration gapWait = Duration(hours: 1);

/// How often the channel is read in the foreground with a device linked (D-11), and while a link
/// is being made.
const Duration deviceSyncEvery = Duration(seconds: 5);
const Duration linkPollEvery = Duration(seconds: 2);

/// How long Send waits for one read of the channel before it chooses coins.
const Duration sendWaitsForDevices = Duration(seconds: 3);

/// How long a link waits for the other device's check once this one matched.
const Duration linkCheckWait = Duration(minutes: 10);

/// The ids of notices remembered per device for duplicates.
const int _seenIdsKept = 200;

/// Why a link did not complete.
enum LinkFailure {
  /// The text or QR is not a device link, or it is damaged.
  invalidCode,

  /// The code's time ran out.
  expired,

  /// The code was used already or no longer exists.
  notFound,

  /// The code is this device's own.
  ownCode,

  /// The other device holds another wallet: its hello did not prove this wallet.
  otherWallet,

  /// The scanned code was made by another wallet; refused before answering it.
  otherWalletCode,

  /// The pictures did not match on this device.
  mismatch,

  /// The other device cancelled, or did not confirm in time.
  cancelled,

  /// [maxLinkedDevices] devices are linked already.
  tooMany,

  /// No server answered.
  unreachable,

  /// This wallet's core cannot link devices yet.
  unsupported,
}

enum LinkRole { shows, scans }

enum LinkPhase {
  /// Making the code, or answering one.
  starting,

  /// The code is on screen (shows) or the answer went out (scans): waiting for the other.
  waiting,

  /// Both are paired: the user compares the four pictures.
  checking,

  /// This device matched; waiting for the other device's check.
  waitingOther,
  done,
  failed,
}

/// A link being made on this device.
class LinkFlow {
  const LinkFlow({
    required this.role,
    required this.phase,
    this.servers = const [],
    this.pairingId,
    this.code,
    this.expiresAt,
    this.sas = const [],
    this.otherName,
    this.failure,
    this.device,
  });

  final LinkRole role;
  final LinkPhase phase;
  final List<String> servers;
  final String? pairingId;

  /// The device link text (shows).
  final String? code;
  final DateTime? expiresAt;
  final List<SasWord> sas;
  final String? otherName;
  final LinkFailure? failure;

  /// The device once linked.
  final LinkedDevice? device;

  LinkFlow to(
    LinkPhase phase, {
    String? pairingId,
    List<SasWord>? sas,
    String? otherName,
    LinkFailure? failure,
    LinkedDevice? device,
    List<String>? servers,
  }) => LinkFlow(
    role: role,
    phase: phase,
    servers: servers ?? this.servers,
    pairingId: pairingId ?? this.pairingId,
    code: code,
    expiresAt: expiresAt,
    sas: sas ?? this.sas,
    otherName: otherName ?? this.otherName,
    failure: failure ?? this.failure,
    device: device ?? this.device,
  );
}

/// The state of the other side of a link in the making, kept beside [LinkFlow].
class _LinkPeer {
  bool matchedHere = false;
  DateTime? matchedAt;
  Notice? hello;
}

/// The link server of a pairing whose core names it [relay] (`host` or `host:port`): the host
/// alone for the TLS port, as the link's servers are written; null while the core names none.
String? linkServerOf(String? relay) {
  final r = relay?.trim().toLowerCase() ?? '';
  if (r.isEmpty) return null;
  return r.endsWith(':443') ? r.substring(0, r.length - 4) : r;
}

/// Why the service reads the channel now (D-11).
enum DeviceSyncTrigger { start, resume, unlock, refresh, tick, beforeSend, link }

class DeviceService {
  DeviceService({required this.host, required this.store, required this.defaultName, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DeviceHost host;
  final DeviceStore store;

  /// This device's name until the user renames it ("Phone", "Desktop").
  final String defaultName;
  final DateTime Function() _clock;

  DeviceBook? _book;
  LinkFlow? _link;
  _LinkPeer _peer = _LinkPeer();
  final StreamController<void> _changes = StreamController<void>.broadcast();
  Future<void>? _running;
  Timer? _timer;
  bool _foreground = false;
  bool _disposed = false;

  PairingApi get _api => host.pairing;

  /// Every change of [book] or [link].
  Stream<void> get changes => _changes.stream;

  DeviceBook get book => _book ?? DeviceBook(deviceId: '0' * 32, deviceName: defaultName);

  bool get loaded => _book != null;

  /// The link being made, or null.
  LinkFlow? get link => _link;

  /// The core links devices.
  bool get supported => _api.privateSupported;

  Future<void> load() async {
    _book ??= await store.load(defaultName: defaultName);
    host.heldOutputs = book.heldCommitments;
    _changed();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _changes.close();
  }

  void _changed() {
    if (!_disposed) _changes.add(null);
  }

  String? _saved;

  /// Makes [next] the book, stores it when it changed and tells the listeners.
  Future<void> _put(DeviceBook next) async {
    _book = next;
    host.heldOutputs = next.heldCommitments;
    final json = jsonEncode(next.toJson());
    if (json == _saved) return;
    _saved = json;
    await store.save(next);
    _changed();
  }

  // Runs (D-11): start, resume, unlock and refresh read the channel once; while in the
  // foreground with a device linked it is read every [deviceSyncEvery].

  /// The app is on screen ([on]) or not: the timer runs only while it is.
  void setForeground(bool on) {
    _foreground = on;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_foreground || _disposed) return;
    final every = _link != null && _link!.phase != LinkPhase.done && _link!.phase != LinkPhase.failed
        ? linkPollEvery
        : book.devices.isNotEmpty
        ? deviceSyncEvery
        : null;
    if (every == null) return;
    _timer = Timer.periodic(every, (_) => sync(DeviceSyncTrigger.tick).ignore());
  }

  /// Reads the channel once (one at a time: a call while one runs waits for it).
  Future<void> sync(DeviceSyncTrigger trigger) {
    final running = _running;
    if (running != null) return running;
    final run = _sync(trigger).whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  /// Before Send chooses coins: one read, waited for at most [sendWaitsForDevices].
  Future<void> beforeSend() async {
    if (book.devices.isEmpty) return;
    try {
      await sync(DeviceSyncTrigger.beforeSend).timeout(sendWaitsForDevices);
    } on Object {
      // Send goes on with what is known; the chain check covers the rest.
    }
  }

  Future<void> _sync(DeviceSyncTrigger trigger) async {
    if (!loaded) await load();
    final reach = !book.paused && host.online && _api.privateSupported;
    final flow = _link;
    final linking = flow != null && flow.pairingId != null && flow.phase != LinkPhase.done && flow.phase != LinkPhase.failed;
    if (reach && (book.devices.isNotEmpty || linking)) {
      try {
        await _api.collectPrivate(only: [for (final d in book.devices) ...d.pairingIds, if (linking) flow.pairingId!]);
        // Payloads first: a hello that came before its pairing ended still answers the link.
        await _readPayloads();
        if (linking) await _pollLink();
        await _checkPairings();
      } on Object catch (e) {
        logWarn('devices', 'reading linked devices failed: ${_kind(e)}');
      }
    }
    try {
      await _announce();
      if (reach) await _flush();
      await _sweep();
    } on Object catch (e) {
      logWarn('devices', 'linked devices check failed: ${_kind(e)}');
    }
  }

  // Receiving.

  Future<void> _readPayloads() async {
    final list = await _api.payloads();
    if (list.isEmpty) {
      // A notice waiting for a missing one may be due now.
      await _applyWaitingAll();
      return _put(book);
    }
    final done = <String>[];
    for (final p in list) {
      if (await _receive(p)) done.add(p.id);
    }
    await _applyWaitingAll();
    await _put(book);
    if (done.isNotEmpty) await _api.ackPayloads(done);
  }

  /// Reads [p]; false leaves it with the engine for a later read (a notice for a link that is
  /// not finished here yet).
  Future<bool> _receive(PairingPayload p) async {
    final flow = _link;
    if (flow != null && flow.pairingId == p.pairingId && book.deviceOfPairing(p.pairingId) == null) return _receiveLink(p);
    final device = book.deviceOfPairing(p.pairingId);
    if (device == null) return _drop('payload on a pairing of no linked device');
    if (p.bytes.length > deviceNoticeMaxBytes) return _drop('notice too large');
    final decoded = decodeNotice(p.bytes);
    final n = decoded.notice;
    if (n == null) return _drop('notice not readable (${decoded.drop?.name})');
    if (n.dev != device.deviceId) return _drop('notice names another device than its pairing');
    if (device.seenIds.contains(n.id) || n.seq <= device.seqIn) return true;
    if (n.seq > device.seqIn + noticeWindow) return _drop('notice too far ahead');
    _book = book.withDevice(
      device.copyWith(
        waiting: {...device.waiting, n.seq: (json: jsonEncode(n.toJson()), at: _clock())},
        seenIds: _keepIds([...device.seenIds, n.id]),
      ),
    );
    await _applyWaiting(device.deviceId);
    return true;
  }

  static List<String> _keepIds(List<String> ids) => ids.length <= _seenIdsKept ? ids : ids.sublist(ids.length - _seenIdsKept);

  bool _drop(String why) {
    logWarn('devices', 'dropped: $why');
    return true;
  }

  Future<void> _applyWaitingAll() async {
    for (final d in [...book.devices]) {
      if (d.waiting.isNotEmpty) await _applyWaiting(d.deviceId);
    }
  }

  /// Applies the waiting notices of [deviceId] in order; past [gapWait] a missing one is given
  /// up and the next present one applies.
  Future<void> _applyWaiting(String deviceId) async {
    while (true) {
      final d = book.device(deviceId);
      if (d == null || d.waiting.isEmpty) return;
      var next = d.seqIn + 1;
      var entry = d.waiting[next];
      if (entry == null) {
        final first = (d.waiting.keys.toList()..sort()).first;
        if (_clock().difference(d.waiting[first]!.at) < gapWait) return;
        logWarn('devices', 'notices ${d.seqIn + 1}..${first - 1} never came; going on');
        next = first;
        entry = d.waiting[first]!;
      }
      final waiting = {...d.waiting}..remove(next);
      _book = book.withDevice(d.copyWith(seqIn: next, waiting: waiting, lastSeen: _clock()));
      final n = noticeFromJson(jsonDecode(entry.json));
      if (n != null) await _dispatch(deviceId, n);
    }
  }

  Future<void> _dispatch(String deviceId, Notice n) async {
    if (!n.readable) {
      logInfo('devices', 'ignored a notice of version ${n.v}, type ${n.typeName}');
      return;
    }
    if (!noticeBodyValid(n.type!, n.body)) {
      logWarn('devices', 'dropped: ${n.type!.name} notice with a bad body');
      return;
    }
    final from = book.device(deviceId);
    if (from == null) return;
    await _handlers[n.type!]!(from, n);
  }

  /// One handler per notice type.
  late final Map<NoticeType, Future<void> Function(LinkedDevice from, Notice n)> _handlers = {
    NoticeType.hello: _onHello,
    NoticeType.send: _onSend,
    NoticeType.status: _onStatus,
    NoticeType.rename: _onRename,
    NoticeType.servers: _onServers,
    NoticeType.serversOk: _onServersOk,
    NoticeType.pair2: _onPair2,
    NoticeType.pair2ok: _onPair2Ok,
    NoticeType.pair2done: _onPair2Done,
    NoticeType.unlink: _onUnlink,
    NoticeType.removed: _onRemoved,
    NoticeType.snapshotRequest: _reserved,
    NoticeType.snapshot: _reserved,
  };

  Future<void> _reserved(LinkedDevice from, Notice n) async {}

  // A hello again from a linked device changes nothing but its name.
  Future<void> _onHello(LinkedDevice from, Notice n) async {
    final name = _shownName(n.body['name'], from.name);
    if (name != from.name) _book = book.withDevice(from.copyWith(name: name));
  }

  Future<void> _onRename(LinkedDevice from, Notice n) async {
    _book = book.withDevice(from.copyWith(name: _shownName(n.body['name'], from.name)));
  }

  /// A device's name as the user reads it: plain text, no direction marks or invisible
  /// characters ([cleanUntrustedText]); [fallback] when nothing is left.
  static String _shownName(Object? name, String fallback) => cleanUntrustedText(name as String) ?? fallback;

  // A linked device is the same wallet's, but what its notices hold is bounded: no more than
  // [maxOpenHoldsPerDevice] payments at once, never coins the user released from it by hand, and
  // never a payment larger than the coins it names.
  Future<void> _onSend(LinkedDevice from, Notice n) async {
    final slateId = n.body['slateId'] as String;
    if (book.holds.any((h) => h.deviceId == from.deviceId && h.slateId == slateId)) return;
    final value = {
      for (final o in await host.outputs())
        if (o.status == WalletOutputStatus.unspent || o.status == WalletOutputStatus.locked) o.commitment: o.value,
    };
    final hold = holdFromSend(deviceId: from.deviceId, deviceName: from.name, body: n.body, own: value.keys.toSet(), now: _clock());
    if (hold == null) {
      _drop('send notice for coins this wallet does not hold');
      return;
    }
    final mine = [for (final h in book.holds) if (h.deviceId == from.deviceId) h];
    if (mine.where((h) => h.state.holds).length >= maxOpenHoldsPerDevice) {
      _drop('send notice past the open holds a device may have');
      return;
    }
    final released = {for (final h in mine) if (h.state == HoldState.byHand) ...h.commitments};
    if (hold.commitments.any(released.contains)) {
      _drop('send notice for coins released by hand');
      return;
    }
    final inputs = hold.commitments.fold(BigInt.zero, (sum, c) => sum + (value[c] ?? BigInt.zero));
    if (hold.amount + (hold.fee ?? BigInt.zero) > inputs) {
      _drop('send notice for more than its coins hold');
      return;
    }
    _book = book.copyWith(holds: [...book.holds, hold]);
  }

  Future<void> _onStatus(LinkedDevice from, Notice n) async {
    final slateId = n.body['slateId'] as String;
    // Only the device that held the coins releases them.
    final i = book.holds.indexWhere((h) => h.deviceId == from.deviceId && h.slateId == slateId);
    if (i < 0) {
      _drop('status for a payment this device never held');
      return;
    }
    final next = applyStatus(
      book.holds[i],
      n.body['state'] as String,
      height: n.body['height'] as int?,
      kernel: n.body['kernel'] as String?,
      why: n.body['why'] as String?,
      spent: spentFor(book.holds[i], book.holds, await _spent()),
      now: _clock(),
    );
    _book = book.copyWith(holds: [...book.holds]..[i] = next);
  }

  // Servers: a proposal from another device waits for the user here.
  Future<void> _onServers(LinkedDevice from, Notice n) async {
    final version = n.body['version'] as int;
    final set = [for (final s in n.body['set'] as List) s as String];
    final mine = book.proposal;
    if (version <= book.serversVersion) return;
    if (mine != null && mine.fromHere && (mine.version > version || (mine.version == version && book.deviceId.compareTo(from.deviceId) > 0))) return;
    _book = book.copyWith(proposal: ServerProposal(servers: set, version: version, fromHere: false, accepted: {from.deviceId}));
  }

  Future<void> _onServersOk(LinkedDevice from, Notice n) async {
    final p = book.proposal;
    if (p == null || !p.fromHere || p.version != n.body['version']) return;
    final accepted = p.accept(from.deviceId);
    if (book.devices.every((d) => accepted.accepted.contains(d.deviceId))) {
      _book = book.copyWith(servers: p.servers, serversVersion: p.version, clearProposal: true);
      for (final d in book.devices) {
        await _moveToServers(d.deviceId);
      }
    } else {
      _book = book.copyWith(proposal: accepted);
    }
  }

  /// Makes pairings with [deviceId] on the link's servers it lacks; the ones on servers no
  /// longer in the set go once a new one is confirmed ([_dropOldServers]).
  Future<void> _moveToServers(String deviceId) async {
    final d = book.device(deviceId);
    if (d == null) return;
    final adding = [for (final s in book.servers) if (!d.pairings.containsKey(s) && !d.pending.any((p) => p.server == s)) s];
    for (final s in adding) {
      await _invite(deviceId, s);
    }
    if (adding.isEmpty) await _dropOldServers(deviceId);
  }

  /// Invites [deviceId] to a private pairing on [server] over the channel ([replaces]: the
  /// pairing on that server it re-keys).
  Future<void> _invite(String deviceId, String server, {String? replaces}) async {
    final d = book.device(deviceId);
    if (d == null) return;
    try {
      final r = await _api.makePrivateInvite(name: book.deviceName, homeRelay: server);
      _book = book.withDevice(d.copyWith(pending: [...d.pending, PendingPairing(server: server, pairingId: r.id, inviter: true, replaces: replaces)]));
      await _send(deviceId, NoticeType.pair2, {'inviteLink': r.inviteLink, 'server': server, 'rekey': replaces != null});
    } on Object catch (e) {
      logWarn('devices', 'no invite on a link server: ${_kind(e)}');
    }
  }

  // A pairing invite over the confirmed channel is answered without the user: the channel is
  // already checked, and the pictures of the new pairing are compared over it.
  Future<void> _onPair2(LinkedDevice from, Notice n) async {
    final server = n.body['server'] as String;
    final rekey = n.body['rekey'] == true;
    if (rekey ? !from.pairings.containsKey(server) : from.pairings.length + from.pending.length >= maxLinkServers) {
      _drop('pairing invite the link does not expect');
      return;
    }
    // Only on a server of the link's set, which the user accepted; moving it is `servers`'s.
    if (!book.servers.contains(server) && !from.pairings.containsKey(server)) {
      _drop('pairing invite on a server the link does not use');
      return;
    }
    try {
      final r = await _api.acceptPrivateInvite(link: n.body['inviteLink'] as String, name: book.deviceName);
      final d = book.device(from.deviceId)!;
      _book = book.withDevice(
        d.copyWith(
          pending: [
            ...d.pending.where((p) => p.server != server),
            PendingPairing(server: server, pairingId: r.id, inviter: false, replaces: rekey ? from.pairings[server] : null),
          ],
        ),
      );
    } on Object catch (e) {
      logWarn('devices', 'pairing invite over the link not answered: ${_kind(e)}');
    }
  }

  static List<String> _sasNames(List<SasWord> sas) => [for (final w in sas) w.name];

  static bool _sameSas(List<SasWord> sas, Object? names) =>
      names is List && sas.length == names.length && sas.isNotEmpty && [for (var i = 0; i < sas.length; i++) sas[i].name == names[i]].every((x) => x);

  Future<void> _onPair2Ok(LinkedDevice from, Notice n) async {
    final server = n.body['server'] as String;
    final p = from.pending.where((p) => p.server == server && p.inviter).firstOrNull;
    if (p == null) return;
    final r = await _privateRecord(p.pairingId);
    if (r == null || !r.state.isPaired) return;
    if (!_sameSas(r.sas, n.body['sas'])) {
      logWarn('devices', 'pictures of a further pairing did not match; dropped it');
      await _unpair(p.pairingId);
      _book = book.withDevice(from.copyWith(pending: [for (final x in from.pending) if (x != p) x]));
      return;
    }
    await _api.checkWords(p.pairingId, PairingCheck.match);
    _book = book.withDevice(from.copyWith(pairings: {...from.pairings, server: p.pairingId}, pending: [for (final x in from.pending) if (x != p) x]));
    await _send(from.deviceId, NoticeType.pair2done, {'server': server, 'sas': _sasNames(r.sas)});
    final old = p.replaces;
    if (old != null && old != p.pairingId) await _unpair(old);
    await _dropOldServers(from.deviceId);
  }

  Future<void> _onPair2Done(LinkedDevice from, Notice n) async {
    final server = n.body['server'] as String;
    final p = from.pending.where((p) => p.server == server && !p.inviter).firstOrNull;
    if (p == null) return;
    final r = await _privateRecord(p.pairingId);
    if (r == null || !r.state.isPaired || !_sameSas(r.sas, n.body['sas'])) {
      logWarn('devices', 'pictures of a further pairing did not match; dropped it');
      await _unpair(p.pairingId);
      _book = book.withDevice(from.copyWith(pending: [for (final x in from.pending) if (x != p) x]));
      return;
    }
    await _api.checkWords(p.pairingId, PairingCheck.match);
    final pairings = {...from.pairings, server: p.pairingId};
    _book = book.withDevice(from.copyWith(pairings: pairings, pending: [for (final x in from.pending) if (x != p) x]));
    final old = p.replaces;
    if (old != null && old != p.pairingId) await _unpair(old);
    await _dropOldServers(from.deviceId);
  }

  /// Removes [deviceId]'s pairings on servers no longer in the link's set, keeping at least one.
  Future<void> _dropOldServers(String deviceId) async {
    final d = book.device(deviceId);
    if (d == null || book.servers.isEmpty) return;
    final keep = {for (final e in d.pairings.entries) if (book.servers.contains(e.key)) e.key: e.value};
    if (keep.isEmpty || keep.length == d.pairings.length) return;
    for (final e in d.pairings.entries) {
      if (!keep.containsKey(e.key)) await _unpair(e.value);
    }
    _book = book.withDevice(d.copyWith(pairings: keep));
  }

  Future<void> _onUnlink(LinkedDevice from, Notice n) async {
    await _forget(from.deviceId);
    _book = book.copyWith(removedBy: from.name);
  }

  Future<void> _onRemoved(LinkedDevice from, Notice n) async {
    final id = n.body['deviceId'] as String;
    if (id == book.deviceId) return _onUnlink(from, n);
    if (book.device(id) == null) return;
    await _forget(id);
    await _rekeyAll();
  }

  // Sending.

  /// Numbers [type] with [body] for [deviceId], keeps it in the outbox and posts it.
  Future<void> _send(String deviceId, NoticeType type, Map<String, Object?> body) async {
    final d = book.device(deviceId);
    if (d == null) return;
    final seq = d.seqOut + 1;
    final n = Notice(type: type, id: randomHexId(), seq: seq, dev: book.deviceId, ts: _clock().millisecondsSinceEpoch, body: body);
    _book = book.withDevice(d.copyWith(seqOut: seq)).copyWith(outbox: [...book.outbox, (deviceId: deviceId, json: jsonEncode(n.toJson()))]);
    await _put(book);
    if (!book.paused && host.online) await _flush();
  }

  /// [type] to every linked device.
  Future<void> _broadcast(NoticeType type, Map<String, Object?> body) async {
    for (final d in [...book.devices]) {
      await _send(d.deviceId, type, body);
    }
  }

  /// Posts the outbox: an entry is done once one pairing of its device took it.
  Future<void> _flush() async {
    if (book.outbox.isEmpty) return;
    final left = <({String deviceId, String json})>[];
    for (final o in book.outbox) {
      final d = book.device(o.deviceId);
      if (d == null) continue;
      final bytes = utf8.encode(o.json);
      var took = false;
      for (final id in d.pairings.values) {
        try {
          await _api.postPayload(id: id, bytes: bytes);
          took = true;
        } on Object catch (e) {
          logWarn('devices', 'notice not posted on one server: ${_kind(e)}');
        }
      }
      if (!took) left.add(o);
    }
    await _put(book.copyWith(outbox: left));
  }

  // This device's own sends: the others hear when one starts and when it moves on or ends.

  Future<void> _announce() async {
    if (book.devices.isEmpty) return;
    final rows = await host.transactions();
    List<WalletOutput>? outs;
    final announced = {...book.announced};
    for (final r in rows) {
      final slateId = r.slateId;
      if (r.origin != TxOrigin.thisWallet || slateId == null || r.id == null) continue;
      if (r.kind != TxKind.sent && r.kind != TxKind.sentCancelled) continue;
      final last = announced[slateId];
      if (r.confirmed) {
        announced.remove(slateId);
        continue;
      }
      final state = _stateOf(r);
      if (last == null) {
        if (r.kind == TxKind.sentCancelled) continue;
        outs ??= await host.outputs();
        final inputs = [
          for (final o in outs)
            if (o.status == WalletOutputStatus.locked && o.txId == r.id) o.commitment,
        ];
        if (inputs.isEmpty) continue;
        await _broadcast(NoticeType.send, {
          'slateId': slateId,
          'txId': r.id,
          'inputs': inputs,
          'amount': '${r.amountDebited - r.amountCredited - (r.fee ?? BigInt.zero)}',
          'fee': r.fee?.toString(),
          'counterparty': r.counterparty,
          'method': r.transport,
          'message': r.messages.where((m) => m.role == SlateRole.sender).firstOrNull?.text,
          'cutoffHeight': r.ttlCutoffHeight?.toInt(),
          'createdAt': r.createdAtUnix,
        });
        announced[slateId] = AnnouncedState.sent;
        if (state.$1 != AnnouncedState.sent) {
          await _broadcast(NoticeType.status, {'slateId': slateId, 'state': state.$2, 'kernel': r.kernelExcess, 'why': ?_whyOf(r)});
          announced[slateId] = state.$1;
        }
      } else if (last != AnnouncedState.ended && state.$1 != last) {
        await _broadcast(NoticeType.status, {
          'slateId': slateId,
          'state': state.$2,
          'kernel': r.kernelExcess,
          'height': await host.tipHeight(),
          'why': ?_whyOf(r),
        });
        announced[slateId] = state.$1;
      }
    }
    if (!_sameMap(announced, book.announced)) await _put(book.copyWith(announced: announced));
  }

  static bool _sameMap(Map<String, AnnouncedState> a, Map<String, AnnouncedState> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// Where this device's send [r] stands, as told to the others.
  static (AnnouncedState, String) _stateOf(TxEntry r) {
    if (r.kind == TxKind.sentCancelled || r.status == TxStatus.cancelled) {
      return (AnnouncedState.ended, switch (r.cancelReason) {
        CancelReason.expiry || CancelReason.lateAnswer => 'expired',
        CancelReason.failed => 'failed',
        CancelReason.release => 'released',
        _ => 'cancelled',
      });
    }
    if (r.finalizedAtUnix != null || r.status == TxStatus.awaitingConfirmation) {
      return r.repostable ? (AnnouncedState.finalized, 'finalized') : (AnnouncedState.posted, 'posted');
    }
    return (AnnouncedState.sent, 'sent');
  }

  /// Why a send of this device failed, as a code the others word themselves; null for any other
  /// ending. A send the core cancelled at once because its transport failed never reached the
  /// recipient.
  static String? _whyOf(TxEntry r) => r.cancelReason == CancelReason.failed ? 'notDelivered' : null;

  /// A send this device just made: the others hear at once, not at the next tick.
  Future<void> announceNow() async {
    if (book.devices.isEmpty) return;
    try {
      await _announce();
    } on Object catch (e) {
      logWarn('devices', 'announcing a send failed: ${_kind(e)}');
    }
  }

  // The chain and the clock.

  /// Commitments the chain shows spent: this wallet's spent outputs and the inputs of the
  /// chain check's rows.
  Future<Set<String>> _spent() async {
    final spent = <String>{
      for (final o in await host.outputs())
        if (o.status == WalletOutputStatus.spent) o.commitment,
    };
    for (final r in await host.transactions()) {
      if (r.origin == TxOrigin.otherWallet) spent.addAll(r.spentCommits);
    }
    return spent;
  }

  Future<void> _sweep() async {
    if (book.holds.isEmpty) {
      host.heldOutputs = const {};
      return;
    }
    final now = _clock();
    final next = pruneHolds(sweepHolds(book.holds, spent: await _spent(), tip: await host.tipHeight(), now: now), now);
    await _put(book.copyWith(holds: next));
  }

  // Pairings: removals by the other side, further pairings to confirm.

  Future<PairingRecord?> _privateRecord(String id) async => (await _api.privatePairings()).where((r) => r.id == id).firstOrNull;

  Future<void> _checkPairings() async {
    if (book.devices.isEmpty) return;
    final records = {for (final r in await _api.privatePairings()) r.id: r};
    for (final d in [...book.devices]) {
      final pairings = {
        for (final e in d.pairings.entries)
          if (records[e.value] != null && !records[e.value]!.removedByPeer) e.key: e.value,
      };
      // A further pairing must live on the server its invite named: the core names the relay
      // once the pairing is made, so an invite that pointed elsewhere is dropped then.
      final elsewhere = [
        for (final p in d.pending)
          if (records[p.pairingId] case final r? when r.state.isPaired && linkServerOf(r.homeRelay) != p.server) p,
      ];
      for (final p in elsewhere) {
        _drop('further pairing on another relay than its server');
        await _unpair(p.pairingId);
      }
      // The answerer of a further pairing sends its pictures once it is paired.
      final ok = <({String server, List<SasWord> sas})>[];
      final pending = <PendingPairing>[
        for (final p in d.pending)
          if (!elsewhere.contains(p))
            if (records[p.pairingId] case final r? when !r.removedByPeer)
              if (!p.inviter && r.state.isPaired && !p.okSent) ...[p.sent(), ?_noteOk(ok, p.server, r.sas)] else p,
      ];
      if (pairings.isEmpty && pending.isEmpty) {
        // Every pairing with it is gone: the other device removed this one.
        await _forget(d.deviceId);
        _book = book.copyWith(removedBy: d.name);
        continue;
      }
      _book = book.withDevice(d.copyWith(pairings: pairings, pending: pending));
      for (final o in ok) {
        await _send(d.deviceId, NoticeType.pair2ok, {'server': o.server, 'sas': _sasNames(o.sas)});
      }
    }
    await _put(book);
  }

  static PendingPairing? _noteOk(List<({String server, List<SasWord> sas})> ok, String server, List<SasWord> sas) {
    ok.add((server: server, sas: sas));
    return null;
  }

  Future<void> _unpair(String pairingId) async {
    try {
      await _api.removePairing(pairingId);
    } on Object catch (e) {
      logWarn('devices', 'unpairing failed: ${_kind(e)}');
    }
  }

  /// Forgets [deviceId] here: its holds end (spent where the chain says so), its pairings go.
  /// Forgets [deviceId]: its pairings go and, unless [keepHolds], the coins it held are freed.
  Future<void> _forget(String deviceId, {bool keepHolds = false}) async {
    final d = book.device(deviceId);
    if (d == null) return;
    for (final id in d.pairingIds) {
      await _unpair(id);
    }
    final holds = keepHolds ? book.holds : unlinkHolds(book.holds, deviceId, spent: await _spent(), now: _clock());
    _book = book.withoutDevice(deviceId).copyWith(holds: holds, outbox: [for (final o in book.outbox) if (o.deviceId != deviceId) o]);
  }

  /// After a removal: each remaining pair of devices makes fresh pairings over its channel, the
  /// lower device id inviting, and drops the old ones.
  Future<void> _rekeyAll() async {
    for (final d in [...book.devices]) {
      if (book.deviceId.compareTo(d.deviceId) >= 0) continue;
      for (final e in d.pairings.entries) {
        await _invite(d.deviceId, e.key, replaces: e.value);
      }
    }
  }

  // The user's actions.

  /// Removes [deviceId]: it is told, the others are told and re-key, its coins are freed here.
  /// It does not protect the money: a device with the phrase can always spend.
  Future<void> removeDevice(String deviceId) async {
    if (book.device(deviceId) == null) return;
    await _send(deviceId, NoticeType.unlink, const {});
    for (final d in book.devices) {
      if (d.deviceId != deviceId) await _send(d.deviceId, NoticeType.removed, {'deviceId': deviceId});
    }
    await _forget(deviceId);
    await _rekeyAll();
    await _put(book);
    _schedule();
  }

  Future<void> renameThis(String name) async {
    final n = name.trim();
    if (n.isEmpty || n == book.deviceName) return;
    await _put(book.copyWith(deviceName: n.length > deviceNameMaxLength ? n.substring(0, deviceNameMaxLength) : n));
    await _broadcast(NoticeType.rename, {'name': book.deviceName});
  }

  /// The name shown here for [deviceId] (the other device keeps its own name for itself).
  Future<void> renameDevice(String deviceId, String name) async {
    final d = book.device(deviceId);
    final n = name.trim();
    if (d == null || n.isEmpty) return;
    await _put(book.withDevice(d.copyWith(name: n.length > deviceNameMaxLength ? n.substring(0, deviceNameMaxLength) : n)));
  }

  Future<void> setPaused(bool paused) async {
    await _put(book.copyWith(paused: paused));
    if (!paused) unawaited(sync(DeviceSyncTrigger.refresh));
  }

  /// Frees the coins of [deviceId]'s payment [slateId] on this device only.
  Future<void> releaseByHandOf(String deviceId, String slateId) async {
    final now = _clock();
    await _put(book.copyWith(holds: [for (final h in book.holds) h.deviceId == deviceId && h.slateId == slateId ? releaseByHand(h, now) : h]));
  }

  /// Proposes [servers] for the link; with no device linked they are the set at once.
  Future<void> proposeServers(List<String> servers) async {
    final set = servers.take(maxLinkServers).toList();
    if (set.isEmpty) return;
    if (book.devices.isEmpty) {
      await _put(book.copyWith(servers: set, serversVersion: book.serversVersion + 1, clearProposal: true));
      return;
    }
    final version = book.serversVersion + 1;
    await _put(book.copyWith(proposal: ServerProposal(servers: set, version: version, fromHere: true)));
    await _broadcast(NoticeType.servers, {'set': set, 'version': version});
  }

  /// The user here accepts the other device's proposal.
  Future<void> acceptProposal() async {
    final p = book.proposal;
    if (p == null || p.fromHere) return;
    await _put(book.copyWith(servers: p.servers, serversVersion: p.version, clearProposal: true));
    await _broadcast(NoticeType.serversOk, {'version': p.version});
  }

  Future<void> declineProposal() async {
    if (book.proposal == null || book.proposal!.fromHere) return;
    await _put(book.copyWith(clearProposal: true));
  }

  /// Withdraws this device's own proposal; the others never get its version applied (a later
  /// proposal takes a higher one).
  Future<void> cancelProposal() async {
    final p = book.proposal;
    if (p == null || !p.fromHere) return;
    await _put(book.copyWith(clearProposal: true, serversVersion: p.version));
  }

  Future<void> clearRemovedBy() => _put(book.copyWith(clearRemovedBy: true));

  // Linking (both screens check the pictures; nothing is linked until both matched).

  /// The servers a new link starts with: the link's set, else [defaults].
  List<String> linkServers(List<String> defaults) => book.servers.isNotEmpty ? book.servers : defaults.take(maxLinkServers).toList();

  bool get canLinkMore => book.devices.length < maxLinkedDevices - 1;

  void _setLink(LinkFlow? flow) {
    _link = flow;
    _changed();
    _schedule();
  }

  /// This device shows the code, on [servers] (the first carries the link).
  Future<void> startShowing(List<String> servers) async {
    if (!loaded) await load();
    final set = servers.take(maxLinkServers).toList();
    _peer = _LinkPeer();
    if (!supported) return _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.failed, failure: LinkFailure.unsupported));
    if (!canLinkMore) return _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.failed, failure: LinkFailure.tooMany));
    _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.starting, servers: set));
    try {
      final r = await _api.makePrivateInvite(name: book.deviceName, homeRelay: set.first);
      final invite = r.inviteLink!;
      final code = deviceLinkText(invite, fingerprint: deviceLinkFingerprint(await host.signProof(deviceLinkFingerprintMessage(invite))));
      _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.waiting, servers: set, pairingId: r.id, code: code, expiresAt: r.expiresAt));
    } on Object catch (e) {
      _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.failed, servers: set, failure: _failureOf(e)));
    }
  }

  /// This device answers the device link in [text] (scanned or pasted). A code that carries
  /// another wallet's fingerprint is refused before it is answered; one without a fingerprint
  /// is answered, and the hello's proof decides ([_finishLink]).
  Future<void> startScanned(String text) async {
    if (!loaded) await load();
    _peer = _LinkPeer();
    final code = deviceLinkIn(text);
    if (!supported) return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.unsupported));
    if (code == null) return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.invalidCode));
    if (!canLinkMore) return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.tooMany));
    _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.starting));
    try {
      if (code.fingerprint != null &&
          code.fingerprint != deviceLinkFingerprint(await host.signProof(deviceLinkFingerprintMessage(code.invite)))) {
        logInfo('devices', 'link code of another wallet refused');
        return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.otherWalletCode));
      }
      final r = await _api.acceptPrivateInvite(link: code.invite, name: book.deviceName);
      _setLink(LinkFlow(role: LinkRole.scans, phase: LinkPhase.waiting, pairingId: r.id, otherName: r.name, servers: [?linkServerOf(r.homeRelay)]));
      unawaited(sync(DeviceSyncTrigger.link));
    } on Object catch (e) {
      _setLink(LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: _failureOf(e)));
    }
  }

  static LinkFailure _failureOf(Object e) => switch (pairingFailureOf(e)) {
    PairingFailure.expired => LinkFailure.expired,
    PairingFailure.alreadyUsed || PairingFailure.notFound || PairingFailure.cancelled => LinkFailure.notFound,
    PairingFailure.ownCard => LinkFailure.ownCode,
    PairingFailure.relayUnreachable || PairingFailure.noRelay || PairingFailure.relaysBlocked => LinkFailure.unreachable,
    PairingFailure.invalid || PairingFailure.newerVersion || PairingFailure.wrongNetwork => LinkFailure.invalidCode,
    null => e is WalletError && e.kind == WalletErrorKind.other ? LinkFailure.unsupported : LinkFailure.unreachable,
    _ => LinkFailure.cancelled,
  };

  Future<void> _pollLink() async {
    final flow = _link;
    final id = flow?.pairingId;
    if (flow == null || id == null || flow.phase == LinkPhase.done || flow.phase == LinkPhase.failed) return;
    final r = await _privateRecord(id);
    final now = _clock();
    if (r == null || r.removedByPeer) {
      if (r != null) await _unpair(id);
      return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.cancelled));
    }
    if (flow.phase == LinkPhase.waiting) {
      if (r.state.isPaired) {
        // The core names the code's server once the pairing is made, not when it is answered.
        final server = linkServerOf(r.homeRelay);
        final servers = flow.servers.isEmpty && server != null ? [server] : null;
        return _setLink(flow.to(LinkPhase.checking, sas: r.sas, otherName: r.name, servers: servers));
      }
      final expires = flow.expiresAt ?? r.expiresAt;
      if (expires != null && now.isAfter(expires)) {
        await _unpair(id);
        return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.expired));
      }
    }
    final matched = _peer.matchedAt;
    if (flow.phase == LinkPhase.waitingOther && matched != null && now.difference(matched) > linkCheckWait) {
      await _unpair(id);
      _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.cancelled));
    }
  }

  /// The user's answer on the four pictures. A match sends this device's hello; the link is
  /// made once the other device's hello (its own match) came too and holds the same wallet.
  Future<void> answerCheck(bool match) async {
    final flow = _link;
    final id = flow?.pairingId;
    if (flow == null || id == null || flow.phase != LinkPhase.checking) return;
    if (!match) {
      // Unpaired rather than only marked: the other device is told and stops waiting.
      await _unpair(id);
      return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.mismatch));
    }
    try {
      await _api.checkWords(id, PairingCheck.match);
      final hello = Notice(
        type: NoticeType.hello,
        id: randomHexId(),
        seq: 1,
        dev: book.deviceId,
        ts: _clock().millisecondsSinceEpoch,
        body: {
          'deviceId': book.deviceId,
          'name': book.deviceName,
          'walletAddress': await host.walletKey(),
          'servers': flow.servers,
          'proof': await host.signProof(helloTranscript(book.deviceId, flow.sas)),
        },
      );
      await _api.postPayload(id: id, bytes: hello.encode());
    } on Object catch (e) {
      return _setLink(flow.to(LinkPhase.failed, failure: _failureOf(e)));
    }
    _peer
      ..matchedHere = true
      ..matchedAt = _clock();
    _setLink(flow.to(LinkPhase.waitingOther));
    if (_peer.hello != null) {
      await _finishLink();
    } else {
      unawaited(sync(DeviceSyncTrigger.link));
    }
  }

  /// A payload on the pairing of the link in the making: only the other device's hello is read;
  /// anything after it waits until the link is made.
  Future<bool> _receiveLink(PairingPayload p) async {
    if (p.bytes.length > deviceNoticeMaxBytes) return _drop('notice too large');
    final n = decodeNotice(p.bytes).notice;
    if (n == null || !n.readable) return _drop('link notice not readable');
    if (n.type != NoticeType.hello) return false;
    if (n.seq != 1 || !noticeBodyValid(NoticeType.hello, n.body) || n.body['deviceId'] != n.dev || n.dev == book.deviceId) {
      return _drop('link hello with a bad body');
    }
    _peer.hello = n;
    if (_peer.matchedHere) await _finishLink();
    return true;
  }

  Future<void> _finishLink() async {
    final flow = _link;
    final hello = _peer.hello;
    final id = flow?.pairingId;
    if (flow == null || hello == null || id == null || flow.phase == LinkPhase.done) return;
    // The address is public, so it only turns another wallet away early; the proof is the
    // check: only a device holding this wallet's address key can sign this pairing's transcript.
    final key = await host.walletKey();
    final proof = hello.body['proof'];
    if (hello.body['walletAddress'] != key ||
        proof is! String ||
        flow.sas.length != 4 ||
        !await host.verifyProof(key, helloTranscript(hello.dev, flow.sas), proof)) {
      logWarn('devices', 'link hello did not prove this wallet');
      await _unpair(id);
      return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.otherWallet));
    }
    final theirId = hello.dev;
    if (book.device(theirId) == null && !canLinkMore) {
      await _unpair(id);
      return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.tooMany));
    }
    final r = await _privateRecord(id);
    final server = linkServerOf(r?.homeRelay) ?? flow.servers.first;
    final theirServers = [for (final s in hello.body['servers'] as List) s as String];
    final servers = flow.role == LinkRole.shows ? flow.servers : theirServers;
    // Linked again: the old pairings of that device go. The coins it held stay held: a hello
    // that names a linked device's id must not free the payments that device is making.
    final before = book.device(theirId);
    if (before != null) await _forget(theirId, keepHolds: true);
    final device = LinkedDevice(
      deviceId: theirId,
      name: _shownName(hello.body['name'], before?.name ?? '?'),
      pairings: {server: id},
      linkedAt: _clock(),
      lastSeen: _clock(),
      seqOut: 1,
      seqIn: 1,
      seenIds: [hello.id],
    );
    var next = book.withDevice(device);
    if (next.servers.isEmpty) next = next.copyWith(servers: servers, serversVersion: max(1, next.serversVersion));
    await _put(next);
    _setLink(flow.to(LinkPhase.done, device: device));
    // The device that showed the code adds the second server over the confirmed channel.
    if (flow.role == LinkRole.shows) {
      for (final s in flow.servers.skip(1)) {
        await _invite(theirId, s);
      }
      await _put(book);
    }
  }

  /// Ends the link in the making: the pairing goes, the other side is told by the engine.
  Future<void> cancelLink() async {
    final flow = _link;
    final id = flow?.pairingId;
    if (flow != null && id != null && flow.phase != LinkPhase.done) await _unpair(id);
    _setLink(null);
  }

  /// Closes a finished or failed link's screen.
  void closeLink() {
    if (_link?.phase == LinkPhase.done || _link?.phase == LinkPhase.failed) _setLink(null);
  }

  static String _kind(Object e) => e is WalletError ? e.kind.name : e.runtimeType.toString();
}
