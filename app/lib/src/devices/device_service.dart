// SPDX-License-Identifier: Apache-2.0
/// Linked devices at work for one open wallet: linking, the notices between devices, the coins
/// they hold, the runs that read the channel. Shared by the phone and the desktop; each app
/// gives it a [DeviceHost] and wraps it in its providers (`device_providers.dart`).
///
/// Receiving, in one path ([_receive]): the payload must come through a private pairing of a
/// linked device and name that device → at most [deviceNoticeMaxBytes] (before parsing) → not
/// seen before (by id) → in order (by seq, waiting up to [noticeWindow] ahead and [gapWait] for
/// a missing one) → a body valid for its type → its handler in [_handlers]. A `send`, a
/// `status` of a known hold, `unlink`, `recv` and `fwd` are keyed by slate or device and apply
/// the same however often they come, so they apply as they arrive, ahead of a missing one
/// ([_applyEarly]); `servers` and the `pair2*` notices keep the order. Anything else is dropped
/// and logged without amounts or addresses. A notice of another wire version keeps its place
/// in the order and marks its device: the user is told to update it ([LinkedDevice.otherVersion]).
///
/// Sending, in one path ([_send]): numbered, stamped, kept in the book's outbox and posted to
/// every pairing of the linked device (one per server).
///
/// A wallet is on two devices at most: this one and one linked device ([maxLinkedDevices]).
/// Links are pairwise, so with a third device one of them would not hear the other's payments.
/// Both devices answer payments to the wallet's one address; the sender takes the first answer,
/// and the other device drops its own once the chain shows which was used.
///
/// What a notice can do here: hold or release coins, add history details, rename its device,
/// propose servers (the user accepts here), make a further pairing with this device over the
/// confirmed channel (second server, a lost pairing made again), pass on a payer's report or a
/// contact's request that reached the other device only ([forwarded]), and end the link. It
/// never sends, signs or changes a setting on its own.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../boosts.dart';
import '../log.dart';
import '../models.dart';
import '../pairing_api.dart';
import '../relay_boost.dart';
import '../scan/scan_router.dart' show cleanUntrustedText;
import '../wallet_service.dart' show WalletSession;
import 'device_link_code.dart';
import 'device_locks.dart';
import 'device_history.dart' show answersTakenThere;
import 'device_model.dart';
import 'device_store.dart';
import 'device_wire.dart';

/// What the service needs from the open wallet. [SessionDeviceHost] gives it from a
/// [WalletSession]; an app may give its own.
abstract interface class DeviceHost {
  /// The wallet's pairing engine, whatever the Pairing switch says.
  PairingApi get pairing;

  /// The wallet's boosts: a link under way checks the relays more often.
  Boosts get boosts;

  /// Whether the channel may reach the servers now (not Offline, Epicbox on).
  bool get online;

  /// This wallet's payments key (its Epicbox address without the server).
  Future<String> walletKey();

  /// Cancels this device's own answer [txId] to a payment the linked device answered and the
  /// chain, or the payer, took from it.
  Future<void> cancelTransaction(int txId);

  /// [message] signed with this wallet's device-link key ([WalletSession.signDeviceLink]).
  Future<String> signProof(List<int> message);

  /// Whether [signature] is [signProof] of [message] by a wallet of this wallet's phrase.
  Future<bool> verifyProof(List<int> message, String signature);

  /// Notices for a slate this device holds nothing of ([WalletSession.unmatchedNotices]).
  Stream<UnmatchedNotice> unmatchedNotices();

  /// Applies a notice the linked device passed on ([WalletSession.applyForwardedNotice]).
  Future<bool> applyForwardedNotice(String sender, String notice);

  Future<List<WalletOutput>> outputs();

  /// This wallet's history as the session lists it, chain-check rows included.
  Future<List<TxEntry>> transactions();

  /// The chain height last seen, or null.
  Future<int?> tipHeight();

  /// Where the chain holds the kernel [excess] from [minHeight] on, null when it does not;
  /// throws when the node cannot be asked ([WalletSession.kernelOnChain]).
  Future<KernelLocation?> kernelOnChain(String excess, {int? minHeight});

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
  Boosts get boosts => session.boosts;

  @override
  bool get online => _online();

  @override
  Future<String> walletKey() async => epicboxKey(await session.epicboxAddress());

  @override
  Future<void> cancelTransaction(int txId) => session.cancelTransaction(txId: txId);

  @override
  Future<String> signProof(List<int> message) => session.signDeviceLink(message);

  @override
  Future<bool> verifyProof(List<int> message, String signature) =>
      session.verifyDeviceLink(transcript: message, signature: signature);

  @override
  Stream<UnmatchedNotice> unmatchedNotices() => session.unmatchedNotices();

  @override
  Future<bool> applyForwardedNotice(String sender, String notice) =>
      session.applyForwardedNotice(sender: sender, notice: notice);

  @override
  Future<List<WalletOutput>> outputs() => session.outputs();

  @override
  Future<List<TxEntry>> transactions() => session.transactions(refresh: false);

  @override
  Future<int?> tipHeight() async =>
      (await session.summary(refresh: false, minimumConfirmations: _confirmations)).lastConfirmedHeight.toInt();

  @override
  Future<KernelLocation?> kernelOnChain(String excess, {int? minHeight}) => session.kernelOnChain(excess, minHeight: minHeight);

  @override
  set heldOutputs(Set<String> commitments) => session.heldOutputs = commitments;
}

/// What a hello's `proof` signs: a tag, the sending device's id and the four pictures of the
/// link's private pairing, which both devices see alike and LEPIC derives from both sides' keys,
/// so a proof holds for this pairing and sender only. JSON keeps the parts apart.
///
/// The signature is the wallet's device-link key's, which LEPIC makes under its own tag
/// (`lepic/device-link/v1`) and every install of the phrase shares ([DeviceHost.signProof]:
/// [DeviceService._sendHello]; the link code's fingerprint signs another message). This tag
/// keeps a hello apart from the fingerprint's message under that one key.
List<int> helloTranscript(String deviceId, List<SasWord> sas) =>
    utf8.encode(jsonEncode(['epiccash/device-link/hello/v1', deviceId, for (final w in sas) w.name]));

/// How far ahead of the next expected notice one is kept; further ones are dropped.
const int noticeWindow = 64;

/// How long a missing notice is waited for before the ones after it apply. Every notice goes
/// through both servers, so one that did not come in a few minutes is lost.
const Duration gapWait = Duration(minutes: 3);

/// How often the channel is read in the foreground with a device linked, and while a link
/// is being made.
const Duration deviceSyncEvery = Duration(seconds: 5);

