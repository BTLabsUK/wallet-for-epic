// SPDX-License-Identifier: Apache-2.0
/// The in-person payments (spec D3, D5, P3, P5, P6) without their widgets, for the phone and
/// the desktop: what a scanned or pasted text is, and a code on screen waiting for its answer.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../boosts.dart' show Boosts, boostMinInterval;
import '../../epic1.dart';
import '../../models.dart';
import '../../qr_slate.dart' show qrFrameMs;
import '../../relay_boost.dart';

/// How often a code on screen asks for its answers.
const Duration inPersonPollEvery = Duration(seconds: 3);

/// How long each part of an animated QR code shows: the payment code's rate, six a second, so
/// an answer of about 19 parts passes in about three seconds.
const Duration inPersonFrameEvery = Duration(milliseconds: qrFrameMs);

/// A block is about a minute (as the payment details count).
const int _minutesPerBlock = 1;

/// The minutes a code with [cutoff] still works at [tip]; null when unknown or past.
int? inPersonMinutesLeft(BigInt cutoff, BigInt? tip) {
  if (tip == null || tip <= BigInt.zero) return null;
  final left = (cutoff - tip).toInt();
  return left > 0 ? left * _minutesPerBlock : null;
}

/// What a scanned or pasted text holds.
sealed class InPersonInput {
  const InPersonInput();
}

/// A code or an answer as bytes: a complete QR code, or a pasted code's text decoded.
class InPersonBytes extends InPersonInput {
  const InPersonBytes(this.bytes, {this.fromQr = false});
  final Uint8List bytes;

  /// Read from a QR code: it may be an answer as well as a code.
  final bool fromQr;
}

/// One part of an animated QR code; more parts are needed.
class InPersonPart extends InPersonInput {
  const InPersonPart(this.part, this.progress);
  final String part;
  final InPersonQrProgress progress;
}

/// A `BEGINEPICTX.` answer.
class InPersonArmored extends InPersonInput {
  const InPersonArmored(this.text);
  final String text;

  Uint8List get bytes => Uint8List.fromList(utf8.encode(text));
}

final RegExp _codeText = RegExp(r'^[A-Za-z0-9_-]{16,}={0,2}$');

/// What [text] holds, or null when it is nothing in person. Reads QR parts through [wallet].
InPersonInput? readInPersonText(Epic1Wallet wallet, String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  if (looksLikeEpictx(t)) return InPersonArmored(t);
  if (t.toLowerCase().startsWith('ur:')) {
    try {
      final p = wallet.qrRead([t]);
      final bytes = p.bytes;
      if (p.complete && bytes != null) return InPersonBytes(bytes, fromQr: true);
      return InPersonPart(t, p);
    } on Object {
      return null;
    }
  }
  if (_codeText.hasMatch(t)) {
    try {
      return InPersonBytes(base64Url.decode(base64Url.normalize(t)));
    } on FormatException {
      return null;
    }
  }
  return null;
}

/// Where a code on screen stands.
enum InPersonPhase {
  /// Shown; no answer yet.
  waiting,

  /// An answer came: "Does the other phone show 4821?"
  check,

  /// Matches was pressed; finishing.
  finishing,

  /// Finished: "Sent" or "Received".
  done,

  /// Different was pressed: nothing was posted.
  stopped,

  /// Two answers with the same check code (P6).
  sameCode,

  /// The code expired before it was finished.
  expired,
}

/// Where an answer going through the code's Epicbox server stands.
enum InPersonOnlineStep {
  /// The answering side sends its answer.
  posting,

  /// The answering side's answer went through.
  sent,

  /// The code side waits for the answer.
  waiting,

  /// The code side got the answer.
  received,

  /// The server did not answer: the answering side shows its answer to scan; the code side
  /// keeps asking and offers paste and scan meanwhile.
  failed,

  /// "Cancel online reply": the answer goes by scan or paste.
  cancelled,
}

/// An answer coming back through an Epicbox server, for the status line and its details.
abstract interface class InPersonOnline implements Listenable {
  /// The Epicbox server, host alone.
  String get host;

  InPersonOnlineStep get step;

  /// The block height the code stops working at.
  BigInt get cutoff;

  /// Stops sending or waiting online; the answer then goes by scan or paste.
  void cancelOnline();
}

/// [mailbox] (`domain:port` or a bare host) without its port.
String inPersonHostOf(String mailbox) {
  final at = mailbox.lastIndexOf(':');
  return at > 0 && int.tryParse(mailbox.substring(at + 1)) != null ? mailbox.substring(0, at) : mailbox;
}

/// Polls failing in a row before the code side shows paste and scan again.
const int _failsBeforeManual = 2;

