// The node list compares the nodes' heights with each other ("12 behind"), so its checks age:
// once the oldest is older than nodeRecheck, every node is asked again together. A check kept
// for good froze the public nodes while an own node added later moved on, and every public
// node read "64 behind" for as long as the app ran. LepicDeskWallet over
// FakeWalletSession; the password is a throwaway test value.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/relay_directory.dart' show NodeHealthState;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _own = 'http://127.0.0.1:3413';

/// Every node at [height]; the tip moves when a test raises it.
class _Chain extends core.FakeWalletService {
  _Chain() : super(password: _password);

  int height = 2500000;
  final asked = <String>[];

  /// Nodes that refuse, and nodes that never answer.
  final dead = <String>{};
  final hung = <String>{};

  /// A block arrives after this many more answers.
  int? blockAfter;

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async {
    asked.add(config.nodeUrl);
    if (hung.contains(config.nodeUrl)) await Completer<void>().future;
    if (dead.contains(config.nodeUrl)) throw StateError('connection refused');
    final answer = core.NodeTip(height: BigInt.from(height), nodeVersion: '4.1.1');
    final left = blockAfter == null ? null : blockAfter! - 1;
    blockAfter = left;
    if (left == 0) {
      blockAfter = null;
      height++;
    }
    return answer;
  }
}

void main() {
  late Directory support;
  late _Chain chain;
  late LepicDeskWallet wallet;

  Future<void> open(Duration recheck, {Duration stale = const Duration(minutes: 3)}) async {
    wallet = LepicDeskWallet(
      service: chain,
      walletDir: (c) async {
        final dir = Directory(WalletRegistry.firstWalletDir(support.path, c));
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      nodeRecheck: recheck,
      nodeStale: stale,
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

  test('the gap does not grow: an own node added, then another node picked, later and later', () async {
    await open(const Duration(milliseconds: 50));
    await settled();
    const picked = 'https://node.epicnet.us:3413';
    for (final (blocks, step) in [(64, 'own node added'), (66, 'another node picked')]) {
      chain.height += blocks;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (step == 'own node added') {
        final c = await wallet.checkNode(_own);
        await wallet.addNode(NodeServer(url: _own, label: '', health: c.health, height: c.height, version: c.version, own: true));
      } else {
        await wallet.checkNode(picked);
      }
      final rows = nodePanelRows(await settled());
      expect([for (final r in rows) r.behind], everyElement(0), reason: '$step at ${chain.height}');
      expect(rows.length, 6);
    }
  });

  test('a check older than nodeStale gives no height: behind is unknown, never a stale figure', () async {
    await open(const Duration(hours: 1), stale: const Duration(milliseconds: 50));
    await settled();
    chain.height += 130;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await wallet.checkNode('https://node.epicnet.us:3413');
    final rows = nodePanelRows(await wallet.nodes());
    expect(rows.where((r) => r.behind != null).map((r) => r.value), ['https://node.epicnet.us:3413']);
    expect(rows.firstWhere((r) => r.value == 'https://node.btlabs.uk').behind, isNull);
    expect(rows.every((r) => (r.behind ?? 0) == 0), isTrue, reason: 'no row reads 130 behind');
  });

  test('a node that stops answering is shown down, never with its old height behind', () async {
    await open(const Duration(milliseconds: 50));
    await settled();
    chain.dead.add('https://node.epiccash.com:3413');
    chain.height += 64;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final rows = nodePanelRows(await settled());
    final gone = rows.firstWhere((r) => r.value == 'https://node.epiccash.com:3413');
    expect(gone.state, NodeHealthState.down);
    expect(gone.behind, isNull);
    expect([for (final r in rows) if (r.value != gone.value) r.behind], everyElement(0));
  });

  test('a node whose check hangs loses its height once the check is older than nodeStale', () async {
    await open(const Duration(milliseconds: 50), stale: const Duration(milliseconds: 150));
    await settled();
    chain.hung.add('https://node.epiccash.com:3413');
    chain.height += 64;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await settled();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final rows = nodePanelRows(await settled());
    expect(rows.firstWhere((r) => r.value == 'https://node.epiccash.com:3413').behind, isNull);
    expect([for (final r in rows) r.behind ?? 0], everyElement(0), reason: 'no row reads 64 behind');
  });

  test('a block during a joint recheck: at most 1 behind, 0 at the next recheck', () async {
    await open(const Duration(milliseconds: 50));
    await settled();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    chain.blockAfter = 3;
    final during = nodePanelRows(await settled());
    expect([for (final r in during) r.behind!], everyElement(lessThanOrEqualTo(1)));
    expect(during.any((r) => r.behind == 1), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final next = nodePanelRows(await settled());
    expect([for (final r in next) r.behind], everyElement(0));
  });

  test('after hours open or a sleep: no stale figure, then fresh heights at once', () async {
    await open(const Duration(milliseconds: 50), stale: const Duration(milliseconds: 100));
    await settled();
    // The computer slept: the wall clock moved on, 500 blocks came meanwhile.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    chain.height += 500;
    final woke = nodePanelRows(await wallet.nodes());
    expect([for (final r in woke) r.behind], everyElement(isNull), reason: 'stale heights are not compared');
    final rows = nodePanelRows(await settled());
    expect([for (final r in rows) r.behind], everyElement(0));
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