/// How long Send waits for one read of the channel before it chooses coins.
const Duration sendWaitsForDevices = Duration(seconds: 3);

/// How long a link waits for the other device's hello once this one's went out.
const Duration linkHelloWait = Duration(minutes: 10);

/// How long a device is given to post its `unlink` before the wallet is deleted.
const Duration unlinkBeforeDeleteWait = Duration(seconds: 5);

/// How long "Linked" stays on screen before the screen closes by itself.
const Duration linkDoneShown = Duration(seconds: 2);

/// Whole minutes until [t], at least 1: the code's remaining time, shown alike on the phone and
/// the desktop.
int linkMinutesLeft(DateTime t, DateTime now) => ((t.difference(now).inSeconds + 59) ~/ 60).clamp(1, 60);

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

  /// The other device cancelled.
  cancelled,

  /// [maxLinkedDevices] devices are linked already on this device: it may replace the one
  /// linked ([DeviceService.replaceLinked]).
  tooMany,

  /// The other device is linked to another device already; it said so and unpaired.
  full,

  /// The other device writes a newer wire version: update this one.
  update,

  /// The other device writes an older wire version: update that one.
  updateOther,

  /// No server answered, or the other device could not be reached in time.
  unreachable,

  /// This wallet's core cannot link devices yet.
  unsupported,
}

enum LinkRole { shows, scans }

enum LinkPhase {
  /// Making the invite, or answering one.
  starting,

  /// The code is on screen (shows) or the answer went out (scans): waiting for the other.
  waiting,

  /// Both are paired: this device's hello went out, the four pictures show as "Linking…" and
  /// the other device's hello is waited for. Nothing to tap.
  linking,
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
    this.refusing = false,
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

  /// This device is full ([maxLinkedDevices]) and answers the code only to say so: once the
  /// pairing is made it posts `full` and unpairs, so the other device does not wait.
  final bool refusing;

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
    refusing: refusing,
  );
}

/// The state of the other side of a link in the making, kept beside [LinkFlow].
class _LinkPeer {
  DateTime? helloSentAt;
  Notice? hello;
}

/// The link server of a pairing whose core names it [relay] (`host` or `host:port`): the host
/// alone for the TLS port, as the link's servers are written; null while the core names none.
String? linkServerOf(String? relay) {
  final r = relay?.trim().toLowerCase() ?? '';
  if (r.isEmpty) return null;
  return r.endsWith(':443') ? r.substring(0, r.length - 4) : r;
}

/// The receives remembered from the linked device.
const int _theirReceivesKept = 200;

/// Why the service reads the channel now.
enum DeviceSyncTrigger { start, resume, unlock, refresh, tick, beforeSend, link }

/// What a `fwd` notice passes on: a report from the payer of a payment this wallet answered,
/// or a contact's request to pay, that reached the other device only.
enum ForwardKind { posted, cancelled, declined, invoice }

/// A notice the linked device passed on ([DeviceService.forwarded]).
class ForwardedNotice {
  const ForwardedNotice({required this.kind, required this.slateId, required this.device, this.kernel});

  final ForwardKind kind;
  final String slateId;

  /// The name of the device it reached.
  final String device;

  /// For [ForwardKind.posted]: the kernel excess the payer reported.
  final String? kernel;
}

