// SPDX-License-Identifier: Apache-2.0
// The phone's payment scanner (Home's scan of an animated code) on the real LEPIC codec: an
// in-person code is drawn as `ur:epic-slate` parts too and tells itself apart from a payment
// only once every part is read. The reader given the epic1 calls hands a whole in-person code
// on; without them it refuses it as before. The part below is frame 3 of 4 of the in-person
// request the desktop showed (12 EPIC, a note, answer by Epicbox), read from its screenshot.
//
//   WFE_LEPIC_LIB=<path to liblepic_ffi.so> flutter test test/smart_scanner_lepic_test.dart
//
// WFE_LEPIC_MOCK_LIB works too. Without either it is skipped.
import 'dart:io';
import 'dart:math';

import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:lepic/src/rust/api/in_person.dart' as lepic_in_person;

final String? _lib = Platform.environment['WFE_LEPIC_LIB'] ?? Platform.environment['WFE_LEPIC_MOCK_LIB'];
final String? _skip = _lib == null ? 'needs WFE_LEPIC_LIB' : null;

const String _screenshotPart =
    'UR:EPIC-SLATE/3-4/LPAXAACFADGACYSREEDATNHDGUKTIHIHJPKTJPIYFGBDFSJNASCNRHSWAOLSGSFTLTSGGSAAGWDTGHMELDIHPKFXDKFHYTJSRSGMISNNEMMEHPVAWYBBKBFPWTIHOTRPCTJODSEYPLDEIOSTVDDEVLZESAPFGMDPUEMKYTAEAEAEAEADAECXGMGATKSNTSWKCAEYWMPE';

/// The epic1 calls with LEPIC's QR reader, as the open wallet's.
class _LepicQr extends FakeEpic1 {
  @override
  InPersonQrProgress qrRead(List<String> parts) {
    final p = lepic_in_person.inPersonQrRead(parts: parts);
    return InPersonQrProgress(complete: p.complete, received: p.receivedFragments, total: p.fragmentCount, bytes: p.bytes);
  }
}

/// [length] bytes behind the magic of an in-person code, the same on every run.
List<int> _code(int length) {
  final random = Random(length);
  return [0x89, 0x45, 0x53, 0x4C, for (var i = 4; i < length; i++) random.nextInt(256)];
}

/// The plain parts of in-person code [bytes], as the camera reads them, uppercase.
List<String> _plain(List<int> bytes) {
  final parts = lepic_in_person.inPersonQrParts(bytes: bytes, maxFragmentLen: qrFragmentLen, singleCodeMaxLen: qrSingleCodeMaxLen);
  return [for (final p in parts.take(partCountOf(parts.first)!)) p.toUpperCase()];
}

void main() {
  late LepicWalletService service;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
    service = LepicWalletService(secrets: MemorySecretStore());
  });

  /// What the reader made of each part, fed in order.
  Future<List<QrRead>> feed(QrSlateReader reader, List<String> parts) async => [for (final part in parts) await reader.feed(part)];

  test('the screenshot part reads as part 3 of 4 in both readers', () async {
    final read = await QrSlateReader(service, epic1: _LepicQr()).feed(_screenshotPart);
    expect(read.kind, QrReadKind.part);
    expect(read.count, 4);
    final own = lepic_in_person.inPersonQrRead(parts: [_screenshotPart]);
    expect(own.complete, isFalse);
    expect(own.fragmentCount, 4);
  }, skip: _skip);

  test('a whole in-person code in four parts is handed on with its bytes', () async {
    final bytes = _code(321);
    // The four plain parts; the extra fountain parts after them repeat what they hold.
    final parts = _plain(bytes);
    expect(partCountOf(parts.first), 4);
    final reads = await feed(QrSlateReader(service, epic1: _LepicQr()), parts);
    expect([for (final r in reads) r.kind], [QrReadKind.part, QrReadKind.part, QrReadKind.part, QrReadKind.inPerson]);
    expect(reads.last.bytes, bytes);
  }, skip: _skip);

  test('without the epic1 calls the whole in-person code is refused as no payment, as before', () async {
    final reads = await feed(QrSlateReader(service), _plain(_code(321)));
    // What the phone said: "That is not a payment QR".
    expect(reads.last.kind, QrReadKind.notSlate);
  }, skip: _skip);

  test('a classic payment still completes; the in-person reader refuses it and the payment decoder reads it', () async {
    final json = File('test/fixtures/qr_slates/s1.json').readAsStringSync();
    final parts = await lepic.encodeUrSlate(json: json, maxFragmentLen: qrFragmentLen, singleCodeMaxLen: qrSingleCodeMaxLen);
    final reads = await feed(QrSlateReader(service, epic1: _LepicQr()), parts);
    expect(reads.last.kind, QrReadKind.complete);
    expect(reads.last.json, json);
    // What the in-person scanner checks before it says "classic code".
    expect(() => _LepicQr().qrRead(parts), throwsA(anything));
    final read = await service.decodeQrSlate(parts: parts);
    expect(read.complete, isTrue);
  }, skip: _skip);
}
