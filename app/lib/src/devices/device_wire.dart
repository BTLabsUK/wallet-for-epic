// SPDX-License-Identifier: Apache-2.0
/// The one envelope linked devices send each other, as the payload bytes of a private pairing
/// (UTF-8 JSON): `{"v":1,"type":…,"id":…,"seq":…,"dev":…,"ts":…,"body":{…}}`.
///
/// - `v`: the format version; a newer one is read for its place in the order and ignored.
/// - `type`: what it says ([NoticeType]); an unknown type is ignored the same way, so later
///   kinds (labels, contacts) need no change here or in LEPIC.
/// - `id`: 128 random bits; the copy that comes through the second server is dropped by it.
/// - `seq`: the sender's number for this receiver, from 1; notices apply in this order.
/// - `dev`: the sender's device id; it must be the device the pairing belongs to.
/// - `ts`: when it was sent (ms since the epoch), informational.
///
/// [decodeNotice] checks the size before parsing and the envelope's shape; [noticeBodyValid]
/// checks a body against its type before any handler sees it.
library;

import 'dart:convert';

import 'device_model.dart';

/// The version this app writes and reads.
const int deviceWireVersion = 1;

/// The largest notice read; a larger payload is dropped before it is parsed.
const int deviceNoticeMaxBytes = 16 * 1024;

/// The longest device name.
const int deviceNameMaxLength = 48;

enum NoticeType {
  /// After the pictures matched on the sender: its device id, name, wallet and servers.
  hello,

  /// The sender started a payment: hold its inputs here.
  send,

  /// A payment of the sender moved on (finalized, posted) or ended (cancelled, expired, failed,
  /// released): release the coins unless the chain shows them spent.
  status,

  /// The sender's new name.
  rename,

  /// The sender proposes other servers for the link; the user here accepts it or not.
  servers,

  /// The sender's user accepted servers [version].
  serversOk,

  /// An invite for a further private pairing (a second server, a server change, a re-key).
  pair2,

  /// The answerer's four pictures of that pairing.
  pair2ok,

  /// The inviter's pictures matched: the pairing is in use.
  pair2done,

  /// The sender removed this device.
  unlink,

  /// The sender removed a third device: remove it here too and re-key.
  removed,

  // Reserved for a later version: read for their order, not acted on.
  snapshotRequest,
  snapshot,
}

/// One notice.
class Notice {
  const Notice({
    required this.type,
    required this.id,
    required this.seq,
    required this.dev,
    required this.ts,
    this.body = const {},
    this.v = deviceWireVersion,
    this.typeName,
  });

  final int v;

  /// Null for a type this version does not know ([typeName] holds it).
  final NoticeType? type;
  final String? typeName;
  final String id;
  final int seq;
  final String dev;
  final int ts;
  final Map<String, Object?> body;

  /// Acted on here: this version and a known type.
  bool get readable => v == deviceWireVersion && type != null;

  List<int> encode() => utf8.encode(jsonEncode(toJson()));

  Map<String, Object?> toJson() => {'v': v, 'type': typeName ?? type!.name, 'id': id, 'seq': seq, 'dev': dev, 'ts': ts, 'body': body};
}

/// Why a payload was not read.
enum NoticeDrop { tooLarge, malformed }

/// [bytes] as a [Notice], or why it is dropped: too large (checked before parsing), not JSON, or
/// an envelope without its fields. A newer version or an unknown type still decodes (with
/// [Notice.readable] false) so its place in the order is kept.
({Notice? notice, NoticeDrop? drop}) decodeNotice(List<int> bytes) {
  if (bytes.length > deviceNoticeMaxBytes) return (notice: null, drop: NoticeDrop.tooLarge);
  Object? j;
  try {
    j = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return (notice: null, drop: NoticeDrop.malformed);
  }
  final notice = noticeFromJson(j);
  return notice == null ? (notice: null, drop: NoticeDrop.malformed) : (notice: notice, drop: null);
}

