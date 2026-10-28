// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// §0 task 1: ESignalBars and EMethodIcon at the four tones, ESegmented md + stretch.
// Regenerate with `flutter test --no-pub --update-goldens test/desktop/status_widgets_test.dart`.

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('EpicStatusIcons')..addFont(read('assets/fonts/EpicStatusIcons.ttf'))).load();
}

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildDeskTheme(Brightness.dark),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  setUpAll(_loadFonts);

  test('state mapping', () {
    expect(stateOf(ServiceHealth.ok), EState.ok);
    expect(stateOf(ServiceHealth.slow), EState.warn);
    // Checking is in progress (blue), not a warning.
    expect(stateOf(ServiceHealth.checking), EState.active);
    expect(stateOf(ServiceHealth.down), EState.risk);
    expect(stateOf(ServiceHealth.off), EState.off);
    expect([for (final s in EState.values) stateBars(s)], [3, 2, 2, 1, 0]);
    expect(methodIcon(TxMethod.tor), EIcons.tor);
  });

  testWidgets('bars, method icons and status glyphs at every state (golden)', (tester) async {
    // Five states: ok, in progress, warn, risk, off; the glyph's second cue.
    tester.view.physicalSize = const Size(560, 440);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in EState.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ESignalBars(s),
                      const SizedBox(width: 16),
                      for (final m in TxMethod.values) ...[EMethodIcon(m, s), const SizedBox(width: 10)],
                      const SizedBox(width: 6),
                      EStatusGlyph(icon: EIcons.node, state: s, label: s.name),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(find.byType(ESignalBars).first), Size(16.u, 14.u));
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/status_widgets.png'));
  });

  Color barColor(WidgetTester tester, int i) {
    final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(ESignalBars), matching: find.byType(CustomPaint)));
    return (paint.painter as dynamic).colors[i] as Color;
  }

  for (final reduce in [false, true]) {
    testWidgets('bars light upwards, dim downwards${reduce ? ', swap with reduced motion' : ''}', (tester) async {
      final state = ValueNotifier(EState.off);
      await tester.pumpWidget(_app(ValueListenableBuilder(valueListenable: state, builder: (_, s, _) => ESignalBars(s)), reduce: reduce));
      const c = deskDark;
      expect(barColor(tester, 0), c.lineStrong);
      state.value = EState.ok;
      await tester.pump();
      if (reduce) {
        expect([for (var i = 0; i < 3; i++) barColor(tester, i)], everyElement(c.ok));
      } else {
        await tester.pump(const Duration(milliseconds: 60));
        // 60 ms in: the bottom bar is on its way, the top one has not started.
        expect(barColor(tester, 0), isNot(c.lineStrong));
        expect(barColor(tester, 0), isNot(c.ok));
        expect(barColor(tester, 2), c.lineStrong);
        await tester.pump(const Duration(milliseconds: 200));
        expect([for (var i = 0; i < 3; i++) barColor(tester, i)], everyElement(c.ok));
      }
      state.value = EState.risk;
      await tester.pump();
      if (!reduce) {
        await tester.pump(const Duration(milliseconds: 30));
        // Dimming runs downwards: the top bar goes first, the middle one starts at 40 ms.
        expect(barColor(tester, 2), isNot(c.ok));
        expect(barColor(tester, 1), c.ok);
        await tester.pump(const Duration(milliseconds: 230));
      }
      expect([barColor(tester, 0), barColor(tester, 1), barColor(tester, 2)], [c.risk, c.lineStrong, c.lineStrong]);
    });
  }

  for (final reduce in [false, true]) {
    testWidgets('an in-progress glyph pulses a few beats, then stops drawing${reduce ? ' (reduced motion: never pulses)' : ''}', (tester) async {
      // A pulse that never ended redrew the window 60 times a second for as long as
      // Epicbox over Tor kept retrying.
      await tester.pumpWidget(_app(const Center(child: EStatusGlyph(icon: EIcons.epicbox, state: EState.active, label: 'Epicbox: Connecting')), reduce: reduce));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.hasScheduledFrame, !reduce);
      if (!reduce) {
        final fade = tester.widget<FadeTransition>(find.descendant(of: find.byType(EStatusGlyph), matching: find.byType(FadeTransition)).last);
        expect(fade.opacity.value, lessThan(1));
      }
      // Still the same state, well past the beats: nothing left to draw, full opacity.
      await tester.pump(const Duration(milliseconds: 1600) * statusPulseBeats);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      final fades = find.descendant(of: find.byType(EStatusGlyph), matching: find.byType(FadeTransition));
      if (!reduce) expect(tester.widget<FadeTransition>(fades.last).opacity.value, 1);
      // A rebuild in the same state does not start it again.
      await tester.pumpWidget(_app(const Center(child: EStatusGlyph(icon: EIcons.epicbox, state: EState.active, label: 'Epicbox: Connecting, again')), reduce: reduce));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('ESegmented md + stretch is 44 u tall and fills its width', (tester) async {
    tester.view.physicalSize = const Size(600, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 480,
            child: ESegmented<TxMethod>(
              size: EBtnSize.md,
              stretch: true,
              segments: [for (final m in TxMethod.values) ESegment(m, m.name, icon: methodIcon(m))],
              value: TxMethod.epicbox,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final box = tester.getSize(find.byType(ESegmented<TxMethod>));
    expect(box, Size(480, Ctl.md));
    // Equal shares.
    final widths = [for (final m in TxMethod.values) tester.getSize(find.ancestor(of: find.text(m.name), matching: find.byType(AnimatedContainer))).width];
    expect(widths.toSet().length, 1);
    expect(tester.takeException(), isNull);
  });
}
