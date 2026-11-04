// SPDX-License-Identifier: Apache-2.0
/// A [PairingApi] that plays both sides of a pairing in memory, for widget tests, the
/// screenshot tour, the web preview and the desktop prototype. Nothing is sealed: links and
/// sealed files are readable JSON that only this fake opens.
///
/// Tests drive the other side with [answerInvite], [confirmAnswer], [hear], [peerMatch],
/// [peerMismatch], [neverFinished], [removedByPeer], [receiveRequest], [failPending],
/// [changeKeys], [restoreKeys], [setRelayDown], [secondAnswer] and [emit]. With
/// [autoAnswerAfter] set, a request is answered and an answer confirmed on their own after
/// that long, as the preview wants.
library;

import 'desktop/data/mock_hosts.dart';
import 'dart:async';
import 'dart:convert';

import 'models.dart';
import 'pairing_api.dart';
import 'recipient.dart';
import 'sas_table.dart';
import 'trust/policy.dart' show featureStatusNotices;
import 'wallet_service.dart' show FakeWalletSession, fakeTx;

/// The fake's links: `epiccash://<path>/1/<base64url of a JSON object>`.
String fakePairingLink(String path, Map<String, Object?> body) =>
    'epiccash://$path/1/${base64Url.encode(utf8.encode(jsonEncode(body))).replaceAll('=', '')}';

Map<String, Object?>? _readLink(String text, String path) {
  final link = pairingLinkIn(text);
  if (link == null) return null;
  final prefix = 'epiccash://$path/1/';
  if (!link.toLowerCase().startsWith(prefix)) return null;
  var b64 = link.substring(prefix.length);
  b64 = b64.padRight((b64.length + 3) ~/ 4 * 4, '=');
  try {
    final body = jsonDecode(utf8.decode(base64Url.decode(b64)));
    return body is Map<String, Object?> ? body : null;
  } on FormatException {
    return null;
  }
}

/// Four (or [count]) table entries from [seed], the same on both sides for one seed.
List<SasWord> fakeSasWords(String seed, {int count = sasWordCount}) {
  var h = 0x811c9dc5;
  final out = <SasWord>[];
  for (final unit in utf8.encode(seed)) {
    h = ((h ^ unit) * 0x01000193) & 0xffffffff;
  }
  for (var i = 0; i < count; i++) {
    h = ((h ^ (i + 7)) * 0x01000193) & 0xffffffff;
    out.add(sasTable[h & 0xff]);
  }
  return out;
}

/// A fake Epicbox address for [seed] on [relay]: 52 base58 characters, as the fakes accept.
String fakePairedAddress(String seed, [String? relay]) {
  relay ??= mockBox;
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var h = 0x9e3779b9;
  final b = StringBuffer('es');
  for (var i = 0; b.length < 52; i++) {
    for (final unit in utf8.encode('$seed$i')) {
      h = ((h ^ unit) * 0x01000193) & 0xffffffff;
    }
    b.write(alphabet[h % alphabet.length]);
  }
  return '$b@$relay';
}

class FakePairing implements PairingApi {
  FakePairing([this.session]);

  /// The session whose invoices and sends a pairing reaches, when there is one.
  final FakeWalletSession? session;

  /// When false, the fake behaves as a core without pairing ([NoPairing]).
  bool enabled = true;

  /// The Connection servers the app last set ([setConnectionServers]); null the defaults.
  List<String>? connectionServers;

  @override
  void setConnectionServers(List<String>? hosts) => connectionServers = hosts == null ? null : List.unmodifiable(hosts);

  /// Now, for expiries.
  DateTime Function() clock = DateTime.now;

  /// The relay the fake's own codes name ("Delivered via").
  String homeRelay = mockBox;

  /// This wallet's own payments address: what a request goes out from, and the key the
  /// lower-key rule compares.
  String ownAddress = fakePairedAddress('self');

  /// When set, [pairings] answers after this long, as the core's call does.
  Duration? listDelay;

  /// When set, the other side answers requests and confirms answers on its own after this long.
  Duration? autoAnswerAfter;

  /// The name the other side gives itself when it answers on its own.
  String autoAnswerName = 'Anna';

  /// When set, the relay is not reachable: answers wait to go by hand, requests cannot be
  /// posted.
  bool relayUnreachable = false;

  /// Epicbox is off on this wallet: a request cannot be sent ([PairingFailure.relayUnreachable]).
  bool epicboxOff = false;

  /// The Epicbox keys a request may go to: proven peers (a marked payment within 30 days and
  /// pair requests claimed). Addresses or keys; compared by key.
  final Set<String> provenPeers = {};

  /// The feature bits the other side announces when it answers ([answerInvite] default):
  /// status notices on, so the inviter waits until heard.
  int peerFeatures = featureStatusNotices;

  /// Whether a key check (a new pairing added to a contact that has one) finds the old keys:
  /// true is a restored wallet ("keys are back"), false another wallet ("keys changed").
  bool keyCheckFindsOldKeys = true;

  /// When set, the next open of a link fails with it.
  PairingFailure? nextOpenFailure;

  final List<PairingRecord> records = [];
  final List<PairingStray> strayList = [];
  final Map<String, PairingInvitePreview> _previews = {};

  /// The standing code, apart from [records]: an unused code is no row.
  PairingRecord? standing;

  /// The live requests to this wallet's address, oldest first, and the ids dismissed or
  /// answered (replays are dropped).
  final List<PairRequest> requestList = [];
  final Set<String> dismissedRequests = {};
  final Set<String> answeredRequests = {};

  /// Codes whose reply was opened by hand: as LEPIC, only these hold a finish link, unless
  /// the confirm could not be posted ([relayUnreachable]).
  final Set<String> _repliedByHand = {};
  final StreamController<PairingEvent> _events = StreamController<PairingEvent>.broadcast();
  final List<Timer> _timers = [];
  int _seq = 0;

  /// Every call that changed something, in order (`standing`, `request`, `accept`, `check:match`, …).
  final List<String> calls = [];

  String _id(String prefix) => '$prefix-${++_seq}';

  void _require(String call) {
    if (!enabled) throw pairingUnsupported(call);
  }

