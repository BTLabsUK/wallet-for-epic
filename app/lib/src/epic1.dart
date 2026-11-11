// SPDX-License-Identifier: Apache-2.0
/// epic1 payments (`/tmp/epic-build/epictx/ui-spec.md`): the per-wallet switch, epic1 links,
/// in-person codes and `.epictx` files, as the app sees them.
///
/// A session with them implements [Epic1Capable]; [Epic1Of.epic1] reads its [Epic1Wallet], null for one
/// without (older fakes, a locked wallet). [LepicWalletSession] runs it on LEPIC, which picks the
/// relay mode itself (the NetGate mode, as for other relay calls); [FakeEpic1] answers in tests
/// and the desktop mock.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'recipient.dart' show epic1AddressOnly, epic1Shaped;
import 'wallet_service.dart' show WalletSession, fakeTx;

/// Which payment UI a wallet shows: today's ([classic]) or epic1 only ([epic1]).
enum PaymentMode { classic, epic1 }

/// The kind of an epic1 link this wallet issues.
enum Epic1LinkKind {
  /// Shown on a screen: the next mailbox of a ring of 50, drained for seven days after it was
  /// issued or last used.
  onScreen,

  /// Printed or kept: one of 32 mailboxes, held until the link is retired.
  printed,
}

/// The stage of an in-person code: a send to receive ([send], S1) or a request to pay
/// ([request], I1).
enum InPersonStage { send, request }

/// A relay a payment or answer would be posted to: show it before the user confirms.
class Epic1Host {
  const Epic1Host({required this.host, required this.port, this.localNetwork = false, this.inRelayList = false});

  final String host;
  final int port;

  /// An address on the local network rather than the internet.
  final bool localNetwork;

  /// The host is in the wallet's relay list: no "Send through this server?" for it.
  final bool inRelayList;

  /// `host` alone, or `host:port`, as the UI shows it.
  String get label => '$host:$port';

  @override
  bool operator ==(Object other) =>
      other is Epic1Host && other.host == host && other.port == port && other.localNetwork == localNetwork && other.inRelayList == inRelayList;

  @override
  int get hashCode => Object.hash(host, port, localNetwork, inRelayList);
}

/// A link made by [Epic1Wallet.makeLink].
class Epic1LinkMade {
  const Epic1LinkMade({required this.link, required this.address, required this.kind, required this.n});

  /// The link text, `epic:epic1…?epicbox=…`, to show as a QR code, copy or share.
  final String link;

  /// The epic1 address the link pays.
  final String address;
  final Epic1LinkKind kind;

  /// The link's number within its kind, from 0. The UI counts printed codes from 1.
  final int n;
}

/// What a link asks, from [Epic1Wallet.readLink]. Nothing is stored.
class Epic1LinkInfo {
  const Epic1LinkInfo({required this.address, this.amount, this.message, this.label, this.hosts = const []});

  final String address;

  /// The amount asked, in base units; null when the payer chooses it.
  final BigInt? amount;

  /// The payee's message, shown as quoted text.
  final String? message;
  final String? label;

  /// The relays the payment tries, in order. One not [Epic1Host.inRelayList] asks "Send
  /// through this server?" first, then the pay goes with `hostsOk: true`.
  final List<Epic1Host> hosts;
}

/// One post of an epic1 payment to a relay of its link.
class Epic1Attempt {
  const Epic1Attempt({required this.host, this.error});
  final String host;

  /// Why the post failed; null when it went through.
  final String? error;
}

/// A payment to an epic1 link, from [Epic1Wallet.payLink] or [Epic1Wallet.postNext].
class Epic1Payment {
  const Epic1Payment({required this.txId, required this.slateId, required this.address, this.attempts = const [], this.posted});

  final int txId;
  final String slateId;
  final String address;

  /// The posts made, in order; the last went through when [posted] is set.
  final List<Epic1Attempt> attempts;

  /// The relay, from 0, the payment was posted to; null when none took it yet ("Try next
  /// server").
  final int? posted;

