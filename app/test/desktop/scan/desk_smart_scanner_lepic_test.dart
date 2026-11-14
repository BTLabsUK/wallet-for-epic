// SPDX-License-Identifier: Apache-2.0
// The desktop's scan readers on the real LEPIC codec: an epic1 in-person code and a classic
// payment share the `ur:epic-slate` code type and tell themselves apart only once whole. The
// payment reader of classic mode refuses a whole in-person code with the mode line; the
// in-person reader of epic1 mode ends on a whole classic payment as `classic`.
//
//   WFE_LEPIC_LIB=<path to liblepic_ffi.so> flutter test test/desktop/scan/desk_smart_scanner_lepic_test.dart
//
// Without WFE_LEPIC_LIB (or WFE_LEPIC_MOCK_LIB) it is skipped.
import 'dart:io';
import 'dart:math';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_reader.dart';
import 'package:epic_wallet/src/desktop/screens/scan/desk_scan.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/qr_payment.dart';
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_scan.dart' show InPersonScanned;
import 'package:epic_wallet/src/wallet_service.dart' show QrSlateProgress;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;
import 'package:lepic/src/rust/api/in_person.dart' as lepic_in_person;

final String? _lib = Platform.environment['WFE_LEPIC_LIB'] ?? Platform.environment['WFE_LEPIC_MOCK_LIB'];
final String? _skip = _lib == null ? 'needs WFE_LEPIC_LIB' : null;

class _LepicQr extends FakeEpic1 {
  @override
  InPersonQrProgress qrRead(List<String> parts) {
    final p = lepic_in_person.inPersonQrRead(parts: parts);
    return InPersonQrProgress(complete: p.complete, received: p.receivedFragments, total: p.fragmentCount, bytes: p.bytes);
  }
}

/// The desktop wallet with LEPIC's payment decoder.
class _Api extends MockDeskWallet {
  _Api(this.service) : super(delay: Duration.zero);
  final LepicWalletService service;

  @override
  Future<QrSlateProgress> decodeQrSlate(List<String> parts) => service.decodeQrSlate(parts: parts);
}

List<String> _inPersonParts(int length) {
  final random = Random(length);
  final bytes = [0x89, 0x45, 0x53, 0x4C, for (var i = 4; i < length; i++) random.nextInt(256)];
  final parts = lepic_in_person.inPersonQrParts(bytes: bytes, maxFragmentLen: qrFragmentLen, singleCodeMaxLen: qrSingleCodeMaxLen);
  return [for (final p in parts.take(partCountOf(parts.first)!)) p.toUpperCase()];
}

void main() {
  late LepicWalletService service;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
    service = LepicWalletService(secrets: MemorySecretStore());
  });

  test('classic mode: a whole in-person code is refused with the epic1 mode line', () async {
    final reader = DeskSlateQrReader(_Api(service), notSlate: (l) => l.deskQrNotTx, epic1: _LepicQr());
    final steps = [for (final p in _inPersonParts(321)) await reader.read(p)];
    expect(steps.take(3), everyElement(isA<DeskPartWaiting<String>>()));
    final last = steps.last;
    expect(last, isA<DeskPartRefused<String>>());
    expect((last as DeskPartRefused<String>).message(englishStrings), englishStrings.deskE1ModeEpic1Code);
    // Without the epic1 calls it is "not a transaction code", what the desktop said before.
    final before = DeskSlateQrReader(_Api(service), notSlate: (l) => l.deskQrNotTx);
    final old = [for (final p in _inPersonParts(321)) await before.read(p)].last;
    expect((old as DeskPartRefused<String>).message(englishStrings), englishStrings.deskQrNotTx);
  }, skip: _skip);

  test('epic1 mode: a whole classic payment ends the in-person scan as classic', () async {
    final json = File('test/fixtures/qr_slates/s1.json').readAsStringSync();
    final parts = await lepic.encodeUrSlate(json: json, maxFragmentLen: qrFragmentLen, singleCodeMaxLen: qrSingleCodeMaxLen);
    final reader = DeskInPersonReader(_LepicQr(), classic: _Api(service).decodeQrSlate);
    DeskPartStep<InPersonScanned>? last;
    for (final p in parts) {
      last = await reader.read(p);
      if (last is DeskPartDone) break;
    }
    expect(last, isA<DeskPartDone<InPersonScanned>>());
    expect((last! as DeskPartDone<InPersonScanned>).value.classic, isTrue);
  }, skip: _skip);
}
