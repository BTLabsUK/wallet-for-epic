// Live: the user's own node reached by its home-network address (tester #113), with the app's
// real node client, the node relay and the owner secret. Needs a node answering plain http on
// WFE_OWN_NODE (e.g. http://10.0.0.44:33413, never 127.0.0.1) and its `.api_secret` at
// WFE_OWN_NODE_SECRET; WFE_OWN_NODE_CHAIN is the status site's chain name (none for usernet).
// Without them it is skipped:
//
//   WFE_OWN_NODE=http://10.0.0.44:33413 WFE_OWN_NODE_SECRET=<node dir>/.api_secret \
//   flutter test test/desktop/own_node_live_test.dart
//
// WFE_MINE_NODE=https://floo-node.btlabs.uk also asks that listed node as one marked Mine.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/own_node.dart';
import 'package:epic_wallet/src/net/lan_node_relay.dart';
import 'package:epic_wallet/src/net/local_address.dart';
import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_info.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _url = Platform.environment['WFE_OWN_NODE'];
final String? _secretFile = Platform.environment['WFE_OWN_NODE_SECRET'];
final String? _chain = Platform.environment['WFE_OWN_NODE_CHAIN'];
final String? _mine = Platform.environment['WFE_MINE_NODE'];

void main() {
  tearDownAll(closeLanNodeRelays);

  test('a home-network node over plain http: tier 1 asked directly through the relay', () async {
    final url = _url!;
    expect(nodeClassOf(url), isNot(NodeClass.thisComputer), reason: 'reach it by its LAN address');
    final service = NodeInfoService(nodes: const _NoNodes(), clientFor: NodeApiClient.new);
    final i = await service.info(url, chain: _chain);
    // ignore: avoid_print
    print('own node: class ${i.nodeClass.name} source ${i.source.name} head ${i.head?.name} height ${i.height} version ${i.version} '
        'latency ${i.latencyMs} ms ready ${i.readyForTxs} pool ${i.poolSize} tip ${i.networkHeight} from ${i.tipFrom?.name} error ${i.error}');
    expect(i.source, NodeInfoSource.limited);
    expect(i.height, isNotNull);
    expect(i.version, isNotNull);
    expect(i.latencyMs, isNotNull);
    expect(i.poolSize, isNotNull);
  }, skip: _url == null);

  test('owner access: a wrong secret refused, the right one kept, status and peers read', () async {
    final url = _url!;
    final secret = File(_secretFile!).readAsLinesSync().first.trim();
    final store = MemorySecretStore();
    final a = OwnNodeAccess(store, torOn: () => false);
    expect(await a.add(url, 'not-the-secret'), OwnerCheck.refused);
    expect(store.values, isEmpty);
    expect(await a.add(url, secret), OwnerCheck.ok);
    final st = await a.status(url);
    final peers = await a.peers(url);
    // ignore: avoid_print
    print('owner: sync ${st.syncStatus} peers ${st.peers} version ${st.version} height ${st.height}; table ${peers.connected.length} connected, ${peers.banned.length} banned');
    expect(st.height, isNotNull);
    // Rotated on the node: refused, not down.
    await store.write(ownerSecretKey(url), 'rotated');
    await expectLater(a.status(url), throwsA(isA<OwnerUnavailable>().having((e) => e.why, 'why', OwnerOff.refused)));
  }, skip: _url == null || _secretFile == null);

  test('a listed node marked Mine is asked directly, the tip from the status site', () async {
    final directory = HttpRelayDirectory();
    final service = NodeInfoService(nodes: directory, network: directory);
    final i = await service.info(_mine!, chain: 'floonet', mine: true);
    // ignore: avoid_print
    print('mine: class ${i.nodeClass.name} head ${i.head?.name} height ${i.height} tip ${i.networkHeight} from ${i.tipFrom?.name} pool ${i.poolSize} latency ${i.latencyMs}');
    expect(i.nodeClass, NodeClass.ownServer);
    expect(i.tipFrom, TipReference.statusSite);
    expect(i.height, isNotNull);
  }, skip: _mine == null);
}

class _NoNodes implements NodeDirectory {
  const _NoNodes();

  @override
  Future<List<NodeStatus>> nodes(String chain) async => const [];
}