/// The envelope in [j], or null when it lacks a field or one has the wrong shape.
Notice? noticeFromJson(Object? j) {
  if (j is! Map) return null;
  final v = j['v'];
  final type = j['type'];
  final id = j['id'];
  final seq = j['seq'];
  final dev = j['dev'];
  final ts = j['ts'];
  final body = j['body'];
  if (v is! int || v < 1 || type is! String || type.isEmpty || type.length > 32) return null;
  if (!isHexId(id) || seq is! int || seq < 1 || !isHexId(dev) || ts is! int || body is! Map<String, Object?>) return null;
  return Notice(
    v: v,
    type: NoticeType.values.asNameMap()[type],
    typeName: type,
    id: id as String,
    seq: seq,
    dev: dev as String,
    ts: ts,
    body: body,
  );
}

// Body checks. Each field is the shape the handler reads, or the notice is dropped.

bool _str(Object? v, {int max = 256, bool empty = false}) => v is String && v.length <= max && (empty || v.isNotEmpty);
bool _optStr(Object? v, {int max = 256}) => v == null || _str(v, max: max, empty: true);
bool _optInt(Object? v) => v == null || (v is int && v >= 0);
bool _amount(Object? v) => v is String && RegExp(r'^[0-9]{1,20}$').hasMatch(v);
bool _optAmount(Object? v) => v == null || _amount(v);
bool _commit(Object? v) => v is String && RegExp(r'^[0-9a-f]{66}$').hasMatch(v);
bool _servers(Object? v) => v is List && v.isNotEmpty && v.length <= maxLinkServers && v.every((s) => _str(s, max: 255));
bool _sas(Object? v) => v is List && v.length == 4 && v.every((s) => _str(s, max: 64));

/// A hello's proof: an address key signature, DER in hex (8 to 72 bytes). Absent in a hello of
/// an app from before proofs; such a hello is read and the link refused ([DeviceService]).
bool _optProof(Object? v) => v == null || (v is String && RegExp(r'^[0-9a-f]{16,144}$').hasMatch(v));

/// The payment states a `status` notice names.
const noticeStatusStates = {'finalized', 'posted', 'cancelled', 'expired', 'failed', 'released'};

/// The codes a failed payment's `status` notice may carry as `why`: no free text goes over the
/// wire, the receiving device words them in its own language.
const noticeFailureCodes = {'notDelivered', 'refused', 'inputsSpent', 'other'};

/// Whether [body] is a valid body of [type].
bool noticeBodyValid(NoticeType type, Map<String, Object?> b) => switch (type) {
  NoticeType.hello =>
    isHexId(b['deviceId']) &&
        _str(b['name'], max: deviceNameMaxLength) &&
        _str(b['walletAddress'], max: 128) &&
        _servers(b['servers']) &&
        _optProof(b['proof']),
  NoticeType.send =>
    _str(b['slateId'], max: 64) &&
        _optInt(b['txId']) &&
        b['inputs'] is List &&
        (b['inputs'] as List).isNotEmpty &&
        (b['inputs'] as List).length <= 500 &&
        (b['inputs'] as List).every(_commit) &&
        _amount(b['amount']) &&
        _optAmount(b['fee']) &&
        _optStr(b['counterparty']) &&
        _optStr(b['method'], max: 16) &&
        _optStr(b['message'], max: 512) &&
        _optInt(b['cutoffHeight']) &&
        _optInt(b['createdAt']),
  NoticeType.status =>
    _str(b['slateId'], max: 64) &&
        noticeStatusStates.contains(b['state']) &&
        _optStr(b['kernel'], max: 66) &&
        _optInt(b['height']) &&
        (b['why'] == null || (b['why'] is String && noticeFailureCodes.contains(b['why']))),
  NoticeType.rename => _str(b['name'], max: deviceNameMaxLength),
  NoticeType.servers => _servers(b['set']) && b['version'] is int,
  NoticeType.serversOk => b['version'] is int,
  NoticeType.pair2 => _str(b['inviteLink'], max: 4096) && _str(b['server'], max: 255) && (b['rekey'] == null || b['rekey'] is bool),
  NoticeType.pair2ok || NoticeType.pair2done => _str(b['server'], max: 255) && _sas(b['sas']),
  NoticeType.unlink => true,
  NoticeType.removed => isHexId(b['deviceId']),
  NoticeType.snapshotRequest || NoticeType.snapshot => true,
};
