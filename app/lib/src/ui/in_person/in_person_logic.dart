// SPDX-License-Identifier: Apache-2.0
/// The in-person payments (spec D3, D5, P3, P5, P6) without their widgets, for the phone and
/// the desktop: what a scanned or pasted text is, and a code on screen waiting for its answer.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../epic1.dart';
import '../../models.dart';

/// How often a code on screen asks for its answers.
const Duration inPersonPollEvery = Duration(seconds: 3);

/// How long each part of an animated QR code shows.
const Duration inPersonFrameEvery = Duration(milliseconds: 250);

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

/// A code this wallet shows, waiting for its answer: asks [Epic1Wallet.inPersonAnswers] every
/// [inPersonPollEvery] while it waits, and takes answers pasted or scanned back.
class InPersonCodeWatch extends ChangeNotifier {
  InPersonCodeWatch({required this.wallet, required this.stage, required BigInt this.amount, required InPersonCodeMade made, this.pollEvery = inPersonPollEvery})
    : _made = made,
      _slateId = made.slateId {
    _start();
  }

  /// An answer pasted or scanned outside its code's screen ([Epic1Wallet.inPersonTake]): the
  /// check question at once, no code to show.
  InPersonCodeWatch.answered({required this.wallet, required InPersonTaken taken})
    : stage = taken.stage,
      amount = null,
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
  bool _asking = false;
  bool _disposed = false;

  /// The QR parts of the code.
  late List<String> parts = switch (_made) {
    final made? => wallet.qrParts(made.bytes),
    null => const [],
  };

  void _start() {
    _poll?.cancel();
    _poll = Timer.periodic(pollEvery, (_) => unawaited(poll()));
  }

  void _set(InPersonPhase phase) {
    _phase = phase;
    if (phase != InPersonPhase.waiting) _poll?.cancel();
    if (!_disposed) notifyListeners();
  }

  /// Asks for the answers once.
  Future<void> poll() async {
    if (_phase != InPersonPhase.waiting || _asking) return;
    _asking = true;
    final slateId = _slateId;
    try {
      final status = await wallet.inPersonAnswers(slateId);
      if (_disposed || _phase != InPersonPhase.waiting || slateId != _slateId) return;
      if (status.answers.any((a) => a.sameCode)) {
        _set(InPersonPhase.sameCode);
      } else if (status.answers.isNotEmpty) {
        final a = status.answers.first;
        _answer = a.number;
        _checkCode = a.checkCode;
        _set(InPersonPhase.check);
      }
    } on WalletError catch (e) {
      if (!_disposed && e.kind == WalletErrorKind.codeExpired) _set(InPersonPhase.expired);
      // Else the server did not answer this time: the next ask tries again.
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
    _set(InPersonPhase.waiting);
    _start();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    super.dispose();
  }
}