  /// The host the payment went to, for the "Server" row.
  String? get postedHost => posted == null || attempts.isEmpty ? null : attempts.last.host;
}

/// An answer this wallet made to a payment that came to one of its links.
class Epic1Answer {
  const Epic1Answer({required this.txId, required this.slateId, required this.mailbox, this.host, required this.posted});

  final int txId;
  final String slateId;

  /// The relay of the payer's reply mailbox, as the payment wrote it.
  final String mailbox;

  /// The relay to post to; null when it cannot be posted to.
  final Epic1Host? host;
  final bool posted;
}

/// A link mailbox in use, from [Epic1Wallet.links]: the printed codes panel lists the
/// [Epic1LinkKind.printed] ones.
class Epic1LinkSlot {
  const Epic1LinkSlot({required this.kind, required this.n, required this.issuedAt, this.usedAt, this.relays = const []});

  final Epic1LinkKind kind;
  final int n;
  final DateTime issuedAt;

  /// When a payment last came to the link.
  final DateTime? usedAt;

  /// `domain[:port]` of each relay the link names.
  final List<String> relays;
}

/// A `.epictx` file or `BEGINEPICTX.` text opened by [Epic1Wallet.openEpictx].
class EpictxOpened {
  const EpictxOpened({this.contactId, required this.native, required this.slateJson, this.reference, this.expires});

  /// The paired contact whose signature it carries; null for an anonymous one.
  final String? contactId;

  /// The body is a `lepic.v1` slate.
  final bool native;

  /// The slate as JSON, for [WalletSession.inspectSlate] and the existing receive/finalize.
  final String slateJson;

  /// The sender's own reference, shown and never trusted.
  final String? reference;

  /// When the sender stops honouring it; advisory.
  final DateTime? expires;
}

/// An in-person code to show, from [Epic1Wallet.inPersonRequest] or [Epic1Wallet.inPersonSend].
class InPersonCodeMade {
  const InPersonCodeMade({required this.txId, required this.slateId, required this.bytes, required this.ttlCutoff, this.mailbox});

  final int txId;
  final String slateId;

  /// The raw code: one byte-mode QR code, or the parts [Epic1Wallet.qrParts] gives.
  final Uint8List bytes;

  /// The code is good until this height (expiry line: blocks left from the tip).
  final BigInt ttlCutoff;

  /// `domain:port` of the reply mailbox the code names; null when the answer comes back by
  /// scan or paste.
  final String? mailbox;

  /// The code as text to copy, paste and show beside the QR (desktop has no scanner).
  String get text => base64Url.encode(bytes);
}

/// A scanned or pasted code, from [Epic1Wallet.inPersonRead]. Nothing is stored.
class InPersonCodeInfo {
  const InPersonCodeInfo({required this.slateId, required this.stage, required this.amount, this.fee, this.message, required this.ttlCutoff, this.mailbox});

  final String slateId;
  final InPersonStage stage;
  final BigInt amount;

  /// The fee of the send; for a request, the estimated fee of paying it (null: no estimate).
  final BigInt? fee;
  final String? message;
  final BigInt ttlCutoff;

  /// The mailbox the answer is posted to; null when it is shown back. One not
  /// [Epic1Host.inRelayList] is confirmed by the user before [Epic1Wallet.inPersonPost].
  final Epic1Host? mailbox;
}

/// The answer to a scanned code, from [Epic1Wallet.inPersonReceive] or [Epic1Wallet.inPersonPay].
/// It is stored.
class InPersonAnswerMade {
  const InPersonAnswerMade({required this.txId, required this.slateId, required this.envelope, required this.armored, this.mailbox});

  final int txId;
  final String slateId;

  /// The sealed answer to show back as a QR code when [mailbox] is null.
  final Uint8List envelope;

  /// [envelope] as `BEGINEPICTX.` text, to copy.
  final String armored;

  final Epic1Host? mailbox;
}

/// One answer taken for a code this wallet showed.
class InPersonAnswer {
  const InPersonAnswer({required this.number, required this.checkCode, required this.sameCode, required this.receivedAt});

