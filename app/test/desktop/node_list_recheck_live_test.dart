// Live: the node list over the real LEPIC core and the real public nodes, with an own node added
// once the chain moved on. Every public node at the tip must read 0 behind again within a
// recheck, not the blocks between the first check and the own node's. Needs the Linux library
// and a mainnet node of your own (on this computer or reached through a tunnel):
//
//   WFE_DEMO_LEPIC_LIB=<path to liblepic_ffi.so> WFE_OWN_NODE=http://127.0.0.1:43413 \
//   flutter test test/desktop/node_list_recheck_live_test.dart
//
// Without them it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? _own = Platform.environment['WFE_OWN_NODE'];

const _password = 'recheck-live-pass-1';

void main() {
  late Directory tmp;

  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  setUp(() async => tmp = await Directory.systemTemp.createTemp('desk-node-recheck-live-'));
  tearDown(() => tmp.delete(recursive: true));

  test('public nodes read 0 behind again after an own node is added later', () async {
    final own = _own!;
    final secrets = MemorySecretStore({'app.node.mainnet': own});
    final wallet = LepicDeskWallet(
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async {
        final d = Directory('${tmp.path}/support/wallets/${chain.name}');
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => tmp,
      nodePoll: const Duration(hours: 1),
      nodeRecheck: const Duration(seconds: 20),
      rememberDir: () async => Directory('${tmp.path}/support/remember'),
      listProcesses: () async => const [],
    );
    addTearDown(wallet.dispose);
    await wallet.createWallet(name: 'Live', password: _password);
    expect(await wallet.unlock(_password), isTrue);

    String line(List<PanelServer> rows) => rows.map((r) => '${r.host}:${r.behind}').join('  ');
    Future<List<NodeServer>> settle() async {
      await wallet.nodes();
      await Future<void>.delayed(const Duration(seconds: 10));
      return wallet.nodes();
    }

    // The first check of the public nodes, then wait for a block.
    final first = await settle();
    final start = first.where((n) => !n.own && n.health == ServiceHealth.ok).map((n) => n.height!).reduce((a, b) => a > b ? a : b);
    // ignore: avoid_print
    print('first check: tip $start  ${line(nodePanelRows(first))}');
    var tip = start;
    while (tip <= start) {
      await Future<void>.delayed(const Duration(seconds: 15));
      tip = (await wallet.checkNode(own)).height ?? tip;
    }

    final checked = await wallet.checkNode(own);
    await wallet.addNode(NodeServer(url: own, label: '', health: checked.health, height: checked.height, version: checked.version, own: true));
    final added = nodePanelRows(await wallet.nodes());
    // ignore: avoid_print
    print('own node added at ${checked.height}: ${line(added)}');

    // Within a recheck the public nodes catch up; before, they kept the first check for good.
    final until = DateTime.now().add(const Duration(minutes: 2));
    List<PanelServer> rows = added;
    while (DateTime.now().isBefore(until)) {
      await Future<void>.delayed(const Duration(seconds: 10));
      rows = nodePanelRows(await wallet.nodes());
      // ignore: avoid_print
      print('${DateTime.now().toIso8601String().substring(11, 19)}  ${line(rows)}');
      final up = rows.where((r) => r.behind != null);
      if (up.length > 1 && up.every((r) => r.behind! <= 1)) break;
    }
    final up = rows.where((r) => r.behind != null).toList();
    expect(up.length, greaterThan(1));
    expect(up.map((r) => r.behind), everyElement(lessThanOrEqualTo(1)), reason: line(rows));
  }, skip: _lib == null || _own == null ? 'needs WFE_DEMO_LEPIC_LIB and WFE_OWN_NODE' : false, timeout: const Timeout(Duration(minutes: 15)));
}
