// SPDX-License-Identifier: Apache-2.0
// The key picture against the spec's vectors (docs/design/key-picture-vectors.json, written by
// tools/key_picture_vectors.py): every picture, every link, the constants.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/key_picture.dart';
import 'package:epic_wallet/src/ui/key_picture.dart';

Uint8List _bytes(String hex) => Uint8List.fromList([for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);

String _hex(Uint8List b) => [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();

String _css(int argb) => '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';

void main() {
  final vectors = jsonDecode(File('../docs/design/key-picture-vectors.json').readAsStringSync()) as Map<String, dynamic>;

  test('constants match the spec', () {
    expect(keyPictureLabel, vectors['label']);
    expect(_css(keyPictureTile), vectors['tile']);
    expect([for (final c in keyPicturePalette) _css(c)], vectors['palette']);
    final listed = [
      for (final k in vectors['btlabs_keys'] as List) (k as Map<String, dynamic>),
    ];
    expect([for (final k in btLabsKeys) (k.keyHex, k.name, k.logo)], [for (final k in listed) (k['key'], k['name'], k['logo'])]);
  });

  group('pictures', () {
    for (final v in (vectors['pictures'] as List).cast<Map<String, dynamic>>()) {
      test(v['key'] as String, () {
        final p = KeyPicture.of(_bytes(v['key'] as String));
        expect(_hex(p.seed), v['seed']);
        expect(p.colour, v['colour']);
        expect(_css(p.colourValue), v['hex']);
        expect(p.cells, v['cells']);
        expect(p.grid, v['grid']);
      });
    }
  });

  group('links', () {
    for (final v in (vectors['links'] as List).cast<Map<String, dynamic>>()) {
      test(v['why'] as String? ?? v['link'] as String, () {
        final key = inviteKeyOf(v['link'] as String);
        expect(key == null ? null : _hex(key), v['key']);
      });
    }

    test('padding in the payload is accepted', () {
      final link = (vectors['links'] as List).cast<Map<String, dynamic>>().first['link'] as String;
      final padded = link + '=' * (-(link.length - link.indexOf('/1/') - 3) % 4);
      expect(inviteKeyOf(padded), inviteKeyOf(link));
    });

    test('text that is no invite has no key', () {
      expect(inviteKeyOf(''), isNull);
      expect(inviteKeyOf('epiccash://pair/1/'), isNull);
      expect(inviteKeyOf('epiccash://pair/1/!!!!'), isNull);
    });
  });

  test('BT Labs keys are found by their bytes', () {
    final faucet = _bytes(btLabsKeys.first.keyHex);
    expect(btLabsKeyOf(faucet)?.name, 'BT Labs Faucet');
    expect(btLabsKeyOf(Uint8List(32)), isNull);
  });

  testWidgets('framed grows by the bracket offset on each side; the check is labelled', (tester) async {
    final picture = KeyPicture.of(Uint8List(32));
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            KeyPictureView(key: const ValueKey('plain'), picture: picture, size: 72),
            KeyPictureView(key: const ValueKey('framed'), picture: picture, size: 72, framed: true),
            const VerifiedCheck(label: 'Verified BT Labs service', colour: Colors.green),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('plain'))), const Size.square(72));
    final o = KeyPictureView.frameOffsetOf(72);
    expect(tester.getSize(find.byKey(const ValueKey('framed'))), Size.square(72 + 2 * o));
    expect(find.bySemanticsLabel('Verified BT Labs service'), findsOneWidget);
    expect(find.byTooltip('Verified BT Labs service'), findsOneWidget);
  });
}