class DeviceService {
  DeviceService({
    required this.host,
    required this.store,
    required this.defaultName,
    this.nameWithCode,
    this.kind = DeviceKind.phone,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DeviceHost host;
  final DeviceStore store;

  /// This device's kind of name until the user renames it ("Phone", "Desktop").
  final String defaultName;

  /// A name with a device's short code ([deviceCode]), in the app's language: a new book's
  /// own name, and a linked device's that would read the same as this one's. Null keeps names
  /// as they are (tests).
  final String Function(String name, String code)? nameWithCode;

  /// What this device is, told in its hello for the other device's icon.
  final DeviceKind kind;
  final DateTime Function() _clock;

  DeviceBook? _book;
  LinkFlow? _link;
  _LinkPeer _peer = _LinkPeer();
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<ForwardedNotice> _forwarded = StreamController<ForwardedNotice>.broadcast();
  Future<void>? _running;
  late final PollDriver _driver = PollDriver(
    host.boosts,
    Poller.relays,
    base: deviceSyncEvery,
    tick: () async {
      await sync(DeviceSyncTrigger.tick);
      return true;
    },
  );

  /// Ends the boost a link under way holds; null without one.
  void Function()? _endLinkBoost;
  bool _foreground = false;
  bool _disposed = false;

  /// What reaches this device only and goes on to the linked device: requests to pair and
  /// their answers here ([_onPairingEvent]), notices for slates held elsewhere.
  StreamSubscription<PairingEvent>? _pairingEvents;
  StreamSubscription<UnmatchedNotice>? _unmatched;

  /// Requests the linked device passed on: never passed back.
  final Set<String> _requestsFromLinked = {};

  /// Requests passed on to the linked device: each once.
  final Set<String> _requestsPassedOn = {};

  /// Done once the book is read ([load]) or the service is let go.
  final Completer<void> _ready = Completer<void>();

  /// The desktop's interval with a device linked ([setPace]); null: [deviceSyncEvery].
  Duration? _pace;

  PairingApi get _api => host.pairing;

  /// Every change of [book] or [link].
  Stream<void> get changes => _changes.stream;

  /// The notices the linked device passed on, as they are read: the app shows them or reads
  /// its lists again ([ForwardedNotice]).
  Stream<ForwardedNotice> get forwarded => _forwarded.stream;

  DeviceBook get book => _book ?? DeviceBook(deviceId: '0' * 32, deviceName: defaultName);

  bool get loaded => _book != null;

  /// The link being made, or null.
  LinkFlow? get link => _link;

  /// The core links devices.
  bool get supported => _api.privateSupported;

  Future<void> load() async {
    _book ??= await store.load(defaultName: defaultName, withCode: nameWithCode);
    _passOn();
    host.heldOutputs = book.heldCommitments;
    _changed();
    // The apps set the foreground before the book is read: with devices linked already (a
    // start, a wallet switch) the timer starts only now. Without it nothing was read or told
    // until a window focus or Refresh, and a cancel reached the other device minutes late.
    _schedule();
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Lets the service go. A link still in the making is ended best-effort, so the other device
  /// does not wait for a session that closed (the auto-lock, a wallet switch).
  void dispose() {
    final flow = _link;
    final id = flow?.pairingId;
    if (flow != null && id != null && flow.phase != LinkPhase.done && flow.phase != LinkPhase.failed) {
      try {
        unawaited(_api.removePairing(id).catchError((Object _) {}));
      } on Object {
        // The engine is gone with the session: nothing to tell.
      }
    }
    _disposed = true;
    if (!_ready.isCompleted) _ready.complete();
    _driver.stop();
    _endLinkBoost?.call();
    _pairingEvents?.cancel();
    _unmatched?.cancel();
    _changes.close();
    _forwarded.close();
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
    // A service that was let go never writes: the wallet's next service owns the book now, and
    // a run still under way here would put an older book over it.
    if (json == _saved || _disposed) return;
    _saved = json;
    await store.save(next);
    _changed();
  }

  // Runs: start, resume, unlock and refresh read the channel once; while in the
  // foreground with a device linked it is read every [deviceSyncEvery].

  /// The app is on screen ([on]) or not: the timer runs only while it is.
  void setForeground(bool on) {
    _foreground = on;
    _schedule();
  }

  /// The desktop runs minimized too, so it reads at its own [every] instead of
  /// [deviceSyncEvery]: the interval starts again from now, after a read now when [now]. With
  /// a pace set, a payload and the read before a send start the interval again too.
  void setPace(Duration every, {bool now = false}) {
    _pace = every;
    _schedule();
    if (now) unawaited(sync(DeviceSyncTrigger.resume));
  }

  /// A link is being made.
  bool get _linking => _link != null && _link!.phase != LinkPhase.done && _link!.phase != LinkPhase.failed;

  /// Runs the read while in the foreground with a device linked or a link under way, from now.
  void _schedule() {
    if (!_foreground || _disposed || !(_linking || book.devices.isNotEmpty || book.removing.isNotEmpty)) return _driver.stop();
    _driver.base = _pace ?? deviceSyncEvery;
    _driver.start();
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
    if (_pace != null) _schedule();
  }

  Future<void> _sync(DeviceSyncTrigger trigger) async {
    if (!loaded) await load();
    final reach = !book.paused && host.online && _api.privateSupported;
    final flow = _link;
    final linking = flow != null && flow.pairingId != null && flow.phase != LinkPhase.done && flow.phase != LinkPhase.failed;
    if (reach && (book.devices.isNotEmpty || book.removing.isNotEmpty || linking)) {
      try {
        await _api.collectPrivate(
          only: [for (final d in [...book.devices, ...book.removing]) ...d.pairingIds, if (linking) flow.pairingId!],
        );
        // Payloads first: a hello that came before its pairing ended still answers the link.
        await _readPayloads();
        if (linking) await _pollLink();
        await _checkPairings();
        await _checkRemovals();
      } on Object catch (e) {
        logWarn('devices', 'reading linked devices failed: ${_kind(e)}');
      }
    }
    try {
      await _announce();
      if (reach) await _flush();
      await _sweep();
      await _dropAnswersTakenThere();
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
    for (final p in await _ownPayloads(list)) {
      if (await _receive(p)) done.add(p.id);
    }
    await _applyWaitingAll();
    await _put(book);
    if (done.isNotEmpty) await _api.ackPayloads(done);
    // Something came: the next read is a whole interval from now.
    if (_pace != null) _schedule();
  }

  /// The payloads of [list] that belong to this service: those of a linked device, a device
  /// being removed, the link under way, or any other private pairing. A payload of a contact
  /// pairing is the name service's (`name_service/name_service_service.dart`): it stays with the engine
  /// for that service to read and acknowledge.
  Future<List<PairingPayload>> _ownPayloads(List<PairingPayload> list) async {
    bool known(String pairingId) =>
        _link?.pairingId == pairingId ||
        book.deviceOfPairing(pairingId) != null ||
        book.removing.any((d) => d.pairingIds.contains(pairingId));
    if (list.every((p) => known(p.pairingId))) return list;
    final private = {for (final r in await _api.privatePairings()) r.id};
    return [
      for (final p in list)
        if (known(p.pairingId) || private.contains(p.pairingId)) p,
    ];
  }

  /// Reads [p]; false leaves it with the engine for a later read (a notice for a link that is
  /// not finished here yet).
  Future<bool> _receive(PairingPayload p) async {
    final flow = _link;
    if (flow != null && flow.pairingId == p.pairingId && book.deviceOfPairing(p.pairingId) == null) return _receiveLink(p);
    final device = book.deviceOfPairing(p.pairingId);
    if (device == null) return _receiveRemoving(p);
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
    await _applyEarly(device.deviceId);
    return true;
  }

  /// A payload on a pairing of a device being removed: only its own `unlink` counts, which
  /// ends the removal (the link is over on both devices); anything else is dropped.
  Future<bool> _receiveRemoving(PairingPayload p) async {
    final gone = book.removing.where((d) => d.pairingIds.contains(p.pairingId)).firstOrNull;
    if (gone == null) return _drop('payload on a pairing of no linked device');
    if (p.bytes.length <= deviceNoticeMaxBytes) {
      final n = decodeNotice(p.bytes).notice;
      if (n != null && n.readable && n.type == NoticeType.unlink && n.dev == gone.deviceId) {
        await _endRemoval(gone.deviceId);
        return true;
      }
    }
    return _drop('notice from a device being removed');
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
  /// up and the next present one applies. One applied as it came ([_applyEarly]) only takes
  /// its place.
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
      final applied = d.early.contains(next);
      _book = book.withDevice(d.copyWith(seqIn: next, waiting: waiting, early: {...d.early}..remove(next), lastSeen: _clock()));
      if (applied) continue;
      final n = noticeFromJson(jsonDecode(entry.json));
      if (n != null) await _dispatch(deviceId, n);
    }
  }

  /// Applies, in order, the waiting notices of [deviceId] that stand on their own, ahead of a
  /// missing one: a `send` (the coins it names are held or already are), a `status` whose hold
  /// is known, `unlink`, `recv` and `fwd`. The order still carries them ([_applyWaiting]).
  Future<void> _applyEarly(String deviceId) async {
    for (final seq in (book.device(deviceId)?.waiting.keys.toList() ?? <int>[])..sort()) {
      final d = book.device(deviceId);
      if (d == null || d.early.contains(seq)) continue;
      final entry = d.waiting[seq];
      if (entry == null) continue;
      final n = noticeFromJson(jsonDecode(entry.json));
      if (n == null || !_standsAlone(d, n)) continue;
      _book = book.withDevice(d.copyWith(early: {...d.early, seq}, lastSeen: _clock()));
      await _dispatch(deviceId, n);
    }
  }

  bool _standsAlone(LinkedDevice d, Notice n) {
    if (!n.readable || !noticeBodyValid(n.type!, n.body)) return false;
    return switch (n.type!) {
      NoticeType.send || NoticeType.unlink || NoticeType.recv || NoticeType.fwd => true,
      NoticeType.status => book.holds.any((h) => h.deviceId == d.deviceId && h.slateId == n.body['slateId']),
      _ => false,
    };
  }

  Future<void> _dispatch(String deviceId, Notice n) async {
    final from = book.device(deviceId);
    if (from == null) return;
    if (n.otherVersion) {
      // Not read: the device that writes it is named on screen until it is updated.
      logInfo('devices', 'a notice of wire version ${n.v} from a device to update');
      if (from.otherVersion != n.v) _book = book.withDevice(from.copyWith(otherVersion: n.v));
      return;
    }
    if (from.otherVersion != null) _book = book.withDevice(from.copyWith(clearOtherVersion: true));
    if (n.type == null) {
      logInfo('devices', 'ignored a notice of type ${n.typeName}');
      return;
    }
    if (!noticeBodyValid(n.type!, n.body)) {
      logWarn('devices', 'dropped: ${n.type!.name} notice with a bad body');
      return;
    }
    await _handlers[n.type!]!(book.device(deviceId)!, n);
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
    NoticeType.recv: _onRecv,
    NoticeType.fwd: _onForward,
    // A `full` belongs to a link in the making ([_receiveLink]); from a linked device it says
    // nothing new.
    NoticeType.full: _reserved,
    NoticeType.snapshotRequest: _reserved,
    NoticeType.snapshot: _reserved,
  };

  Future<void> _reserved(LinkedDevice from, Notice n) async {}

  // A hello again from a linked device changes nothing but its name.
  Future<void> _onHello(LinkedDevice from, Notice n) async {
    final name = _apart(_shownName(n.body['name'], from.name), from.deviceId);
    if (name != from.name) _book = book.withDevice(from.copyWith(name: name));
  }

  Future<void> _onRecv(LinkedDevice from, Notice n) async {
    final slateId = n.body['slateId'] as String;
    final outputs = [for (final c in n.body['outputs'] as List) c as String];
    final next = {...book.theirReceives, slateId: outputs};
    while (next.length > _theirReceivesKept) {
      next.remove(next.keys.first);
    }
    _book = book.copyWith(theirReceives: next);
  }

  /// A report or a request that reached the other device only. A payer's `posted` or
  /// `cancelled` for a payment this device answered too: that answer never completes (the payer
  /// used the other device's, or cancelled), so it is dropped here, quietly. Every kind goes to
  /// the app ([forwarded]) to show or to read its lists again.
  Future<void> _onForward(LinkedDevice from, Notice n) async {
    switch (n.body['kind']) {
      case 'pair':
        return _onForwardedRequest(n.body);
      case 'paired':
        final id = n.body['requestId'] as String;
        _requestsFromLinked.remove(id);
        try {
          await _api.requestHandledOn(id, from.name);
        } on Object catch (e) {
          logInfo('devices', 'a request answered on the linked device was not known here: ${_kind(e)}');
        }
        return;
      case 'notice':
        try {
          final taken = await host.applyForwardedNotice(n.body['sender'] as String, n.body['notice'] as String);
          logInfo('devices', taken ? 'a notice the linked device passed on applied' : 'a notice the linked device passed on matched nothing here');
        } on Object catch (e) {
          logWarn('devices', 'a notice the linked device passed on was refused: ${_kind(e)}');
        }
        return;
    }
    final kind = ForwardKind.values.asNameMap()[n.body['kind']]!;
    final slateId = n.body['slateId'] as String;
    // A declined send was made here or on the linked device, never answered: nothing to drop.
    if (kind == ForwardKind.posted || kind == ForwardKind.cancelled) await _releaseOwnAnswer(slateId);
    if (!_disposed) _forwarded.add(ForwardedNotice(kind: kind, slateId: slateId, device: from.name, kernel: n.body['kernel'] as String?));
  }

  /// Cancels this device's own answer to the payment [slateId] while it still waits for its
  /// payer. The core asks the node first and refuses a payment the network has: that one is
  /// left to confirm.
  Future<void> _releaseOwnAnswer(String slateId) async {
    for (final r in await host.transactions()) {
      if (r.origin != TxOrigin.thisWallet || r.slateId != slateId || r.kind != TxKind.received || r.confirmed || !r.cancellable || r.id == null) continue;
      try {
        await host.cancelTransaction(r.id!);
        logInfo('devices', 'an answer the payer settled with the linked device was dropped');
      } on WalletError catch (e) {
        if (e.kind == WalletErrorKind.invalidArgument) {
          logInfo('devices', 'the network has this answer: left to confirm');
        } else {
          logWarn('devices', 'dropping an answer failed: ${e.kind.name}');
        }
      } on Object catch (e) {
        logWarn('devices', 'dropping an answer failed: ${_kind(e)}');
      }
    }
  }

  Future<void> _onRename(LinkedDevice from, Notice n) async {
    _book = book.withDevice(from.copyWith(name: _apart(_shownName(n.body['name'], from.name), from.deviceId)));
  }

  /// A device's name as the user reads it: plain text, no direction marks or invisible
  /// characters ([cleanUntrustedText]); [fallback] when nothing is left.
  static String _shownName(Object? name, String fallback) => cleanUntrustedText(name as String) ?? fallback;

  /// [name] of the device [deviceId], told apart from this device's own: the same name gets
  /// the other device's short code, so "Received on …" names one device only.
  String _apart(String name, String deviceId) {
    final withCode = nameWithCode;
    if (withCode == null || name.trim().toLowerCase() != book.deviceName.trim().toLowerCase()) return name;
    return withCode(name, deviceCode(deviceId));
  }

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
    final height = n.body['height'] as int?;
    final next = applyStatus(
      book.holds[i],
      n.body['state'] as String,
      height: height,
      kernel: n.body['kernel'] as String?,
      why: n.body['why'] as String?,
      // A first notice may say posted without a height: the post is counted from now.
      tip: height == null && n.body['state'] == 'posted' ? await host.tipHeight() : null,
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
    // The pairings on the new servers are made by the next read ([_completeServers]).
    final accepted = p.accept(from.deviceId);
    if (book.devices.every((d) => accepted.accepted.contains(d.deviceId))) {
      _book = book.copyWith(servers: p.servers, serversVersion: p.version, clearProposal: true);
    } else {
      _book = book.copyWith(proposal: accepted);
    }
  }

  /// Gives the link a pairing on every server of its set. Only the device with the lower id
  /// invites, so the two never invite each other on the same server at once; the other answers
  /// ([_onPair2]). This makes the second server after a link, the new ones after a server
  /// change, and any pairing the link lost (a relay that dropped it, an invite that never
  /// finished). Once every server has one, pairings on servers out of the set go.
  Future<void> _completeServers(String deviceId) async {
    final d = book.device(deviceId);
    if (d == null || book.servers.isEmpty) return;
    final missing = [for (final s in book.servers) if (!d.pairings.containsKey(s) && !d.pending.any((p) => p.server == s)) s];
    if (missing.isEmpty && d.pending.isEmpty) return _dropOldServers(deviceId);
    if (book.deviceId.compareTo(deviceId) >= 0) return;
    for (final s in missing) {
      await _invite(deviceId, s);
    }
  }

  /// Invites [deviceId] to a private pairing on [server] over the channel.
  Future<void> _invite(String deviceId, String server) async {
    final d = book.device(deviceId);
    if (d == null) return;
    try {
      final r = await _api.makePrivateInvite(name: book.deviceName, homeRelay: server);
      _book = book.withDevice(
        d.copyWith(
          pending: [
            ...d.pending,
            PendingPairing(server: server, pairingId: r.id, inviter: true, startedAt: _clock(), replaces: d.pairings[server]),
          ],
        ),
      );
      await _send(deviceId, NoticeType.pair2, {'inviteLink': r.inviteLink, 'server': server});
    } on Object catch (e) {
      logWarn('devices', 'no invite on a link server: ${_kind(e)}');
    }
  }

  // A pairing invite over the confirmed channel is answered without the user: the channel is
  // already checked, and the pictures of the new pairing are compared over it. An invite on a
  // server the link has a pairing on already replaces it once confirmed: the inviter lost it.
  Future<void> _onPair2(LinkedDevice from, Notice n) async {
    final server = n.body['server'] as String;
    // Only on a server of the link's set, which the user accepted; moving it is `servers`'s.
    if (!book.servers.contains(server) && !from.pairings.containsKey(server)) {
      _drop('pairing invite on a server the link does not use');
      return;
    }
    if ({...from.pairings.keys, for (final p in from.pending) p.server, server}.length > maxLinkServers) {
      _drop('pairing invite the link does not expect');
      return;
    }
    try {
      final r = await _api.acceptPrivateInvite(link: n.body['inviteLink'] as String, name: book.deviceName);
      final d = book.device(from.deviceId)!;
      // An earlier invite on this server that never finished gives way to this one.
      for (final p in d.pending.where((p) => p.server == server)) {
        await _unpair(p.pairingId);
      }
      _book = book.withDevice(
        d.copyWith(
          pending: [
            ...d.pending.where((p) => p.server != server),
            PendingPairing(server: server, pairingId: r.id, inviter: false, startedAt: _clock(), replaces: d.pairings[server]),
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
    var r = await _privateRecord(p.pairingId);
    if (r != null && !r.state.isPaired) {
      // The answer can come before this side read that the pairing is made: read it now, as
      // this notice is not read twice.
      await _api.collectPrivate(only: [p.pairingId]);
      r = await _privateRecord(p.pairingId);
    }
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

  /// Passes on to the linked device a notice that reached this one only: the payer of the
  /// payment [slateId] this wallet answered reports it [ForwardKind.posted] (with its
  /// [kernel]), [ForwardKind.cancelled] or [ForwardKind.declined] (the receiver of a send refused it), or a contact's request to pay arrived
  /// ([ForwardKind.invoice]). The apps call it from their notice handlers. Nothing without a
  /// linked device.
  Future<void> forward(ForwardKind kind, String slateId, {String? kernel}) async {
    if (book.devices.isEmpty) return;
    try {
      await _broadcast(NoticeType.fwd, {'kind': kind.name, 'slateId': slateId, 'kernel': ?kernel});
    } on Object catch (e) {
      logWarn('devices', 'passing a notice on failed: ${_kind(e)}');
    }
  }

  /// Passes on what reaches this device only: requests to pair (and that one was answered
  /// here, so the other device hides its copy: the first Pair wins) and notices for slates
  /// this device holds nothing of. Subscribed once, when the book is read.
  void _passOn() {
    if (_disposed) return;
    try {
      _pairingEvents ??= _api.events().listen((e) => unawaited(_onPairingEvent(e)), onError: (Object _) {});
    } on Object catch (e) {
      logInfo('devices', 'no pairing events to pass on: ${_kind(e)}');
    }
    try {
      _unmatched ??= host.unmatchedNotices().listen(
        (n) => unawaited(_broadcastForward({'kind': 'notice', 'sender': n.sender, 'notice': n.notice})),
        onError: (Object _) {},
      );
    } on Object catch (e) {
      logInfo('devices', 'no notices to pass on: ${_kind(e)}');
    }
  }

  Future<void> _onPairingEvent(PairingEvent e) async {
    final id = e.requestId;
    if (id == null || book.devices.isEmpty) return;
    if (e.kind == PairingEventKind.requestAnswered) {
      _requestsFromLinked.remove(id);
      return _broadcastForward({'kind': 'paired', 'requestId': id});
    }
    if (e.kind != PairingEventKind.requested || _requestsFromLinked.contains(id)) return;
    final PairRequest? request;
    try {
      request = (await _api.requests()).where((r) => r.id == id).firstOrNull;
    } on Object catch (e) {
      return logWarn('devices', 'a request to pair was not read: ${_kind(e)}');
    }
    // Dismissed here already (a stranger's): it was passed on before ([passOnRequest]).
    if (request == null) return;
    await _passOnRequest(request);
  }

  /// Passes [request] on to the linked device before this device dismisses it: its sender is
  /// not in this device's address book, but may be in the other's. Waits for the book to be
  /// read; each request goes once.
  Future<void> passOnRequest(PairRequest request) async {
    await _ready.future;
    await _passOnRequest(request);
  }

  Future<void> _passOnRequest(PairRequest request) async {
    if (_disposed || book.devices.isEmpty || _requestsFromLinked.contains(request.id)) return;
    if (!_requestsPassedOn.add(request.id)) return;
    await _broadcastForward({
      'kind': 'pair',
      'requestId': request.id,
      'link': request.inviteLink,
      'from': request.fromAddress,
      'name': request.claimedName,
      'party': request.kind.name,
      'received': request.receivedAt.millisecondsSinceEpoch,
      'expires': request.expiresAt.millisecondsSinceEpoch,
    });
  }

  Future<void> _onForwardedRequest(Map<String, Object?> b) async {
    final request = PairRequest(
      id: b['requestId'] as String,
      fromAddress: b['from'] as String,
      claimedName: cleanUntrustedText(b['name'] as String) ?? '',
      kind: PairingParty.values.asNameMap()[b['party']] ?? PairingParty.person,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(b['received'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(b['expires'] as int),
      inviteLink: b['link'] as String,
    );
    _requestsFromLinked.add(request.id);
    try {
      await _api.takeForwardedRequest(request);
    } on Object catch (e) {
      logWarn('devices', 'a request the linked device passed on was not taken: ${_kind(e)}');
    }
  }

  Future<void> _broadcastForward(Map<String, Object?> body) async {
    if (_disposed || book.devices.isEmpty) return;
    try {
      await _broadcast(NoticeType.fwd, body);
    } on Object catch (e) {
      logWarn('devices', 'passing a notice on failed: ${_kind(e)}');
    }
  }

  /// Posts the outbox: an entry is done once one pairing of its device took it. A device being
  /// removed whose notices all went is forgotten then.
  Future<void> _flush() async {
    if (book.outbox.isEmpty) return _finishRemovals();
    final left = <({String deviceId, String json})>[];
    for (final o in book.outbox) {
      final d = book.device(o.deviceId) ?? book.removingDevice(o.deviceId);
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
    await _finishRemovals();
  }

  // Removals waiting for this device to be online ([DeviceBook.removing]).

  /// Forgets each device being removed whose notices a server took.
  Future<void> _finishRemovals() async {
    final done = [for (final d in book.removing) if (!book.outbox.any((o) => o.deviceId == d.deviceId)) d.deviceId];
    if (done.isEmpty) return;
    for (final id in done) {
      await _endRemoval(id);
    }
    await _put(book);
  }

  /// Ends the removal of a device the other side already let go: every pairing with it is
  /// gone or removed by it, so the notice has nowhere to go and is not needed.
  Future<void> _checkRemovals() async {
    if (book.removing.isEmpty) return;
    final records = {for (final r in await _api.privatePairings()) r.id: r};
    final gone = [
      for (final d in book.removing)
        if (d.pairingIds.every((id) => records[id] == null || records[id]!.removedByPeer)) d.deviceId,
    ];
    if (gone.isEmpty) return;
    for (final id in gone) {
      await _endRemoval(id);
    }
    await _put(book);
  }

  /// Forgets the device [deviceId] being removed: its pairings go (which also tells it) and
  /// so do its notices not sent.
  Future<void> _endRemoval(String deviceId) async {
    final d = book.removingDevice(deviceId);
    if (d == null) return;
    for (final id in d.pairingIds) {
      await _unpair(id);
    }
    _book = book.copyWith(
      removing: [for (final r in book.removing) if (r.deviceId != deviceId) r],
      outbox: [for (final o in book.outbox) if (o.deviceId != deviceId) o],
    );
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
      if (r.kind == TxKind.received && !r.isRequest) {
        // An answer this device made: the other hears it, for a payment both answered.
        final key = 'recv:$slateId';
        if (r.confirmed) {
          announced.remove(key);
        } else if (announced[key] == null && r.status != TxStatus.cancelled) {
          outs ??= await host.outputs();
          final mine = r.outputCommits.isNotEmpty
              ? r.outputCommits
              : [for (final o in outs) if (o.txId == r.id) o.commitment];
          if (mine.isEmpty) continue;
          await _broadcast(NoticeType.recv, {'slateId': slateId, 'outputs': mine.take(16).toList()});
          announced[key] = AnnouncedState.sent;
        }
        continue;
      }
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
        // Its change: the other device folds it into this payment's row once the chain shows it.
        final change = r.outputCommits.isNotEmpty
            ? r.outputCommits
            : [
                for (final o in outs)
                  if (o.status == WalletOutputStatus.unconfirmed && o.txId == r.id) o.commitment,
              ];
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
          if (change.isNotEmpty) 'change': change.take(maxNoticeChange).toList(),
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

  /// Cancels, quietly, this device's answers to payments the linked device answered too once
  /// the chain shows the linked device's outputs: the sender used that answer, so this one's
  /// coins never come. History shows the payment as received on that device
  /// ([mergeDeviceHistory]).
  Future<void> _dropAnswersTakenThere() async {
    if (book.theirReceives.isEmpty) return;
    final rows = await host.transactions();
    for (final r in answersTakenThere(rows, book)) {
      if (!r.cancellable || r.id == null) continue;
      try {
        await host.cancelTransaction(r.id!);
        logInfo('devices', 'an answer the linked device made instead was dropped');
      } on Object catch (e) {
        logWarn('devices', 'dropping an answer the linked device made failed: ${_kind(e)}');
      }
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
    final tip = await host.tipHeight();
    final kernels = await _lookUpKernels(tip, now);
    final next = pruneHolds(sweepHolds(book.holds, spent: await _spent(), tip: tip, now: now, kernels: kernels), now);
    await _put(book.copyWith(holds: next));
  }

  /// When each kernel was last looked up, and first found absent: excess → the tip then.
  final Map<String, int> _kernelAsked = {};
  final Map<String, int> _kernelAbsent = {};

  /// Kernels of payments the chain confirmed by their coins only that have their answer.
  final Set<String> _kernelSettled = {};
  bool _kernelLookupWarned = false;

  /// The chain's word on the kernels of the payments still open here, each once per block, and
  /// on those the chain confirmed by their coins only, without a block, until it is found or
  /// absent ([kernelWanted]). A kernel counts as absent only when two lookups at two heights
  /// did not find it, so one node answer that missed it ends nothing. A lookup that fails is
  /// left out: unknown, not absent.
  Future<KernelAnswers> _lookUpKernels(int? tip, DateTime now) async {
    if (tip == null || tip <= 0 || !host.online) return const {};
    final answers = <String, KernelLocation?>{};
    for (final h in book.holds) {
      final kernel = h.kernel;
      if (kernel == null || !kernelWanted(h) || answers.containsKey(kernel) || _kernelSettled.contains(kernel)) continue;
      final last = _kernelAsked[kernel];
      if (last != null && last >= tip) continue;
      final KernelLocation? found;
      try {
        found = await host.kernelOnChain(kernel, minHeight: kernelFloor(h, tip: tip, now: now));
      } on Object catch (e) {
        // Unknown, not absent: asked again on the next sweep.
        if (!_kernelLookupWarned) logWarn('devices', 'kernel lookup failed: ${_kind(e)}');
        _kernelLookupWarned = true;
        continue;
      }
      _kernelAsked[kernel] = tip;
      if (found == null && (_kernelAbsent[kernel] ??= tip) >= tip) continue;
      answers[kernel] = found;
      // Only a kernel found settles it: an absent one is the sweep's to judge.
      if (found != null && h.state == HoldState.spent) _kernelSettled.add(kernel);
    }
    return answers;
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
      // A further pairing not done within [pairingWait] goes; the inviter makes it again.
      final stale = [for (final p in d.pending) if (!elsewhere.contains(p) && _clock().difference(p.startedAt) > pairingWait) p];
      for (final p in stale) {
        logWarn('devices', 'a further pairing did not finish in time; making it again');
        await _unpair(p.pairingId);
      }
      final ok = <({String server, List<SasWord> sas})>[];
      final pending = <PendingPairing>[
        for (final p in d.pending)
          if (!elsewhere.contains(p) && !stale.contains(p))
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
      await _completeServers(d.deviceId);
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

  /// Forgets [deviceId]: its pairings go and, unless [keepHolds], the coins it held are freed
  /// (spent where the chain says so). A server proposal waiting on it goes too.
  Future<void> _forget(String deviceId, {bool keepHolds = false}) async {
    final d = book.device(deviceId);
    if (d == null) return;
    for (final id in d.pairingIds) {
      await _unpair(id);
    }
    final holds = keepHolds ? book.holds : unlinkHolds(book.holds, deviceId, spent: await _spent(), now: _clock());
    _book = book
        .withoutDevice(deviceId)
        .copyWith(holds: holds, outbox: [for (final o in book.outbox) if (o.deviceId != deviceId) o], clearProposal: true);
  }

  // The user's actions.

  /// Ends the link with [deviceId] on both devices: it is told (`unlink`, which names this
  /// device), its pairings go, which also tells it should the notice not arrive, and its coins
  /// are freed here. It does not protect the money: a device with the phrase can always spend.
  ///
  /// When no server takes the notice now (Offline, paused, no network), the device moves to
  /// [DeviceBook.removing] with its pairings and the notice kept, and is forgotten once a later
  /// read posts it. Removing a device being removed forgets it here at once.
  Future<void> removeDevice(String deviceId) async {
    if (book.removingDevice(deviceId) != null) {
      await _endRemoval(deviceId);
      await _put(book);
      _schedule();
      return;
    }
    if (book.device(deviceId) == null) return;
    await _send(deviceId, NoticeType.unlink, const {});
    final d = book.device(deviceId);
    if (d != null && book.outbox.any((o) => o.deviceId == deviceId)) {
      final holds = unlinkHolds(book.holds, deviceId, spent: await _spent(), now: _clock());
      _book = book.withoutDevice(deviceId).copyWith(removing: [...book.removing, d], holds: holds, clearProposal: true);
    } else {
      await _forget(deviceId);
    }
    await _put(book);
    _schedule();
  }

  /// Before this wallet is deleted: tells every linked device, best effort, within [wait] each,
  /// so it does not list this device, and post to it, for ever. The delete goes on whatever
  /// happens here; a device not told forgets this one once its pairings are gone.
  Future<void> unlinkAll({Duration wait = unlinkBeforeDeleteWait}) async {
    if (!loaded) {
      try {
        await load();
      } on Object {
        return;
      }
    }
    for (final d in [...book.devices]) {
      try {
        await removeDevice(d.deviceId).timeout(wait);
      } on Object catch (e) {
        logWarn('devices', 'a linked device was not told of the delete: ${_kind(e)}');
      }
    }
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

  /// Proposes [servers] for the link; with no device linked they are the set at once. No screen
  /// offers it now; the handling of a proposal that comes in stays.
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

  // Linking. One device shows a code, the other scans or pastes it. Once the private pairing
  // is made, each side posts its hello by itself (its pictures show as "Linking…", nothing to
  // tap) and checks the other's: the hello's proof needs the wallet's address key, which only
  // a device with the recovery phrase has, and the four pictures are the pairing's own.

  /// The servers a new link starts with: the link's set, else [defaults].
  List<String> linkServers(List<String> defaults) => book.servers.isNotEmpty ? book.servers : defaults.take(maxLinkServers).toList();

  /// No device is linked yet: one can be ([maxLinkedDevices]).
  bool get canLinkMore => book.devices.length < maxLinkedDevices - 1;

  void _setLink(LinkFlow? flow) {
    _link = flow;
    if (_linking) {
      _endLinkBoost ??= boostRelays(host.boosts, boostMinInterval);
    } else {
      _endLinkBoost?.call();
      _endLinkBoost = null;
    }
    _changed();
    _schedule();
  }

  /// This device shows the code, on [servers] (the first carries the link).
  Future<void> startShowing(List<String> servers) async {
    if (!loaded) await load();
    final set = servers.take(maxLinkServers).toList();
    _peer = _LinkPeer();
    if (!supported) return _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.failed, failure: LinkFailure.unsupported));
    if (!canLinkMore) return _setLink(LinkFlow(role: LinkRole.shows, phase: LinkPhase.failed, servers: set, failure: LinkFailure.tooMany));
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
  /// is answered, and the hello's proof decides ([_finishLink]). A device that is full still
  /// answers, to tell the other device so ([LinkFlow.refusing]); it then shows Replace.
  Future<void> startScanned(String text) async {
    if (!loaded) await load();
    _peer = _LinkPeer();
    final code = deviceLinkIn(text);
    if (!supported) return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.unsupported));
    if (code == null) return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.invalidCode));
    final refusing = !canLinkMore;
    _setLink(LinkFlow(role: LinkRole.scans, phase: LinkPhase.starting, refusing: refusing));
    try {
      if (code.fingerprint != null &&
          code.fingerprint != deviceLinkFingerprint(await host.signProof(deviceLinkFingerprintMessage(code.invite)))) {
        logInfo('devices', 'link code of another wallet refused');
        return _setLink(const LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: LinkFailure.otherWalletCode));
      }
      final r = await _api.acceptPrivateInvite(link: code.invite, name: book.deviceName);
      _setLink(
        LinkFlow(role: LinkRole.scans, phase: LinkPhase.waiting, pairingId: r.id, otherName: r.name, servers: [?linkServerOf(r.homeRelay)], refusing: refusing),
      );
      unawaited(sync(DeviceSyncTrigger.link));
    } on Object catch (e) {
      _setLink(LinkFlow(role: LinkRole.scans, phase: LinkPhase.failed, failure: _failureOf(e)));
    }
  }

  static LinkFailure _failureOf(Object e) => switch (pairingFailureOf(e)) {
    PairingFailure.expired => LinkFailure.expired,
    PairingFailure.alreadyUsed || PairingFailure.notFound || PairingFailure.cancelled => LinkFailure.notFound,
    PairingFailure.ownCard => LinkFailure.ownCode,
    PairingFailure.newerVersion => LinkFailure.update,
    PairingFailure.invalid || PairingFailure.wrongNetwork => LinkFailure.invalidCode,
    null => e is WalletError && e.kind == WalletErrorKind.unsupported ? LinkFailure.unsupported : LinkFailure.unreachable,
    _ => LinkFailure.unreachable,
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
        final linking = flow.to(LinkPhase.linking, sas: r.sas, otherName: r.name, servers: servers);
        _setLink(linking);
        if (flow.refusing) return _refuse(linking);
        try {
          await _sendHello(id, linking);
        } on Object catch (e) {
          await _unpair(id);
          return _setLink(linking.to(LinkPhase.failed, failure: _failureOf(e)));
        }
        if (_peer.hello != null) await _finishLink();
        return;
      }
      final expires = flow.expiresAt ?? r.expiresAt;
      if (expires != null && now.isAfter(expires)) {
        await _unpair(id);
        return _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.expired));
      }
    }
    final sent = _peer.helloSentAt;
    if (flow.phase == LinkPhase.linking && sent != null && now.difference(sent) > linkHelloWait) {
      await _unpair(id);
      _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.unreachable));
    }
  }

  /// Confirms the pairing on this side and posts this device's hello with its proof.
  Future<void> _sendHello(String id, LinkFlow flow) async {
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
        'kind': kind.name,
      },
    );
    await _api.postPayload(id: id, bytes: hello.encode());
    _peer.helloSentAt = _clock();
  }

  /// This device is full: once paired it says so and unpairs, and shows Replace.
  Future<void> _refuse(LinkFlow flow) async {
    final id = flow.pairingId!;
    final n = Notice(
      type: NoticeType.full,
      id: randomHexId(),
      seq: 1,
      dev: book.deviceId,
      ts: _clock().millisecondsSinceEpoch,
      body: {'linked': book.linked?.name ?? ''},
    );
    try {
      // LEPIC carries a payload only on a pairing whose words this side confirmed, as a hello
      // does; out before the unpair, which drops what still waits in the outbox.
      await _api.checkWords(id, PairingCheck.match);
      await _api.postPayload(id: id, bytes: n.encode());
      await _api.collectPrivate(only: [id]);
    } on Object catch (e) {
      logWarn('devices', 'the refusal was not posted: ${_kind(e)}');
    }
    await _unpair(id);
    _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.tooMany));
  }

