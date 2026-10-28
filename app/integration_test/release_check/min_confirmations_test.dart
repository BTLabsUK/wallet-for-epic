// Desktop release check: the minimum confirmations setting on a real LEPIC wallet (ADR 0027).
// Creates a throwaway mainnet wallet against the check's node, opens Settings › Advanced,
// reads the Confirmations row (6, Default), sets 7 with the stepper, checks the wallet's
// balance now counts with 7 (the core's setting, read back through the summary), locks and
// unlocks (the value is the wallet's, not the screen's), goes below the default and sees the
// note, then resets to 6. Never prints the phrase or the password.
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/widgets/buttons.dart' show EIconButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: minimum confirmations setting', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester);
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    await waitText(tester, 'Skip setup', timeout: const Duration(seconds: 60));
    await tapText(tester, 'Skip setup');
    await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
    if (hasText('Unlock wallet')) {
      await typeIn(tester, 0, password);
      await tapText(tester, 'Unlock', last: true);
    }
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    await settle(tester, ms: 1000);

    int counted() => containerOf(tester).read(deskProvider).balance?.minConfirmations ?? -1;
    Future<int> stored() async => (await tester.runAsync(() => containerOf(tester).read(deskApiProvider).minimumConfirmations()))!;
    record('a new wallet counts 6 confirmations (core default)', counted() == 6 && await stored() == 6, 'balance ${counted()}, core ${await stored()}');

    // ---- Settings › Advanced › Confirmations.
    await tapText(tester, 'Settings');
    await tapText(tester, 'Advanced');
    await settle(tester, ms: 800);
    final row = find.byKey(const ValueKey('adv-minConfirmations'));
    await tester.ensureVisible(row);
    await settle(tester, ms: 500);
    record('Advanced shows the Confirmations row at 6, marked Default', row.evaluate().isNotEmpty && hasText('Confirmations') && hasText('Default') && hasText('6'), texts().where((t) => t.contains('onfirmation') || t == 'Default').join(' | '));
    await shot(tester, '20-advanced-confirmations-6');

    Finder stepButton(String label) => find.descendant(of: row, matching: find.byWidgetPredicate((w) => w is EIconButton && w.label == label));
    Future<void> step(String label) async {
      expect(stepButton(label), findsOneWidget, reason: 'no "$label" button: ${shownTexts(30)}');
      await tester.tap(stepButton(label), warnIfMissed: false);
      await settle(tester, ms: 1500);
    }

    await step('More confirmations');
    record('+ stores 7 in the core and the balance counts with it at once', await stored() == 7 && counted() == 7 && hasText('Reset to 6'), 'core ${await stored()}, balance ${counted()}');
    await shot(tester, '21-advanced-confirmations-7');

    // ---- The value is the wallet's: lock, unlock, it is still 7.
    await key(tester, LogicalKeyboardKey.keyL, ctrl: true);
    await waitText(tester, 'Unlock wallet', timeout: const Duration(seconds: 30));
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, 'Available to spend', timeout: const Duration(seconds: 120));
    await settle(tester, ms: 2000);
    record('after lock and unlock the wallet still counts 7', await stored() == 7 && counted() == 7, 'core ${await stored()}, balance ${counted()}');

    // ---- Below the default: the quiet note; Reset returns to 6.
    await tapText(tester, 'Settings');
    await tapText(tester, 'Advanced');
    await settle(tester, ms: 800);
    await tester.ensureVisible(row);
    await settle(tester, ms: 300);
    for (var i = 0; i < 3; i++) {
      await step('Fewer confirmations');
    }
    record('− to 4 shows the note below the row', await stored() == 4 && find.byKey(const ValueKey('adv-minConfirmations-note')).evaluate().isNotEmpty, 'core ${await stored()}');
    await shot(tester, '22-advanced-confirmations-4');
    await tester.tap(find.byKey(const ValueKey('adv-minConfirmations-reset')), warnIfMissed: false);
    await settle(tester, ms: 1500);
    record('Reset returns to 6 and the note goes', await stored() == 6 && counted() == 6 && hasText('Default') && find.byKey(const ValueKey('adv-minConfirmations-note')).evaluate().isEmpty, 'core ${await stored()}, balance ${counted()}');
    await shot(tester, '23-advanced-confirmations-reset');

    // ---- Help follows the count.
    await tapText(tester, 'Help');
    await settle(tester, ms: 800);
    record('Help names the confirmations count', hasText(RegExp('6 confirmations|6 by default')), texts().where((t) => t.contains('6 confirmations') || t.contains('6 by default')).take(2).join(' / '));

    record('no Flutter exceptions during the run', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
