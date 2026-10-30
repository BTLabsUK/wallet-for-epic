// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('interface scale applies at once to text and layout', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => deskScale = deskBase);
    final container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAppearance);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await tester.pump(const Duration(seconds: 1));

    // Selectable text wraps its paragraph in a MouseRegion: measure the paragraph itself.
    double titleSize() => tester
        .renderObject<RenderParagraph>(find.descendant(of: find.text('Interface scale').first, matching: find.byType(RichText)))
        .textSize
        .height;
    expect(deskScale, deskBase);
    expect(Sp.x4, 17);
    final at100 = titleSize();

    for (final scale in [150, 90]) {
      final s = container.read(deskProvider).settings;
      await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(scale: scale)));
      await tester.pump(const Duration(seconds: 1));
      expect(deskScale, scale / 100 * deskBase);
      expect(Sp.x4, (16 * deskScale).roundToDouble());
      if (scale == 150) expect(titleSize(), greaterThan(at100 * 1.3));
      if (scale == 90) expect(titleSize(), lessThan(at100));
      expect(tester.takeException(), isNull);
    }
    // Back to the default for the other tests in this run.
    final s = container.read(deskProvider).settings;
    await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(scale: 100)));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
