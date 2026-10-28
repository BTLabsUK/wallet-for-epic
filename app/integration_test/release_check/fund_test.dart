// SPDX-License-Identifier: Apache-2.0
// Pays a floonet address from a funded floonet wallet of this machine's QA homes, for the live
// checks when the floonet faucet is down (it finalizes stale replies, 2026-10-25). Runs as a
// Linux integration test under the QA home's unlocked keyring, since the desktop keeps the
// wallet's sealed seed there:
//
//   HOME=<qa home> XDG_DATA_HOME=<qa home>/.local/share  (keyring unlocked with its password)
//   WFE_FUNDER_DIR=<qa home>/.epic_cash_desktop/wallets/floonet WFE_FUNDER_PASSWORD=…
//   WFE_FUND_TO=<epicbox address>|balance WFE_FUND_EPIC=10
//   flutter test -d linux integration_test/release_check/fund_test.dart
//
// The recipient must be online (its listener answers); the send is finalized and posted here.
// Prints only amounts and the slate id.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/network.dart' show floonetPreset;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final dir = env['WFE_FUNDER_DIR'];
  final password = env['WFE_FUNDER_PASSWORD'];
  final to = env['WFE_FUND_TO'];
  final epic = double.tryParse(env['WFE_FUND_EPIC'] ?? '') ?? 10;
  testWidgets('fund a floonet address', (tester) async {
    if (dir == null || password == null || to == null) {
      // ignore: avoid_print
      print('FUND SKIP | set WFE_FUNDER_DIR, WFE_FUNDER_PASSWORD and WFE_FUND_TO');
      return;
    }
    await tester.runAsync(() async {
      await initWalletBackend();
      // WFE_FUND_TO=faucet: a probe of the floonet faucet with a fresh listening wallet.
      if (to == 'faucet') {
        final dir = await Directory.systemTemp.createTemp('wfe-faucet-probe-');
        final w = await createWalletService(MemorySecretStore()).create(config: floonetPreset.config(dataDir: dir.path, nodeUrl: floonetPreset.nodeUrl), password: 'probe-${DateTime.now().microsecondsSinceEpoch}');
        final sub = w.startListener().listen((_) {});
        final addr = await w.epicboxAddress();
        final c = HttpClient()..connectionTimeout = const Duration(seconds: 20);
        final rq = await c.postUrl(Uri.parse('https://floo-explorer.btlabs.uk/api/faucet/claim?method=epicbox&destination=${Uri.encodeComponent(addr)}'));
        final rs = await rq.close().timeout(const Duration(seconds: 120));
        final body = await rs.transform(utf8.decoder).join();
        // ignore: avoid_print
        print('FUND | faucet ${rs.statusCode} ${body.length > 200 ? body.substring(0, 200) : body}');
        c.close(force: true);
        await Future<void>.delayed(const Duration(seconds: 20));
        final rows = await w.transactions(refresh: true);
        // ignore: avoid_print
        print('FUND | probe wallet rows: ${rows.map((t) => '${t.kind.name}/${t.status.name}').join(', ')}');
        await sub.cancel();
        w.dispose();
        return;
      }
      final f = await createWalletService(createSecretStore()).open(config: floonetPreset.config(dataDir: dir, nodeUrl: floonetPreset.nodeUrl), password: password);
      try {
        final before = await f.summary(refresh: true, minimumConfirmations: BigInt.from(3));
        // ignore: avoid_print
        print('FUND | funder spendable ${before.spendable} nano, locked ${before.locked}, awaiting ${before.awaitingConfirmation}');
        if (to == 'balance') return;
        final amount = BigInt.from((epic * 100000000).round());
        expect(before.spendable >= amount, isTrue, reason: 'the funder has ${before.spendable} nano, needs $amount');
        final sent = await f.sendEpicbox(amount: amount, minimumConfirmations: BigInt.from(3), address: to, message: 'live check funds');
        // ignore: avoid_print
        print('FUND | sent ${sent.slateId} ($epic EPIC)');
        final end = DateTime.now().add(const Duration(minutes: 6));
        TxEntry? row;
        while (DateTime.now().isBefore(end)) {
          row = (await f.transactions(refresh: true)).where((t) => t.slateId == sent.slateId).firstOrNull;
          if (row != null && row.status != TxStatus.awaitingRecipient) break;
          await Future<void>.delayed(const Duration(seconds: 5));
        }
        // ignore: avoid_print
        print('FUND | status ${row?.status.name}');
        expect(row?.status, isNot(TxStatus.awaitingRecipient), reason: 'the recipient did not answer in 6 minutes');
      } finally {
        f.dispose();
      }
    });
  }, timeout: const Timeout(Duration(minutes: 12)));
}
