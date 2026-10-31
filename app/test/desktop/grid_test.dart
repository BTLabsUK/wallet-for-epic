// SPDX-License-Identifier: Apache-2.0
// One grid on desktop: panels side by side share their top, bottom
// and header line; every Settings row control is Ctl.sm tall, one of the row widths, and the
// controls of a card end on one right edge; the balance trace is as wide as the balance row.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart' show NodeDemo;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

/// The mock with a balance the test can change.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int spendable = 128473215000;

  @override
  Future<Balance> balance() async {
    final b = await super.balance();
    return Balance(
      spendable: spendable,
      awaitingConfirmation: b.awaitingConfirmation,
      locked: b.locked,
      awaitingFinalization: b.awaitingFinalization,
      immature: b.immature,
    );
  }
}

const _sizes = [Size(1280, 800), Size(1920, 1080)];
const _scales = [100, 125];

/// The real faces, as the screenshot tour loads them: widths measured with the test font (every
/// glyph a square) say nothing about what fits.
Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'), ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf')]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

Future<ProviderContainer> _pump(WidgetTester tester, Size size, int scale, DeskRoute route, {Object? arg, _Wallet? wallet}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => deskScale = deskBase);
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(wallet ?? _Wallet())],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  final s = container.read(deskProvider).settings;
  await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(theme: ThemeChoice.dark, scale: scale)));
  // Outputs is a page of its own only with Advanced › Outputs on (desk_levels.dart outputsPage).
  if (route == DeskRoute.outputs) await tester.runAsync(() => advancedOn(container, only: {AdvancedFeature.outputs}));
  container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

Rect _rect(RenderBox b) => b.localToGlobal(Offset.zero) & b.size;

/// The two columns of the page's [PanelRow] and the bottom line of each column's first header band.
({Rect main, Rect side, double mainHead, double sideHead}) _columns(WidgetTester tester) {
  final row = tester.renderObject<RenderPanelRow>(find.byType(PanelRow));
  final main = _rect(row.firstChild!);
  final side = _rect(row.childAfter(row.firstChild!)!);
  double head(Rect col) {
    final heads = find.byKey(const ValueKey('epanel-head')).evaluate().map((e) => _rect(e.renderObject! as RenderBox)).where((r) => col.contains(r.center)).toList()
      ..sort((a, b) => a.top.compareTo(b.top));
    expect(heads, isNotEmpty, reason: 'a header band in the column at $col');
    return heads.first.bottom;
  }

  return (main: main, side: side, mainHead: head(main), sideHead: head(side));
}

void _expectOneUnit(WidgetTester tester, String what) {
  final c = _columns(tester);
  expect(c.main.top, moreOrLessEquals(c.side.top, epsilon: 0.5), reason: '$what: tops');
  expect(c.main.bottom, moreOrLessEquals(c.side.bottom, epsilon: 0.5), reason: '$what: bottoms');
  expect(c.mainHead, moreOrLessEquals(c.sideHead, epsilon: 0.5), reason: '$what: header lines');
}

const _settingsPages = [
  DeskRoute.settingsReceiving,
  DeskRoute.settingsAppearance,
  DeskRoute.settingsAccount,
  DeskRoute.settingsWallets,
  DeskRoute.settingsRescan,
  DeskRoute.settingsAbout,
  DeskRoute.settingsHelp,
];

/// The row widths on the page shown: control sizes, nothing cut short, one right edge per card.
void _expectRowControls(WidgetTester tester, String what) {
  final widths = [Ctl.rowW, Ctl.rowWide];
  for (final e in find.byType(ERowControl).evaluate()) {
    final r = _rect(e.renderObject! as RenderBox);
    expect(r.height, moreOrLessEquals(Ctl.sm, epsilon: 0.5), reason: '$what: a row control is Ctl.sm tall (${e.widget})');
    expect(widths.any((w) => (w - r.width).abs() < 0.5), isTrue, reason: '$what: a row control is ${r.width} wide, not one of $widths');
    final paragraphs = find.descendant(of: find.byWidget(e.widget), matching: find.byType(RichText));
    for (final p in paragraphs.evaluate()) {
      final rp = p.renderObject! as RenderParagraph;
      expect(rp.didExceedMaxLines, isFalse, reason: '$what: "${rp.text.toPlainText()}" is cut short (${rp.size}, ${rp.constraints})');
    }
  }
  // Every row control (button, dropdown, field, segmented choice) goes through ERowControl.
  for (final e in find.byType(ESetRow).evaluate()) {
    final row = e.widget as ESetRow;
    if (row.control == null || row.stacked) continue;
    // A control sized to its words (Theme, Send starts on) wraps under the title instead.
    if (row.wrap) continue;
    final inRow = find.descendant(of: find.byWidget(row), matching: find.byWidget(row.control!));
    final ok = [ERowControl, ESwitch, EBadge].any((t) => find.descendant(of: inRow, matching: find.byType(t), matchRoot: true).evaluate().isNotEmpty);
    expect(ok, isTrue, reason: '$what: the control of "${row.title ?? row.text}" is not an ERowControl');
  }
  // One right edge per card.
  for (final g in find.byType(ESetGroup).evaluate()) {
    final edges = <double>[];
    for (final e in find.descendant(of: find.byWidget(g.widget), matching: find.byType(ESetRow)).evaluate()) {
      final row = e.widget as ESetRow;
      if (row.control == null || row.stacked) continue;
      final ctl = find.descendant(of: find.byWidget(row), matching: find.byWidget(row.control!)).evaluate().first;
      final r = _rect(ctl.renderObject! as RenderBox);
      // A wrap row whose control went under the title has no right edge to share.
      if (row.wrap && r.top >= _rect(find.descendant(of: find.byWidget(row), matching: find.text(row.title!)).evaluate().first.renderObject! as RenderBox).bottom) continue;
      edges.add(r.right);
    }
    for (final x in edges) {
      expect(x, moreOrLessEquals(edges.first, epsilon: 0.5), reason: '$what: right edges in "${(g.widget as ESetGroup).title}": $edges');
    }
  }
}