  /// From 1.
  final int number;
  final String checkCode;

  /// An earlier answer had the same check code: show "Two phones answered with the same code."
  final bool sameCode;
  final DateTime receivedAt;
}

/// A code this wallet showed and the answers taken for it, from [Epic1Wallet.inPersonAnswers].
class InPersonStatus {
  const InPersonStatus({required this.txId, required this.slateId, required this.stage, required this.ttlCutoff, this.mailbox, this.closed = false, this.finalized, this.answers = const []});

  final int txId;
  final String slateId;
  final InPersonStage stage;
  final BigInt ttlCutoff;
  final String? mailbox;

  /// No more answers are taken.
  final bool closed;

  /// The number of the answer finalized.
  final int? finalized;
  final List<InPersonAnswer> answers;
}

/// An answer taken by [Epic1Wallet.inPersonTake] (pasted or scanned back). Nothing finalized.
class InPersonTaken {
  const InPersonTaken({required this.txId, required this.slateId, required this.stage, required this.answer, required this.checkCode, this.sameCode = false, this.duplicate = false});

  final int txId;
  final String slateId;
  final InPersonStage stage;

  /// The answer's number, for [Epic1Wallet.inPersonFinalize].
  final int answer;
  final String checkCode;
  final bool sameCode;

  /// The same answer was taken before; nothing new was stored.
  final bool duplicate;
}

/// The parts of an animated QR code read so far, from [Epic1Wallet.qrRead].
class InPersonQrProgress {
  const InPersonQrProgress({required this.complete, required this.received, required this.total, this.bytes});

  final bool complete;
  final int received;
  final int total;

  /// Once [complete]: the code or answer for [Epic1Wallet.inPersonRead] or
  /// [Epic1Wallet.inPersonTake].
  final Uint8List? bytes;
}

/// The epic1 calls of an open wallet (spec section 5). Errors are [WalletError]s with the
/// kinds of spec section 6 (`WalletErrorKind.epic1CannotPay` …).
abstract interface class Epic1Wallet {
  // The switch.

  /// The stored setting: on makes the next unlock open in epic1 mode.
  bool get storedOn;

  /// The setting this session opened with: the mode the UI shows now.
  bool get inUse;

  /// Stores the setting; it applies at the next unlock ("Applies at next unlock" while
  /// [storedOn] differs from [inUse]).
  Future<void> setStoredOn(bool on);

  // Links.

  Future<String> address();

  /// Makes a link on [relays] (the wallet's Epicbox server, `domain[:port]`).
  Future<Epic1LinkMade> makeLink({BigInt? amount, String? message, Epic1LinkKind kind = Epic1LinkKind.onScreen, required List<String> relays});

  /// Reads a pasted or scanned link. Throws notAnEpic1Link, epic1WrongNetwork, epic1CannotPay.
  Future<Epic1LinkInfo> readLink(String link);

  /// Pays [link]. [hostsOk] is true once the review showed the link's relays and "Use server"
  /// was pressed for any not in the relay list; LEPIC refuses false. A payment no relay took comes back with [Epic1Payment.posted] null, or as
  /// epic1NoMoreRelays.
  Future<Epic1Payment> payLink({
    required String link,
    BigInt? amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
    required bool hostsOk,
  });

  /// "Try next server": posts the stored payment to the next relay of its link.
  Future<Epic1Payment> postNext({required String slateId, required bool hostsOk});

  /// Answers made to payments that came to this wallet's links.
  Future<List<Epic1Answer>> answers();

  /// Posts the answer for [slateId] to its payer's mailbox.
  Future<void> postAnswer({required String slateId, required bool relayOk});

  /// The link mailboxes in use (on-screen and printed).
  Future<List<Epic1LinkSlot>> links();

  /// Retires printed link [n]: payments to it stop arriving.
  Future<void> retireLink(int n);

  /// Drains the 50 on-screen and 32 printed link mailboxes after a restore; the count found.
  Future<int> restore();

