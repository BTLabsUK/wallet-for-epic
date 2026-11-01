// SPDX-License-Identifier: Apache-2.0
// Wallet levels in the desktop shell: the rail, the wallet chip, the status icons and their
// popovers, the Settings side list and the route guard, at Shallow and at Deep end (today's app).
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart' show OverviewScreen;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, WalletLevel level, {DeskRoute start = DeskRoute.overview}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskStartProvider.overrideWithValue(start),
      deskLevelProvider.overrideWithValue(level),
      // One wallet on this computer.
      deskLevelUiProvider.overrideWithValue(DeskLevelFeatures.of(level, prefs: const AdvancedPrefs(), wallets: 1)),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(seconds: 1));
  return container;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

Finder _rail(String label) => find.descendant(of: find.byType(ENavItem), matching: find.text(label));

void main() {
  group('Shallow', () {
    testWidgets('six rail items, the name without a menu, Network and Epicbox, a popover without For support or Copy details', (tester) async {
      await _pump(tester, WalletLevel.justSendReceive);
      for (final l in ['Overview', 'Activity', 'Contacts', 'Send', 'Receive', 'Settings']) {
        expect(_rail(l), findsOneWidget, reason: l);
      }
      expect(_rail('Outputs'), findsNothing);
      expect(_rail('Invoices'), findsNothing);
      expect(find.byKey(const ValueKey('bar-wallet')), findsNothing);
      expect(find.byKey(const ValueKey('bar-wallet-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-node')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-epicbox')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-http')), findsNothing);
      expect(find.byKey(const ValueKey('bar-status-tor')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('bar-status-node')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('status-pop-node')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('status-row-node')), matching: find.text('Network')), findsOneWidget);
      expect(find.text('For support'), findsNothing);
      expect(find.byKey(const ValueKey('status-copy-node')), findsNothing);
      expect(find.byKey(const ValueKey('status-switch-node')), findsOneWidget);
      expect(find.byKey(const ValueKey('status-open-node')), findsNothing, reason: 'no settings page to open at Shallow');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('status-pop-node')), findsNothing);
      await _end(tester);
    });

    testWidgets('Settings: six entries, Recheck balance from This wallet; hidden pages read as the landing', (tester) async {
      final c = await _pump(tester, WalletLevel.justSendReceive, start: DeskRoute.settingsAccount);
      Finder side(String l) => find.descendant(of: find.byType(ESubnav), matching: find.text(l));
      for (final l in ['Appearance', 'This wallet', 'Security', 'Advanced', 'About', 'Help']) {
        expect(side(l), findsOneWidget, reason: l);
      }
      for (final l in ['Node', 'Transactions', 'Privacy', 'All wallets', 'Recheck balance']) {
        expect(side(l), findsNothing, reason: l);
      }
      expect(find.byKey(const ValueKey('account-recheck')), findsOneWidget);

      c.read(deskNavProvider.notifier).go(DeskRoute.settingsNode);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Interface scale'), findsOneWidget, reason: 'Settings › Node reads as Appearance');
      c.read(deskNavProvider.notifier).go(DeskRoute.outputs);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(OverviewScreen), findsOneWidget, reason: 'Outputs reads as Overview');
      await _end(tester);
    });
  });

  group('Deep end', () {
    testWidgets("today's rail, wallet menu and four status icons with a settings button", (tester) async {
      await _pump(tester, WalletLevel.everything);
      expect(find.byKey(const ValueKey('bar-wallet')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-node')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-epicbox')), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-status-http')), findsOneWidget);
      if (DeskFeatures.tor) expect(find.byKey(const ValueKey('bar-status-tor')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('status-open-epicbox')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 500));
      await _end(tester);
    });

    testWidgets("Settings: today's side list", (tester) async {
      await _pump(tester, WalletLevel.everything, start: DeskRoute.settingsAccount);
      Finder side(String l) => find.descendant(of: find.byType(ESubnav), matching: find.text(l));
      for (final l in ['Node', 'Transactions', 'Network & privacy', 'Appearance', 'This wallet', 'All wallets', 'Security', 'Recheck balance', 'Advanced', 'About', 'Help']) {
        expect(side(l), findsOneWidget, reason: l);
      }
      expect(find.byKey(const ValueKey('account-recheck')), findsNothing);
      await _end(tester);
    });
  });
}
