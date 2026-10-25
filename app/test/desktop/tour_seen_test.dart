// Build 6: the tour opens by itself once, not on every start (its seen flag is saved with the
// app's settings), and the compact rail shows the version with the build.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart' show deskAppVersion;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh app start on [store]: its settings read before the first frame, as main does.
Future<ProviderContainer> _start(DeskStore store) async {
  final boot = await DeskBoot.load(store);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      deskStoreProvider.overrideWithValue(store),
      deskBootProvider.overrideWithValue(boot),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('tour seen', () {
    test('a first start has not seen it; once opened, the next start has', () async {
      final store = DeskStore(MemorySecretStore());
      final first = await _start(store);
      expect(first.read(deskTourProvider).seen, isFalse);
      first.read(deskTourProvider.notifier).open();
      await pumpEventQueue();
      first.read(deskTourProvider.notifier).close();

      final second = await _start(store);
      expect(second.read(deskTourProvider), isA<DeskTourState>().having((t) => t.seen, 'seen', isTrue).having((t) => t.open, 'open', isFalse));
      expect((await store.settings()).tourSeen, isTrue);
    });

    test('closed before it ever opened (a quick lock) it still counts as unseen', () async {
      final store = DeskStore(MemorySecretStore());
      final first = await _start(store);
      first.read(deskTourProvider.notifier).close();
      await pumpEventQueue();
      expect(first.read(deskTourProvider).seen, isFalse);
      expect((await _start(store)).read(deskTourProvider).seen, isFalse);
    });

    test('Show the tour (reset, open) opens it again after a restart', () async {
      final store = DeskStore(MemorySecretStore());
      await store.saveSettings(const DeskSettings(tourSeen: true));
      final c = await _start(store);
      expect(c.read(deskTourProvider).seen, isTrue);
      c.read(deskTourProvider.notifier)
        ..reset()
        ..open();
      expect(c.read(deskTourProvider).open, isTrue);
      await pumpEventQueue();
      expect((await store.settings()).tourSeen, isTrue);
    });

    test('a saved value of the wrong type falls back to unseen', () {
      expect(deskSettingsFromJson({'tourSeen': 'yes'}).tourSeen, isFalse);
      expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings(tourSeen: true))).tourSeen, isTrue);
    });
  });

  testWidgets('the compact rail shows the version with the build', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(980, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))], retry: (_, _) => null);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await tester.pump(const Duration(milliseconds: 600));

    // The rail's part of the title bar: the mark, the build in its tooltip.
    expect(find.byTooltip('Epic Cash Desktop $deskAppVersion'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