  /// A payload on the pairing of the link in the making: the other device's hello, or its
  /// refusal; anything after a hello waits until the link is made.
  Future<bool> _receiveLink(PairingPayload p) async {
    final flow = _link!;
    final id = flow.pairingId!;
    if (p.bytes.length > deviceNoticeMaxBytes) return _drop('notice too large');
    final n = decodeNotice(p.bytes).notice;
    if (n == null) return _drop('link notice not readable');
    if (n.otherVersion) {
      logInfo('devices', 'the other device writes wire version ${n.v}');
      await _unpair(id);
      _setLink(flow.to(LinkPhase.failed, failure: n.v > deviceWireVersion ? LinkFailure.update : LinkFailure.updateOther));
      return true;
    }
    if (n.type == NoticeType.full) {
      if (!noticeBodyValid(NoticeType.full, n.body)) return _drop('link refusal with a bad body');
      await _unpair(id);
      _setLink(flow.to(LinkPhase.failed, failure: LinkFailure.full));
      return true;
    }
    if (n.type != NoticeType.hello) return false;
    if (n.seq != 1 || !noticeBodyValid(NoticeType.hello, n.body) || n.body['deviceId'] != n.dev || n.dev == book.deviceId) {
      return _drop('link hello with a bad body');
    }
    _peer.hello = n;
    if (_peer.helloSentAt != null) await _finishLink();
    return true;
  }

