// SPDX-License-Identifier: Apache-2.0
// The Settings navigation moves while a search has words, and lists Contacts.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/screens/settings/search/search_slot.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_appearance.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/trust_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _open(WidgetTester tester, DeskRoute route, Size size, {WalletLevel? level}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
    if (level != null) deskLevelProvider.overrideWithValue(level),
  ], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(route);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  for (final size in const [Size(1280, 800), Size(1000, 700)]) {
    // The owner on Windows: with words in the search, the navigation seemed dead until it was
    // cleared, as the results stood in for every page.
    testWidgets('a Settings entry opens its page while the search has words, $size', (tester) async {
      final container = await _open(tester, DeskRoute.settingsHelp, size);
      final field = find.byKey(SettingsSearchSlot.fieldKey);
      await tester.tap(field);
      await _settle(tester);
      await tester.enterText(find.descendant(of: field, matching: find.byType(EditableText)), 'tor');
      await _settle(tester);
      expect(find.byType(SettingsSearchResults), findsOneWidget);
      // At 700 high the status cards under the Settings list cover it: scroll to the entry.
      await tester.ensureVisible(find.text('Appearance').first);
      await _settle(tester);
      await tester.tap(find.text('Appearance').first);
      await _settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAppearance);
      expect(container.read(settingsQueryProvider), isEmpty);
      expect(find.byType(SettingsSearchResults), findsNothing);
      expect(find.byType(SettingsAppearanceScreen), findsOneWidget);
    });

    testWidgets('Help search keeps the navigation working, $size', (tester) async {
      final container = await _open(tester, DeskRoute.settingsHelp, size);
      final field = find.descendant(of: find.byType(SettingsHelpScreen), matching: find.byType(EditableText));
      await tester.tap(field);
      await _settle(tester);
      await tester.enterText(field, 'tor');
      await _settle(tester);
      // At 700 high the status cards under the Settings list cover it: scroll to the entry.
      await tester.ensureVisible(find.text('Appearance').first);
      await _settle(tester);
      await tester.tap(find.text('Appearance').first);
      await _settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.settingsAppearance);
      expect(find.byType(SettingsAppearanceScreen), findsOneWidget);
    });

    testWidgets('Settings lists Contacts, which opens the Contacts page, at the Shallow view, $size', (tester) async {
      final container = await _open(tester, DeskRoute.settingsAccount, size, level: WalletLevel.ofNumber(1));
      final entry = find.byWidgetPredicate((w) => w is TrustId && w.id == TrustIds.settingsSection(DeskRoute.contacts.name));
      expect(entry, findsOneWidget);
      await tester.tap(entry, warnIfMissed: true);
      await _settle(tester);
      expect(container.read(deskNavProvider).route, DeskRoute.contacts);
    });
  }
}
