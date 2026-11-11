// SPDX-License-Identifier: Apache-2.0
// The QR codes the wallet shows, on the real LEPIC codec: payment files (`ur:epic-slate`) and
// in-person codes and answers, encoded with the app's limits (qrFragmentLen, qrSingleCodeMaxLen),
// every part read back, and every frame drawn at level H no larger than version 14 (73 modules).
// The payment slates in test/fixtures/qr_slates come from a floonet send and invoice of LEPIC's
// test wallets, with a message. The wallet writes payment codes as deflated text (version 1),
// which every release reads, and reads native codes (version 2) too; s1.v1-64.parts is that S1
// as an app up to 26.11.3 showed it (deflated text, 64-byte parts). Needs a LEPIC Linux library, the release one or
// LEPIC's mock build (lepic-flutter's `tool/lepic.sh test` makes it in test_native/):
//
//   WFE_LEPIC_LIB=<path to liblepic_ffi.so> flutter test test/qr_dense_lepic_test.dart
//
// WFE_LEPIC_MOCK_LIB works too. Without either it is skipped.
import 'dart:io';
import 'dart:math';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:lepic/src/rust/api/in_person.dart' as lepic_in_person;

final String? _lib = Platform.environment['WFE_LEPIC_LIB'] ?? Platform.environment['WFE_LEPIC_MOCK_LIB'];

/// The largest frame the wallet draws: version 14.
const int _maxModules = 73;

const String _slates = 'test/fixtures/qr_slates';

/// [length] bytes that do not compress, the same on every run, behind the magic LEPIC checks:
/// a native slate's (a code) or an envelope's (an answer).
List<int> _bytes(int length, int seed, {bool answer = false}) {
  final random = Random(seed);
  return [0x89, 0x45, 0x53, answer ? 0x45 : 0x4C, for (var i = 4; i < length; i++) random.nextInt(256)];
}

/// A payment text of about [length] characters that does not compress.
String _json(int length, int seed) {
  final random = Random(seed);
  const hex = '0123456789abcdef';
  final pad = String.fromCharCodes([for (var i = 0; i < length; i++) hex.codeUnitAt(random.nextInt(16))]);
  return '{"id":"$seed","pad":"$pad"}';
}

void main() {
  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  List<String> inPerson(List<int> bytes) => lepic_in_person.inPersonQrParts(
    bytes: bytes,
    maxFragmentLen: qrFragmentLen,
    singleCodeMaxLen: qrSingleCodeMaxLen,
  );

  void expectFrames(List<String> parts, int partCount) {
    final frames = QrFrames.of(parts);
    expect(frames.partCount, partCount);
    expect(frames.moduleCount, lessThanOrEqualTo(_maxModules));
    expect({for (final i in frames.images) i.typeNumber}, hasLength(1));
  }

  group('in-person codes', () {
    // A send code, an invoice code and the pay answer, at the sizes LEPIC makes them.
    for (final (name, length, partCount, answer) in [
      ('a short code', 60, 1, false),
      ('the longest single code', 118, 1, false),
      ('a send code', 196, 2, false),
      ('an invoice code', 321, 4, false),
      ('a pay answer', 1152, 11, true),
    ]) {
      test('$name ($length bytes) reads back and every frame fits version 14', () {
        final bytes = _bytes(length, length, answer: answer);
        final parts = inPerson(bytes);
        expectFrames(parts, partCount);
        final read = lepic_in_person.inPersonQrRead(parts: parts);
        expect(read.complete, isTrue);
        expect(read.bytes, bytes);
        // Each part on its own is a code the reader takes.
        for (final part in parts) {
          expect(lepic_in_person.inPersonQrRead(parts: [part]).fragmentCount, partCount);
        }
      });
    }

    test('without the app limit a code up to 360 bytes stays one code, as before', () {
      final parts = lepic_in_person.inPersonQrParts(bytes: _bytes(321, 1), maxFragmentLen: qrFragmentLen);
      expect(parts, hasLength(1));
      expect(lepic_in_person.inPersonQrRead(parts: parts).complete, isTrue);
    });
  }, skip: _lib == null ? 'needs WFE_LEPIC_LIB' : null);

  group('payment files', () {
    Future<List<String>> encode(String json, {bool native = qrPaymentNative}) => lepic.encodeUrSlate(
      json: json,
      chain: lepic.Chain.floonet,
      native: native,
      maxFragmentLen: qrFragmentLen,
      singleCodeMaxLen: qrSingleCodeMaxLen,
    );

    test('the wallet writes payment codes as deflated text, which older apps read', () {
      expect(qrPaymentNative, isFalse);
    });

    // The parts each stage takes as deflated text (what the wallet writes) and as lepic.v1
    // bytes (what it reads as well), and the stage the text read back has.
    for (final (name, textParts, nativeParts, stage) in [
      ('s1', 14, 3, lepic.SlateStage.s1),
      ('s2', 23, 17, lepic.SlateStage.s2),
      ('s3', 25, 19, lepic.SlateStage.s3),
      ('i1', 14, 3, lepic.SlateStage.i1),
      ('i2', 24, 18, lepic.SlateStage.i2),
    ]) {
      for (final (form, native, partCount) in [('text', false, textParts), ('native', true, nativeParts)]) {
        test('a real $name as $form reads back as the same slate and every frame fits version 14', () async {
          final json = File('$_slates/$name.json').readAsStringSync();
          final parts = await encode(json, native: native);
          expectFrames(parts, partCount);
          final read = await lepic.decodeUrSlate(parts: parts);
          expect(read.complete, isTrue);
          final (got, shown) = (
            await lepic.inspectSlate(json: read.json!, chain: lepic.Chain.floonet),
            await lepic.inspectSlate(json: json, chain: lepic.Chain.floonet),
          );
          expect(got.stage, stage);
          expect((got.slateId, got.amount, got.fee), (shown.slateId, shown.amount, shown.fee));
          // Text reads back as the very text written.
          if (!native) expect(read.json, json);
        });
      }
    }

    test('a code an older app showed, deflated text in 64-byte parts, still reads', () async {
      final parts = File('$_slates/s1.v1-64.parts').readAsLinesSync();
      final read = await lepic.decodeUrSlate(parts: parts);
      expect(read.complete, isTrue);
      expect(read.json, File('$_slates/s1.json').readAsStringSync());
    });

    // Text that is not a slate goes as deflated text.
    for (final (name, length) in [('a short payment', 40), ('a long payment', 4000)]) {
      test('$name that is not a slate reads back and every frame fits version 14', () async {
        final json = _json(length, length);
        final parts = await encode(json);
        final partCount = QrFrames.of(parts).partCount;
        expect(partCount, length < 100 ? 1 : greaterThan(10));
        expectFrames(parts, partCount);
        final read = await lepic.decodeUrSlate(parts: parts);
        expect(read.complete, isTrue);
        expect(read.json, json);
      });
    }
  }, skip: _lib == null ? 'needs WFE_LEPIC_LIB' : null);
}
