/// A [PairingApi] that plays both sides of a pairing in memory, for widget tests, the
/// screenshot tour, the web preview and the desktop prototype. Nothing is sealed: links and
/// sealed files are readable JSON that only this fake opens.
///
/// Tests drive the other side with [answerInvite], [confirmAnswer], [failPending],
/// [changeKeys], [restoreKeys], [setRelayDown], [secondAnswer] and [emit]. With
/// [autoAnswerAfter] set, an invite is answered and an answer confirmed on their own after
/// that long, as the preview wants.
library;

import 'dart:async';
import 'dart:convert';

import 'models.dart';
import 'pairing_api.dart';
import 'sas_table.dart';
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
String fakePairedAddress(String seed, [String relay = 'epicbox.epiccash.com']) {
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

  /// Now, for expiries.
  DateTime Function() clock = DateTime.now;

  /// The relay the fake's own invites name ("Delivered via").
  String homeRelay = 'epicbox.epiccash.com';

  /// When set, the other side answers invites and confirms answers on its own after this long.
  Duration? autoAnswerAfter;

  /// The name the other side gives itself when it answers on its own.
  String autoAnswerName = 'Anna';

  /// When set, the relay is not reachable: answers wait to go by hand, words cannot be made
  /// or found ([PairingFailure.noRelay]).
  bool relayUnreachable = false;

  /// Whether a key check (a new pairing added to a contact that has one) finds the old keys:
  /// true is a restored wallet ("keys are back"), false another wallet ("keys changed").
  bool keyCheckFindsOldKeys = true;

  /// When set, the next open of a link, words or card fails with it.
  PairingFailure? nextOpenFailure;

  /// Invites another wallet made that [openWords] finds by their words (joined names).
  final Map<String, PairingInvitePreview> wordsInvites = {};

  final List<PairingRecord> records = [];
  final List<PairingStray> strayList = [];
  final Map<String, PairingInvitePreview> _previews = {};
  final Map<String, String> _cards = {};
  final StreamController<PairingEvent> _events = StreamController<PairingEvent>.broadcast();
  final List<Timer> _timers = [];
  int _seq = 0;

  /// Every call that changed something, in order (`makeInvite`, `accept`, `check:match`, …).
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

  /// The pairing whose contact sends from [address], matched on the key, or null.
  PairingRecord? recordFor(String address) {
    final key = epicboxKey(address);
    for (final r in records) {
      if (r.paymentsAddress != null && epicboxKey(r.paymentsAddress!) == key) return r;
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

  /// A paired contact in one call, for tests and the preview.
  PairingRecord seedPaired({
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
    bool relayDown = false,
    bool checkSkipped = false,
    PairingWay way = PairingWay.inPerson,
    List<SasWord>? sas,
  }) {
    final rid = id ?? _id('pairing');
    final now = clock();
    final record = PairingRecord(
      id: rid,
      state: state,
      way: way,
      inviter: false,
      createdAt: now.subtract(const Duration(days: 3)),
      name: name,
      kind: kind,
      caps: caps,
      sas: sas ?? fakeSasWords(rid),
      verifiedAt: state == PairingState.verified ? (verifiedAt ?? now.subtract(const Duration(days: 1))) : null,
      allowInvoices: allowInvoices && state == PairingState.verified,
      seal: seal,
      homeRelay: relay ?? homeRelay,
      contactId: contactId,
      paymentsAddress: paymentsAddress ?? fakePairedAddress(rid),
      lastSealedIn: lastSealedIn ?? now.subtract(const Duration(hours: 5)),
      relayDown: relayDown,
      checkSkipped: checkSkipped,
    );
    _put(record);
    return record;
  }

  /// The other wallet answered the invite [id] as [name]: it becomes paired and the inviter
  /// gets [PairingEventKind.replied].
  PairingRecord answerInvite(String id, {String? name, PairingParty kind = PairingParty.person, PairingCaps? caps}) {
    final r = _get(id);
    final who = name ?? r.label ?? autoAnswerName;
    final paired = r.copyWith(
      state: PairingState.paired,
      name: who,
      kind: kind,
      caps: caps,
      sas: fakeSasWords(r.id),
      paymentsAddress: fakePairedAddress(r.id),
    );
    _put(paired);
    emit(PairingEvent(PairingEventKind.replied, pairingId: id, name: paired.shownName));
    return paired;
  }

  /// The inviter confirmed the answer [id]: it becomes paired and the answerer gets
  /// [PairingEventKind.confirmed].
  PairingRecord confirmAnswer(String id) {
    final r = _get(id);
    final paired = r.copyWith(state: PairingState.paired, sas: fakeSasWords(r.id), paymentsAddress: fakePairedAddress(r.id));
    _put(paired);
    emit(PairingEvent(PairingEventKind.confirmed, pairingId: id, name: paired.shownName));
    return paired;
  }

  /// The pending pairing [id] ended with [failure]: removed, with [PairingEventKind.failed].
  void failPending(String id, PairingFailure failure) {
    final r = _get(id);
    records.removeWhere((e) => e.id == id);
    emit(PairingEvent(PairingEventKind.failed, pairingId: id, name: r.shownName, failure: failure));
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

  /// A second wallet answered the used invite [inviteId], claiming [name].
  PairingStray secondAnswer(String inviteId, String name) {
    final stray = PairingStray(id: _id('stray'), inviteId: inviteId, name: name);
    strayList.add(stray);
    emit(PairingEvent(PairingEventKind.secondReply, pairingId: inviteId, name: _nameOf(_get(inviteId))));
    return stray;
  }

  /// An invite from another wallet, as its link: [openInvite] reads it.
  String inviteLinkFrom({
    required String name,
    Duration expiresIn = const Duration(hours: 23, minutes: 12),
    PairingParty kind = PairingParty.person,
    bool asksInvoices = false,
    String? relay,
  }) {
    final token = _id('invite');
    return fakePairingLink('pair', {
      't': token,
      'n': name,
      'e': clock().add(expiresIn).millisecondsSinceEpoch,
      'k': kind.name,
      'i': asksInvoices,
      'r': relay ?? homeRelay,
    });
  }

  /// A card of another wallet, as its link: [scanCard] reads it.
  String cardLinkFrom(String name) => fakePairingLink('contact', {'c': _id('peer'), 'n': name});

  /// The name the app shows for [r]: its contact's, else its own.
  String _nameOf(PairingRecord r) {
    final cid = r.contactId;
    final contact = cid == null ? null : session?.contactsValue.where((c) => c.id == cid).firstOrNull;
    return contact?.name ?? r.shownName;
  }

  // PairingApi.

  @override
  bool get supported => enabled;

  @override
  Future<List<PairingRecord>> pairings() async {
    if (!enabled) return const [];
    return [...records];
  }

  @override
  Future<PairingRecord?> pairing(String id) async {
    if (!enabled) return null;
    return records.where((r) => r.id == id).firstOrNull;
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

  @override
  Future<PairingRecord> makeInvite({
    required String name,
    required Duration expiry,
    bool words = false,
    String? label,
    String? contactId,
  }) async {
    _require('makeInvite');
    final shown = name.trim();
    if (shown.isEmpty || utf8.encode(shown).length > 48) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the name must be 1 to 48 bytes');
    }
    if (words && relayUnreachable) throw pairingError(PairingFailure.noRelay);
    calls.add('makeInvite');
    final id = _id('invite');
    final now = clock();
    final expires = now.add(words ? pairingWordsExpiry : expiry);
    final record = PairingRecord(
      id: id,
      state: PairingState.pendingInvite,
      way: words ? PairingWay.words : PairingWay.link,
      inviter: true,
      createdAt: now,
      label: label,
      homeRelay: homeRelay,
      contactId: contactId,
      expiresAt: expires,
      inviteLink: fakePairingLink('pair', {'t': id, 'n': shown, 'e': expires.millisecondsSinceEpoch, 'k': 'person', 'i': false, 'r': homeRelay}),
      inviteWords: words ? fakeSasWords('words:$id', count: pairingWordCount) : const [],
    );
    _put(record);
    _later(() {
      if (records.any((r) => r.id == id && r.state == PairingState.pendingInvite)) answerInvite(id);
    });
    return record;
  }

  @override
  Future<void> cancelInvite(String id) async {
    _require('cancelInvite');
    calls.add('cancelInvite');
    // LEPIC's pairing_cancel: an invite stops working, an answer waiting for its confirm goes.
    records.removeWhere((r) => r.id == id && r.state.isPending);
  }

  @override
  Future<PairingRecord> openReply(String link) async {
    _require('openReply');
    final body = _readLink(link, 'pair-reply');
    if (body == null) throw pairingError(PairingFailure.invalid);
    final id = body['t'] as String?;
    final invite = records.where((r) => r.id == id).firstOrNull;
    if (invite == null) throw pairingError(PairingFailure.notFound);
    if (invite.state != PairingState.pendingInvite) throw pairingError(PairingFailure.alreadyUsed);
    calls.add('openReply');
    return answerInvite(invite.id, name: body['n'] as String?);
  }

  @override
  Future<String> confirmLink(String id) async {
    _require('confirmLink');
    final r = _get(id);
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
    if (body == null) throw pairingError(PairingFailure.invalid);
    final token = body['t'] as String? ?? _id('invite');
    if (records.any((r) => r.id == token)) throw pairingError(PairingFailure.ownCard);
    final expires = DateTime.fromMillisecondsSinceEpoch((body['e'] as num?)?.toInt() ?? 0);
    if (!clock().isBefore(expires)) throw pairingError(PairingFailure.expired);
    final preview = PairingInvitePreview(
      token: token,
      name: body['n'] as String? ?? '',
      expiresAt: expires,
      kind: PairingParty.values.asNameMap()[body['k']] ?? PairingParty.person,
      asksInvoices: body['i'] == true,
      homeRelay: body['r'] as String? ?? homeRelay,
      wordsAvailable: !relayUnreachable,
    );
    _previews[token] = preview;
    return preview;
  }

  @override
  Future<PairingInvitePreview> openWords(List<String> words) async {
    _require('openWords');
    if (relayUnreachable) throw pairingError(PairingFailure.noRelay);
    final failure = nextOpenFailure;
    if (failure != null) {
      nextOpenFailure = null;
      throw pairingError(failure);
    }
    final names = [
      for (final w in words) (sasWordNamed(w) ?? sasWordOfEmoji(w))?.name ?? w.trim().toLowerCase(),
    ];
    if (names.length != pairingWordCount) throw pairingError(PairingFailure.notFound);
    final key = names.join(' ');
    final preview = wordsInvites[key];
    if (preview == null) throw pairingError(PairingFailure.notFound);
    if (!clock().isBefore(preview.expiresAt)) throw pairingError(PairingFailure.expired);
    // The first to use the words takes the invite (C-33).
    wordsInvites.remove(key);
    _previews[preview.token] = preview;
    return preview;
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
    calls.add('accept');
    _previews.remove(token);
    final now = clock();
    final record = PairingRecord(
      id: _id('pairing'),
      state: PairingState.pendingReply,
      way: PairingWay.link,
      inviter: false,
      createdAt: now,
      name: preview.name,
      kind: preview.kind,
      caps: PairingCaps(issuesInvoices: preview.asksInvoices || preview.kind != PairingParty.person, sendsWithdrawals: preview.kind == PairingParty.exchange),
      asksInvoices: preview.asksInvoices && allowInvoices,
      homeRelay: preview.homeRelay,
      contactId: contactId,
      expiresAt: now.add(pairingReplyWait),
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
    return fakePairingLink('pair-reply', {'t': r.id, 'n': session == null ? 'Alex' : r.shownName});
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
  Future<PairingCard> showCard({required String name}) async {
    _require('showCard');
    final id = _id('card');
    _cards[id] = name;
    return PairingCard(id: id, link: fakePairingLink('contact', {'c': id, 'n': name}));
  }

  @override
  Future<PairingRecord> scanCard({required String cardId, required String text}) async {
    _require('scanCard');
    final failure = nextOpenFailure;
    if (failure != null) {
      nextOpenFailure = null;
      throw pairingError(failure);
    }
    final body = _readLink(text, 'contact');
    if (body == null) throw pairingError(PairingFailure.invalid);
    final peer = body['c'] as String? ?? '';
    if (_cards.containsKey(peer)) throw pairingError(PairingFailure.ownCard);
    calls.add('scanCard');
    final now = clock();
    final record = PairingRecord(
      id: _id('pairing'),
      state: PairingState.paired,
      way: PairingWay.inPerson,
      inviter: false,
      createdAt: now,
      name: body['n'] as String? ?? '',
      sas: fakeSasWords('$cardId:$peer'),
      homeRelay: homeRelay,
      paymentsAddress: fakePairedAddress(peer),
    );
    _put(record);
    return record;
  }

  @override
  Future<PairingRecord?> checkWords(String id, PairingCheck check) async {
    _require('checkWords');
    calls.add('check:${check.name}');
    final r = _get(id);
    switch (check) {
      case PairingCheck.match:
        final verified = r.copyWith(
          state: PairingState.verified,
          verifiedAt: clock(),
          allowInvoices: r.asksInvoices || r.allowInvoices,
          checkSkipped: false,
        );
        _put(verified);
        return verified;
      case PairingCheck.mismatch:
        records.removeWhere((e) => e.id == id);
            return null;
      case PairingCheck.skip:
        final skipped = r.copyWith(checkSkipped: true);
        _put(skipped);
        return skipped;
    }
  }

  @override
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground}) async {
    collects.add(trigger);
    if (!enabled) return 0;
    final now = clock();
    var taken = 0;
    // An answer with no confirm for an hour ends (C-16); an expired invite stays listed, so
    // Pending invites can offer Invite again, until it is cancelled.
    for (final r in [...records]) {
      if (r.state == PairingState.pendingReply && r.expiredAt(now)) {
        failPending(r.id, PairingFailure.noAnswer);
        taken++;
      }
    }
    return taken;
  }

  @override
  Future<void> removePairing(String id) async {
    _require('removePairing');
    calls.add('remove');
    records.removeWhere((r) => r.id == id);
  }

  @override
  Future<PairingRecord> setSeal(String id, bool on) async {
    _require('setSeal');
    final r = _get(id);
    if (r.paused) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'keys changed: check the words first');
    final next = r.copyWith(seal: on ? SealMode.on : SealMode.off);
    _put(next);
    return next;
  }

  @override
  Future<int> setAllowInvoices(String id, bool on) async {
    _require('setAllowInvoices');
    final r = _get(id);
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
  Future<PairingRecord> attach(String id, String? contactId) async {
    _require('attach');
    calls.add('attach');
    final fresh = _get(id);
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
        final next = r.copyWith(state: PairingState.paired, clearVerified: true, checkSkipped: false, allowInvoices: false);
        _put(next);
        return next;
    }
  }

  @override
  Future<IssuedInvoice> requestPayment({required String id, required BigInt amount, String? message}) async {
    _require('requestPayment');
    final r = _get(id);
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
    return OpenedSlate(slateJson: body['s'] as String? ?? '', pairingId: id, sealed: true);
  }

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
    return tx;
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
    return s.finalizeAndPost(slateJson: inside.slateJson);
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

  /// The backup object an export carries (RFC 10.5): the records, nothing secret.
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
          },
      ],
    };
  }

  /// Takes [backup] in; with [otherDevice] the records wait for [useImportedPairings].
  /// Returns how many records came in.
  int importBackup(Map<String, Object?>? backup, {bool otherDevice = true}) {
    if (!enabled || backup == null) return 0;
    var n = 0;
    for (final raw in (backup['records'] as List?) ?? const []) {
      final m = raw as Map<String, Object?>;
      final id = m['id'] as String;
      if (records.any((r) => r.id == id)) continue;
      final verifiedAt = m['verified_at'] as int?;
      _put(
        PairingRecord(
          id: id,
          state: PairingState.values.asNameMap()[m['state']] ?? PairingState.paired,
          way: PairingWay.inPerson,
          inviter: false,
          createdAt: clock(),
          name: m['name'] as String?,
          kind: PairingParty.values.asNameMap()[m['kind']] ?? PairingParty.person,
          sas: fakeSasWords(id),
          verifiedAt: verifiedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(verifiedAt),
          homeRelay: m['relay'] as String? ?? homeRelay,
          paymentsAddress: m['payments'] as String?,
          contactId: m['contact_id'] as String?,
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
}
