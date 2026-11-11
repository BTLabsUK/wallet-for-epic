// SPDX-License-Identifier: Apache-2.0
/// Paying in person by QR: a payment file as an animated code (LEPIC's `ur:epic-slate`
/// transport, behind [WalletService.encodeQrSlate] and [WalletService.decodeQrSlate]), the
/// frames the show screen draws, and the reader the scan screen feeds.
library;

import 'dart:async';

import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'wallet_service.dart';

export 'wallet_service.dart' show qrFragmentLen, qrPaymentNative, qrSingleCodeMaxLen;

/// Frames a second the show screen cycles the parts at.
const int qrFramesPerSecond = 6;

/// Milliseconds a frame stays.
const int qrFrameMs = 1000 ~/ qrFramesPerSecond;

/// Seconds the code stays visible once shown.
const int qrShowSeconds = 40;

/// The numerals before the code appears: 3, 2, 1.
const int qrCountdownSeconds = 3;

/// The last seconds, when the time line turns to a warning.
const int qrLowSeconds = 10;

/// Seconds without a new part, while reading, before the scanner says to hold steady.
const int qrHoldSteadySeconds = 4;

/// The quiet zone around the modules, as the QR standard asks.
const int qrQuietModules = 4;

/// The parts of one code as drawable modules, all in the same QR version and mask, so the
/// finder and alignment patterns never move between frames. Level H, as every code the wallet
/// shows: a logo covers the centre (`LogoQr`). Payment files and in-person codes and answers
/// draw this way.
class QrFrames {
  QrFrames._(this.texts, this.images, this.partCount);

  /// Draws [texts], the parts of one animated code. A `ur:` text is case-insensitive, so it is
  /// drawn uppercase in the alphanumeric mode, the smallest code; any other text in byte mode.
  factory QrFrames.of(List<String> texts) {
    assert(texts.isNotEmpty);
    final alpha = texts.every(_alphanumeric);
    var version = 1;
    for (final text in texts) {
      version = _versionOf(text, version, alpha);
    }
    QrImage image(String text, [int? mask]) {
      final code = _code(version, text, alpha);
      return mask == null ? QrImage(code) : QrImage.withMaskPattern(code, mask);
    }

    final first = image(texts.first);
    final images = [
      first,
      for (final text in texts.skip(1)) image(text, first.maskPattern),
    ];
    return QrFrames._(texts, images, partCountOf(texts.first) ?? texts.length);
  }

  /// Whether [text] is a UR text whose uppercase form is all QR alphanumeric characters.
  static bool _alphanumeric(String text) =>
      text.length > 3 &&
      text.substring(0, 3).toUpperCase() == 'UR:' &&
      _alphanumericText.hasMatch(text.toUpperCase());

  static final RegExp _alphanumericText = RegExp(r'^[0-9A-Z $%*+\-./:]*$');

  static QrCode _code(int version, String text, bool alpha) {
    final code = QrCode(version, QrErrorCorrectLevel.H);
    return alpha ? (code..addAlphaNumeric(text.toUpperCase())) : (code..addData(text));
  }

  /// The smallest version at least [from] that holds [text].
  static int _versionOf(String text, int from, bool alpha) {
    for (var version = from; version <= 40; version++) {
      try {
        QrImage.withMaskPattern(_code(version, text, alpha), 0);
        return version;
      } on InputTooLongException {
        continue;
      }
    }
    throw ArgumentError('part too long for a QR code');
  }

  final List<String> texts;
  final List<QrImage> images;

  /// The parts one pass of the code has (`7` in `UR:EPIC-SLATE/3-7/…`).
  final int partCount;

  int get length => images.length;
  int get moduleCount => images.first.moduleCount;

  /// Which part [frame] shows, from 0 to [partCount] - 1; the extra parts after the plain
  /// ones show as the plain part they sit on.
  int partOf(int frame) {
    final seq = partNumberOf(texts[frame % length]);
    return seq == null ? frame % partCount : (seq - 1) % partCount;
  }
}

final RegExp _partHeader = RegExp(
  r'^UR:EPIC-SLATE/(\d+)-(\d+)/',
  caseSensitive: false,
);

/// `3` of `UR:EPIC-SLATE/3-7/…`, or null.
int? partNumberOf(String text) {
  final m = _partHeader.firstMatch(text.trim());
  return m == null ? null : int.tryParse(m[1]!);
}

/// `7` of `UR:EPIC-SLATE/3-7/…`, or null.
int? partCountOf(String text) {
  final m = _partHeader.firstMatch(text.trim());
  return m == null ? null : int.tryParse(m[2]!);
}

/// Whether [text] starts like a payment QR. The decoder has the final word.
bool looksLikeQrSlate(String text) =>
    text.trim().toUpperCase().startsWith('UR:EPIC-SLATE/');

/// What one scanned text did to the reader.
enum QrReadKind {
  /// The same text as one already read: the camera sees the same frame several times.
  repeat,

  /// Not a payment QR (an address, a link, another wallet's code): dropped, state kept.
  notSlate,

  /// A part of another payment than the one being read: the reader started over.
  otherPayment,

  /// A payment QR the wallet cannot read (damaged, or too large): dropped, state kept.
  unreadable,

  /// A new part of the payment being read.
  part,

  /// Every part is read; [QrRead.json] holds the payment text.
  complete,
}

class QrRead {
  const QrRead(this.kind, {this.received = 0, this.count = 0, this.json});

  final QrReadKind kind;
  final int received;
  final int count;
  final String? json;
}

/// Collects the scanned texts of one payment. Holds the distinct texts and asks the wallet's
/// decoder about all of them each time; texts are fed one at a time, in order.
class QrSlateReader {
  QrSlateReader(this._service);

  final WalletService _service;
  final Set<String> _parts = {};
  Future<void> _tail = Future.value();

  int received = 0;
  int count = 0;

  /// Reads [raw], after the texts fed before it.
  Future<QrRead> feed(String raw) {
    final done = _tail.then((_) => _read(raw));
    _tail = done.then((_) {}, onError: (_) {});
    return done;
  }

  void reset() {
    _parts.clear();
    received = 0;
    count = 0;
  }

  Future<QrRead> _read(String raw) async {
    final text = raw.trim().toUpperCase();
    if (!looksLikeQrSlate(text)) return const QrRead(QrReadKind.notSlate);
    if (_parts.contains(text)) return const QrRead(QrReadKind.repeat);
    try {
      final p = await _service.decodeQrSlate(parts: [..._parts, text]);
      _parts.add(text);
      received = p.received;
      count = p.count;
      final json = p.json;
      if (p.complete && json != null) {
        return QrRead(
          QrReadKind.complete,
          received: received,
          count: count,
          json: json,
        );
      }
      return QrRead(QrReadKind.part, received: received, count: count);
    } on WalletError catch (error) {
      switch (error.kind) {
        case WalletErrorKind.mixedQrCodes:
          reset();
          return const QrRead(QrReadKind.otherPayment);
        case WalletErrorKind.notQrSlate:
        case WalletErrorKind.foreignQrCode:
          return const QrRead(QrReadKind.notSlate);
        case WalletErrorKind.invalidQrCode:
        case WalletErrorKind.qrCodeTooLarge:
          // The parts held so far cannot make a payment (one of them was forged or damaged,
          // or they grew past the limit): start over, so the code in front of the camera
          // can still be read instead of failing on every frame until the screen closes.
          reset();
          return const QrRead(QrReadKind.unreadable);
        default:
          rethrow;
      }
    }
  }
}
