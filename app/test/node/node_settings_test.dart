// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/fallback.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecretStore store;
  late NodeSettings settings;

  setUp(() {
    store = MemorySecretStore();
    settings = NodeSettings(store, Chain.mainnet);
  });

  test('defaults', () async {
    expect(await settings.startWithApp(), isTrue);
    expect(await settings.chainDataPath(), isNull);
    expect(await settings.preferredPeers(), isEmpty);
    expect(await settings.maxInbound(), isNull);
    expect(await settings.maxOutbound(), isNull);
    expect(await settings.fallbackChoice(), const FallbackChoice.unasked());
    expect(await settings.toOptions(), const NodeTomlOptions());
  });

  test('round trip under node.<chain>.<name>', () async {
    await settings.setStartWithApp(false);
    await settings.setChainDataPath(' /data/chain ');
    await settings.setPreferredPeers(['1.2.3.4:3414', ' ', '[::1]:3414']);
    await settings.setMaxInbound(12);
    await settings.setMaxOutbound(0);
    final choice = FallbackChoice(
      FallbackConsent.accepted,
      nodeUrl: 'https://node.btlabs.uk',
      at: DateTime.utc(2026, 10, 22, 9),
    );
    await settings.setFallbackChoice(choice);

    expect(store.values.keys, everyElement(startsWith('node.mainnet.')));
    expect(store.values['node.mainnet.preferredPeers'], '["1.2.3.4:3414","[::1]:3414"]');
    expect(await settings.startWithApp(), isFalse);
    expect(await settings.fallbackChoice(), choice);
    expect(
      await settings.toOptions(),
      const NodeTomlOptions(
        chainDataPath: '/data/chain',
        preferredPeers: ['1.2.3.4:3414', '[::1]:3414'],
        maxInbound: 12,
        maxOutbound: 0,
      ),
    );
    expect(await NodeSettings(store, Chain.floonet).maxInbound(), isNull);
  });

  test('clearing removes the keys', () async {
    await settings.saveOptions(
      const NodeTomlOptions(chainDataPath: '/x', preferredPeers: ['1.2.3.4:1'], maxInbound: 3),
    );
    await settings.saveOptions(const NodeTomlOptions());
    expect(store.values, isEmpty);
  });

  test('garbage gives the defaults', () async {
    store.values.addAll({
      'node.mainnet.startWithApp': 'maybe',
      'node.mainnet.chainDataPath': '   ',
      'node.mainnet.preferredPeers': '{not json',
      'node.mainnet.maxInbound': 'ten',
      'node.mainnet.maxOutbound': '-4',
      'node.mainnet.fallbackConsent': '[1,2',
    });
    expect(await settings.startWithApp(), isTrue);
    expect(await settings.toOptions(), const NodeTomlOptions());
    expect(await settings.fallbackChoice(), const FallbackChoice.unasked());

    store.values['node.mainnet.preferredPeers'] = '["1.2.3.4:1", 5, null]';
    store.values['node.mainnet.fallbackConsent'] = '{"consent":"accepted","nodeUrl":"http://x"}';
    expect(await settings.preferredPeers(), ['1.2.3.4:1']);
    expect(await settings.fallbackChoice(), const FallbackChoice.unasked());
  });

  test('a store that throws gives the defaults', () async {
    final s = NodeSettings(_Broken(), Chain.mainnet);
    expect(await s.startWithApp(), isTrue);
    expect(await s.toOptions(), const NodeTomlOptions());
  });
}

class _Broken implements SecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('locked');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