  PairingRecord _get(String id) => records.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'no pairing with that id'),
  );

  void _put(PairingRecord r) {
    final i = records.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      records[i] = r;
    } else {
      records.insert(0, r);
    }
  }

  String get ownKey => epicboxKey(ownAddress);

  bool _sameKey(String? a, String? b) => a != null && b != null && epicboxKey(a) == epicboxKey(b);

  /// The pairing whose contact sends from [address], matched on the key, or null. Ended
  /// records do not count.
  PairingRecord? recordFor(String address) {
    final key = epicboxKey(address);
    for (final r in records) {
      if (!r.ended && r.paymentsAddress != null && epicboxKey(r.paymentsAddress!) == key) return r;
    }
    return null;
  }

  /// A pairing in progress with [address]'s key: a pending code or request expecting it, a
  /// waiting record, or a live request from it (M7's lower-key rule applies to these).
  PairingRecord? inProgressWith(String address) {
    for (final r in records) {
      if (r.state == PairingState.pendingInvite && _sameKey(r.expectAddress, address)) return r;
      if (r.state == PairingState.pendingReply && _sameKey(r.expectAddress, address)) return r;
      if (r.state == PairingState.waiting && _sameKey(r.paymentsAddress, address)) return r;
    }
    return null;
  }

  /// Raises [event] as the engine would.
  void emit(PairingEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _later(void Function() run) {
    final after = autoAnswerAfter;
    if (after == null) return;
    _timers.add(Timer(after, run));
  }

  /// Stops the auto-answer timers and the event stream.
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _events.close();
  }

  // Test and preview hooks: the other side.

  /// Adds [record] as if it had been paired before (a seeded wallet, a test).
  void seed(PairingRecord record) => _put(record);

  /// A paired contact in one call, for tests and the preview. [state] waiting leaves the peer
  /// unheard; ended needs [endedReason]. [unproven]: made before 26.10.25, no proven address.
  PairingRecord seedPaired({
    bool unproven = false,
    required String name,
    String? id,
    PairingState state = PairingState.verified,
    PairingParty kind = PairingParty.person,
    bool allowInvoices = false,
    String? contactId,
    String? paymentsAddress,
    String? relay,
    SealMode seal = SealMode.on,
    PairingCaps caps = const PairingCaps(),
    DateTime? verifiedAt,
    DateTime? lastSealedIn,
    DateTime? peerVerifiedAt,
    bool relayDown = false,
    PairingWay way = PairingWay.link,
    List<SasWord>? sas,
    PairingEndReason? endedReason,
    int? peerFeatures,
    bool inviter = false,
  }) {
    final rid = id ?? _id('pairing');
    final now = clock();
    final ended = state == PairingState.ended;
    final record = PairingRecord(
      id: rid,
      state: state,
      way: way,
      inviter: inviter,
      createdAt: now.subtract(const Duration(days: 3)),
      name: name,
      kind: kind,
      caps: caps,
      sas: sas ?? fakeSasWords(rid),
      verifiedAt: state == PairingState.verified ? (verifiedAt ?? now.subtract(const Duration(days: 1))) : verifiedAt,
      allowInvoices: allowInvoices && state == PairingState.verified,
      seal: seal,
      homeRelay: relay ?? homeRelay,
      contactId: contactId,
      paymentsAddress: unproven ? null : (paymentsAddress ?? fakePairedAddress(rid)),
      lastSealedIn: lastSealedIn ?? now.subtract(const Duration(hours: 5)),
      peerHeardAt: state == PairingState.waiting ? null : now.subtract(const Duration(days: 3)),
      peerVerifiedAt: peerVerifiedAt,
      peerFeatures: peerFeatures ?? this.peerFeatures,
      endedReason: ended ? (endedReason ?? PairingEndReason.peerMismatch) : null,
      endedAt: ended ? now.subtract(const Duration(hours: 1)) : null,
      relayDown: relayDown,
    );
    _put(record);
    return record;
  }

  /// The other wallet answered the code or request [id] as [name], from [fromAddress]. A
  /// request answered from another key than it went to stores nothing ("This answer came from
  /// another wallet", [PairingFailure.otherWallet]). With status notices in [features] the
  /// inviter waits until heard (Waiting); without, it is paired at the reply. A request
  /// answered by the expected key is verified on completion, shown Waiting until heard.
  PairingRecord? answerInvite(String id, {String? name, String? fromAddress, PairingParty kind = PairingParty.person, PairingCaps? caps, int? features}) {
    final r = id == standing?.id ? standing! : _get(id);
    final who = name ?? r.label ?? autoAnswerName;
    final from = fromAddress ?? r.expectAddress ?? fakePairedAddress(r.id);
    if (r.expectAddress != null && !_sameKey(r.expectAddress, from)) {
      records.removeWhere((e) => e.id == id);
      emit(PairingEvent(PairingEventKind.failed, pairingId: id, name: who, failure: PairingFailure.otherWallet));
      return null;
    }
    final bits = features ?? peerFeatures;
    final waits = bits & featureStatusNotices != 0;
    final now = clock();
    final answered = r.copyWith(
      state: waits ? PairingState.waiting : PairingState.paired,
      name: who,
      kind: kind,
      caps: caps,
      sas: fakeSasWords(r.id),
      paymentsAddress: from,
      peerFeatures: bits,
      peerHeardAt: waits ? null : now,
      // Both addresses proven: verified once heard (D3).
      verifiedAt: r.expectAddress != null ? now : null,
    );
    if (id == standing?.id) {
      // The standing code was used: it becomes a row, and the next visit makes a fresh code.
      standing = null;
    }
    _put(answered.copyWith(state: !waits && r.expectAddress != null ? PairingState.verified : answered.state));
    emit(PairingEvent(PairingEventKind.replied, pairingId: id, name: answered.shownName));
    return _get(id);
  }

  /// The inviter confirmed the answer [id]: the answerer is paired (heard at the confirm), or
  /// verified when it answered a request (both addresses proven), with
  /// [PairingEventKind.confirmed].
  PairingRecord confirmAnswer(String id) {
    final r = _get(id);
    final now = clock();
    final request = r.expectAddress != null;
    final paired = r.copyWith(
      state: request ? PairingState.verified : PairingState.paired,
      verifiedAt: request ? now : null,
      sas: fakeSasWords(r.id),
      paymentsAddress: r.expectAddress ?? fakePairedAddress(r.id),
      peerHeardAt: now,
    );
    _put(paired);
    emit(PairingEvent(PairingEventKind.confirmed, pairingId: id, name: paired.shownName));
    return paired;
  }

  /// The other wallet was heard in the pairing [id] (its finished notice, a card, a slate):
  /// Waiting becomes Paired, or Verified for a request, with [PairingEventKind.heard].
  PairingRecord hear(String id) {
    final r = _get(id);
    if (r.state != PairingState.waiting) return r;
    final heard = r.copyWith(state: r.verifiedAt != null ? PairingState.verified : PairingState.paired, peerHeardAt: clock());
    _put(heard);
    emit(PairingEvent(PairingEventKind.heard, pairingId: id, name: _nameOf(heard)));
    return heard;
  }

  /// The other side pressed They match on [id] ("Anna confirmed too"). Counts as heard.
  PairingRecord peerMatch(String id) {
    hear(id);
    final r = _get(id).copyWith(peerVerifiedAt: clock());
    _put(r);
    emit(PairingEvent(PairingEventKind.peerVerified, pairingId: id, name: _nameOf(r)));
    return r;
  }

  /// The other side pressed They do not match on [id]: ended, kept, with
  /// [PairingEventKind.ended]. Nothing in its mailbox is finalized any more.
  PairingRecord peerMismatch(String id) => _end(id, PairingEndReason.peerMismatch);

  /// The other wallet was never heard within 7 days of collecting: ended as never finished.
  PairingRecord neverFinished(String id) => _end(id, PairingEndReason.neverFinished);

  PairingRecord _end(String id, PairingEndReason reason) {
    final r = _get(id);
    if (r.ended) return r;
    final ended = r.copyWith(state: PairingState.ended, endedReason: reason, endedAt: clock(), allowInvoices: false);
    _put(ended);
    _dropInvoicesOf(ended);
    emit(PairingEvent(PairingEventKind.ended, pairingId: id, name: _nameOf(ended), endedReason: reason));
    return ended;
  }

  /// The pending pairing [id] ended with [failure]: removed, with [PairingEventKind.failed].
  void failPending(String id, PairingFailure failure) {
    final r = _get(id);
    records.removeWhere((e) => e.id == id);
    emit(PairingEvent(PairingEventKind.failed, pairingId: id, name: r.shownName, failure: failure));
  }

  /// The other side removed the pairing [id] and said so (RFC 7.6): it stays, ended, with
  /// [PairingEventKind.unpaired] once, as LEPIC keeps it.
  void removedByPeer(String id) {
    final r = _get(id);
    if (r.ended) return;
    final marked = r.copyWith(state: PairingState.ended, endedReason: PairingEndReason.unpaired, endedAt: clock(), allowInvoices: false);
    _put(marked);
    _dropInvoicesOf(marked);
    emit(PairingEvent(PairingEventKind.unpaired, pairingId: id, name: _nameOf(marked)));
  }

  /// A request to pair came to this wallet's address from [from] (the sender's `key@relay`),
  /// claiming [name]. Stored and raised as [PairingEventKind.requested] unless its sender has
  /// a live pairing, or it is not newer than the one kept for that sender; a newer one
  /// replaces the older. Returns the stored request, or null when it was dropped.
  PairRequest? receiveRequest({required String from, required String name, Duration expiresIn = pairingInviteExpiry, PairingParty kind = PairingParty.person}) {
    if (recordFor(from) != null) return null;
    final now = clock();
    final expires = now.add(expiresIn);
    final older = requestList.where((q) => _sameKey(q.fromAddress, from)).firstOrNull;
    if (older != null && !expires.isAfter(older.expiresAt)) return null;
    requestList.removeWhere((q) => _sameKey(q.fromAddress, from));
    // 16 hex characters, as LEPIC's request ids (the invite id).
    final id = (++_seq).toRadixString(16).padLeft(16, '0');
    final request = PairRequest(
      id: id,
      fromAddress: from,
      claimedName: name,
      kind: kind,
      receivedAt: now,
      expiresAt: expires,
      inviteLink: fakePairingLink('pair', {'t': id, 'n': name, 'e': expires.millisecondsSinceEpoch, 'k': kind.name, 'i': false, 'r': homeRelay, 'from': from}),
    );
    requestList.add(request);
    if (requestList.length > 20) requestList.removeAt(0);
    emit(PairingEvent(PairingEventKind.requested, requestId: id, sender: from, name: name));
    return request;
  }

  /// The old records a keys-changed pairing would replace, by the new pairing's id: they stay
  /// as they were, out of the list, until the user decides (RFC 7.8 after the review).
  final Map<String, PairingRecord> _superseded = {};

  /// A re-pair with the contact of [oldId] found other keys (C-12): the new pairing is
  /// [PairingState.keysChanged] and takes the contact; the old record stays as it was, set
  /// aside until [resolveKeysChanged]. Returns the new pairing.
  PairingRecord changeKeys(String oldId) {
    final old = _get(oldId);
    final id = _id('pairing');
    final fresh = PairingRecord(
      id: id,
      state: PairingState.keysChanged,
      way: PairingWay.link,
      inviter: false,
      createdAt: clock(),
      name: old.name,
      kind: old.kind,
      caps: old.caps,
      sas: fakeSasWords('$id:new'),
      homeRelay: old.homeRelay,
      contactId: old.contactId,
      paymentsAddress: old.paymentsAddress,
      verifiedAt: old.verifiedAt,
      peerHeardAt: clock(),
      peerFeatures: old.peerFeatures,
    );
    records.removeWhere((r) => r.id == oldId);
    _superseded[id] = old;
    _put(fresh);
    emit(PairingEvent(PairingEventKind.keysChanged, pairingId: id, name: _nameOf(fresh)));
    return fresh;
  }

  /// A re-pair found the old keys of [id]: nothing changes but the notice.
  void restoreKeys(String id) {
    final r = _get(id);
    emit(PairingEvent(PairingEventKind.keysRestored, pairingId: id, name: _nameOf(r)));
  }

  /// The relay of [id] stops (or starts again) answering.
  void setRelayDown(String id, bool down) {
    final r = _get(id).copyWith(relayDown: down);
    _put(r);
    if (down) emit(PairingEvent(PairingEventKind.homeRelayUnreachable, pairingId: id, name: _nameOf(r)));
  }

  /// A second wallet answered the used code [inviteId], claiming [name].
  PairingStray secondAnswer(String inviteId, String name) {
    final stray = PairingStray(id: _id('stray'), inviteId: inviteId, name: name);
    strayList.add(stray);
    emit(PairingEvent(PairingEventKind.secondReply, pairingId: inviteId, name: _nameOf(_get(inviteId))));
    return stray;
  }

  /// A code of another wallet, as its link: [openInvite] reads it. [from] is the sender's
  /// address when the code travels as a request.
  String inviteLinkFrom({
    required String name,
    Duration expiresIn = const Duration(days: 6, hours: 23),
    PairingParty kind = PairingParty.person,
    bool asksInvoices = false,
    String? relay,
    String? from,
  }) {
    final token = _id('invite');
    return fakePairingLink('pair', {
      't': token,
      'n': name,
      'e': clock().add(expiresIn).millisecondsSinceEpoch,
      'k': kind.name,
      'i': asksInvoices,
      'r': relay ?? homeRelay,
      'from': ?from,
    });
  }

  /// The name the app shows for [r]: its contact's, else its own.
  String _nameOf(PairingRecord r) {
    final cid = r.contactId;
    final contact = cid == null ? null : session?.contactsValue.where((c) => c.id == cid).firstOrNull;
    return contact?.name ?? r.shownName;
  }

  /// Drops the open invoices from the contact of [r], as the core does when a pairing ends.
  void _dropInvoicesOf(PairingRecord r) {
    final s = session;
    if (s == null || r.paymentsAddress == null) return;
    final key = epicboxKey(r.paymentsAddress!);
    s.pendingInvoicesValue.removeWhere((_, i) => i.pairingId == r.id || epicboxKey(i.senderAddress) == key);
  }

  // PairingApi.

  @override
  bool get supported => enabled;

  @override
  Future<List<PairingRecord>> pairings() async {
    if (!enabled) return const [];
    final snapshot = [...records];
    if (listDelay case final delay?) await Future<void>.delayed(delay);
    return snapshot;
  }

  @override
  Future<PairingRecord?> pairing(String id) async {
    if (!enabled) return null;
    return records.where((r) => r.id == id).firstOrNull ?? (standing?.id == id ? standing : null);
  }

  @override
  Future<PairingRecord?> pairingForContact(String contactId) async {
    if (!enabled) return null;
    return contactPairingOf(records, contactId);
  }

  @override
  Future<List<PairingStray>> strays() async => enabled ? [...strayList] : const [];

  @override
  Future<void> removeStray(String id) async {
    _require('removeStray');
    strayList.removeWhere((s) => s.id == id);
  }

  String _checkName(String name) {
    final shown = name.trim();
    if (shown.isEmpty || utf8.encode(shown).length > 48) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the name must be 1 to 48 bytes');
    }
    return shown;
  }

  PairingRecord _newCode({required String name, String? expectAddress, String? label, String? contactId, PairingWay way = PairingWay.link}) {
    final id = _id('invite');
    final now = clock();
    final expires = now.add(pairingInviteExpiry);
    return PairingRecord(
      id: id,
      state: PairingState.pendingInvite,
      way: way,
      inviter: true,
      createdAt: now,
      label: label,
      homeRelay: homeRelay,
      contactId: contactId,
      expiresAt: expires,
      expectAddress: expectAddress,
      inviteLink: fakePairingLink('pair', {'t': id, 'n': name, 'e': expires.millisecondsSinceEpoch, 'k': 'person', 'i': false, 'r': homeRelay, 'from': ownAddress}),
    );
  }

  /// The name the standing code carries.
  String? standingName;

  @override
  Future<PairingRecord> standingCode({required String name}) async {
    _require('standingCode');
    final shown = _checkName(name);
    final now = clock();
    final old = standing;
    final stale = old == null ||
        old.expiresAt == null ||
        old.expiresAt!.difference(now) < pairingInviteRenewBefore ||
        old.homeRelay != homeRelay ||
        standingName != shown;
    if (!stale) return old;
    // A new name withdraws the old code; the rest leave it valid, no longer standing.
    if (old != null && standingName != shown) _cancelled.add(old.id);
    calls.add('standing');
    standing = _newCode(name: shown);
    standingName = shown;
    return standing!;
  }

  @override
  Future<int> setOwnName(String name) async {
    _require('setOwnName');
    _checkName(name);
    calls.add('ownName');
    return records.where((r) => r.state.isPaired || r.state == PairingState.waiting).length;
  }

  /// The requests this wallet sent, in order, as (to, name).
  final List<({String to, String name})> sentRequests = [];

  @override
  Future<PairingRecord> requestPairing({required String toAddress, required String name, String? contactId}) async {
    _require('requestPairing');
    final shown = _checkName(name);
    if (parseRecipient(toAddress).kind != RecipientKind.epicbox) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'not an Epicbox address');
    }
    if (epicboxOff) throw pairingError(PairingFailure.relayUnreachable);
    final key = epicboxKey(toAddress);
    if (!provenPeers.any((p) => epicboxKey(p) == key)) throw pairingError(PairingFailure.peerNotProven);
    if (recordFor(toAddress) != null) throw pairingError(PairingFailure.alreadyUsed);
    if (inProgressWith(toAddress) != null || requestList.any((q) => _sameKey(q.fromAddress, toAddress))) {
      throw pairingError(PairingFailure.inProgress);
    }
    if (relayUnreachable) throw const WalletError(kind: WalletErrorKind.transportFailed, message: 'the request could not be posted');
    calls.add('request');
    sentRequests.add((to: toAddress, name: shown));
    final label = contactId == null ? null : session?.contactsValue.where((c) => c.id == contactId).firstOrNull?.name;
    final record = _newCode(name: shown, expectAddress: toAddress, label: label, contactId: contactId, way: PairingWay.request);
    _put(record);
    _later(() {
      if (!records.any((r) => r.id == record.id && r.state == PairingState.pendingInvite)) return;
      answerInvite(record.id);
      _later(() => hear(record.id));
    });
    return record;
  }

  /// Codes cancelled and kept hidden until they expire: a late answer is refused.
  final Set<String> _cancelled = {};

  @override
  Future<void> cancelInvite(String id) async {
    _require('cancelInvite');
    calls.add('cancelInvite');
    // LEPIC's pairing_cancel: a code stops working (its row hides, a late reply is refused), an
    // answer waiting for its confirm goes.
    if (records.any((r) => r.id == id && r.state == PairingState.pendingInvite)) _cancelled.add(id);
    records.removeWhere((r) => r.id == id && r.state.isPending);
    if (standing?.id == id) {
      _cancelled.add(id);
      standing = null;
    }
  }

  @override
  Future<PairingRecord> openReply(String link) async {
    _require('openReply');
    final body = _readLink(link, 'pair-reply');
    if (body == null) throw pairingError(PairingFailure.invalid);
    final id = body['t'] as String?;
    final invite = records.where((r) => r.id == id).firstOrNull ?? (standing?.id == id ? standing : null);
    if (invite == null) throw pairingError(_cancelled.contains(id) ? PairingFailure.cancelled : PairingFailure.notFound);
    // The same reply again (it came through the relay first): LEPIC answers it with the same
    // finish link and changes nothing.
    if (invite.state.isRecord && invite.inviter) return invite;
    if (invite.state != PairingState.pendingInvite) throw pairingError(PairingFailure.alreadyUsed);
    calls.add('openReply');
    _repliedByHand.add(invite.id);
    final answered = answerInvite(invite.id, name: body['n'] as String?, fromAddress: body['from'] as String?);
    if (answered == null) throw pairingError(PairingFailure.otherWallet);
    return answered;
  }

  @override
  Future<String> confirmLink(String id) async {
    _require('confirmLink');
    final r = _get(id);
    // A reply that came through the relay was confirmed through it too: no finish code to
    // send, unless the confirm could not be posted.
    if (!_repliedByHand.contains(id) && !relayUnreachable && !epicboxOff) throw pairingError(PairingFailure.notFound);
    return fakePairingLink('pair-confirm', {'t': r.id, 'n': r.shownName});
  }

  @override
  Future<PairingInvitePreview> openInvite(String link) async {
    _require('openInvite');
    final failure = nextOpenFailure;
    if (failure != null) {
      nextOpenFailure = null;
      throw pairingError(failure);
    }
    final body = _readLink(link, 'pair');
    // A private invite (a device link) is not a contact invite.
    if (body == null || body['class'] == 'private') throw pairingError(PairingFailure.invalid);
    final token = body['t'] as String? ?? _id('invite');
    if (records.any((r) => r.id == token) || standing?.id == token || _cancelled.contains(token)) throw pairingError(PairingFailure.ownCard);
    final expires = DateTime.fromMillisecondsSinceEpoch((body['e'] as num?)?.toInt() ?? 0);
    if (!clock().isBefore(expires)) throw pairingError(PairingFailure.expired);
    // A copy of a stored request (forwarded by the linked device, or opened from its row).
    final stored = requestList.where((q) => q.id == token).firstOrNull;
    final preview = PairingInvitePreview(
      token: token,
      name: body['n'] as String? ?? '',
      expiresAt: expires,
      kind: PairingParty.values.asNameMap()[body['k']] ?? PairingParty.person,
      asksInvoices: body['i'] == true,
      homeRelay: body['r'] as String? ?? homeRelay,
      wordsAvailable: !relayUnreachable,
      fromAddress: stored?.fromAddress ?? body['from'] as String?,
      requestId: stored?.id,
    );
    _previews[token] = preview;
    return preview;
  }

  @override
  Future<List<PairRequest>> requests() async {
    if (!enabled) return const [];
    final now = clock();
    requestList.removeWhere((q) => q.expiredAt(now));
    return [for (final q in requestList) if (!dismissedRequests.contains(q.id) && !answeredRequests.contains(q.id)) q];
  }

  @override
  Future<PairingInvitePreview> openRequest(String requestId) async {
    _require('openRequest');
    final q = requestList.where((r) => r.id == requestId).firstOrNull;
    if (q == null) throw pairingError(PairingFailure.notFound);
    return openInvite(q.inviteLink);
  }

  @override
  Future<void> dismissRequest(String requestId) async {
    _require('dismissRequest');
    if (!requestList.any((q) => q.id == requestId)) throw pairingError(PairingFailure.notFound);
    calls.add('dismiss');
    dismissedRequests.add(requestId);
  }

  @override
  Future<void> requestHandledOn(String requestId, String device) async {
    _require('requestHandledOn');
    final q = requestList.where((r) => r.id == requestId).firstOrNull;
    if (q == null) throw pairingError(PairingFailure.notFound);
    calls.add('handledOn');
    dismissedRequests.add(requestId);
    emit(PairingEvent(PairingEventKind.pairedElsewhere, requestId: requestId, name: device, sender: q.fromAddress));
  }

  @override
  Future<void> takeForwardedRequest(PairRequest request) async {
    _require('takeForwardedRequest');
    if (request.expiredAt(clock()) || requestList.any((q) => q.id == request.id)) return;
    calls.add('forwardedRequest');
    requestList.add(request);
    emit(PairingEvent(PairingEventKind.requested, requestId: request.id, sender: request.fromAddress, name: request.claimedName));
  }

  @override
  Future<PairingRecord> acceptInvite({
    required String token,
    required String name,
    bool allowInvoices = false,
    String? contactId,
    bool byHand = false,
  }) async {
    _require('acceptInvite');
    final preview = _previews[token];
    if (preview == null) throw pairingError(PairingFailure.invalid);
    if (!clock().isBefore(preview.expiresAt)) throw pairingError(PairingFailure.expired);
    if (dismissedRequests.contains(token)) throw pairingError(PairingFailure.inviteDismissed);
    final from = preview.fromAddress;
    if (from != null) {
      if (recordFor(from) != null) throw pairingError(PairingFailure.alreadyUsed);
      // Crossed codes (M7): the pairing made by the lower key survives.
      final own = inProgressWith(from);
      if (own != null && own.id != token) {
        if (ownKey.compareTo(epicboxKey(from)) < 0) throw pairingError(PairingFailure.crossed);
        records.removeWhere((r) => r.id == own.id);
        _cancelled.add(own.id);
        emit(PairingEvent(PairingEventKind.failed, pairingId: own.id, name: own.shownName, failure: PairingFailure.crossed));
      }
    }
    calls.add('accept');
    _previews.remove(token);
    if (preview.requestId != null) {
      answeredRequests.add(preview.requestId!);
      emit(PairingEvent(PairingEventKind.requestAnswered, requestId: preview.requestId));
    }
    final now = clock();
    final record = PairingRecord(
      id: _id('pairing'),
      state: PairingState.pendingReply,
      way: preview.isRequest ? PairingWay.request : PairingWay.link,
      inviter: false,
      createdAt: now,
      name: preview.name,
      kind: preview.kind,
      caps: PairingCaps(issuesInvoices: preview.asksInvoices || preview.kind != PairingParty.person, sendsWithdrawals: preview.kind == PairingParty.exchange),
      asksInvoices: preview.asksInvoices && allowInvoices,
      homeRelay: preview.homeRelay,
      contactId: contactId,
      expiresAt: now.add(pairingReplyWait),
      expectAddress: from,
      // The answer could not be posted: it waits to be sent by hand.
      relayDown: !byHand && relayUnreachable,
    );
    _put(record);
    if (!byHand && !relayUnreachable) {
      _later(() {
        if (records.any((r) => r.id == record.id && r.state == PairingState.pendingReply)) confirmAnswer(record.id);
      });
    }
    return record;
  }

  @override
  Future<String> replyLink(String id) async {
    _require('replyLink');
    final r = _get(id);
    return fakePairingLink('pair-reply', {'t': r.id, 'n': session == null ? 'Alex' : r.shownName, 'from': ownAddress});
  }

  @override
  Future<PairingRecord> openConfirm(String link) async {
    _require('openConfirm');
    final body = _readLink(link, 'pair-confirm');
    if (body == null) throw pairingError(PairingFailure.invalid);
    final waiting = records.where((r) => r.state == PairingState.pendingReply).toList();
    final match = waiting.where((r) => r.id == body['t']).firstOrNull ?? waiting.firstOrNull;
    if (match == null) throw pairingError(PairingFailure.notFound);
    calls.add('openConfirm');
    return confirmAnswer(match.id);
  }

  @override
  Future<PairingRecord?> checkWords(String id, PairingCheck check) async {
    _require('checkWords');
    calls.add('check:${check.name}');
    if (_privateIndex(id) >= 0) return _checkPrivate(id, check);
    final r = _get(id);
    if (r.ended) throw pairingError(PairingFailure.ended);
    switch (check) {
      case PairingCheck.match:
        // They match counts as heard (H3), and makes it verified.
        final verified = r.copyWith(
          state: PairingState.verified,
          verifiedAt: clock(),
          peerHeardAt: r.peerHeardAt ?? clock(),
          allowInvoices: r.asksInvoices || r.allowInvoices,
        );
        _put(verified);
        return verified;
      case PairingCheck.mismatch:
        // Ended, not deleted: the verdict goes to the other side, and a sealed send waiting in
        // this mailbox is never finalized (its row offers Cancel).
        final ended = r.copyWith(state: PairingState.ended, endedReason: PairingEndReason.mismatch, endedAt: clock(), allowInvoices: false);
        _put(ended);
        _dropInvoicesOf(ended);
        return ended;
      case PairingCheck.skip:
        return r;
    }
  }

  @override
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground}) async {
    collects.add(trigger);
    if (!enabled) return 0;
    final now = clock();
    var taken = 0;
    // An answer whose confirm never came in the invite's window ends as not completed (C-16);
    // an expired request stays listed ("No answer from Anna's wallet"), until it is removed.
    for (final r in [...records]) {
      if (r.state == PairingState.pendingReply && r.expiredAt(now)) {
        failPending(r.id, PairingFailure.notCompleted);
        taken++;
      }
    }
    requestList.removeWhere((q) => q.expiredAt(now));
    return taken;
  }

  @override
  Future<void> removePairing(String id) async {
    _require('removePairing');
    calls.add('remove');
    if (_privateIndex(id) >= 0) return _removePrivate(id);
    records.removeWhere((r) => r.id == id);
  }

  @override
  Future<PairingRecord> setSeal(String id, bool on) async {
    _require('setSeal');
    final r = _get(id);
    if (r.ended) throw pairingError(PairingFailure.ended);
    if (r.paused) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'keys changed: check the words first');
    final next = r.copyWith(seal: on ? SealMode.on : SealMode.off);
    _put(next);
    return next;
  }

  @override
  Future<int> setAllowInvoices(String id, bool on) async {
    _require('setAllowInvoices');
    final r = _get(id);
    if (r.ended) throw pairingError(PairingFailure.ended);
    if (on && r.state == PairingState.waiting) throw pairingError(PairingFailure.waiting);
    if (on && !r.canAllowInvoices) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'check the words first');
    }
    calls.add('allowInvoices:$on');
    _put(r.copyWith(allowInvoices: on));
    if (on) return 0;
    // Off declines the contact's open requests at once (RFC 11.1).
    final s = session;
    if (s == null || r.paymentsAddress == null) return 0;
    final key = epicboxKey(r.paymentsAddress!);
    final open = [
      for (final i in s.pendingInvoicesValue.values)
        if (i.pairingId == id || epicboxKey(i.senderAddress) == key) i.slateId,
    ];
    for (final slateId in open) {
      s.pendingInvoicesValue.remove(slateId);
      s.declinedInvoices.add(slateId);
    }
    return open.length;
  }

  @override
  Future<PairingRecord> attach(String id, String? contactId, {String? contactAddress}) async {
    _require('attach');
    calls.add('attach');
    final fresh = _get(id);
    // The contact's Epicbox address decides first: a proven address of another key refuses,
    // and a contact with an address needs a proof to attach to.
    if (contactId != null && contactAddress != null && contactAddress.trim().isNotEmpty) {
      final proven = fresh.paymentsAddress;
      if (proven == null) throw pairingError(PairingFailure.addressProofMissing);
      if (!_sameKey(proven, contactAddress)) throw pairingError(PairingFailure.otherAddress);
    }
    final old = contactId == null ? null : records.where((r) => r.contactId == contactId && r.id != id).firstOrNull;
    if (old != null && old.state.isPaired) {
      // A new pairing for a contact that has one runs the key check (RFC 7.8).
      if (keyCheckFindsOldKeys) {
        records.removeWhere((r) => r.id == id);
        emit(PairingEvent(PairingEventKind.keysRestored, pairingId: old.id, name: _nameOf(old)));
        return old;
      }
      records.removeWhere((r) => r.id == old.id);
      _superseded[id] = old;
      final changed = fresh.copyWith(state: PairingState.keysChanged, contactId: contactId);
      _put(changed);
      emit(PairingEvent(PairingEventKind.keysChanged, pairingId: id, name: _nameOf(changed)));
      return changed;
    }
    final r = fresh.copyWith(contactId: contactId, clearContact: contactId == null);
    _put(r);
    return r;
  }

  @override
  Future<PairingRecord> resolveKeysChanged(String id, KeysChoice choice) async {
    _require('resolveKeysChanged');
    if (_get(id).state != PairingState.keysChanged) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the keys of this pairing did not change');
    }
    calls.add('keys:${choice.name}');
    final r = _get(id);
    final previous = _superseded.remove(id);
    switch (choice) {
      case KeysChoice.keepOld:
        // The old keys come back as they were; the new pairing goes.
        records.removeWhere((e) => e.id == id);
        final back = previous ?? r.copyWith(state: PairingState.verified, verifiedAt: r.verifiedAt ?? clock());
        _put(back);
        return back;
      case KeysChoice.useNew:
        // The new keys stay, paired and to be checked; the old record goes.
        final next = r.copyWith(state: PairingState.paired, clearVerified: true, clearPeerVerified: true, allowInvoices: false);
        _put(next);
        return next;
    }
  }

  void _needsLive(PairingRecord r) {
    if (r.ended) throw pairingError(PairingFailure.ended);
    if (r.state == PairingState.waiting) throw pairingError(PairingFailure.waiting);
  }

  @override
  Future<IssuedInvoice> requestPayment({required String id, required BigInt amount, String? message}) async {
    _require('requestPayment');
    final r = _get(id);
    _needsLive(r);
    if (r.state != PairingState.verified || !r.caps.paysInvoices) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the contact cannot be sent requests');
    }
    final s = session;
    if (s == null) throw pairingUnsupported('requestPayment');
    calls.add('request');
    return s.issueToContact(amount: amount, address: r.paymentsAddress!, message: message);
  }

  @override
  Future<Slate> requestFile({required BigInt amount, String? message}) async {
    _require('requestFile');
    final s = session;
    if (s == null) throw pairingUnsupported('requestFile');
    if (amount <= BigInt.zero) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the amount must be above zero');
    }
    calls.add('requestFile');
    final issued = await s.issueRequestFile(amount: amount, message: message);
    final json = jsonEncode({'fake_invoice': issued.slateId, 'amount': '$amount', 'message': ?message});
    // Read back as a request, the way LEPIC's inspect reads an I1.
    s.node?.slateInfos[json] = SlateInfo(
      slateId: issued.slateId,
      amount: amount,
      fee: BigInt.zero,
      stage: SlateStage.request,
      messages: [if (issued.message case final m?) SlateMessage(role: SlateRole.receiver, text: m)],
    );
    return Slate(slateId: issued.slateId, json: json);
  }

  static const _armorHead = 'BEGINEPICSEALED. ';
  static const _armorFoot = '. ENDEPICSEALED.';

  @override
  Future<String> sealSlate({required String id, required String slateJson}) async {
    _require('sealSlate');
    final r = _get(id);
    _needsLive(r);
    if (!r.seals) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'not sealing for this contact');
    final body = base64Url.encode(utf8.encode(jsonEncode({'p': id, 's': slateJson})));
    // Kept by the transaction, as the engine keeps a sealed send, for [plainSlate].
    try {
      final slateId = (jsonDecode(slateJson) as Map<String, Object?>)['id'];
      if (slateId is String) sealedSends['s:$slateId'] = (id: id, slateJson: slateJson);
    } on Object {
      // Not a slate the fake can read: sealed all the same.
    }
    calls.add('seal');
    return '$_armorHead$body$_armorFoot';
  }

  @override
  Future<OpenedSlate> openSlate(String text) async {
    final t = text.trim();
    if (!t.startsWith('BEGINEPICSEALED')) {
      // A plain file from a paired contact's address says who sent it ([plainFrom]).
      return OpenedSlate(slateJson: text, pairingId: plainFrom[t]);
    }
    if (!t.startsWith(_armorHead) || !t.endsWith(_armorFoot)) throw pairingError(PairingFailure.newerVersion);
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(base64Url.decode(t.substring(_armorHead.length, t.length - _armorFoot.length))));
    } on FormatException {
      throw pairingError(PairingFailure.invalid);
    }
    if (body is! Map<String, Object?>) throw pairingError(PairingFailure.invalid);
    final id = body['p'] as String?;
    if (id == null || !records.any((r) => r.id == id)) throw pairingError(PairingFailure.sealedForOther);
    final r = _get(id);
    if (r.seal == SealMode.degraded) _put(r.copyWith(seal: SealMode.on));
    _put(_get(id).copyWith(lastSealedIn: clock()));
    // A sealed slate is the other wallet, heard.
    hear(id);
    final json = body['s'] as String? ?? '';
    // As LEPIC: what the slate holds, not the slate.
    if (!handsOutSealedSlate) {
      final info = session?.node?.slateInfos[json];
      return OpenedSlate(
        pairingId: id,
        sealed: true,
        stage: info?.stage,
        slateId: info?.slateId,
        amount: info?.amount,
        fee: info?.fee,
        messages: info?.messages ?? const [],
      );
    }
    return OpenedSlate(slateJson: json, pairingId: id, sealed: true);
  }

  /// [openSlate] hands out the slate inside sealed text, as LEPIC does not: false reads it
  /// as LEPIC does.
  bool handsOutSealedSlate = true;

  @override
  Future<TxEntry> sendViaMailbox({
    required String id,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) async {
    _require('sendViaMailbox');
    final r = _get(id);
    _needsLive(r);
    final s = session;
    // As LEPIC: the paired state and the card's "opens sealed", not the seal switch. A contact
    // with no address takes it too.
    if (s == null || !r.paysByMailbox) throw pairingUnsupported('sendViaMailbox');
    calls.add('sendViaMailbox');
    // The post failed: LEPIC cancels the payment it made, so nothing is left holding coins.
    if (s.sendError case final error?) throw error;
    final tx = await s.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: r.paymentsAddress ?? '',
      message: message,
      options: options,
    );
    if (tx.slateId case final slateId?) slates[slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.payment);
    // The row carries its pairing, as LEPIC's does, and waits for the recipient in the list.
    final marked = tx.withPairing(id);
    final i = s.transactionsValue.indexWhere((t) => t.key == tx.key);
    if (i >= 0) {
      s.transactionsValue[i] = marked;
    } else {
      s.transactionsValue.add(marked);
    }
    return marked;
  }

  /// Every [collect], by its trigger.
  final List<PairingCollectTrigger> collects = [];

  /// The pairing and slate inside sealed [text], as [openSlate] reads it.
  ({String id, String slateJson}) _inside(String text) {
    final t = text.trim();
    if (!t.startsWith(_armorHead) || !t.endsWith(_armorFoot)) throw pairingError(PairingFailure.newerVersion);
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(base64Url.decode(t.substring(_armorHead.length, t.length - _armorFoot.length))));
    } on FormatException {
      throw pairingError(PairingFailure.invalid);
    }
    if (body is! Map<String, Object?>) throw pairingError(PairingFailure.invalid);
    final id = body['p'] as String?;
    if (id == null || !records.any((r) => r.id == id)) throw pairingError(PairingFailure.sealedForOther);
    return (id: id, slateJson: body['s'] as String? ?? '');
  }

  @override
  Future<SealedReply> receiveSealed(String text, {String? message}) async {
    _require('receiveSealed');
    final inside = _inside(text);
    final s = session;
    if (s == null) throw pairingUnsupported('receiveSealed');
    final answer = await s.receiveSlate(slateJson: inside.slateJson);
    final r = _get(inside.id);
    final sealed = r.seals ? await sealSlate(id: inside.id, slateJson: answer.json) : null;
    return SealedReply(slateId: answer.slateId, answer: sealed ?? answer.json, sealed: sealed != null, repeated: answer.repeated);
  }

  @override
  Future<TxEntry> finalizeSealed(String text) async {
    _require('finalizeSealed');
    final inside = _inside(text);
    final s = session;
    if (s == null) throw pairingUnsupported('finalizeSealed');
    // A mailbox that ended by mismatch finalizes nothing (the send stays cancellable).
    final r = _get(inside.id);
    if (r.endedReason == PairingEndReason.mismatch || r.endedReason == PairingEndReason.peerMismatch) throw pairingError(PairingFailure.ended);
    return s.finalizeAndPost(slateJson: inside.slateJson);
  }

  @override
  Future<PaidSealedRequest> paySealedRequest(String text, {required BigInt amount}) async {
    _require('paySealedRequest');
    final inside = _inside(text);
    final s = session;
    if (s == null) throw pairingUnsupported('paySealedRequest');
    calls.add('paySealedRequest');
    final paid = await s.payRequestFile(slateJson: inside.slateJson, amount: amount);
    final sealed = _get(inside.id).seals ? await sealSlate(id: inside.id, slateJson: paid.json) : null;
    if (sealed == null) return PaidSealedRequest(paid: paid, sealed: false);
    return PaidSealedRequest(
      paid: PaidRequestFile(txId: paid.txId, slateId: paid.slateId, amount: paid.amount, fee: paid.fee, json: sealed),
      sealed: true,
    );
  }

  /// Plain slates a paired contact sent, by their text: [openSlate] names the pairing, as the
  /// engine does from the slate's payment proof.
  final Map<String, String> plainFrom = {};

  /// The sealed sends by transaction key, with their slate and pairing, for [plainSlate].
  final Map<String, ({String id, String slateJson})> sealedSends = {};

  @override
  Future<String> plainSlate(String txKey) async {
    _require('plainSlate');
    final sent = sealedSends[txKey];
    if (sent == null) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'not a sealed send');
    calls.add('plain');
    final r = records.where((e) => e.id == sent.id).firstOrNull;
    if (r != null) _put(r.copyWith(seal: SealMode.degraded));
    return sent.slateJson;
  }

  /// Pairings an import brought in as used on another device.
  int importedOtherDevice = 0;

  /// What each slate a pairing took part in was for, by slate id ([slateOf]).
  final Map<String, PairingSlate> slates = {};

  @override
  Future<PairingSlate?> slateOf(String slateId) async => enabled ? slates[slateId] : null;

  /// The exchange of [id] sent a withdrawal of [amount] (RFC 12.5): the wallet signed and
  /// answered it on its own, and it waits for the exchange to post. Raises
  /// [PairingEventKind.withdrawalFromContact]. Returns the slate id.
  String withdrawalFrom(String id, BigInt amount, {String? reference}) {
    final r = _get(id);
    final s = session;
    final slateId = _id('withdrawal');
    s?.transactionsValue.add(
      fakeTx(
        id: 700 + slates.length,
        slateId: slateId,
        kind: TxKind.received,
        // Signed and answered here; the exchange finalizes and posts. Not on the chain yet,
        // so it can be cancelled, as LEPIC's received transaction can.
        status: TxStatus.awaitingConfirmation,
        cancellable: true,
        createdAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
        amountCredited: amount,
        counterparty: r.paymentsAddress,
      ),
    );
    slates[slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.withdrawal, reference: reference);
    emit(PairingEvent(PairingEventKind.withdrawalFromContact, pairingId: id, name: _nameOf(r), slateId: slateId, amount: amount));
    return slateId;
  }

  @override
  Future<int> useImportedPairings() async {
    if (!enabled) return 0;
    calls.add('useImported');
    var n = 0;
    for (final r in [...records]) {
      if (r.otherDevice) {
        _put(r.copyWith(otherDevice: false));
        n++;
      }
    }
    importedOtherDevice = 0;
    return n;
  }

  /// The backup object an export carries (RFC 10.5): the paired records, nothing secret.
  /// Never a pending, waiting or ended one.
  Map<String, Object?>? exportBackup() {
    final paired = [for (final r in records) if (r.state.isPaired) r];
    if (!enabled || paired.isEmpty) return null;
    return {
      'version': 1,
      'records': [
        for (final r in paired)
          {
            'id': r.id,
            'name': r.name,
            'state': r.state.name,
            'kind': r.kind.name,
            'relay': r.homeRelay,
            'payments': r.paymentsAddress,
            'verified_at': r.verifiedAt?.millisecondsSinceEpoch,
            'contact_id': r.contactId,
            'peer_features': r.peerFeatures,
            'peer_heard_at': r.peerHeardAt?.millisecondsSinceEpoch,
            'peer_verified_at': r.peerVerifiedAt?.millisecondsSinceEpoch,
          },
      ],
    };
  }

  /// Takes [backup] in; with [otherDevice] the records wait for [useImportedPairings].
  /// Returns how many records came in. An entry without the new fields counts as heard when
  /// it was made, with no features.
  int importBackup(Map<String, Object?>? backup, {bool otherDevice = true}) {
    if (!enabled || backup == null) return 0;
    var n = 0;
    for (final raw in (backup['records'] as List?) ?? const []) {
      final m = raw as Map<String, Object?>;
      final id = m['id'] as String;
      if (records.any((r) => r.id == id)) continue;
      DateTime? at(String key) => switch (m[key]) { final int ms => DateTime.fromMillisecondsSinceEpoch(ms), _ => null };
      final created = clock();
      _put(
        PairingRecord(
          id: id,
          state: PairingState.values.asNameMap()[m['state']] ?? PairingState.paired,
          way: PairingWay.link,
          inviter: false,
          createdAt: created,
          name: m['name'] as String?,
          kind: PairingParty.values.asNameMap()[m['kind']] ?? PairingParty.person,
          sas: fakeSasWords(id),
          verifiedAt: at('verified_at'),
          homeRelay: m['relay'] as String? ?? homeRelay,
          paymentsAddress: m['payments'] as String?,
          contactId: m['contact_id'] as String?,
          peerFeatures: m['peer_features'] as int? ?? 0,
          peerHeardAt: at('peer_heard_at') ?? created,
          peerVerifiedAt: at('peer_verified_at'),
          otherDevice: otherDevice,
        ),
      );
      n++;
    }
    if (otherDevice) importedOtherDevice += n;
    return n;
  }

  @override
  Stream<PairingEvent> events() => _events.stream;

  // Private pairings (linked devices). Two fakes that share one [privateNet] reach each other:
  // an invite one makes, the other accepts; answers, confirms, payloads and removals wait in
  // the receiving fake's inbox until it collects, as on a relay. They refuse what LEPIC's
  // private class refuses: words, contact calls, payloads on a contact pairing.

  /// The relay the private pairings go through. Give two fakes the same one to link them.
  FakePrivateNet privateNet = FakePrivateNet();

  /// The private pairings, apart from [records] as LEPIC keeps them.
  final List<PairingRecord> privateRecords = [];

  /// For each private pairing, the fake and the record on the other end.
  final Map<String, ({FakePairing fake, String id})> _peers = {};
  final List<_PrivateMail> _inbox = [];
  final List<_PrivateMail> _outbox = [];
  final List<PairingPayload> _payloads = [];

  /// The server of each answered private pairing, named on its record once it is made.
  final Map<String, String> _answeredOn = {};

  /// Every payload posted, in order: (pairing id, bytes). Tests read it.
  final List<({String id, List<int> bytes})> posted = [];

  int _privateIndex(String id) => privateRecords.indexWhere((r) => r.id == id);

  PairingRecord _private(String id) {
    final i = _privateIndex(id);
    if (i < 0) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'no private pairing with that id');
    return privateRecords[i];
  }

  void _putPrivate(PairingRecord r) {
    final i = _privateIndex(r.id);
    if (i >= 0) {
      privateRecords[i] = r;
    } else {
      privateRecords.insert(0, r);
    }
  }

  void _deliver(FakePairing to, _PrivateMail mail) {
    if (relayUnreachable) {
      _outbox.add(mail.._to = to);
    } else {
      to._inbox.add(mail);
    }
  }

  @override
  bool get privateSupported => enabled;

  @override
  Future<List<PairingRecord>> privatePairings() async => enabled ? [...privateRecords] : const [];

  @override
  Future<PairingRecord> makePrivateInvite({required String name, required String homeRelay, Duration expiry = privateInviteExpiry}) async {
    _require('makePrivateInvite');
    calls.add('makePrivateInvite');
    final id = _id('device');
    final token = privateNet._next('t');
    final expires = clock().add(expiry);
    final link = fakePairingLink('pair', {'t': token, 'n': name, 'r': homeRelay, 'e': expires.millisecondsSinceEpoch, 'class': 'private'});
    privateNet._invites[token] = (fake: this, id: id);
    final record = PairingRecord(
      id: id,
      state: PairingState.pendingInvite,
      way: PairingWay.link,
      inviter: true,
      createdAt: clock(),
      homeRelay: homeRelay,
      expiresAt: expires,
      inviteLink: link,
    );
    _putPrivate(record);
    return record;
  }

  @override
  Future<PairingRecord> acceptPrivateInvite({required String link, required String name}) async {
    _require('acceptPrivateInvite');
    calls.add('acceptPrivateInvite');
    final body = _readLink(link, 'pair');
    if (body == null || body['class'] != 'private') throw pairingError(PairingFailure.invalid);
    final token = body['t'] as String? ?? '';
    final invite = privateNet._invites[token];
    if (invite == null) throw pairingError(PairingFailure.notFound);
    if (identical(invite.fake, this)) throw pairingError(PairingFailure.ownCard);
    if (privateNet._used.contains(token)) throw pairingError(PairingFailure.alreadyUsed);
    final expires = DateTime.fromMillisecondsSinceEpoch((body['e'] as num?)?.toInt() ?? 0);
    if (!clock().isBefore(expires)) throw pairingError(PairingFailure.expired);
    privateNet._used.add(token);
    final id = _id('device');
    final record = PairingRecord(
      id: id,
      state: PairingState.pendingReply,
      way: PairingWay.link,
      inviter: false,
      createdAt: clock(),
      name: body['n'] as String?,
      // As LEPIC: the answered pairing names its server only once it is made, with the port.
      homeRelay: '',
      expiresAt: clock().add(pairingReplyWait),
    );
    _answeredOn[id] = '${body['r'] as String? ?? homeRelay}:443';
    _putPrivate(record);
    _deliver(invite.fake, _PrivateMail.answer(to: invite.id, from: this, fromId: id, name: name, token: token));
    return record;
  }

  @override
  Future<int> collectPrivate({List<String>? only}) async {
    if (!enabled) return 0;
    calls.add('collectPrivate');
    if (!relayUnreachable) {
      for (final m in _outbox) {
        m._to!._inbox.add(m);
      }
      _outbox.clear();
    } else {
      return 0;
    }
    var taken = 0;
    for (final m in [..._inbox]) {
      if (only != null && !only.contains(m.to)) continue;
      _inbox.remove(m);
      final i = _privateIndex(m.to);
      if (i < 0) continue;
      final r = privateRecords[i];
      switch (m.kind) {
        case _MailKind.answer:
          if (r.state != PairingState.pendingInvite) continue;
          _peers[r.id] = (fake: m.from!, id: m.fromId!);
          _putPrivate(r.copyWith(state: PairingState.paired, name: m.name, sas: fakeSasWords('private:${m.token}')));
          _deliver(m.from!, _PrivateMail.confirm(to: m.fromId!, from: this, fromId: r.id, token: m.token!));
          taken++;
        case _MailKind.confirm:
          if (r.state != PairingState.pendingReply) continue;
          _peers[r.id] = (fake: m.from!, id: m.fromId!);
          _putPrivate(r.copyWith(state: PairingState.paired, sas: fakeSasWords('private:${m.token}'), homeRelay: _answeredOn.remove(r.id)));
          taken++;
        case _MailKind.payload:
          if (!r.state.isPaired) continue;
          _payloads.add(PairingPayload(id: privateNet._next('payload'), pairingId: r.id, bytes: m.bytes!, receivedAt: clock()));
        case _MailKind.unpaired:
          _putPrivate(r.copyWith(state: PairingState.ended, endedReason: PairingEndReason.unpaired, endedAt: clock()));
          taken++;
      }
    }
    return taken;
  }

  @override
  Future<void> postPayload({required String id, required List<int> bytes}) async {
    _require('postPayload');
    // A contact pairing never carries a payload.
    final r = _private(id);
    if (!r.state.isPaired) throw pairingError(PairingFailure.invalid);
    // As LEPIC: only once this side confirmed the words.
    if (r.state != PairingState.verified) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the words of this pairing are not confirmed');
    }
    if (bytes.length > privatePayloadMaxBytes) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'payload too large');
    }
    posted.add((id: id, bytes: List.unmodifiable(bytes)));
    final peer = _peers[id];
    if (peer == null) return;
    _deliver(peer.fake, _PrivateMail.payload(to: peer.id, bytes: List.unmodifiable(bytes)));
  }

  @override
  Future<List<PairingPayload>> payloads() async => enabled ? [..._payloads] : const [];

  @override
  Future<void> ackPayloads(List<String> ids) async {
    _payloads.removeWhere((p) => ids.contains(p.id));
  }

  PairingRecord? _checkPrivate(String id, PairingCheck check) {
    final r = _private(id);
    if (!r.state.isPaired) throw pairingError(PairingFailure.invalid);
    switch (check) {
      case PairingCheck.match:
        final verified = r.copyWith(state: PairingState.verified, verifiedAt: clock());
        _putPrivate(verified);
        return verified;
      case PairingCheck.mismatch:
        privateRecords.removeAt(_privateIndex(id));
        _peers.remove(id);
        return null;
      // A private pairing has no "check later".
      case PairingCheck.skip:
        throw pairingError(PairingFailure.invalid);
    }
  }

  void _removePrivate(String id) {
    privateRecords.removeAt(_privateIndex(id));
    final peer = _peers.remove(id);
    if (peer != null) _deliver(peer.fake, _PrivateMail.unpaired(to: peer.id));
    privateNet._invites.removeWhere((_, v) => identical(v.fake, this) && v.id == id);
  }

  /// A payload as if the private pairing [id] had received [bytes] (tests).
  void receivePayload(String id, List<int> bytes) =>
      _payloads.add(PairingPayload(id: privateNet._next('payload'), pairingId: id, bytes: bytes, receivedAt: clock()));
}