  // Files.

  /// Opens a `.epictx` file's text or pasted `BEGINEPICTX.` text.
  Future<EpictxOpened> openEpictx(String text);

  // In person.

  /// "Request in person": a request code for [amount]. [ttlBlocks] null is LEPIC's 30.
  Future<InPersonCodeMade> inPersonRequest({required BigInt amount, String? message, int? ttlBlocks});

  /// "Pay in person": a send code for [amount]. Inputs stay locked until an answer is
  /// finalized, the code expires or it is cancelled.
  Future<InPersonCodeMade> inPersonSend({required BigInt amount, required BigInt minimumConfirmations, String? message, SendOptions? options});

  /// Reads a scanned or pasted code (raw bytes, or [InPersonCodeMade.text] decoded).
  Future<InPersonCodeInfo> inPersonRead(List<int> code, {required BigInt minimumConfirmations, SendOptions? options});

  /// Receives a send code: the answer to show or post.
  Future<InPersonAnswerMade> inPersonReceive(List<int> code, {String? message});

  /// Pays a request code for exactly [amount], the amount shown.
  Future<InPersonAnswerMade> inPersonPay(List<int> code, {required BigInt amount, required BigInt minimumConfirmations, String? message, SendOptions? options});

  /// Posts a stored answer to the mailbox its code named. Returns its check code: four digits
  /// shown to the user only now, after posting; the other side finalizes the answer showing
  /// the same. An answer shown back has none.
  Future<String> inPersonPost({required String slateId, required bool relayOk});

  /// The answers taken so far for a code this wallet showed (the pairing collect fetches
  /// them from the reply mailbox).
  Future<InPersonStatus> inPersonAnswers(String slateId);

  /// Takes an answer scanned or pasted back (its bytes, or `BEGINEPICTX.` text as UTF-8).
  Future<InPersonTaken> inPersonTake(List<int> answer);

  /// "Matches": finalizes answer [answer] and posts it. The code takes no more answers.
  Future<TxEntry> inPersonFinalize({required String slateId, required int answer});

  /// The parts of an animated QR code for [bytes] (code or answer); one part when it fits.
  List<String> qrParts(List<int> bytes);

  /// Reads the distinct QR texts scanned so far, in any order.
  InPersonQrProgress qrRead(List<String> parts);
}

/// A session that holds epic1 calls: the LEPIC session and [FakeWalletSession].
abstract interface class Epic1Capable {
  Epic1Wallet? get epic1Wallet;
}

extension Epic1Of on WalletSession {
  /// This session's epic1 calls, or null for one without them.
  Epic1Wallet? get epic1 {
    // A pattern, not `is`, as in DrainEpicboxAt (wallet_service.dart).
    if (this case final Epic1Capable c) return c.epic1Wallet;
    return null;
  }

  /// The mode the payment UI shows for this session.
  PaymentMode get paymentMode => (epic1?.inUse ?? false) ? PaymentMode.epic1 : PaymentMode.classic;
}

/// Whether [text] looks like an epic1 link (`epic:epic1…` or a bare `epic1…` address; `tepic1`
/// on the test network), for the mode lines ("epic1 link. Turn on epic1 payments to pay it.").
/// LEPIC's [Epic1Wallet.readLink] is the real check.
bool looksLikeEpic1Link(String text) => epic1Shaped(text);

/// [text] cut in the middle to [keep] characters: the scheme and start, then the end.
String shortMiddle(String text, {int keep = 44}) {
  if (text.length <= keep) return text;
  final head = (keep * 0.6).round();
  return '${text.substring(0, head)}…${text.substring(text.length - (keep - head - 1))}';
}

/// Whether [text] is a `BEGINEPICTX.` armored envelope (an epic1 file or answer).
bool looksLikeEpictx(String text) => text.trimLeft().startsWith('BEGINEPICTX.');

