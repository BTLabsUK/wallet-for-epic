// The node list compares the nodes' heights with each other ("12 behind"), so its checks age:
// once the oldest is older than nodeRecheck, every node is asked again together. A check kept
// for good froze the public nodes while an own node added later moved on, and every public
// node read "64 behind" for as long as the app ran. LepicDeskWallet over
// FakeWalletSession; the password is a throwaway test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/relay_directory.dart' show NodeHealthState;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _own = 'http://127.0.0.1:3413';

/// Every node at [height]; the tip moves when a test raises it.
class _Chain extends core.FakeWalletService {
  _Chain() : super(password: _password);

  int height = 2500000;
  final asked = <String>[];

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async {
    asked.add(config.nodeUrl);
    return core.NodeTip(height: BigInt.from(height), nodeVersion: '4.1.1');
  }
}

void main() {
  late Directory support;
  late _Chain chain;
  late LepicDeskWallet wallet;

  Future<void> open(Duration recheck) async {
    wallet = LepicDeskWallet(
      service: chain,
      walletDir: (c) async {
        final dir = Directory('${support.path}/wallets/${c.name}');
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      nodeRecheck: recheck,
    );
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await pumpEventQueue();
  }

  /// The list once every check it started is in.
  Future<List<NodeServer>> settled() async {
    await wallet.nodes();
    await pumpEventQueue(times: 50);
    return wallet.nodes();
  }

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-node-recheck-test-');
    chain = _Chain();
  });

  tearDown(() async {
    await wallet.dispose();
    await support.delete(recursive: true);
  });

  test('an own node added after the tip moved does not leave the public nodes behind', () async {
    await open(Duration.zero);
    final first = await settled();
    final publics = first.where((n) => !n.own).toList();
    expect(publics, isNotEmpty);
    expect(publics.every((n) => n.height == 2500000), isTrue);

    // 64 blocks later the user adds their own node, checked as it is added (Settings › Node).
    chain.height += 64;
    final ownCheck = await wallet.checkNode(_own);
    await wallet.addNode(NodeServer(url: _own, label: '', health: ownCheck.health, height: ownCheck.height, version: ownCheck.version, own: true));

    final rows = nodePanelRows(await settled());
    expect({for (final r in rows) r.value: r.behind}.values, everyElement(0), reason: 'every node is at the tip');
    expect(rows.every((r) => r.state == NodeHealthState.healthy), isTrue);
  });

  test('checks younger than nodeRecheck are kept: no node is asked twice', () async {
    await open(const Duration(hours: 1));
    await settled();
    final asked = chain.asked.length;
    chain.height += 5;
    final again = await settled();
    expect(chain.asked.length, asked);
    expect(again.where((n) => !n.own).every((n) => n.height == 2500000), isTrue);
  });
}