  Future<void> _finishLink() async {
    final flow = _link;
    final hello = _peer.hello;
    final id = flow?.pairingId;
    if (flow == null || hello == null || id == null || flow.phase == LinkPhase.done || flow.phase == LinkPhase.failed) return;
    // The address is public, so it only turns another wallet away early; the proof is the
    // check: only a device holding this wallet's phrase can sign this pairing's transcript.
    final key = await host.walletKey();
    final proof = hello.body['proof'];
    if (hello.body['walletAddress'] != key ||
        proof is! String ||
        flow.sas.length != 4 ||
        !await host.verifyProof(helloTranscript(hello.dev, flow.sas), proof)) {
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
    // Linked again while its removal waits: the removal is over.
    await _endRemoval(theirId);
    final before = book.device(theirId);
    if (before != null) await _forget(theirId, keepHolds: true);
    final device = LinkedDevice(
      deviceId: theirId,
      name: _apart(_shownName(hello.body['name'], before?.name ?? '?'), theirId),
      kind: DeviceKind.values.asNameMap()[hello.body['kind']],
      pairings: {server: id},
      linkedAt: _clock(),
      lastSeen: _clock(),
      seqOut: 1,
      seqIn: 1,
      seenIds: [hello.id],
    );
    // The only link: both devices take the set of the device that showed the code, whatever an
    // earlier link used. The second server's pairing follows over the channel
    // ([_completeServers]).
    _book = book.withDevice(device).copyWith(
      servers: servers,
      serversVersion: max(1, book.serversVersion + 1),
      clearProposal: true,
      theirReceives: const {},
    );
    await _put(book);
    _setLink(flow.to(LinkPhase.done, device: device));
    unawaited(sync(DeviceSyncTrigger.link));
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

  /// After a link was refused here as [LinkFailure.tooMany], with the user's confirm: the device
  /// linked is removed (told, its coins here released) and the link starts again, a new code
  /// when this device showed one; the other device scans it, or shows a new code to scan.
  Future<void> replaceLinked() async {
    final flow = _link;
    if (flow == null || flow.failure != LinkFailure.tooMany) return;
    for (final d in [...book.devices]) {
      await removeDevice(d.deviceId);
    }
    _setLink(null);
    if (flow.role == LinkRole.shows && flow.servers.isNotEmpty) await startShowing(flow.servers);
  }

  static String _kind(Object e) => e is WalletError ? e.kind.name : e.runtimeType.toString();
}
