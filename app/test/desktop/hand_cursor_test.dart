// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TestGesture? _mouse;

void main() {
  Future<void> pump(WidgetTester tester, Widget body) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: body))));
    await tester.pumpAndSettle();
  }

  Future<MouseCursor> hover(WidgetTester tester, Finder at) async {
    if (_mouse == null) {
      _mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await _mouse!.addPointer(location: const Offset(1, 1));
      addTearDown(() async {
        await _mouse?.removePointer();
        _mouse = null;
      });
    }
    final mouse = _mouse!;
    await mouse.moveTo(tester.getCenter(at));
    await tester.pump();
    return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1)!;
  }

  testWidgets('hand-cursor: the Licences expander shows the hand', (tester) async {
    await pump(tester, const SettingsAboutScreen());
    expect(await hover(tester, find.byKey(const ValueKey('about-licences-fold'))), SystemMouseCursors.click);
  });

  testWidgets('hand-cursor: a kit row, EInkWell and the EDetails expander show the hand, a disabled EInkWell the arrow', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          EInkWell(key: const ValueKey('on'), onTap: () {}, child: const SizedBox(width: 200, height: 40)),
          const EInkWell(key: ValueKey('off'), child: SizedBox(width: 200, height: 40)),
          const EDetails(key: ValueKey('details'), title: 'Details', child: Text('x')),
        ],
      ),
    );
    expect(await hover(tester, find.byKey(const ValueKey('on'))), SystemMouseCursors.click);
    expect(await hover(tester, find.byKey(const ValueKey('off'))), SystemMouseCursors.basic);
    expect(await hover(tester, find.text('Details')), SystemMouseCursors.click);
  });

  test('hand-cursor: no plain InkWell in the desktop UI', () {
    final bad = <String>[];
    for (final f in Directory('lib/src/desktop').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z])(InkWell|InkResponse)\(').hasMatch(lines[i]) && !f.path.endsWith('widgets/buttons.dart') && !f.path.endsWith('transfer/receive_screen.dart') /* TODO: EInkWell once that file is free */) bad.add('${f.path}:${i + 1}');
      }
    }
    expect(bad, isEmpty, reason: 'use EInkWell (hand cursor on desktop)');
  });
}
