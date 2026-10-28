// SPDX-License-Identifier: Apache-2.0
// The pairing word tiles never cut a name: the longest names of the table in
// every slot, the five pairing words and the four-word check on a 360 dp phone, the desktop's
// small tiles and its words check dialog. Each name is laid out whole, on one line, inside its
// slot.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart' show showDeskCheckWords;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/models.dart' show PairingState, SasWord;
import 'package:epic_wallet/src/sas_table.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart' show buildWalletTheme, protocolDark;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The table's longest names, longest first.
final List<SasWord> _longest = ([...sasTable]..sort((a, b) => b.name.length.compareTo(a.name.length))).take(5).toList();

/// Every name on screen is laid out whole on one line and stays inside its tile's slot.
void _namesWhole(WidgetTester tester, List<SasWord> words) {
  for (final w in words) {
    final text = find.text(w.name);
    expect(text, findsWidgets, reason: w.name);
    for (final e in text.evaluate()) {
      final paragraph = e.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse, reason: '${w.name} is cut');
      // Scaled down to fit, never wider than its slot.
      final shown = tester.getRect(find.byElementPredicate((x) => x == e));
      final slot = tester.getRect(find.ancestor(of: find.byElementPredicate((x) => x == e), matching: find.byType(FittedBox)).first);
      expect(shown.width, lessThanOrEqualTo(slot.width + 0.01), reason: w.name);
      expect(shown.left, greaterThanOrEqualTo(slot.left - 0.01), reason: w.name);
    }
  }
}

Future<void> _phone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildWalletTheme(protocolDark, Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(initializeDateFormatting);

  test('the longest names are the ones the acceptance found cut', () {
    expect(_longest.map((w) => w.name), containsAll(['toothbrush', 'flashlight']));
  });

  testWidgets('five pairing words, the longest names, at 360 dp', (tester) async {
    await _phone(tester, WordTiles(words: [for (var i = 0; i < 5; i++) sasWordNamed('toothbrush')!], label: 'words'));
    expect(tester.takeException(), isNull);
    _namesWhole(tester, [sasWordNamed('toothbrush')!]);
    await _phone(tester, WordTiles(words: _longest, label: 'words'));
    expect(tester.takeException(), isNull);
    _namesWhole(tester, _longest);
  });

  testWidgets('the four-word check at 360 dp', (tester) async {
    final four = _longest.take(4).toList();
    await _phone(tester, WordTiles(words: four, label: 'check', size: WordTileSize.check));
    expect(tester.takeException(), isNull);
    _namesWhole(tester, four);
  });

  testWidgets('the desktop: small tiles in the code panel, and the words check dialog', (tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final mock = MockDeskWallet(delay: Duration.zero);
    final four = _longest.take(4).toList();
    final r = mock.pairing.seedPaired(name: 'Northwind', state: PairingState.paired, sas: four);
    final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(mock)]);
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  // The code panel's words column is 340 wide.
                  SizedBox(width: 340, child: WordTiles(words: _longest, label: 'words', size: WordTileSize.small)),
                  TextButton(onPressed: () => showDeskCheckWords(context, ref, r.id), child: const Text('check')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    _namesWhole(tester, _longest);
    await tester.tap(find.text('check'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    _namesWhole(tester, four);
  });
}
