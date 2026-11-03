// SPDX-License-Identifier: Apache-2.0
// The Receive from the internet guide opens from the (?) beside the Internet address and changes
// nothing by itself; opening it is saved app-wide as seen. The Internet switch never opens it.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_http.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

final _l = englishStrings;

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

  final help = find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Receive from the internet: how it works');
  final internetSwitch = find.byKey(const ValueKey('http-public-switch'));

  Future<void> openGuide(WidgetTester tester) async {
    await tester.ensureVisible(help);
    await tester.tap(help);
    await settle(tester);
  }

  Future<void> flipInternet(WidgetTester tester) async {
    await tester.ensureVisible(internetSwitch);
    await tester.tap(internetSwitch);
    await settle(tester);
  }

  testWidgets('the Internet switch turns it on and off at once; the guide never opens by itself', (tester) async {
    var container = await show(tester);
    await flipInternet(tester);
    expect(find.byType(InternetGuide), findsNothing);
    expect(container.read(deskProvider).settings.publicMode, isTrue);
    await flipInternet(tester);
    expect(find.byType(InternetGuide), findsNothing);
    expect(container.read(deskProvider).settings.publicMode, isFalse);
    expect(container.read(deskProvider).settings.internetGuideSeen, isFalse);

    // The (?) saves that the guide was seen, app-wide: a new app start with the same store.
    await openGuide(tester);
    expect(container.read(deskProvider).settings.internetGuideSeen, isTrue);
    await tester.pumpWidget(const SizedBox());
    container = await show(tester);
    expect(container.read(deskProvider).settings.internetGuideSeen, isTrue);
  });

  testWidgets('the (?) opens the guide and changes nothing by itself', (tester) async {
    final container = await show(tester);
    await openGuide(tester);
    expect(find.byType(InternetGuide), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Close'));
    await settle(tester);
    expect(container.read(deskProvider).settings.publicMode, isFalse);
    // Open again from the (?) after it was seen.
    await openGuide(tester);
    expect(find.byType(InternetGuide), findsOneWidget);
  });

  testWidgets('the guide\'s buttons switch: Receive from the internet on, Back to local only off', (tester) async {
    final container = await show(tester);
    await openGuide(tester);
    await tester.tap(find.widgetWithText(EButton, _l.deskSetHttpGuideTitle));
    await settle(tester);
    expect(find.byType(InternetGuide), findsNothing);
    expect(container.read(deskProvider).settings.publicMode, isTrue);
    await openGuide(tester);
    await tester.tap(find.widgetWithText(EButton, 'Back to local only'));
    await settle(tester);
    expect(container.read(deskProvider).settings.publicMode, isFalse);
  });

  test('the seen flag is saved app-wide and read back', () {
    final j = deskSettingsToJson(const DeskSettings(internetGuideSeen: true));
    expect(deskSettingsFromJson(j).internetGuideSeen, isTrue);
    expect(deskSettingsFromJson(const {}).internetGuideSeen, isFalse);
  });
}
