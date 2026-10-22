// The providers bind without starting anything (O2): reading them never starts a node.
import 'dart:io';

import 'package:epic_wallet/src/builtin_node.dart' show stopAllBuiltInNodes;
import 'package:epic_wallet/src/builtin_node_provider.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/fallback.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_providers.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

void main() {
  late Directory dir;
  late ProviderContainer c;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wfe-node-prov-');
    resetBuiltInNodes();
    c = ProviderContainer(
      overrides: [
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        builtInNodeSupportedProvider.overrideWithValue(true),
        builtInNodeLocationProvider.overrideWith(
          (ref) async => BuiltInNodeLocation(root: '${dir.path}/node', binary: '${dir.path}/epic'),
        ),
      ],
    );
  });

  tearDown(() async {
    c.dispose();
    await stopAllBuiltInNodes();
    resetBuiltInNodes();
    await dir.delete(recursive: true);
  });

  test('state, controller, maintenance and fallback read without starting a node', () async {
    // As a screen would: a provider nobody listens to is paused.
    c.listen(localNodeStateProvider(Chain.mainnet), (_, _) {});
    c.listen(fallbackDecisionProvider(Chain.mainnet), (_, _) {});
    final state = await c.read(localNodeStateProvider(Chain.mainnet).future);
    expect(state.phase, LocalNodePhase.stopped);
    expect(state.online, isFalse);
    await c.read(nodeMaintenanceProvider(Chain.mainnet).future);
    expect((await c.read(fallbackChoiceProvider(Chain.mainnet).future)).consent, FallbackConsent.unasked);
    await Future<void>.delayed(Duration.zero);
    final decision = c.read(fallbackDecisionProvider(Chain.mainnet));
    expect(decision.value?.action, FallbackAction.useLocal, reason: 'stopped and unasked: nothing to ask');
    final node = await c.read(builtInNodeProvider(Chain.mainnet).future);
    expect(node.state.isActive, isFalse);
    expect(File('${node.folder}/node.pid').existsSync(), isFalse);
    expect(Directory('${node.folder}/chain_data').existsSync(), isFalse, reason: 'nothing downloaded');
  });

  test('the providers and the wallet share one node per chain', () async {
    final where = await c.read(builtInNodeLocationProvider.future);
    expect(identical(await c.read(builtInNodeProvider(Chain.mainnet).future), builtInNodeFor(where, Chain.mainnet)), isTrue);
    expect(identical(builtInNodeFor(where, Chain.floonet), builtInNodeFor(where, Chain.mainnet)), isFalse);
  });
}