void main() {
  setUpAll(_loadFonts);
  for (final size in _sizes) {
    for (final scale in _scales) {
      final at = '${size.width.toInt()}x${size.height.toInt()} at $scale %';

      testWidgets('Activity and the detail are one unit, $at', (tester) async {
        // The newest transactions: a full page of rows beside a short and a long detail.
        for (final id in [39, 36]) {
          await _pump(tester, size, scale, DeskRoute.activity, arg: id);
          _expectOneUnit(tester, 'Activity, tx $id, $at');
          expect(tester.takeException(), isNull);
          await _done(tester);
        }
      });

      testWidgets('Send and its summary are one unit, $at', (tester) async {
        await _pump(tester, size, scale, DeskRoute.send);
        if (find.byType(PanelRow).evaluate().isEmpty) {
          // Under 720 u of page the Summary goes below the form: one column, same edges.
          final panels = find.byType(EPanel).evaluate().map((e) => _rect(e.renderObject! as RenderBox)).toList();
          final summary = _rect(find.ancestor(of: find.text('Summary'), matching: find.byType(EPanel)).evaluate().first.renderObject! as RenderBox);
          expect(panels.first.left, moreOrLessEquals(summary.left, epsilon: 0.5));
          expect(panels.first.width, moreOrLessEquals(summary.width, epsilon: 0.5));
          expect(summary.top, greaterThan(panels.first.bottom));
        } else {
          _expectOneUnit(tester, 'Send, $at');
        }
        expect(tester.takeException(), isNull);
        await _done(tester);
      });

      testWidgets('Contacts: the list and the detail share top and bottom, $at', (tester) async {
        await _pump(tester, size, scale, DeskRoute.contacts);
        await tester.tap(find.text('Anna Kowalska').first);
        await _settle(tester);
        final row = tester.renderObject<RenderPanelRow>(find.byType(PanelRow));
        final a = _rect(row.firstChild!);
        final b = _rect(row.childAfter(row.firstChild!)!);
        expect(a.top, moreOrLessEquals(b.top, epsilon: 0.5));
        expect(a.bottom, moreOrLessEquals(b.bottom, epsilon: 0.5));
        expect(a.right, lessThan(b.left), reason: 'the list comes first, at the start');
        _expectOneUnit(tester, 'Contacts, $at');
        expect(tester.takeException(), isNull);
        await _done(tester);
      });

      testWidgets('Outputs: Split and Consolidate buttons on one line, one size, $at', (tester) async {
        await _pump(tester, size, scale, DeskRoute.outputs);
        final split = tester.getRect(find.widgetWithText(EButton, 'Split…'));
        final cons = tester.getRect(find.widgetWithText(EButton, 'Consolidate…'));
        expect(split.size.width, moreOrLessEquals(cons.size.width, epsilon: 0.5));
        expect(split.size.height, moreOrLessEquals(cons.size.height, epsilon: 0.5));
        // Side by side from 860 u of page: one line. Stacked below that.
        if (split.right < cons.left) {
          expect(split.top, moreOrLessEquals(cons.top, epsilon: 0.5), reason: 'side by side: one line');
        } else {
          expect(cons.top, greaterThan(split.bottom), reason: 'stacked');
        }
        if (size.width == 1920) expect(split.right, lessThan(cons.left), reason: 'side by side at $at');
        expect(tester.takeException(), isNull);
        await _done(tester);
      });

      testWidgets('Settings row controls share sizes and edges, $at', (tester) async {
        for (final (route, arg) in [for (final r in _settingsPages) (r, null), (DeskRoute.settingsNode, null), (DeskRoute.settingsNode, NodeDemo.builtin)]) {
          await _pump(tester, size, scale, route, arg: arg);
          _expectRowControls(tester, '${route.name} ${arg ?? ''}, $at');
          expect(tester.takeException(), isNull, reason: route.name);
          await _done(tester);
        }
      });

      testWidgets('the balance trace follows the balance row, $at', (tester) async {
        final wallet = _Wallet();
        final container = await _pump(tester, size, scale, DeskRoute.overview, wallet: wallet);
        double rowW() => tester.getSize(find.byKey(const ValueKey('balance-row'))).width;
        double traceW() => tester.getSize(find.byKey(const ValueKey('balance-trace'))).width;
        expect(traceW(), moreOrLessEquals(rowW(), epsilon: 1));
        final before = rowW();
        wallet.spendable = 5000000;
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        await tester.pump(const Duration(seconds: 1));
        await _settle(tester);
        expect(rowW(), lessThan(before));
        expect(traceW(), moreOrLessEquals(rowW(), epsilon: 1));
        expect(tester.takeException(), isNull);
        await _done(tester);
      });
    }
  }

  // A German or Russian system locale must still leave every page above whole.
  for (final locale in const [Locale('de'), Locale('ru')]) {
    testWidgets('no overflow with the system locale ${locale.languageCode}', (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      for (final route in [DeskRoute.activity, DeskRoute.send, DeskRoute.overview, ..._settingsPages]) {
        for (final scale in _scales) {
          await _pump(tester, _sizes.first, scale, route, arg: route == DeskRoute.activity ? 39 : null);
          expect(tester.takeException(), isNull, reason: '${route.name} at $scale %');
          await _done(tester);
        }
      }
    });
  }
}
