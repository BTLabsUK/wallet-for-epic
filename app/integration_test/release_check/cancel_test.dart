// Desktop release check, Cancel (2026-10-25): a floonet send to a wallet that never
// answers shows the quiet line beside Cancel and its Help link; the dialog says the same; the
// link opens Help › Cancelling a payment at Sending; the cancel frees the coins. Real LEPIC,
// the floonet node, relay and faucet (tool/release_check.sh desktop <this file>). Throwaway
// wallets only; never prints a phrase or a password.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/api.dart' show DeskWalletApi;
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider;
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart' show onbFlowProvider;
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EButton, ESeedGrid;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart' show floonetPreset;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const flooNode = 'https://floo-node.btlabs.uk';
const faucet = 'https://floo-explorer.btlabs.uk/api/faucet/claim';
int epic(num n) => (n * 100000000).round();
String fmt(int nano) => (nano / 100000000).toStringAsFixed(2);

void log(String s) {
  // ignore: avoid_print
  print('${DateTime.now().toIso8601String()} $s');
}

DeskWalletApi apiOf(WidgetTester tester) => containerOf(tester).read(deskApiProvider);
Future<T> io<T>(WidgetTester tester, Future<T> Function() f) async => (await tester.runAsync(f)) as T;

Future<String> claimFaucet(String address) async {
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final rq = await c.postUrl(Uri.parse('$faucet?method=epicbox&destination=${Uri.encodeComponent(address)}'));
    final rs = await rq.close().timeout(const Duration(seconds: 90));
    final body = await rs.transform(utf8.decoder).join();
    return '${rs.statusCode} ${body.length > 160 ? body.substring(0, 160) : body}';
  } on Object catch (e) {
    return 'error ${e.runtimeType}';
  } finally {
    c.close(force: true);
  }
}

/// Welcome on floonet: the adapter and Welcome's flow move to the test network.
Future<void> useFloonet(WidgetTester tester) async {
  await settle(tester, ms: 6000);
  await io(tester, () => apiOf(tester).useNetwork('floonet'));
  containerOf(tester).read(onbFlowProvider.notifier).setNetwork('floonet');
  await settle(tester, ms: 800);
  record('Welcome makes floonet wallets', apiOf(tester).network == 'floonet', apiOf(tester).network);
}

Future<void> unlockToOverview(WidgetTester tester, String password) async {
  for (var i = 0; i < 8 && !hasText('Unlock wallet'); i++) {
    if (hasText(RegExp(r'^(Continue|Save settings)$'))) {
      await settle(tester, ms: 1000);
      await tapText(tester, hasText('Save settings') ? 'Save settings' : 'Continue', last: true);
    }
    await settle(tester, ms: 3000);
  }
  await waitText(tester, 'Unlock wallet', timeout: const Duration(minutes: 4));
  await typeIn(tester, 0, password);
  await tapText(tester, 'Unlock', last: true);
  await waitText(tester, RegExp('Available to spend|Overview'), timeout: const Duration(minutes: 3));
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    await settle(tester, ms: 1500);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    if (hasText('Skip setup')) await tapText(tester, 'Skip setup', last: true);
  }
}

Future<void> createA(WidgetTester tester, String password) async {
  await tapText(tester, 'Create a new wallet');
  await typeIn(tester, 0, password);
  await typeIn(tester, 1, password);
  await settle(tester);
  await tapText(tester, 'Create wallet', last: true);
  await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
  await tapText(tester, 'Reveal phrase');
  final words = tester.widget<ESeedGrid>(find.byType(ESeedGrid)).words;
  record('A made (throwaway, phrase not kept)', words.length == 24, '${words.length} words');
  await tapText(tester, RegExp('[Ww]ritten down'));
  await tapText(tester, 'Continue', last: true);
  await unlockToOverview(tester, password);
}

