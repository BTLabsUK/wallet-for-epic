// Desktop release check with a phone (report utc3fhjj and the copy bug, 2026-10-26): the phone
// (integration_test/pairing_words_phone_test.dart, WFE_WORDS_JOINER=desk) offers pairing words
// on a relay outside the meeting list with epicbox.epiccash.com blocked on its network, and
// copies them with its Copy button. The driver writes what the phone copied to $WFE_WORDS_FILE;
// this real desktop wallet, on the default relay, pastes exactly that under Enter link or words,
// answers, and shows the four words. Real LEPIC, node and relays; no funds move.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

// tool/release_check.sh passes the environment through to the app.
final _wordsFile = Platform.environment['WFE_WORDS_FILE'] ?? '';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: pastes the words a phone copied and pairs', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester);

    // A fresh desktop wallet.
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    // A throwaway wallet: the phrase is shown but never read or kept.
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    // Setup: node, Epicbox and Review with their defaults.
    for (var i = 0; i < 4 && !hasText('Unlock wallet'); i++) {
      await waitText(tester, RegExp(r'^(Continue|Save settings)$'));
      await settle(tester, ms: 1000);
      await tapText(tester, hasText('Save settings') ? 'Save settings' : 'Continue', last: true);
      await settle(tester, ms: 3000);
    }
    await waitText(tester, 'Unlock wallet');
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    final desk = containerOf(tester).read(deskProvider.notifier);
    final settings = containerOf(tester).read(deskProvider).settings;
    await tester.runAsync(() => desk.saveSettings(settings.copyWith(advanced: settings.advanced.withExperimental(AdvancedFeature.pairing, true))));
    await settle(tester, ms: 3000);

    // What the phone copied, as the driver saved it.
    final file = File(_wordsFile);
    final until = DateTime.now().add(const Duration(minutes: 10));
    while (!file.existsSync() && DateTime.now().isBefore(until)) {
      await settle(tester, ms: 2000);
    }
    final pasted = file.existsSync() ? file.readAsStringSync() : '';
    record('the phone\'s copied words arrived', pasted.trim().isNotEmpty, pasted);

    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair);
    await settle(tester, ms: 1500);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), pasted);
    await settle(tester);
    await tester.tap(find.byKey(deskPairGoKey));
    await waitText(tester, RegExp('Pair with'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 800);
    await shot(tester, 'paste-01-incoming');
    record('the pasted words open the phone\'s invite', hasText(RegExp('Pair with')), texts().where((t) => t.contains('Pair with')).take(2).join(' / '));
    await tester.tap(find.byKey(deskIncomingPairKey));
    await settle(tester);
    if (hasText('Enter the name they will see')) {
      await tester.enterText(find.byType(EditableText).last, 'RC Desk');
      await settle(tester);
      await tester.tap(find.byKey(deskIncomingPairKey));
    }
    final wait = DateTime.now().add(const Duration(minutes: 6));
    while (find.byType(WordTiles).evaluate().isEmpty && DateTime.now().isBefore(wait)) {
      await settle(tester, ms: 3000);
    }
    await shot(tester, 'paste-02-check');
    final tiles = find.byType(WordTiles);
    final shown = tiles.evaluate().isEmpty ? const <String>[] : [for (final w in tester.widget<WordTiles>(tiles.first).words) w?.name ?? '?'];
    record('the desktop shows the four words', shown.length == 4, shown.join(' '));
    // ignore: avoid_print
    print('RC NOTE | DESK SAS|${shown.join(' ')}|');
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  });
}
