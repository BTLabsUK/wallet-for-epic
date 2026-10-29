// SPDX-License-Identifier: Apache-2.0
// An empty Node or Epicbox list in settings.toml (no server configured): the reader takes it,
// and the wallet still opens. LEPIC opens a wallet only with a node address, so it is given
// one that never answers ([noNodeUrl]); the app keeps the empty one. An empty Epicbox list
// goes to LEPIC as a server that never answers too ([noEpicboxDomain]), and picking a server
// writes nothing for the list that is empty.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/server_list_file.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

/// Both lists of settings.toml empty.
const Map<String, Object> _empty = {'node.servers': <String>[], 'epicbox.servers': <String>[]};

void main() {
  test('the reader takes empty lists: nothing in use, nothing thrown', () {
    final s = testSettings().withValues(_empty);
    expect(s.nodeUrls, isEmpty);
    expect(s.nodeUse, '');
    expect(s.epicboxServers, isEmpty);
    expect(s.epicboxUse, '');
    expect(s.pairingServers, isEmpty);
  });

  test('no node: LEPIC gets an address that never answers, https on an RFC 2606 .invalid name', () async {
    final c = await LepicWalletService.lepicConfigOf(
      const WalletConfig(dataDir: '/wallets/main', chain: Chain.mainnet, nodeUrl: '', epicboxDomain: '', epicboxPort: 443),
    );
    expect(c.nodeUrl, noNodeUrl);
    final u = Uri.parse(c.nodeUrl);
    expect(u.scheme, 'https', reason: 'LEPIC takes https to any host');
    expect(u.host, endsWith('.invalid'));
    expect(c.epicboxDomain, noEpicboxDomain, reason: 'the address key stays readable (.wfeh files)');
    expect(c.epicboxDomain, endsWith('.invalid'));
    // LEPIC's rule for an Epicbox domain (lepic-epicbox Domain::parse): letters, digits, dots.
    expect(c.epicboxDomain, matches(RegExp(r'^[A-Za-z0-9.]+$')));
  });

  test('a node in the list goes as it is', () async {
    final url = testSettings().nodeUse;
    final c = await LepicWalletService.lepicConfigOf(
      WalletConfig(dataDir: '/wallets/main', chain: Chain.mainnet, nodeUrl: url, epicboxDomain: 'relay.example.invalid', epicboxPort: 443),
    );
    expect(c.nodeUrl, url);
  });

  test('picking a server while the other list is empty writes only the one picked', () {
    final s = testSettings().withValues(_empty);
    final node = testSettings().nodeUse;
    final relay = testSettings().epicboxUse;
    expect(useServerValues(s, node: node, relay: ''), {'node.servers': [node]});
    expect(useServerValues(s, node: '', relay: relay), {'epicbox.servers': [relay]});
    expect(useServerValues(s, node: '', relay: ''), isEmpty);
  });
}
