// SPDX-License-Identifier: Apache-2.0
// Live: a node on the local network (a 192.168.x address, plain http as the app writes it)
// checked through the real LEPIC core, as Settings › Node does (it goes through the loopback
// relay, lan_node_relay.dart). Needs a node answering on
// WFE_LAN_NODE (e.g. http://10.0.0.44:4413) and the Linux library:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//   WFE_LAN_NODE=http://10.0.0.44:4413 flutter test test/desktop/lan_node_live_test.dart
//
// Without them it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _lan = Platform.environment['WFE_LAN_NODE'];

void main() {
  late Directory tmp;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async => tmp = await Directory.systemTemp.createTemp('desk-lan-node-live-'));
  tearDown(() => tmp.delete(recursive: true));

  test('a node on the local network answers its check', () async {
    final secrets = MemorySecretStore({'app.node.mainnet': 'https://node.btlabs.uk'});
    final wallet = LepicDeskWallet(
      preset: mainnetPreset,
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async {
        final d = Directory(WalletRegistry.firstWalletDir('${tmp.path}/support', chain));
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => tmp,
      nodePoll: const Duration(hours: 1),
      nodeTimeout: const Duration(seconds: 5),
      rememberDir: () async => Directory('${tmp.path}/support/remember'),
      listProcesses: () async => const [],
    );
    final r = await wallet.checkNode(_lan!);
    expect(r.health, ServiceHealth.ok, reason: '$_lan');
    expect(r.height, greaterThan(0));
    await wallet.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)), skip: _lib == null || _lan == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_LAN_NODE' : false);
}