/// The relay two [FakePairing]s share for private pairings: open invites by token.
class FakePrivateNet {
  final Map<String, ({FakePairing fake, String id})> _invites = {};
  final Set<String> _used = {};
  int _n = 0;

  String _next(String prefix) => '$prefix-${++_n}';
}

enum _MailKind { answer, confirm, payload, unpaired }

class _PrivateMail {
  _PrivateMail.answer({required this.to, required FakePairing this.from, required String this.fromId, required String this.name, required String this.token})
    : kind = _MailKind.answer,
      bytes = null;

  _PrivateMail.confirm({required this.to, required FakePairing this.from, required String this.fromId, required String this.token})
    : kind = _MailKind.confirm,
      name = null,
      bytes = null;

  _PrivateMail.payload({required this.to, required List<int> this.bytes})
    : kind = _MailKind.payload,
      from = null,
      fromId = null,
      name = null,
      token = null;

  _PrivateMail.unpaired({required this.to})
    : kind = _MailKind.unpaired,
      from = null,
      fromId = null,
      name = null,
      token = null,
      bytes = null;

  final _MailKind kind;

  /// The receiving fake's record.
  final String to;
  final FakePairing? from;
  final String? fromId;
  final String? name;
  final String? token;
  final List<int>? bytes;

  /// Set while it waits in an outbox.
  FakePairing? _to;
}
