// Desktop release check, pairing (RFC 0002): the real desktop wallet answers an invite that a
// second LEPIC wallet in this process makes on the default Epicbox relay, both see the same
// four words, the user says they match, and both sides are verified. Then the other wallet
// asks for a payment, which the desktop lists to pay. Real LEPIC, real node and relay (see
// tool/release_check.sh); no funds move. Never prints a phrase or a password.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingApiProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: pairing with another wallet over the relay', (tester) async {
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
    await tapText(tester, 'Written down');
    await tapText(tester, 'Continue', last: true);
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
        config: mainnetPreset.config(dataDir: otherDir!.path, nodeUrl: node),
        password: randomPassword(),
      ),
    ))!;
    addTearDown(() {
      other.dispose();
      otherDir!.deleteSync(recursive: true);
    });
    final invite = (await tester.runAsync(() => other.pairing.makeInvite(name: 'RC Shop', expiry: const Duration(hours: 1))))!;
    record('the other wallet made an invite on the relay', invite.inviteLink?.startsWith('epiccash://pair/1/') ?? false, invite.homeRelay);

    // Contacts › Pair: the invite pasted under Enter link or words.
    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair);
    await settle(tester, ms: 1500);
    await shot(tester, 'pair-01-screen');
    await tester.enterText(find.byKey(deskPairEnterKey), invite.inviteLink!);
    await settle(tester);
    await tester.tap(find.byKey(deskPairGoKey));
    await waitText(tester, 'RC Shop', timeout: const Duration(seconds: 60));
    await settle(tester, ms: 800);
    await shot(tester, 'pair-02-incoming');
    record('the invite opens as Pair with RC Shop?', hasText('RC Shop'), texts().where((t) => t.contains('RC Shop')).take(2).join(' / '));
    await tester.tap(find.byKey(deskIncomingPairKey));
    await settle(tester, ms: 1500);
    await shot(tester, 'pair-03-waiting');

    // The other wallet collects the answer and confirms; the desktop collects the confirm.
    PairingRecord? theirs;
    final until = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(until)) {
      await tester.runAsync(() => other.pairing.collect(trigger: PairingCollectTrigger.pull));
      theirs = await tester.runAsync<PairingRecord?>(() => other.pairing.pairing(invite.id));
      if (theirs != null && theirs.state == PairingState.paired && find.byType(WordTiles).evaluate().isNotEmpty) break;
      await settle(tester, ms: 3000);
    }
    record('the other wallet got the answer', theirs?.state == PairingState.paired, '${theirs?.state.name}');
    final tiles = find.byType(WordTiles);
    record('the desktop shows the four words', tiles.evaluate().isNotEmpty, texts().take(8).join(' | '));
    await shot(tester, 'pair-04-words');
    final shown = tiles.evaluate().isEmpty ? const <String>[] : [for (final w in tester.widget<WordTiles>(tiles.first).words) w?.name ?? '?'];
    final expected = [for (final w in theirs?.sas ?? const <SasWord>[]) w.name];
    record('both wallets show the same four words', shown.length == 4 && shown.join(' ') == expected.join(' '), '${shown.length} words, same: ${shown.join(' ') == expected.join(' ')}');

    // They match, on both sides.
    if (tiles.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(deskCheckMatchKey));
      await settle(tester, ms: 1500);
    }
    final verified = await tester.runAsync(() => other.pairing.checkWords(invite.id, PairingCheck.match));
    final mine = (await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).pairings()))!;
    record('the desktop pairing is verified', mine.any((p) => p.state == PairingState.verified && p.name == 'RC Shop'), mine.map((p) => '${p.name}:${p.state.name}').join(', '));
    record('the other side is verified', verified?.state == PairingState.verified, '${verified?.state.name}');
    // The mailbox is never an address to show (RFC C-21).
    record('no pairing shows a payments address', mine.every((p) => p.paymentsAddress == null), '');
    await shot(tester, 'pair-05-verified');

    // A request from the verified contact the desktop allows: it waits under Invoices › To pay.
    final desk = containerOf(tester).read(deskPairingApiProvider);
    final mineId = mine.firstWhere((p) => p.name == 'RC Shop').id;
    await tester.runAsync(() => desk.setAllowInvoices(mineId, true));
    final asked = await tester.runAsync(() => other.pairing.requestPayment(id: invite.id, amount: BigInt.from(12345678), message: 'RC order'));
    record('the other wallet asked for a payment', asked?.pairingId == invite.id, '${asked?.state.name}');
    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.invoices);
    final waitUntil = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(waitUntil) && !hasText('RC Shop')) {
      await tester.runAsync(() => desk.collect(trigger: PairingCollectTrigger.pull));
      await settle(tester, ms: 4000);
    }
    await shot(tester, 'pair-06-to-pay');
    record('the request waits to pay, named by the pairing', hasText('RC Shop'), texts().where((t) => t.contains('RC Shop') || t.contains('0.123')).take(3).join(' / '));
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  });
}
