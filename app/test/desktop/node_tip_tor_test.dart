// The node is never asked directly while the Tor switch is on: with a wallet open every tip and
// node check goes through the wallet (WalletSession.nodeTipFor, LEPIC's tor), announced to it
// before the first one; locked, a remote node is not asked at all (a node on this computer
// still is), and the app's own requests wait for tor from launch. Off, a locked check asks the
// node directly as before. LepicDeskWallet over FakeWalletSession; the password is a throwaway
// test value; no tor runs.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _bundle = TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle');
const _remote = 'https://node.example:3413';

/// A node that answers after [delay], or fails with [fails].
class _Node extends core.FakeWalletService {
  _Node() : super(password: _password);

  Duration delay = Duration.zero;
  Object? fails;

  @override
  Future<core.NodeTip> nodeAnswer(core.WalletConfig config) async {
    await Future<void>.delayed(delay);
    final f = fails;
    if (f != null) throw f;
    return nodeTipValue;
  }
}

void main() {
  late Directory support;
  late _Node service;
  late MemorySecretStore secrets;
  late LepicDeskWallet wallet;
  core.FakeWalletSession session() => service.session;

  LepicDeskWallet make({bool torSwitch = false}) => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final dir = Directory('${support.path}/wallets/${chain.name}');
      await dir.create(recursive: true);
      return dir.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    torBundle: () async => _bundle,
    torFeature: true,
    torSwitch: torSwitch,
  );

  /// The Tor switch on, saved, and the wallet locked.
  Future<void> torOnAndLocked() async {
    await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: true));
    await wallet.lock();
  }

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-node-tip-tor-test-');
    service = _Node();
    secrets = MemorySecretStore();
    wallet = make();
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await pumpEventQueue();
  });

  tearDown(() async {
    await wallet.dispose();
    TorNet.useDirect();
    await support.delete(recursive: true);
  });

  test('Tor on: the node poll and node checks go through the wallet, never directly', () async {
    await torOnAndLocked();
    service.nodeTipFails = StateError('the node was asked directly');
    final order = <String>[];
    session().routeLog.clear();
    session().onNodeTipFor = () => order.add(session().routeLog.contains('expectTor') ? 'after expectTor' : 'before expectTor');
    expect(await wallet.unlock(_password), isTrue);
    await pumpEventQueue();
    expect(session().nodeTipsFor, isNotEmpty, reason: 'the poll asked at unlock');
    expect((await wallet.status()).nodeHealth, ServiceHealth.ok);
    final checked = await wallet.checkNode(_remote);
    expect(checked.health, ServiceHealth.ok);
    expect(session().nodeTipsFor.last.nodeUrl, _remote);
    expect(service.nodeTipCalls, 0);
    expect(order.first, 'after expectTor', reason: 'the wallet waits for tor before the first tip');
  });

  test('Tor on and locked: a remote node is not asked, a node on this computer is', () async {
    await torOnAndLocked();
    final checked = await wallet.checkNode(_remote);
    expect(checked.health, ServiceHealth.checking, reason: 'not known until unlock');
    expect(service.nodeTipCalls, 0);
    await wallet.checkNode('http://127.0.0.1:3413');
    expect(service.nodeTipCalls, 1);
  });

  test('Tor on: the app\'s own requests wait for tor from launch, before any unlock', () async {
    await torOnAndLocked();
    await wallet.dispose();
    TorNet.useDirect();
    wallet = make(torSwitch: true);
    expect(TorNet.mode, TorNetMode.waiting);
    await wallet.dispose();
    wallet = make();
    expect(TorNet.mode, TorNetMode.direct);
  });

  test('Tor off: a locked check asks the node directly, as before', () async {
    await wallet.lock();
    final checked = await wallet.checkNode(_remote);
    expect(checked.health, ServiceHealth.ok);
    expect(service.nodeTipCalls, 1);
  });

  group('a tor restart', () {
    // The tester killed tor; it came back after 2 s, and the status said Not answering for
    // minutes while the wallet synced over Tor: a check timed for direct connections, counted
    // while tor started again.
    LepicDeskWallet torWallet() => LepicDeskWallet(
      service: service,
      walletDir: (chain) async => '${support.path}/wallets/${chain.name}',
      secrets: secrets,
      filesDir: () async => support,
      nodePoll: const Duration(milliseconds: 40),
      nodeTimeout: const Duration(milliseconds: 50),
      nodeTorTimeout: const Duration(seconds: 5),
      torStartBackoff: const [Duration(milliseconds: 20)],
      torBundle: () async => _bundle,
      torFeature: true,
    );

    Future<void> tor(core.TorEvent e) async {
      session().torEvents.add(e);
      await pumpEventQueue();
    }

    test('never makes a slow node over Tor Not answering', () async {
      await wallet.dispose();
      wallet = torWallet();
      expect(await wallet.unlock(_password), isTrue);
      await wallet.setTor(true);
      await tor(const core.TorEvent(kind: core.TorEventKind.ready));
      final seen = <ServiceHealth>[];
      final watch = wallet.changes().listen((_) async => seen.add((await wallet.status()).nodeHealth));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect((await wallet.status()).nodeHealth, ServiceHealth.ok);

      // tor stops; the node is unreachable until it is back.
      service.fails = TimeoutException('no circuit');
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.stopped));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect((await wallet.status()).nodeHealth, isNot(ServiceHealth.down), reason: 'not counted while tor starts again');

      // Back, and the node answers, slower than a direct check allows.
      service
        ..fails = null
        ..delay = const Duration(milliseconds: 300)
        ..nodeTipValue = core.NodeTip(height: BigInt.from(2500100), nodeVersion: '3.6.0');
      await tor(const core.TorEvent(kind: core.TorEventKind.ready));
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final s = await wallet.status();
      expect(s.nodeHealth, ServiceHealth.ok);
      expect(s.nodeHeight, 2500100, reason: 'the slow answer over Tor was taken, not timed out');

      // Freshly connected, a failed check over Tor is not counted either.
      service.fails = TimeoutException('circuit still building');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await watch.cancel();
      expect((await wallet.status()).nodeHealth, ServiceHealth.ok);
      expect(seen, isNot(contains(ServiceHealth.down)));
    });
  });
}
