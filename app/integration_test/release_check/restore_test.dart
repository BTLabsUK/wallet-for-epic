// Desktop release check, part 2: restore the wallet made by desktop_test.dart into a second fresh
// data dir and compare the receive address. The phrase is read from RC_PHRASE_FILE (a mode-600
// file in the scratch dir, throwaway empty wallet only), kept in memory and the file is deleted
// right after reading. Never prints the phrase or the password.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop: restore from the first wallet\'s phrase', (tester) async {
    captureErrors();
    final phraseFile = Platform.environment['RC_PHRASE_FILE'];
    final addrFile = Platform.environment['RC_ADDR_FILE'];
    if (phraseFile == null || !File(phraseFile).existsSync() || addrFile == null || !File(addrFile).existsSync()) {
      record('restore: first wallet phrase available', false, 'desktop_test.dart did not leave a phrase/address (run it first, same RC_* env)');
      return;
    }
    final phrase = File(phraseFile).readAsStringSync().trim();
    File(phraseFile).deleteSync();
    final wantAddr = File(addrFile).readAsStringSync().trim();
    final password = randomPassword();

    await boot(tester);
    record('restore: second fresh data dir starts on Welcome', hasText('Restore from a phrase') && !hasText('Unlock wallet'), '');
    await tapText(tester, 'Restore from a phrase');
    await shot(tester, '20-restore-words');
    await typeIn(tester, 0, phrase);
    await settle(tester, ms: 1500);
    record('restore: 24 words accepted', hasText('All 24 words are in the word list'), texts().where((t) => t.contains('word list')).join());
    await shot(tester, '21-restore-words-checked');
    await tapText(tester, 'Continue', last: true);
    await settle(tester);
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Restore wallet', last: true);
    await waitText(tester, 'Unlock wallet', timeout: const Duration(minutes: 4));
    record('restore: wallet restored, lands on Unlock', true, texts().where((t) => t.contains('added')).join());
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, 'Available to spend', timeout: const Duration(seconds: 150));
    await settle(tester, ms: 2500);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    await settle(tester, ms: 1500);
    await shot(tester, '22-restored-overview');
    final got = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).epicboxAddress());
    record('restore: same receive address as the first wallet', got == wantAddr, got == wantAddr ? 'identical (${got!.replaceAll(RegExp(r'^[^@]+'), '<id>')})' : 'DIFFERENT: ${got!.replaceAll(RegExp(r'^[^@]+'), '<id>')} vs ${wantAddr.replaceAll(RegExp(r'^[^@]+'), '<id>')}');
    record('restore: node online with a height', RegExp(r'Height \d').hasMatch(texts().join(' ')), '');
    record('restore: no Flutter exceptions', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