/// A code this wallet shows, waiting for its answer: asks [Epic1Wallet.inPersonAnswers] every
/// [inPersonPollEvery] while it waits, and takes answers pasted or scanned back.
class InPersonCodeWatch extends ChangeNotifier implements InPersonOnline {
  InPersonCodeWatch({required this.wallet, required this.stage, required BigInt this.amount, required InPersonCodeMade made, this.boosts, this.pollEvery = inPersonPollEvery})
    : _made = made,
      _slateId = made.slateId {
    _start();
  }

  /// An answer pasted or scanned outside its code's screen ([Epic1Wallet.inPersonTake]): the
  /// check question at once, no code to show.
  InPersonCodeWatch.answered({required this.wallet, required InPersonTaken taken})
    : stage = taken.stage,
      amount = null,
      boosts = null,
      pollEvery = inPersonPollEvery,
      _made = null,
      _slateId = taken.slateId {
    _use(taken);
  }

  final Epic1Wallet wallet;
  final InPersonStage stage;

  /// The code's amount; null for [InPersonCodeWatch.answered].
  final BigInt? amount;
  final Duration pollEvery;

  /// The wallet's boosts: the relays are checked more often while the code waits online.
  final Boosts? boosts;

  InPersonCodeMade? _made;

  /// The code on screen; null for [InPersonCodeWatch.answered].
  InPersonCodeMade? get made => _made;
  String _slateId;

  InPersonPhase _phase = InPersonPhase.waiting;
  InPersonPhase get phase => _phase;

  /// The answer to finish on Matches, and its check code.
  int? _answer;
  String? _checkCode;
  String? get checkCode => _checkCode;

  /// The finished payment, once [InPersonPhase.done].
  TxEntry? tx;

  /// The last refusal, while the screen can still go on (Matches again).
  Object? error;

  Timer? _poll;
  void Function()? _unboost;
  bool _asking = false;
  bool _disposed = false;

  /// "Cancel online reply" was pressed: no more asking the server.
  bool _manual = false;

  /// Asks that failed in a row.
  int _fails = 0;

  /// The code names an Epicbox server for its answer.
  bool get hasMailbox => _made?.mailbox != null;

  @override
  String get host => inPersonHostOf(_made?.mailbox ?? '');

  @override
  BigInt get cutoff => _made?.ttlCutoff ?? BigInt.zero;

  @override
  InPersonOnlineStep get step {
    if (_manual) return InPersonOnlineStep.cancelled;
    if (_phase != InPersonPhase.waiting) return InPersonOnlineStep.received;
    return _fails >= _failsBeforeManual ? InPersonOnlineStep.failed : InPersonOnlineStep.waiting;
  }

  /// The answer comes back through the server: the screen shows the status line, and paste
  /// and scan only once the server failed.
  bool get online => hasMailbox && !_manual && _phase == InPersonPhase.waiting;

  /// Paste and scan are offered: no server, the server failed, or the online reply was cancelled.
  bool get manual => !online || step == InPersonOnlineStep.failed;

  @override
  void cancelOnline() {
    if (!online) return;
    _manual = true;
    _stop();
    if (!_disposed) notifyListeners();
  }

  /// The QR parts of the code.
  late List<String> parts = switch (_made) {
    final made? => wallet.qrParts(made.bytes),
    null => const [],
  };

  void _start() {
    _stop();
    _poll = Timer.periodic(pollEvery, (_) => unawaited(poll()));
    if (hasMailbox) _unboost = boostRelays(boosts, boostMinInterval);
  }

  void _stop() {
    _poll?.cancel();
    _unboost?.call();
    _unboost = null;
  }

  void _set(InPersonPhase phase) {
    _phase = phase;
    if (phase != InPersonPhase.waiting) _stop();
    if (!_disposed) notifyListeners();
  }

  /// Asks for the answers once.
  Future<void> poll() async {
    if (_phase != InPersonPhase.waiting || _asking || _manual) return;
    _asking = true;
    final slateId = _slateId;
    try {
      final status = await wallet.inPersonAnswers(slateId);
      // An answer that comes after "Cancel online reply" is left: the one pasted or scanned
      // is the same answer to LEPIC (it keeps one record per answer).
      if (_disposed || _phase != InPersonPhase.waiting || slateId != _slateId || _manual) return;
      if (_fails > 0) {
        _fails = 0;
        notifyListeners();
      }
      if (status.answers.any((a) => a.sameCode)) {
        _set(InPersonPhase.sameCode);
      } else if (status.answers.isNotEmpty) {
        final a = status.answers.first;
        _answer = a.number;
        _checkCode = a.checkCode;
        _set(InPersonPhase.check);
      }
    } on WalletError catch (e) {
      if (_disposed || slateId != _slateId) return;
      if (e.kind == WalletErrorKind.codeExpired) {
        _set(InPersonPhase.expired);
      } else if (!_manual && ++_fails == _failsBeforeManual) {
        // The server did not answer: the next ask tries again, and paste and scan show.
        notifyListeners();
      }
    } finally {
      _asking = false;
    }
  }

