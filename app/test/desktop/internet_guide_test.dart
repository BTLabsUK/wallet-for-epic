// SPDX-License-Identifier: Apache-2.0
// The Receive from the internet guide shows the first time From the internet is picked, then
// never again by itself (app-wide, saved); the (?) opens it any time and changes nothing.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_http.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

void main() {
  late MemorySecretStore secrets;
  late DeskStore store;

  setUp(() {
    secrets = MemorySecretStore();
    store = DeskStore(secrets);
  });

  Future<ProviderContainer> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boot = (await tester.runAsync(() => DeskBoot.load(store)))!;
    // The app hands the boot settings to the API (as main does for the real wallet).
    final api = MockDeskWallet(delay: Duration.zero);
    await tester.runAsync(() => api.saveSettings(boot.settings));
    final container = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(api),
        deskStoreProvider.overrideWithValue(store),
        deskBootProvider.overrideWithValue(boot),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsReceivingScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }

  Future<void> pickInternet(WidgetTester tester) async {
    await tester.ensureVisible(find.text('From the internet'));
    await tester.tap(find.text('From the internet'));
    await settle(tester);
  }

  testWidgets('first pick shows the guide; later picks switch straight, also after a restart', (tester) async {
    var container = await show(tester);
    await pickInternet(tester);
    expect(find.byType(InternetGuide), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Close'));
    await settle(tester);
    expect(container.read(deskProvider).settings.publicMode, isFalse, reason: 'Close changes nothing');
    expect(container.read(deskProvider).settings.internetGuideSeen, isTrue);

    await pickInternet(tester);
    expect(find.byType(InternetGuide), findsNothing);
    expect(container.read(deskProvider).settings.publicMode, isTrue);

    // A new app start with the same store: still seen.
    await tester.pumpWidget(const SizedBox());
    container = await show(tester);
    expect(container.read(deskProvider).settings.internetGuideSeen, isTrue);
    await tester.tap(find.text('Local only'));
    await settle(tester);
    await pickInternet(tester);
    expect(find.byType(InternetGuide), findsNothing);
    expect(container.read(deskProvider).settings.publicMode, isTrue);
  });

  testWidgets('the (?) opens the guide and changes nothing by itself', (tester) async {
    final container = await show(tester);
    final help = find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Receive from the internet: how it works');
    await tester.ensureVisible(help);
    await tester.tap(help);
    await settle(tester);
    expect(find.byType(InternetGuide), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Close'));
    await settle(tester);
    expect(container.read(deskProvider).settings.publicMode, isFalse);
    // Seen once from the (?) too: the next pick switches straight.
    await pickInternet(tester);
    expect(find.byType(InternetGuide), findsNothing);
    // Open again from the (?) after it was seen.
    await tester.tap(help);
    await settle(tester);
    expect(find.byType(InternetGuide), findsOneWidget);
  });

  test('the seen flag is saved app-wide and read back', () {
    final j = deskSettingsToJson(const DeskSettings(internetGuideSeen: true));
    expect(deskSettingsFromJson(j).internetGuideSeen, isTrue);
    expect(deskSettingsFromJson(const {}).internetGuideSeen, isFalse);
  });
}
