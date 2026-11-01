// SPDX-License-Identifier: Apache-2.0
/// Linked devices: what one wallet keeps about the other devices that hold the same wallet,
/// and about the coins they are spending. App data, per wallet (`device_store.dart`); LEPIC
/// only carries the bytes over private pairings (`pairing_api.dart`).
///
/// Nothing here can spend, sign or move money: a notice from another device can only hold or
/// release coins on this one and add details to its history (`device_service.dart`).
library;

import 'dart:math';

import '../models.dart' show DeviceEnding;
import '../settings_file/host_settings.dart';

/// The most devices one wallet links, this one included: this device and one linked device.
/// Links are pairwise, so a third device would not hear the other's payments.
const int maxLinkedDevices = 2;

/// The most servers a link uses: `epicbox.link_servers` of `app-config.toml`.
int get maxLinkServers => appConfig.linkServerCount;

/// What a device is, for its icon: said in its hello.
enum DeviceKind { phone, desktop }

/// A random 128-bit id, 32 lowercase hex characters: a device id or a notice id.
String randomHexId([Random? random]) {
  final r = random ?? Random.secure();
  return [for (var i = 0; i < 16; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}

bool isHexId(Object? v) => v is String && v.length == 32 && RegExp(r'^[0-9a-f]{32}$').hasMatch(v);

/// A set of servers proposed for the link (Settings › Linked devices › Servers): by this device
/// ([fromHere]) waiting for the others to accept, or by another device waiting for the user here.
class ServerProposal {
  const ServerProposal({required this.servers, required this.version, required this.fromHere, this.accepted = const {}});

  final List<String> servers;
  final int version;
  final bool fromHere;

  /// The devices that accepted it (proposals from here).
  final Set<String> accepted;

  ServerProposal accept(String deviceId) =>
      ServerProposal(servers: servers, version: version, fromHere: fromHere, accepted: {...accepted, deviceId});

  Map<String, Object?> toJson() => {'servers': servers, 'version': version, 'here': fromHere, 'accepted': accepted.toList()};

  static ServerProposal? fromJson(Object? j) {
    if (j is! Map) return null;
    return ServerProposal(
      servers: [for (final s in (j['servers'] as List? ?? const [])) '$s'],
      version: (j['version'] as num?)?.toInt() ?? 0,
      fromHere: j['here'] == true,
      accepted: {for (final s in (j['accepted'] as List? ?? const [])) '$s'},
    );
  }
}

/// A private pairing being made on [server] over the confirmed channel: the second server of a
/// link, a server change, or a pairing the link lost made again. Its four pictures are compared
/// over the channel, not by the user ([DeviceService]).
class PendingPairing {
  const PendingPairing({
    required this.server,
    required this.pairingId,
    required this.inviter,
    required this.startedAt,
    this.replaces,
    this.okSent = false,
  });

  final String server;
  final String pairingId;

  /// This device made the invite (and confirms once the other's pictures match).
  final bool inviter;

  /// When the invite was made or answered: one not done within [pairingWait] is dropped and
  /// made again.
  final DateTime startedAt;

  /// The pairing on [server] it replaces, dropped once it is confirmed.
  final String? replaces;

  /// The answerer sent its pictures (`pair2ok`).
  final bool okSent;

  PendingPairing sent() =>
      PendingPairing(server: server, pairingId: pairingId, inviter: inviter, startedAt: startedAt, replaces: replaces, okSent: true);

  Map<String, Object?> toJson() => {
    'server': server,
    'id': pairingId,
    'inviter': inviter,
    'at': startedAt.millisecondsSinceEpoch,
    'replaces': replaces,
    'ok': okSent,
  };

  static PendingPairing? fromJson(Object? j) {
    if (j is! Map || j['server'] is! String || j['id'] is! String) return null;
    return PendingPairing(
      server: j['server'] as String,
      pairingId: j['id'] as String,
      inviter: j['inviter'] == true,
      startedAt: _time(j['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      replaces: j['replaces'] as String?,
      okSent: j['ok'] == true,
    );
  }
}

/// How long a further pairing may take before it is dropped and made again.
const Duration pairingWait = Duration(minutes: 5);

/// Another device of this wallet.
class LinkedDevice {
  const LinkedDevice({
    required this.deviceId,
    required this.name,
    required this.pairings,
    required this.linkedAt,
    this.lastSeen,
    this.seqOut = 0,
    this.seqIn = 0,
    this.waiting = const {},
    this.seenIds = const [],
    this.pending = const [],
    this.early = const {},
    this.otherVersion,
    this.kind,
  });

  final String deviceId;
  final String name;

  /// What it is, as its hello said; null for a link made before hellos said.
  final DeviceKind? kind;

  /// Sequence numbers among [waiting] whose notices were applied as they came, ahead of a
  /// missing one (a `send`, a `status` of a known hold, `unlink`, `recv`, `fwd`): they are not
  /// applied again when the order reaches them.
  final Set<int> early;

  /// The wire version of the last notice from it that was not this app's, until a notice of
  /// this version comes: the user is told to update that device. Null while its notices read.
  final int? otherVersion;

  /// Its private pairings, one per server: server → pairing id.
  final Map<String, String> pairings;
  final DateTime linkedAt;

  /// When a notice from it was last read.
  final DateTime? lastSeen;

  /// The last sequence number sent to it, and the last one applied from it.
  final int seqOut;
  final int seqIn;

  /// Notices from it that came ahead of a missing one: seq → (envelope JSON, when it came).
  final Map<int, ({String json, DateTime at})> waiting;

  /// The ids of the last notices read from it, for duplicates through the second server.
  final List<String> seenIds;

  /// Pairings being made with it over the channel.
  final List<PendingPairing> pending;

  List<String> get servers => pairings.keys.toList();

  /// Every pairing it is reached and read through, the pending ones included.
  Iterable<String> get pairingIds sync* {
    yield* pairings.values;
    for (final p in pending) {
      yield p.pairingId;
    }
  }

  LinkedDevice copyWith({
    String? name,
    Map<String, String>? pairings,
    DateTime? lastSeen,
    int? seqOut,
    int? seqIn,
    Map<int, ({String json, DateTime at})>? waiting,
    List<String>? seenIds,
    List<PendingPairing>? pending,
    Set<int>? early,
    int? otherVersion,
    bool clearOtherVersion = false,
  }) => LinkedDevice(
    deviceId: deviceId,
    name: name ?? this.name,
    kind: kind,
    pairings: pairings ?? this.pairings,
    linkedAt: linkedAt,
    lastSeen: lastSeen ?? this.lastSeen,
    seqOut: seqOut ?? this.seqOut,
    seqIn: seqIn ?? this.seqIn,
    waiting: waiting ?? this.waiting,
    seenIds: seenIds ?? this.seenIds,
    pending: pending ?? this.pending,
    early: early ?? this.early,
    otherVersion: clearOtherVersion ? null : otherVersion ?? this.otherVersion,
  );

  Map<String, Object?> toJson() => {
    'id': deviceId,
    'name': name,
    'pairings': pairings,
    'linked': linkedAt.millisecondsSinceEpoch,
    'seen': lastSeen?.millisecondsSinceEpoch,
    'out': seqOut,
    'in': seqIn,
    'waiting': {for (final e in waiting.entries) '${e.key}': {'json': e.value.json, 'at': e.value.at.millisecondsSinceEpoch}},
    'ids': seenIds,
    'pending': [for (final p in pending) p.toJson()],
    'early': early.toList(),
    'ver': otherVersion,
    'kind': kind?.name,
  };

  static LinkedDevice? fromJson(Object? j) {
    if (j is! Map || !isHexId(j['id']) || j['name'] is! String) return null;
    final pairings = j['pairings'];
    final waiting = j['waiting'];
    return LinkedDevice(
      deviceId: j['id'] as String,
      name: j['name'] as String,
      pairings: {if (pairings is Map) for (final e in pairings.entries) '${e.key}': '${e.value}'},
      linkedAt: _time(j['linked']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastSeen: _time(j['seen']),
      seqOut: (j['out'] as num?)?.toInt() ?? 0,
      seqIn: (j['in'] as num?)?.toInt() ?? 0,
      waiting: {
        if (waiting is Map)
          for (final e in waiting.entries)
            if (int.tryParse('${e.key}') != null && e.value is Map && (e.value as Map)['json'] is String)
              int.parse('${e.key}'): (json: (e.value as Map)['json'] as String, at: _time((e.value as Map)['at']) ?? DateTime.now()),
      },
      seenIds: [for (final s in (j['ids'] as List? ?? const [])) '$s'],
      pending: [for (final p in (j['pending'] as List? ?? const [])) ?PendingPairing.fromJson(p)],
      early: {for (final e in (j['early'] as List? ?? const [])) if (e is num) e.toInt()},
      otherVersion: (j['ver'] as num?)?.toInt(),
      kind: DeviceKind.values.asNameMap()[j['kind']],
    );
  }
}

/// Where coins another device holds stand.
enum HoldState {
  /// Its payment is under way: the coins stay out of this device's sends.
  held,

  /// Its payment was posted: still held until the chain shows the coins spent.
  posted,

  /// The chain shows them spent: the payment is history ("Sent from `<device>`").
  spent,

  /// The device said its payment ended without spending them (cancelled, expired, failed,
  /// released).
  released,

  /// Past its cutoff height and still unspent: the payment expired on its own.
  expired,

  /// Posted 1,440 blocks ago and not on chain, or held for 7 days: given up.
  timedOut,

  /// Its device was removed.
  unlinked,

  /// Released by hand on this device.
  byHand;

  /// The coins are still left out of sends.
  bool get holds => this == held || this == posted;

  /// Ended without the coins being spent.
  bool get freed => !holds && this != spent;

  /// Freed on this device (by hand, a fallback, the device's removal) while its device may still
  /// send it: history shows it as released here.
  bool get releasedHere => this == byHand || this == expired || this == timedOut || this == unlinked;
}

/// Coins of this wallet another device is spending, from its `send` notice.
class HeldPayment {
  const HeldPayment({
    required this.deviceId,
    required this.slateId,
    required this.commitments,
    required this.amount,
    required this.lockedAt,
    this.state = HoldState.held,
    this.txId,
    this.fee,
    this.counterparty,
    this.method,
    this.message,
    this.cutoffHeight,
    this.postedHeight,
    this.kernel,
    this.createdAt,
    this.deviceName,
    this.changedAt,
    this.reason,
    this.why,
  });

  final String deviceId;
  final String slateId;

  /// The input commitments it spends that this wallet holds.
  final List<String> commitments;
  final BigInt amount;
  final DateTime lockedAt;
  final HoldState state;
  final int? txId;
  final BigInt? fee;
  final String? counterparty;
  final String? method;
  final String? message;
  final int? cutoffHeight;
  final int? postedHeight;
  final String? kernel;

  /// When the other device made the payment.
  final DateTime? createdAt;

  /// The device's name when the coins were held, for history once it is removed.
  final String? deviceName;
  final DateTime? changedAt;

  /// The other device's word for how it ended (`cancelled`, `expired`, …), when it said.
  final String? reason;

  /// For a payment that failed there: its code for why (`notDelivered`, `refused`, `inputsSpent`,
  /// `other`), as a status notice carried it.
  final String? why;

  /// How this payment ended without spending its coins, for its row in the history; null while
  /// it is held or once the chain shows it spent. A hold the device ended itself reads as that
  /// ending; a fallback (past its cutoff, not on chain after posting, seven days) reads Expired.
  DeviceEnding? get ending => switch (state) {
    HoldState.held || HoldState.posted || HoldState.spent => null,
    HoldState.byHand || HoldState.unlinked => DeviceEnding.releasedHere,
    HoldState.expired || HoldState.timedOut => DeviceEnding.expired,
    HoldState.released => switch (reason) {
      'failed' => DeviceEnding.failed,
      'expired' => DeviceEnding.expired,
      _ => DeviceEnding.cancelled,
    },
  };

  HeldPayment copyWith({HoldState? state, int? postedHeight, String? kernel, DateTime? changedAt, String? reason, String? why}) => HeldPayment(
    deviceId: deviceId,
    slateId: slateId,
    commitments: commitments,
    amount: amount,
    lockedAt: lockedAt,
    state: state ?? this.state,
    txId: txId,
    fee: fee,
    counterparty: counterparty,
    method: method,
    message: message,
    cutoffHeight: cutoffHeight,
    postedHeight: postedHeight ?? this.postedHeight,
    kernel: kernel ?? this.kernel,
    createdAt: createdAt,
    deviceName: deviceName,
    changedAt: changedAt ?? this.changedAt,
    reason: reason ?? this.reason,
    why: why ?? this.why,
  );

  Map<String, Object?> toJson() => {
    'dev': deviceId,
    'slate': slateId,
    'commits': commitments,
    'amount': '$amount',
    'locked': lockedAt.millisecondsSinceEpoch,
    'state': state.name,
    'tx': txId,
    'fee': fee?.toString(),
    'to': counterparty,
    'method': method,
    'msg': message,
    'cutoff': cutoffHeight,
    'posted': postedHeight,
    'kernel': kernel,
    'created': createdAt?.millisecondsSinceEpoch,
    'name': deviceName,
    'changed': changedAt?.millisecondsSinceEpoch,
    'reason': reason,
    'why': why,
  };

  static HeldPayment? fromJson(Object? j) {
    if (j is! Map || j['dev'] is! String || j['slate'] is! String) return null;
    final amount = BigInt.tryParse('${j['amount']}');
    if (amount == null) return null;
    return HeldPayment(
      deviceId: j['dev'] as String,
      slateId: j['slate'] as String,
      commitments: [for (final c in (j['commits'] as List? ?? const [])) '$c'],
      amount: amount,
      lockedAt: _time(j['locked']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      state: HoldState.values.asNameMap()[j['state']] ?? HoldState.released,
      txId: (j['tx'] as num?)?.toInt(),
      fee: j['fee'] == null ? null : BigInt.tryParse('${j['fee']}'),
      counterparty: j['to'] as String?,
      method: j['method'] as String?,
      message: j['msg'] as String?,
      cutoffHeight: (j['cutoff'] as num?)?.toInt(),
      postedHeight: (j['posted'] as num?)?.toInt(),
      kernel: j['kernel'] as String?,
      createdAt: _time(j['created']),
      deviceName: j['name'] as String?,
      changedAt: _time(j['changed']),
      reason: j['reason'] as String?,
      why: j['why'] as String?,
    );
  }
}

/// What this device last told the others about one of its own sends.
enum AnnouncedState { sent, finalized, posted, ended }

/// Everything the wallet keeps about linked devices.
class DeviceBook {
  const DeviceBook({
    required this.deviceId,
    required this.deviceName,
    this.devices = const [],
    this.removing = const [],
    this.holds = const [],
    this.servers = const [],
    this.serversVersion = 0,
    this.proposal,
    this.paused = false,
    this.announced = const {},
    this.outbox = const [],
    this.removedBy,
    this.theirReceives = const {},
  });

  /// A fresh book: a new random device id, [name] as this device's name.
  factory DeviceBook.fresh(String name) => DeviceBook(deviceId: randomHexId(), deviceName: name);

  final String deviceId;
  final String deviceName;
  final List<LinkedDevice> devices;

  /// Devices the user removed here whose `unlink` notice no server took yet (this device was
  /// offline): their outbox entries and pairings stay until a post goes through, then they are
  /// forgotten. Not a link any more: nothing is read from or sent to them but that notice, and
  /// they do not count toward [maxLinkedDevices].
  final List<LinkedDevice> removing;
  final List<HeldPayment> holds;

  /// The link's servers, up to [maxLinkServers]; empty until the first link.
  final List<String> servers;
  final int serversVersion;
  final ServerProposal? proposal;

  /// The pause switch: nothing is read or sent until it is off.
  final bool paused;

  /// This device's own sends the others were told about: slate id → what they last heard.
  final Map<String, AnnouncedState> announced;

  /// Notices not handed to the engine yet (paused, Offline, a failed post): device id and the
  /// encoded notice.
  final List<({String deviceId, String json})> outbox;

  /// The name of a device that removed this one, until the user saw it.
  final String? removedBy;

  /// Payments the linked device answered (its receives): slate id → the commitments of its
  /// outputs. When the chain shows one of them, this device's own answer to the same payment
  /// was not used ([mergeDeviceHistory], [DeviceService]). Both devices answer payments to the
  /// wallet's one address: the sender takes the first answer and refuses the second.
  final Map<String, List<String>> theirReceives;

  /// The one linked device, or null ([maxLinkedDevices]).
  LinkedDevice? get linked => devices.firstOrNull;

  LinkedDevice? device(String id) => devices.where((d) => d.deviceId == id).firstOrNull;

  /// The device [id] being removed ([removing]), or null.
  LinkedDevice? removingDevice(String id) => removing.where((d) => d.deviceId == id).firstOrNull;

  /// The device a private pairing [pairingId] belongs to, pending pairings included.
  LinkedDevice? deviceOfPairing(String pairingId) => devices.where((d) => d.pairingIds.contains(pairingId)).firstOrNull;

  /// The coins left out of this device's sends now.
  Set<String> get heldCommitments => {
    for (final h in holds)
      if (h.state.holds) ...h.commitments,
  };

  DeviceBook copyWith({
    String? deviceName,
    List<LinkedDevice>? devices,
    List<LinkedDevice>? removing,
    List<HeldPayment>? holds,
    List<String>? servers,
    int? serversVersion,
    ServerProposal? proposal,
    bool clearProposal = false,
    bool? paused,
    Map<String, AnnouncedState>? announced,
    List<({String deviceId, String json})>? outbox,
    String? removedBy,
    bool clearRemovedBy = false,
    Map<String, List<String>>? theirReceives,
  }) => DeviceBook(
    deviceId: deviceId,
    deviceName: deviceName ?? this.deviceName,
    devices: devices ?? this.devices,
    removing: removing ?? this.removing,
    holds: holds ?? this.holds,
    servers: servers ?? this.servers,
    serversVersion: serversVersion ?? this.serversVersion,
    proposal: clearProposal ? null : proposal ?? this.proposal,
    paused: paused ?? this.paused,
    announced: announced ?? this.announced,
    outbox: outbox ?? this.outbox,
    removedBy: clearRemovedBy ? null : removedBy ?? this.removedBy,
    theirReceives: theirReceives ?? this.theirReceives,
  );

  /// [device] put in place of the one with its id, or added.
  DeviceBook withDevice(LinkedDevice device) {
    final i = devices.indexWhere((d) => d.deviceId == device.deviceId);
    return copyWith(devices: i < 0 ? [...devices, device] : ([...devices]..[i] = device));
  }

  DeviceBook withoutDevice(String id) => copyWith(devices: [for (final d in devices) if (d.deviceId != id) d]);

  Map<String, Object?> toJson() => {
    'v': 1,
    'id': deviceId,
    'name': deviceName,
    'devices': [for (final d in devices) d.toJson()],
    'removing': [for (final d in removing) d.toJson()],
    'holds': [for (final h in holds) h.toJson()],
    'servers': servers,
    'serversVersion': serversVersion,
    'proposal': proposal?.toJson(),
    'paused': paused,
    'announced': {for (final e in announced.entries) e.key: e.value.name},
    'outbox': [for (final o in outbox) {'dev': o.deviceId, 'json': o.json}],
    'removedBy': removedBy,
    'theirReceives': theirReceives,
  };

  static DeviceBook? fromJson(Object? j) {
    if (j is! Map || !isHexId(j['id']) || j['name'] is! String) return null;
    final announced = j['announced'];
    return DeviceBook(
      deviceId: j['id'] as String,
      deviceName: j['name'] as String,
      devices: [for (final d in (j['devices'] as List? ?? const [])) ?LinkedDevice.fromJson(d)],
      removing: [for (final d in (j['removing'] as List? ?? const [])) ?LinkedDevice.fromJson(d)],
      holds: [for (final h in (j['holds'] as List? ?? const [])) ?HeldPayment.fromJson(h)],
      servers: [for (final s in (j['servers'] as List? ?? const [])) '$s'],
      serversVersion: (j['serversVersion'] as num?)?.toInt() ?? 0,
      proposal: ServerProposal.fromJson(j['proposal']),
      paused: j['paused'] == true,
      announced: {
        if (announced is Map)
          for (final e in announced.entries)
            if (AnnouncedState.values.asNameMap()[e.value] != null) '${e.key}': AnnouncedState.values.asNameMap()[e.value]!,
      },
      outbox: [
        for (final o in (j['outbox'] as List? ?? const []))
          if (o is Map && o['dev'] is String && o['json'] is String) (deviceId: o['dev'] as String, json: o['json'] as String),
      ],
      removedBy: j['removedBy'] as String?,
      theirReceives: {
        if (j['theirReceives'] case final Map m)
          for (final e in m.entries)
            if (e.value is List) '${e.key}': [for (final c in e.value as List) '$c'],
      },
    );
  }
}

DateTime? _time(Object? ms) => ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;

/// The servers a link proposes: this wallet's Epicbox server, then the others of the first
/// `epicbox.link_servers` of the Epicbox list ([servers] in tests), [maxLinkServers] in all.
/// Values as the server list writes them: `host`, or `host:port` off 443.
List<String> defaultLinkServers({required String ownHost, int ownPort = 443, List<String>? servers}) {
  final own = ownPort == 443 ? ownHost : '$ownHost:$ownPort';
  String key(String v) => v.toLowerCase().endsWith(':443') ? v.substring(0, v.length - 4).toLowerCase() : v.toLowerCase();
  final others = (servers ?? hostSettings.deviceLinkServers).where((v) => key(v) != key(own));
  return [own, ...others].take(maxLinkServers).toList();
}
