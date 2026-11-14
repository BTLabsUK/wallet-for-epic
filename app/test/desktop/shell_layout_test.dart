// SPDX-License-Identifier: Apache-2.0
// The desktop shell: the tabs, the wallet menu, the status lights and their popovers, the
// Settings side list and the route guard.
import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart' show deskInvoiceBadgeProvider;
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart' show OverviewScreen;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {DeskRoute start = DeskRoute.overview, int invoicesToAnswer = 0}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskStartProvider.overrideWithValue(start),
      deskInvoiceBadgeProvider.overrideWithValue(invoicesToAnswer),
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

// A tab of the title bar by its label (a narrow window shows the selected tab's label only).
Finder _rail(String label) => find.byWidgetPredicate((w) => w is ETab && w.label == label);

void main() {
  testWidgets('an invoice to answer brings Invoices to the tabs', (tester) async {
    await _pump(tester, invoicesToAnswer: 1);
    expect(_rail('Invoices'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('the tabs, the wallet menu and the status lights; a popover opens its settings', (tester) async {
    await _pump(tester);
    for (final l in ['Home', 'Activity', 'Contacts', 'Settings']) {
      expect(_rail(l), findsOneWidget, reason: l);
    }
    expect(find.byKey(const ValueKey('bar-wallet')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-status-node')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-status-epicbox')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-status-http')), findsOneWidget);
    if (DeskFeatures.tor) expect(find.byKey(const ValueKey('bar-status-network')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('status-open-epicbox')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('status-pop-epicbox')), findsNothing);
    await _end(tester);
  });

  testWidgets('Settings: the four groups, every entry; Recheck balance a row of Wallet', (tester) async {
    await _pump(tester, start: DeskRoute.settingsAccount);
    Finder side(String l) => find.descendant(of: find.byType(ESubnav), matching: find.text(l));
    for (final l in ['Wallet', 'Security', 'Transactions', 'Linked devices', 'Appearance', 'Node', 'Network & privacy', 'Advanced', 'Wallets', 'Files & logs', 'Help', 'About', 'APP', 'THIS COMPUTER', 'HELP']) {
      expect(side(l), findsWidgets, reason: l);
    }
    expect(side('Recheck balance'), findsNothing);
    expect(find.byKey(const ValueKey('account-recheck')), findsOneWidget);
    await _end(tester);
  });

  testWidgets('Outputs with its switch off reads as Home', (tester) async {
    final c = await _pump(tester);
    final s = c.read(deskProvider).settings;
    await tester.runAsync(() => c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withFeature(AdvancedFeature.outputs, false))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_rail('Outputs'), findsNothing);
    c.read(deskNavProvider.notifier).go(DeskRoute.outputs);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OverviewScreen), findsOneWidget);
    await _end(tester);
  });
}