/// [Epic1Wallet] in memory, for widget tests and the desktop mock. Nothing touches the
/// network; posts succeed unless a test sets [failPosts] or [failNext].
class FakeEpic1 implements Epic1Wallet {
  FakeEpic1({bool on = false}) : _stored = on, _inUse = on;

  bool _stored;
  bool _inUse;

  /// The next call throws this, once.
  WalletError? failNext;

  /// Relays that refuse posts (payLink, postNext).
  final Set<String> failPosts = {};

  /// What [readLink] reports as the link's hosts; default one relay in the list.
  List<Epic1Host> linkHosts = const [Epic1Host(host: 'relay.example.invalid', port: 443, inRelayList: true)];

  final List<Epic1LinkSlot> _links = [];
  final Map<String, InPersonStatus> _codes = {};
  final List<Epic1Answer> answerList = [];
  final List<String> calls = [];
  int _next = 1;

  /// Told each stored change, so a fake service keeps the setting per wallet across unlocks.
  void Function(bool on)? onStored;

  /// Simulates the next unlock: the stored setting becomes the one in use.
  void reopen() => _inUse = _stored;

  void _call(String name) {
    calls.add(name);
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  String _slate() => '00000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';

  @override
  bool get storedOn => _stored;

  @override
  bool get inUse => _inUse;

  @override
  Future<void> setStoredOn(bool on) async {
    _call('setStoredOn');
    _stored = on;
    onStored?.call(on);
  }

  @override
  Future<String> address() async {
    _call('address');
    return 'epic1qfake${'q' * 52}';
  }

  @override
  Future<Epic1LinkMade> makeLink({BigInt? amount, String? message, Epic1LinkKind kind = Epic1LinkKind.onScreen, required List<String> relays}) async {
    _call('makeLink');
    final n = _links.where((l) => l.kind == kind).length;
    if (kind == Epic1LinkKind.printed && n >= 32) {
      throw const WalletError(kind: WalletErrorKind.printedLinksFull, message: 'printed links full');
    }
    _links.add(Epic1LinkSlot(kind: kind, n: kind == Epic1LinkKind.onScreen ? n % 50 : n, issuedAt: DateTime.now(), relays: relays));
    final q = [if (amount != null) 'amount=$amount', for (final r in relays) 'epicbox=$r'].join('&');
    return Epic1LinkMade(link: 'epic:${await address()}${q.isEmpty ? '' : '?$q'}', address: await address(), kind: kind, n: n);
  }

  @override
  Future<Epic1LinkInfo> readLink(String link) async {
    _call('readLink');
    // As LEPIC: only an `epic:` link parses; one with no query names no server, so cannot be
    // paid. A link with a query reaches [linkHosts].
    if (!looksLikeEpic1Link(link) || !link.trim().toLowerCase().startsWith('epic:')) {
      throw const WalletError(kind: WalletErrorKind.notAnEpic1Link, message: 'not an epic1 link');
    }
    if (epic1AddressOnly(link)) {
      throw const WalletError(kind: WalletErrorKind.epic1CannotPay, message: 'the link names no server');
    }
    final amount = RegExp(r'amount=(\d+)').firstMatch(link)?[1];
    return Epic1LinkInfo(address: link.split('?').first.replaceFirst('epic:', ''), amount: amount == null ? null : BigInt.parse(amount), hosts: linkHosts);
  }

  Epic1Payment _post(int txId, String slateId, String address, List<Epic1Attempt> before) {
    final attempts = [...before];
    for (final h in linkHosts.skip(before.length)) {
      if (failPosts.contains(h.host)) {
        attempts.add(Epic1Attempt(host: h.host, error: 'refused'));
        return Epic1Payment(txId: txId, slateId: slateId, address: address, attempts: attempts);
      }
      attempts.add(Epic1Attempt(host: h.host));
      return Epic1Payment(txId: txId, slateId: slateId, address: address, attempts: attempts, posted: attempts.length - 1);
    }
    throw WalletError(kind: WalletErrorKind.epic1NoMoreRelays, message: 'every relay tried', txId: txId);
  }

  final Map<String, Epic1Payment> _payments = {};

  @override
  Future<Epic1Payment> payLink({required String link, BigInt? amount, required BigInt minimumConfirmations, String? message, SendOptions? options, required bool hostsOk}) async {
    _call('payLink');
    // As LEPIC: no payment without the relays confirmed, listed or not.
    if (!hostsOk) throw const WalletError(kind: WalletErrorKind.relayNotConfirmed, message: 'relay not confirmed');
    final info = await readLink(link);
    final p = _post(_next, _slate(), info.address, const []);
    return _payments[p.slateId] = p;
  }

  @override
  Future<Epic1Payment> postNext({required String slateId, required bool hostsOk}) async {
    _call('postNext');
    final was = _payments[slateId];
    if (!hostsOk) throw const WalletError(kind: WalletErrorKind.relayNotConfirmed, message: 'relay not confirmed');
    if (was == null) throw const WalletError(kind: WalletErrorKind.codeExpired, message: 'no such payment');
    return _payments[slateId] = _post(was.txId, slateId, was.address, was.attempts);
  }

  @override
  Future<List<Epic1Answer>> answers() async {
    _call('answers');
    return List.of(answerList);
  }

  @override
  Future<void> postAnswer({required String slateId, required bool relayOk}) async {
    _call('postAnswer');
    final i = answerList.indexWhere((a) => a.slateId == slateId);
    if (i >= 0) {
      final a = answerList[i];
      answerList[i] = Epic1Answer(txId: a.txId, slateId: a.slateId, mailbox: a.mailbox, host: a.host, posted: true);
    }
  }

  @override
  Future<List<Epic1LinkSlot>> links() async {
    _call('links');
    return List.of(_links);
  }

  @override
  Future<void> retireLink(int n) async {
    _call('retireLink');
    _links.removeWhere((l) => l.kind == Epic1LinkKind.printed && l.n == n);
  }

  @override
  Future<int> restore() async {
    _call('restore');
    return 0;
  }

  @override
  Future<EpictxOpened> openEpictx(String text) async {
    _call('openEpictx');
    if (!looksLikeEpictx(text)) throw const WalletError(kind: WalletErrorKind.invalidSlate, message: 'not an epictx');
    return const EpictxOpened(native: true, slateJson: '{}');
  }

  InPersonCodeMade _code(InPersonStage stage, BigInt amount) {
    final slateId = _slate();
    final bytes = Uint8List.fromList([stage.index, ...sha256.convert(utf8.encode('$slateId $amount')).bytes]);
    _codes[slateId] = InPersonStatus(txId: _next, slateId: slateId, stage: stage, ttlCutoff: BigInt.from(1030), mailbox: 'relay.example.invalid:443');
    return InPersonCodeMade(txId: _next, slateId: slateId, bytes: bytes, ttlCutoff: BigInt.from(1030), mailbox: 'relay.example.invalid:443');
  }

  @override
  Future<InPersonCodeMade> inPersonRequest({required BigInt amount, String? message, int? ttlBlocks}) async {
    _call('inPersonRequest');
    if (ttlBlocks != null && ttlBlocks <= 10) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'ttl');
    return _code(InPersonStage.request, amount);
  }

