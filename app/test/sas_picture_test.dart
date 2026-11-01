// SPDX-License-Identifier: Apache-2.0
// The pairing pictures: every entry of the word table has its bundled SVG, flutter_svg's parser
// reads each one without a warning, and SasPicture draws it with the word's name as its label.
import 'dart:io';

import 'package:epic_wallet/src/models.dart' show SasWord;
import 'package:epic_wallet/src/sas_table.dart';
import 'package:epic_wallet/src/ui/sas_picture.dart';
import 'package:epic_wallet/src/ui/theme/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;

void main() {
  testWidgets('every table entry has a bundled picture that parses without warnings', (tester) async {
    await tester.runAsync(() async {
      for (final w in sasTable) {
        final asset = sasPictureAsset(w);
        expect(asset, 'assets/sas/${w.name}.svg');
        final xml = await rootBundle.loadString(asset!);
        expect(
          () => vg.encodeSvg(
            xml: xml,
            debugName: asset,
            warningsAsErrors: true,
            enableClippingOptimizer: false,
            enableMaskingOptimizer: false,
            enableOverdrawOptimizer: false,
          ),
          returnsNormally,
          reason: asset,
        );
      }
    });
  });

  test('the folder holds the table\'s pictures and the licence, nothing else', () {
    final files = Directory('assets/sas').listSync().map((f) => f.uri.pathSegments.last).toSet();
    expect(files, {for (final w in sasTable) '${w.name}.svg', 'LICENSE.txt'});
  });

  testWidgets('the pictures\' licence is on the licences page', (tester) async {
    expect(fontLicenceAssets.values, contains('assets/sas/LICENSE.txt'));
    final text = await tester.runAsync(() => rootBundle.loadString('assets/sas/LICENSE.txt'));
    expect(text, contains('Apache License, Version 2.0'));
  });

  testWidgets('a table word is drawn from its SVG, labelled by its name', (tester) async {
    final handle = tester.ensureSemantics();
    final word = sasTable.firstWhere((w) => w.name == 'pretzel');
    await tester.pumpWidget(MaterialApp(home: Center(child: SasPicture(word, size: 48))));
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect((svg.bytesLoader as SvgAssetLoader).assetName, 'assets/sas/pretzel.svg');
    expect(tester.getSize(find.byType(SvgPicture)), const Size(48, 48));
    expect(find.bySemanticsLabel('pretzel'), findsOneWidget);
    expect(find.text(word.emoji), findsNothing);
    handle.dispose();
  });

  testWidgets('a word outside the table falls back to its emoji as text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: SasPicture(SasWord('🥨', 'notaword'), excludeFromSemantics: true))),
    );
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('🥨'), findsOneWidget);
  });
}
