// SPDX-License-Identifier: Apache-2.0
// The desktop's host for linked devices through a reopen of the wallet (a node change, node
// failover): while the new session opens it never hands the devices an engine that answers
// "no pairings", which ended a link under way and forgot every linked device as removed
// (live check of the tester report of 2026-10-28); once open it is the new session's.

import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/pairing_api.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _other = 'https://other.example';

class _Opens extends core.FakeWalletService {
  _Opens() : super(password: _password);

  /// Holds the opening on a node URL until completed.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async => core.NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    await gates[config.nodeUrl]?.future;
    return super.open(config: config, password: password);
  }
}

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('desk-device-host-'));
  tearDown(() => dir.delete(recursive: true));

  test('while the wallet reopens, the devices keep the last session, never an empty engine', () async {
    final service = _Opens()..existingWallets.add('${dir.path}/wallet');
    final secrets = MemorySecretStore();
    await secrets.write('app.node.mainnet', 'https://node.example');
    final w = LepicDeskWallet(
      service: service,
      walletDir: (chain) async => WalletRegistry.firstWalletDir(dir.path, chain),
      secrets: secrets,
      filesDir: () async => dir,
      nodePoll: const Duration(hours: 1),
    );
    expect(await w.unlock(_password), isTrue);
    final host = w.deviceHost(online: () => true)!;
    expect(host.pairing.privateSupported, isTrue);

    final gate = service.gates[_other] = Completer<void>();
    final moving = w.useNode(_other);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // The old session is closed, the new one not open yet.
    expect(host.pairing, isNot(isA<NoPairing>()));
    expect(host.pairing.privateSupported, isTrue);

    gate.complete();
    await moving;
    expect(host.pairing.privateSupported, isTrue);
    expect(await host.walletKey(), isNotEmpty);
    await w.dispose();
  });
}