  /// Takes the answer [text] pasted or scanned back. False when it is no answer to this code.
  Future<bool> take(String text) async {
    final input = readInPersonText(wallet, text);
    final bytes = switch (input) {
      InPersonArmored(:final bytes) => bytes,
      InPersonBytes(:final bytes) => bytes,
      _ => null,
    };
    return bytes != null && await takeBytes(bytes);
  }

  /// Takes the answer [bytes] scanned back. False when it is no answer to this code.
  Future<bool> takeBytes(List<int> bytes) async {
    try {
      return taken(await wallet.inPersonTake(bytes));
    } on WalletError catch (e) {
      if (e.kind == WalletErrorKind.codeExpired) {
        _set(InPersonPhase.expired);
        return true;
      }
      return false;
    }
  }

  /// Uses [t], an answer taken for some code. False when it is for another code.
  bool taken(InPersonTaken t) {
    if (t.slateId != _slateId) return false;
    if (_phase != InPersonPhase.waiting) return true;
    _use(t);
    return true;
  }

  void _use(InPersonTaken t) {
    if (t.sameCode) {
      _set(InPersonPhase.sameCode);
    } else {
      _answer = t.answer;
      _checkCode = t.checkCode;
      _set(InPersonPhase.check);
    }
  }

  /// "Matches": finishes the answer and posts it.
  Future<void> matches() async {
    final answer = _answer;
    if (_phase != InPersonPhase.check || answer == null) return;
    error = null;
    _set(InPersonPhase.finishing);
    try {
      tx = await wallet.inPersonFinalize(slateId: _slateId, answer: answer);
      _set(InPersonPhase.done);
    } on WalletError catch (e) {
      if (e.kind == WalletErrorKind.codeExpired) {
        _set(InPersonPhase.expired);
      } else {
        error = e;
        _set(InPersonPhase.check);
      }
    } on Object catch (e) {
      error = e;
      _set(InPersonPhase.check);
    }
  }

  /// "Different": nothing is posted.
  void different() {
    if (_phase == InPersonPhase.check) _set(InPersonPhase.stopped);
  }

  /// "Show a new code": [code] replaces the one shown, waiting again.
  void renew(InPersonCodeMade code) {
    _made = code;
    _slateId = code.slateId;
    parts = wallet.qrParts(code.bytes);
    _answer = null;
    _checkCode = null;
    error = null;
    tx = null;
    _manual = false;
    _fails = 0;
    _set(InPersonPhase.waiting);
    _start();
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}

/// An answer sent through the code's Epicbox server [mailbox] ([Epic1Wallet.inPersonPost]),
/// after the user agreed to the server. [post] starts it; Retry calls it again.
class InPersonAnswerPost extends ChangeNotifier implements InPersonOnline {
  InPersonAnswerPost({required this.wallet, required this.slateId, required this.mailbox, required this.cutoff});

  final Epic1Wallet wallet;
  final String slateId;
  final Epic1Host mailbox;

  @override
  final BigInt cutoff;

  @override
  String get host => mailbox.host;

  InPersonOnlineStep _step = InPersonOnlineStep.posting;
  @override
  InPersonOnlineStep get step => _step;

  /// From the post, once [InPersonOnlineStep.sent].
  String? checkCode;

  /// Counts posts, so a post that ends after Cancel or a newer post is left.
  int _round = 0;
  bool _disposed = false;

  /// The answer goes to the other phone as a QR code and text.
  bool get showAnswer => _step == InPersonOnlineStep.failed || _step == InPersonOnlineStep.cancelled;

  /// Sends the answer.
  Future<void> post() async {
    if (_step == InPersonOnlineStep.sent || _step == InPersonOnlineStep.cancelled) return;
    final round = ++_round;
    _set(InPersonOnlineStep.posting);
    try {
      final code = await wallet.inPersonPost(slateId: slateId, relayOk: true);
      if (round != _round) {
        // It went through after Cancel: the other phone may ask about its check code.
        if (_step == InPersonOnlineStep.cancelled && checkCode == null) {
          checkCode = code;
          if (!_disposed) notifyListeners();
        }
        return;
      }
      checkCode = code;
      _set(InPersonOnlineStep.sent);
    } on Object {
      if (round == _round) _set(InPersonOnlineStep.failed);
    }
  }

  @override
  void cancelOnline() {
    if (_step != InPersonOnlineStep.posting && _step != InPersonOnlineStep.failed) return;
    // A post on its way cannot be stopped: its answer is the one shown, and the other phone
    // takes it once whichever way it comes.
    _round++;
    _set(InPersonOnlineStep.cancelled);
  }

  void _set(InPersonOnlineStep step) {
    _step = step;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
