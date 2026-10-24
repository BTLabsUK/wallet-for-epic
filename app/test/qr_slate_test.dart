// The payment QR transport as the app uses it: the frames the show screen draws, and the
// reader the scan screen feeds. The codec is LEPIC's; the fake service stands in for it here.
// Its error mapping is checked against the generated LEPIC kinds.

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// A payment text long enough for [parts] parts of [qrFragmentLen] bytes.
String _json(int parts, [String tag = 'a']) =>
    '{"id":"$tag","pad":"${tag * (qrFragmentLen * parts - 20)}"}';

void main() {
  final service = FakeWalletService();

  Future<List<String>> encode(String json) =>
      service.encodeQrSlate(json: json, maxFragmentLen: qrFragmentLen);

  group('QrFrames', () {
    test('every frame is the same QR version and the part count is read', () async {
      final texts = await encode(_json(3));
      final frames = QrFrames.of(texts);
      expect(frames.partCount, 3);
      expect(frames.length, texts.length);
      expect({for (final i in frames.images) i.moduleCount}, hasLength(1));
      expect({for (final i in frames.images) i.typeNumber}, hasLength(1));
      expect({for (final i in frames.images) i.maskPattern}, hasLength(1));
      expect(frames.moduleCount, frames.images.first.typeNumber * 4 + 17);
    });

    test('parts are uppercase, the alphanumeric alphabet', () async {
      for (final text in await encode(_json(4))) {
        expect(text, startsWith('UR:EPIC-SLATE/'));
        expect(text, text.toUpperCase());
      }
    });

    test('extra parts show as the part they sit on', () async {
      final frames = QrFrames.of(await encode(_json(3)));
      expect([for (var i = 0; i < frames.length; i++) frames.partOf(i)], [
        0,
        1,
        2,
        0,
        1,
      ]);
    });

    test('a single-part payment is one frame', () async {
      final frames = QrFrames.of(await encode('{"id":"x"}'));
      expect(frames.length, 1);
      expect(frames.partCount, 1);
    });
  });

  group('QrSlateReader', () {
    test('parts in any order complete with the payment text', () async {
      final json = _json(3);
      final texts = await encode(json);
      final reader = QrSlateReader(service);
      final first = await reader.feed(texts[2]);
      expect(first.kind, QrReadKind.part);
      expect((first.received, first.count), (1, 3));
      expect((await reader.feed(texts[0])).received, 2);
      final last = await reader.feed(texts[1]);
      expect(last.kind, QrReadKind.complete);
      expect(last.json, json);
    });

    test('a part seen again changes nothing', () async {
      final texts = await encode(_json(3));
      final reader = QrSlateReader(service);
      await reader.feed(texts[0]);
      expect((await reader.feed(texts[0])).kind, QrReadKind.repeat);
      expect((await reader.feed(texts[0].toLowerCase())).kind, QrReadKind.repeat);
      expect(reader.received, 1);
    });

    test('an address, a link or another wallet code is dropped and the rest is kept', () async {
      final texts = await encode(_json(3));
      final reader = QrSlateReader(service);
      await reader.feed(texts[0]);
      for (final other in [
        'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@epicbox.epiccash.com',
        'https://example.com',
        'UR:BYTES/1-2/LPADAXCFAXIOCYFPFEATAOCYAAAA',
      ]) {
        expect((await reader.feed(other)).kind, QrReadKind.notSlate);
      }
      expect(reader.received, 1);
      expect((await reader.feed(texts[1])).received, 2);
    });

    test('a part of another payment starts reading over', () async {
      final mine = await encode(_json(3));
      final other = await encode(_json(3, 'b'));
      final reader = QrSlateReader(service);
      await reader.feed(mine[0]);
      await reader.feed(mine[1]);
      expect((await reader.feed(other[0])).kind, QrReadKind.otherPayment);
      expect((reader.received, reader.count), (0, 0));
      // The next parts count towards whichever payment is in front of the camera now.
      expect((await reader.feed(other[1])).received, 1);
    });

    test('texts fed together are read in order', () async {
      final texts = await encode(_json(3));
      final reader = QrSlateReader(service);
      final reads = await Future.wait([for (final t in texts) reader.feed(t)]);
      expect(reads[0].kind, QrReadKind.part);
      expect(reads[2].kind, QrReadKind.complete);
      // The two extra parts come after completion and add nothing new to read.
      expect(reads.where((r) => r.kind == QrReadKind.complete), isNotEmpty);
    });
  });

  group('LEPIC error kinds', () {
    test('the five QR kinds map to kinds the screens tell apart', () {
      WalletErrorKind of(lepic.WalletErrorKind kind) =>
          mapLepicError(lepic.WalletError(kind: kind, code: 0, message: 'x')).kind;
      expect(of(lepic.WalletErrorKind.notUrCode), WalletErrorKind.notQrSlate);
      expect(of(lepic.WalletErrorKind.foreignUrCode), WalletErrorKind.foreignQrCode);
      expect(of(lepic.WalletErrorKind.mixedUrCodes), WalletErrorKind.mixedQrCodes);
      expect(of(lepic.WalletErrorKind.invalidUrCode), WalletErrorKind.invalidQrCode);
      expect(of(lepic.WalletErrorKind.urCodeTooLarge), WalletErrorKind.qrCodeTooLarge);
    });
  });
}
