// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_corner_marks.dart';
import 'package:epic_wallet/src/ui/kit/kit_icons.dart';
import 'package:epic_wallet/src/ui/kit/kit_slot_card.dart';
import 'package:epic_wallet/src/ui/kit/kit_row.dart';
import 'package:epic_wallet/src/ui/kit/kit_sheet.dart';
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: buildWalletTheme(protocolDark, Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
  home: Scaffold(body: home),
);

void main() {
  group('KitButton', () {
    testWidgets('a small button keeps its 36 look and takes taps in a 44 area', (tester) async {
      var taps = 0;
      const key = ValueKey('small');
      await tester.pumpWidget(
        _app(Center(child: SizedBox(height: 120, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [KitButton(key: key, label: 'Copy', small: true, expand: false, onPressed: () => taps++)])))),
      );
      final box = tester.getRect(find.byKey(key));
      expect(box.height, Kit.buttonSmall, reason: 'the look and the layout stay 36');
      // The band counts where the parent reaches past the button (a card, a row with a taller
      // sibling); a parent that wraps the button at 36 cuts it, as for any child.
      // 4 px above and below the visible box is inside the 44 area; 6 px is outside it.
      await tester.tapAt(Offset(box.center.dx, box.top - 3.5));
      await tester.tapAt(Offset(box.center.dx, box.bottom + 3.5));
      expect(taps, 2);
      await tester.tapAt(Offset(box.center.dx, box.top - 6));
      await tester.tapAt(Offset(box.center.dx, box.bottom + 6));
      expect(taps, 2);
    });

    testWidgets('a long label takes a second line at a large text size and nothing overflows', (tester) async {
      const key = ValueKey('long');
      await tester.pumpWidget(
        _app(
          const SizedBox(width: 300, child: Column(mainAxisSize: MainAxisSize.min, children: [KitButton(key: key, label: 'Send the whole payment through the other address', onPressed: _noop)])),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(key)).height, greaterThan(Kit.button), reason: 'the button grows to fit');
      final text = tester.renderObject<RenderParagraph>(find.text('Send the whole payment through the other address'));
      final lines = text.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.text.toPlainText().length)).map((b) => b.top.round()).toSet();
      expect(lines.length, 2, reason: 'two lines, centred');
    });

    testWidgets('a short label at text scale 1 stays on one line at the frame height', (tester) async {
      const key = ValueKey('short');
      await tester.pumpWidget(_app(const Column(mainAxisSize: MainAxisSize.min, children: [KitButton(key: key, label: 'Continue', onPressed: _noop)])));
      expect(tester.getSize(find.byKey(key)).height, Kit.button);
      await tester.pumpWidget(_app(const Column(mainAxisSize: MainAxisSize.min, children: [KitButton(key: key, label: 'Cancel', kind: KitButtonKind.ghost, onPressed: _noop)])));
      expect(tester.getSize(find.byKey(key)).height, Kit.hitMin);
    });
  });

  group('the slot cards', () {
    testWidgets('the quiet needs-you card has no gold fill and no corner marks, its Review is quiet', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              KitNeedsYouCard(key: const ValueKey('gold'), title: 'Invoice', reviewLabel: 'Review', laterLabel: 'Later', onReview: _noop),
              KitNeedsYouCard(key: const ValueKey('info'), title: 'Invoice', reviewLabel: 'Review', laterLabel: 'Later', onReview: _noop, info: true),
            ],
          ),
        ),
      );
      final gold = find.byKey(const ValueKey('gold'));
      final info = find.byKey(const ValueKey('info'));
      expect(find.descendant(of: gold, matching: find.byType(KitCornerMarks)), findsOneWidget);
      expect(find.descendant(of: info, matching: find.byType(KitCornerMarks)), findsNothing);
      KitButtonKind review(Finder card) => tester.widget<KitButton>(find.descendant(of: card, matching: find.widgetWithText(KitButton, 'Review'))).kind;
      expect(review(gold), KitButtonKind.gold);
      expect(review(info), KitButtonKind.quiet);
      final t = tester.element(info).tokens;
      final box = tester.widget<Container>(find.descendant(of: info, matching: find.byType(Container)).first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, t.group);
      expect((decoration.border! as Border).top.color, t.info.withValues(alpha: 0.4));
      final icon = tester.widget<Icon>(find.descendant(of: info, matching: find.byIcon(KitIcons.invoice)));
      expect(icon.color, t.info);
    });

    testWidgets('the reminder card is 90 tall, its link and its cross do their own thing', (tester) async {
      var acted = 0;
      var closed = 0;
      await tester.pumpWidget(
        _app(
          KitReminderCard(
            key: const ValueKey('r'),
            icon: KitIcons.security,
            text: 'Your recovery phrase is not backed up. Without it, a lost phone means a lost wallet.',
            action: 'Back up now',
            onAction: () => acted++,
            closeLabel: 'Close',
            onClose: () => closed++,
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('r'))).height, greaterThanOrEqualTo(Kit.slotCard));
      await tester.tap(find.text('Back up now'));
      expect(acted, 1);
      expect(closed, 0);
      await tester.tap(find.byIcon(KitIcons.close));
      expect(closed, 1);
      expect(acted, 1);
      final t = tester.element(find.text('Back up now')).tokens;
      expect(tester.widget<Text>(find.text('Back up now')).style!.color, t.accentText);
    });
  });

  group('KitRow disabled state', () {
    double opacityOf(WidgetTester tester, Key key) {
      final op = find.descendant(of: find.byKey(key), matching: find.byType(Opacity));
      return op.evaluate().isEmpty ? 1 : tester.widget<Opacity>(op.first).opacity;
    }

    testWidgets('a row with a chevron and no tap is dimmed and reads as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const KitRow(key: ValueKey('chev'), title: 'Export', chevron: true)));
      expect(opacityOf(tester, const ValueKey('chev')), Kit.disabledOpacity);
      final data = tester.getSemantics(find.text('Export')).getSemanticsData();
      expect(data.flagsCollection.isEnabled.name, 'isFalse');
      handle.dispose();
    });

    testWidgets('an explicit enabled: false dims a row with no chevron', (tester) async {
      await tester.pumpWidget(_app(const KitRow(key: ValueKey('off'), title: 'Delete', enabled: false)));
      expect(opacityOf(tester, const ValueKey('off')), Kit.disabledOpacity);
    });

    testWidgets('a switch row with no handler is dimmed once', (tester) async {
      await tester.pumpWidget(_app(KitRow.toggle(key: const ValueKey('sw'), title: 'Tor', value: true, onChanged: null)));
      expect(opacityOf(tester, const ValueKey('sw')), Kit.disabledOpacity);
      // The switch inside does not dim itself a second time.
      final inner = find.descendant(of: find.byKey(const ValueKey('sw')), matching: find.byType(Opacity)).evaluate().skip(1);
      expect(inner.map((e) => (e.widget as Opacity).opacity), everyElement(1));
    });

    testWidgets('an info row and a tappable row are not dimmed', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              const KitRow(key: ValueKey('info'), title: 'Version', value: '1.0'),
              KitRow(key: const ValueKey('tap'), title: 'Open', chevron: true, onTap: () {}),
              const KitRow(key: ValueKey('on'), title: 'Open', chevron: true, enabled: true),
            ],
          ),
        ),
      );
      expect(opacityOf(tester, const ValueKey('info')), 1);
      expect(opacityOf(tester, const ValueKey('tap')), 1);
      expect(opacityOf(tester, const ValueKey('on')), 1);
    });
  });

  group('KitPickerSheet', () {
    Future<void> open(WidgetTester tester, FutureOr<void> Function(int) save, {String? subtitle}) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => KitPickerSheet.show<int>(
                  context: context,
                  title: 'Lock after',
                  subtitle: subtitle,
                  selected: 1,
                  choices: const [KitChoice(value: 1, title: 'One'), KitChoice(value: 2, title: 'Two')],
                  onSelected: save,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a failed save keeps the sheet open and says so', (tester) async {
      await open(tester, (v) async => throw StateError('disk full'));
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Lock after'), findsOneWidget, reason: 'the sheet stays');
      expect(find.text('Not saved. Try again.'), findsOneWidget);
    });

    testWidgets('a save that works waits for the setter, then closes', (tester) async {
      final saved = <int>[];
      await open(tester, (v) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        saved.add(v);
      });
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(find.text('Lock after'), findsOneWidget, reason: 'still open while it saves');
      await tester.pumpAndSettle();
      expect(saved, [2]);
      expect(find.text('Lock after'), findsNothing);
    });

    testWidgets('the subtitle is the 13 px hint, dim, with 1.45 line height', (tester) async {
      await open(tester, (v) {}, subtitle: 'Lock the wallet');
      final style = tester.widget<Text>(find.text('Lock the wallet')).style!;
      expect(style.fontSize, 13);
      expect(style.height, 1.45);
      expect(style.color, protocolDark.dim);
    });
  });
}

void _noop() {}
