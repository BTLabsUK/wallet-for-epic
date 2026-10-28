// Desktop release check, pairing by words (RFC 0002 7.7, report utc3fhjj): a second LEPIC
// wallet in this process, on a relay outside the words meeting list (WFE_WORDS_RELAY, by
// default epicbox.iniaku.my.id), offers pairing words; the real desktop types them under Enter
// link or words, answers, and both sides see the same four words. Before the fix the other
// wallet was refused words outright ("Can't reach the relay"). Real LEPIC, real node and
// relays; no funds move. Never prints a phrase or a password.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: pairing by words with a wallet on another relay', (tester) async {
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

    // The other wallet, headless, on the same chain and the default relay.
    final otherDir = await tester.runAsync(() => Directory.systemTemp.createTemp('rc-pair-other-'));
    final other = (await tester.runAsync(
      () => LepicWalletService(secrets: MemorySecretStore()).create(
        config: mainnetPreset.config(
          dataDir: otherDir!.path,
          nodeUrl: node,
          relay: const EpicboxRelay(host: String.fromEnvironment('WFE_WORDS_RELAY', defaultValue: 'epicbox.iniaku.my.id'), port: 443),
        ),
        password: randomPassword(),
      ),
    ))!;
    addTearDown(() {
      other.dispose();
      otherDir!.deleteSync(recursive: true);
    });
    final invite = (await tester.runAsync(() => other.pairing.makeInvite(name: 'RC Words', expiry: const Duration(minutes: 10), words: true)))!;
    record('the other wallet, on ${invite.homeRelay}, offered five words', invite.inviteWords.length == 5, invite.homeRelay);

    // Contacts › Pair: the words typed under Enter link or words.
    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair);
    await settle(tester, ms: 1500);
    await tester.enterText(find.byKey(deskPairEnterKey), invite.inviteWords.map((w) => w.name).join(' '));
    await settle(tester);
    await tester.tap(find.byKey(deskPairGoKey));
    await waitText(tester, 'RC Words', timeout: const Duration(seconds: 90));
    await settle(tester, ms: 800);
    await shot(tester, 'words-01-incoming');
    record('the words open as Pair with RC Words?', hasText('RC Words'), texts().where((t) => t.contains('RC Words')).take(2).join(' / '));
    await tester.tap(find.byKey(deskIncomingPairKey));
    await settle(tester);
    if (hasText('Enter the name they will see')) {
      await tester.enterText(find.byType(EditableText).last, 'RC Desk');
      await settle(tester);
      await tester.tap(find.byKey(deskIncomingPairKey));
    }
    await settle(tester, ms: 1500);

    // The answer goes to the other wallet's own relay; it confirms; the desktop collects that.
    PairingRecord? theirs;
    final until = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(until)) {
      await tester.runAsync(() => other.pairing.collect(trigger: PairingCollectTrigger.pull));
      theirs = await tester.runAsync<PairingRecord?>(() => other.pairing.pairing(invite.id));
      if (theirs != null && theirs.state == PairingState.paired && find.byType(WordTiles).evaluate().isNotEmpty) break;
      await settle(tester, ms: 3000);
    }
    record('the other wallet got the answer on its own relay', theirs?.state == PairingState.paired, '${theirs?.state.name}');
    final tiles = find.byType(WordTiles);
    await shot(tester, 'words-02-check');
    final shown = tiles.evaluate().isEmpty ? const <String>[] : [for (final w in tester.widget<WordTiles>(tiles.first).words) w?.name ?? '?'];
    final expected = [for (final w in theirs?.sas ?? const <SasWord>[]) w.name];
    record('both wallets show the same four words', shown.length == 4 && shown.join(' ') == expected.join(' '), '${shown.length} words, same: ${shown.join(' ') == expected.join(' ')}');
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  });
}