  @override
  Future<InPersonCodeMade> inPersonSend({required BigInt amount, required BigInt minimumConfirmations, String? message, SendOptions? options}) async {
    _call('inPersonSend');
    return _code(InPersonStage.send, amount);
  }

  @override
  Future<InPersonCodeInfo> inPersonRead(List<int> code, {required BigInt minimumConfirmations, SendOptions? options}) async {
    _call('inPersonRead');
    if (code.isEmpty || code.first > 1) throw const WalletError(kind: WalletErrorKind.invalidSlate, message: 'not a code');
    return InPersonCodeInfo(
      slateId: _slate(),
      stage: InPersonStage.values[code.first],
      amount: BigInt.from(100000000),
      fee: BigInt.from(700000),
      ttlCutoff: BigInt.from(1030),
      mailbox: const Epic1Host(host: 'relay.example.invalid', port: 443, inRelayList: true),
    );
  }

  InPersonAnswerMade _answer() {
    final slateId = _slate();
    final envelope = Uint8List.fromList(utf8.encode('BEGINEPICTX. fake $slateId. ENDEPICTX.'));
    return InPersonAnswerMade(txId: _next, slateId: slateId, envelope: envelope, armored: utf8.decode(envelope), mailbox: const Epic1Host(host: 'relay.example.invalid', port: 443, inRelayList: true));
  }

