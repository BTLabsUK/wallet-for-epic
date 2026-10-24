// The invoice address follows a live relay switch, on LEPIC and two real relays: a wallet opened
// on relay A and switched to relay B (setServers, no reopen) shows its invoice address on B, an
// invoice sent there arrives, and one sent to the old address on A waits on A until the wallet
// is back there.
//
// Needs the usernet node (/opt/epic/stable-network, 127.0.0.1:23413) and two epic-relay instances,
// each spelled as the wallet spells it and with its own database: A with
// EPIC_RELAY_EPICBOX_DOMAIN=127.0.0.1 EPIC_RELAY_PORT=3423, B with EPIC_RELAY_HOST=127.0.0.2
// EPIC_RELAY_EPICBOX_DOMAIN=127.0.0.2 EPIC_RELAY_PORT=3424. Skipped without the define:
//
//   xvfb-run -a flutter test integration_test/invoice_address_switch_test.dart -d linux \
//     --dart-define=WFE_RELAY_SWITCH=127.0.0.1:3423,127.0.0.2:3424
//
// No funds: issuing and parking an invoice spends nothing. Fresh random wallets, never printed.
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _relays = String.fromEnvironment('WFE_RELAY_SWITCH');
const _node = 'http://127.0.0.1:23413';
const _password = 'invoice switch test password';

final BigInt _epic = BigInt.from(100000000);
final _lepic = LepicWalletService(secrets: MemorySecretStore());
final _dirs = <Directory>[];

typedef _Relay = ({String host, int port});

_Relay _relay(String text) {
  final at = text.lastIndexOf(':');
  return (host: text.substring(0, at), port: int.parse(text.substring(at + 1)));
}

WalletConfig _on(WalletConfig c, _Relay r) => WalletConfig(
  dataDir: c.dataDir,
  chain: c.chain,
  nodeUrl: c.nodeUrl,
  epicboxDomain: r.host,
  epicboxPort: r.port,
);

Future<(WalletSession, WalletConfig)> _wallet(_Relay relay) async {
  final base = await getTemporaryDirectory();
  final dir = await base.createTemp('wfe-invoice-switch-');
  _dirs.add(dir);
  final config = _on(usernetPreset.config(dataDir: dir.path, nodeUrl: _node), relay);
  return (await _lepic.create(config: config, password: _password), config);
}

String _key(String address) => address.split('@').first;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_relays.isNotEmpty) await initLepic();
  });
  tearDownAll(() async {
    for (final d in _dirs) {
      if (d.existsSync()) await d.delete(recursive: true);
    }
  });

  testWidgets(
    'after a live switch from relay A to B the invoice address is on B, an invoice sent there '
    'arrives, and one sent to the old address on A arrives only back on A',
    (tester) async {
      final [a, b] = _relays.split(',').map(_relay).toList();
      final (payer, payerConfig) = await _wallet(a);
      final (issuerA, _) = await _wallet(a);
      final (issuerB, _) = await _wallet(b);
      try {
        // The invoices come from each issuer's payments address.
        await payer.addTrustedService(address: await issuerA.epicboxAddress(), label: 'A');
        await payer.addTrustedService(address: await issuerB.epicboxAddress(), label: 'B');
        final oldInvoice = await payer.invoiceAddress();
        final oldPayments = await payer.epicboxAddress();
        expect(oldInvoice, contains('@${a.host}'));

        await payer.setServers(config: _on(payerConfig, b));

        final newInvoice = await payer.invoiceAddress();
        final newPayments = await payer.epicboxAddress();
        expect(newInvoice, contains('@${b.host}'));
        expect(newPayments, contains('@${b.host}'));
        // Same keys: only the relay part moved.
        expect(_key(newInvoice), _key(oldInvoice));
        expect(_key(newPayments), _key(oldPayments));

        await issuerB.issueInvoice(amount: _epic, address: newInvoice, message: 'on B');
        await issuerA.issueInvoice(amount: _epic * BigInt.two, address: oldInvoice, message: 'stale');

        await payer.drainInvoices();
        var pending = await payer.pendingInvoices();
        expect(pending.map((i) => i.message), ['on B'], reason: 'the drain reads relay B only');
        expect(pending.single.amount, _epic);

        // The old address's invoice waits on A, unread, until the wallet is on A again.
        await payer.setServers(config: _on(payerConfig, a));
        expect(await payer.invoiceAddress(), oldInvoice);
        await payer.drainInvoices();
        pending = await payer.pendingInvoices();
        expect(pending.map((i) => i.message), unorderedEquals(['on B', 'stale']));
      } finally {
        payer.dispose();
        issuerA.dispose();
        issuerB.dispose();
      }
    },
    skip: _relays.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