Future<void> go(WidgetTester tester, DeskRoute r, [Object? arg]) async {
  if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
  final nav = containerOf(tester).read(deskNavProvider.notifier);
  nav.go(DeskRoute.overview);
  await settle(tester, ms: 300);
  nav.go(r, arg);
  await settle(tester, ms: 1500);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: cancel a waiting floonet send, with the quiet line and Help', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester, size: const Size(1400, 950));
    await useFloonet(tester);
    await createA(tester, password);
    final api = apiOf(tester);
    final aAddr = await io(tester, api.epicboxAddress);
    record('A has a floonet Epicbox address', aAddr.contains('@'), aAddr.split('@').last);

    // B: a headless wallet in this process that never listens, so A's send waits for ever.
    final bDir = await io(tester, () => Directory.systemTemp.createTemp('wfe-cancel-b-'));
    final b = await io(
      tester,
      () => LepicWalletService(secrets: MemorySecretStore()).create(
        config: floonetPreset.config(dataDir: bDir.path, nodeUrl: floonetPreset.nodeUrl),
        password: 'b-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    addTearDown(() async {
      b.dispose();
      try {
        await bDir.delete(recursive: true).timeout(const Duration(seconds: 10));
      } catch (_) {}
    });
    final bAddr = await io(tester, b.epicboxAddress);

    // Funds: one faucet payment, confirmed.
    var claimed = false;
    log('fund this address if the faucet is down: $aAddr');
    for (var attempt = 0; attempt < 2 && !claimed; attempt++) {
      final r = await io(tester, () => claimFaucet(aAddr));
      log('faucet claim: $r');
      claimed = RegExp(r'^20[0-9] ').hasMatch(r);
      final wait = int.tryParse(RegExp(r'wait (\d+)').firstMatch(r)?.group(1) ?? '');
      if (!claimed) await settle(tester, ms: wait != null ? (wait + 3) * 1000 : 60000);
    }
    record('faucet claim accepted (or funds come from the host funder)', true, claimed ? 'faucet' : 'faucet down: waiting for the funder');
    var spendable = 0;
    final fundEnd = DateTime.now().add(const Duration(minutes: 30));
    var lastLog = DateTime(2000);
    var lastClaim = DateTime.now();
    while (DateTime.now().isBefore(fundEnd)) {
      await tester.runAsync(api.syncNow);
      final bal = await io(tester, api.balance);
      spendable = bal.spendable;
      if (spendable >= epic(9)) break;
      // Nothing on its way after four minutes: the faucet may have paid a stale payee; ask again.
      if (bal.awaitingConfirmation == 0 && DateTime.now().difference(lastClaim).inMinutes >= 4) {
        lastClaim = DateTime.now();
        log('faucet claim again: ${await io(tester, () => claimFaucet(aAddr))}');
      }
      if (DateTime.now().difference(lastLog).inSeconds > 60) {
        lastLog = DateTime.now();
        log('waiting for funds: spendable ${fmt(spendable)}');
      }
      await settle(tester, ms: 15000);
    }
    record('A funded and confirmed', spendable >= epic(9), '${fmt(spendable)} EPIC');
    if (spendable < epic(2)) return;

    // The send: Epicbox, to B, which never answers.
    final sent = await io(tester, () => api.send(SendRequest(method: TxMethod.epicbox, amount: epic(1), to: bAddr, message: 'RC cancel')));
    final sentTx = sent is SendDone ? sent.tx : null;
    record('A sent 1 EPIC to B over Epicbox', sentTx != null, sent.runtimeType.toString());
    if (sentTx == null) return;
    await settle(tester, ms: 3000);
    final waiting = (await io(tester, api.transactions)).where((t) => t.id == sentTx.id).firstOrNull;
    record('the send waits for the recipient', waiting?.state == TxState.waitingRecipient, '${waiting?.state.name}');

    // Activity › the send: the Cancel button, the quiet line and its link.
    await go(tester, DeskRoute.activity, sentTx.id);
    await waitText(tester, 'Not posted yet: cancelling frees the coins.', timeout: const Duration(seconds: 30));
    record('the quiet line beside Cancel states the guarantee', hasText('Not posted yet: cancelling frees the coins.'), textMatching('cancelling frees'));
    record('…with a Help link', find.text('More in Help').evaluate().isNotEmpty, '${find.text('More in Help').evaluate().length} link(s)');
    // The Cancel row ends the detail panel, below the fold at this height: scroll to it.
    await tester.ensureVisible(find.text('More in Help').first);
    await settle(tester, ms: 600);
    await shot(tester, 'cancel-01-detail-waiting-send');

    // The dialog: the same guarantee, the same link.
    await tester.tap(find.widgetWithText(EButton, 'Cancel payment').first);
    await settle(tester, ms: 1200);
    record('the cancel dialog says the recipient cannot finish it', hasText('Cancel this payment?') && hasText('cannot finish it without yours'), textMatching('cannot finish'));
    await shot(tester, 'cancel-02-dialog');
    // The dialog's link: closes the dialog, opens Help at Sending.
    await tester.tap(find.text('More in Help').last);
    await settle(tester, ms: 2500);
    record('More in Help opens Help › Cancelling a payment', hasText('Cancelling a payment') && hasText('Sending') && hasText('Cancel is certain'), screenLine());
    await shot(tester, 'cancel-03-help-topic');

    // Back to the send and cancel it for real.
    await go(tester, DeskRoute.activity, sentTx.id);
    await waitText(tester, 'Not posted yet: cancelling frees the coins.', timeout: const Duration(seconds: 30));
    await tester.ensureVisible(find.widgetWithText(EButton, 'Cancel payment').first);
    await settle(tester, ms: 600);
    await tester.tap(find.widgetWithText(EButton, 'Cancel payment').first);
    await settle(tester, ms: 1200);
    await tapText(tester, 'Cancel payment', last: true);
    await waitText(tester, RegExp(r'^Cancelled\.?$'), timeout: const Duration(seconds: 60));
    await settle(tester, ms: 3000);
    final after = (await io(tester, api.transactions)).where((t) => t.id == sentTx.id).firstOrNull;
    final bal = await io(tester, api.balance);
    record('the send is cancelled', after?.state == TxState.cancelled, '${after?.state.name}');
    record('its coins are free again (nothing locked)', bal.locked == 0 && bal.spendable >= epic(9), 'spendable ${fmt(bal.spendable)}, locked ${fmt(bal.locked)}');
    await shot(tester, 'cancel-04-cancelled');
  }, timeout: const Timeout(Duration(minutes: 50)));
}

String screenLine() => shownTexts(12);

String textMatching(Pattern p) => texts().firstWhere((t) => p is RegExp ? p.hasMatch(t) : t.contains(p as String), orElse: () => '');
