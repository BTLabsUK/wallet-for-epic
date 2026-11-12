// SPDX-License-Identifier: Apache-2.0
/// Where the phone shell is, for widget tests: one of its four tabs, or the Send or Receive
/// flow open over the tab bar. Before the redesign the shell had a Send, Wallet and Receive
/// tab; tests that asked for those now ask here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_tab_bar.dart';

enum ShellWhere { home, activity, contacts, settings, send, receive }

/// The flow route over the tab bar, if one is open; otherwise the tab the bar marks.
ShellWhere shellWhere(WidgetTester tester) {
  final flow = find.byType(ShellFlowRoute);
  if (flow.evaluate().isNotEmpty) {
    return tester.widget<ShellFlowRoute>(flow.last).flow == ShellFlow.send ? ShellWhere.send : ShellWhere.receive;
  }
  final bar = find.byType(KitTabBar);
  if (bar.evaluate().isEmpty) throw StateError('no tab bar and no flow route on screen');
  return ShellWhere.values[tester.widget<KitTabBar>(bar).selected];
}

/// Closes the flow route over the tab bar, if one is open.
Future<void> closeShellFlow(WidgetTester tester, {bool settle = true}) async {
  if (find.byType(ShellFlowRoute).evaluate().isEmpty) return;
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.popUntil((r) => r.isFirst);
  if (settle) {
    await tester.pumpAndSettle();
    return;
  }
  // The pop animates and the route leaves the tree a frame after it ends.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// What the old tab bar's words did, on the new shell: "Send" and "Receive" press the Home
/// buttons (closing an open flow first), "Wallet" or "Home" goes to the Home tab, and the other
/// tab words press the tab bar.
Future<void> shellGo(WidgetTester tester, String label, {bool settle = true}) async {
  Future<void> done() async => settle ? await tester.pumpAndSettle() : await tester.pump(const Duration(milliseconds: 400));
  final flow = find.byType(ShellFlowRoute).evaluate().isNotEmpty;
  if (flow) await closeShellFlow(tester, settle: settle);
  final bar = find.descendant(of: find.byType(KitTabBar), matching: find.text(label));
  if (bar.evaluate().isNotEmpty) {
    await tester.tap(bar.first);
    return done();
  }
  final home = find.descendant(of: find.byType(KitTabBar), matching: find.text('Home'));
  if (label == 'Wallet' && home.evaluate().isNotEmpty) {
    await tester.tap(home.first);
    return done();
  }
  final button = find.widgetWithText(KitButton, label);
  await tester.tap(button.first);
  return done();
}

/// The container behind the shell, for tests that read the providers.
ProviderContainer shellContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
