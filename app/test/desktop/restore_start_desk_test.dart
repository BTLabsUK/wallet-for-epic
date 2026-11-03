// SPDX-License-Identifier: Apache-2.0
// Restore's start on the desktop: January 2025 on mainnet unless the user picks another month
// or a height, and "Scan from the start" passes no start height.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/start_month.dart' show defaultStartMonth;
import 'package:epic_wallet/src/ui/scan_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;

const _v12 = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

Future<MockDeskWallet> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = MockDeskWallet(delay: Duration.zero);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: RestoreScreen())),
    ),
  );
  await tester.pump();
  return api;
}

Future<void> _wait(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The phrase pasted and Continue: the password step.
Future<void> _toAccount(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, _v12);
  await _wait(tester);
  await tester.tap(find.text(_l.commonContinue));
  await _wait(tester);
  expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
}

Future<void> _restore(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).at(0), 'password-1234');
  await tester.enterText(find.byType(EditableText).at(1), 'password-1234');
  await tester.pump();
  await tester.ensureVisible(find.text(_l.deskOnbRestoreSide).last);
  await tester.tap(find.text(_l.deskOnbRestoreSide).last);
  await _wait(tester);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('mainnet restores from January 2025 by default', (tester) async {
    final api = await _pump(tester);
    await _toAccount(tester);
    expect(find.text(_l.restoreScanningFrom('January 2025')), findsOneWidget);
    expect(find.byKey(ScanStart.changeKey), findsOneWidget);
    expect(find.byKey(ScanStart.infoKey), findsOneWidget);
    expect(find.byKey(ScanStart.fromStartKey), findsNothing, reason: 'inside the info popover');
    await _restore(tester);
    expect(api.restoreStartHeight, defaultStartMonth.height);
    await _end(tester);
  });

  testWidgets('Scan from the start restores with no start height', (tester) async {
    final api = await _pump(tester);
    await _toAccount(tester);
    await tester.tap(find.byKey(ScanStart.infoKey));
    await _wait(tester, 300);
    expect(find.text(_l.scanStartInfo), findsOneWidget);
    await tester.tap(find.byKey(ScanStart.fromStartKey));
    await _wait(tester, 300);
    expect(find.text(_l.restoreScanningFromStart), findsOneWidget);
    expect(find.byKey(ScanStart.changeKey), findsOneWidget, reason: 'the way back to a month');
    await _restore(tester);
    expect(api.restoreStartHeight, isNull);
    await _end(tester);
  });
}