  @override
  Future<InPersonAnswerMade> inPersonReceive(List<int> code, {String? message}) async {
    _call('inPersonReceive');
    return _answer();
  }

  @override
  Future<InPersonAnswerMade> inPersonPay(List<int> code, {required BigInt amount, required BigInt minimumConfirmations, String? message, SendOptions? options}) async {
    _call('inPersonPay');
    return _answer();
  }

  @override
  Future<String> inPersonPost({required String slateId, required bool relayOk}) async {
    _call('inPersonPost');
    if (!relayOk) throw const WalletError(kind: WalletErrorKind.relayNotConfirmed, message: 'relay not confirmed');
    return '4821';
  }

  /// Adds an answer to code [slateId], as the collect would.
  void answerCode(String slateId, {String checkCode = '4821'}) {
    final s = _codes[slateId]!;
    final same = s.answers.any((a) => a.checkCode == checkCode);
    _codes[slateId] = InPersonStatus(
      txId: s.txId,
      slateId: s.slateId,
      stage: s.stage,
      ttlCutoff: s.ttlCutoff,
      mailbox: s.mailbox,
      answers: [...s.answers, InPersonAnswer(number: s.answers.length + 1, checkCode: checkCode, sameCode: same, receivedAt: DateTime.now())],
    );
  }

  @override
  Future<InPersonStatus> inPersonAnswers(String slateId) async {
    _call('inPersonAnswers');
    final s = _codes[slateId];
    if (s == null) throw const WalletError(kind: WalletErrorKind.codeExpired, message: 'no such code');
    return s;
  }

  @override
  Future<InPersonTaken> inPersonTake(List<int> answer) async {
    _call('inPersonTake');
    final open = _codes.values.where((c) => !c.closed).toList();
    if (open.isEmpty) throw const WalletError(kind: WalletErrorKind.invalidSlate, message: 'answers no open code');
    final c = open.last;
    answerCode(c.slateId);
    final a = _codes[c.slateId]!.answers.last;
    return InPersonTaken(txId: c.txId, slateId: c.slateId, stage: c.stage, answer: a.number, checkCode: a.checkCode, sameCode: a.sameCode);
  }

  @override
  Future<TxEntry> inPersonFinalize({required String slateId, required int answer}) async {
    _call('inPersonFinalize');
    final s = _codes[slateId];
    if (s == null || answer < 1 || answer > s.answers.length) {
      throw const WalletError(kind: WalletErrorKind.codeExpired, message: 'no such code or answer');
    }
    if (s.closed) throw const WalletError(kind: WalletErrorKind.epic1Finalized, message: 'finalized');
    _codes[slateId] = InPersonStatus(txId: s.txId, slateId: slateId, stage: s.stage, ttlCutoff: s.ttlCutoff, mailbox: s.mailbox, closed: true, finalized: answer, answers: s.answers);
    return fakeTx(id: s.txId, slateId: slateId, kind: s.stage == InPersonStage.send ? TxKind.sent : TxKind.received);
  }

  @override
  List<String> qrParts(List<int> bytes) => ['ur:epic1/${base64Url.encode(bytes)}'];

  @override
  InPersonQrProgress qrRead(List<String> parts) {
    if (parts.isEmpty) return const InPersonQrProgress(complete: false, received: 0, total: 1);
    final b = base64Url.decode(parts.first.replaceFirst('ur:epic1/', ''));
    return InPersonQrProgress(complete: true, received: 1, total: 1, bytes: Uint8List.fromList(b));
  }
}
